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





#import "AppDelegate.h"





#import "MessageSyncHelper.h"
#import <MailCore/MailCore.h>
#import "EmailMessage+Category.h"
#import "IMAPFolderSetting+Category.h"
#import "IMAPAccount.h"
#import "EmailMessageData.h"
#import "GmailAccountSetting.h"
#import "GmailLabelSetting.h"
#import "MynigmaMessage+Category.h"
#import "FileAttachment+Category.h"
#import "EmailRecipient.h"
#import "MessageSieve.h"
#import "EmailContactDetail+Category.h"
#import "Contact+Category.h"
#import "EmailMessageInstance+Category.h"
#import "PublicKeyManager.h"
#import "RegistrationHelper.h"
#import "IMAPAccountSetting+Category.h"
#import "DeviceMessage+Category.h"
#import "MynigmaDevice+Category.h"
#import "DeviceConnectionHelper.h"
#import "AddressDataHelper.h"
#import "NSString+EmailAddresses.h"
#import "StoreFlagsOperation.h"
#import "AccountCheckManager.h"
#import "DisconnectOperation.h"
#import "StoreLabelsOperation.h"
#import "DownloadHelper.h"




@implementation MessageSyncHelper


#pragma mark -
#pragma mark GMAIL LABELS

+ (NSArray*)arrayOfLabelStringsForStoreMessageInstance:(EmailMessageInstance*)storeMessageInstance
{
    NSMutableArray* labelArray = [NSMutableArray new];
    for(IMAPFolderSetting* folder in storeMessageInstance.hasLabels)
    {
        if([folder isKindOfClass:[GmailLabelSetting class]])
        {
            NSString* labelName = [(GmailLabelSetting*)folder labelName];

            if(labelName)
                [labelArray addObject:labelName];
        }
    }

    return labelArray;
}

+ (NSSet*)labelStringsForStoreMessageInstance:(EmailMessageInstance*)storeMessageInstance
{
    return [storeMessageInstance.hasLabels valueForKey:@"labelName"];
}

+ (NSSet*)gmailLabelSettingsForServerMessage:(MCOIMAPMessage*)serverMessage withLocalAccountSetting:(IMAPAccountSetting*)localAccountSetting
{
    NSMutableSet* labelArray = [NSMutableSet new];
    for(IMAPFolderSetting* folder in localAccountSetting.folders)
    {
        if([folder isKindOfClass:[GmailLabelSetting class]])
        {
            if([(GmailLabelSetting*)folder labelName])
                if([serverMessage.gmailLabels containsObject:[(GmailLabelSetting*)folder labelName]])
                    [labelArray addObject:folder];
        }
    }
    return labelArray;
}



#pragma mark -
#pragma mark INDIVIDUAL MESSAGE SYNCHRONIZATION


/*
 + (void)moveServerMessage:(MCOIMAPMessage*)serverMessage fromFolderPath:(NSString*)sourceFolderPath withStoreMessageInstance:(EmailMessageInstance*)storeMessageInstance usingSession:(IMAPSessionHelper*)session localContext:(NSManagedObjectContext*)localContext
 {
 NSInteger uid = serverMessage.uid;

 NSString* destinationFolderPath = storeMessageInstance.inFolder.path;

 if([sourceFolderPath isEqualToString:destinationFolderPath])
 {
 return;
 }

 MCOIndexSet* indexSet = [MCOIndexSet indexSetWithIndex:uid];

 if(sourceFolderPath && destinationFolderPath && indexSet)
 {
 [session startSequenceOfOperations];

 [session copyMessagesWithFolder:sourceFolderPath uids:indexSet destFolder:destinationFolderPath withCallback:^(NSError *error, NSDictionary *resultDict)
 {
 if(error)
 {
 NSLog(@"Error moving message: %@", error);
 [session stopSequenceOfOperations];
 return;
 }
 else
 {

 [localContext performBlock:^{
 //[storeMessageInstance setMovedInAccount:nil];

 if(resultDict.count==1)
 {
 NSNumber* newUID = [resultDict allValues][0];
 [storeMessageInstance setUid:newUID];
 }
 else
 {
 NSLog(@"Result dict after moving message does not contain exactly one key-value pair: %@", resultDict);
 }
 }];

 [session storeFlagsWithFolder:sourceFolderPath uids:indexSet kind:MCOIMAPStoreFlagsRequestKindAdd flags:MCOMessageFlagDeleted withCallback:^(NSError *error)
 {
 if(!error)
 {
 [session expungeInFolder:sourceFolderPath withCallback:^(NSError* error)
 {
 [session stopSequenceOfOperations];
 }];
 }
 else
 [session stopSequenceOfOperations];

 }];
 }
 }];
 }
 }*/

