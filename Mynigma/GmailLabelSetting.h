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
#import "IMAPFolderSetting.h"

@class EmailMessageInstance, GmailAccountSetting;

@interface GmailLabelSetting : IMAPFolderSetting

@property (nonatomic, retain) NSData * displayColour;
@property (nonatomic, retain) NSString * labelName;
@property (nonatomic, retain) NSNumber * isSystemLabel;
@property (nonatomic, retain) NSSet *attachedToMessages;
@property (nonatomic, retain) NSSet *attachedToUnreadMessages;
@property (nonatomic, retain) NSSet *labelsChangedOnMessages;
@property (nonatomic, retain) GmailAccountSetting *importantForAccount;
@property (nonatomic, retain) GmailAccountSetting *starredForAccount;
@end

@interface GmailLabelSetting (CoreDataGeneratedAccessors)

- (void)addAttachedToMessagesObject:(EmailMessageInstance *)value;
- (void)removeAttachedToMessagesObject:(EmailMessageInstance *)value;
- (void)addAttachedToMessages:(NSSet *)values;
- (void)removeAttachedToMessages:(NSSet *)values;

- (void)addAttachedToUnreadMessagesObject:(EmailMessageInstance *)value;
- (void)removeAttachedToUnreadMessagesObject:(EmailMessageInstance *)value;
- (void)addAttachedToUnreadMessages:(NSSet *)values;
- (void)removeAttachedToUnreadMessages:(NSSet *)values;

- (void)addLabelsChangedOnMessagesObject:(EmailMessageInstance *)value;
- (void)removeLabelsChangedOnMessagesObject:(EmailMessageInstance *)value;
- (void)addLabelsChangedOnMessages:(NSSet *)values;
- (void)removeLabelsChangedOnMessages:(NSSet *)values;

@end
