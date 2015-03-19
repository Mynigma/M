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


#if TARGET_OS_IPHONE
#import "EmailMessageController.h"
#else
#endif

#import "AppDelegate.h"
#import "KeychainHelper.h"
#import "HTMLPurifier.h"
#import "Reachability.h"
#import "IMAPAccount.h"
#import "IMAPAccountSetting+Category.h"
#import "IMAPFolderSetting+Category.h"
#import "GmailLabelSetting.h"
#import "GmailAccountSetting.h"
#import "EmailMessage+Category.h"
#import "FileAttachment+Category.h"
#import "Recipient.h"
#import "EmailContactDetail+Category.h"
#import "EmailRecipient.h"
#import "EncryptionHelper.h"
#import "MynigmaMessage+Category.h"
#import "UserSettings.h"
#import <MailCore/MailCore.h>
#import "MynigmaAttachment.h"
#import "InlineAttachment.h"
#import "MessageSieve.h"
#import "FolderInfoObject.h"
#import "EmailMessageData.h"
#import "IdleHelper.h"
#import "IMAPFolderManager.h"
#import "MCODelegate.h"
#import "SendingManager.h"
#import "AttachmentsManager.h"
#import "MessageSyncHelper.h"
#import "EmailMessageInstance+Category.h"
#import "FetchMessagesOperation.h"
#import "AppendMessagesOperation.h"
#import "DeleteMessagesOperation.h"
#import "StoreFlagsOperation.h"
#import "StoreLabelsOperation.h"
#import "CopyMessageOperation.h"
#import "OutlineObject.h"
#import "FolderInfoOperation.h"
#import "DeviceConnectionHelper.h"
#import "AccountCheckManager.h"
#import "EmailMessageController.h"
#import "UIDHelper.h"
#import "MergeLocalChangesHelper.h"
#import "UserNotificationHelper.h"
#import "DisconnectOperation.h"
#import "SyncMessagesOperation.h"
#import "FolderInfoOperation.h"
#import "DisconnectOperation.h"
#import "DeviceMessage+Category.h"
#import "SelectionAndFilterHelper.h"
#import "DownloadHelper.h"



#if ULTIMATE
#import "RegistrationHelper.h"
#endif

static __strong NSMutableSet* sessionHelpers;

@implementation IMAPAccount

@synthesize quickAccessSession;
@synthesize idleHelperInbox;
@synthesize idleHelperSpam;
@synthesize smtpSession;


#define VERBOSE NO
#define VERBOSE_CHECK NO


#pragma mark -
#pragma mark INIT


- (BOOL)canIdle
{
    if(accountSetting.supportsIDLE.boolValue)
        return YES;

    return NO;
}

- (BOOL)canModSeq
{
    if(accountSetting.supportsMODSEQ.boolValue)
        return YES;

    return NO;
}

- (BOOL)canQResync
{
    if(accountSetting.supportsQRESYNC.boolValue)
        return YES;

    return NO;
}



//inits the account with an IMAPAccountSetting - all fields must be set at this point(!)
- (id)init
{
    self = [super init];
    if (self) {
        newMessageObjectIDs = [NSMutableArray new];

        fetchingSignUpMessage = NO;

#if ULTIMATE
        self.registrationHelper = [[RegistrationHelper alloc] initWithAccount:self];
#endif

        messagesBeingDownloaded = [NSMutableSet new];
        messagesBeingDecrypted = [NSMutableSet new];

        operationQueues = [NSMutableDictionary new];
    }
    return self;
}

//- (NSOperationQueue*)newMessagesQueueForFolderWithObjectID:(NSManagedObjectID*)folderObjectID
//{
//    if(![folderObjectID isKindOfClass:[NSManagedObjectID class]])
//        return nil;
//
//    NSURL* key = folderObjectID.URIRepresentation;
//
//    if(!key)
//        return nil;
//
//    @synchronized(@"Operation Queues Lock")
//    {
//        if(![operationQueues objectForKey:@"new"])
//        {
//            [operationQueues setObject:[NSDictionary new] forKey:@"new"];
//        }
//
//        NSMutableDictionary* newMessagesQueues = [[operationQueues objectForKey:@"new"] mutableCopy];
//
//        if(![newMessagesQueues objectForKey:key])
//        {
//            if(VERBOSE)
//                NSLog(@"Operation queue started (new check), %ld queues", (unsigned long)newMessagesQueues.count);
//
//            [newMessagesQueues setObject:[NSOperationQueue new] forKey:key];
//
//            [operationQueues setObject:newMessagesQueues forKey:@"new"];
//        }
//
//        NSOperationQueue* newMessagesQueue = [newMessagesQueues objectForKey:key];
//
//        return newMessagesQueue;
//    }
//}
//
//- (NSOperationQueue*)existingMessagesQueueForFolderWithObjectID:(NSManagedObjectID*)folderObjectID
//{
//    if(![folderObjectID isKindOfClass:[NSManagedObjectID class]])
//        return nil;
//
//    NSURL* key = folderObjectID.URIRepresentation;
//
//    if(!key)
//        return nil;
//
//    @synchronized(@"Operation Queues Lock")
//    {
//        if(![operationQueues objectForKey:@"existing"])
//            [operationQueues setObject:[NSDictionary new] forKey:@"existing"];
//
//        NSMutableDictionary* existingMessagesQueues = [[operationQueues objectForKey:@"existing"] mutableCopy];
//
//        if(![existingMessagesQueues objectForKey:key])
//        {
//            if(VERBOSE)
//                NSLog(@"Operation queue started (old check), %ld queues", (unsigned long)existingMessagesQueues.count);
//
//            [existingMessagesQueues setObject:[NSOperationQueue new] forKey:key];
//
//            [operationQueues setObject:existingMessagesQueues forKey:@"existing"];
//        }
//
//        NSOperationQueue* existingMessagesQueue = [existingMessagesQueues objectForKey:key];
//
//        return existingMessagesQueue;
//    }
//}
//
//- (NSOperationQueue*)mergeLocalChangesQueueForFolderWithObjectID:(NSManagedObjectID*)folderObjectID
//{
//    if(![folderObjectID isKindOfClass:[NSManagedObjectID class]])
//        return nil;
//
//    NSURL* key = folderObjectID.URIRepresentation;
//
//    if(!key)
//        return nil;
//
//    @synchronized(@"Operation Queues Lock")
//    {
//        if(![operationQueues objectForKey:@"mergeLocal"])
//            [operationQueues setObject:[NSDictionary new] forKey:@"mergeLocal"];
//
//        NSMutableDictionary* existingMessagesQueues = [[operationQueues objectForKey:@"mergeLocal"] mutableCopy];
//
//        if(![existingMessagesQueues objectForKey:key])
//        {
//            if(VERBOSE)
//                NSLog(@"Operation queue started (merge local), %ld queues", (unsigned long)existingMessagesQueues.count);
//
//            [existingMessagesQueues setObject:[NSOperationQueue new] forKey:key];
//
//            [operationQueues setObject:existingMessagesQueues forKey:@"mergeLocal"];
//        }
//
//        NSOperationQueue* existingMessagesQueue = [existingMessagesQueues objectForKey:key];
//
//        return existingMessagesQueue;
//    }
//}


- (MCOIMAPSession*)freshSession
{
    //[ThreadHelper ensureMainThread];

    return [self.quickAccessSession copyThisSession];
}

- (void)freshSessionWithScope:(void(^)(MCOIMAPSession* session, DisconnectOperation* disconnectOperation))scope
{
    //create a new session
    MCOIMAPSession* newSession = [self.quickAccessSession copyThisSession];

    if(!newSession)
    {
        NSLog(@"Failed to create session!!!");
        return;
    }

    DisconnectOperation* disconnectOperation = [DisconnectOperation operationWithIMAPSession:newSession withCallback:nil];

    //now execute the block in which the session may be used
    scope(newSession, disconnectOperation);

    //and disconnect
    NSOperationQueue* queue = [AccountCheckManager mailcoreOperationQueue];

    [queue addOperation:disconnectOperation];
}


- (void)notifyOfAnyNewMessages
{
    if(newMessageObjectIDs.count==0)
        return;

    [ThreadHelper runAsyncOnMain:^{

        //if the new message is very recent, download it immediately
        for(NSManagedObjectID* messageInstanceObjectID in newMessageObjectIDs)
        {
            NSError* error = nil;
            EmailMessageInstance* messageInstance = (EmailMessageInstance*)[MAIN_CONTEXT existingObjectWithID:messageInstanceObjectID error:&error];
            if(error)
                continue;

            BOOL urgent = [messageInstance.message.dateSent timeIntervalSinceNow]>-60*60;
            if([messageInstance.message.dateSent timeIntervalSinceNow]>-3*24*60*60)
                [DownloadHelper downloadMessageInstance:messageInstance urgent:urgent];
        }

        if(newMessageObjectIDs.count>3)
            [UserNotificationHelper notifyOfMessageBatch:newMessageObjectIDs.count];
        else
        {
            //TO DO: take out lock to guard against crashes due to multi-thread access
            NSArray* newMessageObjectIDsCopy = [newMessageObjectIDs copy];

            for(NSManagedObjectID* messageInstanceObjectID in newMessageObjectIDsCopy)
            {
                [UserNotificationHelper notifyOfMessage:messageInstanceObjectID];
            }
        }

        newMessageObjectIDs = [NSMutableArray new];

        [CoreDataHelper save];
    }];
}







#pragma mark - BATCH MESSAGE PROCESSING


