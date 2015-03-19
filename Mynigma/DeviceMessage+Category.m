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





#import "DeviceMessage+Category.h"
#import "EmailMessage+Category.h"
#import "AppDelegate.h"
#import "SendingManager.h"
#import "MynigmaDevice+Category.h"
#import "DataWrapHelper.h"
#import "EmailMessageData.h"
#import "AddressDataHelper.h"
#import "FormattingHelper.h"
#import "EmailMessageInstance+Category.h"
#import "IMAPAccountSetting+Category.h"
#import "TrustEstablishmentThread.h"
#import "DeviceConnectionHelper.h"
#import "FileAttachment+Category.h"
#import <MailCore/MailCore.h>
#import "GmailAccountSetting.h"
#import "NSData+Base64.h"
#import "UserSettings+Category.h"
#import "IMAPAccount.h"
#import "MergeLocalChangesHelper.h"
#import "MynigmaPublicKey+Category.h"
#import "EncryptionHelper.h"
#import "EmailMessage+Category.h"
#import "AlertHelper.h"
#import "NSString+EmailAddresses.h"
#import "Recipient.h"





//access to this private method in EncryptionHelper must be "granted" explicitly through a class extension
@interface EncryptionHelper()

+ (NSData*)encryptData:(NSData*)data withEncryptionKeyLabels:(NSArray*)encryptionKeyLabels expectedSignatureKeyLabels:(NSArray*)expectedSignatureKeyLabels signatureKeyLabel:(NSString*)signatureKeyLabel andAttachments:(NSArray*)attachments inContext:(NSManagedObjectContext*)localContext;

@end



@implementation DeviceMessage (Category)



#pragma mark - Status management

- (BOOL)isDownloaded
{
    return ([self payloadData]!=nil);
}

- (BOOL)isDeviceMessage
{
    return YES;
}






#pragma mark - Constructing device messages


//creates a new device message in the given context
+ (DeviceMessage*)constructNewDeviceMessageInContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    NSEntityDescription* entity = [NSEntityDescription entityForName:@"DeviceMessage" inManagedObjectContext:localContext];

    DeviceMessage* newMessage = [[DeviceMessage alloc] initWithEntity:entity insertIntoManagedObjectContext:localContext];

    entity = [NSEntityDescription entityForName:@"EmailMessageData" inManagedObjectContext:localContext];
    EmailMessageData* newMessageData = [[EmailMessageData alloc] initWithEntity:entity insertIntoManagedObjectContext:localContext];

    [newMessage setMessageData:newMessageData];

    [newMessageData setAddressData:[NSData new]];

    [newMessageData setHasImages:@NO];
    [newMessageData setLoadRemoteImages:@YES];

    NSString* messageID = [@"anonymous@mynigma.org" generateMessageID];

    [newMessage setMessageid:messageID];

    NSString* subjectString = [NSString stringWithFormat:NSLocalizedString(@"Internal Mynigma message",@"Device message subject")];

    [newMessageData setSubject:subjectString];

    NSURL* mynigmaMessageURL = [BUNDLE URLForResource:@"DeviceMessage" withExtension:@"html"];

    NSString* bodyString = [NSString stringWithContentsOfURL:mynigmaMessageURL encoding:NSUTF8StringEncoding error:nil];

    [newMessageData setHtmlBody:bodyString];

    NSError* error = nil;
    [localContext obtainPermanentIDsForObjects:@[newMessage] error:&error];
    if(error)
    {
        NSLog(@"Error obtaining permanent object ID for message with messageID %@", messageID);
    }

    [newMessage includeInAllMessagesDictInContext:localContext];

    return newMessage;
}


+ (void)deviceDiscoveryMessageWithCallback:(void(^)(DeviceMessage* deviceDiscoveryMessage))callback
{
    MynigmaDevice* currentDevice = [MynigmaDevice currentDevice];

    if(currentDevice.discoveryMessage)
    {
        callback(currentDevice.discoveryMessage);
        return;
    }

    [DeviceMessage constructNewDeviceDiscoveryMessageWithCallback:^(DeviceMessage* newDiscoveryMessage){

        [currentDevice setDiscoveryMessage:newDiscoveryMessage];

        callback(newDiscoveryMessage);

    }];
}


