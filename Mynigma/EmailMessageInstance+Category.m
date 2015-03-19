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

#import "FolderListController_iOS.h"

#else

#import "FolderListController_MacOS.h"

#endif

#import "EmailMessageInstance+Category.h"
#import "IMAPFolderSetting+Category.h"
#import "AppDelegate.h"
#import "GmailLabelSetting.h"
#import "IMAPAccountSetting+Category.h"
#import <MailCore/MailCore.h>
#import "GmailAccountSetting.h"
#import "IMAPAccount.h"
#import "MynigmaMessage+Category.h"
#import "EmailMessage+Category.h"
#import "HTMLPurifier.h"
#import "FileAttachment+Category.h"
#import "IMAPFolderManager.h"
#import "MCODelegate.h"
#import "EmailMessageData.h"
#import "AddressDataHelper.h"
#import "EmailMessageController.h"
#import "FormattingHelper.h"
#import "DeviceMessage+Category.h"
#import "UIDHelper.h"
#import "FetchAttachmentOperation.h"
#import "FetchMessageOperation.h"
#import "AccountCheckManager.h"
#import "DisconnectOperation.h"
#import "SelectionAndFilterHelper.h"
#import "AccountCreationManager.h"
#import "Recipient.h"
#import "FetchContentOperation.h"




#define VERBOSE NO


@implementation EmailMessageInstance (Category)



#pragma mark - MOVING ETC.


/**Call this if a locally moved message has been moved (i.e. copied) on the IMAP server - any previous movedAwayMessageInstances can now be safely deleted*/
- (void)moveOnIMAPDoneWithNewUID:(NSNumber*)newUID withContext:(NSManagedObjectContext*)localContext toInstance:(EmailMessageInstance*)newInstance
{
    //[ThreadHelper ensureLocalThread:localContext];

    if(VERBOSE)
    {
        NSLog(@"After IMAP move of %@ from %@ to %@:", self, self.folderSetting.displayName, newInstance.folderSetting.displayName);
        [self.message outputInstancesInfoToConsole];
    }

    //self *must* be the source of the move, unless something has gone terribly wrong(!)
    if([self isSourceOfMove])
    {
        if(VERBOSE)
        {
            NSLog(@"Have moved message with UID %@ in folder %@ to folder %@ with UID %@", self.uid, self.movedAwayFromFolder.displayName, newInstance.folderSetting.displayName, newUID);
        }

        //don't overwrite a potentially pre-existing UID if newUID is nil...
        if(newUID)
        {
            if(VERBOSE)
                NSLog(@"Changing UID from %@ to %@", newInstance.uid, newUID);
            [newInstance changeUID:newUID];
        }

        //if no UID is returned (but the operation was successful) then don't do anything with the new message instance - at the next fetch the UID ought to be set to the correct value

        //now remove the old instance - it's no longer needed
        //mark it as deleted, so it will be removed from the server in the next round of mergeLocalChanges
        //there is no hurry, since neither movedAwayFromFolder nor deletedFromFolder instances are displayed to the user

        EmailMessageInstance* sourceInstance = self;

        EmailMessageInstance* intermediateInstance = sourceInstance.movedToInstance;

        EmailMessageInstance* nextIntermediateInstance;

        //go through the chain of messages that are neither source nor destination of the move
        while(intermediateInstance && ![intermediateInstance isEqual:newInstance])
        {
            nextIntermediateInstance = intermediateInstance.movedToInstance;

            //delete the message instance from the store - this will also cut the movedFromInstance relationships

            if(VERBOSE_DELETE)
            {
                [intermediateInstance.message outputInstancesInfoToConsole];

                NSLog(@"Delete 7: %@, %@", intermediateInstance.objectID, intermediateInstance);
            }

            [localContext deleteObject:intermediateInstance];

            //[localContext processPendingChanges];

            if(VERBOSE_DELETE)
                [intermediateInstance.message outputInstancesInfoToConsole];

            //move on to the next item in the chain
            intermediateInstance = nextIntermediateInstance;
        }

        //mark source as deleted
        //the actual IMAP operation was COPY, so we still need to delete the source instance
        [self setDeletedFromFolder:self.movedAwayFromFolder];

        //also remove any labels the source instance may have - in fact, these should already be deleted, but doing it again cannot hurt
        [self setHasLabels:nil];
        [self setUnreadWithLabels:nil];

        //no longer moved away
        [self setMovedAwayFromFolder:nil];

        //this is only necessary if there are no intermediate instances (a direct move from A to B)
        [self setMovedToInstance:nil];
    }
    else
    {
        NSLog(@"Move on IMAP done, but the message says it hasn't been moved away!!");
    }
}





- (void)deleteInstanceInContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    if(VERBOSE)
        NSLog(@"Deleting message with UID %@ in folder %@", self.uid, self.inFolder.displayName);

    IMAPAccountSetting* accountSetting = self.accountSetting;
    if(!accountSetting)
        return;

    //don't delete instances that have been moved away: they shouldn't be displayed to the user anyway
    if(self.movedAwayFromFolder)
    {
        if(VERBOSE)
            NSLog(@"Attempting to delete a \"moved away\" instance!!!");
        return;
    }

    if(self.movedFromInstance)
    {
        if(VERBOSE)
            NSLog(@"Deleting a \"moved from\" instance!!!");

        //assumption is that self will be the destination of the move
        //otherwise it wouldn't even be displayed to the user
        //simply go ahead and mark the message as deleted
        //on the server, the move will be performed before the delete
        //this is because the move IMAP operation might already be taking place
    }

    if(self.inFolder)
    {
        [self setDeletedFromFolder:self.inFolder];
        [self setInFolder:nil];
        [self setUnreadInFolder:nil];
        [self setHasLabels:nil];
        [self setUnreadWithLabels:nil];
        [self setFlagsChangedInFolder:nil];
        [self setLabelsChangedInFolder:nil];
    }
}

/**CALL ON MAIN*/
- (EmailMessageInstance*)moveToFolder:(IMAPFolderSetting*)folderSetting
{
    //[ThreadHelper ensureLocalThread:localContext];

    if(VERBOSE)
    {
        NSLog(@"Before moving %@ from %@ to %@:", self, self.folderSetting.displayName, folderSetting.displayName);
        [self.message outputInstancesInfoToConsole];
    }

    //this shouldn't happen:
    //the message has already been moved in a previous operation
    //don't move it again - that would be asking for trouble
    //better not to do anything and wait for the UI to update
    if([self movedToInstance])
    {
        if(VERBOSE)
            NSLog(@"Moving a message for the second time!!! %@->%@", self.folderSetting.displayName, self.movedToInstance.folderSetting.displayName);

        if(VERBOSE)
        {
            NSLog(@"After moving %@ from %@ to %@:", self, self.folderSetting.displayName, folderSetting.displayName);
            [self.message outputInstancesInfoToConsole];
        }
        return nil;
    }


    if([self.inFolder isEqual:folderSetting])
    {
        NSLog(@"Cannot move a message from a folder to itself!!!");

        if(VERBOSE)
        {
            NSLog(@"After moving %@ from %@ to %@:", self, self.folderSetting.displayName, folderSetting.displayName);
            [self.message outputInstancesInfoToConsole];
        }
        return self;
    }

    //if the message has already been deleted don't move it
    if(self.deletedFromFolder)
    {
        if(VERBOSE)
            NSLog(@"Cannot move a message that has been deleted!!!");

        if(VERBOSE)
        {
            NSLog(@"After moving %@ from %@ to %@:", self, self.folderSetting.displayName, folderSetting.displayName);
            [self.message outputInstancesInfoToConsole];
        }
        return self;
    }

    //if the message was added locally it should not be marked as moved, since a copyMessage IMAP operation would not succeed
    //simply put it into the new folder instead - it will be appended to that folder in mergeLocalChanges
    //
    //UPDATE - no longer true: the IMAP move operation will not be performed on messages that are marked as added, so the move operation won't go ahead until the instance has been added to the server
    // - that makes more sense, since the addition IMAP operation may already be in progress
    //    if([self addedToFolder])
    //    {
    //        if(VERBOSE)
    //            NSLog(@"Message was added locally - moving it by setting inFolder relationship!");
    //        [self setInFolder:folderSetting];
    //        if([self unreadInFolder])
    //            [self setUnreadInFolder:self.inFolder];
    //
    //        if(VERBOSE)
    //        {
    //            NSLog(@"After moving %@ from %@ to %@:", self, self.folderSetting.displayName, folderSetting.displayName);
    //            [self.message outputInstancesInfoToConsole];
    //        }
    //        return self;
    //    }

    //ACTUALLY DON'T USE THE FOLLOWING SHORTCUT

    // NO: if the source message instance is already moved away from a third folder then use shortcut:
    // NO: A->B->C becomes A->C
    // NO: i.e. self.movedFromInstance.inFolder->self.inFolder->folderSetting becomes self.movedFromInstance.inFolder->folderSetting

    //THE MESSAGE COPY OPERATION MIGHT ALREADY BE IN PROGRESS, IN WHICH CASE THE RESULT WOULD BE CLIENT AND SERVER BEING OUT OF STEP

    if([self movedFromInstance])
    {
        if(VERBOSE)
            NSLog(@"Moving a message that has already been moved. Folders: %@->%@->%@!", self.movedFromInstance.folderSetting.displayName, self.folderSetting.displayName, folderSetting.displayName);

        //        [self setInFolder:folderSetting];
        //
        //        if([self unreadInFolder])
        //            [self setUnreadInFolder:self.inFolder];
        //
        //
        //        return self;
    }

    //don't do an IMAP move from the outbox folder
    //just take the message and put it into the new folder
    //need to take care that unreadInFolder etc. is set correctly
    if([self isInOutboxFolder])
    {
        if([self movedFromInstance])
        {
            NSLog(@"Message instance has a moved from instance!!");
            [[self message] outputInstancesInfoToConsole];
        }

        [self changeUID:nil];

        [self setInFolder:folderSetting];
        [self setAddedToFolder:folderSetting];

        if(self.unreadInFolder)
            [self setUnreadInFolder:folderSetting];

        [self removeHasLabels:self.hasLabels];
        [self removeUnreadWithLabels:self.unreadWithLabels];
    }


    /*
     //this will check if an instance exists in the destination folder
     //if not, it will create a new one
     EmailMessageInstance* newInstance = [EmailMessageInstance findOrMakeNewInstanceForMessage:self.message inFolder:folderSetting inContext:localContext];
     */

    //this will create a new message instance in the destination folder, even if a different one already exists
    //that's important because the existing instance might also have been moved into the folder and the existing movedFromInstance relationship needs to be preserved
    EmailMessageInstance* newInstance = [EmailMessageInstance makeNewInstanceForMessage:self.message inFolder:folderSetting inContext:self.managedObjectContext];

    if(!newInstance)
    {
        NSLog(@"Cannot create message instance!!");
    }

    //mark the source message as moved away and remove its inFolder relationship
    [self setMovedAwayFromFolder:self.folderSetting];

    if(!self.folderSetting)
    {
        NSLog(@"Message is lacking a folder setting!!!");
    }

    [self setInFolder:nil];

    if(!self.uid)
    {
        if(VERBOSE)
            NSLog(@"Moving a message without a uid!!");

    }

    //connect it to the destination
    [self setMovedToInstance:newInstance];


    if([self unreadInFolder])
    {
        [newInstance setUnreadInFolder:newInstance.inFolder];
        [newInstance setUnreadWithLabels:self.hasLabels];
        [self setUnreadInFolder:nil];
    }

    if([self labelsChangedInFolder])
    {
        [self setLabelsChangedInFolder:nil];
        [newInstance setLabelsChangedInFolder:(GmailLabelSetting*)newInstance.inFolder];
    }

    if([self flagsChangedInFolder])
    {
        [self setFlagsChangedInFolder:nil];
        [newInstance setFlagsChangedInFolder:(GmailLabelSetting*)newInstance.inFolder];
    }

    if(self.hasLabels)
    {
        [newInstance setHasLabels:self.hasLabels];
        [self removeHasLabels:self.hasLabels];
        [self removeUnreadWithLabels:self.unreadWithLabels];
    }

    //the destination instance should keep the flags, but the UID won't be assigned until the copyMessage IMAP operation has been performed
    [newInstance changeUID:nil];
    [newInstance setFlags:self.flags];

    //remove the message from the list of displayed messages, if applicable
    //only do this if running on the main thread and working with the main context
    //otherwise this will be done when the local context is saved
    if([self.managedObjectContext isEqual:MAIN_CONTEXT])
    {
#if TARGET_OS_IPHONE

        //TO DO: implement table update for iOS

#else

        [[EmailMessageController sharedInstance] removeMessageObjectFromTable:self animated:YES];
        [[EmailMessageController sharedInstance] insertMessageObjectIntoTable:newInstance animated:YES];

#endif

    }

    if(VERBOSE)
    {
        NSLog(@"After moving %@ from %@ to %@:", self, self.folderSetting.displayName, folderSetting.displayName);
        [self.message outputInstancesInfoToConsole];
    }

    return newInstance;
}