//processes messages fetched from the server (in their entirety, as opposed to just the headers or flags)
- (void)processFetchedMessages:(NSArray*)fetchedMessages inFolderWithObjectID:(NSManagedObjectID*)folderSettingID withCallback:(void(^)(BOOL success, BOOL foundNewMessages))callback
{
    //[ThreadHelper ensureMainThread];

    //exit immediately if there is nothing to do
    if(!folderSettingID || fetchedMessages.count==0)
    {
        callback(NO, NO);
        return;
    }

    //make a new local context that can be thrown away as soon as the batch has been processed
    [ThreadHelper runSyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

        //this will be set to yes if any new messages have been found
        __block BOOL foundNew = NO;

        [self freshSessionWithScope:^(MCOIMAPSession *session, DisconnectOperation *disconnectOperation) {

        //recereate the folder setting in the local context
        NSError* error = nil;
        IMAPFolderSetting* localFolderSetting = (IMAPFolderSetting*)[localContext existingObjectWithID:folderSettingID error:&error];
        if(error || !localFolderSetting)
        {
            NSLog(@"Error creating folderSetting in local context!!! %@", error);
            callback(NO, NO);
            return;
        }


        //batch fetch the corresponding messages in the core data store

        //first collect all UIDs and messageIDs of the fetched server messages
        NSMutableSet* allUIDs = [NSMutableSet new];
        NSMutableSet* allMessageIDs = [NSMutableSet new];

        //the highest UID found among the server messages
        NSUInteger maxUID = 0;

        for(MCOIMAPMessage* serverMessage in [fetchedMessages reverseObjectEnumerator])
        {
            if(serverMessage.uid>maxUID)
                maxUID = serverMessage.uid;

            if(serverMessage.uid)
                [allUIDs addObject:@(serverMessage.uid)];
            else
                NSLog(@"Server message has no UID!!");

            if(serverMessage.header.messageID)
                [allMessageIDs addObject:serverMessage.header.messageID];
            else
                NSLog(@"Server message has no messageID!!");
        }

        //fetch all EmailMessageInstance objects with the corresponding UIDs that are either still in this folder or have been deleted/moved from it
        NSPredicate* UIDFetchPredicate = [NSPredicate predicateWithFormat:@"(uid IN %@) AND ((inFolder == %@) || (deletedFromFolder == %@) || (movedAwayFromFolder == %@))", allUIDs, localFolderSetting, localFolderSetting, localFolderSetting];

        NSFetchRequest* UIDFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"EmailMessageInstance"];
        [UIDFetchRequest setPredicate:UIDFetchPredicate];

        error = nil;

        NSArray* storeMessageInstancesByUID = [localContext executeFetchRequest:UIDFetchRequest error:&error];

        if(error)
        {
            NSLog(@"Error fetching UID store instances!!!");
        }

        NSArray* UIDsInStore = [storeMessageInstancesByUID valueForKey:@"uid"];


        //and all EmailMessage objects with the corresponding messageIDs
        NSPredicate* messageIDFetchPredicate = [NSPredicate predicateWithFormat:@"(messageid IN %@)", allMessageIDs];

        NSFetchRequest* messageIDFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"EmailMessage"];
        [messageIDFetchRequest setPredicate:messageIDFetchPredicate];

        error = nil;

        NSArray* storeMessagesByMessageID = [localContext executeFetchRequest:messageIDFetchRequest error:&error];

        if(error)
        {
            NSLog(@"Error fetching store messages by messageID!!!");
        }

        NSArray* messageIDsInStore = [storeMessagesByMessageID valueForKey:@"messageid"];


        for(MCOIMAPMessage* serverMessage in [fetchedMessages reverseObjectEnumerator])
        {
            NSInteger indexByUID = [UIDsInStore indexOfObject:@(serverMessage.uid)];

            if(indexByUID != NSNotFound)
            {
                EmailMessageInstance* storeMessageInstance = [storeMessageInstancesByUID objectAtIndex:indexByUID];

                if(storeMessageInstance)
                {
                    //the search by UID was successful
                    if(!storeMessageInstance.inFolder)
                    {
                        //the message is in either deleted or moved
                        //there is nothing to do at this stage
                        continue;
                    }
                    else
                    {
                        //the message is in the folder, as it should be
                        //sync the flags!
                        [MessageSyncHelper syncFlagsOnStoreMessageInstance:storeMessageInstance withServerMessage:serverMessage inFolder:localFolderSetting usingSession:session disconnectOperation:disconnectOperation withLocalContext:localContext];
                        continue;
                    }
                }
            }

            //search by messageID - maybe the message already exists in a different folder
            NSInteger indexByMessageID = [messageIDsInStore indexOfObject:serverMessage.header.messageID];

            if(indexByMessageID != NSNotFound)
            {
                EmailMessage* storeMessage = [storeMessagesByMessageID objectAtIndex:indexByMessageID];

                EmailMessageInstance* storeMessageInstance = [EmailMessageInstance findOrMakeNewInstanceForMessage:storeMessage inFolder:localFolderSetting withUID:@(serverMessage.uid) inContext:localContext];

                if(storeMessageInstance)
                {
                    //the search by messageID was successful
                    if(!storeMessageInstance.inFolder)
                    {
                        //the message is in either deleted or moved
                        //there is nothing to do at this stage
                        continue;
                    }
                    else
                    {
                        //the message is in the folder, as it should be
                        //sync the flags!
                        [MessageSyncHelper syncFlagsOnStoreMessageInstance:storeMessageInstance withServerMessage:serverMessage inFolder:localFolderSetting usingSession:session disconnectOperation:disconnectOperation withLocalContext:localContext];
                        continue;
                    }
                }
            }

            //no message was found - create a new one!

            BOOL alreadyHaveMessage = NO;

            BOOL alreadyHaveMessageInstance = NO;

            BOOL isSafe = [serverMessage.header extraHeaderValueForName:@"X-Mynigma-Safe-Message"]!=nil;

            BOOL isDeviceMessage = [serverMessage.header extraHeaderValueForName:@"X-Mynigma-Device-Message"]!=nil;


#if ULTIMATE
            //if the account hasn't been verified this could be a welcome message that has somehow ended up in an odd folder - check!
            IMAPAccountSetting* localAccountSetting = localFolderSetting.inIMAPAccount;
            IMAPAccount* account = localAccountSetting.account;
            if(!localAccountSetting.hasBeenVerified.boolValue)
                [account.registrationHelper checkIfMessageIsWelcomeMail:serverMessage];
#endif

            EmailMessage* storeMessage = nil;

            if(isSafe)
                storeMessage = [MynigmaMessage findOrMakeMessageWithMessageID:serverMessage.header.messageID inContext:localContext messageFound:&alreadyHaveMessage];
            else if(isDeviceMessage)
                storeMessage = [DeviceMessage findOrMakeMessageWithMessageID:serverMessage.header.messageID inContext:localContext messageFound:&alreadyHaveMessage];
            else
                storeMessage = [EmailMessage findOrMakeMessageWithMessageID:serverMessage.header.messageID inContext:localContext messageFound:&alreadyHaveMessage];

            EmailMessageInstance* storeMessageInstance = [EmailMessageInstance findOrMakeNewInstanceForMessage:storeMessage inFolder:localFolderSetting withUID:@(serverMessage.uid) inContext:localContext alreadyFoundOne:&alreadyHaveMessageInstance];

            if(!storeMessage || !storeMessageInstance)
            {
                NSLog(@"Failed to create fetched message!! %@ %@", storeMessage, storeMessageInstance);
                continue;
            }

            if(!alreadyHaveMessage)
                [MessageSyncHelper populateMessage:storeMessage withCoreMessage:serverMessage inFolder:localFolderSetting andContext:localContext];

            if(alreadyHaveMessageInstance)
            {
                NSLog(@"Error: already had EmailMessageInstance!!!");
            }

            //there should have been no EmailMessageInstance, so will definitely need to populate this one...
            [MessageSyncHelper populateMessageInstance:storeMessageInstance withCoreMessage:serverMessage inFolder:localFolderSetting andContext:localContext];

            if([storeMessage isSafe] && [storeMessageInstance isInSpamFolder])
            {
                //safe messages should be moved out of the spam folder
                IMAPFolderSetting* allMailOrInbox = storeMessageInstance.accountSetting.allMailOrInboxFolder;
                if(allMailOrInbox)
                    [storeMessageInstance moveToFolder:allMailOrInbox];
            }

            //user notifications
            NSInteger flags = serverMessage.flags;

            NSInteger seenFlag = flags & MCOMessageFlagSeen;

            if(seenFlag == 0)
                if([storeMessageInstance isInAllMailFolder] || [storeMessageInstance isInInboxFolder])
                {
                    //post a user notification, provided that the message is recent (less than a week old)
                    if([serverMessage.header.date timeIntervalSinceNow]>-24*60*60*7)
                    {
                        [localContext obtainPermanentIDsForObjects:@[storeMessageInstance] error:nil];

                        [UserNotificationHelper queueMessageInstanceForNotification:storeMessageInstance];
                        foundNew = YES;
                    }
                }
        }

        if(maxUID>localFolderSetting.highestUID.integerValue)
        {
            [localFolderSetting setHighestUID:@(maxUID)];
        }

        error = nil;
        [localContext save:&error];
        if(error)
            NSLog(@"Error saving local context!! %@",error);

        [UserNotificationHelper postNotifications];

        }];

        callback(YES, foundNew);
    }];
}



//processes messages whose flags (but not structure etc.) have been fetched from the server
- (void)processFetchedFlags:(NSArray*)fetchedMessages inFolderWithObjectID:(NSManagedObjectID*)folderSettingID usingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation 
{
    [ThreadHelper ensureMainThread];

    if(!folderSettingID)
    {
        NSLog(@"No folderSettingID passed to processFetchedFlags!!");
        return;
    }

    //collects new messages for user notifications
    __block NSMutableArray* newMessageInstances = [NSMutableArray new];

    //operate in batches of (messageBatchSize) messages to avoid keeping too many messages is memory
    const NSInteger messageBatchSize = 100;

    for(NSInteger loopCounter = 0; loopCounter<fetchedMessages.count;loopCounter += messageBatchSize)
    {
        NSArray* messagesBatch = [fetchedMessages subarrayWithRange:NSMakeRange(loopCounter, MIN(messageBatchSize, fetchedMessages.count-loopCounter))];

        //make a new local context that can be thrown away as soon as the batch has been processed
        [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

            NSError* error = nil;
            IMAPFolderSetting* localFolderSetting = (IMAPFolderSetting*)[localContext existingObjectWithID:folderSettingID error:&error];
            if(error || !localFolderSetting)
            {
                NSLog(@"Error creating folderSetting in local context!!! %@", error);
                return;
            }

            //go through the messages on the server and sync them with the messages in the store

            for(MCOIMAPMessage* serverMessage in messagesBatch)
            {
                if(VERBOSE)
                    NSLog(@"Processing flags: %@ - %@", serverMessage.header.date, serverMessage.header.subject);

                [MessageSyncHelper processUpdatedFlagsForMessage:serverMessage inFolder:localFolderSetting withContext:localContext usingSession:session disconnectOperation:disconnectOperation newMessageInstancesArray:newMessageInstances];
            }
        }];

        [SelectionAndFilterHelper refreshAllMessages];
    }
}


/**Goes through local messages and deals with local additions and deletions*/
- (void)mergeLocalChangesInFolder:(IMAPFolderSetting*)folderSetting userInitiated:(BOOL)userInitiated
{
    [MergeLocalChangesHelper mergeLocalChangesForAccount:self inFolder:folderSetting userInitiated:userInitiated];
}

- (NSSet*)setFromMCOIndexSet:(MCOIndexSet*)indexSet
{
    NSMutableSet* newSet = [NSMutableSet new];

    [indexSet enumerateIndexes:^(uint64_t idx) {
        [newSet addObject:@(idx)];
    }];

    return newSet;
}

