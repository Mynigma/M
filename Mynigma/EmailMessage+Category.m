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





#import "EmailMessage+Category.h"
#import "EmailMessageData.h"
#import "EmailRecipient.h"
#import "AppDelegate.h"
#import "MynigmaMessage+Category.h"
#import "EncryptedMessage.h"
#import "EmailMessageInstance+Category.h"
#import "IMAPAccount.h"
#import "FileAttachment+Category.h"
#import "AddressDataHelper.h"
#import "FormattingHelper.h"
#import "IMAPAccountSetting+Category.h"
#import "IMAPFolderSetting+Category.h"
#import "DeviceMessage+Category.h"
#import "EmailMessageController.h"
#import "NSString+EmailAddresses.h"
#import "MynigmaFeedback.h"
#import "NSData+Base64.h"
#import "SelectionAndFilterHelper.h"
#import "EmailContactDetail+Category.h"
#import "Contact+Category.h"
#import "Recipient.h"
#import "MynigmaPublicKey+Category.h"
#import "PublicKeyManager.h"
#import "DownloadHelper.h"





static NSMutableSet* messagesBeingDownloaded_internal;
static NSMutableSet* messagesBeingDecrypted_internal;
static NSMutableSet* messagesBeingCleaned_internal;

static dispatch_queue_t statusDispatchQueue_internal;




@interface EmailMessageInstance()

- (void)downloadUsingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation urgent:(BOOL)urgent alsoDownloadAttachments:(BOOL)withAttachments;

@end




static NSMutableDictionary* allMessages;

static BOOL haveCollectedAllMessages;

static dispatch_queue_t emailMessageQueue;

@implementation EmailMessage (Category)

#pragma mark - Status management

+ (NSMutableSet*)messagesBeingDownloaded
{
    if(!messagesBeingDownloaded_internal)
    {
        messagesBeingDownloaded_internal = [NSMutableSet new];
    }

    return messagesBeingDownloaded_internal;
}

+ (NSMutableSet*)messagesBeingDecrypted
{
    if(!messagesBeingDecrypted_internal)
    {
        messagesBeingDecrypted_internal = [NSMutableSet new];
    }

    return messagesBeingDecrypted_internal;
}

+ (NSMutableSet*)messagesBeingCleaned
{
    if(!messagesBeingCleaned_internal)
    {
        messagesBeingCleaned_internal = [NSMutableSet new];
    }

    return messagesBeingCleaned_internal;
}

+ (dispatch_queue_t)statusDispatchQueue
{
    if(!statusDispatchQueue_internal)
    {
        statusDispatchQueue_internal = dispatch_queue_create("Mynigma_EmailMessage_status_queue", NULL);
    }

    return statusDispatchQueue_internal;
}


- (BOOL)isCleaning
{
    __block BOOL result = NO;

    NSManagedObjectID* ownObjectID = self.objectID;

    dispatch_sync([EmailMessage statusDispatchQueue], ^{

        result = [[EmailMessage messagesBeingCleaned] containsObject:ownObjectID];
    });

    return result;
}

- (BOOL)isDecrypting
{
    if([self isSafe])
    {
        __block BOOL result = NO;

        NSManagedObjectID* ownObjectID = self.objectID;

        dispatch_sync([EmailMessage statusDispatchQueue], ^{

            result = [[EmailMessage messagesBeingDecrypted] containsObject:ownObjectID];
        });

        //sanity check
        if(result && [self isDecrypted])
        {
            NSLog(@"Decrypted message is reporting that decryption is in progress!!");

            //in this case don't want to have a never-ending decryption status - in the long run need to resolve the problem that decryption status is not relinquished on decryption
            return NO;
        }

        if(result && ![self isDownloaded])
            NSLog(@"Message being decrypted is not downloaded!!");

        return result;
    }

    return NO;
}

- (BOOL)isDownloading
{
    __block BOOL result = NO;

    NSManagedObjectID* ownObjectID = self.objectID;

    dispatch_sync([EmailMessage statusDispatchQueue], ^{

        result = [[EmailMessage messagesBeingDownloaded] containsObject:ownObjectID];
    });

    //sanity check
    if(result && [self isDownloaded])
        NSLog(@"Downloading message that is already downloaded!!");

    if(result && [self isDecrypted])
        NSLog(@"Downloading message that is already decrypted!!");

    return result;
}

- (void)setIsDownloading:(BOOL)isDownloading
{
    NSManagedObjectID* ownObjectID = self.objectID;
    
    if(ownObjectID.isTemporaryID)
    {
        [self.managedObjectContext obtainPermanentIDsForObjects:@[self] error:nil];
        ownObjectID = self.objectID;
    }

    if(isDownloading)
    {
        dispatch_sync([EmailMessage statusDispatchQueue], ^{

            [[EmailMessage messagesBeingDownloaded] addObject:ownObjectID];
        });
    }
    else
    {
        dispatch_sync([EmailMessage statusDispatchQueue], ^{

            if([[EmailMessage messagesBeingDownloaded] containsObject:ownObjectID])
                [[EmailMessage messagesBeingDownloaded] removeObject:ownObjectID];
        });
    }

    for(EmailMessageInstance* messageInstance in self.instances)
    {
        NSManagedObjectID* messageInstanceObjectID = messageInstance.objectID;

        [SelectionAndFilterHelper refreshMessage:self.objectID];

        [SelectionAndFilterHelper refreshViewerShowingMessageInstanceWithObjectID:messageInstanceObjectID];
    }
}

- (void)setIsDecrypting:(BOOL)isDecrypting
{
    NSManagedObjectID* ownObjectID = self.objectID;

    if(isDecrypting)
    {
        dispatch_sync([EmailMessage statusDispatchQueue], ^{

            [[EmailMessage messagesBeingDecrypted] addObject:ownObjectID];
        });
    }
    else
    {
        dispatch_sync([EmailMessage statusDispatchQueue], ^{

            if([[EmailMessage messagesBeingDecrypted] containsObject:ownObjectID])
                [[EmailMessage messagesBeingDecrypted] removeObject:ownObjectID];
        });
    }

    for(EmailMessageInstance* messageInstance in self.instances)
    {
        NSManagedObjectID* messageInstanceObjectID = messageInstance.objectID;

        [SelectionAndFilterHelper refreshViewerShowingMessageInstanceWithObjectID:messageInstanceObjectID];
    }
}

