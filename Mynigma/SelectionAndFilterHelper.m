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





#import "SelectionAndFilterHelper.h"
#import "OutlineObject.h"
#import "EmailMessageController.h"
#import "Contact+Category.h"
#import "EmailMessageInstance+Category.h"
#import "EmailMessage+Category.h"
#import "IMAPFolderSetting+Category.h"
#import "AppDelegate.h"
#import "UserNotificationHelper.h"
#import "AlertHelper.h"
#import "IMAPAccountSetting+Category.h"
#import "EmailMessageData.h"
#import "UIDHelper.h"


#if TARGET_OS_IPHONE

#import "FolderListController_iOS.h"
#import "ViewControllersManager.h"

static NSArray* _selectedMessages;

#else

#import "FolderListController_MacOS.h"
#import "WindowManager.h"
#import "MessageCellView.h"
#import "SeparateViewerWindowController.h"
#import "DisplayMessageView.h"

#endif



@implementation SelectionAndFilterHelper

+ (instancetype)sharedInstance
{
    static dispatch_once_t p = 0;

    __strong static id sharedObject = nil;

    dispatch_once(&p, ^{
        sharedObject = [self new];
    });

    return sharedObject;
}



#if TARGET_OS_IPHONE

+ (void)setSelectedMessages:(NSArray*)messages
{
    _selectedMessages = messages;
}

+ (NSArray*)selectedMessages
{
    return _selectedMessages;
}

#else

+ (NSArray*)selectedMessages
{
    return [EmailMessageController selectedMessages];
}


