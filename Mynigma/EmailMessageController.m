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
#import "MessagesController.h"
#import "ViewControllersManager.h"

#else

#import "FolderListController_MacOS.h"
#import "ReloadViewController.h"
#import "MessagesTable.h"
#import "ReloadingDelegate.h"
#import "PullToReloadViewController.h"
#import "MessageListController.h"
#import "DisplayMessageView.h"
#import "WindowManager.h"

#endif



#import "AppDelegate.h"
#import "EmailMessageController.h"
#import "IMAPAccountSetting+Category.h"
#import "IMAPFolderSetting+Category.h"
#import "UserSettings.h"
#import "Contact+Category.h"
#import "EmailContactDetail+Category.h"
#import "EmailMessage+Category.h"
#import "IMAPAccount.h"
#import "FolderInfoObject.h"
#import "EmailMessageInstance+Category.h"
#import "OutlineObject.h"
#import "SelectionAndFilterHelper.h"



#define VERBOSE NO

#define ANIMATION_DURATION .5


static NSPredicate* messagesFilter;


#if TARGET_OS_IPHONE

#else

static NSInteger currentBlockIdentifier;

#endif


#if TARGET_OS_IPHONE

@implementation EmailMessageController


- (id)init
{
    self = [super init];
    if (self) {
        sortedMessageInstances = [NSMutableArray new];
        sortComparator = ^(EmailMessageInstance* message1, EmailMessageInstance* message2)
        {
            NSComparisonResult result = [message2.message.dateSent compare:message1.message.dateSent];
            if(result!=NSOrderedSame)
                return result;
            return [message2.message.messageid compare:message1.message.messageid];
        };
        filterPredicate = [NSPredicate predicateWithValue:YES];

    }
    return self;
}


+ (EmailMessageController*)sharedInstance
{
    static dispatch_once_t p = 0;

    __strong static id sharedObject = nil;

    dispatch_once(&p, ^{
        sharedObject = [EmailMessageController new];
    });

    return sharedObject;
}


- (void)updateFiltersReselectingIndexPath:(NSIndexPath*)indexPath
{
    if([ViewControllersManager sharedInstance].messagesController.refreshControl.isRefreshing)
        [[ViewControllersManager sharedInstance].messagesController.refreshControl endRefreshing];

    NSMutableString* filterString = [@"" mutableCopy];

    UITableView* tableView = [ViewControllersManager sharedInstance].foldersController.tableView;

    if(!tableView)
    {
        [[ViewControllersManager sharedInstance].messagesController.tableView reloadData];
        return;
    }

    NSPredicate* accountAndFolderSelectionPredicate = [NSPredicate predicateWithValue:YES];

    NSSet* selectedFolders = [OutlineObject selectedFolderSettingsForFiltering];

    if(selectedFolders)
    {
        accountAndFolderSelectionPredicate = [NSPredicate predicateWithFormat:@"(inFolder IN %@) or (ANY hasLabels IN %@)", selectedFolders, selectedFolders];
    }

    //change the heading of the message list controller
    if([SelectionAndFilterHelper sharedInstance].bottomSelection.type==STANDARD_ALL_FOLDERS)
    {
        //no particular folder is selected, so only need to display the account name, if any
        if([SelectionAndFilterHelper sharedInstance].topSelection.type==STANDARD_ALL_ACCOUNTS)
        {
            [[ViewControllersManager sharedInstance].messagesController.navigationController.navigationBar.topItem setTitle:NSLocalizedString(@"All Messages", @"Messages Controller")];
        }
        else
        {
            NSString* displayName = [SelectionAndFilterHelper sharedInstance].topSelection.accountSetting.displayName;
            [[ViewControllersManager sharedInstance].messagesController.navigationController.navigationBar.topItem setTitle:displayName?displayName:@""];
        }
    }
    else
    {
        NSString* displayName = [SelectionAndFilterHelper sharedInstance].bottomSelection.displayName;
        [[ViewControllersManager sharedInstance].messagesController.navigationController.navigationBar.topItem setTitle:displayName?displayName:@""];
    }



    NSPredicate* filtersPredicate = [NSPredicate predicateWithValue:YES];

    switch([SelectionAndFilterHelper sharedInstance].filterIndex)
    {
        case 0: //all

            break;
        case 1: //unread
            filtersPredicate = [NSPredicate predicateWithFormat:@"(unreadInFolder != nil)"];
//            if(filterString.length>0)
//                [filterString appendString:@", "];
//            [filterString appendString:@"unread"];
            break;
        case 2: //flagged
            filtersPredicate = [NSPredicate predicateWithBlock:^BOOL(EmailMessageInstance* evaluatedObject, NSDictionary *bindings) {
                if([evaluatedObject isKindOfClass:[EmailMessageInstance class]])
                {
                    return [evaluatedObject isFlagged];
                }
                return NO;
            }];
//            if(filterString.length>0)
//                [filterString appendString:@", "];
//            [filterString appendString:@"flagged"];
            break;
        case 3: //attachments
            filtersPredicate = [NSPredicate predicateWithFormat:@"((message.className != \"MynigmaMessage\" AND message.attachments.@count > 0) OR (message.className == \"MynigmaMessage\" AND message.attachments.@count > 0))"];
//            if(filterString.length>0)
//                [filterString appendString:@", "];
//            [filterString appendString:@"files"];
            break;
        case 4: //safe
            filtersPredicate = [NSPredicate predicateWithBlock:^BOOL(EmailMessageInstance* evaluatedObject, NSDictionary *bindings) {
                if([evaluatedObject isKindOfClass:[EmailMessageInstance class]])
                {
                    return [evaluatedObject isSafe];
                }
                return NO;
            }];
//            if(filterString.length>0)
//                [filterString appendString:@", "];
//            [filterString appendString:@"safe"];
            break;
    }


    NSPredicate* searchStringPredicate = [NSPredicate predicateWithValue:TRUE]; //used to filter messages by user search input
    
    NSString* searchString = [[SelectionAndFilterHelper sharedInstance] searchString];
    
    if([searchString length]>0)
    {
        searchStringPredicate = [NSPredicate predicateWithFormat:@"(message.searchString CONTAINS[cd] %@)",searchString];
        
//        [filterString appendFormat:NSLocalizedString(@"containing '%@' ", nil),searchString];
    }

    
    NSPredicate* contactSelectionPredicate = [NSPredicate predicateWithValue:YES];

    //    if(APPDELEGATE.foldersController.selectedContact)
    //    {
    //        //contactSelectionPredicate = [NSPredicate predicateWithFormat:@"searchString "]
    //        NSMutableArray* subPredicates = [NSMutableArray new];
    //        for(EmailContactDetail* emailDetail in APPDELEGATE.foldersController.selectedContact.emailAddresses)
    //        {
    //            [subPredicates addObject:[NSPredicate predicateWithFormat:@"(searchString CONTAINS[c] %@)",emailDetail.address]];
    //        }
    //        contactSelectionPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:subPredicates];
    //
    //        NSString* contactName = [MODEL nameOfContact:APPDELEGATE.foldersController.selectedContact];
    //        if(filterString.length==0)
    //            [filterString appendString:contactName];
    //        else
    //            [filterString appendFormat:@", %@", contactName];
    //    }

    NSPredicate* combinedPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[accountAndFolderSelectionPredicate, filtersPredicate, contactSelectionPredicate, searchStringPredicate]];

    filterPredicate = combinedPredicate;
    //NSLog(@"Before new fetch: %lu messages", (unsigned long)APPDELEGATE.filteredMessages.count);
    [SelectionAndFilterHelper sharedInstance].filteredMessages = [[sortedMessageInstances filteredArrayUsingPredicate:filterPredicate] mutableCopy];
    //NSLog(@"After new fetch: %lu messages", (unsigned long)APPDELEGATE.filteredMessages.count);

    UITableView* messagesTableView = [ViewControllersManager sharedInstance].messagesController.tableView;

    [messagesTableView reloadData];

    //the default choice for a selection after reload is 0 on the iPad (select the first row)
    //on the iPhone no selection shcould be made unless explicitly required
    NSInteger proposedSelectedRow = [ViewControllersManager isHorizontallyCompact]?-1:0;

    if(indexPath.row>0)
    {
        proposedSelectedRow = indexPath.row;

        if([messagesTableView numberOfRowsInSection:0] <= indexPath.row)
        {
            proposedSelectedRow--;
        }
    }

    if(proposedSelectedRow >= 0 && [messagesTableView numberOfRowsInSection:0] > proposedSelectedRow)
    {
        [messagesTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:proposedSelectedRow inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
        [[ViewControllersManager sharedInstance].messagesController tableView:messagesTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:proposedSelectedRow inSection:0]];
    }

    //[APPDELEGATE reloadOutlinePreservingSelection];
    
    [[ViewControllersManager sharedInstance].messagesController.navigationController.navigationBar.topItem setPrompt:filterString.length>0?filterString:nil];
}

