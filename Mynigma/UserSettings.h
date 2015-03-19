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

@class EmailFooter, IMAPAccountSetting, MynigmaDevice;

@interface UserSettings : NSManagedObject

@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSNumber * haveExplainedContactsAccess;
@property (nonatomic, retain) NSString * lastCorruptVersion;
@property (nonatomic, retain) NSDate * lastUsed;
@property (nonatomic, retain) NSString * lastVersionUsed;
@property (nonatomic, retain) NSNumber * personalUse;
@property (nonatomic, retain) NSNumber * privacyProtectionOn;
@property (nonatomic, retain) NSData * settingsData;
@property (nonatomic, retain) NSNumber * showNewbieExplanations;
@property (nonatomic, retain) NSNumber * uid;
@property (nonatomic, retain) NSString * userName;
@property (nonatomic, retain) NSNumber * dummyProperty;
@property (nonatomic, retain) NSSet *accounts;
@property (nonatomic, retain) MynigmaDevice *currentDevice;
@property (nonatomic, retain) NSSet *hasDevices;
@property (nonatomic, retain) IMAPAccountSetting *preferredAccount;
@property (nonatomic, retain) IMAPAccountSetting *settingsAccount;
@property (nonatomic, retain) EmailFooter *standardFooter;
@end

@interface UserSettings (CoreDataGeneratedAccessors)

- (void)addAccountsObject:(IMAPAccountSetting *)value;
- (void)removeAccountsObject:(IMAPAccountSetting *)value;
- (void)addAccounts:(NSSet *)values;
- (void)removeAccounts:(NSSet *)values;

- (void)addHasDevicesObject:(MynigmaDevice *)value;
- (void)removeHasDevicesObject:(MynigmaDevice *)value;
- (void)addHasDevices:(NSSet *)values;
- (void)removeHasDevices:(NSSet *)values;

@end