- (void)setIsCleaning:(BOOL)isCleaning
{
    NSManagedObjectID* ownObjectID = self.objectID;

    if(isCleaning)
    {
        dispatch_sync([EmailMessage statusDispatchQueue], ^{

            [[EmailMessage messagesBeingCleaned] addObject:ownObjectID];
        });
    }
    else
    {
        dispatch_sync([EmailMessage statusDispatchQueue], ^{

            if([[EmailMessage messagesBeingCleaned] containsObject:ownObjectID])
                [[EmailMessage messagesBeingCleaned] removeObject:ownObjectID];
        });
    }

    for(EmailMessageInstance* messageInstance in self.instances)
    {
        NSManagedObjectID* messageInstanceObjectID = messageInstance.objectID;

        [SelectionAndFilterHelper refreshViewerShowingMessageInstanceWithObjectID:messageInstanceObjectID];
    }
}





- (BOOL)isDownloaded
{
    return [[self messageData] htmlBody]!=nil || [self isCleaning];
}

- (BOOL)isDecrypted
{
    return NO;
}

- (BOOL)isSafe
{
    return NO;
}

- (BOOL)isDeviceMessage
{
    return NO;
}

- (BOOL)canBeDecrypted
{
    return NO;
}

- (BOOL)canBeDownloaded
{
    BOOL result = ![self isDownloaded] && ![self isDownloading];

    //sanity check
    if(result && [self isDecrypted])
        NSLog(@"Email message to be downloaded has already been decrypted!!");
    
    return result;
}

- (BOOL)willBeSafeWhenSent
{
    NSArray* recArray = [AddressDataHelper recipientsForAddressData:self.messageData.addressData];

    return [Recipient recipientListIsSafe:recArray];
}


//checks if a given message is sent by one of the user's own email addresses
- (BOOL)isSentByMe
{
    NSArray* recArray = [AddressDataHelper emailRecipientsForAddressData:self.messageData.addressData];

    EmailRecipient* senderEmailRecipient = [AddressDataHelper senderAmongRecipients:recArray];

    return [senderEmailRecipient.email isUsersAddress];
}





+ (NSManagedObjectID*)messageObjectIDForMessageID:(NSString*)messageID
{
    if(!messageID)
        return nil;

    __block NSManagedObjectID* returnValue = nil;

    if(!emailMessageQueue)
        emailMessageQueue = dispatch_queue_create("org.mynigma.emailMessageQueue", NULL);

    dispatch_sync(emailMessageQueue, ^{

        returnValue = [allMessages objectForKey:messageID];

    });

    return returnValue;
}


+ (void)collectAllMessagesWithCallback:(void(^)(void))callback
{
    haveCollectedAllMessages = NO;

    if(!emailMessageQueue)
        emailMessageQueue = dispatch_queue_create("org.mynigma.emailMessageQueue", NULL);

    dispatch_sync(emailMessageQueue, ^{

        allMessages = [NSMutableDictionary new];

    });

    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

        NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"EmailMessage"];

        NSDictionary* properties = [[NSEntityDescription entityForName:@"EmailMessage" inManagedObjectContext:localContext] propertiesByName];

        NSPropertyDescription* messageIDProperty = [properties objectForKey:@"messageid"];

        NSExpressionDescription* objectIDProperty = [NSExpressionDescription new];
        objectIDProperty.name = @"objectID";
        objectIDProperty.expression = [NSExpression expressionForEvaluatedObject];
        objectIDProperty.expressionResultType = NSObjectIDAttributeType;

        [fetchRequest setPropertiesToFetch:@[messageIDProperty, objectIDProperty]];
        [fetchRequest setReturnsDistinctResults:YES];
        [fetchRequest setResultType:NSDictionaryResultType];

        NSError* error = nil;
        NSArray* results = [localContext executeFetchRequest:fetchRequest error:&error];
        if(error)
        {
            NSLog(@"Error fetching messages array!!!");
        }

        //NSInteger counter = 0;

        for(NSDictionary* messageDict in results)
        {
            NSString* messageID = messageDict[@"messageid"];

            NSManagedObjectID* objectID = messageDict[@"objectID"];

            if(objectID.isTemporaryID)
            {
                NSLog(@"Entering temporary objectID into allMessages dictionary!!");
            }

            if(messageID && objectID)
                [EmailMessage includeMessageID:messageID inAllMessagesDictForObjectID:objectID];

            //            if(!messageID)
            //            {
            //                messageID = [MODEL generateMessageID:@"anonymous@mynigma.org"];
            //                [message setMessageid:messageID];
            //            }

            //            NSManagedObjectID* messageObjectID = [self messageObjectIDForMessageID:messageID];
            //            if(messageObjectID)
            //            {
            //                //uh oh, a message with the same messageID has already been added to the dictionary - log an error message and try to at least make the choice unique by picking the earlier one, if the dates are different
            //                //if not, then it's likely the other properties will be identical as well, so at some point in the future one might consider merging the messages, taking care that no downloaded data gets deleted
            //
            //                //if it's the exact same message again, there is no problem
            //                EmailMessage* existingMessage = [EmailMessage messageWithObjectID:messageObjectID inContext:localContext];
            //
            //                if(existingMessage && ![existingMessage isEqual:[NSNull null]] && ![existingMessage isEqual:message])
            //                {
            //
            //                    //merge the messages
            //                    [existingMessage mergeIntoMessage:message inContext:localContext];
            //
            //                    //if the date etc. doesn't match the merge will have set a new messageID for the second message - we can now safely insert it into the dictionary
            //                    if(![message.messageid isEqual:messageID])
            //                    {
            //                        [message includeInAllMessagesDictInContext:localContext];
            //                    }
            //
            //                    counter++;
            //
            //                    //save once for every 20 messages that have been deleted
            //                    if(counter%20==0)
            //                    {
            //                        error = nil;
            //
            //                        [localContext save:&error];
            //
            //                        if(error)
            //                        {
            //                            NSLog(@"Error saving local context while collecting all messages!!! %@", error);
            //                        }
            //                    }
            //                }
            //            }
            //            else
            //            {
            //                if(message.messageid)
            //                    [message includeInAllMessagesDictInContext:localContext];
            //                else
            //                    NSLog(@"Message has no messageID!! %@", message);
            //            }
        }

        NSLog(@"Done collecting email messages.");

        haveCollectedAllMessages = YES;

        if(callback)
            callback();

        error = nil;

        [localContext save:&error];

        if(error)
        {
            NSLog(@"Error saving local context after collecting all messages!!! %@", error);
        }

    }];
}