/**Assuming that the message has an inFolder relationship set. It should also not have been moved, but to make doubly sure we'll delete any existing movedFromInstances, if applicable...*/
- (void)deleteCompletelyWithContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    if(self.folderSetting && !self.deletedFromFolder)
    {
        EmailMessageInstance* previousInstance = self.movedFromInstance;

        EmailMessageInstance* nextPreviousInstance;

        while(previousInstance)
        {
            nextPreviousInstance = previousInstance.movedFromInstance;

            //#if TARGET_OS_IPHONE
            //
            //#else
            //            NSManagedObjectID* ownObjectID = previousInstance.objectID;
            //
            //            [MAIN_CONTEXT performBlockAndWait:^{
            //
            //                EmailMessageInstance* instanceOnMain = [EmailMessageInstance messageInstanceWithObjectID:ownObjectID inContext:MAIN_CONTEXT];
            //
            //                [[EmailMessageController sharedInstance] removeMessageObjectFromTable:instanceOnMain animated:YES];
            //
            //            }];
            //
            //#endif

            NSLog(@"Delete 8a");
            [localContext deleteObject:previousInstance];

            previousInstance = nextPreviousInstance;
        }

        //#if TARGET_OS_IPHONE
        //
        //#else
        //        NSManagedObjectID* ownObjectID = self.objectID;
        //
        //        [MAIN_CONTEXT performBlockAndWait:^{
        //
        //            EmailMessageInstance* instanceOnMain = [EmailMessageInstance messageInstanceWithObjectID:ownObjectID inContext:MAIN_CONTEXT];
        //
        //            [[EmailMessageController sharedInstance] removeMessageObjectFromTable:instanceOnMain animated:YES];
        //
        //        }];
        //
        //#endif
        //        NSLog(@"Delete 8");

        [UIDHelper removeUID:self.uid.integerValue fromFolder:self.folderSetting];

        //set everything to nil so the instance won't be found or used
        //totally unnecessary. whatevs...

        [self setMessage:nil];
        [self setUid:nil];
        [self setInFolder:nil];
        [self setDeletedFromFolder:nil];
        [self setAddedToFolder:nil];
        [self setMovedAwayFromFolder:nil];
        [self setMovedFromInstance:nil];
        [self setMovedToInstance:nil];


        [localContext deleteObject:self];


#if TARGET_OS_IPHONE

#else

        NSManagedObjectID* emailMessageObjectID = self.objectID;

        [ThreadHelper runAsyncOnMain:^{

            EmailMessageInstance* instanceOnMain = [EmailMessageInstance messageInstanceWithObjectID:emailMessageObjectID inContext:MAIN_CONTEXT];

            if(instanceOnMain)
                [[EmailMessageController sharedInstance] removeMessageObjectsFromTable:@[instanceOnMain] animated:YES];
        }];

#endif

        //now delete
        [localContext save:nil];
    }
    else if(self.deletedFromFolder)
    {
        NSLog(@"Attempting to delete completely a message that has already been marked as deleted locally(!!)");
    }
}

- (void)moveToBinOrDelete
{
    IMAPAccountSetting* accountSetting = self.accountSetting;
    if(!accountSetting)
        return;

    if([self isInBinFolder])
    {
        [self deleteInstanceInContext:self.managedObjectContext];
        return;
    }

    if([self isInOutboxFolder])
    {
        IMAPFolderSetting* binFolder = accountSetting.binFolder;
        if(binFolder)
        {
            [self setInFolder:binFolder];
            [self setAddedToFolder:binFolder];
            [self setMovedAwayFromFolder:nil];
            [self setMovedFromInstance:nil];
            [self setMovedToInstance:nil];

            if([self unreadInFolder])
            {
                [self setUnreadInFolder:binFolder];
                [self setUnreadWithLabels:self.hasLabels];
            }
            else
            {
                [self setUnreadWithLabels:nil];
            }
        }
        return;
    }

    IMAPFolderSetting* binFolder = accountSetting.binFolder;

    if(!binFolder)
        return;

    [self markRead];
#if TARGET_OS_IPHONE
    if([accountSetting isKindOfClass:[GmailAccountSetting class]])
    {
        IMAPFolderSetting* selectedFolder = [FolderListController selectedFolderForMessageInstance:self];

        [self moveToFolderOrAddLabel:binFolder fromFolder:selectedFolder];
        return;
    }
    else
        [self moveToFolder:accountSetting.binFolder];
#else
    if([accountSetting isKindOfClass:[GmailAccountSetting class]])
    {
        IMAPFolderSetting* selectedFolder = [FolderListController selectedFolderForMessageInstance:self];

        [self moveToFolderOrAddLabel:binFolder fromFolder:selectedFolder];
        return;
    }
    else
        [self moveToFolder:accountSetting.binFolder];
#endif
}



- (BOOL)canAddLabel:(GmailLabelSetting*)label
{
    if([self.hasLabels containsObject:label])
        return NO;

    if([label isImportant] || [label isStarred])
        return YES;

    if([[label isSystemLabel] boolValue])
        return NO;

    return YES;
}

- (void)addDraggedLabel:(GmailLabelSetting*)label
{
    if([[label isSystemLabel] boolValue] && ![label isImportant] && ![label isStarred])
        return;

    [self addHasLabelsObject:label];
    [self setLabelsChangedInFolder:(GmailLabelSetting*)self.inFolder];

    [SelectionAndFilterHelper refreshMessageInstance:self.objectID];
    [CoreDataHelper save];
}

- (void)removeAllSystemLabels
{
    NSSet* ownLabels = [NSSet setWithSet:self.hasLabels];
    for(GmailLabelSetting* labelSetting in ownLabels)
    {
        if([labelSetting isKindOfClass:[GmailLabelSetting class]] && [[labelSetting isSystemLabel] boolValue])
        {
            [self removeHasLabelsObject:labelSetting];
            [self removeUnreadWithLabelsObject:labelSetting];
        }
    }
}

- (BOOL)canMoveToFolderOrAddLabel:(IMAPFolderSetting*)toFolder fromFolder:(IMAPFolderSetting*)fromFolder
{
    if([toFolder isOutbox])
        return NO;

    if([toFolder isKindOfClass:[GmailLabelSetting class]])
    {
        if([toFolder isInbox])
        {
            if(![fromFolder isInbox])
            {
                return YES;
            }

            return NO;
        }

        if([toFolder isSpam])
        {
            if(![fromFolder isSpam] && ![self isInDraftsFolder])
            {
                return YES;
            }

            return NO;
        }

        if([toFolder isBin])
        {
            if(![fromFolder isBin])
            {
                return YES;
            }

            return NO;
        }

        if([toFolder isDrafts] && [fromFolder isOutbox])
            return YES;

        if([[(GmailLabelSetting*)toFolder isSystemLabel] boolValue])
            return NO;

        return YES;
    }
    else
    {
        return ![toFolder isEqual:fromFolder];
    }
}

