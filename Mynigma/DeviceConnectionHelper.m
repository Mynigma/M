//
//	Copyright © 2012 - 2015 Roman Priebe
//
//	This file is part of M - Safe email made simple.
//
//	M is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	M is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with M.  If not, see <http://www.gnu.org/licenses/>.
//





#import "DeviceConnectionHelper.h"
#import "DeviceMessage+Category.h"
#import "IMAPAccountSetting+Category.h"
#import "MynigmaDevice+Category.h"
#import "AppDelegate.h"
#import "UserSettings.h"
#import "EmailMessageInstance+Category.h"
#import "IdleHelper.h"
#import "TrustEstablishmentThread.h"
#import "MergeLocalChangesHelper.h"
#import "AlertHelper.h"
#import "EmailMessage+Category.h"
#import "DataWrapHelper.h"
#import "UserSettings+Category.h"




#if TARGET_OS_IPHONE

#import "DisplayMessageController.h"

#endif



@implementation DeviceConnectionHelper

- (instancetype)init
{
    self = [super init];
    if (self) {
        //self.folderCheckTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(downloadAndProcessDeviceMessageBodiesIfNecessary:) userInfo:nil repeats:YES];
    }
    return self;
}



#if TARGET_OS_IPHONE

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //the "inform user about newly discovered device dialogue" on iOS 7
    if(buttonIndex != [alertView cancelButtonIndex])
    {
        [TrustEstablishmentThread startNewThreadWithTargetDeviceUUID:self.targetDeviceForThreadEstablishmentToBeConfirmed.deviceId withCallback:nil];
    }
}

#endif

+ (void)informUserAboutNewlyDiscoveredDevice:(MynigmaDevice*)device inAccountSetting:(IMAPAccountSetting*)accountSetting
{
    if(!PROCESS_DEVICE_MESSAGES)
        return;
    
    NSString* targetDeviceUUID = device.deviceId;
    
    NSString* titleString = NSLocalizedString(@"New device found", nil);

    NSString* messageString = [NSString stringWithFormat:NSLocalizedString(@"Device %@ is also connected to this account. Would you like to pair with this device? Pairing will allow both devices to access your safe messages.", nil), device.displayName];

    [AlertHelper showTwoOptionDialogueWithTitle:titleString message:messageString OKOption:NSLocalizedString(@"OK", nil) cancelOption:NSLocalizedString(@"Cancel", nil) suppressionIdentifier:@"mynigmaSuppressionDeviceDiscoveryMessage" callback:^(BOOL OKOptionSelected) {

        if(OKOptionSelected)
        {
            [ThreadHelper runAsyncOnMain:^{

                [TrustEstablishmentThread startNewThreadWithTargetDeviceUUID:targetDeviceUUID withCallback:nil];
            }];
        }
    }];
}


+ (DeviceConnectionHelper*)sharedInstance
{
    static dispatch_once_t p = 0;

    __strong static id sharedObject = nil;

    dispatch_once(&p, ^{
        sharedObject = [DeviceConnectionHelper new];
    });

    return sharedObject;
}




+ (void)postDeviceDiscoveryAndSyncDataMessages
{
    //first remove any previous, unused device discovery messages
    NSArray* allDeviceMessages = [DeviceMessage listAllDeviceMessagesInContext:MAIN_CONTEXT];

    for(DeviceMessage* deviceMessage in allDeviceMessages)
    {
        //remove any unnecessary device messages
        if([deviceMessage.messageCommand isEqual:@"DEVICE_DISCOVERY"])
        {
            //is the message associated with this device?
            if([deviceMessage.sender isEqual:[MynigmaDevice currentDevice]])
            {
                //is it obsolete?
                if(!deviceMessage.discoveryMessageForDevice)
                {
                    //remove all instances!
                    NSSet* allInstances = [NSSet setWithSet:deviceMessage.instances];
                    for(EmailMessageInstance* messageInstance in allInstances)
                    {
                        [messageInstance deleteInstanceInContext:MAIN_CONTEXT];
                    }
                }
            }
        }

        if([deviceMessage.messageCommand isEqual:@"SYNC_DATA"])
        {
            //is the message associated with this device?
            if([deviceMessage.sender isEqual:[MynigmaDevice currentDevice]])
            {
                //is it obsolete?
                if(!deviceMessage.dataSyncMessageForDevice)
                {
                    //remove all instances!
                    NSSet* allInstances = [NSSet setWithSet:deviceMessage.instances];
                    for(EmailMessageInstance* messageInstance in allInstances)
                    {
                        [messageInstance deleteInstanceInContext:MAIN_CONTEXT];
                    }
                }
            }
        }
    }

    //go through the accounts and ensure that the current device discovery message instance is present in each account
    for(IMAPAccountSetting* accountSetting in [UserSettings currentUserSettings].accounts)
        if(accountSetting.shouldUse.boolValue)
    {
        BOOL haveDeviceMessageForThisAccount = NO;

        for(EmailMessageInstance* messageInstance in [MynigmaDevice currentDevice].discoveryMessage.instances)
        {
            if([messageInstance.accountSetting isEqual:accountSetting] && !messageInstance.deletedFromFolder)
                haveDeviceMessageForThisAccount = YES;
        }

        if(!haveDeviceMessageForThisAccount)
        {
            //no device message instance present
            //add one!
            [DeviceConnectionHelper postDeviceDiscoveryMessageWithAccountSetting:accountSetting];
        }

        
        BOOL haveSyncDataMessageForThisAccount = NO;

        for(EmailMessageInstance* messageInstance in [MynigmaDevice currentDevice].syncDataMessage.instances)
        {
            if([messageInstance.accountSetting isEqual:accountSetting] && !messageInstance.deletedFromFolder)
                haveSyncDataMessageForThisAccount = YES;
        }

        if(!haveSyncDataMessageForThisAccount)
        {
            //no device message instance present
            //add one!
            [DeviceConnectionHelper postSyncDataMessageWithAccountSetting:accountSetting];
        }
    }
}