//this is awfully slow, but if the allMessages dict has not yet been collected together, it's the only option that doesn't block the UI forever or create duplicate messages
+ (EmailMessage*)fetchMessageFromStoreWithMessageID:(NSString*)messageID inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"EmailMessage"];

    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"messageid = %@", messageID];

    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateSent" ascending:YES];

    [fetchRequest setSortDescriptors:@[sortDescriptor]];

    [fetchRequest setPredicate:predicate];

    NSError* error = nil;
    NSArray* results = [localContext executeFetchRequest:fetchRequest error:&error];

    if(results.count>0)
    {
        return results[0];
    }

    return nil;
}


- (void)mergeIntoMessage:(EmailMessage*)message inContext:(NSManagedObjectContext*)localContext
{
    if([self.messageid isEqual:message.messageid])
    {
        //check that the date and search string matches
        if((!self.dateSent && !message.dateSent) || (message.dateSent && [self.dateSent isEqual:message.dateSent]))
            if([self.searchString isEqual:message.searchString])
                if(self.allAttachments.count == message.allAttachments.count)
                {
                    //looks like it really is the same message
                    //no real need to merge anything, since there is no reason why the first message shouldn't already be equipped with all the data
                    //deleting the second message's instances might result in some instances disapperaing until the next fetch cycle, but that is probably preferable to having duplicates
                    //could think about actually merging instances
                    //delete the attachments first
                    NSSet* allAttachments = [NSSet setWithSet:message.allAttachments];
                    for(FileAttachment* attachment in allAttachments)
                    {
                        [localContext deleteObject:attachment];
                    }

                    //#if TARGET_OS_IPHONE
                    //
                    //#else
                    //                    NSManagedObjectID* ownObjectID = message.objectID;
                    //
                    //                    [MAIN_CONTEXT performBlockAndWait:^{
                    //
                    //                        EmailMessage* messageOnMain = [EmailMessage messageWithObjectID:ownObjectID inContext:MAIN_CONTEXT];
                    //
                    //                    [[EmailMessageController sharedInstance] removeMessageObjectFromTable:messageOnMain animated:YES];
                    //
                    //                    for(EmailMessageInstance* instanceOnMain in messageOnMain.instances)
                    //                    {
                    //                        [[EmailMessageController sharedInstance] removeMessageObjectFromTable:instanceOnMain animated:YES];
                    //                    }
                    //
                    //                    }];
                    //
                    //#endif
                    NSLog(@"Delete 5");

                    [localContext deleteObject:message];

                    //[localContext processPendingChanges];

                    NSLog(@"Merged messages");
                    return;
                }

        //the messages seem to be different(!)
        NSLog(@"Found different messages with the same messageID! %@ vs. %@", self, message);

        //assign a fresh messageID to the second message
        [message setMessageid:[@"anonymous@mynigma.org" generateMessageID]];
    }
}







//searches for a message with the given messageID and, if none is found, creates a new one. if safe is YES the new message will be a MynigmaMessage, otherwise an EmailMessage. the messageFound BOOL parameter is an optional value that, upon return, will reflect whether the returned message was found or newly created
+ (instancetype)findOrMakeMessageWithMessageID:(NSString*)messageID
{
    return [self findOrMakeMessageWithMessageID:messageID inContext:MAIN_CONTEXT messageFound:nil];
}

+ (instancetype)findOrMakeMessageWithMessageID:(NSString*)messageID inContext:(NSManagedObjectContext*)localContext
{
    return [self findOrMakeMessageWithMessageID:messageID inContext:localContext messageFound:nil];
}

+ (instancetype)findOrMakeMessageWithMessageID:(NSString*)messageID messageFound:(BOOL*)found
{
    return [self findOrMakeMessageWithMessageID:messageID inContext:MAIN_CONTEXT messageFound:found];
}