- (BOOL)addLabel:(GmailLabelSetting*)label
{
    if(![[self hasLabels] containsObject:label])
    {
        [self addHasLabelsObject:label];
        if([self unreadInFolder])
            [self addUnreadWithLabelsObject:label];
        [self setLabelsChangedInFolder:(GmailLabelSetting*)self.inFolder];
        return YES;
    }

    return NO;
}

- (BOOL)removeLabel:(GmailLabelSetting*)label
{
    if([[self hasLabels] containsObject:label])
    {
        [self removeHasLabelsObject:label];
        [self removeUnreadWithLabelsObject:label];
        [self setLabelsChangedInFolder:(GmailLabelSetting*)self.inFolder];
        return YES;
    }

    return NO;
}

- (BOOL)removeLabels:(NSSet*)labels
{
    BOOL result = [labels isSubsetOfSet:self.hasLabels];

    [self removeHasLabels:labels];
    [self removeUnreadWithLabels:labels];
    if([self.inFolder isKindOfClass:[GmailLabelSetting class]])
        [self setLabelsChangedInFolder:(GmailLabelSetting*)self.inFolder];

    return result;
}

- (void)removeAllLabels
{
    [self removeHasLabels:self.hasLabels];
    [self removeUnreadWithLabels:self.unreadWithLabels];

    if([self.inFolder isKindOfClass:[GmailLabelSetting class]])
        [self setLabelsChangedInFolder:(GmailLabelSetting*)self.inFolder];
}

/**Use only for Gmail: updates inFolder, unreadInFolder etc. relationships - does not cause IMAP commands to be sent to the server*/
/*- (void)putIntoFolder:(GmailLabelSetting*)gmailFolder
 {
 if(![gmailFolder isKindOfClass:[GmailLabelSetting class]])
 return;

 if(self.inFolder)
 [self setInFolder:gmailFolder];

 if([self unreadInFolder])
 [self setUnreadInFolder:gmailFolder];

 if(self.addedToFolder)
 [self setAddedToFolder:gmailFolder];

 if(self.movedAwayFromFolder)
 [self setMovedAwayFromFolder:gmailFolder];
 }*/


/**Performs the action appropriate for a drag and drop of the instance into the toFolder. The fromFolder is needed because inFolder might be "All Mail" while "Inbox" is selected (in this case fromFolder will be Inbox)*/
- (void)moveToFolderOrAddLabel:(IMAPFolderSetting*)toFolder fromFolder:(IMAPFolderSetting*)fromFolder
{
    if(VERBOSE)
    {
        NSLog(@".After moving %@ from %@ to %@:", self, fromFolder.displayName, toFolder.displayName);
        [self.message outputInstancesInfoToConsole];
    }


    //this shouldn't happen:
    //the message has already been moved in a previous operation
    //don't move it again - that would be asking for trouble
    //better not to do anything and wait for the UI to update
    if([self movedToInstance] || !self.inFolder)
    {
        if(VERBOSE)
            NSLog(@"Moving a message for the second time!!! %@->%@", self.folderSetting.displayName, self.movedToInstance.folderSetting.displayName);

        if(VERBOSE)
        {
            NSLog(@".After moving %@ from %@ to %@:", self, fromFolder.displayName, toFolder.displayName);
            [self.message outputInstancesInfoToConsole];
        }
        return;
    }

    //if we're moving from the outbox it's enough to simply set the inFolder connection and mark the message as added to that folder
    //after all, the server doesn't know about the outbox, so no move is necessary
    if([fromFolder isOutbox])
    {
        [self removeLabels:self.hasLabels];

        if([toFolder isKindOfClass:[GmailLabelSetting class]])
        {
            if([toFolder isBin] || [toFolder isSpam])
            {
                [self setInFolder:toFolder];
                [self setAddedToFolder:toFolder];
                [self changeUID:nil];

                if(VERBOSE)
                {
                    NSLog(@".After moving %@ from %@ to %@:", self, fromFolder.displayName, toFolder.displayName);
                    [self.message outputInstancesInfoToConsole];
                }
                return;
            }

            GmailLabelSetting* allMailFolder = (GmailLabelSetting*)toFolder.accountSetting.allMailOrInboxFolder;
            [self setInFolder:allMailFolder];
            [self setAddedToFolder:allMailFolder];
            [self changeUID:nil];

            [self addLabel:(GmailLabelSetting*)toFolder];

            if(VERBOSE)
            {
                NSLog(@".After moving %@ from %@ to %@:", self, fromFolder.displayName, toFolder.displayName);
                [self.message outputInstancesInfoToConsole];
            }
            return;
        }
        else
        {
            [self setInFolder:toFolder];
            [self setAddedToFolder:toFolder];
            [self changeUID:nil];

            if(VERBOSE)
            {
                NSLog(@".After moving %@ from %@ to %@:", self, fromFolder.displayName, toFolder.displayName);
                [self.message outputInstancesInfoToConsole];
            }
            return;
        }
    }

    if([toFolder isKindOfClass:[GmailLabelSetting class]])
    {
        if([toFolder isInbox])
        {
            if(![fromFolder isInbox])
            {
                if([fromFolder isSpam])
                {
                    if(self.flags.integerValue & MCOMessageFlagMDNSent)
                        [self addLabel:(GmailLabelSetting*)toFolder.accountSetting.sentFolder];
                    [self removeLabel:(GmailLabelSetting*)fromFolder];
                    [self moveToFolder:self.accountSetting.allMailOrInboxFolder];
                }

                if([fromFolder isBin])
                {
                    if(self.flags.integerValue & MCOMessageFlagMDNSent)
                        [self addLabel:(GmailLabelSetting*)toFolder.accountSetting.sentFolder];
                    [self removeLabel:(GmailLabelSetting*)fromFolder];
                    [self moveToFolder:self.accountSetting.allMailOrInboxFolder];
                }

                if(![toFolder isAllMail])
                {
                    [self addLabel:(GmailLabelSetting*)toFolder];
                }
            }

            if(VERBOSE)
            {
                NSLog(@".After moving %@ from %@ to %@:", self, fromFolder.displayName, toFolder.displayName);
                [self.message outputInstancesInfoToConsole];
            }
            return;
        }

        if([toFolder isSpam])
        {
            if(![fromFolder isSpam] && ![self isInDraftsFolder])
            {
                [self removeLabel:(GmailLabelSetting*)fromFolder];

                //remove 'Important' label, if such a thing exists (i.e. if Gmail is set up to expose it to IMAP)
                GmailLabelSetting* importantLabel = [(GmailAccountSetting*)self.accountSetting importantLabel];
                if(importantLabel)
                    [self removeLabel:importantLabel];

                [self moveToFolder:toFolder];
            }

            if(VERBOSE)
            {
                NSLog(@".After moving %@ from %@ to %@:", self, fromFolder.displayName, toFolder.displayName);
                [self.message outputInstancesInfoToConsole];
            }
            return;
        }

        if([toFolder isBin])
        {
            if(![fromFolder isBin])
            {
                [self removeAllSystemLabels];
                [self removeLabel:(GmailLabelSetting*)fromFolder];
                [self moveToFolder:toFolder];
            }

            if(VERBOSE)
            {
                NSLog(@".After moving %@ from %@ to %@:", self, fromFolder.displayName, toFolder.displayName);
                [self.message outputInstancesInfoToConsole];
            }
            return;
        }

        if([[(GmailLabelSetting*)toFolder isSystemLabel] boolValue])
            return;


        if([fromFolder isInbox] || [fromFolder isSpam] || [fromFolder isBin] || ![fromFolder isGmailSystemLabel])
            [self removeLabel:(GmailLabelSetting*)fromFolder];

        if(![toFolder isAllMail])
            [self addLabel:(GmailLabelSetting*)toFolder];

        if([fromFolder isBin] || [fromFolder isSpam])
        {
            if(self.flags.integerValue & MCOMessageFlagMDNSent)
                [self addLabel:(GmailLabelSetting*)toFolder.accountSetting.sentFolder];
            [self moveToFolder:self.accountSetting.allMailOrInboxFolder];
        }
    }
    else
    {
        [self moveToFolder:toFolder];
    }

    if(VERBOSE)
    {
        NSLog(@".After moving %@ from %@ to %@:", self, fromFolder.displayName, toFolder.displayName);
        [self.message outputInstancesInfoToConsole];
    }
}


/**CALL ON MAIN*/
- (void)moveToSpam
{
    IMAPFolderSetting* spamFolder = self.accountSetting.spamFolder;
    if(spamFolder)
        [self moveToFolder:spamFolder];
}

/**CALL ON MAIN*/
- (void)moveToInbox
{
    [ThreadHelper ensureMainThread];

    IMAPFolderSetting* inboxFolder = self.accountSetting.inboxFolder;
    if([IMAPFolderManager hasAllMailFolder:self.accountSetting])
    {
        EmailMessageInstance* newInstance = [self moveToFolder:self.accountSetting.allMailOrInboxFolder];
        if([inboxFolder isKindOfClass:[GmailLabelSetting class]])
            [newInstance addLabel:(GmailLabelSetting*)inboxFolder];
    }
    else
        if(inboxFolder)
            [self moveToFolder:inboxFolder];
}