+ (void)postDeviceDiscoveryMessageWithAccountSetting:(IMAPAccountSetting*)accountSetting
{
    NSManagedObjectID* mainAccountSettingObjectID = accountSetting.objectID;

    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

        IMAPAccountSetting* localAccountSetting = (IMAPAccountSetting*)[localContext existingObjectWithID:mainAccountSettingObjectID error:nil];

        MynigmaDevice* currentDevice = [MynigmaDevice currentDeviceInContext:localContext];

        DeviceMessage* previousDiscoveryMessage = currentDevice.discoveryMessage;

        DeviceMessage* discoveryMessage = [DeviceMessage deviceDiscoveryMessageInContext:localContext];

        if(previousDiscoveryMessage && [previousDiscoveryMessage isEqual:discoveryMessage])
        {
            //return if the message has already been posted to this account
            if([[previousDiscoveryMessage.instances valueForKeyPath:@"inFolder.inIMAPAccount"] containsObject:accountSetting])
                return;
        }

        [DeviceConnectionHelper postDeviceMessage:discoveryMessage intoAccountSetting:localAccountSetting inContext:localContext];

        [currentDevice setDiscoveryMessage:discoveryMessage];

        [MergeLocalChangesHelper mergeDeviceMessagesForAccount:accountSetting.account inFolder:accountSetting.mynigmaFolder];
    }];
}


+ (void)postSyncDataMessageWithAccountSetting:(IMAPAccountSetting*)accountSetting
{
    NSManagedObjectID* mainAccountSettingObjectID = accountSetting.objectID;

    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

        IMAPAccountSetting* localAccountSetting = (IMAPAccountSetting*)[localContext existingObjectWithID:mainAccountSettingObjectID error:nil];

        MynigmaDevice* currentDevice = [MynigmaDevice currentDeviceInContext:localContext];

        DeviceMessage* dataSyncMessage = [DeviceMessage syncDataMessageFromDevice:currentDevice inContext:localContext];

        [DeviceConnectionHelper postDeviceMessage:dataSyncMessage intoAccountSetting:localAccountSetting inContext:localContext];

        [MergeLocalChangesHelper mergeDeviceMessagesForAccount:accountSetting.account inFolder:accountSetting.mynigmaFolder];
    }];
}


- (BOOL)isCurrentlyEstablishingTrust
{
    return self.establishingTrustInThreadWithID!=nil;
}

- (void)startEstablishingTrustInThreadWithID:(NSString*)threadID
{
    if(self.establishingTrustInThreadWithID)
        [self cancelEstablishingTrustInThreadWithID:self.establishingTrustInThreadWithID];

    self.establishingTrustInThreadWithID = threadID;
}

- (void)cancelEstablishingTrustInThreadWithID:(NSString*)threadID
{
    self.establishingTrustInThreadWithID = nil;
}

- (void)startIdlingAccount:(IMAPAccountSetting*)accountSetting
{
    IMAPFolderSetting* folderSetting = accountSetting.mynigmaFolder;

    for(IdleHelper* idleHelper in self.idleHelpers)
    {
        IMAPFolderSetting* idledFolder = [idleHelper idledFolder];

        if([idledFolder isEqual:folderSetting])
        {
            //found an existing idleHelper for this folder
            //if it is not currently idling, restart it!
            if(![idleHelper isIdling])
            {
                [idleHelper idle:folderSetting];
            }
            return;
        }
    }

    //no matching idleHelper so far
    //add a new one
    IdleHelper* newIdleHelper = [IdleHelper new];

    if(!self.idleHelpers)
        self.idleHelpers = [NSMutableArray new];

    [self.idleHelpers addObject:newIdleHelper];

    [newIdleHelper idle:folderSetting];
}



