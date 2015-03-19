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





#import "TrustEstablishmentThread.h"
#import "DeviceMessage+Category.h"
#import "MynigmaDevice+Category.h"
#import "OpenSSLWrapper.h"
#import "AppleEncryptionWrapper.h"
#import "DeviceConnectionHelper.h"
#import "AppDelegate.h"
#import "MergeLocalChangesHelper.h"
#import "MynigmaPublicKey+Category.h"
#import "AlertHelper.h"
#import "AnnounceInfoDeviceMessage.h"
#import "ConfirmConnectionMessage.h"
#import "NSString+EmailAddresses.h"
#import "MynigmaPrivateKey+Category.h"
#import "IMAPAccountSetting+Category.h"



#if TARGET_OS_IPHONE

#import "DisplayMessageController.h"
#import "ViewControllersManager.h"

#endif


static NSMutableDictionary* allThreads;


@implementation TrustEstablishmentThread


+ (void)addThread:(TrustEstablishmentThread*)newThread withID:(NSString*)threadID
{
    @synchronized(self)
    {
        if(!threadID)
            return;
        
        if(!allThreads)
            allThreads = [NSMutableDictionary new];
        
        allThreads[threadID] = newThread;
    }
}

+ (TrustEstablishmentThread*)threadWithID:(NSString*)threadID
{
    @synchronized(self)
    {
        if(!allThreads)
            return nil;
        
        return allThreads[threadID];
    }
}

- (BOOL)isAllowedMessageCommand:(NSString*)messageKind
{
    if(!self.expectedMessageCommands)
        return YES;
    
    if([self.expectedMessageCommands containsObject:messageKind])
        return YES;
    
    return NO;
}

#if TARGET_OS_IPHONE

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //the "let user confirm device connection dialogue" on iOS 7
    if(self.confirmationCallback)
        self.confirmationCallback(buttonIndex != [alertView cancelButtonIndex]);
}

#endif

//another device is trying to connect to me!
//ask user to confirm
- (void)askForConfirmationToRespondToMessage:(DeviceMessage*)deviceMessage withCallback:(void(^)(BOOL confirmed))callback
{
    NSString* deviceDescription = [NSString stringWithFormat:NSLocalizedString(@"%@ is trying to connect to you! Do you trust this device?", @"Device connection alert dialogue"), deviceMessage.sender.displayName];
    
    [AlertHelper showTwoOptionDialogueWithTitle:NSLocalizedString(@"Device connection initialised", nil) message:deviceDescription OKOption:NSLocalizedString(@"OK", nil) cancelOption:NSLocalizedString(@"Cancel", nil) suppressionIdentifier:@"MynigmaDeviceConnection_SuppressionIdentifier" callback:^(BOOL OKOptionSelected) {
        
        if(callback)
            callback(OKOptionSelected);
    }];
    
    return;
    
    //
    //    NSString* deviceDescription = [NSString stringWithFormat:NSLocalizedString(@"%@ is trying to connect to you! Do you trust this device?", @"Device connection alert dialogue"), deviceMessage.sender.displayName];
    //
    //    [ThreadHelper runAsyncOnMain:^{
    //
    //#if TARGET_OS_IPHONE
    //
    //    if(NSClassFromString(@"UIAlertController")!=nil)
    //    {
    //        UIAlertController* alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Device connection initialised", nil) message:deviceDescription preferredStyle:UIAlertControllerStyleAlert];
    //
    //        UIAlertAction* OKAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
    //
    //            if(callback)
    //                callback(YES);
    //
    //        }];
    //
    //        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
    //
    //            if(callback)
    //                callback(NO);
    //        }];
    //
    //        [alertController addAction:OKAction];
    //
    //        [alertController addAction:cancelAction];
    //
    //        [[ViewControllersManager sharedInstance].displayMessageController presentViewController:alertController animated:YES completion:nil];
    //    }
    //    else
    //    {
    //        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Device connection initialised", nil) message:deviceDescription delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    //
    //        [alertView setDelegate:self];
    //
    //        [self setConfirmationCallback:callback];
    //
    //        [alertView show];
    //
    //#warning TO DO: add suppression button (iOS)
    //
    //    }
    //
    //#else
    //
    //    __block NSInteger result = 0;
    //
    //    [MAIN_CONTEXT performBlockAndWait:^{
    //
    //        [AlertHelper showDialogueWithTitle:NSLocalizedString(@"New device found", nil) message:deviceDescription options:@[NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil)]  suppressionIdenitifer:@"MynigmaSuppressionButton_DeviceDiscoveryNewDevice" callback:^(NSInteger indexOfSelectedOption){
    //
    //            if(callback)
    //                callback(result == NSAlertFirstButtonReturn);
    //        }];
    //    }];
    //
    //
    //#endif
    //
    //    }];
}



