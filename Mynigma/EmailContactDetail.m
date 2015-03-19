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





#import "EmailContactDetail.h"
#import "Contact.h"
#import "EmailMessage.h"
#import "IMAPAccountSetting.h"
#import "MynigmaPrivateKey.h"
#import "MynigmaPublicKey.h"


@implementation EmailContactDetail

@dynamic address;
@dynamic currentReceivedDate;
@dynamic currentSentDate;
@dynamic dateLastContacted;
@dynamic fullName;
@dynamic hasUsedMac;
@dynamic lastCheckedWithServer;
@dynamic lastSentPublicKeyInHeader;
@dynamic licencedUntil;
@dynamic numberOfTimesContacted;
@dynamic sentToServer;
@dynamic currentPublicKey;
@dynamic currentReceivedPair;
@dynamic currentSentPair;
@dynamic linkedToContact;
@dynamic messages;
@dynamic publicKeys;
@dynamic senderAddressForAccount;

@end