/**Checks messages in the UID range presumed to be already present in the store*/
- (void)checkOldMessagesUpToUID:(NSInteger)passedMaxUID inFolderWithObjectID:(IMAPFolderSetting*)folderSetting userInitiated:(BOOL)userInitiated
{
    [ThreadHelper ensureMainThread];

    if(![AccountCheckManager shouldStartCheckingOldMessagesInFolder:folderSetting userInitiated:userInitiated])
        return;

    __block NSInteger maxUID = passedMaxUID;

    __block NSManagedObjectID* folderObjectID = folderSetting.objectID;

    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

        [self freshSessionWithScope:^(MCOIMAPSession *session, DisconnectOperation *disconnectOperation) {

            [disconnectOperation setCallback:^(NSError* error){

                [ThreadHelper runAsyncOnMain:^{

                    [AccountCheckManager didCheckOldMessagesInFolder:folderSetting];

                }];
            }];


        IMAPFolderSetting* localFolderSetting = [IMAPFolderSetting folderSettingWithObjectID:folderObjectID inContext:localContext];

        //first fetch the UIDs up to and including maxUID from the server (just the UIDs)
        //do it in batches

        NSString* folderPath = localFolderSetting.path;

        //headers are needed for the messageID to be correct(!)
        MCOIMAPMessagesRequestKind requestKind = MCOIMAPMessagesRequestKindUid;

        if([localFolderSetting.inIMAPAccount isKindOfClass:[GmailAccountSetting class]])
            requestKind |= MCOIMAPMessagesRequestKindGmailLabels;


        //the minimum UID to check is given by downloadedFromUID, but this should be respected only on iOS, as on the Mac this is used to fetch old messages not downloaded in the initial fetch
        //on iOS, old messages are fetched in small batches and only as needed
        NSInteger minimumUIDToFetch = 1;

#if TARGET_OS_IPHONE
        minimumUIDToFetch = localFolderSetting.downloadedFromUID?localFolderSetting.downloadedFromUID.integerValue:1;
#endif


        //split the UIDs into batches
        NSArray* batches = [IMAPAccount splitIndexSet:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(minimumUIDToFetch, maxUID+1)] intoMCOIndexSetBatchesOfSize:1000];

        //perform the operations in reverse order

        __block BOOL allSuccessful = YES;

        for(MCOIndexSet* batch in batches)
        {
            FetchMessagesOperation* operation = [FetchMessagesOperation fetchMessagesByUIDOperationWithRequestKind:requestKind indexSet:batch folderPath:folderPath session:session withCallback:^(NSError *error, NSArray *fetchedUIDs, MCOIndexSet *vanishedMessages){

                if(error)
                {
                    allSuccessful = NO;
                    NSLog(@"Error fetching UIDs of existing messages: %@, %@", error, folderPath);
                    return;
                }

                [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

                    NSError* error = nil;
                    IMAPFolderSetting* localFolderSetting = (IMAPFolderSetting*)[localContext existingObjectWithID:folderObjectID error:&error];
                    if(error || !localFolderSetting)
                    {
                        NSLog(@"Error creating local folder setting!!! %@", error.localizedDescription);
                        return;
                    }

                    NSMutableIndexSet* unknownMessageUIDs = [NSMutableIndexSet new];

                    NSMutableIndexSet* existingMessageUIDs = [NSMutableIndexSet new];

                    NSIndexSet* UIDCollection = [UIDHelper UIDsInFolder:localFolderSetting];

                    [self processUIDs:fetchedUIDs inFolder:localFolderSetting inContext:localContext UIDsOfMessagesWhoseMessageIDNeedsToBeFetched:unknownMessageUIDs UIDsOfMessagesWhoseFlagsNeedToBeSynced:existingMessageUIDs UIDCollection:UIDCollection];

                    if(VERBOSE || VERBOSE_CHECK)
                    {
                        NSLog(@"Unknown UIDs (%@): %@", localFolderSetting.displayName, unknownMessageUIDs);
                        NSLog(@"Existing UIDs (%@): %@", localFolderSetting.displayName, existingMessageUIDs);
                    }


//                    //reset UIDs for any messages not found on the server
//                    NSSet* UIDs = [self setFromMCOIndexSet:batch];
//
//                    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"uid in %@", UIDs];

                    //need to deal with messages that are found in the store, but weren't returned from the server

                    NSMutableIndexSet* storeMessageUIDsWithinRange = [NSMutableIndexSet new];

                    [batch enumerateIndexes:^(uint64_t index) {
                        if([UIDCollection containsIndex:(NSUInteger)index])
                            [storeMessageUIDsWithinRange addIndex:(NSUInteger)index];
                    }];


                    [storeMessageUIDsWithinRange removeIndexes:unknownMessageUIDs];
                    [storeMessageUIDsWithinRange removeIndexes:existingMessageUIDs];

                    //need to delete these instances - they are no longer found on the server(!)
                    if(storeMessageUIDsWithinRange.count > 0)
                    {
                        NSMutableArray* missingIndexes = [NSMutableArray new];
                        [storeMessageUIDsWithinRange enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
                            [missingIndexes addObject:@(index)];
                        }];

                        NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"EmailMessageInstance"];

                        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"self.uid IN %@", missingIndexes]];

                        NSArray* storeMessagesWhoseUIDsAreNotOnServer = [localContext executeFetchRequest:fetchRequest error:nil];

                        for(EmailMessageInstance* messageInstance in storeMessagesWhoseUIDsAreNotOnServer)
                        {
                            [messageInstance UIDNotFoundOnServerWithContext:localContext];
                        }
                    }

                    //now fetch messageIDs of unkown messages
                    //this might help us find them in the store

                    //[session fetchMessagesByUIDWithFolder:folderPath requestKind:MCOIMAPMessagesRequestKindHeaders uids: withCallback:]

                    if (unknownMessageUIDs.count != 0)
                    {
                        if([self fetchNewMessagesWithUIDs:unknownMessageUIDs inFolder:localFolderSetting folderPath:localFolderSetting.path userInitiated:NO])
                        {
                            if(allSuccessful)
                            {
                                if(localFolderSetting.downloadedFromUID.integerValue<=maxUID+1)
                                {
                                    NSInteger newLowestIndex = unknownMessageUIDs.firstIndex;
                                    if([batches indexOfObject:batch]==batches.count-1)
                                        newLowestIndex = 0;
                                    if(localFolderSetting.downloadedFromUID.integerValue>newLowestIndex)
                                        [localFolderSetting setDownloadedFromUID:@(newLowestIndex)];
                                }
                            }
                        }
                        else
                            allSuccessful = NO;
                      }
//                    if(existingMessageUIDs.count>0)
//                    {
//                        if(VERBOSE)
//                            NSLog(@"Fetching flags for UIDs (%@): %@", localFolderSetting.displayName, [fetchedUIDs valueForKey:@"uid"]);
//
//                        [self fetchFlagsOfMessagesWithUIDs:existingMessageUIDs inFolder:localFolderSetting usingSession:session];
//                    }
                }];
            }];

            [operation setVeryLowPriority];

            [operation addToMailCoreQueueWithDisconnectOperation:disconnectOperation];
        }

        }];
    }];
}

- (void)checkOldMessagesWithMODSEQUpToUID:(NSInteger)passedMaxUID inFolder:(IMAPFolderSetting*)folderSetting userInitiated:(BOOL)userInitiated withCallback:(void(^)(void))callback
{
    if(![AccountCheckManager shouldStartCheckingOldMessagesWithMODSEQInFolder:folderSetting userInitiated:userInitiated])
        return;

    __block NSManagedObjectID* folderObjectID = folderSetting.objectID;
    
    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

        [self freshSessionWithScope:^(MCOIMAPSession *session, DisconnectOperation *disconnectOperation) {

            [disconnectOperation setCallback:^(NSError *error) {

                [ThreadHelper runAsyncOnMain:^{

                [AccountCheckManager didCheckOldMessagesWithMODSEQInFolder:folderSetting];

                }];
            }];

        IMAPFolderSetting* localFolderSetting = [IMAPFolderSetting folderSettingWithObjectID:folderObjectID inContext:localContext];

        if(!localFolderSetting)
        {
            NSLog(@"Error creating local folder setting!!!");
            return;
        }

        if(!localFolderSetting.modSequenceValue)
        {
            NSLog(@"No MODSEQ value set!");
            return;
        }

        NSInteger modSeqValue = localFolderSetting.modSequenceValue.integerValue;

        MCOIndexSet* indexSet = [MCOIndexSet indexSetWithRange:MCORangeMake(1, passedMaxUID)];

        if(VERBOSE)
            NSLog(@"Syncing with MODSEQ (%@): %@", localFolderSetting.displayName, indexSet);

        SyncMessagesOperation* syncOperation = [SyncMessagesOperation syncWithMODSEQValue:modSeqValue toFolder:localFolderSetting.path uids:indexSet session:session withCallback:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages){

            //process the fetched messages
            [self processFetchedFlags:messages inFolderWithObjectID:folderObjectID usingSession:session disconnectOperation:disconnectOperation];

            [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *callbackContext) {

                IMAPFolderSetting* callbackFolderSetting = [IMAPFolderSetting folderSettingWithObjectID:folderObjectID inContext:callbackContext];

                //messages that don't exist in the store should be fetched
                NSMutableIndexSet* newMessageUIDs = [NSMutableIndexSet new];

                for(MCOIMAPMessage* message in messages)
                {
                    if(![EmailMessageInstance findExistingInstanceWithMessageID:message.header.messageID inAccount:callbackFolderSetting.accountSetting inContext:callbackContext])
                    {
                        if(![EmailMessageInstance haveRemovedInstanceWithMessageID:message.header.messageID andUid:@(message.uid) inFolder:callbackFolderSetting inContext:callbackContext])
                            [newMessageUIDs addIndex:message.uid];
                    }
                }

                if(newMessageUIDs.count>0)
                {
                    if(VERBOSE)
                        NSLog(@"Fetching new messages with UIDs (%@): %@", callbackFolderSetting.displayName, newMessageUIDs);

                    [self fetchNewMessagesWithUIDs:newMessageUIDs inFolder:callbackFolderSetting folderPath:callbackFolderSetting.path userInitiated:NO];
                }

                //now delete the vanished messages (vanishedMessages only with IMAP capability: CONDSTORE / QRESYNC, so far only used by Fastmail)
                
                if(vanishedMessages.count>0)
                {
                    NSSet* setOfUIDsToBeDeleted = [self setFromMCOIndexSet:vanishedMessages];

                    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"uid in %@", setOfUIDsToBeDeleted];

                    NSSet* messageInstancesToBeDeleted = nil;

                    @try {
                        messageInstancesToBeDeleted = [NSSet setWithSet:[callbackFolderSetting.containsMessages filteredSetUsingPredicate:predicate]];
                    }
                    @catch (NSException *exception) {
                        NSLog(@"Caught exception while collecting message instances to be deleted: %@", exception);
                        return;
                    }
                    @finally {
                    }

                    for(EmailMessageInstance* messageInstance in messageInstancesToBeDeleted)
                    {
                        [messageInstance deleteCompletelyWithContext:callbackContext];
                    }

                    NSError* error = nil;
                    [callbackContext save:&error];
                    if(error)
                        NSLog(@"Error saving local context!! %@", error);
                }

                //only execute the callback on success, as it will increment the modseq value
                if(!error)
                    callback();

            }];
        }];

        [syncOperation setVeryLowPriority];

            [syncOperation addToMailCoreQueueWithDisconnectOperation:disconnectOperation];
        }];
    }];

}