- (void)processDeviceMessage:(DeviceMessage*)deviceMessage inAccount:(IMAPAccountSetting*)accountSetting
{
    if(!PROCESS_DEVICE_MESSAGES)
        return;
    
    if(VERBOSE_TRUST_ESTABLISHMENT)
    {
        NSLog(@"Processing device message: %@\nWith payload: %@", deviceMessage.messageCommand, deviceMessage.payload);
    }
    
    NSString* messageKind = deviceMessage.messageCommand;
    
    //first check that the message kind/message command makes sense at this stage of the protocol
    if(![self isAllowedMessageCommand:messageKind])
    {
        //command does not fit this stage of the protocol
        NSLog(@"Unexpected device message command: %@, expected: %@", messageKind, self.expectedMessageCommands);
        return;
    }
    
    //check that the device is the one that started the thread
    if(![deviceMessage.sender.deviceId isEqual:self.partnerDeviceUUID])
    {
        NSLog(@"Trying to continue thread started with device %@ with new device %@", self.partnerDeviceUUID, deviceMessage.sender.deviceId);
        return;
    }
    
    if(deviceMessage.hasExpired)
        return;
    
    NSManagedObjectID* accountSettingObjectID = accountSetting.objectID;
    
    //start of trust establishment protocol
    if([messageKind isEqualToString:@"1_ANNOUNCE_INFO"])
    {
        //ask user to confirm connection, if message is recent
        
        [self askForConfirmationToRespondToMessage:deviceMessage withCallback:^(BOOL confirmed) {
            
            [deviceMessage.managedObjectContext performBlock:^{
                
                if(!confirmed)
                {
                    //if the user doesn't confirm, make sure that this thread remains blocked
                    self.expectedMessageCommands = [NSSet set];
                    
                    return;
                }
                
                if(deviceMessage.payload.count<4)
                {
                    NSLog(@"Error: message of kind 1_ANNOUNCE_INFO has insufficient payload data: %@", deviceMessage.payload);
                    return;
                }
                
                [self setPartnerPublicVerKeyData:deviceMessage.payload[0]];
                
                [self setPartnerPublicEncKeyData:deviceMessage.payload[1]];
                
                [self setPartnerPublicKeyLabel:deviceMessage.payload[2]];
                
                [self setPartnerHashData:deviceMessage.payload[3]];
                
                //ensure there is a device sync key present...
                NSMethodSignature* keyCompletionMethod = [TrustEstablishmentThread instanceMethodSignatureForSelector:@selector(postAckAnnounceInfoMessageAfterDeviceSyncKeyGeneration)];
                
                NSInvocation* keyGenerationCompleted = [NSInvocation invocationWithMethodSignature:keyCompletionMethod];
                
                [keyGenerationCompleted setTarget:self];
                [keyGenerationCompleted setSelector:@selector(postAckAnnounceInfoMessageAfterDeviceSyncKeyGeneration)];
                
                self.expectedMessageCommands = [NSSet set];
                
                self.accountSettingObjectID = accountSettingObjectID;
                
                self.threadID = deviceMessage.threadID;
                
                if(self.accountSettingObjectID)
                {
                [ThreadHelper runAsyncOnMain:^{
                
                    [MynigmaPrivateKey waitUntilDeviceKeyIsGeneratedForDeviceWithUUID:self.thisDeviceUUID andThenCall:keyGenerationCompleted];
                    
                }];
                }
            }];
        }];
    }
    else if([messageKind isEqualToString:@"1_ACK_ANNOUNCE_INFO"])
    {
        if(deviceMessage.payload.count<4)
        {
            NSLog(@"Error: message of kind 1_ACK_ANNOUNCE_INFO has insufficient payload data: %@", deviceMessage.payload);
            return;
        }
        
        [self setPartnerPublicVerKeyData:deviceMessage.payload[0]];
        
        [self setPartnerPublicEncKeyData:deviceMessage.payload[1]];
        
        [self setPartnerPublicKeyLabel:deviceMessage.payload[2]];
        
        [self setPartnerHashData:deviceMessage.payload[3]];
        
        //respond with the next message in the protocol
        DeviceMessage* response = [ConfirmConnectionMessage confirmConnectionMessageWithSecretKeyData:self.secretData inThread:self.threadID senderDevice:[MynigmaDevice currentDeviceInContext:deviceMessage.managedObjectContext] targetDevice:deviceMessage.sender onLocalContext:deviceMessage.managedObjectContext isResponse:NO];
        
        [DeviceConnectionHelper postDeviceMessage:response intoAccountSetting:accountSetting];
        
        self.expectedMessageCommands = [NSSet setWithObject:@"1_ACK_CONFIRM_CONNECTION"];
        
        [AlertHelper showTrustEstablishmentProgress:3];
        
    }
    else if([messageKind isEqualToString:@"1_CONFIRM_CONNECTION"])
    {
        if(deviceMessage.payload.count<1)
        {
            NSLog(@"Error: message of kind 1_ACK_ANNOUNCE_INFO has insufficient payload data: %@", deviceMessage.payload);
            return;
        }
        
        if([deviceMessage.payload[0] length] == 64)
            [self setPartnerSecretData:deviceMessage.payload[0]];
        
        
        //make sure all the necessary data is there
        if(self.publicVerKeyData && self.publicEncKeyData && self.partnerPublicVerKeyData && self.partnerPublicEncKeyData && self.thisDeviceUUID && self.partnerDeviceUUID && self.secretData && self.partnerSecretData && self.partnerHashData && self.publicKeyLabel && self.partnerPublicKeyLabel)
        {
            //check that the hash is actually correct
            NSMutableData* dataToBeHashed = [NSMutableData dataWithData:self.partnerSecretData];
            
            [dataToBeHashed appendData:[self.partnerDeviceUUID dataUsingEncoding:NSUTF8StringEncoding]];
            
            NSData* computedHash = [AppleEncryptionWrapper SHA512DigestOfData:dataToBeHashed];
            
            if(![computedHash isEqual:self.partnerHashData])
            {
                NSLog(@"Invalid hash computed!!!");
                return;
            }
            
            NSMutableData* INFOData = [NSMutableData dataWithData:[self.publicKeyLabel dataUsingEncoding:NSUTF8StringEncoding]];
            
            [INFOData appendData:self.publicVerKeyData];
            
            [INFOData appendData:self.publicEncKeyData];
            
            [INFOData appendData:[self.thisDeviceUUID dataUsingEncoding:NSUTF8StringEncoding]];
            
            [INFOData appendData:self.secretData];
            
            [INFOData appendData:[self.partnerPublicKeyLabel dataUsingEncoding:NSUTF8StringEncoding]];
            
            [INFOData appendData:self.partnerPublicVerKeyData];
            
            [INFOData appendData:self.partnerPublicEncKeyData];
            
            [INFOData appendData:[self.partnerDeviceUUID dataUsingEncoding:NSUTF8StringEncoding]];
            
            [INFOData appendData:self.partnerSecretData];
            
            NSArray* shortDigestChunks = [AppleEncryptionWrapper shortDigestChunksOfData:INFOData];
            
            [ThreadHelper runAsyncOnMain:^{
                
                [AlertHelper showDigestChunks:shortDigestChunks withTargetDevice:[MynigmaDevice deviceWithUUID:self.partnerDeviceUUID inContext:MAIN_CONTEXT]];
            }];
            
            //respond with the next message in the protocol
            DeviceMessage* response = [ConfirmConnectionMessage confirmConnectionMessageWithSecretKeyData:self.secretData inThread:self.threadID senderDevice:[MynigmaDevice currentDeviceInContext:deviceMessage.managedObjectContext] targetDevice:deviceMessage.sender onLocalContext:deviceMessage.managedObjectContext isResponse:YES];
            
            [DeviceConnectionHelper postDeviceMessage:response intoAccountSetting:accountSetting];
            
            self.expectedMessageCommands = [NSSet set];
            
            [AlertHelper showTrustEstablishmentProgress:4];
        }
    }
    else if([messageKind isEqualToString:@"1_ACK_CONFIRM_CONNECTION"])
    {
        [self setPartnerSecretData:deviceMessage.payload[0]];
        
        //make sure all the necessary data is there
        if(self.publicEncKeyData && self.publicVerKeyData && self.partnerPublicVerKeyData && self.partnerPublicEncKeyData && self.thisDeviceUUID && self.partnerDeviceUUID && self.secretData && self.partnerSecretData && self.partnerHashData && self.publicKeyLabel && self.partnerPublicKeyLabel)
        {
            //check that the hash is actually correct
            NSMutableData* dataToBeHashed = [NSMutableData dataWithData:self.partnerSecretData];
            
            [dataToBeHashed appendData:[self.partnerDeviceUUID dataUsingEncoding:NSUTF8StringEncoding]];
            
            NSData* computedHash = [AppleEncryptionWrapper SHA512DigestOfData:dataToBeHashed];
            
            if(![computedHash isEqual:self.partnerHashData])
            {
                NSLog(@"Invalid hash computed!!!");
                return;
            }
            
            NSMutableData* INFOData = [NSMutableData dataWithData:[self.partnerPublicKeyLabel dataUsingEncoding:NSUTF8StringEncoding]];
            
            [INFOData appendData:self.partnerPublicVerKeyData];
            
            [INFOData appendData:self.partnerPublicEncKeyData];
            
            [INFOData appendData:[self.partnerDeviceUUID dataUsingEncoding:NSUTF8StringEncoding]];
            
            [INFOData appendData:self.partnerSecretData];
            
            [INFOData appendData:[self.publicKeyLabel dataUsingEncoding:NSUTF8StringEncoding]];
            
            [INFOData appendData:self.publicVerKeyData];
            
            [INFOData appendData:self.publicEncKeyData];
            
            [INFOData appendData:[self.thisDeviceUUID dataUsingEncoding:NSUTF8StringEncoding]];
            
            [INFOData appendData:self.secretData];
            
            NSArray* shortDigestChunks = [AppleEncryptionWrapper shortDigestChunksOfData:INFOData];
            
            [AlertHelper showTrustEstablishmentProgress:4];
            
            [ThreadHelper runAsyncOnMain:^{
                
                [AlertHelper showDigestChunks:shortDigestChunks withTargetDevice:[MynigmaDevice deviceWithUUID:self.partnerDeviceUUID inContext:MAIN_CONTEXT]];
            }];
        }
        
        self.expectedMessageCommands = [NSSet set];
    }
    else
    {
        NSLog(@"Unable to process device message with kind: %@", messageKind);
    }
}

