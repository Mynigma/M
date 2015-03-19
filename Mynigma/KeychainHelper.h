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


@class MynigmaPrivateKey, MynigmaPublicKey, IMAPAccountSetting;

@interface KeychainHelper : NSObject


#pragma mark - UUID

+ (NSString*)fetchUUIDFromKeychain;

+ (BOOL)saveUUIDToKeychain:(NSString*)UUID;


#pragma mark - PASSWORDS

+ (NSString*)passwordForPersistentRef:(NSData*)persistentRef;

+ (NSArray*)listLocalKeychainItems;

//when the user enters his email address into the setup dialogue this method is called to check if an appropriate password is already stored in the login keychain
+ (NSString*)findPasswordForEmail:(NSString*)email andServer:(NSString*)server;

//looks in mynigma keychain for password associated with account
+ (NSString*)findPasswordForAccount:(NSManagedObjectID*)accountSettingID incoming:(BOOL)isIncoming;

//upon adding an account, this will create appropriate entries in the keychain
+ (BOOL)savePassword:(NSString*)password forAccount:(NSManagedObjectID*)accountSettingID incoming:(BOOL)isIncoming;

+ (void)saveAsyncPassword:(NSString*)password forAccountSetting:(IMAPAccountSetting*)accountSetting incoming:(BOOL)isIncoming withCallback:(void(^)(BOOL success))callback;

+ (BOOL)haveKeychainPasswordForEmail:(NSString*)email andServer:(NSString*)server;

//removes the password stored for the specified account
+ (BOOL)removePasswordForAccount:(NSManagedObjectID*)accountSettingID incoming:(BOOL)isIncoming;


//a list of all public keys in the keychain
//including presistent references
+ (NSArray*)listPublicKeychainItems;

//excluding persistent references
+ (NSArray*)listPublicKeychainProperties;


//a list of all private keys in the keychain
//including presistent references
+ (NSArray*)listPrivateKeychainItems;

//excluding persistent references
+ (NSArray*)listPrivateKeychainProperties;


+ (void)dumpEntireKeychainToConsole;


#pragma mark - PUBLIC KEYS

+ (void)fetchAllKeysFromKeychainWithCallback:(void(^)(void))callback;

+ (NSArray*)addPublicKeyWithLabel:(NSString*)keyLabel toKeychainWithEncData:(NSData*)encData verData:(NSData*)verData;

+ (BOOL)havePublicKeychainItemWithLabel:(NSString*)keyLabel;

+ (BOOL)removePublicKeychainItemWithLabel:(NSString*)keyLabel;

+ (BOOL)doesPublicKeychainItemWithLabel:(NSString*)keyLabel matchEncData:(NSData*)encData andVerData:(NSData*)verData;

+ (NSArray*)dataForPublicKeychainItemWithLabel:(NSString*)keyLabel;

+ (NSArray*)persistentRefsForPublicKeychainItemWithLabel:(NSString*)keyLabel;


#pragma mark - PRIVATE KEYS

+ (NSArray*)addPrivateKeyWithLabel:(NSString*)keyLabel toKeychainWithEncData:(NSData*)encData verData:(NSData*)verData decData:(NSData*)decData sigData:(NSData*)sigData;

+ (NSArray*)addPrivateKeyWithLabel:(NSString*)keyLabel toKeychainWithEncData:(NSData*)encData verData:(NSData*)verData decData:(NSData*)decData sigData:(NSData*)sigData passphrase:(NSString*)passphrase;

+ (BOOL)havePrivateKeychainItemWithLabel:(NSString*)keyLabel;

+ (BOOL)removePrivateKeychainItemWithLabel:(NSString*)keyLabel;

+ (BOOL)doesPrivateKeychainItemWithLabel:(NSString*)keyLabel matchDecData:(NSData*)decData sigData:(NSData*)sigData encData:(NSData*)encData verData:(NSData*)verData;

+ (NSArray*)dataForPrivateKeychainItemWithLabel:(NSString*)keyLabel;

+ (NSArray*)dataForPrivateKeychainItemWithLabel:(NSString*)keyLabel passphrase:(NSString*)passphrase;

+ (NSArray*)persistentRefsForPrivateKeychainItemWithLabel:(NSString*)keyLabel;



#pragma mark - GENERIC

+ (NSData*)dataForPersistentRef:(NSData*)persistentRef;

+ (NSData*)dataForPersistentRef:(NSData*)persistentRef withPassphrase:(NSString*)passphrase;

+ (SecKeyRef)keyRefForPersistentRef:(NSData*)persistentRef;

#if TARGET_OS_IPHONE
+ (void)deleteAllKeys;
#endif



+ (NSData*)rawDataExportPrivateKeyWithLabel:(NSString*)keyLabel;

+ (BOOL)importPrivateKeyRawData:(NSData*)data withLabel:(NSString*)keyLabel;



@end