#pragma mark - SENDING


/**CALL ON MAIN*/
- (void)sendAnyUnsentMessages
{
    [ThreadHelper ensureMainThread];

    IMAPFolderSetting* outboxSetting = accountSetting.outboxFolder;
    if(outboxSetting)
        for(EmailMessageInstance* messageInstance in outboxSetting.containsMessages)
        {
            [SendingManager sendOutboxMessageInstance:messageInstance fromAccount:self withCallback:^(NSInteger result,NSError* error) {}];
        }
}


#pragma mark - DESCRIPTION

- (NSString*)description
{
    __block NSMutableString* returnString = [NSMutableString new];

    [ThreadHelper runAsyncOnMain:^{

        if(accountSetting)
        {
            [returnString appendFormat:@"IMAPAccount: %@\n",accountSetting.displayName];
        }
        else
        {
            [returnString appendFormat:@"IMAPAccount with no setting ID\n"];
        }

        MCOIMAPSession* imapSession = self.quickAccessSession;

        [returnString appendFormat:@"Email: %@\n--IMAPSession--\nServer: %@\nUser Name: %@\nPassword: %@\nEncryption: %d\nPort: %d\n--SMTPSession--\nServer: %@\nUser Name: %@\nPassword: %@\nEncryption: %d\nPort: %d\n\n", self.emailAddress, imapSession.hostname, imapSession.username, @"--not shown--"/*imapSession.password*/, (int)imapSession.connectionType, imapSession.port, smtpSession.hostname, smtpSession.username, @"--not shown--"/*smtpSession.password*/, (int)smtpSession.connectionType, smtpSession.port];

        [returnString appendFormat:@"Session helpers (%ld):\n", (unsigned long)sessionHelpers.count];

        for(IMAPSessionHelper* sessionHelper in sessionHelpers)
        {
            [returnString appendFormat:@"%@\n", sessionHelper];
        }
    }];

    return returnString;
}



/**Sets all UIDs in this folder to nil - Use when the UID validity changes*/
- (void)removeUIDsFromAllMessagesInFolder:(IMAPFolderSetting*)folderSetting
{
    for(EmailMessageInstance* messageInstance in folderSetting.containsMessages)
    {
        [messageInstance changeUID:nil];
    }
}


/**Splits the index set into an array of batches sorted in reverse order*/
+ (NSArray*)splitIndexSet:(NSIndexSet*)indexSet intoMCOIndexSetBatchesOfSize:(NSInteger)batchSize
{
    NSMutableArray* returnArray = [NSMutableArray new];

    if(indexSet.count==0)
    {
        return returnArray;
    }

    MCOIndexSet* currentMCOIndexSet = [MCOIndexSet indexSet];

    NSInteger index = indexSet.lastIndex;

    while(index > 0 && index != NSNotFound)
    {
        [currentMCOIndexSet addIndex:index];

        if(currentMCOIndexSet.count>=batchSize)
        {
            [returnArray addObject:currentMCOIndexSet];
            currentMCOIndexSet = [MCOIndexSet indexSet];
        }

        index = [indexSet indexLessThanIndex:index];
    }

    if(currentMCOIndexSet.count>0)
        [returnArray addObject:currentMCOIndexSet];

    return returnArray;
}

/**Sorts a list of fetched messages with headers into new and existing messages*/
- (void)processHeaders:(NSArray*)messageHeaders inFolder:(IMAPFolderSetting*)localFolderSetting inContext:(NSManagedObjectContext*)localContext UIDsOfMessagesWhoseStructureNeedsToBeFetched:(NSMutableIndexSet*)newMessageUIDs UIDsOfMessagesWhoseFlagsNeedToBeSynced:(NSMutableIndexSet*)syncMessageUIDs
{
    [ThreadHelper ensureLocalThread:localContext];

    for(MCOIMAPMessage* message in messageHeaders)
    {
        @autoreleasepool
        {
            NSString* messageID = message.header.messageID;

            EmailMessageInstance* messageInstance = [EmailMessageInstance findExistingInstanceWithMessageID:messageID andUid:@(message.uid) inFolder:localFolderSetting inContext:localContext];

            if(messageInstance)
            {
                [syncMessageUIDs addIndex:message.uid];
            }
            else
            {
                if(![EmailMessageInstance haveRemovedInstanceWithMessageID:messageID andUid:@(message.uid) inFolder:localFolderSetting inContext:localContext])
                    [newMessageUIDs addIndex:message.uid];
            }
        }
    }
}


/**Sorts a list of messages with just uids into new and existing messages*/
- (void)processUIDs:(NSArray*)messageUIDs inFolder:(IMAPFolderSetting*)localFolderSetting inContext:(NSManagedObjectContext*)localContext UIDsOfMessagesWhoseMessageIDNeedsToBeFetched:(NSMutableIndexSet*)newMessageUIDs UIDsOfMessagesWhoseFlagsNeedToBeSynced:(NSMutableIndexSet*)syncMessageUIDs
{
    [ThreadHelper ensureLocalThread:localContext];

    [self processUIDs:messageUIDs inFolder:localFolderSetting inContext:localContext UIDsOfMessagesWhoseMessageIDNeedsToBeFetched:newMessageUIDs UIDsOfMessagesWhoseFlagsNeedToBeSynced:syncMessageUIDs UIDCollection:nil];
}

- (void)processUIDs:(NSArray*)messageUIDs inFolder:(IMAPFolderSetting*)localFolderSetting inContext:(NSManagedObjectContext*)localContext UIDsOfMessagesWhoseMessageIDNeedsToBeFetched:(NSMutableIndexSet*)newMessageUIDs UIDsOfMessagesWhoseFlagsNeedToBeSynced:(NSMutableIndexSet*)syncMessageUIDs UIDCollection:(NSIndexSet*)UIDCollection
{
    //[ThreadHelper ensureLocalThread:localContext];

    for(MCOIMAPMessage* message in messageUIDs)
    {
        @autoreleasepool
        {
            if(message.uid <= 0)
                continue;

            if(UIDCollection)
            {
                if([UIDCollection containsIndex:message.uid])
                {
                    [syncMessageUIDs addIndex:message.uid];
                }
                else
                {
                    [newMessageUIDs addIndex:message.uid];
                }

                continue;
            }

            EmailMessageInstance* messageInstance = [EmailMessageInstance findExistingInstanceWithMessageID:nil andUid:@(message.uid) inFolder:localFolderSetting inContext:localContext];

            if(messageInstance)
            {
                [syncMessageUIDs addIndex:message.uid];
            }
            else
            {
                if(![EmailMessageInstance haveRemovedInstanceWithMessageID:nil andUid:@(message.uid) inFolder:localFolderSetting inContext:localContext])
                    [newMessageUIDs addIndex:message.uid];
            }
        }
    }
}

/**Fetches headers & structure - use for messages not yet present in the store*/
- (BOOL)fetchNewMessagesWithUIDs:(NSIndexSet*)UIDsOfNewMessages inFolder:(IMAPFolderSetting*)folderSetting folderPath:(NSString*)folderPath userInitiated:(BOOL)userInitiated
{
    //will be called later
//    if(![AccountCheckManager shouldStartCheckingNewMessagesInFolder:folderSetting  userInitiated:userInitiated])
//        return NO;
    
    NSString* folderName = folderSetting.displayName;
    NSString* accountName = folderSetting.accountSetting.displayName;
    
    __block BOOL returnValue = NO;

    [self freshSessionWithScope:^(MCOIMAPSession *session, DisconnectOperation *disconnectOperation) {

        [disconnectOperation setCallback:^(NSError* error){

//            [ThreadHelper runAsyncOnMain:^{

            [AccountCheckManager didCheckNewMessagesInFolder:folderName inAccount:accountName];

//            }];
    }];

    returnValue = [self fetchNewMessagesWithUIDs:UIDsOfNewMessages inFolder:folderSetting folderPath:folderPath session:session disconnectOperation:disconnectOperation userInitiated:userInitiated];

    }];

    return returnValue;
}


- (BOOL)fetchNewMessagesWithUIDs:(NSIndexSet*)UIDsOfNewMessages inFolder:(IMAPFolderSetting*)folderSetting folderPath:(NSString*)folderPath session:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation userInitiated:(BOOL)userInitiated
{
    if(!UIDsOfNewMessages.count)
        return YES;

    if(![AccountCheckManager shouldStartCheckingNewMessagesInFolder:folderSetting userInitiated:userInitiated])
        return NO;

    __block BOOL allSuccessful = YES;

    MCOIMAPMessagesRequestKind requestKind = MCOIMAPMessagesRequestKindHeaders | MCOIMAPMessagesRequestKindStructure |
    MCOIMAPMessagesRequestKindInternalDate | MCOIMAPMessagesRequestKindHeaderSubject |
    MCOIMAPMessagesRequestKindFlags | MCOIMAPMessagesRequestKindFullHeaders | MCOIMAPMessagesRequestKindExtraHeaders;

    if([accountSetting isKindOfClass:[GmailAccountSetting class]])
        requestKind |= MCOIMAPMessagesRequestKindGmailLabels;

    //split the UIDs again - into smaller batches
    NSArray* batches = [IMAPAccount splitIndexSet:UIDsOfNewMessages intoMCOIndexSetBatchesOfSize:100];

    for(MCOIndexSet* batch in batches)
    {
        FetchMessagesOperation* operation = [FetchMessagesOperation fetchMessagesByUIDOperationWithRequestKind:requestKind indexSet:batch folderPath:folderPath session:session withCallback:^(NSError* error, NSArray* messages, MCOIndexSet* vanishedMessages)
         {
//             [MAIN_CONTEXT performBlock:^{
//
             if(VERBOSE)
                 NSLog(@"Done fetching messages (%@): %@", folderPath, batch);

             if(error)
                 allSuccessful = NO;

             if(VERBOSE_CHECK)
             {
                 NSLog(@"%@ | %@ | Processing %ld old Messages: %@", accountSetting.emailAddress,folderPath,(unsigned long)messages.count,[messages valueForKey:@"uid"]);
             }
             [self processFetchedMessages:messages inFolderWithObjectID:folderSetting.objectID withCallback:^(BOOL success, BOOL foundNewMessages) {

             }];
//             }];

         }];

        if(userInitiated)
            [operation setHighPriority];
        else
            [operation setMediumPriority];

        [operation addToMailCoreQueueWithDisconnectOperation:disconnectOperation];
    }

    if(VERBOSE)
        NSLog(@"Fetch new messages queue done (%@)", folderPath);

    return allSuccessful;
}

