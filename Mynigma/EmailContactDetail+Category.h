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





#import "EmailContactDetail.h"

@class MynigmaPrivateKey, MynigmaPublicKey;

@interface EmailContactDetail (Category)

+ (void)collectAllContactDetails;


//adds a new EmailContactDetail to the store, provided none exists with the same email address (if it does, the method simply returns the existing object and sets found to YES, if applicable)

/**CALL ON MAIN*/
+ (void)addEmailContactDetailForEmail:(NSString*)email withCallback:(void(^)(EmailContactDetail* contactDetail))callback;

/**CALL ON MAIN*/
//+ (EmailContactDetail*)addEmailContactDetailForEmail:(NSString*)email alreadyFoundOne:(BOOL*)found;

//+ (EmailContactDetail*)addEmailContactDetailForEmail:(NSString*)email makeDuplicateIfNecessary:(BOOL)makeDuplicate;

//+ (EmailContactDetail*)addEmailContactDetailForEmail:(NSString*)email alreadyFoundOne:(BOOL*)found  makeDuplicateIfNecessary:(BOOL)makeDuplicate;

+ (void)addEmailContactDetailForEmail:(NSString*)email makeDuplicateIfNecessary:(BOOL)makeDuplicate withCallback:(void(^)(EmailContactDetail* contactDetail, BOOL alreadyFoundOne))callback;


/**CALL ON MAIN*/
+ (EmailContactDetail*)addEmailContactDetailForEmail:(NSString*)email alreadyFoundOne:(BOOL*)found inContext:(NSManagedObjectContext*)localContext;

/**CALL ON MAIN*/
+ (EmailContactDetail*)addEmailContactDetailForEmail:(NSString*)passedEmail alreadyFoundOne:(BOOL*)found inContext:(NSManagedObjectContext*)localContext makeDuplicateIfNecessary:(BOOL)makeDuplicate;


+ (EmailContactDetail*)emailContactDetailForAddress:(NSString*)emailAddress;
+ (EmailContactDetail*)emailContactDetailForAddress:(NSString*)emailAddress inContext:(NSManagedObjectContext*)localContext;

//- (MynigmaPrivateKey*)privateKey;
//- (MynigmaPublicKey*)publicKey;

+ (EmailContactDetail*)contactDetailWithObjectID:(NSManagedObjectID*)contactDetailObjectID inContext:(NSManagedObjectContext*)localContext;

+ (NSDictionary*)allAddressesDict;

- (Contact*)mostFrequentContact;

@end
