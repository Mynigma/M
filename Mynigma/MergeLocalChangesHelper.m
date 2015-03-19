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





#import "MergeLocalChangesHelper.h"
#import "IMAPAccount.h"
#import "IMAPFolderSetting+Category.h"
#import "ThreadHelper.h"
#import "EmailMessageInstance+Category.h"
#import "AppendMessagesOperation.h"
#import "CopyMessageOperation.h"
#import "StoreFlagsOperation.h"
#import "StoreLabelsOperation.h"
#import "DeleteMessagesOperation.h"
#import "GmailLabelSetting.h"
#import "MessageSyncHelper.h"
#import "EmailMessage+Category.h"
#import "FileAttachment+Category.h"
#import "AppDelegate.h"
#import "IMAPAccount.h"
#import "DownloadHelper.h"
#import "IMAPAccountSetting+Category.h"
#import "DisconnectOperation.h"
#import "AccountCheckManager.h"
#import "SendingManager.h"
#import "UserSettings+Category.h"
#import "DeviceMessage+Category.h"





static NSMutableSet* lockedMessageInstances;

@implementation MergeLocalChangesHelper

+ (NSMutableSet*)lockedInstances
{
    if(!lockedMessageInstances)
        lockedMessageInstances = [NSMutableSet new];

    return lockedMessageInstances;
}

+ (BOOL)lockMessageInstance:(NSManagedObjectID*)messageInstanceObjectID
{
    if(!messageInstanceObjectID)
    {
        NSLog(@"Cannot lock nil objectID!!");
        return NO;
    }

    @synchronized(@"MERGE_LOCAL_CHANGES_MESSAGE_INSTANCE_LOCK")
    {
        if(![self.lockedInstances containsObject:messageInstanceObjectID])
        {
            [self.lockedInstances addObject:messageInstanceObjectID];
            return YES;
        }
    }

    return NO;
}

+ (void)releaseLockOnMessageInstance:(NSManagedObjectID*)messageInstanceObjectID
{
    if(!messageInstanceObjectID)
    {
        NSLog(@"Cannot release lock on nil objectID!!");
        return;
    }

    @synchronized(@"MERGE_LOCAL_CHANGES_MESSAGE_INSTANCE_LOCK")
    {
        [self.lockedInstances removeObject:messageInstanceObjectID];
    }
}



