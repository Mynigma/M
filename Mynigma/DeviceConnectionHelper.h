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

@class DeviceConnectionThread, DeviceMessage, IMAPAccountSetting, IdleHelper, TrustEstablishmentThread, MynigmaDevice;

@interface DeviceConnectionHelper : NSObject


//idleHelpers that allow idling of the MynigmaFolder in the various accounts
@property NSMutableArray* idleHelpers;

//an additional timer that checks the folder at regular intervals
@property NSTimer* folderCheckTimer;


//the threadID of the thread in which trust is currently being established
@property NSString* establishingTrustInThreadWithID;


@property MynigmaDevice* targetDeviceForThreadEstablishmentToBeConfirmed;

//only ever need one instance of this
+ (DeviceConnectionHelper*)sharedInstance;


+ (void)postDeviceMessage:(DeviceMessage*)deviceMessage intoAccountSetting:(IMAPAccountSetting*)accountSetting;
+ (void)postDeviceMessage:(DeviceMessage*)deviceMessage intoAccountSetting:(IMAPAccountSetting*)accountSetting inContext:(NSManagedObjectContext*)localContext;
+ (void)postDeviceMessage:(DeviceMessage*)deviceMessage intoAccountSettings:(NSSet*)accounts;
+ (void)postDeviceMessage:(DeviceMessage*)deviceMessage intoAccountSettings:(NSSet*)accounts inContext:(NSManagedObjectContext*)localContext;
+ (void)postDeviceMessage:(DeviceMessage*)deviceMessage intoAllAccountsInContext:(NSManagedObjectContext*)localContext;


+ (void)postDeviceDiscoveryMessageWithAccountSetting:(IMAPAccountSetting*)accountSetting;

+ (void)postDeviceDiscoveryAndSyncDataMessages;

- (void)startEstablishingTrustInThreadWithID:(NSString*)threadID;

- (BOOL)isCurrentlyEstablishingTrust;

@end