- (void)postAckAnnounceInfoMessageAfterDeviceSyncKeyGeneration
{
    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {
        
        //this is the current device
        MynigmaDevice* currentDevice = [MynigmaDevice currentDeviceInContext:localContext];
        
        MynigmaDevice* targetDevice = [MynigmaDevice deviceWithUUID:self.partnerDeviceUUID inContext:localContext];
        
        NSString* syncKeyLabel = currentDevice.syncKey.keyLabel;
        
        if(!syncKeyLabel)
        {
            NSLog(@"Cannot sync without key label");
            return;
        }
        
        NSArray* publicSyncKeyData = [MynigmaPublicKey dataForExistingMynigmaPublicKeyWithLabel:syncKeyLabel];
        
        if(publicSyncKeyData.count != 2)
        {
            NSLog(@"Cannot sync key: insufficient public key data(!!)");
            return;
        }
        
        NSData* publicKeyEncData = publicSyncKeyData.firstObject;
        
        NSData* publicKeyVerData = publicSyncKeyData.lastObject;
        
        //public key data
        self.publicVerKeyData = publicKeyVerData;
        
        self.publicEncKeyData = publicKeyEncData;
        
        self.publicKeyLabel = syncKeyLabel;
        
        //some secret data
        self.secretData = [AppleEncryptionWrapper randomBytesOfLength:64];
        
        //hash the secret data, followed by the device UUID
        NSMutableData* dataToBeHashed = [NSMutableData dataWithData:self.secretData];
        
        NSData* UUIDData = [currentDevice.deviceId dataUsingEncoding:NSUTF8StringEncoding];
        
        [dataToBeHashed appendData:UUIDData];
        
        //the hash: hash(secret||UUID)
        NSData* hashedData = [AppleEncryptionWrapper SHA512DigestOfData:dataToBeHashed];
        
        //respond with the next message in the protocol
        DeviceMessage* response = [AnnounceInfoDeviceMessage announceInfoMessageWithPublicKeyEncData:publicKeyEncData verData:publicKeyVerData keyLabel:syncKeyLabel hashData:hashedData threadID:self.threadID senderDevice:currentDevice targetDevice:targetDevice onLocalContext:localContext isResponse:YES];
        
        IMAPAccountSetting* accountSetting = (IMAPAccountSetting*)[localContext existingObjectWithID:self.accountSettingObjectID error:nil];
        
        [DeviceConnectionHelper postDeviceMessage:response intoAccountSetting:accountSetting];
        
        self.expectedMessageCommands = [NSSet setWithObject:@"1_CONFIRM_CONNECTION"];
        
        [AlertHelper showTrustEstablishmentProgress:2];
    }];
}