+ (void)simplifyMessageInstanceIfNecessary:(EmailMessageInstance*)messageInstance
{
    NSManagedObjectID* messageInstanceObjectID = messageInstance.objectID;

    if(![MergeLocalChangesHelper lockMessageInstance:messageInstanceObjectID])
        return;
    
    if(![messageInstance isSourceOfMove])
    {
        [MergeLocalChangesHelper releaseLockOnMessageInstance:messageInstanceObjectID];
        return;
    }

    EmailMessageInstance* destinationInstance = messageInstance.movedToInstance;

    //if the instance has been added and then moved, simplify it to an add operation to the new folder
    if(messageInstance.addedToFolder && destinationInstance)
    {

        //this shouldn't really be necessary, but never mind...
        if([MergeLocalChangesHelper lockMessageInstance:destinationInstance.objectID])
        {
            //mark the destinationInstance as added to the folder
            destinationInstance.addedToFolder = destinationInstance.folderSetting;
            destinationInstance.movedFromInstance = nil;

            [messageInstance.managedObjectContext deleteObject:messageInstance];

            NSError* error = nil;
            [messageInstance.managedObjectContext save:&error];
            if(error)
                NSLog(@"Error saving message instance context!! %@", error);
            
            messageInstance = destinationInstance;

            [MergeLocalChangesHelper releaseLockOnMessageInstance:messageInstanceObjectID];

            [MergeLocalChangesHelper releaseLockOnMessageInstance:destinationInstance.objectID];

            [MergeLocalChangesHelper simplifyMessageInstanceIfNecessary:destinationInstance];
            
            //no need to proceed
            return;
        }
    }

    //if it has been moved and moved again, cut out the middle man and move straight from A to C
    if(destinationInstance && destinationInstance.movedToInstance)
    {
        //of course this may not actually be the "final" destination
        //recursion will ensure that everything is dandy
        EmailMessageInstance* finalDestinationInstance = destinationInstance.movedToInstance;

        //get the objectID before the instance is deleted (we still need to release the lock)
        NSManagedObjectID* destinationInstanceObjectID = destinationInstance.objectID;

        //this shouldn't really be necessary, but never mind...
        if([MergeLocalChangesHelper lockMessageInstance:destinationInstanceObjectID])
        {
            //this shouldn't really be necessary, but never mind...
            if([MergeLocalChangesHelper lockMessageInstance:finalDestinationInstance.objectID])
            {
                messageInstance.movedToInstance = finalDestinationInstance;

                [destinationInstance.managedObjectContext deleteObject:destinationInstance];

                NSError* error = nil;
                [destinationInstance.managedObjectContext save:&error];
                if(error)
                    NSLog(@"Error saving message instance context!! %@", error);

                [MergeLocalChangesHelper releaseLockOnMessageInstance:messageInstanceObjectID];

                [MergeLocalChangesHelper releaseLockOnMessageInstance:destinationInstanceObjectID];

                [MergeLocalChangesHelper releaseLockOnMessageInstance:finalDestinationInstance.objectID];

                [MergeLocalChangesHelper simplifyMessageInstanceIfNecessary:messageInstance];
                
                return;
            }

            [MergeLocalChangesHelper releaseLockOnMessageInstance:destinationInstanceObjectID];
        }
    }

    //if the message has been added and then deleted, we may as well not bother, given that the append operation isn't already in progress (that's what the locks are for)
    if(messageInstance.addedToFolder && messageInstance.deletedFromFolder)
    {
        [messageInstance.managedObjectContext deleteObject:messageInstance];

        NSError* error = nil;
        [messageInstance.managedObjectContext save:&error];
        if(error)
            NSLog(@"Error saving message instance context!! %@", error);
    }

    [MergeLocalChangesHelper releaseLockOnMessageInstance:messageInstanceObjectID];
}