+ (instancetype)findOrMakeMessageWithMessageID:(NSString*)messageID inContext:(NSManagedObjectContext*)localContext messageFound:(BOOL*)found
{
    if(!messageID)
    {
        NSLog(@"Tried to create message with invalid messageID!!!");
        return nil;
    }

    if(found)
        *found = NO;

    BOOL foundMessage = NO;

    EmailMessage* newMessage = [self findMessageWithMessageID:messageID inContext:localContext found:&foundMessage];

    if(foundMessage)
    {
        //a message was found, though it could not necessarily be created in this context, so newMessage might still be nil
        if(found)
            *found = YES;

        if(!newMessage)
        {
            NSLog(@"Cannot find email message object!!");
            return nil;
        }

        if(![self.class isEqual:newMessage.class])
        {
            NSLog(@"Message class mismatch!!! Expected: %@, found: %@", self.class, newMessage.class);
            return nil;
        }

        return newMessage;
    }

    BOOL successfullyReservedMessageID = [self reserveMessageID:messageID];

    if(!successfullyReservedMessageID)
    {
        //not found a message, but then failed to reserve it
        //probably a race condition problem
        //another thread must have added the message in the meantime
        if(found)
            *found = YES;
        return nil;
    }

    if(newMessage)
    {
        NSLog(@"Not found message, but newMessage isn't nil!!!!");
        return nil;
    }

    NSEntityDescription* entity = [NSEntityDescription entityForName:NSStringFromClass([self class]) inManagedObjectContext:localContext];
    newMessage = [[self.class alloc] initWithEntity:entity insertIntoManagedObjectContext:localContext];

    if([newMessage respondsToSelector:@selector(setDecryptionStatus:)])
        [newMessage performSelector:@selector(setDecryptionStatus:) withObject:@""];

    entity = [NSEntityDescription entityForName:@"EmailMessageData" inManagedObjectContext:localContext];
    EmailMessageData* newMessageData = [[EmailMessageData alloc] initWithEntity:entity insertIntoManagedObjectContext:localContext];

    [newMessage setMessageData:newMessageData];

    [newMessage setHasHadInstancesAtSomePoint:@NO];
    [newMessage setMessageid:messageID];

    if(found)
        *found = NO;

    if(![newMessage includeInAllMessagesDictInContext:localContext])
    {

        [localContext deleteObject:newMessage];

        NSLog(@"Deleting EmailMessage, because it could not be added to all messages context");
    }

    return newMessage;
}

+ (BOOL)reserveMessageID:(NSString*)messageID
{
    __block BOOL returnValue = NO;

    if(!emailMessageQueue)
        emailMessageQueue = dispatch_queue_create("org.mynigma.emailMessageQueue", NULL);

    dispatch_sync(emailMessageQueue, ^{

        if(![allMessages objectForKey:messageID])
        {
            returnValue = YES;

            [allMessages setObject:[NSNull null] forKey:messageID];
        }
    });

    return returnValue;
}

+ (EmailMessage*)findMessageWithMessageID:(NSString*)messageID inContext:(NSManagedObjectContext*)localContext
{
    return [self findMessageWithMessageID:messageID inContext:localContext found:nil];
}

+ (EmailMessage*)findMessageWithMessageID:(NSString*)messageID inContext:(NSManagedObjectContext*)localContext found:(BOOL*)foundMessage
{
    if(foundMessage)
        *foundMessage = NO;

    //[ThreadHelper ensureLocalThread:localContext];

    if(!messageID)
    {
        //NSLog(@"Tried to find message with invalid messageID!!!");
        return nil;
    }

    __block EmailMessage* returnValue = nil;

    if(!emailMessageQueue)
        emailMessageQueue = dispatch_queue_create("org.mynigma.emailMessageQueue", NULL);


    __block NSManagedObjectID* existingMessageObjectID = nil;

    dispatch_sync(emailMessageQueue, ^{

        existingMessageObjectID = [allMessages objectForKey:messageID];

    });

    if([existingMessageObjectID isKindOfClass:[NSManagedObjectID class]])
    {
        if(foundMessage)
            *foundMessage = YES;

        EmailMessage* message = [EmailMessage messageWithObjectID:existingMessageObjectID inContext:localContext];

        if(!message)
        {
            NSLog(@"Cannot create email message object from objectID!!");
            returnValue = nil;
        }

        returnValue = message;
    }

    if(returnValue)
        return returnValue;

    //no such message in the allMessage dictionary so far
    //if the collection/generation of allMessages has not yet finished we need to check the store
    EmailMessage* newMessage = nil;

    if(!haveCollectedAllMessages)
    {
        newMessage = [EmailMessage fetchMessageFromStoreWithMessageID:messageID inContext:localContext];

        if(newMessage)
        {
            //a message has been found in the store
            if(foundMessage)
                *foundMessage = YES;
            return newMessage;
        }
    }

    return nil;
}


+ (BOOL)haveMessageWithMessageID:(NSString*)messageID
{
    [ThreadHelper ensureMainThread];

    return [self haveMessageWithMessageID:messageID inContext:MAIN_CONTEXT];
}

+ (BOOL)haveMessageWithMessageID:(NSString*)messageID inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    if(!messageID)
        return NO;

    if(haveCollectedAllMessages)
    {
        __block BOOL haveMessage = NO;

        if(!emailMessageQueue)
            emailMessageQueue = dispatch_queue_create("org.mynigma.emailMessageQueue", NULL);

        dispatch_sync(emailMessageQueue, ^{

            if([allMessages objectForKey:messageID]!=nil)
                haveMessage = YES;

        });

        return haveMessage;
    }

    EmailMessage* fetchedStoreMessage = [self fetchMessageFromStoreWithMessageID:messageID inContext:localContext];

    return fetchedStoreMessage!=nil;
}


+ (EmailMessage*)newDraftMessageInContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    NSString* messageID = [@"anonymous@mynigma.org" generateMessageID];

    NSEntityDescription* entity = [NSEntityDescription entityForName:@"MynigmaMessage" inManagedObjectContext:localContext];
    MynigmaMessage* newMessage = [[MynigmaMessage alloc] initWithEntity:entity insertIntoManagedObjectContext:localContext];

    [(MynigmaMessage*)newMessage setDecryptionStatus:@""];

    [newMessage setHasHadInstancesAtSomePoint:@NO];

    entity = [NSEntityDescription entityForName:@"EmailMessageData" inManagedObjectContext:localContext];
    EmailMessageData* newMessageData = [[EmailMessageData alloc] initWithEntity:entity insertIntoManagedObjectContext:localContext];

    [newMessage setMessageData:newMessageData];

    [newMessageData setAddressData:[NSData new]];

    [newMessageData setHasImages:@NO];
    [newMessageData setLoadRemoteImages:@YES];

    [AddressDataHelper senderAsEmailRecipientForMessage:newMessage addIfNotFound:YES];

    IMAPAccountSetting* senderAccount = [AddressDataHelper sendingAccountSettingForMessage:newMessage];

    NSString* HTMLBody = [FormattingHelper emptyEmailWithFooter:senderAccount.footer];

    [newMessageData setHtmlBody:HTMLBody];

    [newMessage setMessageid:messageID];

    //no need to block this thread until the message has been included in the all messages dictionary, since the messageID was freshly generated - no clashes are to be expected
    [newMessage asyncIncludeInAllMessagesDictInContext:localContext];

    return newMessage;
}




