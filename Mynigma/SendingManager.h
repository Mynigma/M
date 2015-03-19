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

@class EmailMessageInstance, IMAPAccount, EmailMessage, DeviceMessage, IMAPAccountSetting;

@interface SendingManager : NSObject


+ (void)sendDraftMessageInstance:(EmailMessageInstance*)messageInstance fromAccount:(IMAPAccount*)account withCallback:(void (^)(NSInteger,NSError*))callback;
                                                                                                      

/**CALL ON MAIN**/
+ (NSData*)MCOMessageForEmailMessage:(EmailMessage*)message;

+ (NSData*)MCOMessageForEmailMessage:(EmailMessage*)message inContext:localContext;

//+ (NSArray*)MCOMessagesForEmailMessageInstance:(EmailMessageInstance*)messageInstance;

//+ (NSData*)MCOMessageForEmail:(EmailMessage*)message;

+ (void)sendAnyUnsentMessages;

+ (void)sendOutboxMessageInstance:(EmailMessageInstance*)messageInstance fromAccount:(IMAPAccount*)account withCallback:(void (^)(NSInteger,NSError*))callback;

@end