+ (void)mergeAddedMessagesForAccount:(IMAPAccount*)account inFolder:(IMAPFolderSetting*)localFolderSetting inContext:(NSManagedObjectContext*)localContext usingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation deviceMessages:(BOOL)pickDeviceMessages
{
    NSSet* locallyAddedMessages = [localFolderSetting.addedMessages copy];

    for(EmailMessageInstance* messageInstance in locallyAddedMessages)
    {
        [MergeLocalChangesHelper simplifyMessageInstanceIfNecessary:messageInstance];
        
        //if the instance was deleted during simplification, don't access it(!)
        if(!messageInstance.managedObjectContext || messageInstance.isDeleted)
            continue;
            

        if([messageInstance isOnServer])
        {
            [localFolderSetting removeAddedMessagesObject:messageInstance];
            continue;
        }

        BOOL devicePickCondition = ([messageInstance.message isDeviceMessage] && pickDeviceMessages) || (![messageInstance.message isDeviceMessage] && !pickDeviceMessages);

        if(!devicePickCondition)
            continue;

        MCOMessageFlag flagsToSet = (MCOMessageFlag)(messageInstance.flags.integerValue)%(1 << 9);

        NSData* parsedData = [SendingManager MCOMessageForEmailMessage:messageInstance.message inContext:localContext];

        if(!parsedData)
        {
            NSLog(@"Trying to upload invalid data!!!! %@", messageInstance);
            [messageInstance setAddedToFolder:nil];
            continue;
        }

        if(messageInstance.objectID.isTemporaryID)
        {
            [localContext obtainPermanentIDsForObjects:@[messageInstance] error:nil];
        }

        NSManagedObjectID* messageInstanceObjectID = messageInstance.objectID;

        if(![MergeLocalChangesHelper lockMessageInstance:messageInstanceObjectID])
        {
            continue;
        }
        
        if(pickDeviceMessages && VERBOSE_TRUST_ESTABLISHMENT)
        {
            DeviceMessage* deviceMessage = (DeviceMessage*)messageInstance.message;
            NSLog(@"Pushing device message to server: %@\nPayload: %@", deviceMessage.messageCommand, deviceMessage.payload);
        }

        AppendMessagesOperation* appendOperation = [AppendMessagesOperation appendMessagesWithData:parsedData toFolderWithPath:localFolderSetting.path withFlags:flagsToSet session:session withCallback:^(NSError* error, uint32_t UID){
             if(!error)
             {
                 if(pickDeviceMessages && VERBOSE_TRUST_ESTABLISHMENT)
                 {
                     DeviceMessage* deviceMessage = (DeviceMessage*)messageInstance.message;
                     NSLog(@"Successfully pushed device message to server: %@\nPayload: %@", deviceMessage.messageCommand, deviceMessage.payload);
                 }
                 
                 [ThreadHelper runSyncFreshLocalChildContext:^(NSManagedObjectContext *localContext)
                  {
                      //the message might have been deleted in the meantime, but this should be safe nonetheless

                      //-----------------------------------
                      //trying to fix drafts flood bug:
                      //if no UID is returned, but the operation is sucessful, remove the "addedToFolder" mark and simply set a nil UID
                      //it's the best we can do in this case
                      //don't want to upload a message an unlimited number of times(!!)
                      //-----------------------------------

//                      if(UID>0)
//                      {
                          EmailMessageInstance* messageInstance = [EmailMessageInstance messageInstanceWithObjectID:messageInstanceObjectID inContext:localContext];

                          [messageInstance setUid:UID>0?@(UID):nil];
                          [messageInstance setAddedToFolder:nil];
                          NSError* error = nil;
                          [localContext save:&error];
                          if(error)
                              NSLog(@"Error saving local context!! %@", error);
//                      }
//                      else
//                      {
                      if(UID==0)
                          NSLog(@"No valid UID returned by append message operation!!!");
//                      }
                  }];
             }

            [MergeLocalChangesHelper releaseLockOnMessageInstance:messageInstanceObjectID];
         }];

        if(pickDeviceMessages)
            [appendOperation setHighPriority];
        else
            [appendOperation setLowPriority];

        [appendOperation addToMailCoreQueueWithDisconnectOperation:disconnectOperation];
    }
}