- (void)updateFilters
{
    [MAIN_CONTEXT performBlock:^{

        [self updateFiltersReselectingIndexPath:nil];

    }];
}


- (void)initialFetchDone
{
    sortedMessageInstances = [[APPDELEGATE.messages.fetchedObjects sortedArrayUsingComparator:sortComparator] mutableCopy];
    //NSLog(@"Before new fetch: %lu messages", (unsigned long)APPDELEGATE.filteredMessages.count);
    
    // account data was not loaded yet, need to reselect now
    [self updateFiltersReselectingIndexPath:nil];
    
    [SelectionAndFilterHelper sharedInstance].filteredMessages = [[sortedMessageInstances filteredArrayUsingPredicate:filterPredicate] mutableCopy];
    //NSLog(@"After new fetch: %lu messages", (unsigned long)APPDELEGATE.filteredMessages.count);
    
    // reload the message list table (does not work on iOS 7 yet)
    [[[ViewControllersManager sharedInstance] messagesController].tableView reloadData];
}


- (NSInteger)numberOfMessages
{
    //NSLog(@"%d filtered messages", filteredMessages.count);

    //NSMutableArray* filteredMessages = APPDELEGATE.filteredMessages;

    return [SelectionAndFilterHelper sharedInstance].filteredMessages.count;
}

+ (NSManagedObject*)messageObjectAtIndex:(NSInteger)index
{
    if(index>=0 && index<[SelectionAndFilterHelper sharedInstance].filteredMessages.count)
        return [[SelectionAndFilterHelper sharedInstance].filteredMessages objectAtIndex:index];
    return nil;
}

+ (NSInteger)indexForMessageObject:(NSManagedObject*)messageObject
{
    NSInteger index = [[SelectionAndFilterHelper sharedInstance].filteredMessages indexOfObject:messageObject];

    return index;
}

- (NSArray*)listOfMessages
{
    return [SelectionAndFilterHelper sharedInstance].filteredMessages;
}

- (BOOL)moreToBeLoadedInSelectedFolder
{
    for(IMAPFolderSetting* folderSetting in [OutlineObject selectedFolderSettingsForSyncing])
    {
        if(![folderSetting isCompletelyBackwardLoaded])
            return YES;
    }

    return NO;
}

- (NSSet*)allSelectedFolders
{
    return [OutlineObject selectedFolderSettingsForFiltering];
}



- (void)loadMoreMessagesInSelectedFolder
{
//#warning backward load unimplemented

//          [IMAPAccount backwardLoadWithCallback:^(BOOL success, NSInteger totalNum, NSInteger numDone) {
//
//              [MAIN_CONTEXT performBlock:^{
//                    [APPDELEGATE.messagesController refreshLoadMoreCell];
//                }];
//
//        }];
}