- (MynigmaMessage*)turnIntoSafeMessageInContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    if([self isKindOfClass:[MynigmaMessage class]])
    {
        return (MynigmaMessage*)self;
    }

    NSEntityDescription* entity = [NSEntityDescription entityForName:@"MynigmaMessage" inManagedObjectContext:localContext];
    MynigmaMessage* safeMessage = [[MynigmaMessage alloc] initWithEntity:entity insertIntoManagedObjectContext:localContext];
    [(MynigmaMessage*)safeMessage setDecryptionStatus:@""];

    [safeMessage setHasHadInstancesAtSomePoint:@NO];
    [safeMessage setMessageData:self.messageData];
    [safeMessage setInstances:self.instances];

    [self setMessageData:nil];
    [self setInstances:nil];

    [safeMessage setAllAttachments:self.allAttachments];
    [safeMessage setAttachments:self.attachments];

    [self setAllAttachments:nil];
    [self setAttachments:nil];

    [safeMessage setDateSent:self.dateSent];
    [safeMessage setEmails:self.emails];

    [self setEmails:nil];

    [safeMessage setIsCleaning:NO];
    [safeMessage setIsDecrypting:NO];
    [safeMessage setIsDownloading:NO];
    [safeMessage setMessageid:self.messageid];
    [safeMessage setSearchString:self.searchString];

    //first we need to update the allMessages dictionary in MODEL to point to the new, open message(!)
    [self removeMessageFromAllMessagesDict];

    //#if TARGET_OS_IPHONE
    //
    //#else
    //    NSManagedObjectID* ownObjectID = self.objectID;
    //
    //    [MAIN_CONTEXT performBlockAndWait:^{
    //
    //        EmailMessage* messageOnMain = [EmailMessage messageWithObjectID:ownObjectID inContext:MAIN_CONTEXT];
    //
    //        [[EmailMessageController sharedInstance] removeMessageObjectFromTable:messageOnMain animated:YES];
    //
    //        for(EmailMessageInstance* instanceOnMain in messageOnMain.instances)
    //        {
    //            [[EmailMessageController sharedInstance] removeMessageObjectFromTable:instanceOnMain animated:YES];
    //        }
    //
    //    }];
    //
    //#endif

    NSLog(@"Delete 6");

    [localContext deleteObject:self];

    //[localContext processPendingChanges];

    [safeMessage setMessageid:[@"openToSafe@mynigma.org" generateMessageID]];

    [localContext obtainPermanentIDsForObjects:@[safeMessage] error:nil];

    NSError* error = nil;

    [localContext save:&error];

    if(error)
    {
        NSLog(@"Error saving local context before including message in all messages dict!!! %@", error.localizedDescription);
    }

    [safeMessage includeInAllMessagesDictInContext:localContext];

    return safeMessage;
}

- (void)outputInstancesInfoToConsole
{
    NSMutableString* outputString = [NSMutableString new];

    [outputString appendString:@"\n\nEmailMessage instances:\n"];

    for(EmailMessageInstance* messageInstance in self.instances)
    {
        if(messageInstance.movedFromInstance)
            continue;

        EmailMessageInstance* iterationInstance = messageInstance;

        while (iterationInstance)
        {
            [outputString appendFormat:@"================\n= inFolder: %@\n= unreadInFolder: %@\n= addedToFolder: %@\n= movedAwayFromFolder: %@\n= deletedFromFolder: %@\n= hasLabels: %ld\n= unreadWithLabels: %ld\n= UID: %@\n================\n", iterationInstance.inFolder.displayName, iterationInstance.unreadInFolder.displayName, iterationInstance.addedToFolder.displayName, iterationInstance.movedAwayFromFolder.displayName, iterationInstance.deletedFromFolder.displayName, (unsigned long)iterationInstance.hasLabels.count, (unsigned long)iterationInstance.unreadWithLabels.count, iterationInstance.uid];

            iterationInstance = iterationInstance.movedToInstance;

            if(iterationInstance)
                [outputString appendString:@"       |\n       V\n"];
            else
                [outputString appendString:@"\n"];
        }
    }

    NSLog(@"%@", outputString);
}

+ (instancetype)messageWithObjectID:(NSManagedObjectID*)messageObjectID inContext:(NSManagedObjectContext*)localContext
{
    //[ThreadHelper ensureLocalThread:localContext];

    if(![messageObjectID isKindOfClass:[NSManagedObjectID class]])
    {
        NSLog(@"Trying to create EmailMessageInstance with nil object ID!!");
        return nil;
    }

    NSError* error = nil;

    //NSDate* startDate = [NSDate date];

    EmailMessage* message = (EmailMessage*)[localContext existingObjectWithID:messageObjectID error:&error];

    //[ThreadHelper printElapsedTimeSince:startDate withIdentifier:@"existing object with ID"];

    if(!message)
    {
        NSLog(@"Error creating email message!!! %@ %@", message, error);
        return nil;
    }

    return message;
}


- (BOOL)syncAddToAllMessagesDict
{
    NSString* messageID = self.messageid;

    NSManagedObjectID* messageObjectID = self.objectID;

    if(messageObjectID.isTemporaryID)
    {
        [self.managedObjectContext obtainPermanentIDsForObjects:@[self] error:nil];
        messageObjectID = self.objectID;
    }

    __block BOOL returnValue = NO;

    if(!emailMessageQueue)
        emailMessageQueue = dispatch_queue_create("org.mynigma.emailMessageQueue", NULL);

    if(messageID && messageObjectID)
        dispatch_sync(emailMessageQueue, ^{

            [allMessages setObject:messageObjectID forKey:messageID];
            returnValue = YES;

        });

    return returnValue;
}


