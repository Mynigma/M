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






#import <XCTest/XCTest.h>
#import "MynigmaPrivateKey+Category.h"
#import "MynigmaPublicKey+Category.h"


@interface MynigmaPrivateKey()

+ (MynigmaPrivateKey*)syncMakeNewPrivateKeyWithEncKeyData:(NSData*)encData andVerKeyData:(NSData*)verData decKeyData:(NSData*)decData sigKeyData:(NSData*)sigData forEmail:(NSString*)email keyLabel:(NSString*)keyLabel inContext:(NSManagedObjectContext*)keyContext;

+ (MynigmaPrivateKey*)syncMakeNewPrivateKeyWithLabel:(NSString*)keyLabel forEmail:(NSString*)emailString withDecRef:(NSData*)decRef andSigRef:(NSData*)sigRef andEncRef:(NSData*)encRef andVerRef:(NSData*)verRef dateCreated:(NSDate*)dateCreated isCompromised:(BOOL)isCompromised makeCurrentKey:(BOOL)makeCurrentKey inContext:(NSManagedObjectContext*)keyContext;

+ (BOOL)removePrivateKeyWithLabel:(NSString*)keyPairLabel alsoRemoveFromKeychain:(BOOL)alsoRemoveFromKeychain;

@end


@interface MynigmaPublicKey()

- (void)associateKeyWithEmail:(NSString*)emailString forceMakeCurrent:(BOOL)makeCurrent inContext:(NSManagedObjectContext*)keyContext;

+ (MynigmaPublicKey*)syncMakeNewPublicKeyWithEncKeyData:(NSData*)encKeyData andVerKeyData:(NSData*)verKeyData forEmail:(NSString*)email keyLabel:(NSString*)keyLabel inContext:(NSManagedObjectContext*)keyContext;

+ (BOOL)removePublicKeyWithLabel:(NSString*)publicKeyLabel alsoRemoveFromKeychain:(BOOL)alsoRemoveFromKeychain;

@end



@class IMAPAccountSetting, IMAPSessionMock, IMAPAccount;

@interface TestHarness : XCTestCase


@property IMAPSessionMock* imapSesionMock;

- (void)waitForConditionToBeSatisfied:(BOOL(^)())conditionBlock;
- (void)waitForConditionToBeSatisfied:(BOOL(^)())conditionBlock forNSeconds:(NSInteger)seconds;


- (IMAPAccount*)account1;
- (IMAPAccount*)account2;

- (IMAPAccountSetting*)accountSetting1;
- (IMAPAccountSetting*)accountSetting2;

- (NSString*)keyLabel1;
- (NSString*)keyLabel2;



@end