+ (void)syncFlagsOnStoreMessageInstance:(EmailMessageInstance*)storeMessageInstance withServerMessage:(MCOIMAPMessage*)serverMessage inFolder:(IMAPFolderSetting*)localFolderSetting usingSession:(MCOIMAPSession*)passedSession disconnectOperation:(DisconnectOperation*)disconnectOperation withLocalContext:(NSManagedObjectContext*)localContext
{
    //[ThreadHelper ensureLocalThread:localContext];

    __block NSUInteger flagsInStore = storeMessageInstance.flags.unsignedIntegerValue%(1<<9);

    NSUInteger flagsOnServer = serverMessage.flags;
    //    NSUInteger uid = serverMessage.uid;

    if(flagsOnServer != flagsInStore)
    {
        if(!storeMessageInstance)
        {
            NSLog(@"No store message instance in sync flags method");
        }

        if(storeMessageInstance.flagsChangedInFolder) //the flags have been changed by the user, so update them on the server
        {
            //now done by MergeLocalChangesHelper

            //            if(storeMessageInstance.objectID.isTemporaryID)
            //            {
            //                [localContext obtainPermanentIDsForObjects:@[storeMessageInstance] error:nil];
            //            }
            //
            //            __block NSManagedObjectID* existingMessageID = storeMessageInstance.objectID;
            //            __block NSString* path = localFolderSetting.path;
            //
            //            StoreFlagsOperation* storeFlagsOperation = [StoreFlagsOperation storeFlagsWithFolderPath:path uids:[MCOIndexSet indexSetWithIndex:uid] kind:MCOIMAPStoreFlagsRequestKindSet flags:(MCOMessageFlag)flagsInStore usingSession:passedSession withCallback:^(NSError *error)
            //             {
            //                 if(!error)
            //                 {
            //                     [ThreadHelper runSyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {
            //
            //                         EmailMessageInstance* changedMessageInstance = [EmailMessageInstance messageInstanceWithObjectID:existingMessageID inContext:localContext];
            //
            //                         if(!changedMessageInstance)
            //                             NSLog(@"Failed to reconstruct message from object ID %@ after setting flags",existingMessageID);
            //                         else
            //                         {
            //                             [changedMessageInstance setFlagsChangedInFolder:nil];
            //                         }
            //                     }];
            //                 }
            //             }];
            //
            //            [storeFlagsOperation setLowPriority];
            //
            //            [storeFlagsOperation addToMailCoreQueueWithDisconnectOperation:disconnectOperation];
        }
        else //flags have changed on the server, probably by another client, so update the message object in the store
        {
            [storeMessageInstance setFlags:[NSNumber numberWithUnsignedInteger:flagsOnServer]];
            if((flagsOnServer & MCOMessageFlagSeen) && [storeMessageInstance isUnread])
                [storeMessageInstance markRead];
            if(!(flagsOnServer & MCOMessageFlagSeen) && ![storeMessageInstance isUnread])
                [storeMessageInstance markUnread];
        }
    }


    //update Gmail labels if necessary
    if([localFolderSetting isKindOfClass:[GmailLabelSetting class]])
    {
        NSSet* gmailLabelStringsOnServer = [NSSet setWithArray:serverMessage.gmailLabels];
        NSSet* gmailLabelStringsInStore = [MessageSyncHelper labelStringsForStoreMessageInstance:storeMessageInstance];
        if(![gmailLabelStringsInStore isEqualToSet:gmailLabelStringsOnServer])
        {
            if(storeMessageInstance.labelsChangedInFolder)
            {
                //now done by MergeLocalChangesHelper

                //                __block NSManagedObjectID* existingMessageID = storeMessageInstance.objectID;
                //                __block NSString* path = localFolderSetting.path;
                //
                //                NSArray* newLabels = [MessageSyncHelper arrayOfLabelStringsForStoreMessageInstance:storeMessageInstance];
                //
                //                StoreLabelsOperation* storeLabelsOperation = [StoreLabelsOperation storeLabelsWithFolderPath:path uids:[MCOIndexSet indexSetWithIndex:uid] labels:newLabels kind:MCOIMAPStoreFlagsRequestKindSet usingSession:passedSession withCallback:^(NSError* error){
                //                     if(!error)
                //                     {
                //                         [ThreadHelper runSyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {
                //
                //                             EmailMessageInstance* changedMessageInstance = [EmailMessageInstance messageInstanceWithObjectID:existingMessageID inContext:localContext];
                //
                //                             if(!changedMessageInstance)
                //                                 NSLog(@"Failed to reconstruct message from object ID %@ after setting flags",existingMessageID);
                //                             else
                //                             {
                //                                 [changedMessageInstance setLabelsChangedInFolder:nil];
                //                             }
                //                         }];
                //                     }
                //                 }];
                //
                //                [storeLabelsOperation setLowPriority];
                //
                //                [storeLabelsOperation addToMailCoreQueueWithDisconnectOperation:disconnectOperation];
            }
            else
            {
                [storeMessageInstance removeHasLabels:storeMessageInstance.hasLabels];
                [storeMessageInstance addHasLabels:[MessageSyncHelper gmailLabelSettingsForServerMessage:serverMessage withLocalAccountSetting:localFolderSetting.inIMAPAccount]];
            }
        }
    }
}