#pragma mark - NSFetchedResultsControllerDelegate methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    messagesToBeDeleted = [NSMutableSet set];
    messagesToBeInserted = [NSMutableSet set];
    messagesToBeUpdated = [NSMutableSet set];

    insertedMessageIndexes = [NSMutableSet set];
    deletedMessageIndexes = [NSMutableSet set];
    updatedMessageIndexes = [NSMutableSet set];

    filteredMessageInstancesAfterInsertion = [[SelectionAndFilterHelper sharedInstance].filteredMessages mutableCopy];

    [[ViewControllersManager sharedInstance].messagesController.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    //the sections shouldn't really change

    switch(type) {
        case NSFetchedResultsChangeInsert:
            break;

        case NSFetchedResultsChangeDelete:
            break;

        default:
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{

    switch(type) {

        case NSFetchedResultsChangeInsert:
            if([anObject isKindOfClass:[EmailMessageInstance class]])
            {
                [messagesToBeInserted addObject:anObject];
                [self insertMessageInstance:anObject];
                //NSLog(@"Insertion at index: %d", newIndexPath.row);
            }
            break;

        case NSFetchedResultsChangeDelete:
            if([anObject isKindOfClass:[EmailMessageInstance class]])
            {
                [messagesToBeDeleted addObject:anObject];
                [self deleteMessageInstance:anObject];
            }
            break;

        case NSFetchedResultsChangeUpdate:
            if([anObject isKindOfClass:[EmailMessageInstance class]])
            {
                [messagesToBeUpdated addObject:anObject];
                [self updateMessageInstance:anObject];
            }
            break;

        case NSFetchedResultsChangeMove:
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{

    //NSLog(@"Before: %lu messages", (unsigned long)APPDELEGATE.filteredMessages.count);

    //NSIndexPath* indexPath = [NSIndexPath indexPathForRow:filteredMessages.count inSection:0];
    //[APPDELEGATE.messagesController configureCell:(MessageCell*)[APPDELEGATE.messagesController.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
    //[APPDELEGATE.messagesController.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

    NSMutableArray* newIndexPaths = [NSMutableArray new];

    NSMutableArray* filteredMessagesToBeInserted = [NSMutableArray new];

    for(EmailMessageInstance* messageInstance in messagesToBeInserted)
    {
        if([filterPredicate evaluateWithObject:messageInstance])
        {
            NSInteger filteredInsertionIndex = [filteredMessageInstancesAfterInsertion indexOfObject:messageInstance inSortedRange:NSMakeRange(0, filteredMessageInstancesAfterInsertion.count) options:NSBinarySearchingInsertionIndex usingComparator:sortComparator];

            [newIndexPaths addObject:[NSIndexPath indexPathForRow:filteredInsertionIndex inSection:0]];
            //NSLog(@"Add: %ld", (long)filteredInsertionIndex);

            [filteredMessagesToBeInserted addObject:messageInstance];
        }
    }

    //NSLog(@"Adding: %@", newIndexPaths);

    [[SelectionAndFilterHelper sharedInstance].filteredMessages addObjectsFromArray:filteredMessagesToBeInserted];
    [[SelectionAndFilterHelper sharedInstance].filteredMessages sortUsingComparator:sortComparator];

    [[ViewControllersManager sharedInstance].messagesController.tableView insertRowsAtIndexPaths:newIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];

    NSMutableArray* deletionIndexPaths = [NSMutableArray new];
    NSMutableIndexSet* deletionIndexes = [NSMutableIndexSet new];

    for(EmailMessageInstance* messageInstance in messagesToBeDeleted)
    {
        if([filterPredicate evaluateWithObject:messageInstance])
        {
            NSInteger filteredDeletionIndex = [[SelectionAndFilterHelper sharedInstance].filteredMessages indexOfObject:messageInstance];
            if(filteredDeletionIndex!=NSNotFound)
            {
                NSIndexPath* indexPath = [NSIndexPath indexPathForRow:filteredDeletionIndex inSection:0];
                [deletionIndexPaths addObject:indexPath];
                [deletionIndexes addIndex:filteredDeletionIndex];
            }
        }
    }

    [[SelectionAndFilterHelper sharedInstance].filteredMessages removeObjectsAtIndexes:deletionIndexes];

    [[ViewControllersManager sharedInstance].messagesController.tableView deleteRowsAtIndexPaths:deletionIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];

    [SelectionAndFilterHelper refreshUnreadCount];

    //[APPDELEGATE.messagesController configureCell:(MessageCell*)[APPDELEGATE.messagesController.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];

    /*
    NSLog(@"Before: %d messages", filteredMessages.count);
    [APPDELEGATE.messagesController.tableView beginUpdates];

    for(EmailMessage* message in messagesToBeUpdated)
    {
        NSInteger index = [filteredMessages indexOfObject:message];
        if(index!=NSNotFound)
        {
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            [APPDELEGATE.messagesController configureCell:(MessageCell*)[APPDELEGATE.messagesController.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            NSLog(@"Update: %d", index);
        }
    }



    NSMutableArray* oldFilteredMessages = [filteredMessages copy];

    for(EmailMessage* message in messagesToBeDeleted)
    {
        NSInteger index = [filteredMessages indexOfObject:message];
        if(index!=NSNotFound)
        {
            if([sortedMessages containsObject:message])
                [sortedMessages removeObject:message];
            NSInteger index = [oldFilteredMessages indexOfObject:message];
            if(index!=NSNotFound && [filteredMessages containsObject:message])
            {
                [filteredMessages removeObject:message];
                [APPDELEGATE.messagesController.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                NSLog(@"Delete: %d", index);
            }
        }
    }

    oldFilteredMessages = [filteredMessages copy];

    for(EmailMessage* message in messagesToBeInserted)
    {
        if(![sortedMessages containsObject:message])
        {
            NSInteger sortedInsertionIndex = [sortedMessages indexOfObject:message inSortedRange:NSMakeRange(0, sortedMessages.count) options:NSBinarySearchingInsertionIndex usingComparator:sortComparator];
            [sortedMessages insertObject:message atIndex:sortedInsertionIndex];
        }
            if([filterPredicate evaluateWithObject:message])
            {
                if(![filteredMessages containsObject:message])
                {
                    NSInteger filteredInsertionIndex = [filteredMessages indexOfObject:message inSortedRange:NSMakeRange(0, filteredMessages.count) options:NSBinarySearchingInsertionIndex usingComparator:sortComparator];
                    [filteredMessages insertObject:message atIndex:filteredInsertionIndex];

                    NSInteger tableViewIndex = [oldFilteredMessages indexOfObject:message inSortedRange:NSMakeRange(0, oldFilteredMessages.count) options:NSBinarySearchingInsertionIndex usingComparator:sortComparator];
                    [APPDELEGATE.messagesController.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:tableViewIndex inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                    NSLog(@"Add: %d", tableViewIndex);
                }
            }
    }
*/
    //NSLog(@"After: %lu messages", (unsigned long)APPDELEGATE.filteredMessages.count);

    @try {
        [[ViewControllersManager sharedInstance].messagesController.tableView endUpdates];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception in ControllerDidChangeContent: %@", exception.description);
        [[ViewControllersManager sharedInstance].messagesController.tableView reloadData];
    }
}


- (void)insertMessageInstance:(EmailMessageInstance*)messageInstance
{
    NSInteger sortedInsertionIndex = [sortedMessageInstances indexOfObject:messageInstance inSortedRange:NSMakeRange(0, sortedMessageInstances.count) options:NSBinarySearchingInsertionIndex usingComparator:sortComparator];
    [sortedMessageInstances insertObject:messageInstance atIndex:sortedInsertionIndex];
    if([filterPredicate evaluateWithObject:messageInstance])
    {
        NSInteger filteredInsertionIndex = [filteredMessageInstancesAfterInsertion indexOfObject:messageInstance inSortedRange:NSMakeRange(0, filteredMessageInstancesAfterInsertion.count) options:NSBinarySearchingInsertionIndex usingComparator:sortComparator];
        [filteredMessageInstancesAfterInsertion insertObject:messageInstance atIndex:filteredInsertionIndex];
        //[APPDELEGATE.messagesController.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:filteredInsertionIndex inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        //NSLog(@"Add: %d", filteredInsertionIndex);
    }
}

- (void)updateMessageInstance:(EmailMessageInstance*)messageInstance
{
    NSInteger index = [[SelectionAndFilterHelper sharedInstance].filteredMessages indexOfObject:messageInstance];
    if(index!=NSNotFound)
    {
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [[ViewControllersManager sharedInstance].messagesController configureCell:(MessageCell*)[[ViewControllersManager sharedInstance].messagesController.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
        //NSLog(@"Update: %ld", (long)index);
    }
}

- (void)deleteMessageInstance:(EmailMessageInstance*)messageInstance
{
    //NSInteger sortedInsertionIndex = [sortedMessages indexOfObject:message inSortedRange:NSMakeRange(0, sortedMessages.count) options:NSBinarySearchingInsertionIndex usingComparator:sortComparator];
    if([sortedMessageInstances containsObject:messageInstance])
        [sortedMessageInstances removeObject:messageInstance];
    NSInteger index = [[SelectionAndFilterHelper sharedInstance].filteredMessages indexOfObject:messageInstance];
    if(index!=NSNotFound)
    {
        [[SelectionAndFilterHelper sharedInstance].filteredMessages removeObject:messageInstance];
        [[ViewControllersManager sharedInstance].messagesController.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
//        NSLog(@"Delete: %ld", (long)index);
    }
}




- (NSString*)folderString
{
    NSMutableString* newFolderString = [NSMutableString new];

    NSSet* allSelFolders = [self allSelectedFolders];
    for(IMAPFolderSetting* folderSetting in allSelFolders)
    {
        FolderInfoObject* infoObject = [folderSetting folderInfo];
        [newFolderString appendString:[infoObject description]];
    }
    return newFolderString;
}

@end

#else

@implementation EmailMessageController

+ (EmailMessageController*)sharedInstance
{
    static dispatch_once_t p = 0;

    __strong static id sharedObject = nil;

    dispatch_once(&p, ^{
        sharedObject = [EmailMessageController new];

        [[NSNotificationCenter defaultCenter] addObserver:sharedObject selector:@selector(mainContextChanged:) name:NSManagedObjectContextObjectsDidChangeNotification object:[CoreDataHelper sharedInstance].mainObjectContext];
    });


    return sharedObject;
}

- (void)mainContextChanged:(NSNotification*)notification
{
    //[ThreadHelper runAsyncOnMain:^{

    if(!messagesFilter)
        [EmailMessageController updateFilterPredicate];

        //BOOL showInstances = APPDELEGATE.bottomSelection

    NSSet* insertedObjects = [notification.userInfo objectForKey:NSInsertedObjectsKey];

    NSSet* deletedObjects = [notification.userInfo objectForKey:NSDeletedObjectsKey];

    NSSet* updatedObjects = [notification.userInfo objectForKey:NSUpdatedObjectsKey];


    //first delete any messages no longer included in the filtered messages
    NSMutableArray* deletedMessageObjects = [NSMutableArray new];

        Class theClassWeAreLookingFor = ([SelectionAndFilterHelper sharedInstance].bottomSelection.type!=STANDARD_LOCAL_ARCHIVE)?[EmailMessageInstance class]:[EmailMessage class];

    for(NSObject* messageObject in deletedObjects)
        if([messageObject isKindOfClass:theClassWeAreLookingFor])
        {
            [deletedMessageObjects addObject:messageObject];
        }

        if(deletedMessageObjects.count>0)
            [self removeMessageObjectsFromTable:deletedMessageObjects animated:YES];


    NSMutableArray* insertedMessageObjects = [NSMutableArray new];

    for(NSObject* messageObject in insertedObjects)
        if([messageObject isKindOfClass:theClassWeAreLookingFor])
        {
            [insertedMessageObjects addObject:messageObject];
        }

    if(insertedMessageObjects.count>0)
        [self insertMessageObjectsIntoTable:insertedMessageObjects animated:insertedMessageObjects.count<40];

    
    NSMutableArray* updatedMessageObjects = [NSMutableArray new];

    for(NSObject* messageObject in updatedObjects)
    {
        if([messageObject isKindOfClass:theClassWeAreLookingFor])
        {
            [updatedMessageObjects addObject:messageObject];
        }

        if([messageObject isKindOfClass:[IMAPFolderSetting class]])
        {
            [SelectionAndFilterHelper refreshUnreadCountForFolderSetting:(IMAPFolderSetting*)messageObject];
        }
    }

    if(updatedMessageObjects.count>0)
        [self updateMessageObjectsInTable:updatedMessageObjects animated:YES];

    //}];
}

- (void)clearTable
{
    [[SelectionAndFilterHelper sharedInstance] setFilteredMessages:[NSMutableArray new]];

    //preserve selection
//    NSMutableArray* selectedMessages = [NSMutableArray new];
//
//    NSIndexSet* selectedMessagesIndexSet = APPDELEGATE.messagesTable.selectedRowIndexes;
//
//    NSInteger index = selectedMessagesIndexSet.firstIndex;
//
//    while(index!=NSNotFound)
//    {
//        NSObject* messageObject = [EmailMessageController messageObjectAtIndex:index];
//
//        if([messageObject isKindOfClass:[EmailMessageInstance class]])
//        {
//            [selectedMessages addObject:messageObject];
//        }
//
//        index = [selectedMessagesIndexSet indexGreaterThanIndex:index];
//    }
//
    [APPDELEGATE.messagesTable reloadData];
}

/**CALL ON MAIN*/
+ (EmailMessageInstance*)messageObjectAtIndex:(NSInteger)index
{
    [ThreadHelper ensureMainThread];

    if(index>=0 && index<[SelectionAndFilterHelper sharedInstance].filteredMessages.count)
        return [[SelectionAndFilterHelper sharedInstance].filteredMessages objectAtIndex:index];

    return nil;
}

/**CALL ON MAIN*/
+ (NSInteger)indexForMessageObject:(NSObject*)messageObject
{
    [ThreadHelper ensureMainThread];

    if(![SelectionAndFilterHelper sharedInstance].filteredMessages)
        return NSNotFound;

    return [[SelectionAndFilterHelper sharedInstance].filteredMessages indexOfObject:messageObject];
}

+ (BOOL)messageObjectIsToBeDisplayed:(NSObject*)messageObject
{
    BOOL showInstances = [SelectionAndFilterHelper sharedInstance].bottomSelection.type!=STANDARD_LOCAL_ARCHIVE;

    if(showInstances)
    {
        if(![messageObject isKindOfClass:[EmailMessageInstance class]])
            return NO;
    }
    else
    {
        if(![messageObject isKindOfClass:[EmailMessage class]])
            return NO;
    }

    if([[SelectionAndFilterHelper sharedInstance].temporarilyListedMessages containsObject:messageObject])
        return YES;

    return [messagesFilter evaluateWithObject:messageObject];
}

/**CALL ON MAIN*/
+ (NSArray*)selectedMessages
{
    [ThreadHelper ensureMainThread];

    NSMutableArray* returnValue = [NSMutableArray new];
    [APPDELEGATE.messagesTable.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSObject* messageObject = [EmailMessageController messageObjectAtIndex:idx];
        if([messageObject isKindOfClass:[EmailMessageInstance class]] || [messageObject isKindOfClass:[EmailMessage class]])
           [returnValue addObject:messageObject];
    }];

    return returnValue;
}


- (void)processChunkOfMessages:(NSArray*)allMessages filteredMessages:(NSArray*)filteredMessages
{
    //first delete any messages no longer included in the filtered messages
    NSMutableArray* deletedMessageInstancesArray = [allMessages mutableCopy];
    [deletedMessageInstancesArray removeObjectsInArray:filteredMessages];

    [self removeMessageObjectsFromTable:deletedMessageInstancesArray animated:YES];

    //now add any new messages
    NSMutableArray* insertedMessagesArray = [filteredMessages mutableCopy];
    [insertedMessagesArray removeObjectsInArray:[SelectionAndFilterHelper sharedInstance].filteredMessages];

    [self insertMessageObjectsIntoTable:insertedMessagesArray animated:NO];
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


/**CALL ON MAIN*/
+ (void)updateFilterPredicate
{
    [ThreadHelper ensureMainThread];

    //remove any selection in the display view
    [[WindowManager sharedInstance].displayView showMessage:nil];

    //whether the list of messages to be filtered is comprised of EmailMessageInstances (as opposed to EmailMessages)
    BOOL showInstances = [SelectionAndFilterHelper sharedInstance].bottomSelection.type!=STANDARD_LOCAL_ARCHIVE;

    NSString* searchString = [APPDELEGATE.searchField stringValue];
    //filter messages by: search string entered in search box, contacts selected and all/important/unread switch

        NSSet* selectedEmails = [self selectedEmailAddresses];
        NSSet* selectedFoldersAndLabels = [self selectedFoldersAndLabels];
        __block NSMutableString* titleBarString = [NSMutableString string];

        NSPredicate* showSwitchPredicate = [NSPredicate predicateWithValue:TRUE];

        NSMutableArray* newShowPredicateArray = [NSMutableArray new];

        if(APPDELEGATE.showFlaggedButton.state==NSOnState)
        {
            [newShowPredicateArray addObject:[NSPredicate predicateWithBlock:^BOOL(EmailMessage* evaluatedObject, NSDictionary *bindings) {
                if([evaluatedObject isKindOfClass:[EmailMessageInstance class]])
                {
                    return [(EmailMessageInstance*)evaluatedObject isFlagged];
                }
                if([evaluatedObject isKindOfClass:[EmailMessage class]])
                {
                    return YES;
                }
                return NO;
            }]];
        }

    if(!PROCESS_DEVICE_MESSAGES)
    {
        if(showInstances)
            [newShowPredicateArray addObject:[NSPredicate predicateWithFormat:@"(message.className != \"DeviceMessage\")"]];
        else
            [newShowPredicateArray addObject:[NSPredicate predicateWithFormat:@"(className != \"DeviceMessage\")"]];
    }


        if(showInstances)
            if(APPDELEGATE.showUnreadButton.state==NSOnState)
            {
                [newShowPredicateArray addObject:[NSPredicate predicateWithFormat:@"(unreadInFolder != nil)"]];
            }

        if(APPDELEGATE.showSafeButton.state==NSOnState)
        {
            if(showInstances)
                [newShowPredicateArray addObject:[NSPredicate predicateWithFormat:@"(message.className == \"MynigmaMessage\")"]];
            else
                [newShowPredicateArray addObject:[NSPredicate predicateWithFormat:@"(className == \"MynigmaMessage\")"]];
        }

        if(APPDELEGATE.showAttachmentsButton.state==NSOnState)
        {
            if(showInstances)
                [newShowPredicateArray addObject:[NSPredicate predicateWithFormat:@"((message.className != \"MynigmaMessage\" AND message.attachments.@count > 0) OR (message.className == \"MynigmaMessage\" AND message.attachments.@count > 0))"]];
            else
                [newShowPredicateArray addObject:[NSPredicate predicateWithFormat:@"((className != \"MynigmaMessage\" AND attachments.@count > 0) OR (className == \"MynigmaMessage\" AND attachments.@count > 0))"]];
        }


        if(newShowPredicateArray.count>0)
            showSwitchPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:newShowPredicateArray];


        [titleBarString appendString:NSLocalizedString(@"messages ", nil)];

    NSPredicate* selectedFoldersPredicate = nil;//[NSPredicate predicateWithValue:YES];
    //used to pick messages associated with the selected contacts
    NSPredicate* selectedContactsPredicate = [NSPredicate predicateWithValue:YES];
    if(showInstances)
        {
        selectedFoldersPredicate = selectedFoldersAndLabels?[NSPredicate predicateWithFormat:@"(inFolder IN %@) OR (ANY hasLabels IN %@)", selectedFoldersAndLabels, selectedFoldersAndLabels]:[NSPredicate predicateWithValue:YES];
        if([selectedFoldersAndLabels count]>0)
        {
            if([selectedFoldersAndLabels count]==1)
                [titleBarString appendFormat:NSLocalizedString(@"in '%@' ", nil),[(IMAPFolderSetting*)selectedFoldersAndLabels.anyObject displayName]];
            //else
            //  [titleBarString appendFormat:NSLocalizedString(@"in %ld folders ", nil),[selectedFoldersAndLabels count]];
        }

        if([selectedEmails count]>0)
        {
            NSMutableArray* subPredicates = [NSMutableArray new];
            for(EmailContactDetail* emailDetail in selectedEmails)
            {
                [subPredicates addObject:[NSPredicate predicateWithFormat:@"(message.searchString CONTAINS[c] %@)",emailDetail.address]];
            }
            selectedContactsPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:subPredicates];
            //selectedContactsPredicate = [NSPredicate predicateWithFormat:@"(ANY emailAddresses IN %@)",selectedContacts];
            //selectionPredicate = [NSPredicate predicateWithFormat:@"(ANY emailAddresses IN %@)",selectedEmails];
            if([selectedEmails count]==1)
            {
                EmailContactDetail* emailDetail = selectedEmails.anyObject;
                if(emailDetail.linkedToContact)
                {
                    if(emailDetail.linkedToContact.count==1)
                        [titleBarString appendFormat:NSLocalizedString(@"with %@ ", nil),[emailDetail.linkedToContact.anyObject displayName]];
                }
                else
                    [titleBarString appendFormat:NSLocalizedString(@"with %@ ", nil),emailDetail.address];
            }
            else
                [titleBarString appendFormat:NSLocalizedString(@"with any of %ld addresses ", nil),[selectedEmails count]];
        }
        }
    else
    {
        selectedFoldersPredicate = [NSPredicate predicateWithFormat:@"(ALL instances.inFolder == nil) AND (hasHadInstancesAtSomePoint == YES)"];
    }

        NSPredicate* searchStringPredicate = [NSPredicate predicateWithValue:TRUE]; //used to filter messages by user search input
                                                                                    //NSPredicate* searchStringContactsPredicate = [NSPredicate predicateWithValue:TRUE]; //used to filter contacts by user search input

        if([searchString length]>0)
        {
            if(showInstances)
                searchStringPredicate = [NSPredicate predicateWithFormat:@"(message.searchString CONTAINS[cd] %@)",searchString];
            else
                searchStringPredicate = [NSPredicate predicateWithFormat:@"(searchString CONTAINS[cd] %@)",searchString];
            //searchStringContactsPredicate = [NSPredicate predicateWithFormat:@"(addressBookContact.firstName CONTAINS[cd] %@) OR (addressBookContact.lastName CONTAINS[cd] %@)",searchString,searchString]; // TO DO: look up contact's email addresses as well
            [titleBarString appendFormat:NSLocalizedString(@"containing '%@' ", nil),searchString];
        }

        NSPredicate* typePredicate = [NSPredicate predicateWithFormat:@"self isKindOfClass: %@", showInstances?[EmailMessageInstance class]:[EmailMessage class]];

        NSPredicate* messagesFilterPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[typePredicate, showSwitchPredicate, selectedFoldersPredicate, selectedContactsPredicate, searchStringPredicate]];

//    if(APPDELEGATE.temporarilyListedMessages.count>0)
//    {
//        NSPredicate* temporaryExceptionPredicate = [NSPredicate predicateWithFormat:@"self IN %@", APPDELEGATE.temporarilyListedMessages];
//
//        messagesFilterPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[[messagesFilterPredicate copy], temporaryExceptionPredicate]];
//    }

    messagesFilter = messagesFilterPredicate;
}

- (void)updateMessagesWithOffset:(NSInteger)fromValue chunkSize:(NSInteger)chunkSize blockIdentifier:(NSInteger)blockIdentifier filterPredicate:(NSPredicate*)filterPredicate
{
    if(currentBlockIdentifier == blockIdentifier)
    {
        //whether to show EmailMessageInstance objects (rather than the EmailMessages in the local backup
        BOOL showInstances = [SelectionAndFilterHelper sharedInstance].bottomSelection.type!=STANDARD_LOCAL_ARCHIVE;

        NSArray* sourceArray = (NSArray*)(showInstances?APPDELEGATE.messages.arrangedObjects:APPDELEGATE.localMessages.arrangedObjects);

        sourceArray = [sourceArray sortedArrayUsingDescriptors:self.messageInstanceSortDescriptors];

        NSInteger totalNumber = [sourceArray count];

        NSInteger toValue = fromValue + chunkSize;

        if(toValue>totalNumber)
            toValue = totalNumber;

        if(toValue<fromValue)
            return;

        NSArray* chunk = [sourceArray subarrayWithRange:NSMakeRange(fromValue, toValue - fromValue)];

        NSArray* filteredChunk = [chunk filteredArrayUsingPredicate:filterPredicate];

        if(VERBOSE)
            NSLog(@"**> %ld", (long)blockIdentifier);

        [[EmailMessageController sharedInstance] processChunkOfMessages:chunk filteredMessages:filteredChunk];

        if(VERBOSE)
            NSLog(@"++> %ld", (long)blockIdentifier);

        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateMessagesWithOffset:(fromValue + chunkSize) chunkSize:chunkSize blockIdentifier:blockIdentifier filterPredicate:filterPredicate];
        });
    }
}


- (void)updateFilters
{
    [ThreadHelper runAsyncOnMain:^{

        [[ReloadingDelegate reloadController] stopReloadingAndScrollOutOfViewAnimated:NO withCallback:nil];

        __block NSInteger blockIdentifier = random();

        currentBlockIdentifier = blockIdentifier;


        if(currentBlockIdentifier!=blockIdentifier)
            return;

        [EmailMessageController updateFilterPredicate];

        if(currentBlockIdentifier == blockIdentifier)
        {
            [[EmailMessageController sharedInstance] clearTable];

            [self updateMessagesWithOffset:0 chunkSize:200 blockIdentifier:blockIdentifier filterPredicate:messagesFilter];
        }
    }];
}


/**CALL ON MAIN*/
- (void)insertMessageObjectIntoTable:(EmailMessageInstance*)messageInstance animated:(BOOL)animated
{
    [ThreadHelper ensureMainThread];

    [self insertMessageObjectsIntoTable:[NSArray arrayWithObject:messageInstance] animated:animated];
}

/**CALL ON MAIN*/
- (void)insertMessageObjectsIntoTable:(NSArray*)messageObjects animated:(BOOL)animated
{
    [ThreadHelper ensureMainThread];

    if(!messagesFilter)
        [EmailMessageController updateFilterPredicate];

//    if(animated)
//    {
//        [NSAnimationContext beginGrouping];
//        [[NSAnimationContext currentContext] setDuration:ANIMATION_DURATION];
//    }

    [APPDELEGATE.messagesTable beginUpdates];

    for(NSManagedObject* messageObject in messageObjects)
    {
        if([EmailMessageController messageObjectIsToBeDisplayed:messageObject])
        {
            //the instance should be added to the displayed list thanks to its new properties

            NSComparator comparator = ([SelectionAndFilterHelper sharedInstance].bottomSelection.type!=STANDARD_LOCAL_ARCHIVE)?(^NSComparisonResult(NSObject* obj1, NSObject* obj2) {
                for(NSSortDescriptor* sortDescriptor in self.messageInstanceSortDescriptors)
                {
                    NSComparisonResult result = [sortDescriptor compareObject:obj1 toObject:obj2];
                    if(result!=NSOrderedSame)
                        return result;
                }
                return NSOrderedAscending;
            }):(^NSComparisonResult(NSObject* obj1, NSObject* obj2) {
                for(NSSortDescriptor* sortDescriptor in self.messageSortDescriptors)
                {
                    NSComparisonResult result = [sortDescriptor compareObject:obj1 toObject:obj2];
                    if(result!=NSOrderedSame)
                        return result;
                }
                return NSOrderedAscending;
            });

            NSInteger insertionIndex = [[SelectionAndFilterHelper sharedInstance].filteredMessages indexOfObject:messageObject inSortedRange:NSMakeRange(0, [SelectionAndFilterHelper sharedInstance].filteredMessages.count) options:NSBinarySearchingInsertionIndex usingComparator:comparator];


            //disabled: causes flicker...

//            //ensure a selection is made, whenever possible
//           BOOL hasSelection = [APPDELEGATE.messagesTable selectedRow] != -1;
//
//            if(!hasSelection)
//            {
//                [[NSAnimationContext currentContext] setCompletionHandler:^{
//
//                    BOOL hasSelection = [APPDELEGATE.messagesTable selectedRow] != -1;
//                    if(!hasSelection)
//                    {
//                        if(APPDELEGATE.messagesTable.numberOfRows > 0)
//                            [APPDELEGATE.messageListController selectRowAtIndex:0];
//                    }
//                }];
//            }


            //remove the message instance from view!
            if(![[SelectionAndFilterHelper sharedInstance].filteredMessages containsObject:messageObject] && insertionIndex!=NSNotFound && insertionIndex<=[SelectionAndFilterHelper sharedInstance].filteredMessages.count)
            {
                [[SelectionAndFilterHelper sharedInstance].filteredMessages insertObject:messageObject atIndex:insertionIndex];
                [APPDELEGATE.messagesTable insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:insertionIndex] withAnimation:animated?NSTableViewAnimationSlideUp|NSTableViewAnimationEffectFade:NSTableViewAnimationEffectNone];
            }
        }
    }

    [APPDELEGATE.messagesTable endUpdates];

//    if(animated)
//    {
//        [NSAnimationContext endGrouping];
//    }
}

