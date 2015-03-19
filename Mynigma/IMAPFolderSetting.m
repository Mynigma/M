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
#import "EmailMessageInstance.h"
#import "GmailAccountSetting.h"
#import "IMAPAccountSetting.h"
#import "IMAPFolderSetting.h"


@implementation IMAPFolderSetting

@dynamic displayName;
@dynamic downloadedFromNumber;
@dynamic downloadedFromUID;
@dynamic highestUID;
@dynamic isShownAsStandard;
@dynamic isSubscribed;
@dynamic lastNewCheck;
@dynamic lastOldCheck;
@dynamic modSequenceValue;
@dynamic path;
@dynamic status;
@dynamic uidNext;
@dynamic uidValidity;
@dynamic lastMODSEQCheck;
@dynamic addedMessages;
@dynamic allMailForAccount;
@dynamic binForAccount;
@dynamic containsMessages;
@dynamic deletedMessages;
@dynamic draftsForAccount;
@dynamic flagsChangedOnMessages;
@dynamic inboxForAccount;
@dynamic inIMAPAccount;
@dynamic movedAwayMessages;
@dynamic mynigmaFolderForAccount;
@dynamic outboxForAccount;
@dynamic parentFolder;
@dynamic sentForAccount;
@dynamic spamForAccount;
@dynamic subFolders;
@dynamic unreadMessages;

@end