+ (DeviceMessage*)deviceDiscoveryMessageInContext:(NSManagedObjectContext*)localContext
{
    MynigmaDevice* currentDevice = [MynigmaDevice currentDeviceInContext:localContext];

    if(currentDevice.discoveryMessage)
    {
        return currentDevice.discoveryMessage;
    }

    DeviceMessage* newDiscoveryMessage = [DeviceMessage constructNewDeviceDiscoveryMessageInContext:localContext];

    [currentDevice setDiscoveryMessage:newDiscoveryMessage];

    return newDiscoveryMessage;
}


//creates a fresh device discovery message
//only call once to begin with and whenever the device's properties change
+ (void)constructNewDeviceDiscoveryMessageWithCallback:(void(^)(DeviceMessage* deviceDiscoveryMessage))callback
{
    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

        DeviceMessage* newMessage = [DeviceMessage constructNewDeviceDiscoveryMessageInContext:localContext];

        NSError* error = nil;
        [localContext save:&error];
        if(error)
            NSLog(@"Error saving temporary context creating device discovery message: %@",error);

        NSManagedObjectID* messageObjectID = newMessage.objectID;

        [ThreadHelper runAsyncOnMain:^{

            DeviceMessage* mainMessage = (DeviceMessage*)[MAIN_CONTEXT existingObjectWithID:messageObjectID error:nil];

            callback(mainMessage);

        }];
    }];
}


+ (DeviceMessage*)constructNewDeviceDiscoveryMessageInContext:(NSManagedObjectContext*)localContext
{
    //mark all previous device discovery messages as obsolete
    for(DeviceMessage* previousMessage in [DeviceMessage listAllDeviceMessagesInContext:localContext])
    {
        if([previousMessage.messageCommand isEqual:@"DEVICE_DISCOVERY"])
        {
            if([previousMessage.sender isEqual:[MynigmaDevice currentDeviceInContext:localContext]])
            {
                NSSet* allInstances = [NSSet setWithSet:previousMessage.instances];
                for(EmailMessageInstance* messageInstance in allInstances)
                {
                    //mark as deleted so it will be taken from the server
                    [messageInstance deleteInstanceInContext:localContext];
                }
            }
        }
    }

    DeviceMessage* newMessage = [DeviceMessage constructNewDeviceMessageInContext:localContext];

    [newMessage setBurnAfterReading:@NO];

    [newMessage setExpiryDate:nil];

    [newMessage setMessageCommand:@"DEVICE_DISCOVERY"];

    MynigmaDevice* currentDevice = [MynigmaDevice currentDeviceInContext:localContext];

    NSData* deviceDescription = [DataWrapHelper wrapDeviceDiscoveryData:currentDevice];

    [newMessage setPayload:@[deviceDescription]];

    [newMessage setSender:currentDevice];

    [newMessage setDateSent:[NSDate date]];

    return newMessage;
}


+ (DeviceMessage*)syncDataMessageFromDevice:(MynigmaDevice*)currentDevice inContext:(NSManagedObjectContext*)localContext
{
    if(!currentDevice)
    {
        NSLog(@"No device to make sync data package with(!!)");
        return nil;
    }

    if(!currentDevice.syncKey)
    {
        NSLog(@"No sync key for device %@", currentDevice);
        return nil;
    }

    if([currentDevice.syncDataStale isEqual:@NO] && currentDevice.syncDataMessage)
    {
        return currentDevice.syncDataMessage;
    }

    //either the synData is stale or no sync data message has been posted so far
    //create a fresh one

    NSMutableArray* encryptionKeyLabels = [NSMutableArray new];

    NSMutableSet* targetDevices = [NSMutableSet new];

    NSArray* deviceList = [MynigmaDevice listAllKnownDevices];

    for(MynigmaDevice* otherDevice in deviceList)
    {
        if(![otherDevice isEqual:currentDevice])
        {
            if(otherDevice.isTrusted.boolValue)
            {
                NSString* keyLabel = otherDevice.syncKey.keyLabel;

                if(keyLabel)
                {
                    [encryptionKeyLabels addObject:keyLabel];

                    [targetDevices addObject:otherDevice];
                }
            }
        }
    }

    if(encryptionKeyLabels.count == 0)
    {
        NSLog(@"Not sending sync data: no trusted devices");
        return nil;
    }

    NSString* signatureKeyLabel = currentDevice.syncKey.keyLabel;

    if(!signatureKeyLabel)
    {
        NSLog(@"Cannot post sync data without signature key!!");
        return nil;
    }

    NSData* unencryptedSyncDataPackage = [DataWrapHelper makeCompleteSyncDataPackage];

    NSData* encryptedData = [EncryptionHelper encryptData:unencryptedSyncDataPackage withEncryptionKeyLabels:encryptionKeyLabels expectedSignatureKeyLabels:@[signatureKeyLabel] signatureKeyLabel:signatureKeyLabel andAttachments:nil inContext:localContext];

    if(!encryptedData)
    {
        NSLog(@"Failed to encrypt payload for sync data");
        return nil;
    }

    DeviceMessage* newMessage = [DeviceMessage constructNewDeviceMessageInContext:localContext];

    [newMessage setBurnAfterReading:@NO];

    [newMessage setExpiryDate:nil];

    [newMessage setMessageCommand:@"SYNC_DATA"];

    [newMessage setPayload:@[encryptedData]];

    [newMessage setSender:currentDevice];

    [newMessage setDateSent:[NSDate date]];

    [newMessage setTargets:targetDevices];

    [currentDevice setSyncDataMessage:newMessage];
    [currentDevice setSyncDataStale:@NO];

    return newMessage;
}