+ (void)includeMessageID:(NSString*)messageID inAllMessagesDictForObjectID:(NSManagedObjectID*)objectID
{
    if(messageID && objectID)
    {
        dispatch_sync(emailMessageQueue, ^{

            [allMessages setObject:objectID forKey:messageID];

        });
    }
}


//adds the message to the all messages dict before returning
//presumption: the message is freshly generated, with a new messageID, so not currently in the allMessages dict
- (BOOL)includeInAllMessagesDictInContext:(NSManagedObjectContext*)localContext;
{
    //[ThreadHelper ensureLocalThread:localContext];

    NSString* messageID = self.messageid;

    if(!messageID)
    {
        NSLog(@"Attempting to register message with nil messageID!!");
        return NO;
    }

    NSManagedObjectID* messageObjectID = self.objectID;

    if(messageObjectID.isTemporaryID)
    {
        [self.managedObjectContext obtainPermanentIDsForObjects:@[self] error:nil];
        messageObjectID = self.objectID;
    }

    __block BOOL returnValue = NO;

    if(!emailMessageQueue)
        emailMessageQueue = dispatch_queue_create("org.mynigma.emailMessageQueue", NULL);

    if(messageID && messageObjectID)
    {
        dispatch_sync(emailMessageQueue, ^{

            [allMessages setObject:self.objectID forKey:messageID];

        });

        returnValue = YES;
    }

    return returnValue;
}

//adds the message to the all messages dict asynchronously
//presumption: the message is freshly generated, with a new messageID, so not currently in the allMessages dict
- (void)asyncIncludeInAllMessagesDictInContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    NSString* messageID = self.messageid;

    if(!messageID)
    {
        NSLog(@"Attempting to register message with nil messageID!!");
        return;
    }

    if(self.objectID.isTemporaryID)
    {
        [localContext obtainPermanentIDsForObjects:@[self] error:nil];
    }

    NSManagedObjectID* messageObjectID = self.objectID;

    if(messageObjectID.isTemporaryID)
    {
        [self.managedObjectContext obtainPermanentIDsForObjects:@[self] error:nil];
        messageObjectID = self.objectID;
    }


    if(messageID && messageObjectID)
        dispatch_async(emailMessageQueue, ^{

            [allMessages setObject:self.objectID forKey:messageID];

        });
}

- (BOOL)removeMessageFromAllMessagesDict
{
    NSString* messageID = self.messageid;

    if(!messageID)
    {
        NSLog(@"Attempting to remove message with nil messageID!!");
        return NO;
    }

    __block BOOL returnValue = NO;

    dispatch_sync(emailMessageQueue, ^{

        if([allMessages objectForKey:messageID])
        {
            [allMessages removeObjectForKey:messageID];

            returnValue = YES;
        }

    });

    return returnValue;
}


- (MynigmaFeedback*)feedback
{
    if(![self isDownloaded]) //the content has not yet been downloaded
    {
        if([self isDownloading])
        {
            return [MynigmaFeedback feedback:MynigmaStatusDownloading];
        }
        else
        {
            return [MynigmaFeedback feedback:MynigmaStatusNotDownloaded];
        }
    }
    else if(![self isSafe]) //it is an open message, so just display it normally
    {
        return [MynigmaFeedback feedback:MynigmaStatusDownloadedAndDecrypted];
    }
    else
    {
        if([self isDecrypting])
        {
            return [MynigmaFeedback feedback:MynigmaStatusDecrypting];
        }
        else
        {
            
            NSString* decryptionStatus = [(MynigmaMessage*)self decryptionStatus];

            if([decryptionStatus isEqualToString:@"OK"] || ([decryptionStatus isEqualToString:@""] && self.messageData.htmlBody))
                return [MynigmaFeedback feedback:MynigmaStatusDownloadedAndDecrypted];

            return [MynigmaFeedback feedbackWithArchivedString:decryptionStatus message:self];
        }
    }
}

- (void)didPresentErrorWithRecovery:(BOOL)didRecover contextInfo:(void *)contextInfo
{

}

- (BOOL)attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex
{
    switch(recoveryOptionIndex)
    {
            //the first option is a "try again" button
        case 0:
        {
            {
                [DownloadHelper downloadMessage:self urgent:YES];
            }
            return YES;
        }

            //the second option (if applicable) is "override" (turn error into warning)
        case 1:
        {
            [self overrideError];
            return YES;
        }
    }

    return YES;
}

- (void)overrideError
{
    if([self isKindOfClass:[MynigmaMessage class]])
    {
        MynigmaFeedback* feedback = [self feedback];

        MynigmaFeedback* overriddenFeedback = [feedback override];

        [(MynigmaMessage*)self setDecryptionStatus:overriddenFeedback.archivableString];

        [SelectionAndFilterHelper refreshMessage:self.objectID];
    }
}


- (void)attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex delegate:(id)delegate didRecoverSelector:(SEL)didRecoverSelector contextInfo:(void *)contextInfo
{
    return;
}

- (void)checkIntegrity
{
    if(PERFORM_MESSAGE_INTEGRITY_CHECKS)
    {
        for(EmailMessageInstance* instance in self.instances)
        {
            //corrupt states:
            //moved or deleted messages need a UID, unless they have been added
            if((instance.movedAwayFromFolder || instance.deletedFromFolder) && !instance.addedToFolder && !instance.movedFromInstance && !instance.uid.unsignedIntegerValue)
            {
                NSLog(@"Added instance has nil UID!!");
                [self outputInstancesInfoToConsole];
                return;
            }

            //moved away messages must have a destination instance
            if(instance.movedAwayFromFolder && !instance.movedToInstance)
            {
                NSLog(@"Moved away instance has no destination!!");
                [self outputInstancesInfoToConsole];
                return;
            }

            //messages with a destination need to be either:
            //(i) moved from a third folder
            //(ii) added to the folder
            //(iii) have a movedAwayFromFolder relationship
            if(instance.movedToInstance && (instance.movedFromInstance || instance.addedToFolder || instance.movedAwayFromFolder))
            {
                NSLog(@"Message instance with destination has no appropriate source!!");
                [self outputInstancesInfoToConsole];
                return;
            }

            if(instance.movedFromInstance && instance.addedToFolder)
            {
                NSLog(@"Moved message instance is also added to folder!!");
                [self outputInstancesInfoToConsole];
                return;
            }

            if(instance.movedToInstance && instance.deletedFromFolder)
            {
                NSLog(@"Moved message instance is also deleted from folder!!");
                [self outputInstancesInfoToConsole];
                return;
            }
        }
    }
}

