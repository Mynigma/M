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
#import <CoreData/CoreData.h>

@class DeviceMessage, IMAPAccountSetting, MynigmaPublicKey, UserSettings;

@interface MynigmaDevice : NSManagedObject

@property (nonatomic, retain) NSNumber * alreadyProcessed;
@property (nonatomic, retain) NSDate * dateAdded;
@property (nonatomic, retain) NSString * deviceId;
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSDate * lastSynced;
@property (nonatomic, retain) NSDate * lastUpdatedInfo;
@property (nonatomic, retain) NSString * mynigmaVersion;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSNumber * isTrusted;
@property (nonatomic, retain) NSString * operatingSystemIdentifier;
@property (nonatomic, retain) NSNumber * syncDataStale;
@property (nonatomic, retain) UserSettings *currentDeviceForUser;
@property (nonatomic, retain) DeviceMessage *discoveryMessage;
@property (nonatomic, retain) NSSet *receivedDeviceMessages;
@property (nonatomic, retain) NSSet *sentDeviceMessages;
@property (nonatomic, retain) UserSettings *user;
@property (nonatomic, retain) NSSet *usingAccounts;
@property (nonatomic, retain) MynigmaPublicKey *syncKey;
@property (nonatomic, retain) DeviceMessage *syncDataMessage;
@end

@interface MynigmaDevice (CoreDataGeneratedAccessors)

- (void)addReceivedDeviceMessagesObject:(DeviceMessage *)value;
- (void)removeReceivedDeviceMessagesObject:(DeviceMessage *)value;
- (void)addReceivedDeviceMessages:(NSSet *)values;
- (void)removeReceivedDeviceMessages:(NSSet *)values;

- (void)addSentDeviceMessagesObject:(DeviceMessage *)value;
- (void)removeSentDeviceMessagesObject:(DeviceMessage *)value;
- (void)addSentDeviceMessages:(NSSet *)values;
- (void)removeSentDeviceMessages:(NSSet *)values;

- (void)addUsingAccountsObject:(IMAPAccountSetting *)value;
- (void)removeUsingAccountsObject:(IMAPAccountSetting *)value;
- (void)addUsingAccounts:(NSSet *)values;
- (void)removeUsingAccounts:(NSSet *)values;

@end