+ (void)mergeMovedMessagesForAccount:(IMAPAccount*)account inFolder:(IMAPFolderSetting*)localFolderSetting inContext:(NSManagedObjectContext*)localContext usingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation deviceMessages:(BOOL)pickDeviceMessages
{
    NSSet* movedInstances = [localFolderSetting.movedAwayMessages copy];

    for(EmailMessageInstance* messageInstance in movedInstances)
    {
        [MergeLocalChangesHelper simplifyMessageInstanceIfNecessary:messageInstance];

        //if the instance was deleted during simplification, don't access it(!)
        if(!messageInstance.managedObjectContext || messageInstance.isDeleted)
            continue;

        BOOL devicePickCondition = ([messageInstance.message isDeviceMessage] && pickDeviceMessages) || (![messageInstance.message isDeviceMessage] && !pickDeviceMessages);

        if(!devicePickCondition)
            continue;
        
        //only move the message if the IMAP server would actually find it in the specified place
        //that's not the case for message instances that were moved more than once nor for those that have been added locally
        if([messageInstance isSourceOfMove] && ![messageInstance addedToFolder])
        {
            __block EmailMessageInstance* destinationInstance = messageInstance.moveDestination;

            //if the source folder is the same as the destination then don't actually bother the server - just pretend the message was moved
            if([messageInstance.folderSetting isEqual:destinationInstance.folderSetting])
            {
                [messageInstance moveOnIMAPDoneWithNewUID:messageInstance.uid withContext:localContext toInstance:destinationInstance];

                NSError* error = nil;
                [localContext save:&error];
                if(error)
                    NSLog(@"Error saving local context!! %@", error);

                continue;
            }

            NSString* destinationFolderPath = destinationInstance.folderSetting.path;

            //must be deletedFromFolder
            //                if(!destinationFolderPath)
            //                {
            //                    destinationFolderPath = destinationInstance.deletedFromFolder.path;
            //                }

            if(!destinationFolderPath)
            {
                NSLog(@"No destination folder path for message move");
                continue;
            }

            MCOIndexSet* singleIndex = [MCOIndexSet indexSetWithIndex:messageInstance.uid.integerValue];

            if(messageInstance.objectID.isTemporaryID)
            {
                [localContext obtainPermanentIDsForObjects:@[messageInstance] error:nil];
            }

            NSManagedObjectID* messageInstanceObjectID = messageInstance.objectID;

            if(![MergeLocalChangesHelper lockMessageInstance:messageInstanceObjectID])
            {
                continue;
            }
            
            CopyMessageOperation* copyOperation = [CopyMessageOperation copyWithFolderPath:localFolderSetting.path toDestinationPath:destinationFolderPath uids:singleIndex usingSession:session withCallback:^(NSError* error, NSDictionary* UIDs)
             {
                 if(!error)
                 {
                     [ThreadHelper runSyncFreshLocalChildContext:^(NSManagedObjectContext *localContext)
                      {
                          EmailMessageInstance* messageInstance = [EmailMessageInstance messageInstanceWithObjectID:messageInstanceObjectID inContext:localContext];

                          EmailMessageInstance* destinationInstance = messageInstance.moveDestination;

                          NSNumber* newUID = nil;
                          if(UIDs)
                          {
                              newUID = UIDs[messageInstance.uid];
                          }

                          [messageInstance moveOnIMAPDoneWithNewUID:newUID withContext:localContext toInstance:destinationInstance];
                      }];
                 }

                 [MergeLocalChangesHelper releaseLockOnMessageInstance:messageInstanceObjectID];
             }];

            if(pickDeviceMessages)
                [copyOperation setHighPriority];
            else
                [copyOperation setLowPriority];

            [copyOperation addToMailCoreQueueWithDisconnectOperation:disconnectOperation];
        }
        else
        {
            //NSLog(@"Cannot move instance with UID %@ and movedTo relationship %@", messagesInstance.uid, messagesInstance.movedToInstance);

            //this might happen if several copies of the same message are moved into one folder:
            //only one copy of the message will be created at the destination, so that the movedTo relationship
            //of previously moved messages is overwritten by any subsequently moved messages

            //solution: in moveToFolder a new instance should be created for each moved copy
            //that should do the trick

            //UPDATE: now creating a separate instance for each move

            //this will also happen if the same message is moved several times in succession (before the server can be told)
            //in this case everything is dandy, so long as the first move can be performed
            //all other movedAway instances will return NO to isMovedAway
        }
    }
}

