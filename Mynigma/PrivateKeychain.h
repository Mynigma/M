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

@class MynigmaPrivateKey, MynigmaPublicKey;

@interface PrivateKeychain : NSObject
{
    NSData* symmetricWrapKeyPersistentRef;
}

#pragma mark - PUBLIC KEYS

+ (BOOL)addPublicKeyToKeychainWithEncData:(NSData*)encData verData:(NSData*)verData andMynigmaPublicKey:(MynigmaPublicKey*)publicKey;

+ (BOOL)havePublicKeychainItemWithLabel:(NSString*)keyLabel;

+ (BOOL)removePublicKeychainItemWithLabel:(NSString*)keyLabel;

+ (BOOL)doesPublicKeychainItemWithLabel:(NSString*)keyLabel matchEncData:(NSData*)encData andVerData:(NSData*)verData;

+ (NSArray*)dataForPublicKeychainItemWithLabel:(NSString*)keyLabel;

+ (NSArray*)persistentRefsForPublicKeychainItemWithLabel:(NSString*)keyLabel;


#pragma mark - PRIVATE KEYS

+ (BOOL)addPrivateKeyToKeychainWithEncData:(NSData*)encData verData:(NSData*)verData decData:(NSData*)decData sigData:(NSData*)sigData andPrivateKey:(MynigmaPrivateKey*)keyPair;

+ (BOOL)havePrivateKeychainItemWithLabel:(NSString*)keyLabel;

+ (BOOL)removePrivateKeychainItemWithLabel:(NSString*)keyLabel;

+ (BOOL)doesPrivateKeychainItemWithLabel:(NSString*)keyLabel matchDecData:(NSData*)decData sigData:(NSData*)sigData encData:(NSData*)encData verData:(NSData*)verData;

+ (NSArray*)dataForPrivateKeychainItemWithLabel:(NSString*)keyLabel;

+ (NSArray*)persistentRefsForPrivateKeychainItemWithLabel:(NSString*)keyLabel;




#if TARGET_OS_IPHONE
+ (void)deleteAllKeys;
#endif


@end