/**CALL ON MAIN*/
- (void)moveToSent
{
    [ThreadHelper ensureMainThread];

    if([self isInOutboxFolder])
    {
        IMAPFolderSetting* sentFolder = self.accountSetting.sentFolder;
        if([IMAPFolderManager hasAllMailFolder:self.accountSetting])
        {
            [self setInFolder:self.accountSetting.allMailOrInboxFolder];
            [self setAddedToFolder:self.accountSetting.allMailOrInboxFolder];
            [self changeUID:nil];

            if([sentFolder isKindOfClass:[GmailLabelSetting class]])
                [self addLabel:(GmailLabelSetting*)sentFolder];

            if([self unreadInFolder])
            {
                [self setUnreadInFolder:sentFolder];
                [self setUnreadWithLabels:self.hasLabels];
            }
            else
            {
                [self setUnreadWithLabels:nil];
            }

        }
        else if(sentFolder)
        {
            [self setInFolder:sentFolder];
            [self setAddedToFolder:sentFolder];
            [self changeUID:nil];

            if([self unreadInFolder])
            {
                [self setUnreadInFolder:sentFolder];
                [self setUnreadWithLabels:self.hasLabels];
            }
            else
            {
                [self setUnreadWithLabels:nil];
            }

        }
    }
    else
    {
        IMAPFolderSetting* sentFolder = self.accountSetting.sentFolder;
        if([IMAPFolderManager hasAllMailFolder:self.accountSetting])
        {
            EmailMessageInstance* newInstance = [self moveToFolder:self.accountSetting.allMailOrInboxFolder];
            if([sentFolder isKindOfClass:[GmailLabelSetting class]])
                [newInstance addHasLabelsObject:(GmailLabelSetting*)sentFolder];
        }
        else
            if(sentFolder)
                [self moveToFolder:sentFolder];
    }
}

/**Should only be called by the sending manager shortly before sending a message*/
- (EmailMessageInstance*)moveToOutbox
{
    if(self.isInOutboxFolder)
        return self;

    IMAPFolderSetting* outboxFolderSetting = self.accountSetting.outboxFolder;

    if(!outboxFolderSetting)
    {
        NSLog(@"No outbox folder!!");
        return nil;
    }

    EmailMessageInstance* outboxInstance = [EmailMessageInstance makeNewInstanceForMessage:self.message inFolder:outboxFolderSetting inContext:MAIN_CONTEXT];

    [outboxInstance setFlags:self.flags];
    [outboxInstance setUnreadInFolder:nil];

    IMAPFolderSetting* oldFolder = self.folderSetting;

    if(!oldFolder)
        oldFolder = self.addedToFolder;

    [self setDeletedFromFolder:oldFolder];
    [self setInFolder:nil];
    [self removeHasLabels:self.hasLabels];

    return outboxInstance;
}


/**CALL ON MAIN*/
- (void)moveToDrafts
{
    [ThreadHelper ensureMainThread];

    if([self isInOutboxFolder])
    {
        IMAPFolderSetting* draftsFolder = self.accountSetting.draftsFolder;
        if([IMAPFolderManager hasAllMailFolder:self.accountSetting])
        {
            [self setInFolder:self.accountSetting.allMailOrInboxFolder];
            [self setAddedToFolder:self.accountSetting.allMailOrInboxFolder];
            [self changeUID:nil];

            [self markRead];
            if([draftsFolder isKindOfClass:[GmailLabelSetting class]])
                [self addLabel:(GmailLabelSetting*)draftsFolder];

            if([self unreadInFolder])
            {
                [self setUnreadInFolder:self.inFolder];
                [self setUnreadWithLabels:self.hasLabels];
            }
            else
            {
                [self setUnreadWithLabels:nil];
            }

        }
        else
            if(draftsFolder)
            {
                [self setInFolder:draftsFolder];
                [self setAddedToFolder:draftsFolder];
                [self changeUID:nil];

                if([self unreadInFolder])
                {
                    [self setUnreadInFolder:self.inFolder];
                    [self setUnreadWithLabels:self.hasLabels];
                }
                else
                {
                    [self setUnreadWithLabels:nil];
                }
            }
    }
    else
    {
        IMAPFolderSetting* draftsFolder = self.accountSetting.draftsFolder;
        if([IMAPFolderManager hasAllMailFolder:self.accountSetting])
        {
            EmailMessageInstance* newInstance = [self moveToFolder:self.accountSetting.allMailOrInboxFolder];
            if([draftsFolder isKindOfClass:[GmailLabelSetting class]])
                [newInstance addHasLabelsObject:(GmailLabelSetting*)draftsFolder];
        }
        else
            if(draftsFolder)
                [self moveToFolder:draftsFolder];
    }
}





- (void)UIDNotFoundOnServerWithContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    if(self.inFolder && !self.addedToFolder && !self.movedFromInstance)
    {
        //delete only if this message is actually in a folder, has not been added and not been moved to this folder by the user
        [self deleteCompletelyWithContext:localContext];
    }

    //if the message instance is simply a deletion mark it is no longer required, since the UID is no longer on the server, so no IMAP deleteMessage operation needs to be performed
    if(self.deletedFromFolder)
    {
        [self deleteCompletelyWithContext:localContext];
    }


    if(self.movedAwayFromFolder)
    {
        //error state - the message has been moved away to a different folder, but the copyMessage IMAP operation is bound to fail, since the UID is no longer found on the server

        NSLog(@"Moved away message no longer on the server!!");

        //TO DO: handle this gracefully
    }
}



#pragma mark - OBTAINING MESSAGE INSTANCES

+ (EmailMessageInstance*)findExistingInstanceForMessage:(EmailMessage*)message inFolder:(IMAPFolderSetting*)folderSetting inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    for(EmailMessageInstance* messageInstance in message.instances)
    {
        if([messageInstance.inFolder isEqual:folderSetting])
        {
            return messageInstance;
        }
    }

    return nil;
}


+ (EmailMessageInstance*)findExistingInstanceWithMessageID:(NSString*)messageID andUid:(NSNumber*)uid inFolder:(IMAPFolderSetting*)folderSetting inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    if(messageID)
    {
        EmailMessage* message = [EmailMessage findMessageWithMessageID:messageID inContext:localContext];

        if(message)
        {

            //first check if any of the existing instances already has the correct UID
            //after all, there just *may* be several instances in the same folder, and their UIDs should not be confused
            if(uid)
            {
                for(EmailMessageInstance* messageInstance in message.instances)
                {
                    if([messageInstance.inFolder isEqual:folderSetting])
                    {
                        if([messageInstance.uid isEqual:uid])
                            return messageInstance;
                    }
                }
            }

            for(EmailMessageInstance* messageInstance in message.instances)
            {
                if([messageInstance.inFolder isEqual:folderSetting])
                {
                    if(uid && !messageInstance.uid)
                        [messageInstance changeUID:uid];

                    return messageInstance;
                }
            }
        }
    }

    if(uid)
    {
        NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"EmailMessageInstance"];

        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"(inFolder == %@) AND (uid == %@)", folderSetting, uid];

        [fetchRequest setPredicate:predicate];

        NSArray* results = [localContext executeFetchRequest:fetchRequest error:nil];

        if(results.count>1)
        {
            NSLog(@"More than one message with UID %@ in folder %@", uid, folderSetting.displayName);
        }

        return results.firstObject;
    }

    return nil;
}

+ (EmailMessageInstance*)makeNewInstanceForMessage:(EmailMessage*)message inFolder:(IMAPFolderSetting*)localFolderSetting inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    if(!message)
    {
        NSLog(@"Cannot make instance for nil message!");
        return nil;
    }

    //create a new instance

    NSEntityDescription* description = [NSEntityDescription entityForName:@"EmailMessageInstance" inManagedObjectContext:localContext];

    EmailMessageInstance* newInstance = [[EmailMessageInstance alloc] initWithEntity:description insertIntoManagedObjectContext:localContext];

    [newInstance setInFolder:localFolderSetting];
    [newInstance setMessage:message];
    if(!message.hasHadInstancesAtSomePoint.boolValue)
        [message setHasHadInstancesAtSomePoint:@YES];

    return newInstance;
}

+ (EmailMessageInstance*)findOrMakeNewInstanceForMessage:(EmailMessage*)message inFolder:(IMAPFolderSetting*)localFolderSetting inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    return [EmailMessageInstance findOrMakeNewInstanceForMessage:message inFolder:localFolderSetting inContext:localContext alreadyFoundOne:nil];
}

+ (EmailMessageInstance*)findOrMakeNewInstanceForMessage:(EmailMessage*)message inFolder:(IMAPFolderSetting*)localFolderSetting inContext:(NSManagedObjectContext*)localContext alreadyFoundOne:(BOOL*)foundOne
{
    [ThreadHelper ensureLocalThread:localContext];

    if(!message)
    {
        NSLog(@"Cannot make instance for nil message!");

        if(foundOne)
            *foundOne = NO;

        return nil;
    }

    for(EmailMessageInstance* messageInstance in message.instances)
    {
        if([messageInstance.inFolder isEqual:localFolderSetting])
        {
            if(foundOne)
                *foundOne = YES;
            return messageInstance;
        }

        if([localFolderSetting isKindOfClass:[GmailLabelSetting class]] && [messageInstance.hasLabels containsObject:localFolderSetting])
        {
            if(foundOne)
                *foundOne = YES;
            return messageInstance;
        }
    }

    if(foundOne)
        *foundOne = NO;

    //no instance in this folder, create a new one!

    NSEntityDescription* description = [NSEntityDescription entityForName:@"EmailMessageInstance" inManagedObjectContext:localContext];

    EmailMessageInstance* newInstance = [[EmailMessageInstance alloc] initWithEntity:description insertIntoManagedObjectContext:localContext];


    if([localFolderSetting isKindOfClass:[GmailLabelSetting class]] && ![localFolderSetting isSpam] && ![localFolderSetting isBin] && ![localFolderSetting isOutbox])
    {
        //it's a Gmail label other than Spam or Bin
        //use the All Mail folder instead, but attach the label(!)
        [newInstance setInFolder:localFolderSetting.accountSetting.allMailOrInboxFolder];

        [newInstance addHasLabelsObject:(GmailLabelSetting*)localFolderSetting];
        [newInstance setLabelsChangedInFolder:(GmailLabelSetting*)newInstance.inFolder];
    }
    else
    {
        [newInstance setInFolder:localFolderSetting];
    }

    [newInstance setMessage:message];

    if(!message.hasHadInstancesAtSomePoint.boolValue)
        [message setHasHadInstancesAtSomePoint:@YES];

    return newInstance;
}