+ (void)mergeChangedFlagsForAccount:(IMAPAccount*)account inFolder:(IMAPFolderSetting*)localFolderSetting inContext:(NSManagedObjectContext*)localContext usingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation deviceMessages:(BOOL)pickDeviceMessages
{
    NSSet* flagsChangedInstances = [localFolderSetting.flagsChangedOnMessages copy];

    for(EmailMessageInstance* messageInstance in flagsChangedInstances)
    {
        BOOL devicePickCondition = ([messageInstance.message isDeviceMessage] && pickDeviceMessages) || (![messageInstance.message isDeviceMessage] && !pickDeviceMessages);

        if(!devicePickCondition)
            continue;

        if(messageInstance.addedToFolder || messageInstance.movedToInstance || messageInstance.deletedFromFolder)
            continue;
        
        if([messageInstance isOnServer])
        {
            MCOMessageFlag flagsToSet = (MCOMessageFlag)(messageInstance.flags.integerValue)%(1 << 9);

            NSManagedObjectID* messageInstanceObjectID = messageInstance.objectID;

            if(![MergeLocalChangesHelper lockMessageInstance:messageInstanceObjectID])
            {
                continue;
            }
            
            StoreFlagsOperation* storeFlagsOperation = [StoreFlagsOperation storeFlagsWithFolderPath:localFolderSetting.path uids:[MCOIndexSet indexSetWithIndex:messageInstance.uid.integerValue] kind:MCOIMAPStoreFlagsRequestKindSet flags:flagsToSet usingSession:session withCallback:^(NSError* error)
             {
                 if(!error)
                 {
                     [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext)
                      {

                          //TO DO: change the flags on the destination of a possible move operation instead - just in case the message was moved after the flags were changed, but before the IMAP operation returned

                          EmailMessageInstance* messageInstance = [EmailMessageInstance messageInstanceWithObjectID:messageInstanceObjectID inContext:localContext];

                          [messageInstance setFlagsChangedInFolder:nil];

                          NSError* error = nil;
                          [localContext save:&error];
                          if(error)
                              NSLog(@"Error saving local context!! %@", error);
                      }];
                 }

                 [MergeLocalChangesHelper releaseLockOnMessageInstance:messageInstanceObjectID];
             }];


            if(pickDeviceMessages)
                [storeFlagsOperation setHighPriority];
            else
                [storeFlagsOperation setLowPriority];

            [storeFlagsOperation addToMailCoreQueueWithDisconnectOperation:disconnectOperation];
        }
        else
            [messageInstance setFlagsChangedInFolder:nil];
    }
}


+ (void)mergeChangedLabelsForAccount:(IMAPAccount*)account inFolder:(IMAPFolderSetting*)localFolderSetting inContext:(NSManagedObjectContext*)localContext usingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation deviceMessages:(BOOL)pickDeviceMessages

{
    if(![localFolderSetting isKindOfClass:[GmailLabelSetting class]])
        return;

    NSSet* labelsChangedInstances = [(GmailLabelSetting*)localFolderSetting labelsChangedOnMessages];

    for(EmailMessageInstance* messagesInstance in labelsChangedInstances)
    {
        if(messagesInstance.addedToFolder || messagesInstance.movedToInstance || messagesInstance.deletedFromFolder)
            continue;

        if(messagesInstance.uid)
        {
            NSSet* labels = [MessageSyncHelper labelStringsForStoreMessageInstance:messagesInstance];

            NSArray* labelsArray = [labels allObjects];

            NSManagedObjectID* messageInstanceObjectID = messagesInstance.objectID;

            if(![MergeLocalChangesHelper lockMessageInstance:messageInstanceObjectID])
            {
                continue;
            }
            
            StoreLabelsOperation* storeLabelsOperation = [StoreLabelsOperation storeLabelsWithFolderPath:localFolderSetting.path uids:[MCOIndexSet indexSetWithIndex:messagesInstance.uid.integerValue] labels:labelsArray kind:MCOIMAPStoreFlagsRequestKindSet usingSession:session withCallback:^(NSError *error)
            {
                if(!error)
                {
                    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

                        EmailMessageInstance* messageInstance = [EmailMessageInstance messageInstanceWithObjectID:messageInstanceObjectID inContext:localContext];

                        //TO DO: change the flags on the destination of a possible move operation instead - just in case the message was moved after the labels were changed, but before the IMAP operation returned

                        [messageInstance setLabelsChangedInFolder:nil];

                        NSError* error = nil;
                        [localContext save:&error];
                        if(error)
                            NSLog(@"Error saving local context!! %@", error);
                    }];
                }

                [MergeLocalChangesHelper releaseLockOnMessageInstance:messageInstanceObjectID];
            }];

            if(pickDeviceMessages)
                [storeLabelsOperation setHighPriority];
            else
                [storeLabelsOperation setLowPriority];

            [storeLabelsOperation addToMailCoreQueueWithDisconnectOperation:disconnectOperation];
        }
    }
}