- (NSString*)htmlBody
{
    if([self isDeviceMessage])
    {
        NSString* logoPath = [[NSBundle mainBundle] pathForResource:@"MynigmaIconForLetter" ofType:@"jpg"];

        NSData* logoData = [NSData dataWithContentsOfFile:logoPath];

        NSString* logoBase64String = [logoData base64];

        //        NSString* subjectString = [NSString stringWithFormat:NSLocalizedString(@"Internal Mynigma message",@"Device message subject")];

        NSURL* mynigmaMessageURL = [BUNDLE URLForResource:@"DeviceMessageWithBase64Image" withExtension:@"html"];

        NSString* formatString = [NSString stringWithContentsOfURL:mynigmaMessageURL encoding:NSUTF8StringEncoding error:nil];

        if(!formatString)
        {
            NSLog(@"Error loading device message template!!");
            return nil;
        }

        NSString* bodyString = [NSString stringWithFormat:formatString, logoBase64String?logoBase64String:@""];

        return bodyString;
    }

    NSString* htmlBody = self.messageData.htmlBody;

    if(!htmlBody)
        htmlBody = @"";

    MynigmaFeedback* feedback = [self feedback];

    //don't show the message if there has been an error

    if(feedback.isError)
        htmlBody = @"";

    return htmlBody;
}







#pragma mark - Downloading

- (EmailMessageInstance*)downloadableInstance
{
    EmailMessageInstance* messageInstance = nil;

    for(EmailMessageInstance* instance in self.instances)
    {
        if(instance.folderSetting && instance.uid)
        {
            messageInstance = instance;
            break;
        }
    }

    return messageInstance;
}


//- (void)download
//{
//    [self downloadUsingSession:nil disconnectOperation:nil urgent:NO alsoDownloadAttachments:NO];
//}
//
//- (void)downloadUrgently
//{
//    [self downloadUsingSession:nil disconnectOperation:nil urgent:YES alsoDownloadAttachments:YES];
//}

- (void)downloadUsingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation urgent:(BOOL)urgent alsoDownloadAttachments:(BOOL)withAttachments
{
    [ThreadHelper ensureMainThread];

    //don't need to download a message that has already been downloaded
    if([self isDownloaded])
    {
        //MynigmaMessage overloads this method to initiate decryption instead
        return;
    }

    //if it's already downloading, don't bother doing anything...
    if([self isDownloading])
        return;


    //first find an instance of the message that can be downloaded from the IMAP server
    EmailMessageInstance* messageInstance = [self downloadableInstance];

    if(!messageInstance)
    {
        NSLog(@"Cannot download message without a suitable instance! %@", self);
        return;
    }

    [messageInstance downloadUsingSession:session disconnectOperation:disconnectOperation urgent:urgent alsoDownloadAttachments:withAttachments];

    if(withAttachments)
    {
        for(FileAttachment* attachment in self.allAttachments)
        {
            [attachment downloadUsingSession:session disconnectOperation:disconnectOperation urgent:urgent withCallback:nil];
        }
    }
}


#pragma mark - Profile picture

- (IMAGE*)profilePic
{
    EmailRecipient* sender = [AddressDataHelper senderAsEmailRecipientForMessage:self];
    if(!sender)
        return nil;

    EmailContactDetail* contactDetail = [EmailContactDetail emailContactDetailForAddress:sender.email];

    NSSet* contacts = contactDetail.linkedToContact;
    IMAGE* candidateImage = nil;

    for(Contact* contact in contacts)
    {
        if([contact haveProfilePic])
        {
            IMAGE* newImage = [contact profilePic];
            return newImage;
        }
    }

    return candidateImage;
}

- (BOOL)haveProfilePic
{
    EmailRecipient* sender = [AddressDataHelper senderAsEmailRecipientForMessage:self];
    if(!sender)
        return NO;

    EmailContactDetail* contactDetail = [EmailContactDetail emailContactDetailForAddress:sender.email];

    NSSet* contacts = contactDetail.linkedToContact;

    for(Contact* contact in contacts)
    {
        if([contact haveProfilePic])
            return YES;
    }

    return NO;
}

#pragma mark - Sending