+ (EmailMessageInstance*)findOrMakeNewInstanceForMessage:(EmailMessage*)message inFolder:(IMAPFolderSetting*)localFolderSetting withUID:(NSNumber*)UID inContext:(NSManagedObjectContext*)localContext
{
    return [EmailMessageInstance findOrMakeNewInstanceForMessage:message inFolder:localFolderSetting withUID:UID inContext:localContext alreadyFoundOne:nil];
}


+ (EmailMessageInstance*)findOrMakeNewInstanceForMessage:(EmailMessage*)message inFolder:(IMAPFolderSetting*)localFolderSetting withUID:(NSNumber*)UID inContext:(NSManagedObjectContext*)localContext alreadyFoundOne:(BOOL*)foundOne
{
    [ThreadHelper ensureLocalThread:localContext];

//    if([localFolderSetting isKindOfClass:[GmailLabelSetting class]] && ![localFolderSetting isSpam] && ![localFolderSetting isBin])
//    {
//        NSLog(@"Trying to find message by UID in Gmail label %@", localFolderSetting.displayName);
//    }

    if(!localFolderSetting)
    {
        NSLog(@"Making a message with a nil folder setting!!");
        if(foundOne)
            *foundOne = NO;
        return nil;
    }

    if(!message)
    {
        NSLog(@"Cannot make instance for nil message!");
        if(foundOne)
            *foundOne = NO;
        return nil;
    }

    for(EmailMessageInstance* messageInstance in message.instances)
    {
        if([messageInstance.inFolder isEqual:localFolderSetting])
        {
            if(!messageInstance.uid)
                [messageInstance changeUID:UID];

            if([messageInstance.uid isEqual:UID])
            {
                if(foundOne)
                    *foundOne = YES;
                return messageInstance;
            }
        }

        //if a message was added locally and has not yet been assigned a UID we might as well take that instance
        //this might happen, for example, if a sent message is copied into the sent folder both locally and on the server
        //UPDATE: this doesn't work: the IMAP append operation may already be in progress and we'd rather have a message twice than mess up the local store through concurrent operations on the same instance
        //        if([messageInstance.addedToFolder isEqual:localFolderSetting])
        //        {
        //            if(!messageInstance.uid)
        //                return messageInstance;
        //        }
    }

    //no instance in this folder, create a new one!

    if(foundOne)
        *foundOne = NO;

    NSEntityDescription* description = [NSEntityDescription entityForName:@"EmailMessageInstance" inManagedObjectContext:localContext];

    EmailMessageInstance* newInstance = [[EmailMessageInstance alloc] initWithEntity:description insertIntoManagedObjectContext:localContext];

    [newInstance setInFolder:localFolderSetting];
    [newInstance setMessage:message];
    [newInstance changeUID:UID];

    if(!message.hasHadInstancesAtSomePoint.boolValue)
        [message setHasHadInstancesAtSomePoint:@YES];

    return newInstance;
}

+ (EmailMessageInstance*)findExistingInstanceWithMessageID:(NSString *)messageID inAccount:(IMAPAccountSetting*)accountSetting inContext:(NSManagedObjectContext *)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    if(messageID)
    {
        EmailMessage* message = [EmailMessage findMessageWithMessageID:messageID inContext:localContext];

        for(EmailMessageInstance* messageInstance in message.instances)
        {
            if([messageInstance.accountSetting isEqual:accountSetting])
            {
                return  messageInstance;
            }
        }
    }
    return nil;
}

#pragma mark - MESSAGE INSTANCE QUERIES

+ (BOOL)haveInstanceWithUid:(NSNumber*)UID inFolder:(IMAPFolderSetting*)localFolderSetting UIDCollection:(NSIndexSet*)UIDCollection
{
    if(UIDCollection)
    {
        return [UIDCollection containsIndex:UID.integerValue];
    }

    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"EmailMessageInstance"];

    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"uid == %@", UID];

    [request setPredicate:predicate];

    NSInteger resultCount = [localFolderSetting.managedObjectContext countForFetchRequest:request error:nil];

    if(resultCount>0)
    {
        if(resultCount>1)
            NSLog(@"More than one message with uid %@ in folder %@", UID, localFolderSetting.displayName);

        return resultCount>0;
    }

    return NO;
}

+ (BOOL)haveRemovedInstanceWithMessageID:(NSString*)messageID andUid:(NSNumber*)UID inFolder:(IMAPFolderSetting*)localFolderSetting inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    for(EmailMessageInstance* deletedInstance in localFolderSetting.deletedMessages)
    {
        BOOL UIDCorrect = (UID==nil || [UID isEqual:deletedInstance.uid]);
        BOOL messageIDCorrect = (messageID==nil || [messageID isEqualToString:deletedInstance.message.messageid]);

        if(UIDCorrect && messageIDCorrect)
            return YES;
    }

    for(EmailMessageInstance* movedInstance in localFolderSetting.movedAwayMessages)
    {
        BOOL UIDCorrect = (UID==nil || [UID isEqual:movedInstance.uid]);
        BOOL messageIDCorrect = (messageID==nil || [messageID isEqualToString:movedInstance.message.messageid]);

        if(UIDCorrect && messageIDCorrect)
            return YES;
    }

    return NO;
}




#pragma mark - PROPERTIES

- (IMAPFolderSetting*)folderSetting
{
    if(self.inFolder)
        return self.inFolder;

    if(self.movedAwayFromFolder)
        return self.movedAwayFromFolder;

    if(self.deletedFromFolder)
        return self.deletedFromFolder;

    return nil;
}


/*thread safe*/
- (IMAPAccount*)account
{
    NSManagedObjectID* accountSettingID = [self accountSettingObjectID];

    for(IMAPAccount* account in [AccountCreationManager sharedInstance].allAccounts)
    {
        if([account.accountSettingID isEqual:accountSettingID])
            return account;
    }

    return nil;
}


- (IMAPAccountSetting*)accountSetting
{
    IMAPAccountSetting* accountSetting = self.folderSetting.inIMAPAccount;
    if(accountSetting)
        return accountSetting;

    //might be in the outbox, which has no inIMAPAccount connection
    if([self isInOutboxFolder])
    {
        accountSetting = self.folderSetting.outboxForAccount;
        if(accountSetting)
            return accountSetting;
    }

    return nil;
}

- (NSManagedObjectID*)accountSettingObjectID
{
    NSManagedObjectID* accountSettingID = [[self accountSetting] objectID];
    if(accountSettingID)
        return accountSettingID;

    return nil;
}


- (BOOL)isInSpamFolder
{
    return [self.inFolder isSpam];
}

- (BOOL)isInBinFolder
{
    return [self.inFolder isBin];
}

- (BOOL)isInDraftsFolder
{
    if([self.inFolder isKindOfClass:[GmailLabelSetting class]])
        return self.isInAllMailFolder && [self.hasLabels containsObject:self.accountSetting.draftsFolder];
    else
        return [self.inFolder isDrafts];
}

- (BOOL)isInSentFolder
{
    if([self.inFolder isKindOfClass:[GmailLabelSetting class]])
        return self.isInAllMailFolder && [self.hasLabels containsObject:self.accountSetting.sentFolder];
    else
        return [self.inFolder isSent];
}


- (BOOL)isInOutboxFolder
{
    return [self.inFolder isOutbox];
}


- (BOOL)isInAllMailFolder
{
    return [self.inFolder isAllMail];
}


- (BOOL)isInInboxFolder
{
    if([self.inFolder isKindOfClass:[GmailLabelSetting class]])
        return self.isInAllMailFolder && [self.hasLabels containsObject:self.accountSetting.inboxFolder];
    else
        return [self.inFolder isInbox];
}



//marks a message as unread
- (void)markUnread
{
    [self setUnreadInFolder:self.inFolder];

    NSUInteger flags = self.flags.unsignedIntegerValue;
    flags &= ~MCOMessageFlagSeen;
    [self setFlags:[NSNumber numberWithUnsignedInteger:flags]];
    IMAPAccountSetting* accountSetting = self.inFolder.inIMAPAccount;
    if(accountSetting)
    {
        [self setFlagsChangedInFolder:self.inFolder];
        //   [APPDELEGATE refreshFolderUnreadCount:accountSetting.objectID];
    }
    if([accountSetting isKindOfClass:[GmailAccountSetting class]])
    {
        [self addUnreadWithLabels:self.hasLabels];
        //    for(GmailLabelSetting* label in message.hasLabels)
        {
            //        [APPDELEGATE refreshFolderUnreadCount:label.objectID];
        }
    }
    //[APPDELEGATE refreshUnreadCount];
    //[APPDELEGATE refreshFolderUnreadCount:message.inFolder.objectID];

#if TARGET_OS_IPHONE

#else

    [MAIN_CONTEXT performBlock:^{

        if(APPDELEGATE.showUnreadButton.state==NSOnState) //unread messages are filtered out, so update the entire list...
            [SelectionAndFilterHelper refreshAllMessages];

    }];

#endif

}