/** Fetches headers & structure - use for messages not yet present in the store*/
- (BOOL)fetchNewMessagesWithNumbers:(NSIndexSet*)numbersOfNewMessages inFolderSetting:(IMAPFolderSetting*)folderSetting folderPath:(NSString*)folderPath userInitiated:(BOOL)userInitiated
{
    if(![AccountCheckManager shouldStartCheckingNewMessagesInFolder:folderSetting  userInitiated:userInitiated])
        return NO;

    __block BOOL allSuccessful = YES;
    
    NSString* folderName = folderSetting.displayName;
    NSString* accountName = folderSetting.accountSetting.displayName;

    [self freshSessionWithScope:^(MCOIMAPSession *session, DisconnectOperation *disconnectOperation) {

        [disconnectOperation setCallback:^(NSError *error) {

//            [ThreadHelper runAsyncOnMain:^{

            [AccountCheckManager didCheckNewMessagesInFolder:folderName inAccount:accountName];

//            }];
    }];

    MCOIMAPMessagesRequestKind requestKind = MCOIMAPMessagesRequestKindHeaders | MCOIMAPMessagesRequestKindStructure |
    MCOIMAPMessagesRequestKindInternalDate | MCOIMAPMessagesRequestKindHeaderSubject |
    MCOIMAPMessagesRequestKindFlags | MCOIMAPMessagesRequestKindFullHeaders | MCOIMAPMessagesRequestKindExtraHeaders;

    if([accountSetting isKindOfClass:[GmailAccountSetting class]])
        requestKind |= MCOIMAPMessagesRequestKindGmailLabels;

    //split the UIDs again - into smaller batches
    NSArray* batches = [IMAPAccount splitIndexSet:numbersOfNewMessages intoMCOIndexSetBatchesOfSize:100];

    for(MCOIndexSet* batch in batches)
    {
        FetchMessagesOperation* operation = [FetchMessagesOperation fetchMessagesByNumberOperationWithRequestKind:requestKind indexSet:batch folderPath:folderPath session:session withCallback:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages){

             if(VERBOSE)
                 NSLog(@"Done fetching messages (%@): %@", folderPath, batch);

             if(error)
                 allSuccessful = NO;

             [self processFetchedMessages:messages inFolderWithObjectID:folderSetting.objectID withCallback:^(BOOL success, BOOL foundNewMessages) {

             }];

         }];

        if(userInitiated)
            [operation setHighPriority];
        else
            [operation setMediumPriority];

        [operation addToMailCoreQueueWithDisconnectOperation:disconnectOperation];
    }

    }];

    return allSuccessful;
}


/** Fetches only flags - use for messages already present in the store*/
- (void)fetchFlagsOfMessagesWithUIDs:(NSIndexSet*)UIDsOfExistingMessages inFolder:(IMAPFolderSetting*)folderSetting usingSession:(MCOIMAPSession*)session
{
    //MCOIMAPMessagesRequestKind requestKind = MCOIMAPMessagesRequestKindFlags;

    //NSManagedObjectID* folderSettingObjectID = folderSetting.objectID;

    //if([accountSetting isKindOfClass:[GmailAccountSetting class]])
    //    requestKind |= MCOIMAPMessagesRequestKindGmailLabels;

    //    [self splitIndexSet:UIDsOfExistingMessages intoMCOIndexSetBatchesOfSize:50 andPerformOnEachBatch:^(MCOIndexSet *indexBatch) {
    //
    //        [session fetchMessagesByUIDWithFolder:folderSetting.path requestKind:requestKind uids:indexBatch withCallback:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages)
    //         {
    //             [self processFetchedFlags:messages inFolderWithObjectID:folderSettingObjectID usingSession:session];
    //         }];
    //    }];
}


#pragma mark - ACCOUNT CHECKS


//- (void)checkAndUpdateDeviceList
//{
//    [ThreadHelper ensureMainThread];
//
//    return;
//
//    if(!self.accountSetting.mynigmaFolder)
//    {
//        NSLog(@"Missing Mynigma folder!!");
//        return;
//    }
//
//    //list all UIDs in folder
//    [self.mainSession listUIDsInFolder:self.accountSetting.mynigmaFolder.path withCallback:^(NSArray *uids, NSError *error) {
//        if(error)
//        {
//            NSLog(@"Error listing UIDs in Mynigma folder: %@", error);
//            return;
//        }
//
//        //now get the structure
//        //[self.mainSession fetchMessagesByUIDWithFolder:<#(NSString *)#> requestKind:<#(MCOIMAPMessagesRequestKind)#> uids:<#(MCOIndexSet *)#> withCallback:<#^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages)callback#>]
//    }];
//}


/**Checks the folder (RUN ON MAIN THREAD)*/
- (void)checkFolder:(IMAPFolderSetting*)folderSetting userInitiated:(BOOL)userInitiated
{
    if(![AccountCheckManager shouldStartCheckingFolder:folderSetting userInitiated:userInitiated])
        return;

    [ThreadHelper ensureMainThread];

    NSManagedObjectID* folderSettingObjectID = folderSetting.objectID;

    NSString* folderPath = folderSetting.path;

    if(!self.quickAccessSession || !folderSetting || !folderSetting.path)
    {
        NSLog(@"Error before checking folder! %@ %@ %u", self, folderSetting.path,folderSetting.uidNext.unsignedIntValue);

        [AccountCheckManager didCheckFolder:folderSetting error:[NSError errorWithDomain:@"MynigmaFolderCheck" code:1 userInfo:nil] foundNewMessages:NO];
        return;
    }

    //first get the folder info (containing uidValidity etc.)
    [self freshSessionWithScope:^(MCOIMAPSession *infoSession, DisconnectOperation *disconnectOperation) {

    if(infoSession)
    {
        FolderInfoOperation* infoOperation  = [FolderInfoOperation operationWithFolderPath:folderPath usingSession:infoSession withCallback:^(NSError *error, MCOIMAPFolderInfo *info){

            [ThreadHelper runSyncOnMain:^{

             if(error)
             {
                 NSLog(@"Error fetching folder info for folder %@ (%@): %@", folderPath, folderSetting.accountSetting.displayName, error.localizedDescription);

                 [AccountCheckManager didCheckFolder:folderSetting error:error foundNewMessages:NO];

                 return;
             }
             //first check uidValidity. if incorrect, fetch the messageIDs and update the uids in the store

             if(info.uidValidity==folderSetting.uidValidity.integerValue)
             {
                 NSInteger uidNext = folderSetting.uidNext.integerValue;
                 if(uidNext==-1)
                     uidNext = 1;


                 //the ones from uidNext onwards first - this allows new messages to be processed immediately
                 //re-use the infoSession to make this as fast as possible
                 NSInteger maxUID = folderSetting.highestUID.integerValue;

                 //quick "fix" for bug where initial message download fails and old messages are never fetched
                 //make sure at least the latest dozen messages are fetched again
                 //need to fix this properly when we find the time...
                 NSInteger minIndex = MIN(maxUID, uidNext) - 12;

                 NSInteger maxIndex = MAX(maxUID, uidNext - 1);

                 MCOIndexSet* indexSet = [MCOIndexSet indexSetWithRange:MCORangeMake(minIndex, UINT64_MAX - minIndex)];

                 MCOIMAPMessagesRequestKind requestKind = MCOIMAPMessagesRequestKindHeaders | MCOIMAPMessagesRequestKindStructure | MCOIMAPMessagesRequestKindFlags | MCOIMAPMessagesRequestKindFullHeaders | MCOIMAPMessagesRequestKindExtraHeaders | MCOIMAPMessagesRequestKindUid;

                 if([accountSetting isKindOfClass:[GmailAccountSetting class]])
                     requestKind |= MCOIMAPMessagesRequestKindGmailLabels;


                 if(VERBOSE_CHECK)
                 {
                     NSLog(@"%@ | %@ | Checking from UID min(%ld, %ld)",accountSetting.emailAddress,folderPath,(long)maxUID,(long)uidNext);
                 }


                 FetchMessagesOperation* fetchOperation = [FetchMessagesOperation fetchMessagesByUIDOperationWithRequestKind:requestKind indexSet:indexSet folderPath:folderPath session:infoSession withCallback:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages)
                  {
                      if(VERBOSE_CHECK)
                      {
                          NSLog(@" %@ | %@ | Processing %ld new Messages: %@",accountSetting.emailAddress,folderPath,(long)messages.count,[messages valueForKey:@"uid"]);
                      }

                      [self processFetchedMessages:messages inFolderWithObjectID:folderSetting.objectID withCallback:^(BOOL success, BOOL foundNewMessages) {

                          [AccountCheckManager didCheckFolder:folderSetting error:error foundNewMessages:foundNewMessages];

                          if(!error)
                      {
                          [ThreadHelper runAsyncOnMain:^{
                              IMAPFolderSetting* mainFolderSetting = [IMAPFolderSetting folderSettingWithObjectID:folderSettingObjectID inContext:MAIN_CONTEXT];
                              [mainFolderSetting setUidNext:@(info.uidNext)];
                          }];
                      }
                      }];
                  }];

                 if(userInitiated)
                     [fetchOperation setHighPriority];
                 else
                     [fetchOperation setMediumPriority];

                 [fetchOperation addToMailCoreQueueWithDisconnectOperation:disconnectOperation];


                 //simultaneously check the ones up to and excluding uidNext - and remove the ones that have been deleted locally, fetch the ones that aren't in the store

                 if(VERBOSE_CHECK)
                 {
                     NSLog(@"%@ | %@ | Checking old msgs to UID max(%ld, %ld)",accountSetting.emailAddress,folderPath,(long)maxUID,(long)uidNext);
                 }

                     if([self canModSeq])
                     {
                         if(folderSetting.modSequenceValue && folderSetting.modSequenceValue.integerValue!=info.modSequenceValue)
                         {
                             [self checkOldMessagesWithMODSEQUpToUID:maxIndex inFolder:folderSetting userInitiated:userInitiated withCallback:^{

                                 NSInteger modSeqValue = (NSInteger)info.modSequenceValue;

                                 [ThreadHelper runAsyncOnMain:^{
                                     IMAPFolderSetting* mainFolderSetting = [IMAPFolderSetting folderSettingWithObjectID:folderSettingObjectID inContext:MAIN_CONTEXT];
                                     [mainFolderSetting setModSequenceValue:@(modSeqValue)];
                                 }];
                             }];
                         }
                         
                         if (![self canQResync])
                         {
                             [self checkOldMessagesUpToUID:maxIndex inFolderWithObjectID:folderSetting userInitiated:userInitiated];
                         }


                         //this performs any remaining fetches that were missed during the initial message download
                         //only necessary on Mac - on iOS the messages will be fetched only when the user scrolls down


                         //if the initial download has not been completed, fetch the remaining messages...
                         if(!folderSetting.downloadedFromUID || folderSetting.downloadedFromUID.integerValue>0)
                         {
                             if(folderSetting.downloadedFromUID)
                                 maxIndex = folderSetting.downloadedFromUID.integerValue;

                             [self checkOldMessagesUpToUID:maxIndex inFolderWithObjectID:folderSetting userInitiated:userInitiated];
                         }
                     }
                     else
                     {
                         [self checkOldMessagesUpToUID:MAX(maxUID, uidNext-1) inFolderWithObjectID:folderSetting userInitiated:userInitiated];
                     }

                     [self mergeLocalChangesInFolder:folderSetting userInitiated:userInitiated];
             }
             else
             {
                 //if uidValidity is incorrect, fetch all message headers (as well as structure) and update

                 //first set all uids to 0 - they are invalid.
                 //need a value of 0 (rather than nil) here so that the messages are taken into account by the checkOldMessages method
                 //messages fetched from the server will have their uid updated anyway, but the same is not true for messages still in the store which have somehow disappeared from the server

                 [self removeUIDsFromAllMessagesInFolder:folderSetting];

                 [folderSetting setUidValidity:@(info.uidValidity)];
                 [folderSetting setUidNext:@(info.uidNext)];
                 [folderSetting setModSequenceValue:@(info.modSequenceValue)];
                 [folderSetting setDownloadedFromUID:nil];

                 [CoreDataHelper save];

                 NSInteger numberOfMessages = (NSInteger)info.messageCount;

                 NSIndexSet* completeIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, numberOfMessages)];

                 [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

                     NSArray* batches = [IMAPAccount splitIndexSet:completeIndexSet intoMCOIndexSetBatchesOfSize:1000];

                     //only fetching UIDs and messageIDs/headers first
                     //later, the structure will be fetched for those messages not yet in the store

                     MCOIMAPMessagesRequestKind requestKind = MCOIMAPMessagesRequestKindHeaders;

                     //only the first block of messages is relevant for user feedback: "check completed"
                     __block BOOL isFirstBlock = YES;

                     BOOL alreadyProcessedFirstBlock = NO;

                     __block BOOL allFetchesSuccessful = YES;

                         //fetch all batches one after the other
                         for(MCOIndexSet* batch in batches)
                         {
                             if(alreadyProcessedFirstBlock)
                                 isFirstBlock = NO;

                             alreadyProcessedFirstBlock = YES;

                             FetchMessagesOperation* operation = [FetchMessagesOperation fetchMessagesByNumberOperationWithRequestKind:requestKind indexSet:batch folderPath:folderPath session:infoSession withCallback:^(NSError* error, NSArray* messages, MCOIndexSet* vanishedMessages)
                              {
                                  [ThreadHelper runSyncFreshLocalChildContext:^(NSManagedObjectContext *localSubContext) {

                                      if(error)
                                      {
                                          NSLog(@"Error fetching message batch! %@", error);
                                      }

                                      NSError* error = nil;
                                      IMAPFolderSetting* localFolderSetting = (IMAPFolderSetting*)[localSubContext existingObjectWithID:folderSettingObjectID error:&error];
                                      if(error)
                                      {
                                          NSLog(@"Error creating local folder setting!!! %@", error.localizedDescription);

                                          [AccountCheckManager didCheckFolder:localFolderSetting error:error foundNewMessages:NO];
                                          
//                                          TO DO: this doesn't work!!
//                                          callbacks will return in undetermined order, so allFetchesSuccessful doesn't really mean anything at this stage
//                                          if the last batch returns first and is successful, the app will think all batches were downloaded without error(!!)
                                          
                                          allFetchesSuccessful = NO;

                                          return;
                                      }


                                      NSMutableIndexSet* UIDsOfNewMessages = [NSMutableIndexSet new];

                                      NSMutableIndexSet* UIDsOfExistingMessages = [NSMutableIndexSet new];

                                      [self processHeaders:messages inFolder:localFolderSetting inContext:localSubContext UIDsOfMessagesWhoseStructureNeedsToBeFetched:UIDsOfNewMessages UIDsOfMessagesWhoseFlagsNeedToBeSynced:UIDsOfExistingMessages];


                                      if(UIDsOfNewMessages.count>0)
                                      {
                                          if([self fetchNewMessagesWithUIDs:UIDsOfNewMessages inFolder:localFolderSetting folderPath:localFolderSetting.path session:infoSession disconnectOperation:disconnectOperation userInitiated:userInitiated])
                                          {
                                              if(allFetchesSuccessful)
                                              {
                                                  NSInteger newLowestIndex = UIDsOfNewMessages.firstIndex;
                                                  if([batches indexOfObject:batch]==batches.count-1)
                                                      newLowestIndex = 0;
                                                  if(!localFolderSetting.downloadedFromUID || localFolderSetting.downloadedFromUID.integerValue>newLowestIndex)
                                                      [localFolderSetting setDownloadedFromUID:@(newLowestIndex)];
                                              }
                                          }
                                          else
                                          {
                                              allFetchesSuccessful = NO;
                                          }
                                      }

                                      //the callback should be called only once, for the topmost batch of messages (which gets checked first...)
                                      if(isFirstBlock)
                                      {
                                          [AccountCheckManager didCheckFolder:localFolderSetting error:nil foundNewMessages:NO];
                                      }

                                      [self fetchFlagsOfMessagesWithUIDs:UIDsOfExistingMessages inFolder:localFolderSetting usingSession:infoSession];
                                  }];
                              }];

                             if(userInitiated)
                                 [operation setHighPriority];
                             else
                                 [operation setMediumPriority];

                             [operation addToMailCoreQueueWithDisconnectOperation:disconnectOperation];
                         }

                         [self mergeLocalChangesInFolder:folderSetting userInitiated:userInitiated];
                     }];
                 }
            }];
         }];

        if(userInitiated)
            [infoOperation setHighPriority];
        else
            [infoOperation setMediumPriority];

        [infoOperation addToMailCoreQueueWithDisconnectOperation:disconnectOperation];
    }
    else
    {
        //this never happens
        [AccountCheckManager didCheckFolder:folderSetting error:[NSError errorWithDomain:@"MynigmaFolderCheck" code:6 userInfo:nil] foundNewMessages:NO];
    }

    }];
}