//#pragma mark - Posting a device message
//
//- (void)postThisDeviceMessageIntoAccount:(IMAPAccountSetting*)accountSetting
//{
//    NSManagedObjectID* mainDeviceMessageObjectID = self.objectID;
//    NSManagedObjectID* mainAccountSettingObjectID = accountSetting.objectID;
//
//    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext)
//    {
//        IMAPAccountSetting* localAccountSetting = (IMAPAccountSetting*)[localContext existingObjectWithID:mainAccountSettingObjectID error:nil];
//
//        DeviceMessage* localDeviceMessage = (DeviceMessage*)[DeviceMessage messageWithObjectID:mainDeviceMessageObjectID inContext:localContext];
//
//        [localDeviceMessage postThisDeviceMessageIntoAccount:localAccountSetting inContext:localContext];
//
//        [MergeLocalChangesHelper mergeDeviceMessagesForAccount:localAccountSetting.account inFolder:localAccountSetting.mynigmaFolder];
//    }];
//}
//
//
//- (void)postThisDeviceMessageIntoAccount:(IMAPAccountSetting*)accountSetting inContext:(NSManagedObjectContext*)localContext
//{
//    [ThreadHelper ensureLocalThread:localContext];
//
//    NSData* deviceMessageData = [DataWrapHelper wrapDeviceMessage:self];
//
//    if(!deviceMessageData)
//    {
//        NSLog(@"No device message data!!");
//        return;
//    }
//
//    BOOL alreadyFoundOne = NO;
//
//    IMAPFolderSetting* folderSetting = accountSetting.mynigmaFolder;
//
//    EmailMessageInstance* newInstance = [EmailMessageInstance findOrMakeNewInstanceForMessage:self inFolder:folderSetting inContext:localContext alreadyFoundOne:&alreadyFoundOne];
//
//    if(alreadyFoundOne)
//        return;
//
//    [newInstance setAddedToFolder:newInstance.inFolder];
//
//    [newInstance setFlags:@(MCOMessageFlagSeen)];
//
//    NSError* error = nil;
//    [localContext save:&error];
//    if(error)
//        NSLog(@"Error saving temporary context after posting device messages: %@",error);
//}
//
//- (void)postThisDeviceMessageIntoAccounts:(NSSet*)accounts
//{
//    for(IMAPAccountSetting* accountSetting in accounts)
//    {
//        [self postThisDeviceMessageIntoAccount:accountSetting];
//    }
//}
//
//- (void)postThisDeviceMessageIntoAccounts:(NSSet*)accounts inContext:(NSManagedObjectContext*)localContext
//{
//    for(IMAPAccountSetting* accountSetting in accounts)
//    {
//        [self postThisDeviceMessageIntoAccount:accountSetting inContext:localContext];
//    }
//}
//
//- (void)postThisDeviceMessageIntoAllAccountsInContext:(NSManagedObjectContext*)localContext
//{
//    for(IMAPAccountSetting* accountSetting in [UserSettings usedAccountsInContext:localContext])
//    {
//        [self postThisDeviceMessageIntoAccount:accountSetting inContext:localContext];
//    }
//
//    return;
//}