#pragma mark - HTML part ID extraction

+ (NSSet*)htmlPartsForIMAPPart:(MCOAbstractPart*)imapPart
{
    if([imapPart isKindOfClass:[MCOIMAPMultipart class]])
    {
        NSMutableSet* result = [NSMutableSet new];
        for(MCOIMAPPart* subPart in [(MCOMultipart*)imapPart parts])
        {
            [result unionSet:[MessageSyncHelper htmlPartsForIMAPPart:subPart]];
        }
        return result;
    }

    if([imapPart isKindOfClass:[MCOIMAPPart class]])
    {
        if([[imapPart.mimeType lowercaseString] isEqualToString:@"text/html"])
        {
            return [NSSet setWithObject:imapPart];
        }
    }
    return nil;
}

+ (NSSet*)plainTextPartsForIMAPPart:(MCOAbstractPart*)imapPart
{
    if([imapPart isKindOfClass:[MCOIMAPMultipart class]])
    {
        NSMutableSet* result = [NSMutableSet new];
        for(MCOIMAPPart* subPart in [(MCOMultipart*)imapPart parts])
        {
            [result unionSet:[MessageSyncHelper plainTextPartsForIMAPPart:subPart]];
        }
        return result;
    }

    if([imapPart isKindOfClass:[MCOIMAPPart class]])
    {
        if([[imapPart.mimeType lowercaseString] isEqualToString:@"text/plain"])
        {
            return [NSSet setWithObject:imapPart];
        }
    }
    return nil;
}