- (DeviceMessage*)constructNewStartThreadMessageWithSenderDevice:(MynigmaDevice*)senderDevice targetDevice:(MynigmaDevice*)targetDevice inContext:(NSManagedObjectContext*)localContext
{
    if(!targetDevice)
    {
        return nil;
    }
    
    NSString* syncKeyLabel = senderDevice.syncKey.keyLabel;
    
    if(!syncKeyLabel)
    {
        NSLog(@"Cannot sync without key label");
        return nil;
    }
    
    NSArray* publicSyncKeyData = [MynigmaPublicKey dataForExistingMynigmaPublicKeyWithLabel:syncKeyLabel];
    
    if(publicSyncKeyData.count != 2)
    {
        NSLog(@"Cannot sync key: insufficient public key data(!!)");
        return nil;
    }
    
    
    NSData* publicKeyEncData = publicSyncKeyData.firstObject;
    
    NSData* publicKeyVerData = publicSyncKeyData.lastObject;
    
    TrustEstablishmentThread* newThread = self;
    NSString* newThreadID = newThread.threadID;
    
    //set the key data
    newThread.publicVerKeyData = publicKeyVerData;
    
    newThread.publicEncKeyData = publicKeyEncData;
    
    newThread.thisDeviceUUID = senderDevice.deviceId;
    
    newThread.partnerDeviceUUID = targetDevice.deviceId;
    
    //the ID of the current device
    NSData* UUIDData = [senderDevice.deviceId dataUsingEncoding:NSUTF8StringEncoding];
    
    //some secret, random data
    newThread.secretData = [AppleEncryptionWrapper randomBytesOfLength:64];
    
    //hash the secret data followed by the UUID
    NSMutableData* dataToBeHashed = [NSMutableData dataWithData:newThread.secretData];
    
    [dataToBeHashed appendData:UUIDData];
    
    NSData* hashedData = [AppleEncryptionWrapper SHA512DigestOfData:dataToBeHashed];
    
    //the new device message
    DeviceMessage* newMessage = [AnnounceInfoDeviceMessage announceInfoMessageWithPublicKeyEncData:publicKeyEncData verData:publicKeyVerData keyLabel:syncKeyLabel hashData:hashedData threadID:newThreadID senderDevice:senderDevice targetDevice:targetDevice onLocalContext:localContext isResponse:NO];
    
    return newMessage;
}

