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





#import "PrivateKeychain.h"
#import "MynigmaPrivateKey.h"
#import "MynigmaPublicKey.h"



@implementation PrivateKeychain


- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}


+ (id)sharedInstance
{
    static dispatch_once_t p = 0;

    __strong static id sharedObject = nil;

    dispatch_once(&p, ^{
        sharedObject = [PrivateKeychain new];
    });

    return sharedObject;
}


#pragma mark - PUBLIC KEYS

+ (BOOL)addPublicKeyToKeychainWithEncData:(NSData*)encData verData:(NSData*)verData andMynigmaPublicKey:(MynigmaPublicKey*)publicKey
{
    return NO;
}

+ (BOOL)havePublicKeychainItemWithLabel:(NSString*)keyLabel
{
    return NO;
}

+ (BOOL)removePublicKeychainItemWithLabel:(NSString*)keyLabel
{
    return NO;
}

+ (BOOL)doesPublicKeychainItemWithLabel:(NSString*)keyLabel matchEncData:(NSData*)encData andVerData:(NSData*)verData
{
    return NO;
}

+ (NSArray*)dataForPublicKeychainItemWithLabel:(NSString*)keyLabel
{
    return nil;
}

+ (NSArray*)persistentRefsForPublicKeychainItemWithLabel:(NSString*)keyLabel
{
    return nil;
}


#pragma mark - PRIVATE KEYS

+ (BOOL)addPrivateKeyToKeychainWithEncData:(NSData*)encData verData:(NSData*)verData decData:(NSData*)decData sigData:(NSData*)sigData andPrivateKey:(MynigmaPrivateKey*)keyPair
{
    return NO;
}

+ (BOOL)havePrivateKeychainItemWithLabel:(NSString*)keyLabel
{
    return NO;
}

+ (BOOL)removePrivateKeychainItemWithLabel:(NSString*)keyLabel
{
    return NO;
}

+ (BOOL)doesPrivateKeychainItemWithLabel:(NSString*)keyLabel matchDecData:(NSData*)decData sigData:(NSData*)sigData encData:(NSData*)encData verData:(NSData*)verData
{
    return NO;
}

+ (NSArray*)dataForPrivateKeychainItemWithLabel:(NSString*)keyLabel
{
    return nil;
}

+ (NSArray*)persistentRefsForPrivateKeychainItemWithLabel:(NSString*)keyLabel
{
    return nil;
}



#if TARGET_OS_IPHONE
+ (void)deleteAllKeys
{

}
#endif




@end
