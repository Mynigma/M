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
#else
#import "FolderListController_MacOS.h"
#endif

#import "AppDelegate.h"
#import "HTMLPurifier.h"
#import "EmailMessageInstance.h"
#import "EmailMessage.h"
#import "GmailAccountSetting.h"
#import "GmailLabelSetting.h"
#import "IMAPAccountSetting.h"
#import "IMAPFolderSetting.h"
#import "MynigmaMessage.h"
#import "IMAPAccount.h"
#import "EmailMessage.h"
#import "MCODelegate.h"
#import "EmailMessageData.h"
#import "FileAttachment.h"
#import "IMAPFolderManager.h"

@implementation EmailMessageInstance

@dynamic flags;
@dynamic important;
@dynamic uid;
@dynamic addedToFolder;
@dynamic deletedFromFolder;
@dynamic flagsChangedInFolder;
@dynamic hasLabels;
@dynamic inFolder;
@dynamic labelsChangedInFolder;
@dynamic message;
@dynamic unreadInFolder;
@dynamic unreadWithLabels;
@dynamic movedAwayFromFolder;
@dynamic movedToInstance;
@dynamic movedFromInstance;




@end