- (void)postStartThreadMessageAfterDeviceSyncKeyGeneration
{
    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext)
     {
         MynigmaDevice* targetDevice = [MynigmaDevice deviceWithUUID:self.partnerDeviceUUID inContext:localContext];
         
         //this is the current device
         MynigmaDevice* currentDevice = [MynigmaDevice currentDeviceInContext:localContext];
         
         DeviceMessage* newMessage = [self constructNewStartThreadMessageWithSenderDevice:currentDevice targetDevice:targetDevice inContext:localContext];
         
         //put a device message instance into each account used by the target device
         NSSet* targetAccounts = targetDevice.usingAccounts;
         
         if(targetAccounts.count>0)
         {
             [DeviceConnectionHelper postDeviceMessage:newMessage intoAccountSettings:targetAccounts inContext:localContext];
         }
         else
         {
             //default to all accounts
             [DeviceConnectionHelper postDeviceMessage:newMessage intoAllAccountsInContext:localContext];
         }
         
         [localContext save:nil];
         
         [ThreadHelper runAsyncOnMain:^{
             
             [MergeLocalChangesHelper mergeAllDeviceMessages];
             
             [AlertHelper showTrustEstablishmentProgress:2];
         }];
     }];
    
}

+ (void)startNewThreadWithTargetDeviceUUID:(NSString*)targetDeviceUUID withCallback:(void(^)(NSString* newThreadID))callback;
{
    [ThreadHelper ensureMainThread];
    
    [ThreadHelper runAsyncOnMain:^{
        
        [AlertHelper showTrustEstablishmentProgress:0];
    }];
    
    //generate a new threadID
    NSString* newThreadID = [@"thread@threadID.com" generateMessageID];
    
    //the new thread
    TrustEstablishmentThread* newThread = [TrustEstablishmentThread new];
    [newThread setThreadID:newThreadID];
    
    //add it to the thread lookup dictionary
    [TrustEstablishmentThread addThread:newThread withID:newThreadID];
    
    [ThreadHelper runAsyncOnMain:^{
        
        [AlertHelper showTrustEstablishmentProgress:1];
    }];
    
    MynigmaDevice* currentDeviceOnMain = [MynigmaDevice currentDevice];
    
    [newThread setThisDeviceUUID:currentDeviceOnMain.deviceId];
    [newThread setPartnerDeviceUUID:targetDeviceUUID];
    
    if(callback)
        callback(newThreadID);
    
    //ensure there is a device sync key present...
    NSMethodSignature* keyCompletionMethod = [TrustEstablishmentThread instanceMethodSignatureForSelector:@selector(postStartThreadMessageAfterDeviceSyncKeyGeneration)];
    
    NSInvocation* keyGenerationCompleted = [NSInvocation invocationWithMethodSignature:keyCompletionMethod];
    
    [keyGenerationCompleted setTarget:newThread];
    [keyGenerationCompleted setSelector:@selector(postStartThreadMessageAfterDeviceSyncKeyGeneration)];
    
    [MynigmaPrivateKey waitUntilDeviceKeyIsGeneratedForDeviceWithUUID:currentDeviceOnMain.deviceId andThenCall:keyGenerationCompleted];
}