+ (void)mergeDeletedMessagesForAccount:(IMAPAccount*)account inFolder:(IMAPFolderSetting*)localFolderSetting inContext:(NSManagedObjectContext*)localContext usingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation deviceMessages:(BOOL)pickDeviceMessages
{
    NSSet* locallyDeletedMessages = [localFolderSetting.deletedMessages copy];

    //do not include message instances that have been moved
    //the move should be performed before the delete operation can go ahead
    //a shortcut might be interesting, but none of this is visible to the user, and moving, then deleting shouldn't take too much time

    NSMutableSet* locallyDeletedMessagesThatHaveNotBeenMoved = [NSMutableSet new];

    //go through the messages that are candidates for deletion and various potential reasons for preclusion
    for(EmailMessageInstance* messageInstance in locallyDeletedMessages)
    {
        if(![messageInstance isKindOfClass:[EmailMessageInstance class]])
        {
            NSLog(@"Error! Expected device message instance, got: %@", messageInstance);
            return;
        }
        
        BOOL devicePickCondition = ([messageInstance.message isDeviceMessage] && pickDeviceMessages) || (![messageInstance.message isDeviceMessage] && !pickDeviceMessages);

        if(!devicePickCondition)
            continue;

        //if the instance has been moved we should do the move first
        if([messageInstance movedFromInstance])
        {
            continue;
        }

        //if the message has been added locally it can just be deleted, since it's not on the server
        //it doesn't have a UID anyway
        if(messageInstance.addedToFolder)
        {
            if([MergeLocalChangesHelper lockMessageInstance:messageInstance.objectID])
            {
                [localContext deleteObject:messageInstance];
            }

            //[localContext processPendingChanges];

            continue;
        }

        if(![messageInstance.message isDownloaded])
        {
            //need to download a message instance before it can be deleted, so that it can be backed up
            NSManagedObjectID* messageInstanceObjectID = messageInstance.objectID;
            [ThreadHelper runAsyncOnMain:^{
                
                EmailMessageInstance* messageInstanceOnMain = [EmailMessageInstance messageInstanceWithObjectID:messageInstanceObjectID inContext:MAIN_CONTEXT];

                [DownloadHelper downloadMessageInstance:messageInstanceOnMain usingSession:session disconnectOperation:disconnectOperation urgent:NO alsoDownloadAttachments:YES];
            }];
            continue;
        }

        BOOL allAttachmentsDownloaded = YES;

        for(FileAttachment* attachment in messageInstance.message.allAttachments)
        {
            //should first download all attachments for the same reason
            if(![attachment isDownloaded])
            {
                NSManagedObjectID* attachmentObjectID = attachment.objectID;
                [ThreadHelper runAsyncOnMain:^{

                    FileAttachment* attachmentOnMain = (FileAttachment*)[MAIN_CONTEXT existingObjectWithID:attachmentObjectID error:nil];

                    [attachmentOnMain downloadUsingSession:session disconnectOperation:disconnectOperation withCallback:nil];
                }];
                allAttachmentsDownloaded = NO;
            }
        }

        if(!allAttachmentsDownloaded)
            continue;

        if(!messageInstance.uid)
        {
            if([MergeLocalChangesHelper lockMessageInstance:messageInstance.objectID])
            {
                [localContext deleteObject:messageInstance];
            }
            continue;
        }


        [locallyDeletedMessagesThatHaveNotBeenMoved addObject:messageInstance];
    }

    //only use the instances picked out in the previous loop
    locallyDeletedMessages = locallyDeletedMessagesThatHaveNotBeenMoved;

    if(locallyDeletedMessagesThatHaveNotBeenMoved.count>0)
    {
            MCOIndexSet* UIDsToBeDeleted = [MCOIndexSet indexSet];

            NSMutableSet* messagesToBeDeleted = [NSMutableSet new];

            for(EmailMessageInstance* messageInstance in locallyDeletedMessagesThatHaveNotBeenMoved)
            {
                if(![MergeLocalChangesHelper lockMessageInstance:messageInstance.objectID])
                {
                    continue;
                }

                [UIDsToBeDeleted addIndex:messageInstance.uid.integerValue];
                [messagesToBeDeleted addObject:messageInstance];
            }

            if(UIDsToBeDeleted.count>0)
            {
                NSMutableSet* locallyDeletedMessagesObjectIDs = [NSMutableSet new];

                for (EmailMessageInstance* messageInstance in messagesToBeDeleted)
                {
                    if(messageInstance.objectID.isTemporaryID)
                    {
                        [localContext obtainPermanentIDsForObjects:@[messageInstance] error:nil];
                    }

                    if(messageInstance.objectID.isTemporaryID)
                    {
                        NSLog(@"Still no permanent ID for object %@", messageInstance);
                    }
                    else
                        [locallyDeletedMessagesObjectIDs addObject:messageInstance.objectID];
                }

                DeleteMessagesOperation* deleteOperation = [DeleteMessagesOperation deleteWithFolderPath:localFolderSetting.path uids:UIDsToBeDeleted usingSession:session withCallback:^(NSError *error)
                 {
                     if(!error)
                     {
                         [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext)
                          {

                              for(NSManagedObjectID* messageInstanceObjectID in locallyDeletedMessagesObjectIDs)
                              {
                                  EmailMessageInstance* messageInstance = [EmailMessageInstance messageInstanceWithObjectID:messageInstanceObjectID inContext:localContext];

                                  //the message has been deleted on the server, so this instance can be discarded
                                  if(messageInstance)
                                  {

                                      //#if TARGET_OS_IPHONE
                                      //
                                      //#else
                                      //                                         NSManagedObjectID* ownObjectID = messageInstance.objectID;
                                      //
                                      //                                         [MAIN_CONTEXT performBlockAndWait:^{
                                      //
                                      //                                             EmailMessageInstance* instanceOnMain = [EmailMessageInstance messageInstanceWithObjectID:ownObjectID inContext:MAIN_CONTEXT];
                                      //
                                      //                                             [[EmailMessageController sharedInstance] removeMessageObjectFromTable:instanceOnMain animated:YES];
                                      //
                                      //                                         }];
                                      //
                                      //#endif

                                      if(VERBOSE_DELETE)
                                      {
                                          [messageInstance.message outputInstancesInfoToConsole];

                                          NSLog(@"Delete 12: %@, %@", messageInstance.objectID, messageInstance);
                                      }

                                      [localContext deleteObject:messageInstance];



                                      //[localContext processPendingChanges];

                                      if(VERBOSE_DELETE)
                                      {
                                          [messageInstance.message outputInstancesInfoToConsole];
                                      }
                                  }
                              }
                          }];
                     }

                     for(NSManagedObjectID* messageInstanceObjectID in locallyDeletedMessagesObjectIDs)
                     {
                         [MergeLocalChangesHelper releaseLockOnMessageInstance:messageInstanceObjectID];
                     }
                 }];

                if(pickDeviceMessages)
                    [deleteOperation setHighPriority];
                else
                    [deleteOperation setLowPriority];

                [deleteOperation addToMailCoreQueueWithDisconnectOperation:disconnectOperation];
            }
        }
}