+ (void)findMessageMainPartIDForMessage:(EmailMessage*)message inIMAPMessage:(MCOIMAPMessage*)imapMessage
{
    NSSet* htmlParts = [MessageSyncHelper htmlPartsForIMAPPart:imapMessage.mainPart];
    if(htmlParts.count==1)
    {
        MCOIMAPPart* htmlPart = htmlParts.anyObject;
        [message.messageData setMainPartID:htmlPart.partID];
        [message.messageData setMainPartEncoding:@(htmlPart.encoding)];
        [message.messageData setMainPartType:htmlPart.mimeType];
    }
    else
    {
        NSSet* textParts = [MessageSyncHelper plainTextPartsForIMAPPart:imapMessage.mainPart];
        if(textParts.count==1)
        {
            MCOIMAPPart* textPart = textParts.anyObject;
            [message.messageData setMainPartID:textPart.partID];
            [message.messageData setMainPartEncoding:@(textPart.encoding)];
            [message.messageData setMainPartType:textPart.mimeType];
        }
    }
}


#pragma mark - Populating a message

+ (void)populateMessageInstance:(EmailMessageInstance *)messageInstance withCoreMessage:(MCOIMAPMessage *)imapMessage inFolder:(IMAPFolderSetting *)folderSetting andContext:(NSManagedObjectContext *)localContext
{
    //set labels
    if([folderSetting.inIMAPAccount isKindOfClass:[GmailAccountSetting class]])
    {
        if(messageInstance.hasLabels.count>0)
            [messageInstance removeHasLabels:messageInstance.hasLabels];
        [messageInstance addHasLabels:[MessageSyncHelper gmailLabelSettingsForServerMessage:imapMessage withLocalAccountSetting:folderSetting.inIMAPAccount]];
    }

    //set uid, messageID, etc...
    if(imapMessage.uid>0)
        [messageInstance changeUID:@(imapMessage.uid)];

    [messageInstance setDeletedFromFolder:nil];

    //set the flags (and unread status, if applicable...)
    NSUInteger flags = imapMessage.flags;

    if(flags & MCOMessageFlagSeen)
    {
        //not unread
        [messageInstance setUnreadInFolder:nil];
        if([folderSetting.inIMAPAccount isKindOfClass:[GmailAccountSetting class]])
        {
            [messageInstance removeUnreadWithLabels:messageInstance.unreadWithLabels];
        }
    }
    else
    {
        //unread!
        [messageInstance setUnreadInFolder:messageInstance.inFolder];
        if([folderSetting.inIMAPAccount isKindOfClass:[GmailAccountSetting class]])
        {
            [messageInstance addUnreadWithLabels:messageInstance.hasLabels];
        }
    }

    [messageInstance setFlags:[NSNumber numberWithUnsignedInteger:flags]];

    if([messageInstance isSafe])
    {
        [messageInstance setImportant:[NSNumber numberWithBool:YES]];
    }

    BOOL messageIsSentBySelf = messageInstance.inFolder.sentForAccount?YES:NO;
    if([imapMessage.header.from.mailbox isUsersAddress])
        messageIsSentBySelf = YES;
    if(messageIsSentBySelf)
        [messageInstance setImportant:[NSNumber numberWithBool:YES]];
}