//if a device message starting a new thread is found, this will create the appropriate DeviceMessageThread
+ (TrustEstablishmentThread*)newThreadWithFoundDeviceMessage:(DeviceMessage*)deviceMessage inContext:(NSManagedObjectContext*)localContext
{
    //generate a new threadID
    NSString* newThreadID = deviceMessage.threadID;
    
    //the new thread
    TrustEstablishmentThread* newThread = [TrustEstablishmentThread new];
    
    [newThread setThreadID:newThreadID];
    
    //add it to the thread lookup dictionary
    [TrustEstablishmentThread addThread:newThread withID:newThreadID];
    
    //this is the current device
    MynigmaDevice* currentDevice = [MynigmaDevice currentDeviceInContext:localContext];
    
    newThread.thisDeviceUUID = currentDevice.deviceId;
    
    newThread.partnerDeviceUUID = deviceMessage.sender.deviceId;
    
    return newThread;
}



+ (DeviceMessage*)sendKeyData_inResponseToMessage:(DeviceMessage*)confirmAcknowledgeAccountMessage withSecretKeyData:(NSData*)secretKeyData
{
    
    return nil;
}

+ (DeviceMessage*)sendKeyData_inResponseToMessage:(DeviceMessage*)confirmAcknowledgeAccountMessage withSecretKeyData:(NSData*)secretKeyData onLocalContext:(NSManagedObjectContext*)localContext
{
    
    return nil;
}

- (void)confirmMatch
{
    if(!self.partnerPublicKeyLabel || !self.partnerPublicEncKeyData || !self.partnerPublicVerKeyData || !self.partnerDeviceUUID)
    {
        NSLog(@"Unable to confirm match!!");
        return;
    }
    
    MynigmaDevice* partnerDevice = [MynigmaDevice deviceWithUUID:self.partnerDeviceUUID];
    
    [MynigmaPublicKey syncMakeNewPublicKeyWithEncKeyData:self.partnerPublicEncKeyData andVerKeyData:self.partnerPublicVerKeyData forDeviceWithUUID:self.partnerDeviceUUID keyLabel:self.partnerPublicKeyLabel];
    
    [partnerDevice setIsTrusted:@YES];
    
    [[MynigmaDevice currentDevice] setSyncDataStale:@YES];
    [[MynigmaDevice currentDevice] setSyncDataMessage:nil];
    
    [DeviceConnectionHelper postDeviceDiscoveryAndSyncDataMessages];
}


- (void)cancel
{
    self.expectedMessageCommands = [NSSet set];
}


@end
