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





#import "MynigmaDevice.h"
#import "AppDelegate.h"



@interface MynigmaDevice (Category)

+ (MynigmaDevice*)currentDevice;

+ (MynigmaDevice*)deviceWithUUID:(NSString*)UUID;

+ (MynigmaDevice*)deviceWithUUID:(NSString*)UUID addIfNotFound:(BOOL)addIfNotFound;

+ (MynigmaDevice*)currentDeviceInContext:(NSManagedObjectContext*)localContext;

+ (MynigmaDevice*)deviceWithUUID:(NSString*)UUID inContext:(NSManagedObjectContext*)localContext;

+ (MynigmaDevice*)deviceWithUUID:(NSString*)UUID addIfNotFound:(BOOL)addIfNotFound inContext:(NSManagedObjectContext*)localContext;

+ (BOOL)haveKeyForDeviceWithUUID:(NSString*)deviceUUID;

- (NSString*)deviceTypeName;

+ (NSArray*)listAllKnownDevices;

- (IMAGE*)image;

@end