/**CALL ON MAIN*/
- (void)removeMessageObjectFromTable:(EmailMessageInstance*)messageObject animated:(BOOL)animated
{
    [ThreadHelper ensureMainThread];

    [self removeMessageObjectsFromTable:@[messageObject] animated:animated];
}

/**CALL ON MAIN*/
- (void)removeMessageObjectsFromTable:(NSArray*)messageObjects animated:(BOOL)animated
{
    [ThreadHelper ensureMainThread];

    if(!messagesFilter)
        [EmailMessageController updateFilterPredicate];

    if(animated)
    {
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:ANIMATION_DURATION];
    }

    [APPDELEGATE.messagesTable beginUpdates];

    for(NSObject* messageObject in messageObjects)
    {
        //if the message instance is currently displayed...
        if([[SelectionAndFilterHelper sharedInstance].filteredMessages containsObject:messageObject])
        {
            //and should no longer be shown...
            if(![EmailMessageController messageObjectIsToBeDisplayed:messageObject])
            {
                //remove the message instance from view!
                NSInteger index = [EmailMessageController indexForMessageObject:messageObject];
                if(index!=NSNotFound && index<[SelectionAndFilterHelper sharedInstance].filteredMessages.count)
                {
                    //if the message instance is currently selected, move selection on to next item in the list...

                    //THIS LOOKS BAD - DO IT AFTER THE ANIMATION INSTEAD
                    //if(messageInstances.count==1)
                    //    [APPDELEGATE.messageListController moveSelectionOnFromMessageInstance:messageInstance];

                    NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:index];

                    BOOL wasSelected = [APPDELEGATE.messagesTable selectedRow] == index;

                    [[NSAnimationContext currentContext] setCompletionHandler:^{

                        if(wasSelected && messageObjects.count==1 && index < APPDELEGATE.messagesTable.numberOfRows)
                            [APPDELEGATE.messageListController selectRowAtIndex:index];

                    }];

                    [[SelectionAndFilterHelper sharedInstance].filteredMessages removeObject:messageObject];
                    [APPDELEGATE.messagesTable removeRowsAtIndexes:indexSet withAnimation:animated?NSTableViewAnimationSlideDown|NSTableViewAnimationEffectFade:NSTableViewAnimationEffectNone];

                }
            }
        }
    }

    [APPDELEGATE.messagesTable endUpdates];

    if(animated)
    {
        [NSAnimationContext endGrouping];
    }
}