+ (void)populateMessage:(EmailMessage*)message withCoreMessage:(MCOIMAPMessage*)imapMessage inFolder:(IMAPFolderSetting*)folderSetting andContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    NSString* senderEmail = imapMessage.header.from.mailbox;

    NSArray* allExtraHeaderKeys = imapMessage.header.allExtraHeadersNames;

    if(allExtraHeaderKeys.count>0)
    {
        NSString* keyLabelHeaderName = @"X-Myn-KL";
        NSString* pkHeaderName = @"X-Myn-PK";
        
        NSString* publicKeyString = nil;
        NSString* keyLabelString = nil;

        for(NSString* extraHeaderKey in allExtraHeaderKeys)
        {
            if([extraHeaderKey.lowercaseString isEqual:pkHeaderName.lowercaseString])
                publicKeyString = [imapMessage.header extraHeaderValueForName:extraHeaderKey];
            
            if([extraHeaderKey.lowercaseString isEqual:keyLabelHeaderName.lowercaseString])
                keyLabelString = [imapMessage.header extraHeaderValueForName:keyLabelHeaderName];
            
        }
        
        if (keyLabelString && publicKeyString && senderEmail)
            [PublicKeyManager handleHeaderRepresentationOfPublicKey:publicKeyString withKeyLabel:keyLabelString fromEmail:senderEmail];
      
    }

    [message setMessageid:imapMessage.header.messageID];

    if(imapMessage.header.date)
        [message setDateSent:imapMessage.header.date];
    else
    {
        if(imapMessage.header.receivedDate)
            [message setDateSent:imapMessage.header.receivedDate];
        else
            [message setDateSent:[NSDate date]];
    }

    //could change this to NO to prompt user before downloading remote images (or set it to YES only if the sender is known etc...)
    [message.messageData setLoadRemoteImages:[NSNumber numberWithBool:YES]];

    [message.messageData setHasImages:[NSNumber numberWithBool:NO]];


    //if the seen flag is set then the message isn't unread, it's seen...


    [MessageSyncHelper findMessageMainPartIDForMessage:message inIMAPMessage:imapMessage];


    if([message isSafe])
    {
        NSString* fromName = @"";
        MCOAddress* record = imapMessage.header.from;
        if(record)
        {
            if(record.displayName && record.displayName.length>0)
                fromName = record.displayName;
            else
                fromName = record.mailbox;

            //            if(record.mailbox)
            //            {
            //                EmailRecipient* senderAsEmailRecipient = [EmailRecipient new];
            //                [senderAsEmailRecipient setName:record.displayName?record.displayName:record.mailbox];
            //                [senderAsEmailRecipient setEmail:record.mailbox];
            //
            //                [message.messageData setAddressData:[AddressDataHelper addressDataForEmailRecipients:@[senderAsEmailRecipient]]];
            //            }
        }
        [message.messageData setFromName:fromName];

        //this will be updated and overwritten once the message has been decrypted
        [MessageSieve setAddressDataAndSearchStringForMessage:imapMessage intoMessage:message inContext:localContext];

        //attachments - for MynigmaMessages file name, contentid etc. of the attachments are encoded in the mynAttachment payload. Only the encrypted data is contained in the actual attachments so that it can be downloaded separately
        //the FileAttachment objects will be created during decryption, which will trigger a singleAttachmentDownload. This in turn will instigate decryption of the attachment data, once downloaded...
        //thus need only find the mynAttachment at this stage
        
        NSMutableArray* attachments = [imapMessage.attachments mutableCopy];
        
        [attachments addObjectsFromArray:imapMessage.htmlInlineAttachments];

        for(MCOAbstractPart* attachment in attachments)
        {
            if([attachment.filename isEqualToString:@"Secure message.myn"])
            {
                //this will happen when !IS_IN_TESTING_MODE
                if([attachment isKindOfClass:[MCOIMAPPart class]])
                {
                    MCOIMAPPart* imapPart = (MCOIMAPPart*)attachment;
                    [(MynigmaMessage*)message setMynDataPartID:imapPart.partID];
                    if(imapPart.encoding!=MCOEncodingBase64)
                        NSLog(@"Secure message.myn encoding is not base64: %ld!!!", (long)imapPart.encoding);
                }
            }
            else if([attachment.filename hasSuffix:@"myn"])
            {
                NSEntityDescription *entity = [NSEntityDescription entityForName:@"FileAttachment" inManagedObjectContext:localContext];
                FileAttachment* addedAttachment = [[FileAttachment alloc] initWithEntity:entity insertIntoManagedObjectContext:localContext];

                //set the status code to added: when the main part is decrypted this will be changed to the appropriate value, provided that the attachment appears in the list - if it was added by Mallory the result will remain DECRYPTION_RESULT_ATTACHMENT_ADDED
                [addedAttachment setDecryptionStatus:@""];

                [addedAttachment setFileName:attachment.filename];
                [addedAttachment setContentid:attachment.contentID];
                [addedAttachment setUniqueID:attachment.uniqueID];
                [addedAttachment setDownloadProgress:@0];
                [(MynigmaMessage*)message addAllAttachmentsObject:addedAttachment];
                if([attachment isKindOfClass:[MCOIMAPPart class]])
                {
                    MCOIMAPPart* imapPart = (MCOIMAPPart*)attachment;
                    [addedAttachment setPartID:imapPart.partID];

                    //[addedAttachment setSize:[NSNumber numberWithUnsignedInteger:imapPart.size]];
                    [addedAttachment setEncoding:[NSNumber numberWithInt:imapPart.encoding]];
                }
                else if([attachment isKindOfClass:[MCOAttachment class]])
                {
                    MCOAttachment* mcoAtt = (MCOAttachment*)attachment;
                    if(mcoAtt.data)
                    {
                        [addedAttachment saveAndDecryptData:mcoAtt.data];
                    }
                }
            }
        }

    }
    else
    {
        NSString* subject = imapMessage.header.subject;

        NSArray* subjectComponents = [subject componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

        subject = [subjectComponents componentsJoinedByString:@""];

        [message.messageData setSubject:subject];

        if(message.attachments.count)
        {

        }


        //explicit attachments
        for(MCOIMAPPart* attachment in imapMessage.attachments)
        {
            if([attachment isKindOfClass:[MCOIMAPPart class]])
            {
                NSEntityDescription *entity = [NSEntityDescription entityForName:@"FileAttachment" inManagedObjectContext:localContext];
                FileAttachment* addedAttachment = [[FileAttachment alloc] initWithEntity:entity insertIntoManagedObjectContext:localContext];
                [addedAttachment setFileName:attachment.filename];
                [addedAttachment setContentid:attachment.contentID];
                [addedAttachment setPartID:attachment.partID];
                [addedAttachment setUniqueID:attachment.uniqueID];
                [addedAttachment setSize:[NSNumber numberWithUnsignedInteger:attachment.size]];
                [addedAttachment setDownloadProgress:@0];

                //TO DO: process the signature instead, then remove it from the list of displayed attachments
                BOOL isInlineAndCanBeDisplayed = attachment.inlineAttachment && [addedAttachment isAnImage];

                if(!isInlineAndCanBeDisplayed && ![[attachment.filename lowercaseString] isEqualToString:@"signature.asc"] && ![[attachment.filename lowercaseString] isEqualToString:@"smime.p7s"])
                    [addedAttachment setAttachedToMessage:message];

                [addedAttachment setAttachedAllToMessage:message];
                [addedAttachment setEncoding:[NSNumber numberWithInt:attachment.encoding]];
            }
        }

        //inline attachments
        for(MCOIMAPPart* attachment in imapMessage.htmlInlineAttachments)
        {
            if([attachment isKindOfClass:[MCOIMAPPart class]])
            {
                NSEntityDescription *entity = [NSEntityDescription entityForName:@"FileAttachment" inManagedObjectContext:localContext];
                FileAttachment* addedAttachment = [[FileAttachment alloc] initWithEntity:entity insertIntoManagedObjectContext:localContext];
                [addedAttachment setFileName:attachment.filename];
                [addedAttachment setContentid:attachment.contentID];
                [addedAttachment setPartID:attachment.partID];
                [addedAttachment setUniqueID:attachment.uniqueID];
                [addedAttachment setSize:[NSNumber numberWithUnsignedInteger:attachment.size]];
                [addedAttachment setDownloadProgress:@0];

                //TO DO: process the signature instead, then remove it from the list of displayed attachments
                BOOL isInlineAndCanBeDisplayed = attachment.inlineAttachment && [addedAttachment isAnImage];

                if(!isInlineAndCanBeDisplayed && ![[attachment.filename lowercaseString] isEqualToString:@"signature.asc"] && ![[attachment.filename lowercaseString] isEqualToString:@"smime.p7s"])
                    [addedAttachment setAttachedToMessage:message];

                [addedAttachment setAttachedAllToMessage:message];
                [addedAttachment setEncoding:[NSNumber numberWithInt:attachment.encoding]];
            }
        }

        [MessageSieve setAddressDataAndSearchStringForMessage:imapMessage intoMessage:message inContext:localContext];
    }

    if([message isKindOfClass:[DeviceMessage class]])
    {
        if(VERBOSE_TRUST_ESTABLISHMENT)
        {
            DeviceMessage* deviceMessage = (DeviceMessage*)message;
            NSLog(@"Received device message! %@", deviceMessage);
        }

        //it's a device message!
        if(allExtraHeaderKeys.count>0)
        {
            NSDictionary* headerInfos =
            @{
              @"X-Mynigma-Device-ThreadID" : WRAP([imapMessage.header extraHeaderValueForName:@"X-Mynigma-Device-ThreadID"]),
              @"X-Mynigma-Device-Sender" : WRAP([imapMessage.header extraHeaderValueForName:@"X-Mynigma-Device-Sender"]),
              @"X-Mynigma-Device-Targets" : WRAP([[imapMessage.header extraHeaderValueForName:@"X-Mynigma-Device-Targets"] componentsSeparatedByString:@","]),
              @"X-Mynigma-Device-Command" : WRAP([imapMessage.header extraHeaderValueForName:@"X-Mynigma-Device-Command"])
            };

            [(DeviceMessage*)message parseHeaderInfos:headerInfos inContext:localContext];

            //check if this device is targeted to the current device
            if([(DeviceMessage*)message isTargetedToThisDeviceInContext:localContext])
            {
                //can only download on main, but the local context has not yet been saved

                NSError* error = nil;

                [localContext save:&error];

                if(error)
                    NSLog(@"Error saving local context: %@", error);

                NSManagedObjectID* messageObjectID = message.objectID;

                [ThreadHelper runAsyncOnMain:^{

                    EmailMessage* messageOnMain = [EmailMessage messageWithObjectID:messageObjectID inContext:MAIN_CONTEXT];

                    if(VERBOSE_TRUST_ESTABLISHMENT)
                    {
                        DeviceMessage* deviceMessage = (DeviceMessage*)messageOnMain;
                        NSLog(@"Queued device message for download: %@", deviceMessage.messageCommand);
                    }
                    
                    [DownloadHelper downloadMessage:messageOnMain urgent:YES];
                }];
            }
        }
    }
}