- (NSError*)wrapIntoMessageBuilder:(MCOMessageBuilder*)messageBuilder
{
    [[messageBuilder header] setSubject:self.messageData.subject];
    [messageBuilder setHTMLBody:self.messageData.htmlBody];

    MCOAddress* fromAddress = nil;
    NSMutableArray* replyToArray = [NSMutableArray new];
    NSMutableArray* toArray = [NSMutableArray new];
    NSMutableArray* ccArray = [NSMutableArray new];
    NSMutableArray* bccArray = [NSMutableArray new];

    NSData* recData = self.messageData.addressData;

    NSArray* recArray = [AddressDataHelper emailRecipientsForAddressData:recData];

    for(EmailRecipient* rec in recArray)
    {
        MCOAddress* newAddress = [MCOAddress addressWithDisplayName:rec.name mailbox:rec.email];
        switch(rec.type)
        {
            case TYPE_FROM:
                fromAddress = newAddress;
                break;
            case TYPE_REPLY_TO:
                [replyToArray addObject:newAddress];
                break;
            case TYPE_TO:
                [toArray addObject:newAddress];
                break;
            case TYPE_CC:
                [ccArray addObject:newAddress];
                break;
            case TYPE_BCC:
                [bccArray addObject:newAddress];
                break;
        }
    }
    
    if(fromAddress)
        [messageBuilder.header setFrom:fromAddress];
    else
    {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"Failed to wrap email message", nil), NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"No sending address set(!)", nil), NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"Please submit a bug report so we can fix the problem for you.", nil)};

        NSError* error = [NSError errorWithDomain:@"EmailMessage wrap for sending" code:6 userInfo:userInfo];

        return error;
    }

    [messageBuilder.header setReplyTo:replyToArray];
    [messageBuilder.header setTo:toArray];
    [messageBuilder.header setCc:ccArray];
    [messageBuilder.header setBcc:bccArray];


    NSString* fromEmailAddress = messageBuilder.header.from.mailbox;

    NSString* ownCurrentKeyLabel = [MynigmaPublicKey publicKeyLabelForEmailAddress:fromEmailAddress];

    NSData* ownCurrentKeyLabelData = [ownCurrentKeyLabel dataUsingEncoding:NSUTF8StringEncoding];

    NSString* ownCurrentKeyLabelInBase64 = [ownCurrentKeyLabelData base64In64ByteChunks];

//    if([ownCurrentKeyLabelData respondsToSelector:@selector(base64EncodedStringWithOptions:)])
//    {
//        //available from 10.9
//        ownCurrentKeyLabelInBase64 = [ownCurrentKeyLabelData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength|NSDataBase64EncodingEndLineWithCarriageReturn|NSDataBase64EncodingEndLineWithLineFeed];
//    }
//    else
//    {
//        //available from 10.6, deprecated in 10.9
//        ownCurrentKeyLabelInBase64 = [ownCurrentKeyLabelData base64];
//
//        //split into 64 character lines
//        NSMutableArray* chunks = [NSMutableArray new];
//
//        NSInteger index = 0;
//
//        while(index<ownCurrentKeyLabelInBase64.length)
//        {
//            NSInteger lengthOfChunk = (index+64<ownCurrentKeyLabelInBase64.length)?64:ownCurrentKeyLabelInBase64.length-index;
//
//            NSString* substring = [ownCurrentKeyLabelInBase64 substringWithRange:NSMakeRange(index, lengthOfChunk)];
//
//            [chunks addObject:substring];
//
//            index+= 64;
//        }
//
//        ownCurrentKeyLabelInBase64 = [chunks componentsJoinedByString:@"\r\n"];
//    }



    NSString* publicKeyString = [PublicKeyManager headerRepresentationOfPublicKeyWithLabel:ownCurrentKeyLabel];

    if(publicKeyString)
    {
        [messageBuilder.header setExtraHeaderValue:ownCurrentKeyLabelInBase64 forName:@"X-Myn-KL"];
        [messageBuilder.header setExtraHeaderValue:publicKeyString forName:@"X-Myn-PK"];
    }


    //append the attachments
    for(FileAttachment* fileAttachment in self.allAttachments)
    {
        NSURL* privateURL = [fileAttachment privateURL];

        if(privateURL)
        {
            MCOAttachment* att = [MCOAttachment attachmentWithContentsOfFile:privateURL.path];
            [att setInlineAttachment:fileAttachment.attachedToMessage==nil];
            [att setContentID:fileAttachment.contentid];
            if(att)
            {
                if(fileAttachment.attachedToMessage==nil)
                    [messageBuilder addRelatedAttachment:att];
                else
                    [messageBuilder addAttachment:att];
            }
            else
            {
                NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"Failed to wrap email message", nil), NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"One of the attachments could not be located(!!)", nil), NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"Please submit a bug report so we can fix the problem for you.", nil)};

                NSError* error = [NSError errorWithDomain:@"EmailMessage wrap for sending" code:3 userInfo:userInfo];

                return error;
            }
        }
        else
        {
            NSURL* publicURL = [fileAttachment publicURL];

#if TARGET_OS_IPHONE

            NSData* attachmentData = [NSData dataWithContentsOfURL:publicURL];

#else

            [publicURL startAccessingSecurityScopedResource];
            NSData* attachmentData = [NSData dataWithContentsOfURL:publicURL];
            [publicURL stopAccessingSecurityScopedResource];
            
#endif
            
            if(attachmentData)
            {
                MCOAttachment* att = [MCOAttachment attachmentWithData:attachmentData filename:publicURL.lastPathComponent];
                [att setInlineAttachment:fileAttachment.attachedToMessage==nil];
                [att setContentID:fileAttachment.contentid];
                if(att)
                {
                    if(fileAttachment.attachedToMessage==nil)
                        [messageBuilder addRelatedAttachment:att];
                    else
                        [messageBuilder addAttachment:att];
                }
                else
                {
                    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"Failed to wrap email message", nil), NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"One of the attachments is invalid(!!)", nil), NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"Please submit a bug report so we can fix the problem for you.", nil)};
                    
                    NSError* error = [NSError errorWithDomain:@"EmailMessage wrap for sending" code:4 userInfo:userInfo];
                    
                    return error;
                }
            }
            else
            {
                NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"Failed to wrap email message", nil), NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"One of the attachments has no data(!!)", nil), NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"Please submit a bug report so we can fix the problem for you.", nil)};
                
                NSError* error = [NSError errorWithDomain:@"EmailMessage wrap for sending" code:5 userInfo:userInfo];
                
                return error;
            }
        }
    }

    //no error
    return nil;
}

#pragma mark - Deletion

- (void)removeFromStoreInContext:(NSManagedObjectContext*)localContext
{
    [localContext deleteObject:self.messageData];
    
    NSSet* allInstances = self.instances;
    
    [self removeMessageFromAllMessagesDict];
    [localContext deleteObject:self];
    
    for(EmailMessageInstance* instance in allInstances)
    {
        [instance removeFromStoreInContext:localContext];
    }
}


@end