//marks a message as read
- (void)markRead
{
    if(![self isUnread])
        return;

#if TARGET_OS_IPHONE

#else

    [MAIN_CONTEXT performBlockAndWait:^{

        //if unread messages are filtered out this message need to be added to the list of temporary exceptions, so that it does not disappear immediately
        if(APPDELEGATE.showUnreadButton.state==NSOnState)
        {
            if(![SelectionAndFilterHelper sharedInstance].temporarilyListedMessages)
                [[SelectionAndFilterHelper sharedInstance] setTemporarilyListedMessages:[NSMutableArray new]];
            [[SelectionAndFilterHelper sharedInstance].temporarilyListedMessages addObject:self];
        }

    }];

#endif

    [self setUnreadInFolder:nil];

    NSUInteger flags = self.flags.unsignedIntegerValue;
    flags |= MCOMessageFlagSeen;
    [self setFlags:[NSNumber numberWithUnsignedInteger:flags]];

    IMAPAccountSetting* accountSetting = self.accountSetting;
    if(accountSetting)
    {
        [self setFlagsChangedInFolder:self.folderSetting];
        //    [APPDELEGATE refreshFolderUnreadCount:accountSetting.objectID];
    }
    if([accountSetting isKindOfClass:[GmailAccountSetting class]])
    {
        [self removeUnreadWithLabels:self.unreadWithLabels];
        //     for(GmailLabelSetting* label in message.hasLabels)
        {
            //         [APPDELEGATE refreshFolderUnreadCount:label.objectID];
        }
    }
    //[APPDELEGATE refreshUnreadCount];
    // [APPDELEGATE refreshFolderUnreadCount:message.inFolder.objectID];
#if TARGET_OS_IPHONE
#else

    [MAIN_CONTEXT performBlock:^{

        if(APPDELEGATE.showUnreadButton.state==NSOnState) //unread messages are filtered out, so update the entire list...
            [SelectionAndFilterHelper refreshAllMessages];

    }];

#endif
}

//marks a message as unread
- (BOOL)isUnread
{
    return [self unreadInFolder]!=nil;
}

//returns whether a message is important - currently unused
- (BOOL)isImportant
{
    if([self.inFolder.inIMAPAccount isKindOfClass:[GmailAccountSetting class]])
    {
        return [[self.hasLabels valueForKey:@"labelName"] containsObject:@"\\Important"];
    }
    else
        return self.important.boolValue;
}

//marks a message as important
- (void)markImportant
{
    IMAPAccountSetting* accountSetting = self.inFolder.inIMAPAccount;
    if([self.inFolder.inIMAPAccount isKindOfClass:[GmailAccountSetting class]])
    {
        NSArray* labels = [accountSetting.folders sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"path" ascending:YES]]];
        NSInteger index = [[labels valueForKey:@"labelName"] indexOfObject:@"\\Important"];
        if(index!=NSNotFound)
        {
            GmailLabelSetting* importantLabel = [labels objectAtIndex:index];
            [self addHasLabelsObject:importantLabel];
            [self setLabelsChangedInFolder:(GmailLabelSetting*)self.inFolder];
            //[APPDELEGATE refreshMessage:message];
        }
    }
    else
    {
        [self setImportant:[NSNumber numberWithBool:YES]];
        //[APPDELEGATE refreshMessage:message];
    }
}

//marks a message as unimportant
//- (void)markUnimportant
//{
//    IMAPAccountSetting* accountSetting = self.accountSetting;
//    if([accountSetting isKindOfClass:[GmailAccountSetting class]])
//    {
//        NSArray* labels = [accountSetting.folders sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"path" ascending:YES]]];
//        GmailLabelSetting* importantLabel = [(GmailAccountSetting*)];
//        if(index!=NSNotFound)
//        {
//            [self removeHasLabelsObject:importantLabel];
//            [self setLabelsChangedInFolder:(GmailLabelSetting*)self.inFolder];
//            //[APPDELEGATE refreshMessage:message];
//        }
//    }
//    else
//    {
//        [self setImportant:[NSNumber numberWithBool:NO]];
//        //[APPDELEGATE refreshMessage:message];
//    }
//}

//marks a message as unflagged
- (void)markUnflagged
{
    [ThreadHelper ensureMainThread];

#if TARGET_OS_IPHONE

#else

    //if flagged messages are filtered out this message need to be added to the list of temporary exceptions, so that it does not disappear immediately
    if(APPDELEGATE.showFlaggedButton.state==NSOnState)
    {
        if(![SelectionAndFilterHelper sharedInstance].temporarilyListedMessages)
            [[SelectionAndFilterHelper sharedInstance] setTemporarilyListedMessages:[NSMutableArray new]];
        [[SelectionAndFilterHelper sharedInstance].temporarilyListedMessages addObject:self];
    }

#endif

    NSUInteger flags = self.flags.unsignedIntegerValue;
    flags &= ~MCOMessageFlagFlagged;
    [self setFlags:[NSNumber numberWithUnsignedInteger:flags]];
    IMAPAccountSetting* accountSetting = self.inFolder.inIMAPAccount;
    if(accountSetting)
        [self setFlagsChangedInFolder:self.inFolder];
    //[APPDELEGATE refreshFolderUnreadCount:message.inFolder.objectID];
#if TARGET_OS_IPHONE
#else
    if(APPDELEGATE.showFlaggedButton.state==NSOnState) //flagged messages are filtered out, so update the entire list...
        [SelectionAndFilterHelper refreshAllMessages];
#endif
}


- (void)markFlagged
{
    [ThreadHelper ensureMainThread];

    NSUInteger flags = self.flags.unsignedIntegerValue;
    flags |= MCOMessageFlagFlagged;
    [self setFlags:[NSNumber numberWithUnsignedInteger:flags]];

    IMAPAccountSetting* accountSetting = self.inFolder.inIMAPAccount;
    if(accountSetting)
        [self setFlagsChangedInFolder:self.inFolder];

#if TARGET_OS_IPHONE
#else
    if(APPDELEGATE.showFlaggedButton.state==NSOnState) //flagged messages are filtered out, so update the entire list...
        [SelectionAndFilterHelper refreshAllMessages];
#endif
}


//returns whether a message is flagged
- (BOOL)isFlagged
{
    if(self.flags.unsignedIntValue & MCOMessageFlagFlagged)
    {
        return YES;
    }
    return NO;
}

- (BOOL)recipientListIsSafe
{
    NSArray* emailRecipients = [AddressDataHelper emailRecipientsForAddressData:self.message.messageData.addressData];

    return [Recipient recipientListIsSafe:emailRecipients];
}

- (BOOL)isSafe
{
    return [self.message isKindOfClass:[MynigmaMessage class]];
}

- (BOOL)isOnServer
{
    return self.uid!=nil;
}

- (BOOL)isRemovedLocally
{
    return self.movedAwayFromFolder!=nil || self.deletedFromFolder!=nil;
}



- (BOOL)isSourceOfMove
{
    //
    // nil <--movedFromInstance-- SOURCE <--movedFromInstance-- NOT SOURCE <--movedFromInstance-- DESTINATION
    //      --movedToInstance-->    |     --movedToInstance-->      |       --movedToInstance-->       |
    //                              |                               |                                  |
    //                      movedAwayFromFolder             movedAwayFromFolder                     inFolder
    //                              |                               |                                  |
    //                              V                               V                                  V
    //                        "sourceFolder"                "someOtherFolder"                 "destinationFolder"
    //

    if(self.movedAwayFromFolder)
    {
        //this instance has clearly been moved, but there are a few more things to check:
        //need to make sure that it isn't an already moved message that was subsequently moved away a second time
        if(!self.movedFromInstance)
        {
            //a moved away message instance needs a UID for the copy message operation to succeed
            if(self.uid)
            {
                if(self.movedToInstance)
                {
                    return YES;
                }
                else
                    NSLog(@"Moved away message instance has no movedToInstance relationship!!");
            }
            else
            {
                if(self.addedToFolder)
                {
                    //the message has been added to the folder locally and not yet synchronised with the server, so it's OK that it doesn't have a UID
                    return NO;
                }

                NSLog(@"Moved away message instance has no UID!! Instances:");

                //if(VERBOSE)
                {
                    NSLog(@"Subject: %@ (%@)", self.message.messageData.subject, self.message.dateSent);
                    [self.message outputInstancesInfoToConsole];
                }
            }
        }
    }

    return NO;
}


- (EmailMessageInstance*)moveDestination
{
    EmailMessageInstance* destinationInstance = self;

    while(destinationInstance.movedToInstance)
    {
        destinationInstance = destinationInstance.movedToInstance;
    }

    return destinationInstance;
}


+ (EmailMessageInstance*)messageInstanceWithObjectID:(NSManagedObjectID*)messageInstanceObjectID inContext:(NSManagedObjectContext*)localContext
{
    //[ThreadHelper ensureLocalThread:localContext];

    if(!messageInstanceObjectID)
    {
        NSLog(@"Trying to create EmailMessageInstance with nil object ID!!");
        return nil;
    }

    NSError* error = nil;
    EmailMessageInstance* messageInstance = (EmailMessageInstance*)[localContext existingObjectWithID:messageInstanceObjectID error:&error];
    if(error)
    {
        NSLog(@"Error creating message instance!!! %@", error.localizedDescription);
        return nil;
    }

    return messageInstance;
}

- (void)changeUID:(NSNumber*)newUID
{
    if(self.uid && self.folderSetting)
        [UIDHelper removeUID:self.uid.integerValue fromFolder:self.folderSetting];

    [self setUid:newUID];

    if(newUID && self.folderSetting)
        [UIDHelper addUID:newUID.integerValue toFolder:self.folderSetting];
}


#pragma mark - Saving