+ (void)processUpdatedFlagsForMessage:(MCOIMAPMessage*)serverMessage inFolder:(IMAPFolderSetting*)localFolderSetting withContext:(NSManagedObjectContext*)localContext usingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation *)disconnectOperation newMessageInstancesArray:(NSMutableArray *)newMessages
{
    [ThreadHelper ensureLocalThread:localContext];

    NSString* messageID = serverMessage.header.messageID;

    NSNumber* uid = @(serverMessage.uid);

    EmailMessageInstance* storeMessageInstance = [EmailMessageInstance findExistingInstanceWithMessageID:messageID andUid:uid inFolder:localFolderSetting inContext:localContext];

    if(!storeMessageInstance)
    {
        //might be moved or deleted
        //TO DO: for moved messages, sync flags with move destination instead
        return;
    }

    [MessageSyncHelper syncFlagsOnStoreMessageInstance:storeMessageInstance withServerMessage:serverMessage inFolder:localFolderSetting usingSession:session disconnectOperation:(DisconnectOperation *)disconnectOperation withLocalContext:localContext];
}

//processes a downloaded server message
//returns YES iff the message is new, recent and unread
//+ (BOOL)processDownloadedServerMessage:(MCOIMAPMessage*)serverMessage inFolder:(IMAPFolderSetting*)localFolderSetting withContext:(NSManagedObjectContext*)localContext usingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation newMessageInstancesArray:(NSMutableArray*)newMessages UIDCollection:(NSIndexSet*)UIDCollection
//{
//    [ThreadHelper ensureLocalThread:localContext];
//
//    BOOL hasBeenFound = NO;
//
//    BOOL isSafe = [serverMessage.header extraHeaderValueForName:@"X-Mynigma-Safe-Message"]!=nil;
//
//    BOOL isDeviceMessage = [serverMessage.header extraHeaderValueForName:@"X-Mynigma-Device-Message"]!=nil;
//
//
//#if ULTIMATE
//    //if the account hasn't been verified this could be a welcome message that has somehow ended up in an odd folder - check!
//    IMAPAccountSetting* localAccountSetting = localFolderSetting.inIMAPAccount;
//    IMAPAccount* account = [MODEL accountForSettingID:localAccountSetting.objectID];
//    if(!localAccountSetting.hasBeenVerified.boolValue)
//        [account.registrationHelper checkIfMessageIsWelcomeMail:serverMessage];
//#endif
//
//
//    NSString* messageID = serverMessage.header.messageID;
//
//    NSNumber* uid = serverMessage.uid>0?@(serverMessage.uid):nil;
//
//    //check if there is a deleted message - or one that has been moved away to a different folder - in the store
//    //if so, don't do anything: the server will be told about the local changes later
//    if([EmailMessageInstance haveRemovedInstanceWithMessageID:messageID andUid:uid inFolder:localFolderSetting inContext:localContext])
//        return NO;
//
//
//    //Sometimes a message will have no messageID, and mailcore will assign one. The problem is that each fetch will cause a new messageID to be created. To counteract this don't put more than one message with any given UID in the same folder, even if they have different messageIDs
//    //TO DO: one might want to sync flags even if the messageID is different, but the potential for something to go wrong is probably greater than the benefit...
////    if([EmailMessageInstance haveInstanceWithUid:uid inFolder:localFolderSetting UIDCollection:UIDCollection])
////    {
////        NSLog(@"Already found a different message with the UID %@ in folder %@", uid, localFolderSetting.displayName);
////        return NO;
////    }
//
//    EmailMessage* storeMessage = [EmailMessage findOrMakeMessageWithMessageID:messageID inContext:localContext isSafe:isSafe isDeviceMessage:isDeviceMessage messageFound:&hasBeenFound];
//
//
//    EmailMessageInstance* storeMessageInstance = [EmailMessageInstance findOrMakeNewInstanceForMessage:storeMessage inFolder:localFolderSetting withUID:@(serverMessage.uid) inContext:localContext];
//
//
//
//    if(!storeMessage || !storeMessageInstance)
//    {
//        NSLog(@"Store message could not be found or created! Server message: %@, %@", serverMessage, storeMessageInstance);
//        return NO;
//    }
//
//    BOOL returnValue = NO;
//
//    if(hasBeenFound) //there was a message already in the store
//    {
//        [MessageSyncHelper syncFlagsOnStoreMessageInstance:storeMessageInstance withServerMessage:serverMessage inFolder:localFolderSetting usingSession:session disconnectOperation:disconnectOperation withLocalContext:localContext];
//    }
//    else //a new message has been added to the store, so copy the server message's contents into the freshly created store message
//    {
//        //[MessageSyncHelper populateMessageInstance:storeMessageInstance withCoreMessage:serverMessage inFolder:localFolderSetting andContext:localContext];
//
//        NSInteger flags = serverMessage.flags;
//
//        NSInteger seenFlag = flags & MCOMessageFlagSeen;
//
//        if(seenFlag == 0)
//            if([storeMessageInstance isInAllMailFolder] || [storeMessageInstance isInInboxFolder])
//            {
//                //post a user notification, provided that the message is recent (less than a week old)
//                if([serverMessage.header.date timeIntervalSinceNow]>-24*60*60*7)
//                {
//                    NSManagedObjectID* objectID = storeMessageInstance.objectID;
//                    [MAIN_CONTEXT performBlockAndWait:^{
//                        [newMessages addObject:objectID];
//                    }];
//                    returnValue = YES;
//                }
//            }
//    }
//    
//    
//    if([storeMessage isSafe] && [storeMessageInstance isInSpamFolder])
//    {
//        //safe messages should be moved out of the spam folder
//        IMAPFolderSetting* allMailOrSpam = storeMessageInstance.accountSetting.allMailOrInboxFolder;
//        if(allMailOrSpam)
//            [storeMessageInstance moveToFolder:allMailOrSpam inContext:localContext];
//    }
//    
//    return returnValue;
//}

@end