#pragma mark - List all device messages

+ (NSArray*)listAllDeviceMessagesInContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DeviceMessage"];

    NSError* error = nil;

    NSArray* results = [localContext executeFetchRequest:fetchRequest error:&error];

    return results;
}




#pragma mark - Properties

- (BOOL)isTargetedToThisDeviceInContext:(NSManagedObjectContext*)localContext
{
    if(self.targets.count==0)
        return YES;

    MynigmaDevice* currentDevice = [MynigmaDevice currentDeviceInContext:localContext];

    return [self.targets containsObject:currentDevice];
}

- (BOOL)hasExpired
{
    //no expiry date means message cannot expire
    return [self.expiryDate compare:[NSDate date]] == NSOrderedAscending;
}


- (void)setPayload:(NSArray*)payload
{
    //archive the array into data
    NSData* newPayloadData = [NSKeyedArchiver archivedDataWithRootObject:payload];

    [self setPayloadData:newPayloadData];
}


- (NSArray*)payload
{
    if(!self.payloadData)
        return @[];

    //unarchive the array
    NSArray* newPayload = [NSKeyedUnarchiver unarchiveObjectWithData:self.payloadData];

    return newPayload;
}





#pragma mark - Processing device messages

//- (void)processDeviceData:(NSData*)data withAccount:(IMAPAccountSetting*)accountSetting
//{
//    [ThreadHelper ensureMainThread];
//
//    NSManagedObjectID* deviceMessageObjectID = self.objectID;
//
//    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {
//
//        DeviceMessage* deviceMessage = [DeviceMessage messageWithObjectID:deviceMessageObjectID inContext:localContext];
//
//        if([deviceMessage.messageCommand isEqual:@"DEVICE_DISCOVERY"])
//        {
//            [DataWrapHelper unwrapData:data intoDeviceMessage:deviceMessage];
//
//            if(deviceMessage.payload.count>0)
//            {
//                MynigmaDevice* newDevice = [DataWrapHelper unwrapDeviceDiscoveryData:deviceMessage.payload.firstObject withDate:deviceMessage.dateSent inContext:localContext];
//
//                if(newDevice && ![newDevice isEqual:[MynigmaDevice currentDevice]])
//                {
//                    [AlertHelper informUserAboutNewlyDiscoveredDevice:newDevice inAccountSetting:accountSetting];
//                }
//            }
//            return;
//        }
//
//        [DataWrapHelper unwrapData:data intoDeviceMessage:deviceMessage];
//
//        if([deviceMessage.messageCommand isEqual:@"1_ANNOUNCE_INFO"])
//        {
//            TrustEstablishmentThread* newThread = [TrustEstablishmentThread newThreadWithFoundDeviceMessage:deviceMessage inContext:localContext];
//
//            [newThread processDeviceMessage:deviceMessage inAccount:accountSetting];
//
//            return;
//        }
//
//        TrustEstablishmentThread* existingThread = [TrustEstablishmentThread threadWithID:deviceMessage.threadID];
//
//        [existingThread processDeviceMessage:deviceMessage inAccount:accountSetting];
//
//    }];
//}

- (void)processMessageWithAccountSetting:(IMAPAccountSetting*)accountSetting
{
    NSManagedObjectID* deviceMessageObjectID = self.objectID;

    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext)
     {

         DeviceMessage* deviceMessage = [DeviceMessage messageWithObjectID:deviceMessageObjectID inContext:localContext];
         
         if([deviceMessage.sender isEqual:[MynigmaDevice currentDeviceInContext:localContext]])
             return;
         
         if(![deviceMessage isTargetedToThisDeviceInContext:localContext])
             return;

         //device discovery require different processing: ask the user to confirm
         if([deviceMessage.messageCommand isEqual:@"DEVICE_DISCOVERY"])
         {
             if(deviceMessage.payload.count>0)
             {
                 MynigmaDevice* newDevice = [DataWrapHelper unwrapDeviceDiscoveryData:deviceMessage.payload.firstObject withDate:deviceMessage.dateSent inContext:localContext];

                 if(newDevice && ![newDevice isEqual:[MynigmaDevice currentDevice]])
                 {
                     [AlertHelper informUserAboutNewlyDiscoveredDevice:newDevice inAccountSetting:accountSetting];
                 }
             }
             return;
         }

         //find the right thread to process the device message
         TrustEstablishmentThread* thread = nil;

         if([deviceMessage.messageCommand isEqual:@"1_ANNOUNCE_INFO"])
         {
             //it's the first message, so we need to create the thread first
             thread = [TrustEstablishmentThread newThreadWithFoundDeviceMessage:deviceMessage inContext:localContext];
         }
         else
         {
             thread = [TrustEstablishmentThread threadWithID:deviceMessage.threadID];
         }

         [thread processDeviceMessage:deviceMessage inAccount:accountSetting];

     }];
}

