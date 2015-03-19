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
#import "AppDelegate.h"

#define STANDARD_ALL_ACCOUNTS 1
#define STANDARD_ALL_CONTACTS 2
#define STANDARD_RECENT_CONTACTS 3
#define STANDARD_ALL_FOLDERS 4
#define STANDARD_INBOX 5
#define STANDARD_OUTBOX 6
#define STANDARD_SENT 7
#define STANDARD_DRAFTS 8
#define STANDARD_BIN 9
#define STANDARD_SPAM 10
#define STANDARD_LOCAL_ARCHIVE 14

@class IMAPAccountSetting, IMAPFolderSetting, Contact, AccountOrFolderView;

@interface OutlineObject : NSObject


@property NSString* buttonTitle;

@property NSNumber* sortSection;

@property BOOL showSeparator;
@property BOOL isEmpty;

@property NSString* sortName;
@property NSDate* sortDate;


@property BOOL isStandard;
@property NSInteger type;

@property NSNumber* indentationLevel;

@property IMAPAccountSetting* accountSetting;
@property IMAPFolderSetting* folderSetting;
@property Contact* contact;
@property NSObject* identifier;

#pragma mark - layout constraints

@property NSLayoutConstraint* missingImageConstraint;
@property NSLayoutConstraint* greenBoxConstraint;
@property NSLayoutConstraint* unreadCountConstraint;

- (BOOL)isButton;

- (id)initAsButtonInSection:(NSNumber*)newSection identifier:(NSObject*)newIdentifier title:(NSString*)buttonTitle;
- (id)initAsEmptyInSection:(NSNumber*)newSection identifier:(NSObject*)newIdentifier separator:(BOOL)newShowSeparator;
- (id)initAsStandardWithType:(NSInteger)newType;
- (id)initAsContact:(Contact*)newContact;
- (id)initAsRecentContact:(Contact*)newContact;
- (id)initAsAccount:(IMAPAccountSetting*)newAccountSetting;
- (id)initAsFolder:(IMAPFolderSetting*)newFolderSetting;

#if TARGET_OS_IPHONE

#else

- (void)configureCellView:(AccountOrFolderView*)cellView;

#endif

- (BOOL)isAccount;
- (BOOL)isContactsOption;
- (BOOL)isContact;
- (BOOL)isFolder;
- (BOOL)isLocalArchive;
- (BOOL)isOutbox;

- (NSSet*)associatedFoldersForAccountSettings:(NSSet*)accounts;
- (NSSet*)accountSettings;

- (NSData*)dataForDragAndDrop;
+ (OutlineObject*)objectFromDragAndDropData:(NSData*)data;

+ (NSSet*)selectedFolderSettingsForSyncing;

+ (NSSet*)selectedFolderSettingsForFiltering;

- (IMAGE*)displayImage;

- (NSString*)displayName;

- (NSInteger)unreadCount;

- (NSString*)folderKey;



@end
