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

@class EmailRecipient, Recipient;

@interface NSString (EmailAddresses)

- (NSString*)canonicalForm;

- (BOOL)isValidEmailAddress;

- (Recipient*)parseAsRecipient;

- (EmailRecipient*)parseAsEmailRecipient;



#pragma mark - MessageID generation

//generates a new message ID - it's a timestamp followed by a random string, followed by "@" and the provider part of the given email address
- (NSString*)generateMessageID;


#pragma mark - User's own address

+ (void)setUsersAddresses:(NSArray*)usersAddresses;

+ (NSArray*)usersAddresses;

- (BOOL)isUsersAddress;


@end