//returns the array of selected folders that the user has selected on the left
+ (NSSet*)selectedFoldersAndLabels
{
    if([SelectionAndFilterHelper sharedInstance].showContacts)
        return [[[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_FOLDERS] associatedFoldersForAccountSettings:[[[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_ACCOUNTS] accountSettings]];
    else
    {
        if(![SelectionAndFilterHelper sharedInstance].topSelection)
            [SelectionAndFilterHelper sharedInstance].topSelection = [[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_ACCOUNTS];
        if(![SelectionAndFilterHelper sharedInstance].bottomSelection)
            [SelectionAndFilterHelper sharedInstance].bottomSelection = [[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_FOLDERS];
        return [[SelectionAndFilterHelper sharedInstance].bottomSelection associatedFoldersForAccountSettings:[[SelectionAndFilterHelper sharedInstance].topSelection accountSettings]];
    }
}


+ (NSSet*)selectedEmailAddresses
{
    NSMutableSet* resultsSet = [NSMutableSet new];

    if([SelectionAndFilterHelper sharedInstance].showContacts)
    {
        if([[SelectionAndFilterHelper sharedInstance].bottomSelection isContact])
        {
            Contact* selectedContact = [SelectionAndFilterHelper sharedInstance].bottomSelection.contact;
            for(EmailContactDetail* emailDetail in selectedContact.emailAddresses)
                [resultsSet addObject:emailDetail];
        }
    }
    return resultsSet;
}

#endif


+ (void)updateFilters
{
    if(![SelectionAndFilterHelper sharedInstance].topSelection)
        [[SelectionAndFilterHelper sharedInstance] setTopSelection:[[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_ACCOUNTS]];

    if(![SelectionAndFilterHelper sharedInstance].bottomSelection)
        [[SelectionAndFilterHelper sharedInstance] setBottomSelection:[[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_FOLDERS]];

#if TARGET_OS_IPHONE

#else

    [SelectionAndFilterHelper sharedInstance].temporarilyListedMessages = [NSMutableArray new];

#endif

    [[EmailMessageController sharedInstance] updateFilters];
}




#pragma mark - Refreshing

#if TARGET_OS_IPHONE

+ (void)refreshUnreadCount
{
    [ThreadHelper ensureMainThread];

    OutlineObject* allAccounts = [[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_ACCOUNTS];

    NSInteger unreadCount = allAccounts.unreadCount;

    [UserNotificationHelper setUnreadBadgeTo:unreadCount];
}

#else

+ (void)refreshUnreadCountForFolderSetting:(IMAPFolderSetting*)folderSetting
{
    [ThreadHelper ensureMainThread];

    [[[WindowManager sharedInstance] foldersController] refreshTable];

    OutlineObject* allAccounts = [[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_ACCOUNTS];

    NSInteger unreadCount = allAccounts.unreadCount;
    [UserNotificationHelper setUnreadBadgeTo:unreadCount];
}

+ (void)refreshUnreadCount
{
    [ThreadHelper runAsyncOnMain:^{

        if(![SelectionAndFilterHelper sharedInstance].showContacts)
            [self reloadOutlinePreservingSelection];

        OutlineObject* allAccounts = [[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_ACCOUNTS];
        NSInteger unreadCount = allAccounts.unreadCount;
        [UserNotificationHelper setUnreadBadgeTo:unreadCount];
    }];
}

#endif

/**CALL ON MAIN*/
+ (void)highlightMessageInstance:(EmailMessageInstance*)messageInstance
{
    [ThreadHelper ensureMainThread];

#if TARGET_OS_IPHONE

    NSInteger index = [EmailMessageController indexForMessageObject:messageInstance];
    if(index!=NSNotFound && index>=0)
    {
        NSIndexPath* indexPath = [[NSIndexPath alloc] initWithIndex:index];
        [[EmailMessageController sharedInstance] updateFiltersReselectingIndexPath:indexPath];
    }
    else
        NSLog(@"Index of message to be highlighted could not be found: %@", messageInstance);


#else

    NSInteger index = [EmailMessageController indexForMessageObject:messageInstance];
    if(index!=NSNotFound && index>=0)
    {
        [APPDELEGATE.messagesTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
        [APPDELEGATE.messagesTable scrollRowToVisible:index];
    }
    else
        NSLog(@"Index of message to be highlighted could not be found: %@", messageInstance);

#endif

}

//when the user clicks on a user notification the respective message should be selected in the message list and displayed in the content viewer
/**CALL ON MAIN*/
+ (void)highlightMessageWithID:(NSString*)messageID
{
    [ThreadHelper ensureMainThread];

    //NSLog(@"Highlighting message with ID: %@", messageID);
    EmailMessage* message = [EmailMessage findMessageWithMessageID:messageID inContext:MAIN_CONTEXT];

    //first try all the instances corresponding to this message ID
    //take the first one that is actually being displayed to the user
    for(EmailMessageInstance* messageInstance in message.instances)
    {

#if TARGET_OS_IPHONE
        //NSLog(@"Trying message instance: %@", messageInstance);
        if([APPDELEGATE.displayedMessages containsObject:messageInstance])
#else
            if([EmailMessageController messageObjectIsToBeDisplayed:messageInstance])
#endif
            {
                //highlight it in .3 seconds to give the display a chance to actually show the message
                //NSLog(@"Highlighting message instance: %@", messageInstance);
                [self performSelector:@selector(highlightMessageInstance:) withObject:messageInstance afterDelay:.3];
                return;
            }

    }

    //none of the instances is currently to be displayed
    //need to change the filter criteria
    //NSLog(@"Need to change filter criteria: %@", searchResult);
    for(EmailMessageInstance* messageInstance in message.instances)
    {
        if(messageInstance.inFolder!=nil)
        {
            //at least one instance has been found - change the filter criteria to all accounts & the corresponding folder

#if TARGET_OS_IPHONE

#else

            [APPDELEGATE.showFlaggedButton setState:NSOffState];
            [APPDELEGATE.showAttachmentsButton setState:NSOffState];
            [APPDELEGATE.showSafeButton setState:NSOffState];
            [APPDELEGATE.showUnreadButton setState:NSOffState];

#endif

            if(![[SelectionAndFilterHelper sharedInstance].topSelection.accountSettings containsObject:messageInstance.inFolder.inIMAPAccount])
            {
                [SelectionAndFilterHelper sharedInstance].topSelection = [[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_ACCOUNTS];
            }
            if(![OutlineObject.selectedFolderSettingsForFiltering containsObject:messageInstance.inFolder])
            {
                //first try the "All folders" selection
                [SelectionAndFilterHelper sharedInstance].bottomSelection = [[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_FOLDERS];

                //if that doesn't work select the specific folder instead
                if(![OutlineObject.selectedFolderSettingsForFiltering containsObject:messageInstance.inFolder])
                    [SelectionAndFilterHelper sharedInstance].bottomSelection = [[OutlineObject alloc] initAsFolder:messageInstance.inFolder];
            }

            [[EmailMessageController sharedInstance] updateFilters];

            //highlight it in .8 seconds to give the display a chance to actually show the message
            [self performSelector:@selector(highlightMessageInstance:) withObject:messageInstance afterDelay:.8];

            return;
        }
    }
}


+ (void)refreshAttachment:(FileAttachment*)fileAttachment
{
#if TARGET_OS_IPHONE

    if([ViewControllersManager sharedInstance].attachmentsListController)
    {
        [[ViewControllersManager sharedInstance].attachmentsListController refreshAttachment:fileAttachment];
    }

#endif
}




//reloads the contact outline ensuring that the selection is preserved
+ (void)reloadOutlinePreservingSelection
{

    [ThreadHelper runAsyncOnMain:^{

#if TARGET_OS_IPHONE

        [[[ViewControllersManager sharedInstance] foldersController] refreshTable];

#else

        [[[WindowManager sharedInstance] foldersController] refreshTable];

#endif

    }];

}



+ (void)refreshAllMessages
{
    return;
}

+ (void)refreshMessageInstance:(NSManagedObjectID*)messageID
{

#if TARGET_OS_IPHONE
    
    [[[ViewControllersManager sharedInstance] messagesController] refreshMessageInstance:messageID];

#else

    //this method might be called from any thread, so ensure we're on the main thread...
    [ThreadHelper runAsyncOnMain:^{

        NSError* error = nil;
        EmailMessageInstance* messageInstance = (EmailMessageInstance*)[MAIN_CONTEXT existingObjectWithID:messageID error:&error];
        if(error || !messageInstance || [messageInstance isFault])
            return;

        //index of the message within the message list
        NSInteger index = [EmailMessageController indexForMessageObject:messageInstance];

        //need only do an update if the row is actually shown
        NSRange visibleRows = [APPDELEGATE.messagesTable rowsInRect:[APPDELEGATE.messagesTable visibleRect]];
        if(index>=visibleRows.location && index<visibleRows.location+visibleRows.length)
        {
            MessageCellView* messageView = [APPDELEGATE.messagesTable viewAtColumn:0 row:index makeIfNecessary:NO];
            if([messageView.messageInstance.objectID isEqual:messageID])
            {
                [APPDELEGATE.messagesTable reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:index] columnIndexes:[NSIndexSet indexSetWithIndex:0]];

                //if the message is shown the content viewer this needs to be reloaded as well
                if(index==APPDELEGATE.messagesTable.selectedRow)
                    [[WindowManager sharedInstance].displayView refresh];
            }
        }

        //        //now check the separate viewer windows
        //        for(SeparateViewerWindowController* windowController in composeWindowSet)
        //        {
        //            if([windowController isKindOfClass:[SeparateViewerWindowController class]])
        //            {
        //                if([windowController.shownMessageInstance isEqual:messageInstance])
        //                {
        //                    [windowController showMessageInstance:messageInstance];
        //                }
        //            }
        //        }
    }];

#endif

}

//call this method when properties of the message have changed, so that it can be reflected in the view
+ (void)refreshMessage:(NSManagedObjectID*)messageObjectID
{
#if TARGET_OS_IPHONE

    if(!messageObjectID)
        return;

    [[ViewControllersManager sharedInstance].messagesController refreshMessage:messageObjectID];

#else

    if(!messageObjectID)
        return;

    //this method might be called from any thread, so ensure we're on the main thread...
    [ThreadHelper runAsyncOnMain:^{

        NSError* error = nil;
        EmailMessage* message = (EmailMessage*)[MAIN_CONTEXT existingObjectWithID:messageObjectID error:&error];
        if(error || !message || [message isFault] || ![message isKindOfClass:[EmailMessage class]])
            return;

        for(EmailMessageInstance* messageInstance in message.instances)
        {

            //index of the message within the message list
            NSInteger index = [EmailMessageController indexForMessageObject:messageInstance];

            //need only do an update if the row is actually shown
            NSRange visibleRows = [APPDELEGATE.messagesTable rowsInRect:[APPDELEGATE.messagesTable visibleRect]];
            if(index>=visibleRows.location && index<visibleRows.location+visibleRows.length)
            {
                MessageCellView* messageView = [APPDELEGATE.messagesTable viewAtColumn:0 row:index makeIfNecessary:NO];
                if([messageView isKindOfClass:[MessageCellView class]])
                    if([messageView.messageInstance.message.objectID isEqual:messageObjectID])
                    {
                        [APPDELEGATE.messagesTable reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:index] columnIndexes:[NSIndexSet indexSetWithIndex:0]];

                        //if the message is shown in the content viewer this needs to be reloaded as well
                        if(index==APPDELEGATE.messagesTable.selectedRow)
                            [[WindowManager sharedInstance].displayView refresh];
                    }
            }

            //now check the separate viewer windows
            for(SeparateViewerWindowController* windowController in [WindowManager shownWindows])
            {
                if([windowController isKindOfClass:[SeparateViewerWindowController class]])
                {
                    if([windowController.shownMessageInstance isEqual:messageInstance])
                    {
                        [windowController showMessageInstance:messageInstance];
                    }
                }
            }
        }

        //might be dealing with an email message (in the local backup)

        //index of the message within the message list
        NSInteger index = [EmailMessageController indexForMessageObject:message];

        //need only do an update if the row is actually shown
        NSRange visibleRows = [APPDELEGATE.messagesTable rowsInRect:[APPDELEGATE.messagesTable visibleRect]];
        if(index>=visibleRows.location && index<visibleRows.location+visibleRows.length)
        {
            MessageCellView* messageView = [APPDELEGATE.messagesTable viewAtColumn:0 row:index makeIfNecessary:NO];
            if([messageView isKindOfClass:[MessageCellView class]])
                if([messageView.message.objectID isEqual:messageObjectID])
                {
                    [APPDELEGATE.messagesTable reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:index] columnIndexes:[NSIndexSet indexSetWithIndex:0]];

                    //if the message is shown in the content viewer this needs to be reloaded as well
                    if(index==APPDELEGATE.messagesTable.selectedRow)
                        [[WindowManager sharedInstance].displayView refresh];
                }
        }

    }];

#endif

}

+ (void)refreshViewerShowingMessageInstanceWithObjectID:(NSManagedObjectID*)messageInstanceObjectID
{
    [ThreadHelper runAsyncOnMain:^{

        NSError* error = nil;

        EmailMessageInstance* messageInstance = (EmailMessageInstance*)[MAIN_CONTEXT existingObjectWithID:messageInstanceObjectID error:&error];

        if(messageInstance && !error)
        {
            [self refreshViewerShowingMessageInstance:messageInstance];
        }
    }];
}


+ (void)refreshViewerShowingMessageInstance:(EmailMessageInstance*)messageInstance
{

#if TARGET_OS_IPHONE

    EmailMessageInstance* displayedMessageInstance = [ViewControllersManager sharedInstance].displayMessageController.displayedMessageInstance;

    if([displayedMessageInstance isEqual:messageInstance])
    {
        //opening doors should be animated
        [[ViewControllersManager sharedInstance].displayMessageController refreshAnimated:YES alsoRefreshBody:YES];
    }

#else

    [[WindowManager sharedInstance].displayView refreshMessageInstance:messageInstance];

#endif

}


+ (void)refreshViewerShowingMessage:(EmailMessage*)message
{
    [ThreadHelper ensureMainThread];

#if TARGET_OS_IPHONE

    EmailMessageInstance* displayedMessageInstance = [ViewControllersManager sharedInstance].displayMessageController.displayedMessageInstance;
    
    if(displayedMessageInstance && [message.instances containsObject:displayedMessageInstance])
    {
        //animate opening of doors
        [[ViewControllersManager sharedInstance].displayMessageController refreshAnimated:YES alsoRefreshBody:YES];
    }
    
#else
    
    [[WindowManager sharedInstance].displayView refreshMessage:message];
    
#endif
    
}

+ (void)refreshFolderOrAccount:(NSManagedObjectID*)folderSettingID
{
    
}



#pragma mark - Moving selected messages

+ (void)moveSelectedMessagesToFolder:(IMAPFolderSetting*)folderSetting
{
    [ThreadHelper ensureMainThread];

    NSArray* selectedMessages = [SelectionAndFilterHelper selectedMessages];

    NSError* error = nil;

    NSArray* objects = folderSetting?[selectedMessages arrayByAddingObject:folderSetting]:selectedMessages;
    
    [MAIN_CONTEXT obtainPermanentIDsForObjects:objects error:&error];

    if(error)
    {
        NSLog(@"Error obtaining permanent objectIDs for message obejcts!! %@", error);
    }


    NSMutableArray* messageInstanceObjectIDs = [NSMutableArray new];

    for(EmailMessageInstance* messageInstance in selectedMessages)
    {
        if(![messageInstance.message isDeviceMessage])
            [messageInstanceObjectIDs addObject:messageInstance.objectID];
    }

    NSManagedObjectID* folderSettingID = [folderSetting objectID];

    if(folderSettingID)
    {
    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext)
     {

         NSInteger counter = 0;

         IMAPFolderSetting* localFolderSetting = (IMAPFolderSetting*)[localContext objectWithID:folderSettingID];

         for(NSManagedObjectID* messageInstanceObjectID in messageInstanceObjectIDs)
         {
             EmailMessageInstance* messageInstance = [EmailMessageInstance messageInstanceWithObjectID:messageInstanceObjectID inContext:localContext];

             counter++;

             [messageInstance moveToFolder:localFolderSetting];

             if(counter%20 == 0)
             {
                 [localContext save:nil];
                 
                 [CoreDataHelper saveWithCallback:^{
                     
#if TARGET_OS_IPHONE
                     
                     [[EmailMessageController sharedInstance] updateFiltersReselectingIndexPath:nil];
                     
#endif
                 }];
            }
        }
         
         
        [localContext save:nil];
         
        [CoreDataHelper saveWithCallback:^{
             
#if TARGET_OS_IPHONE
             
                [[EmailMessageController sharedInstance] updateFiltersReselectingIndexPath:nil];
             
#endif
             
            }];
        }];
    }
}


+ (void)moveSelectedMessagesToOutlineObject:(OutlineObject*)object
{
    
    [ThreadHelper ensureMainThread];
    
    if(object.isOutbox)
        return;
 
    if (object.folderSetting != nil)
    {
        [self moveSelectedMessagesToFolder:object.folderSetting];
        return;
    }
    
    NSArray* selectedMessages = [SelectionAndFilterHelper selectedMessages];
    
    NSError* error = nil;
    
    NSArray* objects = object?[selectedMessages arrayByAddingObject:object]:selectedMessages;
    
    [MAIN_CONTEXT obtainPermanentIDsForObjects:objects error:&error];
    
    if(error)
    {
        NSLog(@"Error obtaining permanent objectIDs for message obejcts!! %@", error);
    }
    
    NSMutableArray* messageInstanceAndFolderSettingObjectIDs = [NSMutableArray new];
    
    for(EmailMessageInstance* messageInstance in selectedMessages)
    {
        if([messageInstance.message isDeviceMessage])
            continue;
        
        NSManagedObjectID* folderSettingID = [[[messageInstance accountSetting] valueForKey:[object folderKey]] objectID];
        NSManagedObjectID* messageInstanceID = messageInstance.objectID;
        
        if(folderSettingID && messageInstanceID)
        {
            [messageInstanceAndFolderSettingObjectIDs addObject:@[messageInstanceID,folderSettingID]];
        }
    }
    
    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext)
    {
        
        NSInteger counter = 0;
        
        for(NSArray* objectIDArray in messageInstanceAndFolderSettingObjectIDs)
        {
            if (objectIDArray.count == 2)
            {
                NSManagedObjectID* messageInstanceID = objectIDArray[0];
                NSManagedObjectID* folderSettingID = objectIDArray[1];

                if(folderSettingID && messageInstanceID)
                {
                    EmailMessageInstance* localMessageInstance = [EmailMessageInstance messageInstanceWithObjectID:messageInstanceID inContext:localContext];
                    IMAPFolderSetting* localFolderSetting = (IMAPFolderSetting*)[localContext objectWithID:folderSettingID];
            
                    counter++;
            
                    [localMessageInstance moveToFolder:localFolderSetting];
            
                    if(counter%20 == 0)
                    {
                        [localContext save:nil];
                        
                        [CoreDataHelper saveWithCallback:^{
                            
#if TARGET_OS_IPHONE
                            
                            [[EmailMessageController sharedInstance] updateFiltersReselectingIndexPath:nil];
                            
#endif
                        }];
                    }
                }
            }
        }
        
        [localContext save:nil];
        
        [CoreDataHelper saveWithCallback:^{
            
#if TARGET_OS_IPHONE
            
            [[EmailMessageController sharedInstance] updateFiltersReselectingIndexPath:nil];
            
#endif
            
        }];
    }];
}

+ (void)performDeleteOfMessageInstancesWithObjectIDs:(NSArray*)messageInstanceObjectIDs
{
    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {
        
        NSInteger counter = 0;
        
        for(NSManagedObjectID* messageInstanceObjectID in messageInstanceObjectIDs)
        {
            EmailMessageInstance* messageInstance = [EmailMessageInstance messageInstanceWithObjectID:messageInstanceObjectID inContext:localContext];
            
            counter++;
            
            [messageInstance moveToBinOrDelete];
            
            if(counter%20 == 0)
            {
                [localContext save:nil];
                
                [CoreDataHelper saveWithCallback:^{

#if TARGET_OS_IPHONE
                    
                    [[EmailMessageController sharedInstance] updateFiltersReselectingIndexPath:nil];
                
#endif
                    
                }];
            }
        }
        
        [localContext save:nil];
        
        [CoreDataHelper saveWithCallback:^{
            
#if TARGET_OS_IPHONE
            
            [[EmailMessageController sharedInstance] updateFiltersReselectingIndexPath:nil];
            
#endif

        }];
        
    }];
}

+ (void)deleteSelectedMessages
{
    [ThreadHelper ensureMainThread];

    NSArray* selectedMessages = [SelectionAndFilterHelper selectedMessages];

    NSError* error = nil;

    [MAIN_CONTEXT obtainPermanentIDsForObjects:selectedMessages error:&error];

    if(error)
    {
        NSLog(@"Error obtaining permanent objectIDs for message obejcts!! %@", error);
    }

    if(selectedMessages.count>=12)
    {
        //a considerable number of messages are about to be deleted - ask for confirmation!
        [AlertHelper showTwoOptionDialogueWithTitle:NSLocalizedString(@"Please confirm", @"Seeking confirmation alert message") message:[NSString stringWithFormat:NSLocalizedString(@"Are you sure you would like to delete %ld messages?", @"Message batch deletion confirmation"), selectedMessages.count] OKOption:NSLocalizedString(@"OK", @"OK button") cancelOption:NSLocalizedString(@"Cancel", @"Cancel Button") suppressionIdentifier:nil callback:^(BOOL OKOptionSelected) {

            //don't do anything unless the user confirms
            if(OKOptionSelected)
            {
                NSMutableArray* messageInstanceObjectIDs = [NSMutableArray new];

                for(EmailMessageInstance* messageInstance in selectedMessages)
                {
                    if(![messageInstance.message isDeviceMessage])
                        [messageInstanceObjectIDs addObject:messageInstance.objectID];
                }

                [SelectionAndFilterHelper performDeleteOfMessageInstancesWithObjectIDs:messageInstanceObjectIDs];
            }
        }];
    }
    else
    {
        NSMutableArray* messageInstanceObjectIDs = [NSMutableArray new];
        
        for(EmailMessageInstance* messageInstance in selectedMessages)
        {
            if(![messageInstance.message isDeviceMessage])
                [messageInstanceObjectIDs addObject:messageInstance.objectID];
        }
        
        [SelectionAndFilterHelper performDeleteOfMessageInstancesWithObjectIDs:messageInstanceObjectIDs];
    }
}



/**CALL ON MAIN*/
+ (void)markSelectedMessagesAsSpam
{
    [ThreadHelper ensureMainThread];

    NSArray* selectedMessages = [SelectionAndFilterHelper selectedMessages];

    BOOL allOn = YES;
    for(EmailMessageInstance* messageObject in selectedMessages)
    {
        if([messageObject isKindOfClass:[EmailMessageInstance class]])
            if(![messageObject isInSpamFolder])
                allOn = NO;
    }

    NSError* error = nil;

    [MAIN_CONTEXT obtainPermanentIDsForObjects:selectedMessages error:&error];

    if(error)
    {
        NSLog(@"Error obtaining permanent objectIDs for message obejcts!! %@", error);
    }


    NSMutableArray* messageInstanceObjectIDs = [NSMutableArray new];

    for(EmailMessageInstance* messageInstance in selectedMessages)
    {
        if(![messageInstance.message isDeviceMessage])
            [messageInstanceObjectIDs addObject:messageInstance.objectID];
    }

    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext)
     {

         NSInteger counter = 0;


         for(NSManagedObjectID* messageInstanceObjectID in messageInstanceObjectIDs)
         {
             EmailMessageInstance* messageInstance = [EmailMessageInstance messageInstanceWithObjectID:messageInstanceObjectID inContext:localContext];

             counter++;

             if(!allOn)
             {
                 [messageInstance moveToSpam];
             }
             else
             {
                 [messageInstance moveToFolder:messageInstance.accountSetting.allMailOrInboxFolder];
             }

             if(counter%20 == 0)
             {
                 [localContext save:nil];

                 [CoreDataHelper saveWithCallback:^{
                     
#if TARGET_OS_IPHONE
                     
                     [[EmailMessageController sharedInstance] updateFiltersReselectingIndexPath:nil];
                     
#endif
                     
                 }];
             }
         }


         [localContext save:nil];

         [CoreDataHelper saveWithCallback:^{
             
#if TARGET_OS_IPHONE
             
             [[EmailMessageController sharedInstance] updateFiltersReselectingIndexPath:nil];
             
#endif
             
         }];
     }];
}


+ (void)markSelectedMessagesAsRead
{
    [ThreadHelper ensureMainThread];
    
    NSArray* selectedMessages = [SelectionAndFilterHelper selectedMessages];
    
    BOOL allOn = [SelectionAndFilterHelper selectedMessagesAreAllRead];
    
    for(EmailMessageInstance* messageInstance in selectedMessages)
    {
        if([messageInstance isKindOfClass:[EmailMessageInstance class]])
        {
            if(allOn)
                [messageInstance markUnread];
            else
                [messageInstance markRead];
        }
    }
}

/**CALL ON MAIN*/
+ (void)markSelectedMessagesAsFlagged
{
    [ThreadHelper ensureMainThread];
    
    NSArray* selectedMessages = [SelectionAndFilterHelper selectedMessages];
    
    BOOL allOn = [SelectionAndFilterHelper selectedMessagesAreAllFlagged];
    
    for(EmailMessageInstance* messageObject in selectedMessages)
    {
        if([messageObject isKindOfClass:[EmailMessageInstance class]])
        {
            if(allOn)
                [messageObject markUnflagged];
            else
                [messageObject markFlagged];
            
            [SelectionAndFilterHelper refreshMessageInstance:messageObject.objectID];
        }
    }
}


+ (BOOL)selectedMessagesAreAllRead
{
    NSArray* selectedMessages = [SelectionAndFilterHelper selectedMessages];

    BOOL allOn = YES;
    for(EmailMessageInstance* messageInstance in selectedMessages)
    {
        if([messageInstance isKindOfClass:[EmailMessageInstance class]])
            if([messageInstance isUnread])
                allOn = NO;
    }

    return allOn;
}

+ (BOOL)selectedMessagesAreAllFlagged
{
    NSArray* selectedMessages = [SelectionAndFilterHelper selectedMessages];
    
    BOOL allOn = YES;
    for(EmailMessageInstance* messageObject in selectedMessages)
    {
        if([messageObject isKindOfClass:[EmailMessageInstance class]])
            if(![messageObject isFlagged])
                allOn = NO;
    }
 
    return allOn;
}


#pragma mark - Refetching

+ (void)refetchSelectedMessage
{
    NSArray* selectedMessages = [SelectionAndFilterHelper selectedMessages];
    
    if(selectedMessages.count != 1)
        return;
    
    EmailMessageInstance* messageInstance = selectedMessages.firstObject;
    
    if([messageInstance isKindOfClass:[EmailMessageInstance class]])
    {
        if(!messageInstance.message)
        {
            [messageInstance removeFromStoreInContext:MAIN_CONTEXT];
        }
        else
        {
            [messageInstance.message removeFromStoreInContext:MAIN_CONTEXT];
        }
    }
}

+ (BOOL)canRefetchSelectedMessage
{
    NSArray* selectedMessages = [SelectionAndFilterHelper selectedMessages];

    if(selectedMessages.count != 1)
        return NO;
    
    EmailMessageInstance* messageInstance = selectedMessages.firstObject;
    
    if([messageInstance isKindOfClass:[EmailMessageInstance class]])
    {
        //check there is a UID and that the message has not been changed/added/moved locally
        NSSet* allInstances = messageInstance.message.instances;
        
        for(EmailMessageInstance* instance in allInstances)
        {
            if(instance.uid && !instance.addedToFolder && !instance.movedFromInstance && !instance.movedToInstance && !instance.movedAwayFromFolder)
            {
                //OK, continue...
            }
            else
            {
                return NO;
            }
        }
        
        return YES;
    }
    
    return NO;
}

@end
