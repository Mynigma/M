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





#import <Foundation/Foundation.h>

@class EmailMessageInstance, FileAttachment, IMAPFolderSetting, OutlineObject, EmailMessage;

@interface SelectionAndFilterHelper : NSObject

+ (instancetype)sharedInstance;


#if TARGET_OS_IPHONE

+ (void)setSelectedMessages:(NSArray*)messages;
+ (NSArray*)selectedMessages;

//0 for all messages, 1 for unread, etc...
@property NSInteger filterIndex;

//the text entered into the search field
@property NSString* searchString;

#else

+ (NSSet*)selectedFoldersAndLabels;
+ (NSSet*)selectedEmailAddresses;

//dragged objects (e.g. messages)
@property NSSet* draggedObjects;

//if the filters for unread or flagged messages are enabled, messages should remain in the list even when selected - otherwise they would disappear immediately
//this list contains such messages - it is cleared whenever the filter criteria are changed
@property NSMutableArray* temporarilyListedMessages;

#endif


//reloads a particular message after a change + both in the message list table view and in the content viewer, if applicable
+ (void)refreshMessage:(NSManagedObjectID*)messageID;
+ (void)refreshMessageInstance:(NSManagedObjectID*)messageID;

//reloads all messages after a change
+ (void)refreshAllMessages;


+ (void)refreshViewerShowingMessageInstanceWithObjectID:(NSManagedObjectID*)messageInstanceObjectID;


//reloads only the content viewer after a change to the displayed message
+ (void)refreshViewerShowingMessageInstance:(EmailMessageInstance*)messageInstance;

+ (void)refreshViewerShowingMessage:(EmailMessage*)message;

//stores selected items, reloads the outline view and restores selection
+ (void)reloadOutlinePreservingSelection;

+ (void)refreshAttachment:(FileAttachment*)fileAttachment;

+ (void)refreshFolderOrAccount:(NSManagedObjectID*)folderSettingID;


+ (void)refreshUnreadCount;

#if TARGET_OS_IPHONE

#else

+ (void)refreshUnreadCountForFolderSetting:(IMAPFolderSetting*)folderSetting;

#endif


@property NSMutableArray* filteredMessages;

@property OutlineObject* topSelection;
@property OutlineObject* bottomSelection;

@property NSPredicate* filterPredicate;

//a date formatter for the date in the message list - this format is only used for messages older than a week
@property NSDateFormatter* messageDateFormatter;

@property NSDateFormatter* messageOldDateFormatter;


//indicates whether each of these filters is in place
@property BOOL showContacts;
@property BOOL showFolders;
@property BOOL showMessages;
@property BOOL showContent;

+ (void)updateFilters;

+ (void)highlightMessageWithID:(NSString*)messageID;



#pragma mark - Manipulating selected messages

+ (void)deleteSelectedMessages;
+ (void)markSelectedMessagesAsSpam;

+ (void)moveSelectedMessagesToFolder:(IMAPFolderSetting*)folderSetting;
+ (void)moveSelectedMessagesToOutlineObject:(OutlineObject*)object;

+ (void)markSelectedMessagesAsRead;
+ (void)markSelectedMessagesAsFlagged;

+ (BOOL)selectedMessagesAreAllRead;
+ (BOOL)selectedMessagesAreAllFlagged;


+ (void)refetchSelectedMessage;
+ (BOOL)canRefetchSelectedMessage;


@end