/**CALL ON MAIN*/
- (void)updateMessageObjectsInTable:(NSArray*)messageObjects animated:(BOOL)animated
{
    [ThreadHelper ensureMainThread];

//    if(animated)
//    {
//        [NSAnimationContext beginGrouping];
//        [[NSAnimationContext currentContext] setDuration:ANIMATION_DURATION];
//    }

    [APPDELEGATE.messagesTable beginUpdates];

    for(NSObject* messageObject in messageObjects)
    {
        //if the message instance is currently displayed...
        if([[SelectionAndFilterHelper sharedInstance].filteredMessages containsObject:messageObject])
        {
            //the property change might mean that the message is no longer to be displayed
            if([EmailMessageController messageObjectIsToBeDisplayed:messageObject])
            {
                //everything is fine, the message instance can remain in the display, which needs to be refreshed
                NSInteger index = [EmailMessageController indexForMessageObject:messageObject];
                if(index!=NSNotFound && index<[SelectionAndFilterHelper sharedInstance].filteredMessages.count)
                {
                    [APPDELEGATE.messagesTable reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:index] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
                }
            }
            else
            {
                //remove the message instance from view!
                NSInteger index = [EmailMessageController indexForMessageObject:messageObject];

                BOOL wasSelected = [APPDELEGATE.messagesTable selectedRow] == index;

                if(wasSelected)
                {
                [[NSAnimationContext currentContext] setCompletionHandler:^{

                    if(messageObjects.count==1 && index < APPDELEGATE.messagesTable.numberOfRows)
                        [APPDELEGATE.messageListController selectRowAtIndex:index];
                    else if(APPDELEGATE.messagesTable.numberOfRows > 0)
                        [APPDELEGATE.messageListController selectRowAtIndex:0];
                }];
                }


                if([[SelectionAndFilterHelper sharedInstance].filteredMessages containsObject:messageObject] && index!=NSNotFound && index<[SelectionAndFilterHelper sharedInstance].filteredMessages.count)
                {
                    [[SelectionAndFilterHelper sharedInstance].filteredMessages removeObject:messageObject];
                    [APPDELEGATE.messagesTable removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:animated?NSTableViewAnimationSlideDown|NSTableViewAnimationEffectFade:NSTableViewAnimationEffectNone];
                }
            }
        }
        else
        {
            if([EmailMessageController messageObjectIsToBeDisplayed:messageObject])
            {
                NSComparator comparator = ([SelectionAndFilterHelper sharedInstance].bottomSelection.type!=STANDARD_LOCAL_ARCHIVE)?(^NSComparisonResult(EmailMessageInstance* obj1, EmailMessageInstance* obj2) {
                    for(NSSortDescriptor* sortDescriptor in self.messageInstanceSortDescriptors)
                    {
                        NSComparisonResult result = [sortDescriptor compareObject:obj1 toObject:obj2];
                        if(result!=NSOrderedSame)
                            return result;
                    }
                    return NSOrderedAscending;
                }):(^NSComparisonResult(EmailMessageInstance* obj1, EmailMessageInstance* obj2) {
                    for(NSSortDescriptor* sortDescriptor in self.messageSortDescriptors)
                    {
                        NSComparisonResult result = [sortDescriptor compareObject:obj1 toObject:obj2];
                        if(result!=NSOrderedSame)
                            return result;
                    }
                    return NSOrderedAscending;
                });

                //the instance should be added to the displayed list thanks to its new properties
                NSInteger insertionIndex = [[SelectionAndFilterHelper sharedInstance].filteredMessages indexOfObject:messageObject inSortedRange:NSMakeRange(0, [SelectionAndFilterHelper sharedInstance].filteredMessages.count) options:NSBinarySearchingInsertionIndex usingComparator:comparator];

                if(![[SelectionAndFilterHelper sharedInstance].filteredMessages containsObject:messageObject] && insertionIndex!=NSNotFound && insertionIndex<=[SelectionAndFilterHelper sharedInstance].filteredMessages.count)
                {
                    [[SelectionAndFilterHelper sharedInstance].filteredMessages insertObject:messageObject atIndex:insertionIndex];
                    [APPDELEGATE.messagesTable insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:insertionIndex] withAnimation:animated?NSTableViewAnimationSlideUp|NSTableViewAnimationEffectFade:NSTableViewAnimationEffectNone];
                }
            }
        }
    }

    [APPDELEGATE.messagesTable endUpdates];

//    if(animated)
//    {
//        [NSAnimationContext endGrouping];
//    }
}


@end

#endif