/**Goes through local messages and deals with local additions and deletions*/
+ (void)mergeLocalChangesForAccount:(IMAPAccount*)account inFolder:(IMAPFolderSetting*)folderSetting userInitiated:(BOOL)userInitiated
{
    //don't forget to merge device messages in SPAM as well(!)
    if ([folderSetting isSpam])
        [MergeLocalChangesHelper mergeDeviceMessagesForAccount:account inFolder:folderSetting];
    
    if(![AccountCheckManager shouldMergeLocalChangesInFolder:folderSetting userInitiated:userInitiated])
        return;

    NSManagedObjectID* folderSettingID = folderSetting.objectID;

    //start new local thread
    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext)
     {

         IMAPFolderSetting* localFolderSetting = [IMAPFolderSetting folderSettingWithObjectID:folderSettingID inContext:localContext];

         //if passedSession is nil, create one
         //otherwise use the one provided

         [localFolderSetting.account freshSessionWithScope:^(MCOIMAPSession *session, DisconnectOperation *disconnectOperation) {

             [disconnectOperation setCallback:^(NSError *error) {

                 [localContext performBlock:^{

             [AccountCheckManager didMergeLocalChangesInFolder:localFolderSetting];

                 }];
         }];


         //first take care of messages added locally
         //push them to the server
         [MergeLocalChangesHelper mergeAddedMessagesForAccount:account inFolder:localFolderSetting inContext:localContext usingSession:session disconnectOperation:disconnectOperation deviceMessages:NO];
         
         //now the moved messages
         [MergeLocalChangesHelper mergeMovedMessagesForAccount:account inFolder:localFolderSetting inContext:localContext usingSession:session disconnectOperation:disconnectOperation deviceMessages:NO];
         
         //messages that have had flags changed
         [MergeLocalChangesHelper mergeChangedFlagsForAccount:account inFolder:localFolderSetting inContext:localContext usingSession:session disconnectOperation:disconnectOperation deviceMessages:NO];
         
         //in the case of gmail accounts
         //update labels, if changed
         if([localFolderSetting isKindOfClass:[GmailLabelSetting class]])
             [MergeLocalChangesHelper mergeChangedLabelsForAccount:account inFolder:localFolderSetting inContext:localContext usingSession:session disconnectOperation:disconnectOperation deviceMessages:NO];
         
         //tell the server to remove locally deleted messages
         [MergeLocalChangesHelper mergeDeletedMessagesForAccount:account inFolder:localFolderSetting inContext:localContext usingSession:session disconnectOperation:disconnectOperation deviceMessages:NO];
         
         }];
    }];
}



