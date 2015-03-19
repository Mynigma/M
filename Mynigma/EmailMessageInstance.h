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

@class EmailMessage, GmailAccountSetting, GmailLabelSetting, IMAPAccountSetting, IMAPFolderSetting, IMAPSessionHelper, IMAPAccount;

@interface EmailMessageInstance : NSManagedObject

@property (nonatomic, retain) NSNumber * flags;
@property (nonatomic, retain) NSNumber * important;
@property (nonatomic, retain) NSNumber * uid;
@property (nonatomic, retain) IMAPFolderSetting *addedToFolder;
@property (nonatomic, retain) IMAPFolderSetting *deletedFromFolder;
@property (nonatomic, retain) IMAPFolderSetting *flagsChangedInFolder;
@property (nonatomic, retain) NSSet *hasLabels;
@property (nonatomic, retain) IMAPFolderSetting *inFolder;
@property (nonatomic, retain) GmailLabelSetting *labelsChangedInFolder;
@property (nonatomic, retain) EmailMessage *message;
@property (nonatomic, retain) IMAPFolderSetting *unreadInFolder;
@property (nonatomic, retain) NSSet *unreadWithLabels;
@property (nonatomic, retain) IMAPFolderSetting *movedAwayFromFolder;
@property (nonatomic, retain) EmailMessageInstance *movedToInstance;
@property (nonatomic, retain) EmailMessageInstance *movedFromInstance;
@end

@interface EmailMessageInstance (CoreDataGeneratedAccessors)

- (void)addHasLabelsObject:(GmailLabelSetting *)value;
- (void)removeHasLabelsObject:(GmailLabelSetting *)value;
- (void)addHasLabels:(NSSet *)values;
- (void)removeHasLabels:(NSSet *)values;

- (void)addUnreadWithLabelsObject:(GmailLabelSetting *)value;
- (void)removeUnreadWithLabelsObject:(GmailLabelSetting *)value;
- (void)addUnreadWithLabels:(NSSet *)values;
- (void)removeUnreadWithLabels:(NSSet *)values;


@end