- (void)parseDownloadedData:(NSData*)downloadedData
{
    [DataWrapHelper unwrapData:downloadedData intoDeviceMessage:self];
}

- (void)parseHeaderInfos:(NSDictionary*)headerInfos inContext:(NSManagedObjectContext*)localContext
{
    if(!headerInfos)
        return;

    NSString* threadID = headerInfos[HEADER_KEY_THREAD_ID];

    if([threadID isKindOfClass:[NSString class]])
        [self setThreadID:threadID];

    NSString* senderUUID = headerInfos[HEADER_KEY_SENDER_UUID];

    if([senderUUID isKindOfClass:[NSString class]])
        [self setSender:[MynigmaDevice deviceWithUUID:senderUUID addIfNotFound:YES inContext:localContext]];

    NSArray* targetUUIDs = headerInfos[HEADER_KEY_TARGET_UUIDS];

    [self removeTargets:self.targets];
    if([targetUUIDs isKindOfClass:[NSArray class]])
        for(NSString* targetUUID in targetUUIDs)
        {
            if([targetUUID isKindOfClass:[NSString class]])
                [self addTargetsObject:[MynigmaDevice deviceWithUUID:targetUUID addIfNotFound:YES inContext:localContext]];
        }

    NSString* deviceCommand = headerInfos[HEADER_KEY_MESSAGE_COMMAND];

    if([deviceCommand isKindOfClass:[NSString class]])
        [self setMessageCommand:deviceCommand];
}

- (NSDictionary*)headerInfo
{
    NSMutableDictionary* newHeaderInfo = [NSMutableDictionary new];

    if(self.threadID)
        newHeaderInfo[HEADER_KEY_THREAD_ID] = self.threadID;

    if(self.sender.deviceId)
        newHeaderInfo[HEADER_KEY_SENDER_UUID] = self.sender.deviceId;

    NSMutableArray* newTargetList = [NSMutableArray new];
    if(self.targets.count)
    {
        for(MynigmaDevice* target in self.targets)
            if(target.deviceId)
                [newTargetList addObject:target.deviceId];
    }
    newHeaderInfo[HEADER_KEY_TARGET_UUIDS] = newTargetList;

    if(self.messageCommand)
        newHeaderInfo[HEADER_KEY_MESSAGE_COMMAND] = self.messageCommand;

    return newHeaderInfo;
}



#pragma mark - Downloading

- (void)downloadUsingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation urgent:(BOOL)urgent alsoDownloadAttachments:(BOOL)withAttachments
{
    if([self isDownloaded])
    {
        //the message should have been processed already
        return;
    }

    //for device messages don't bother fetching the body, just the attachment containing the payload

    //there should only be one *explicit* (non-inline) attachment
    FileAttachment* payloadAttachment = self.attachments.anyObject;

    EmailMessageInstance* messageInstance = [self downloadableInstance];

    IMAPAccount* account = messageInstance.account;

    //device messages are always urgent
    session = account.quickAccessSession;
    disconnectOperation = nil;
    
    //don't download more than once(!)
    @synchronized(self)
    {
        if([self isDownloading] || [self isDownloaded])
            return;
        
        [self setIsDownloading:YES];
    }
    
    NSLog(@"-----> %@", self.objectID);
    
    [payloadAttachment downloadUsingSession:session disconnectOperation:disconnectOperation urgent:YES withCallback:^(NSData *data) {
        [ThreadHelper runAsyncOnMain:^{
            
            NSLog(@"<----- %@", self.objectID);
            
            if(data.length)
            {
                if(VERBOSE_TRUST_ESTABLISHMENT)
                {
                    NSLog(@"Downloaded device message: %@", self.messageCommand);
                }
                
                [(DeviceMessage*)self parseDownloadedData:data];
                [(DeviceMessage*)self processMessageWithAccountSetting:account.accountSetting];
            }
            else
            {
                NSLog(@"DeviceMessage attachment has no data!!!");
            }
            
            [self setIsDownloading:NO];
        }];
    }];
}