#pragma mark - SESSION HELPERS

+ (void)registerSessionHelper:(IMAPSessionHelper*)helper
{
    @synchronized(@"Session helpers")
    {
        if(!sessionHelpers)
            sessionHelpers = [NSMutableSet new];
        if(![sessionHelpers containsObject:helper])
            [sessionHelpers addObject:helper];
        else
            NSLog(@"Trying to re-register session helper %@", helper);
    }
}

+ (void)unregisterSessionHelper:(IMAPSessionHelper*)helper
{
    @synchronized(@"Session helpers")
    {
        if([sessionHelpers containsObject:helper])
        {
            [sessionHelpers removeObject:helper];
        }
        else
            NSLog(@"Trying to unregister session helper that has not been registered in the first place!! %@", helper);
    }
}


#pragma mark - iOS

//+ (void)forwardLoadWithCallback:(void(^)(BOOL success, NSInteger totalNum, NSInteger numDone))callback
//{
//    [ThreadHelper ensureMainThread];
//
//    NSSet* selectedFolderSettings = [OutlineObject selectedFolderSettingsForSyncing];
//
//    __block NSInteger totalCount = selectedFolderSettings.count;
//
//    __block NSInteger successCount = 0;
//
//    __block NSInteger doneCount = 0;
//
//    for(IMAPFolderSetting* folderSetting in selectedFolderSettings)
//    {
//        IMAPAccount* account = [MODEL accountForSettingID:folderSetting.accountSetting.objectID];
//
//        if([folderSetting isBusy])
//        {
//
//        }
//        else
//        {
//            [folderSetting setBusy];
//
//            [account checkFolder_iOS:folderSetting withCallback:^(BOOL success)
//             {
//
//                 [folderSetting setDone];
//
//                 doneCount++;
//
//                 if(success)
//                     successCount++;
//
//                 BOOL allSuccessful = (doneCount == successCount);
//
//                 callback(allSuccessful, totalCount, doneCount);
//             }];
//        }
//    }
//}



//+ (void)backwardLoadWithCallback:(void(^)(BOOL success, NSInteger totalNum, NSInteger numDone))callback
//{
//    [ThreadHelper ensureMainThread];
//
//    NSMutableSet* objectIDsOfFoldersToBeSynced = [NSMutableSet new];
//
//    for(IMAPFolderSetting* folderSetting in [OutlineObject selectedFolderSettingsForSyncing])
//    {
//        [objectIDsOfFoldersToBeSynced addObject:folderSetting.objectID];
//    }
//
//    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {
//
//        NSInteger totalCount = objectIDsOfFoldersToBeSynced.count;
//
//        __block BOOL allSuccessful = YES;
//
//        __block NSInteger doneCount = 0;
//
//        __block NSInteger successCount = 0;
//
//        NSOperationQueue* oldQueue = [NSOperationQueue new];
//
//        NSMutableSet* newSessions = [NSMutableSet new];
//
//        for(NSManagedObjectID* folderSettingObjectID in objectIDsOfFoldersToBeSynced)
//        {
//            IMAPFolderSetting* folderSetting = [IMAPFolderSetting folderSettingWithObjectID:folderSettingObjectID inContext:localContext];
//
//            if([folderSetting isBackwardLoading])
//            {
//                continue;
//            }
//
//            [folderSetting setIsBackwardLoading:YES];
//
//            IMAPAccount* account = [MODEL accountForSettingID:folderSetting.accountSetting.objectID];
//
//            [account downloadNextBatchOfMessagesInFolder:folderSetting withCallback:^(BOOL success, BOOL moreToBeLoaded)
//             {
//                 [MAIN_CONTEXT performBlock:^{
//
//                     IMAPFolderSetting* folderSettingOnMain = [IMAPFolderSetting folderSettingWithObjectID:folderSettingObjectID inContext:MAIN_CONTEXT];
//
//                     [folderSettingOnMain setIsBackwardLoading:NO];
//
//                     doneCount++;
//
//                     if(success)
//                         successCount++;
//                     else
//                         allSuccessful = NO;
//
//                     callback(allSuccessful, totalCount, doneCount);
//
//                 }];
//             }];
//        }
//    }];
//}

