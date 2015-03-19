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

@class EmailMessageInstance;

@interface UserNotificationHelper : NSObject


+ (instancetype)sharedInstance;


#if TARGET_OS_IPHONE

#else

//the user notification center used to alert the user of incoming messages
@property NSUserNotificationCenter* notificationCenter;

#endif


+ (void)notifyOfMessage:(NSManagedObjectID*)emailMessageInstanceObjectID;

+ (void)notifyOfMessageBatch:(NSInteger)numberOfMessages;



+ (void)queueMessageInstanceForNotification:(EmailMessageInstance*)messageInstance;

+ (void)postNotifications;


#pragma mark - Unread badge

+ (void)setUnreadBadgeTo:(NSInteger)badgeNumber;

@end
