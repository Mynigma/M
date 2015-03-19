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





#import "IMAPAccountSetting.h"
#import "EmailContactDetail.h"
#import "EmailFooter.h"
#import "IMAPFolderSetting.h"
#import "MynigmaDevice.h"
#import "UserSettings.h"


@implementation IMAPAccountSetting

@dynamic accountID;
@dynamic currentKeyPairLabel;
@dynamic displayName;
@dynamic emailAddress;
@dynamic footerUsage;
@dynamic hasBeenVerified;
@dynamic hasRequestedWelcomeMessage;
@dynamic incomingAuthType;
@dynamic incomingEncryption;
@dynamic incomingPasswordRef;
@dynamic incomingPort;
@dynamic incomingServer;
@dynamic incomingUserName;
@dynamic lastChecked;
@dynamic lastUpdatedFolders;
@dynamic outgoingAuthType;
@dynamic outgoingEmail;
@dynamic outgoingEncryption;
@dynamic outgoingPasswordRef;
@dynamic outgoingPort;
@dynamic outgoingServer;
@dynamic outgoingUserName;
@dynamic senderEmail;
@dynamic senderName;
@dynamic sentMessagesCopiedIntoSentFolder;
@dynamic signUpMessageID;
@dynamic status;
@dynamic supportsIDLE;
@dynamic supportsMODSEQ;
@dynamic supportsQRESYNC;
@dynamic unreadCount;
@dynamic shouldUse;
@dynamic binFolder;
@dynamic draftsFolder;
@dynamic folders;
@dynamic footer;
@dynamic inboxFolder;
@dynamic mynigmaFolder;
@dynamic outboxFolder;
@dynamic preferredAccountForUser;
@dynamic senderAddresses;
@dynamic sentFolder;
@dynamic settingsAccountForUser;
@dynamic spamFolder;
@dynamic usedByDevices;
@dynamic user;

@end