//- (void)downloadNextBatchOfMessagesInFolder:(IMAPFolderSetting*)folderSetting withCallback:(void(^)(BOOL success, BOOL moreToBeLoaded))callback; //callback parameters: success (no error), more messages to load
//{
//    [ThreadHelper ensureMainThread];
//
//    const NSInteger batchSize = 25;
//
//    NSManagedObjectID* folderSettingObjectID = folderSetting.objectID;
//
//
//    NSString* folderPath = folderSetting.path;
//
//    MCOIMAPMessagesRequestKind requestKind = MCOIMAPMessagesRequestKindHeaders;
//
//    NSInteger maxIndex = folderSetting.downloadedFromNumber.integerValue;
//
//    MCOIMAP
//
//
//    if(!folderSetting.downloadedFromNumber)
//    {
//        NSInteger newDownladedFromNumber = [self numberOfMessagesInFolder:folderSetting usingSession:session] + 1;
//
//        if(newDownladedFromNumber>0)
//        {
//            [folderSetting setDownloadedFromNumber:@(newDownladedFromNumber)];
//            maxIndex = newDownladedFromNumber;
//        }
//        else
//        {
//            callback(NO, YES);
//            return;
//        }
//    }
//
//    if(maxIndex<=1)
//    {
//        callback(YES, NO);
//        return;
//    }
//
//    NSInteger minIndex = maxIndex - batchSize;
//
//    if(minIndex<=1)
//        minIndex = 1;
//
//    MCOIndexSet* indexSet = [MCOIndexSet indexSetWithRange:MCORangeMake(minIndex, maxIndex - minIndex)];
//
//    FetchMessagesOperation* operation = [FetchMessagesOperation fetchMessagesByNumberOperationWithRequestKind:requestKind indexSet:indexSet folderPath:folderPath session:session withCallback:^(NSError* error, NSArray* messages, MCOIndexSet* vanishedMessages)
//     {
//         [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {
//
//             if(error)
//             {
//                 NSLog(@"Error fetching message batch! %@", error);
//             }
//             else
//             {
//
//                 NSError* error = nil;
//                 IMAPFolderSetting* localFolderSetting = (IMAPFolderSetting*)[localContext existingObjectWithID:folderSettingObjectID error:&error];
//                 if(error)
//                 {
//                     NSLog(@"Error creating local folder setting!!! %@", error.localizedDescription);
//                     return;
//                 }
//
//                 NSMutableIndexSet* UIDsOfNewMessages = [NSMutableIndexSet new];
//
//                 NSMutableIndexSet* UIDsOfExistingMessages = [NSMutableIndexSet new];
//
//                 [self processHeaders:messages inFolder:localFolderSetting inContext:localContext UIDsOfMessagesWhoseStructureNeedsToBeFetched:UIDsOfNewMessages UIDsOfMessagesWhoseFlagsNeedToBeSynced:UIDsOfExistingMessages];
//
//                 if([self fetchNewMessagesWithUIDs:UIDsOfNewMessages inFolderWithObjectID:localFolderSetting.objectID folderPath:localFolderSetting.path])
//                 {
//                     NSInteger newLowestIndex = minIndex;
//                     if(!localFolderSetting.downloadedFromNumber || localFolderSetting.downloadedFromNumber.integerValue>newLowestIndex)
//                         [localFolderSetting setDownloadedFromNumber:@(newLowestIndex)];
//                 }
//             }
//         }];
//     }];
//
//    NSOperationQueue* queue = [AccountCheckManager mailcoreOperationQueue];
//
//    [discon]
//
//    [queue addOperation:operation];
//
//    //    //first get the folder info (containing uidValidity etc.)
//    //    IMAPSessionHelper* infoSession = [[IMAPSessionHelper alloc] initWithSession:imapSession];
//    //    [infoSession folderInfoWithFolder:folderPath withCallback:
//    //     ^(NSError *error, MCOIMAPFolderInfo *info)
//    //     {
//    //         if(error)
//    //         {
//    //             NSLog(@"Error fetching folder info for folder %@: %@", folderPath, error);
//    //             [infoSession disconnectWhenDone];
//    //             callback(NO, YES);
//    //             return;
//    //         }
//    //
//    //         NSInteger totalNumber = info.messageCount;
//    //         NSInteger numberWeActuallyHave = folderSetting.containsMessages.count;
//    //
//    //         NSInteger maxIndex = totalNumber - numberWeActuallyHave;
//    //         NSInteger minIndex = maxIndex - batchSize;
//    //
//    //         if(minIndex<1)
//    //             minIndex = 1;
//    //
//    //         if(maxIndex<=0 || minIndex >= maxIndex)
//    //         {
//    //             //looks like we're done
//    //             callback(YES, NO);
//    //             return;
//    //         }
//    //
//    //
//    //         NSIndexSet* numberSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(minIndex, maxIndex)];
//    //
//    //         [self fetchNewMessagesWithNumbers:numberSet inFolderWithObjectID:folderSetting.objectID folderPath:folderPath usingSession:infoSession];
//    //
//    //         [infoSession disconnectWhenDone];
//    //     }];
//}
//

/**Checks the folder (RUN ON MAIN THREAD)*/
//- (void)checkFolder_iOS:(IMAPFolderSetting*)folderSetting withCallback:(void(^)(BOOL success))callback
//{
//    [ThreadHelper ensureMainThread];
//
//    NSString* folderPath = folderSetting.path;
//
//    if(!imapSession || !folderSetting || !folderSetting.path)
//    {
//        NSLog(@"Error before checking folder! Values:\nimapSession = %@\nfolderSetting = %@\nfolderSetting.path = %@\nfolderSetting.uidNext = %d",imapSession,folderSetting,folderSetting.path,folderSetting.uidNext.unsignedIntValue);
//        if(callback)
//            callback(NO);
//        return;
//    }
//
//    //first get the folder info (containing uidValidity etc.)
//    IMAPSessionHelper* infoSession = [[IMAPSessionHelper alloc] initWithSession:imapSession];
//    [infoSession folderInfoWithFolder:folderPath withCallback:
//     ^(NSError *error, MCOIMAPFolderInfo *info)
//     {
//         [MAIN_CONTEXT performBlock:^{
//
//             if(error)
//             {
//                 NSLog(@"Error fetching folder info for folder %@: %@", folderPath, error.localizedDescription);
//                 [infoSession disconnectWhenDone];
//                 [self doneCheckingFolder:folderSetting.objectID];
//                 [folderSetting setDone];
//                 if(callback)
//                     callback(NO);
//                 return;
//             }
//             //first check uidValidity. if incorrect, fetch the messageIDs and update the uids in the store
//
//             if(info.uidValidity==folderSetting.uidValidity.integerValue)
//             {
//                 NSInteger uidNext = folderSetting.uidNext.integerValue;
//                 if(uidNext==-1)
//                     uidNext = 1;
//
//                 //the ones from uidNext onwards first - this allows new messages to be processed immediately
//                 //re-use the infoSession to make this as fast as possible
//                 NSInteger maxUID = folderSetting.highestUID.integerValue;
//
//                 NSInteger minIndex = MIN(maxUID, uidNext);
//
//                 MCOIndexSet* indexSet = [MCOIndexSet indexSetWithRange:MCORangeMake(minIndex, UINT32_MAX)];
//
//                 MCOIMAPMessagesRequestKind requestKind = MCOIMAPMessagesRequestKindHeaders | MCOIMAPMessagesRequestKindStructure | MCOIMAPMessagesRequestKindFlags | MCOIMAPMessagesRequestKindFullHeaders | MCOIMAPMessagesRequestKindExtraHeaders | MCOIMAPMessagesRequestKindUid;
//
//                 if([accountSetting isKindOfClass:[GmailAccountSetting class]])
//                     requestKind |= MCOIMAPMessagesRequestKindGmailLabels;
//
//                 [infoSession fetchMessagesByUIDWithFolder:folderPath requestKind:requestKind uids:indexSet withCallback:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages)
//                  {
//                      [self processFetchedMessages:messages inFolderWithObjectID:folderSetting.objectID usingSession:infoSession];
//                      [infoSession disconnectWhenDone];
//                      if(!error)
//                          [folderSetting setUidNext:@(info.uidNext)];
//
//                      [self doneCheckingFolder:folderSetting.objectID];
//                      [folderSetting setDone];
//
//                      if(callback)
//                          callback(error!=nil);
//                  }];
//
//                 //simultaneously check the ones up to and excluding uidNext - and remove the ones that have been deleted locally, fetch the ones that aren't in the store
//
//                 if([self canModSeq])
//                 {
//                     if(folderSetting.modSequenceValue && folderSetting.modSequenceValue.integerValue!=info.modSequenceValue)
//                         [self checkOldMessagesWithMODSEQUpToUID:MAX(maxUID, uidNext-1) inFolder:folderSetting.objectID usingSession:nil withCallback:^{
//
//                             [folderSetting setModSequenceValue:@(info.modSequenceValue)];
//                         }];
//
//                     //#if TARGET_OS_IPHONE
//                     if([Reachability isOnWIFI])
//                         //#endif
//                     {
//
//                         NSInteger triggerTimeInterval = [self canQResync]?60*60*24:60*30;
//
//                         if(!lastCompleteUIDFetch)
//                             lastCompleteUIDFetch = [NSDate date];
//
//                         if([lastCompleteUIDFetch timeIntervalSinceNow]<-triggerTimeInterval)
//                         {
//                             [self checkOldMessagesUpToUID:MAX(maxUID, uidNext-1) inFolderWithObjectID:folderSetting.objectID usingSession:nil withCallback:^{}];
//                         }
//                     }
//                     [self mergeLocalChangesInFolder:folderSetting usingSession:nil];
//
//
//                     //                 //this performs any remaining fetches that were missed during the initial message download
//                     //                 if(!folderSetting.downloadedFromUID || folderSetting.downloadedFromUID.integerValue>0)
//                     //                 {
//                     //                     NSInteger maxIndex = folderSetting.downloadedFromUID?folderSetting.downloadedFromUID.integerValue:MAX(maxUID, uidNext-1);
//                     //                     [self checkOldMessagesUpToUID:maxIndex inFolderWithObjectID:folderSetting.objectID usingSession:nil withCallback:^{
//                     //
//                     //                     }];
//                     //                 }
//
//                 }
//                 else
//                 {
//                     if([Reachability isOnWIFI])
//                     {
//
//                         NSInteger triggerTimeInterval = [self canQResync]?60*60:60*30;
//
//                         if(!lastCompleteUIDFetch)
//                             lastCompleteUIDFetch = [NSDate date];
//
//                         if([lastCompleteUIDFetch timeIntervalSinceNow]<-triggerTimeInterval)
//                             [self checkOldMessagesUpToUID:MAX(maxUID, uidNext-1) inFolderWithObjectID:folderSetting.objectID usingSession:nil withCallback:^{}];
//
//                         [self mergeLocalChangesInFolder:folderSetting usingSession:nil];
//                     }
//                 }
//
//             }
//             else
//             {
//                 //if uidValidity is incorrect, fetch the last n message headers (as well as structure), where n is the number of messages currently in the store
//
//                 //first set all uids to 0 - they are invalid.
//                 //need a value of 0 (rather than nil) here so that the messages are taken into account by the checkOldMessages method
//                 //messages fetched from the server will have their uid updated anyway, but the same is not true for messages still in the store which have somehow disappeared from the server
//
//                 [self removeUIDsFromAllMessagesInFolder:folderSetting];
//
//                 [folderSetting setUidValidity:@(info.uidValidity)];
//                 [folderSetting setUidNext:@(info.uidNext)];
//                 [folderSetting setModSequenceValue:@(info.modSequenceValue)];
//                 [folderSetting setDownloadedFromUID:nil];
//
//                 [MODEL saveContext];
//
//                 NSInteger numberOfMessages = (NSInteger)info.messageCount;
//
//                 __block BOOL allHeaderFetchesSuccessful = YES;
//
//                 NSIndexSet* completeIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, numberOfMessages)];
//
//                 NSManagedObjectID* folderSettingObjectID = folderSetting.objectID;
//
//                 NSString* folderPath = folderSetting.path;
//
//                 NSOperationQueue* newQueue = [self newMessagesQueueForFolderWithObjectID:folderSettingObjectID];
//
//                 if(newQueue.operationCount>0)
//                 {
//                     NSLog(@"Aborting message check: already running...");
//                     return;
//                 }
//
//                 [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext* localContext) {
//
//                     NSArray* batches = [IMAPAccount splitIndexSet:completeIndexSet intoMCOIndexSetBatchesOfSize:25];
//
//                     //only fetching UIDs and messageIDs/headers first
//                     //later, the structure will be fetched for those messages not yet in the store
//
//                     MCOIMAPMessagesRequestKind requestKind = MCOIMAPMessagesRequestKindHeaders;
//
//                     __block BOOL allFetchesSuccessful = YES;
//
//                     [newQueue setMaxConcurrentOperationCount:1];
//
//                     //quick hack on iOS: fetch only the last batch
//
//                     if(batches.count>0)
//                     {
//                         MCOIndexSet* batch = batches[0];
//                         {
//                             FetchMessagesOperation* operation = [FetchMessagesOperation fetchMessagesByNumberOperationWithRequestKind:requestKind indexSet:batch folderPath:folderPath session:infoSession];
//
//                             __weak FetchMessagesOperation* weakOperation = operation;
//
//                             [operation setCallback:^(NSError* error, NSArray* messages, MCOIndexSet* vanishedMessages)
//                              {
//                                  [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {
//
//                                      if(error)
//                                      {
//                                          NSLog(@"Error fetching message batch! %@", error);
//                                          allHeaderFetchesSuccessful = NO;
//                                      }
//
//                                      NSError* error = nil;
//                                      IMAPFolderSetting* localFolderSetting = (IMAPFolderSetting*)[localContext existingObjectWithID:folderSettingObjectID error:&error];
//                                      if(error)
//                                      {
//                                          NSLog(@"Error creating local folder setting!!! %@", error.localizedDescription);
//                                          if(callback)
//                                              callback(NO);
//                                          return;
//                                      }
//
//
//                                      NSMutableIndexSet* UIDsOfNewMessages = [NSMutableIndexSet new];
//
//                                      NSMutableIndexSet* UIDsOfExistingMessages = [NSMutableIndexSet new];
//
//                                      [self processHeaders:messages inFolder:localFolderSetting inContext:localContext UIDsOfMessagesWhoseStructureNeedsToBeFetched:UIDsOfNewMessages UIDsOfMessagesWhoseFlagsNeedToBeSynced:UIDsOfExistingMessages];
//
//                                      if([self fetchNewMessagesWithUIDs:UIDsOfNewMessages inFolderWithObjectID:localFolderSetting.objectID folderPath:localFolderSetting.path usingSession:infoSession])
//                                      {
//                                          if(allFetchesSuccessful)
//                                          {
//                                              MCORange batchRange = batch.allRanges[0];
//                                              NSInteger newLowestNumber = (NSInteger)batchRange.location;
//                                              if(!localFolderSetting.downloadedFromNumber || localFolderSetting.downloadedFromNumber.integerValue>newLowestNumber)
//                                                  [localFolderSetting setDownloadedFromNumber:@(newLowestNumber)];
//
//                                              NSInteger newLowestIndex = UIDsOfNewMessages.firstIndex;
//                                              if([batches indexOfObject:batch]==batches.count-1)
//                                                  newLowestIndex = 0;
//                                              if(!localFolderSetting.downloadedFromUID || localFolderSetting.downloadedFromUID.integerValue>newLowestIndex)
//                                                  [localFolderSetting setDownloadedFromUID:@(newLowestIndex)];
//                                          }
//                                          if(callback)
//                                              callback(YES);
//                                      }
//                                      else
//                                      {
//                                          allFetchesSuccessful = NO;
//                                          if(callback)
//                                              callback(NO);
//                                      }
//
//                                      [self fetchFlagsOfMessagesWithUIDs:UIDsOfExistingMessages inFolder:localFolderSetting usingSession:infoSession];
//
//                                      [weakOperation nowDone];
//
//                                  }];
//                              }];
//
//                             [newQueue addOperation:operation];
//                         }
//                     }
//                     [newQueue waitUntilAllOperationsAreFinished];
//
//                     if(allHeaderFetchesSuccessful)
//                     {
//                         [self mergeLocalChangesInFolder:folderSetting usingSession:infoSession];
//                     }
//
//                     [infoSession disconnectWhenDone];
//
//                     NSError* error = nil;
//                     [localContext save:&error];
//                     if(error)
//                         NSLog(@"Error saving local context!! %@",error);
//
//                 }];
//             }
//
//         }];
//     }];
//}
//