+ (void)mergeDeviceMessagesForAccount:(IMAPAccount*)account inFolder:(IMAPFolderSetting*)folderSetting
{
    NSManagedObjectID* folderSettingID = folderSetting.objectID;

    //start new local thread
    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext)
     {

         IMAPFolderSetting* localFolderSetting = [IMAPFolderSetting folderSettingWithObjectID:folderSettingID inContext:localContext];

         [localFolderSetting.account freshSessionWithScope:^(MCOIMAPSession *session, DisconnectOperation *disconnectOperation) {

             [disconnectOperation setCallback:^(NSError *error) {

                 [localContext performBlock:^{

                     [AccountCheckManager didMergeLocalChangesInFolder:localFolderSetting];

                 }];
         }];

         //first take care of messages added locally
         //push them to the server
         [MergeLocalChangesHelper mergeAddedMessagesForAccount:account inFolder:localFolderSetting inContext:localContext usingSession:session disconnectOperation:disconnectOperation deviceMessages:YES];

         //now the moved messages
         [MergeLocalChangesHelper mergeMovedMessagesForAccount:account inFolder:localFolderSetting inContext:localContext usingSession:session disconnectOperation:disconnectOperation deviceMessages:YES];

         //messages that have had flags changed
         [MergeLocalChangesHelper mergeChangedFlagsForAccount:account inFolder:localFolderSetting inContext:localContext usingSession:session disconnectOperation:disconnectOperation deviceMessages:YES];

         //in the case of gmail accounts
         //update labels, if changed
         if([localFolderSetting isKindOfClass:[GmailLabelSetting class]])
             [MergeLocalChangesHelper mergeChangedLabelsForAccount:account inFolder:localFolderSetting inContext:localContext usingSession:session disconnectOperation:disconnectOperation deviceMessages:YES];

         //tell the server to remove locally deleted messages
         [MergeLocalChangesHelper mergeDeletedMessagesForAccount:account inFolder:localFolderSetting inContext:localContext usingSession:session disconnectOperation:disconnectOperation deviceMessages:YES];

         }];

//         [localQueue addOperationWithBlock:^{
//             if(createdSession)
//                 [session disconnectWhenDone];
//         }];
     }];
}

+ (void)mergeAllDeviceMessages
{
    for(IMAPAccountSetting* accountSetting in [UserSettings usedAccounts])
    {
        IMAPFolderSetting* mynigmaFolder = accountSetting.mynigmaFolder;

        if(mynigmaFolder)
            [MergeLocalChangesHelper mergeDeviceMessagesForAccount:accountSetting.account inFolder:mynigmaFolder];
    }
}


@end
