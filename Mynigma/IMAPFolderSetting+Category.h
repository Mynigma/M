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





#import "IMAPFolderSetting.h"

@class FolderInfoObject, IMAPAccount;

@interface IMAPFolderSetting (Category)


- (BOOL)isSpam;
- (BOOL)isBin;
- (BOOL)isInbox;
- (BOOL)isAllMail;
- (BOOL)isOutbox;
- (BOOL)isSent;
- (BOOL)isDrafts;
- (BOOL)isImportant;
- (BOOL)isStarred;

- (IMAPAccountSetting*)accountSetting;
- (BOOL)isGmailSystemLabel;

- (IMAPAccount*)account;
- (void)checkFolderUserInitiated:(BOOL)userInitiated;

- (void)successfulBackLoad;

- (void)unsuccessfulBackLoad;

- (void)successfulForwardLoad;

- (void)unsuccessfulForwardLoad;

- (FolderInfoObject*)folderInfo;

- (void)setDone;

- (BOOL)isBusy;

- (void)setBusy;

- (BOOL)isCompletelyLoaded;

+ (IMAPFolderSetting*)folderSettingWithObjectID:(NSManagedObjectID*)folderSettingObjectID inContext:(NSManagedObjectContext*)localContext;

- (BOOL)isBackwardLoading;

- (void)setIsBackwardLoading:(BOOL)isBackwardLoading;

- (BOOL)isCompletelyBackwardLoaded;

- (BOOL)isStandardFolder;

@end
