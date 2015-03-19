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
#import "DeviceMessage.h"

@class MynigmaDevice, EmailMessage, IMAPAccountSetting;

@interface DeviceMessage (Category)




#pragma mark - Creation of device messages

+ (DeviceMessage*)constructNewDeviceMessageInContext:(NSManagedObjectContext*)localContext;

//returns the device discovery message posted by the current device
//if none, it will create a fresh one
+ (void)deviceDiscoveryMessageWithCallback:(void(^)(DeviceMessage* deviceDiscoveryMessage))callback;
+ (DeviceMessage*)deviceDiscoveryMessageInContext:(NSManagedObjectContext*)localContext;

//creates a fresh device discovery message
+ (void)constructNewDeviceDiscoveryMessageWithCallback:(void(^)(DeviceMessage* deviceDiscoveryMessage))callback;
+ (DeviceMessage*)constructNewDeviceDiscoveryMessageInContext:(NSManagedObjectContext*)localContext;

//creates a fresh sync data message
+ (DeviceMessage*)syncDataMessageFromDevice:(MynigmaDevice*)device inContext:(NSManagedObjectContext*)localContext;



#pragma mark - List all device messages

+ (NSArray*)listAllDeviceMessagesInContext:(NSManagedObjectContext*)localContext;



#pragma mark - Properties

- (BOOL)isTargetedToThisDeviceInContext:(NSManagedObjectContext*)localContext;
- (BOOL)hasExpired;
- (void)setPayload:(NSArray*)payload;
- (NSArray*)payload;



#pragma mark - Processing device messages

//- (void)processDeviceData:(NSData*)data withAccount:(IMAPAccountSetting*)accountSetting;
- (void)processMessageWithAccountSetting:(IMAPAccountSetting*)accountSetting;

- (void)parseHeaderInfos:(NSDictionary*)headerInfos inContext:(NSManagedObjectContext*)localContext;
- (void)parseDownloadedData:(NSData*)downloadedData;

- (NSDictionary*)headerInfo;


@end