//+ (EmailMessageInstance*)saveFreshDraftInstanceFromAccountSetting:(IMAPAccountSetting*)accountSetting recipients:(NSArray*)recipients subject:(NSString*)subject body:(NSString*)body HTMLBody:(NSString*)HTMLBody asSafe:(BOOL)shouldBeSafe forSending:(BOOL)isForSending
//{
//
//}
//
//- (EmailMessageInstance*)saveAsDraft
//{
//
//}
//
//- (void)saveMessageByOverwritingPreviousCopy:(BOOL)overwrite properDelete:(BOOL)properDelete asSafe:(BOOL)shouldBeSafe forSending:(BOOL)isForSending withCallback:(void(^)(BOOL success))callback
//{
//    [ThreadHelper ensureMainThread];
//
//    //    EmailMessageInstance* messageInstance = self.composedMessageInstance;
//    //
//    //    if(!messageInstance)
//    //    {
//    //        Recipient* fromRecipient = nil;
//    //        if(self.fromField.recipients.count>0)
//    //        {
//    //            fromRecipient = self.fromField.recipients[0];
//    //        }
//    //        else
//    //            fromRecipient = [AddressDataHelper standardSenderAsRecipient];
//    //
//    //        messageInstance = [FormattingHelper freshComposedMessageInstanceWithSenderRecipient:fromRecipient];
//    //    }
//
//    Recipient* fromRecipient = nil;
//
//    if(self.fromField.recipients.count>0)
//    {
//        fromRecipient = self.fromField.recipients[0];
//    }
//    else
//        fromRecipient = [AddressDataHelper standardSenderAsRecipient];
//
//    IMAPAccountSetting* fromAccountSetting = [IMAPAccountSetting accountSettingForSenderEmail:fromRecipient.displayEmail];
//
//
//    IMAPFolderSetting* draftsFolder = nil;
//
//    if(fromAccountSetting)
//    {
//        draftsFolder = fromAccountSetting.draftsFolder;
//    }
//
//    if(!draftsFolder)
//    {
//        if(APPDELEGATE.topSelection)
//            draftsFolder = APPDELEGATE.topSelection.accountSetting.draftsFolder;
//    }
//
//    if(!draftsFolder)
//        draftsFolder = MODEL.currentUserSettings.preferredAccount.draftsFolder;
//
//    if(!draftsFolder)
//    {
//        NSLog(@"Cannot compose message: no drafts folder!!");
//        //return;
//    }
//
//
//    EmailMessage* newMessage = [EmailMessage newDraftMessageInContext:MAIN_CONTEXT];
//
//    if(!shouldBeSafe)
//        newMessage = [(MynigmaMessage*)newMessage turnIntoOpenMessageInContext:MAIN_CONTEXT];
//
//    EmailMessageInstance* newInstance = [EmailMessageInstance findOrMakeNewInstanceForMessage:newMessage inFolder:draftsFolder inContext:MAIN_CONTEXT];
//
//    //[newInstance markUnread];
//
//    [newMessage setDateSent:[NSDate date]];
//
//    [newInstance setFlags:[NSNumber numberWithInt:MCOMessageFlagDraft|MCOMessageFlagSeen]];
//    [newInstance setAddedToFolder:newInstance.inFolder];
//
//    [newInstance changeUID:nil];
//
//    EmailMessageInstance* oldInstance = self.composedMessageInstance;
//
//    [self setComposedMessageInstance:newInstance];
//
//
//    NSArray* recipients = [self recipients];
//
//    //set the searchString so that the message can be found by search
//    NSMutableString* newSearchString = [[NSMutableString alloc] initWithString:@""];
//
//    for(Recipient* rec in recipients)
//    {
//        if([rec isKindOfClass:[Recipient class]])
//        {
//            if(rec.displayEmail)
//                [newSearchString appendFormat:@"%@,",[rec.displayEmail lowercaseString]];
//            if(rec.displayName)
//                [newSearchString appendFormat:@"%@,",[rec.displayName lowercaseString]];
//        }
//
//        if(rec.type==TYPE_FROM)
//            [newMessage.messageData setFromName:rec.displayName?rec.displayName:@""];
//    }
//
//    [newMessage setSearchString:newSearchString];
//
//    [newMessage.messageData setAddressData:[AddressDataHelper addressDataForRecipients:recipients]];
//
//    [newMessage.messageData setLoadRemoteImages:[NSNumber numberWithBool:YES]];
//
//    [newMessage.messageData setSubject:self.subjectField.stringValue];
//
//    [newMessage.messageData setBody:[(DOMHTMLElement *)[[[self.bodyField mainFrame] DOMDocument] documentElement] outerText]];
//
//    [newMessage.messageData setHtmlBody:[(DOMHTMLElement *)[[[self.bodyField mainFrame] DOMDocument] documentElement] outerHTML]];
//
//    NSArray* allAttachments = [self.attachmentsView allAttachments];
//
//    //[[NSSet setWithArray:self.attachmentsArrayController.arrangedObjects] valueForKey:@"fileAttachment"];
//
//    for(FileAttachment* fileAttachment in allAttachments)
//    {
//        FileAttachment* freshAttachment = fileAttachment;
//
//        if(fileAttachment.attachedAllToMessage || fileAttachment.inlineImageForFooter)
//        {
//            //the attachment is already attached to a message
//            //shouldn't be hugely surprising, nor a major problem...
//            //NSLog(@"Attachment is already assigned to a different message!! Fixing by creating a copy...");
//
//            freshAttachment = [fileAttachment copyInContext:MAIN_CONTEXT];
//        }
//
//        [newMessage addAllAttachmentsObject:freshAttachment];
//
//        //make it explicit just if it's not inline
//        if(fileAttachment.inlineImageForFooter)
//        {
//            //it's inline
//            //assume all other attachments are explicit
//        }
//        else
//        {
//            [newMessage addAttachmentsObject:freshAttachment];
//        }
//
//        if(!freshAttachment.contentType)
//            [freshAttachment setContentType:@"application/octet-stream"];
//    }
//
//    if(overwrite)
//    {
//        if(properDelete)
//            [oldInstance deleteInstanceInContext:oldInstance.managedObjectContext];
//        else
//            [oldInstance moveToBinOrDelete];
//    }
//
//    [MODEL save];
//
//    //BOOL usesMynigma = [self willBeSentAsSafe];   //TO DO: ensure messages whose recipients include both safe and unsafe recipients are encrypted for safe recipients!
//
//    if(shouldBeSafe)
//    {
//        if(![self.composedMessageInstance.message isKindOfClass:[MynigmaMessage class]])
//        {
//            self.composedMessageInstance.message = [self.composedMessageInstance.message turnIntoSafeMessageInContext:MAIN_CONTEXT];
//        }
//        if(isForSending)
//        {
//
//            [(MynigmaMessage*)self.composedMessageInstance.message encryptForSendingWithCallback:^(BOOL success) {
//
//                [self setIsDirty:NO];
//
//                if(callback)
//                    callback(success);
//            }];
//
//        }
//        else
//        {
//            //need to encrypt as draft (may not have all the necessary key labels and/or attachments)
//            [(MynigmaMessage*)self.composedMessageInstance.message encryptAsDraftWithCallback:^(BOOL success) {
//
//                [self setIsDirty:NO];
//
//                if(callback)
//                    callback(success);
//            }];
//
//        }
//    }
//    else
//    {
//        [self setIsDirty:NO];
//        if(callback)
//            callback(YES);
//    }
//}
//
//
//- (void)saveMessageByUsingExistingDraft:(EmailMessage*)message andOverwritingPreviousCopy:(BOOL)overwrite properDelete:(BOOL)properDelete asSafe:(BOOL)shouldBeSafe forSending:(BOOL)isForSending withCallback:(void(^)(BOOL success))callback
//{
//    [ThreadHelper ensureMainThread];
//
//    Recipient* fromRecipient = nil;
//
//    fromRecipient = [[AddressDataHelper senderAsEmailRecipientForMessage:message] recipient];
//    //this was already loaded
//    if(self.fromField.recipients.count>0)
//    {
//        fromRecipient = self.fromField.recipients[0];
//    }
//    else
//        fromRecipient = [AddressDataHelper standardSenderAsRecipient];
//
//    IMAPAccountSetting* fromAccountSetting = [IMAPAccountSetting accountSettingForSenderEmail:fromRecipient.displayEmail];
//
//
//    IMAPFolderSetting* draftsFolder = nil;
//
//    if(fromAccountSetting)
//    {
//        draftsFolder = fromAccountSetting.draftsFolder;
//    }
//
//    if(!draftsFolder)
//    {
//        if(APPDELEGATE.topSelection)
//            draftsFolder = APPDELEGATE.topSelection.accountSetting.draftsFolder;
//    }
//
//    if(!draftsFolder)
//        draftsFolder = MODEL.currentUserSettings.preferredAccount.draftsFolder;
//
//    if(!draftsFolder)
//    {
//        NSLog(@"Cannot compose message: no drafts folder!!");
//        //return;
//    }
//
//
//    EmailMessage* newMessage = [EmailMessage newDraftMessageInContext:MAIN_CONTEXT];
//
//    if(!shouldBeSafe)
//        newMessage = [(MynigmaMessage*)newMessage turnIntoOpenMessageInContext:MAIN_CONTEXT];
//
//    EmailMessageInstance* newInstance = [EmailMessageInstance findOrMakeNewInstanceForMessage:newMessage inFolder:draftsFolder inContext:MAIN_CONTEXT];
//
//    //[newInstance markUnread];
//
//    [newMessage setDateSent:[NSDate date]];
//
//    [newInstance setFlags:[NSNumber numberWithInt:MCOMessageFlagDraft|MCOMessageFlagSeen]];
//    [newInstance setAddedToFolder:newInstance.inFolder];
//
//    [newInstance changeUID:nil];
//
//    EmailMessageInstance* oldInstance = self.composedMessageInstance;
//
//    [self setComposedMessageInstance:newInstance];
//
//    [newMessage.messageData setFromName:message.messageData.fromName];
//
//    [newMessage setSearchString:message.searchString];
//
//    [newMessage.messageData setAddressData:message.messageData.addressData];
//
//    [newMessage.messageData setLoadRemoteImages:message.messageData.loadRemoteImages];
//
//    [newMessage.messageData setSubject:message.messageData.subject];
//
//    [newMessage.messageData setBody:message.messageData.body];
//
//    [newMessage.messageData setHtmlBody:message.messageData.htmlBody];
//
//    NSArray* allAttachments = [self.attachmentsView allAttachments];
//
//    //[[NSSet setWzzzithArray:self.attachmentsArrayController.arrangedObjects] valueForKey:@"fileAttachment"];
//
//    for(FileAttachment* fileAttachment in allAttachments)
//    {
//        FileAttachment* freshAttachment = fileAttachment;
//
//        if(fileAttachment.attachedAllToMessage || fileAttachment.inlineImageForFooter)
//        {
//            //the attachment is already attached to a message
//            //shouldn't be hugely surprising, nor a major problem...
//            //NSLog(@"Attachment is already assigned to a different message!! Fixing by creating a copy...");
//
//            freshAttachment = [fileAttachment copyInContext:MAIN_CONTEXT];
//        }
//
//        [newMessage addAllAttachmentsObject:freshAttachment];
//
//        //make it explicit just if it's not inline
//        if(fileAttachment.inlineImageForFooter)
//        {
//            //it's inline
//            //assume all other attachments are explicit
//        }
//        else
//        {
//            [newMessage addAttachmentsObject:freshAttachment];
//        }
//
//        if(!freshAttachment.contentType)
//            [freshAttachment setContentType:@"application/octet-stream"];
//    }
//
//    if(overwrite)
//    {
//        if(properDelete)
//            [oldInstance deleteInstanceInContext:oldInstance.managedObjectContext];
//        else
//            [oldInstance moveToBinOrDelete];
//    }
//
//    [MODEL save];
//
//    //BOOL usesMynigma = [self willBeSentAsSafe];   //TO DO: ensure messages whose recipients include both safe and unsafe recipients are encrypted for safe recipients!
//
//    if(shouldBeSafe)
//    {
//        if(![self.composedMessageInstance.message isKindOfClass:[MynigmaMessage class]])
//        {
//            self.composedMessageInstance.message = [self.composedMessageInstance.message turnIntoSafeMessageInContext:MAIN_CONTEXT];
//        }
//        if(isForSending)
//        {
//
//            [(MynigmaMessage*)self.composedMessageInstance.message encryptForSendingWithCallback:^(BOOL success) {
//
//                [self setIsDirty:NO];
//
//                if(callback)
//                    callback(success);
//            }];
//
//        }
//        else
//        {
//            //need to encrypt as draft (may not have all the necessary key labels and/or attachments)
//            [(MynigmaMessage*)self.composedMessageInstance.message encryptAsDraftWithCallback:^(BOOL success) {
//
//                [self setIsDirty:NO];
//
//                if(callback)
//                    callback(success);
//            }];
//
//        }
//    }
//    else
//    {
//        [self setIsDirty:NO];
//        if(callback)
//            callback(YES);
//    }
//}