#pragma mark - Sending

- (NSError*)wrapIntoMessageBuilder:(MCOMessageBuilder*)messageBuilder
{
    NSMutableString* targetDeviceString = [NSMutableString new];

    for(MynigmaDevice* mynigmaDevice in self.targets)
    {
        NSString* deviceID = mynigmaDevice.deviceId;
        if(deviceID)
        {
            if(targetDeviceString.length==0)
            {
                [targetDeviceString appendString:deviceID];
            }
            else
            {
                [targetDeviceString appendFormat:@", %@", deviceID];
            }
        }
        else
            NSLog(@"MynigmaDevice has no device ID!!! %@", mynigmaDevice);
    }

    [[messageBuilder header] setExtraHeaderValue:@"Mynigma Device Message" forName:@"X-Mynigma-Device-Message"];

    if(targetDeviceString.length>0)
        [[messageBuilder header] setExtraHeaderValue:targetDeviceString forName:@"X-Mynigma-Device-Targets"];

    if(self.threadID)
        [[messageBuilder header] setExtraHeaderValue:self.threadID forName:@"X-Mynigma-Device-ThreadID"];

    if(self.messageCommand)
        [[messageBuilder header] setExtraHeaderValue:self.messageCommand forName:@"X-Mynigma-Device-Command"];

    if(self.sender.deviceId)
        [[messageBuilder header] setExtraHeaderValue:self.sender.deviceId forName:@"X-Mynigma-Device-Sender"];

    /*
     [[messageBuilder header] setSubject:deviceMessage.messageData.subject];
     [messageBuilder setHTMLBody:deviceMessage.messageData.htmlBody];
     */

    // Mynigma icon as inline attachment
    NSString* logoPath = [[NSBundle mainBundle] pathForResource:@"MynigmaIconForLetter" ofType:@"jpg"];
    NSData* logoData = [NSData dataWithContentsOfFile:logoPath];

    MCOAttachment* logoAttachment = [MCOAttachment attachmentWithData:logoData filename:@"MynigmaIconForLetter.jpg"];

    [logoAttachment setInlineAttachment:YES];
    [logoAttachment setContentID:@"TXluaWdtYUljb25Gb3JMZXR0ZXI@mynigma.org"];

    if(logoAttachment)
        [messageBuilder addRelatedAttachment:logoAttachment];

    NSString* subjectString = [NSString stringWithFormat:NSLocalizedString(@"Internal Mynigma message",@"Device message subject")];

    [messageBuilder.header setSubject:subjectString];

    NSURL* mynigmaMessageURL = [BUNDLE URLForResource:@"DeviceMessage" withExtension:@"html"];
    
    NSString* bodyString = [NSString stringWithContentsOfURL:mynigmaMessageURL encoding:NSUTF8StringEncoding error:nil];
    
    if(!bodyString)
    {
        NSLog(@"Error loading device message template!!");
        return nil;
    }
    
    [messageBuilder setHTMLBody:bodyString];
    
    Recipient* senderRecipient = [AddressDataHelper senderAsRecipientForMessage:self addIfNotFound:YES];
    
    MCOAddress* fromAddress = [MCOAddress addressWithDisplayName:senderRecipient.displayName?senderRecipient.displayName:senderRecipient.displayEmail mailbox:senderRecipient.displayEmail];
    
    if(!fromAddress)
    {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"Failed to wrap device message", nil), NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"No sending address set(!)", nil), NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"Please submit a bug report so we can fix the problem for you.", nil)};

        NSError* error = [NSError errorWithDomain:@"EmailMessage wrap for sending" code:1 userInfo:userInfo];

        return error;
    }
    
    [[messageBuilder header] setFrom:fromAddress];
    
    NSData* attachmentData = [DataWrapHelper wrapDeviceMessage:self];
    
    MCOAttachment* attachment = [MCOAttachment attachmentWithData:attachmentData filename:@"Device message.myn"];
    
    [attachment setMimeType:@"application/mynigma"];
    [attachment setInlineAttachment:NO];
    
    [messageBuilder addAttachment:attachment];

    //no error
    return nil;
}

@end
