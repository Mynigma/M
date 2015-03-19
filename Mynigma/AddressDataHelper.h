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

@class EmailRecipient, EmailMessage, IMAPAccountSetting, Recipient, IMAPAccount;

@interface AddressDataHelper : NSObject

+ (NSArray*)recipientsForAddressData:(NSData*)addressData;
+ (NSData*)addressDataForRecipients:(NSArray*)recipients;
+ (NSArray*)emailRecipientsForAddressData:(NSData*)addressData;
+ (NSData*)addressDataForEmailRecipients:(NSArray*)recipients;

+ (EmailRecipient*)senderAmongRecipients:(NSArray*)recipients;



+ (EmailRecipient*)senderAsEmailRecipientForMessage:(EmailMessage*)message;
+ (Recipient*)senderAsRecipientForMessage:(EmailMessage*)message;

+ (EmailRecipient*)senderAsEmailRecipientForMessage:(EmailMessage*)message addIfNotFound:(BOOL)addIfNotFound;
+ (Recipient*)senderAsRecipientForMessage:(EmailMessage*)message addIfNotFound:(BOOL)addIfNotFound;

+ (NSArray*)nonSenderEmailRecipientsForMessage:(EmailMessage*)message;


+ (IMAPAccountSetting*)senderAccountSettingForReplyToOrForwardOfMessage:(EmailMessage*)message;
+ (IMAPAccountSetting*)senderAccountSetting;

+ (NSArray*)recipientsForReplyToMessage:(EmailMessage*)message;
+ (NSArray*)recipientsForReplyAllToMessage:(EmailMessage*)message;
+ (NSArray*)recipientsForForwardOfMessage:(EmailMessage*)message;

+ (EmailRecipient*)standardSenderAsEmailRecipient;
+ (Recipient*)standardSenderAsRecipient;

+ (IMAPAccount*)sendingAccountForMessage:(EmailMessage*)message;
+ (IMAPAccountSetting*)sendingAccountSettingForMessage:(EmailMessage*)message;

+ (BOOL)isValidEmailAddress:(NSString*)email;

+ (BOOL)sendableAddressContainedInEmailRecipients:(NSArray*)emailRecipients;
+ (BOOL)sendableAddressContainedInRecipients:(NSArray*)recipients;

+ (NSArray*)recipientsWithoutSenderForMessageInstance:(EmailMessageInstance*)messageInstance;
+ (NSArray*)recipientsWithoutSenderForMessage:(EmailMessage*)message;

+ (BOOL)shouldShowReplyToForMessageInstance:(EmailMessageInstance*)messageInstance;
+ (BOOL)shouldShowReplyToForMessage:(EmailMessage*)message;

@end
