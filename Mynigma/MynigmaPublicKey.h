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
#import "GenericPublicKey.h"

@class EmailAddress, EmailContactDetail, KeyExpectation, MynigmaDeclaration, MynigmaDevice, MynigmaPublicKey;

@interface MynigmaPublicKey : GenericPublicKey

@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSDate * dateDeclared;
@property (nonatomic, retain) NSDate * dateObtained;
@property (nonatomic, retain) NSString * emailAddress;
@property (nonatomic, retain) NSNumber * fromServer;
@property (nonatomic, retain) NSNumber * isCompromised;
@property (nonatomic, retain) NSNumber * isCurrentKey;
@property (nonatomic, retain) NSData * publicEncrKeyRef;
@property (nonatomic, retain) NSData * publicVerifyKeyRef;
@property (nonatomic, retain) NSString * version;
@property (nonatomic, retain) NSSet *currentForEmailAddress;
@property (nonatomic, retain) NSSet *currentKeyForEmail;
@property (nonatomic, retain) MynigmaDeclaration *declaration;
@property (nonatomic, retain) NSSet *emailAddresses;
@property (nonatomic, retain) NSSet *expectedBy;
@property (nonatomic, retain) NSSet *introducesKeys;
@property (nonatomic, retain) NSSet *isIntroducedByKeys;
@property (nonatomic, retain) EmailContactDetail *keyForEmail;
@property (nonatomic, retain) NSSet *syncKeyForDevice;
@end

@interface MynigmaPublicKey (CoreDataGeneratedAccessors)

- (void)addCurrentForEmailAddressObject:(EmailAddress *)value;
- (void)removeCurrentForEmailAddressObject:(EmailAddress *)value;
- (void)addCurrentForEmailAddress:(NSSet *)values;
- (void)removeCurrentForEmailAddress:(NSSet *)values;

- (void)addCurrentKeyForEmailObject:(EmailContactDetail *)value;
- (void)removeCurrentKeyForEmailObject:(EmailContactDetail *)value;
- (void)addCurrentKeyForEmail:(NSSet *)values;
- (void)removeCurrentKeyForEmail:(NSSet *)values;

- (void)addEmailAddressesObject:(EmailAddress *)value;
- (void)removeEmailAddressesObject:(EmailAddress *)value;
- (void)addEmailAddresses:(NSSet *)values;
- (void)removeEmailAddresses:(NSSet *)values;

- (void)addExpectedByObject:(KeyExpectation *)value;
- (void)removeExpectedByObject:(KeyExpectation *)value;
- (void)addExpectedBy:(NSSet *)values;
- (void)removeExpectedBy:(NSSet *)values;

- (void)addIntroducesKeysObject:(MynigmaPublicKey *)value;
- (void)removeIntroducesKeysObject:(MynigmaPublicKey *)value;
- (void)addIntroducesKeys:(NSSet *)values;
- (void)removeIntroducesKeys:(NSSet *)values;

- (void)addIsIntroducedByKeysObject:(MynigmaPublicKey *)value;
- (void)removeIsIntroducedByKeysObject:(MynigmaPublicKey *)value;
- (void)addIsIntroducedByKeys:(NSSet *)values;
- (void)removeIsIntroducedByKeys:(NSSet *)values;

- (void)addSyncKeyForDeviceObject:(MynigmaDevice *)value;
- (void)removeSyncKeyForDeviceObject:(MynigmaDevice *)value;
- (void)addSyncKeyForDevice:(NSSet *)values;
- (void)removeSyncKeyForDevice:(NSSet *)values;

@end