- (BOOL)isIdlingAccount:(IMAPAccountSetting*)accountSetting
{
    IMAPFolderSetting* folderSetting = accountSetting.mynigmaFolder;

    for(IdleHelper* idleHelper in self.idleHelpers)
    {
        IMAPFolderSetting* idledFolder = [idleHelper idledFolder];

        if([idledFolder isEqual:folderSetting])
        {
            //found an existing idleHelper for this folder
            return [idleHelper isIdling];
        }
    }

    return NO;
}


- (void)stopIdlingAccount:(IMAPAccountSetting*)accountSetting
{
    IMAPFolderSetting* folderSetting = accountSetting.mynigmaFolder;

    for(IdleHelper* idleHelper in self.idleHelpers)
    {
        IMAPFolderSetting* idledFolder = [idleHelper idledFolder];

        if([idledFolder isEqual:folderSetting])
        {
            //found an existing idleHelper for this folder
            //if it is currently idling, cancel it!
            if([idleHelper isIdling])
            {
                [idleHelper cancelIdle];
            }
            return;
        }
    }
}




#pragma mark - Posting device messages


+ (void)postDeviceMessage:(DeviceMessage*)deviceMessage intoAccountSetting:(IMAPAccountSetting*)accountSetting
{
    NSManagedObjectID* mainDeviceMessageObjectID = deviceMessage.objectID;
    NSManagedObjectID* mainAccountSettingObjectID = accountSetting.objectID;

    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext)
     {
         IMAPAccountSetting* localAccountSetting = (IMAPAccountSetting*)[localContext existingObjectWithID:mainAccountSettingObjectID error:nil];

         DeviceMessage* localDeviceMessage = (DeviceMessage*)[DeviceMessage messageWithObjectID:mainDeviceMessageObjectID inContext:localContext];

         [DeviceConnectionHelper postDeviceMessage:localDeviceMessage intoAccountSetting:localAccountSetting inContext:localContext];

         [MergeLocalChangesHelper mergeDeviceMessagesForAccount:localAccountSetting.account inFolder:localAccountSetting.mynigmaFolder];
     }];
}

+ (void)postDeviceMessage:(DeviceMessage*)deviceMessage intoAccountSetting:(IMAPAccountSetting*)accountSetting inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    NSData* deviceMessageData = [DataWrapHelper wrapDeviceMessage:deviceMessage];

    if(!deviceMessageData)
    {
        NSLog(@"No device message data!!");
        return;
    }

    BOOL alreadyFoundOne = NO;

    IMAPFolderSetting* folderSetting = accountSetting.mynigmaFolder;

    EmailMessageInstance* newInstance = [EmailMessageInstance findOrMakeNewInstanceForMessage:deviceMessage inFolder:folderSetting inContext:localContext alreadyFoundOne:&alreadyFoundOne];

    if(alreadyFoundOne)
        return;

    [newInstance setAddedToFolder:newInstance.inFolder];

    [newInstance setFlags:@(MCOMessageFlagSeen)];

    NSError* error = nil;
    [localContext save:&error];
    if(error)
        NSLog(@"Error saving temporary context after posting device messages: %@",error);
}

+ (void)postDeviceMessage:(DeviceMessage*)deviceMessage intoAccountSettings:(NSSet*)accounts
{
    for(IMAPAccountSetting* accountSetting in accounts)
    {
        [DeviceConnectionHelper postDeviceMessage:deviceMessage intoAccountSetting:accountSetting];
    }
}

+ (void)postDeviceMessage:(DeviceMessage*)deviceMessage intoAccountSettings:(NSSet*)accounts inContext:(NSManagedObjectContext*)localContext
{
    for(IMAPAccountSetting* accountSetting in accounts)
    {
        [DeviceConnectionHelper postDeviceMessage:deviceMessage intoAccountSetting:accountSetting inContext:localContext];
    }
}

+ (void)postDeviceMessage:(DeviceMessage*)deviceMessage intoAllAccountsInContext:(NSManagedObjectContext*)localContext
{
    for(IMAPAccountSetting* accountSetting in [UserSettings usedAccountsInContext:localContext])
    {
        [DeviceConnectionHelper postDeviceMessage:deviceMessage intoAccountSetting:accountSetting inContext:localContext];
    }
    
    return;
}


@end