//- (void)checkUIDsOfMessagesFromSequenceNumber:(NSInteger)fromNumber toSequenceNumber:(NSInteger)toNumber inFolder:(IMAPFolderSetting*)folderSetting withCallback:(void(^)(BOOL, NSArray*))callback //callback parameters: success (no error), array of messages (containing only uid and messageID) found
//{
//    [ThreadHelper ensureMainThread];
//
//    MCOIMAPFetchMessagesOperation* fetchOperation = [imapSession fetchMessagesByNumberOperationWithFolder:folderSetting.path requestKind:MCOIMAPMessagesRequestKindUid numbers:[MCOIndexSet indexSetWithRange:MCORangeMake(fromNumber, toNumber-fromNumber)]];
//    [fetchOperation start:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages) {
//
//        [MAIN_CONTEXT performBlock:^{
//
//            if(error)
//                callback(NO, nil);
//            else
//            {
//                callback(YES, messages);
//            }
//
//        }];
//    }];
//}



//
//- (void)fetchHeadersOfMessagesWithUIDs:(MCOIndexSet*)UIDs inFolder:(IMAPFolderSetting*)folderSetting withCallback:(void(^)(BOOL))callback
//{
//    MCOIMAPFetchMessagesOperation* fetchMessagesOperation = [imapSession fetchMessagesByUIDOperationWithFolder:folderSetting.path requestKind:MCOIMAPMessagesRequestKindFlags|MCOIMAPMessagesRequestKindFullHeaders|MCOIMAPMessagesRequestKindGmailLabels|MCOIMAPMessagesRequestKindHeaderSubject|MCOIMAPMessagesRequestKindInternalDate|MCOIMAPMessagesRequestKindSize|MCOIMAPMessagesRequestKindStructure uids:UIDs];
//    [fetchMessagesOperation start:[^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages) {
//
//        NSManagedObjectID* folderSettingID = folderSetting.objectID;
//        NSManagedObjectContext* localContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
//        [localContext setParentContext:MAIN_CONTEXT];
//        [localContext performBlock:
//         [^{
//            NSError* error = nil;
//            IMAPFolderSetting* localFolderSetting = (IMAPFolderSetting*)[localContext existingObjectWithID:folderSettingID error:&error];
//            if(error)
//            {
//                NSLog(@"Error creating local folder setting!!! %@", error.localizedDescription);
//                callback(NO);
//                return;
//            }
//
//            for(MCOIMAPMessage* message in messages)
//            {
//                [self processServerMessage:message inFolder:localFolderSetting withContext:localContext newMessagesArray:nil];
//            }
//
//            error = nil;
//            [localContext save:&error];
//            if(error)
//            {
//                NSLog(@"Error saving local context after message header fetch!!! %@", error.localizedDescription);
//                callback(NO);
//            }
//            else
//                callback(YES);
//            //[APPDELEGATE refreshAllMessages];
//
//        } copy]];
//
//    } copy]];
//}

//- (NSInteger)numberOfMessagesInFolder:(IMAPFolderSetting*)folderSetting usingSession:(IMAPSessionHelper*)session
//{
//    NSOperationQueue* newQueue = [NSOperationQueue new];
//
//    FolderInfoOperation *folderInfoOperation = [FolderInfoOperation folderInfoWithFolderPath:folderSetting.path usingSession:session];
//
//    __weak FolderInfoOperation* weakOperation = folderInfoOperation;
//
//    __block NSInteger returnValue = -1;
//
//    [folderInfoOperation setCallback:^(NSError* error, MCOIMAPFolderInfo* folderInfo)
//     {
//         if(error || !folderInfo)
//             returnValue = -1;
//         else
//         {
//             returnValue = folderInfo.messageCount;
//         }
//         
//         [weakOperation nowDone];
//     }];
//    
//    [newQueue addOperation:folderInfoOperation];
//    
//    [newQueue waitUntilAllOperationsAreFinished];
//    
//    return returnValue;
//}

//- (void)downloadAnyNewMessageHeadersInFolder:(IMAPFolderSetting*)folder withCallback:(void(^)(BOOL success))callback
//{
//    FolderInfoObject* infoObject = [APPDELEGATE folderInfoForFolderSetting:folder];
//
//    if(infoObject.nextUID<=0)
//    {
//        [self downloadNextBatchOfMessagesInFolder:folder withCallback:[^(BOOL completed, BOOL moreToLoad) {
//            callback(completed);
//        } copy]];
//        return;
//    }
//
//
//    [self checkUIDsOfMessagesFromSequenceNumber:folder.containsMessages.count toSequenceNumber:0 inFolder:folder withCallback:[^(BOOL success, NSArray *messages) {
//        if(!success)
//        {
//            callback(NO);
//            return;
//        }
//        MCOIndexSet* messagesToBeDownloaded = [MCOIndexSet new];
//        for(MCOIMAPMessage* message in messages)
//        {
//            if(![MODEL haveMessageWithMessageID:message.header.messageID])
//                [messagesToBeDownloaded addIndex:message.uid];
//        }
//
//        //TO DO: remove deleted messages from the local store...
//
//        if(messagesToBeDownloaded.count==0)
//            callback(YES);
//        else
//        {
//            [self fetchHeadersOfMessagesWithUIDs:messagesToBeDownloaded inFolder:folder withCallback:[^(BOOL success){
//                callback(success);
//            } copy]];
//        }
//    } copy]];
//}
//
//- (void)updateExistingMessagesInFolder:(IMAPFolderSetting*)folderSetting withCallback:(void(^)(BOOL success))callback
//{
//    
//}

//+ (void)backgroundFetch
//{
//    for(IMAPAccount* account in MODEL.accounts)
//    {
//        [account checkAccount];
//    }
//}

@end
