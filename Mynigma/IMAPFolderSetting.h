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
#import <CoreData/CoreData.h>

@class EmailMessageInstance, GmailAccountSetting, IMAPAccountSetting, IMAPFolderSetting;

@interface IMAPFolderSetting : NSManagedObject

@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSNumber * downloadedFromNumber;
@property (nonatomic, retain) NSNumber * downloadedFromUID;
@property (nonatomic, retain) NSNumber * highestUID;
@property (nonatomic, retain) NSNumber * isShownAsStandard;
@property (nonatomic, retain) NSNumber * isSubscribed;
@property (nonatomic, retain) NSDate * lastNewCheck;
@property (nonatomic, retain) NSDate * lastOldCheck;
@property (nonatomic, retain) NSNumber * modSequenceValue;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSNumber * uidNext;
@property (nonatomic, retain) NSNumber * uidValidity;
@property (nonatomic, retain) NSDate * lastMODSEQCheck;
@property (nonatomic, retain) NSSet *addedMessages;
@property (nonatomic, retain) GmailAccountSetting *allMailForAccount;
@property (nonatomic, retain) IMAPAccountSetting *binForAccount;
@property (nonatomic, retain) NSSet *containsMessages;
@property (nonatomic, retain) NSSet *deletedMessages;
@property (nonatomic, retain) IMAPAccountSetting *draftsForAccount;
@property (nonatomic, retain) NSSet *flagsChangedOnMessages;
@property (nonatomic, retain) IMAPAccountSetting *inboxForAccount;
@property (nonatomic, retain) IMAPAccountSetting *inIMAPAccount;
@property (nonatomic, retain) NSSet *movedAwayMessages;
@property (nonatomic, retain) IMAPAccountSetting *mynigmaFolderForAccount;
@property (nonatomic, retain) IMAPAccountSetting *outboxForAccount;
@property (nonatomic, retain) IMAPFolderSetting *parentFolder;
@property (nonatomic, retain) IMAPAccountSetting *sentForAccount;
@property (nonatomic, retain) IMAPAccountSetting *spamForAccount;
@property (nonatomic, retain) NSSet *subFolders;
@property (nonatomic, retain) NSSet *unreadMessages;
@end

@interface IMAPFolderSetting (CoreDataGeneratedAccessors)

- (void)addAddedMessagesObject:(EmailMessageInstance *)value;
- (void)removeAddedMessagesObject:(EmailMessageInstance *)value;
- (void)addAddedMessages:(NSSet *)values;
- (void)removeAddedMessages:(NSSet *)values;

- (void)addContainsMessagesObject:(EmailMessageInstance *)value;
- (void)removeContainsMessagesObject:(EmailMessageInstance *)value;
- (void)addContainsMessages:(NSSet *)values;
- (void)removeContainsMessages:(NSSet *)values;

- (void)addDeletedMessagesObject:(EmailMessageInstance *)value;
- (void)removeDeletedMessagesObject:(EmailMessageInstance *)value;
- (void)addDeletedMessages:(NSSet *)values;
- (void)removeDeletedMessages:(NSSet *)values;

- (void)addFlagsChangedOnMessagesObject:(EmailMessageInstance *)value;
- (void)removeFlagsChangedOnMessagesObject:(EmailMessageInstance *)value;
- (void)addFlagsChangedOnMessages:(NSSet *)values;
- (void)removeFlagsChangedOnMessages:(NSSet *)values;

- (void)addMovedAwayMessagesObject:(EmailMessageInstance *)value;
- (void)removeMovedAwayMessagesObject:(EmailMessageInstance *)value;
- (void)addMovedAwayMessages:(NSSet *)values;
- (void)removeMovedAwayMessages:(NSSet *)values;

- (void)addSubFoldersObject:(IMAPFolderSetting *)value;
- (void)removeSubFoldersObject:(IMAPFolderSetting *)value;
- (void)addSubFolders:(NSSet *)values;
- (void)removeSubFolders:(NSSet *)values;

- (void)addUnreadMessagesObject:(EmailMessageInstance *)value;
- (void)removeUnreadMessagesObject:(EmailMessageInstance *)value;
- (void)addUnreadMessages:(NSSet *)values;
- (void)removeUnreadMessages:(NSSet *)values;

@end
