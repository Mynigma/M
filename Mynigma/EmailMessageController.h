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

#import <Foundation/Foundation.h>

@class IMAPFolderSetting, AbstractFolder, IMAPAccountSetting, EmailMessage, FolderInfoObject, EmailMessageInstance;

@interface EmailMessageController : NSObject <NSFetchedResultsControllerDelegate>
{
    NSMutableDictionary* folderInfoObjects;

    NSMutableArray* sortedMessageInstances;

    NSPredicate* filterPredicate;

    NSMutableSet* messagesToBeInserted;
    NSMutableSet* messagesToBeDeleted;
    NSMutableSet* messagesToBeUpdated;

    NSMutableSet* insertedMessageIndexes;
    NSMutableSet* deletedMessageIndexes;
    NSMutableSet* updatedMessageIndexes;

    NSMutableArray* filteredMessageInstancesAfterInsertion;

    NSComparisonResult(^sortComparator)(id obj1, id obj2);
}

@property NSArray* messageInstanceSortDescriptors;
@property NSArray* messageSortDescriptors;


+ (EmailMessageController*)sharedInstance;

- (void)initialFetchDone;

- (void)updateFilters;

- (void)updateFiltersReselectingIndexPath:(NSIndexPath*)indexPath;

- (NSInteger)numberOfMessages;

+ (NSManagedObject*)messageObjectAtIndex:(NSInteger)index;

+ (NSInteger)indexForMessageObject:(NSManagedObject*)messageObject;

- (NSArray*)listOfMessages;

- (NSSet*)allSelectedFolders;

- (BOOL)moreToBeLoadedInSelectedFolder;

- (void)loadMoreMessagesInSelectedFolder;

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath;
- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type;
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller;
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller;

- (void)insertMessageInstance:(EmailMessageInstance*)messageInstance;

//- (void)reload;

- (NSString*)folderString;

@end

#else

@interface EmailMessageController : NSObject
{
}

@property NSArray* messageInstanceSortDescriptors;
@property NSArray* messageSortDescriptors;

+ (EmailMessageController*)sharedInstance;

- (void)mainContextChanged:(NSNotification*)notification;

+ (void)updateFilterPredicate;

- (void)updateFilters;

+ (NSObject*)messageObjectAtIndex:(NSInteger)index;

+ (NSInteger)indexForMessageObject:(NSObject*)messageObject;

+ (BOOL)messageObjectIsToBeDisplayed:(NSObject*)messageObject;

+ (NSArray*)selectedMessages;

- (void)clearTable;

- (void)processChunkOfMessages:(NSArray*)allMessages filteredMessages:(NSArray*)filteredMessages;

- (void)insertMessageObjectIntoTable:(NSObject*)messageObject animated:(BOOL)animated;

- (void)insertMessageObjectsIntoTable:(NSArray*)messageObject animated:(BOOL)animated;

- (void)removeMessageObjectFromTable:(NSObject*)messageObject animated:(BOOL)animated;

- (void)removeMessageObjectsFromTable:(NSArray*)messageObjects animated:(BOOL)animated;

- (void)updateMessageObjectsInTable:(NSArray*)messageObjects animated:(BOOL)animated;

@end


#endif