#pragma mark - DOWNLOADING

- (void)fetchMessageBodyUsingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation urgent:(BOOL)urgent withCallback:(void(^)(NSError* error, NSString* htmlString))callback
{
    /*
     if(message.messageData.mainPartID && message.messageData.mainPartEncoding)
     {
     [session fetchMessageAttachmentByUIDWithFolder:message.inFolder.path uid:message.uid.intValue partID:message.messageData.mainPartID encoding:message.messageData.mainPartEncoding withProgressBlock:nil urgent:urgent withCallback:^(NSError *error, NSData *partData) {
     if(error)
     callback(error, nil);
     else
     {
     //MCOMessageParser* parser = [[MCOMessageParser alloc] initWithData:partData];
     //NSString* resultString = [parser htmlBodyRendering];//htmlRenderingWithDelegate:[MCODelegate sharedInstance]];
     NSData* entitisedData = [IMAPAccount convertToASCIIDumbLossless:partData];
     NSString* resultString = [[NSString alloc] initWithData:entitisedData encoding:NSASCIIStringEncoding];
     callback(error, resultString);
     }
     }];
     }
     else*/
    {
        IMAPFolderSetting* inFolder = self.folderSetting;

        if (urgent)
            session = self.account.quickAccessSession;

        NSString* mainPartID = [self.message.messageData mainPartID];
        NSNumber* mainPartEncoding = [self.message.messageData mainPartEncoding];
        __block NSString* mainPartType = [self.message.messageData mainPartType];
        
        if(inFolder && session)
        {
            if (mainPartID && mainPartEncoding && mainPartType)
            {
                // this is a minor hack, the correct operation would be htmlBodyRenderingOperationWithMessage:folder:
                FetchContentOperation* fetchContentOperation = [FetchContentOperation fetchMessageContentByUIDWithFolder:inFolder.path uid:self.uid.integerValue partID:mainPartID encoding:mainPartEncoding.integerValue urgent:urgent session:session withCallback:^(NSError *error, NSData *data){
                    
                    if(error)
                        callback(error, nil);
                    else
                    {
                        MCOMessageParser* messageParser = [[MCOMessageParser alloc] initWithData:data];

                         messageParser.mainPart.mimeType = mainPartType;
                        
                        NSString* htmlString = [messageParser htmlRenderingWithDelegate:[MCODelegate sharedInstance]];
                        
                        callback(error, htmlString);
                    }
                }];
                
                if(urgent)
                    [fetchContentOperation setHighPriority];
                else
                    [fetchContentOperation setLowPriority];
                
                if(urgent)
                    [fetchContentOperation addToUserActionQueue];
                else
                {
                    if(![fetchContentOperation addToMailCoreQueueWithDisconnectOperation:disconnectOperation])
                        callback(nil, nil);
                }

            }
            else
            {
                // have no main part -> fetch the complete message
                //NSLog(@"Downloading the complete message due to missing mainPartID");
                FetchMessageOperation* fetchMessageOperation = [FetchMessageOperation fetchMessageByUIDWithFolder:inFolder.path uid:self.uid.integerValue urgent:urgent session:session withCallback:^(NSError *error, NSData *data){
                if(error)
                    callback(error, nil);
                else
                {
                    MCOMessageParser* messageParser = [[MCOMessageParser alloc] initWithData:data];
                    NSString* htmlString = [messageParser htmlRenderingWithDelegate:[MCODelegate sharedInstance]];
                    callback(error, htmlString);
                }
            }];

                if(urgent)
                    [fetchMessageOperation setHighPriority];
                else
                    [fetchMessageOperation setLowPriority];

                if(urgent)
                    [fetchMessageOperation addToUserActionQueue];
                else
                {
                    if(![fetchMessageOperation addToMailCoreQueueWithDisconnectOperation:disconnectOperation])
                    callback(nil, nil);
                }
            }
        }
        else
            callback(nil, nil);
    }
}

/**Downloads this message instance and decrypts it, if applicable (to be called only by the EmailMessage object in order to prevent donwloading the body of safe or device messages)*/
- (void)downloadUsingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation urgent:(BOOL)urgent alsoDownloadAttachments:(BOOL)withAttachments
{
    [ThreadHelper ensureMainThread];

    if([self.message isDownloaded] && ![self.message isSafe])
        return;

    if(![self.message isDownloaded] && !self.uid)
    {
        //cannot download a message instance without a UID
        //this method should never be called on such an instance in the first place
        //report an error
        NSLog(@"Error: trying to download unsuitable instance: %@, message: %@", self, self.message);

        return;
    }

    //normal EmailMessage, so just need to fetch body...
    [self.message setIsDownloading:YES];

    if(!session)
    {
        session = self.account.quickAccessSession;
        disconnectOperation = nil;
    }
    
    [self fetchMessageBodyUsingSession:session disconnectOperation:disconnectOperation urgent:urgent withCallback:^(NSError *error, NSString* dirtyString)
     {
         [ThreadHelper runAsyncOnMain:^{
             
             [self.message setIsDownloading:NO];
             
             //set an empty body to ensure that MODEL returns yes to subsequent calls of isDownloaded: (ensuring that no more downloads are started, even if the html body has not yet been parsed)
             if(error)
             {
                 NSLog(@"Failed to download single body: %@ (folder: %@)", error.localizedDescription, self.folderSetting.path);
                 
                 NSLog(@"Error downloading message!");
                 [SelectionAndFilterHelper refreshMessage:self.message.objectID];
                 
                 return;
             }
             
             [self.message setIsCleaning:YES];
             
             //parse the downloaded message and fill the EmailMessage object with the parsed data
             
             //parsed string belongs into the message body
             [HTMLPurifier cleanHTML:dirtyString withCallBack:^(NSString *cleanedBody, NSError *error) {
                 
                 [self.message.messageData setHtmlBody:cleanedBody?cleanedBody:@""];
                 
                 [self.message setIsCleaning:NO];
                 
                 NSString* body = @""; //this crashes due to an error in MailCore, presumably: [messageParser plainTextBodyRendering];
                 [self.message.messageData setBody:body];
                 
                 [SelectionAndFilterHelper refreshMessage:self.message.objectID];
             }];
         }];
     }];
    
    if(withAttachments)
    {
        for(FileAttachment* attachment in self.message.allAttachments)
        {
            [attachment downloadUsingSession:session disconnectOperation:disconnectOperation withCallback:^(NSData *data) {
                //[APPDELEGATE refreshViewerShowingMessage:message];
            }];
        }
    }
}


#pragma mark - Deletion

- (void)removeFromStoreInContext:(NSManagedObjectContext*)localContext
{
    if(self.uid.integerValue && self.folderSetting)
        [UIDHelper removeUID:self.uid.integerValue fromFolder:self.folderSetting];
    [localContext deleteObject:self];
}


@end
