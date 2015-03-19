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





#import "MynigmaPrivateKey.h"

@class EmailMessage;

@interface MynigmaPrivateKey (Category)




#pragma mark - Key by email address

//checks if there is a private key associated with the given email address
//used to check if a sender email will be safe
+ (BOOL)havePrivateKeyForEmailAddress:(NSString*)emailAddress;

//returns the private key associated with this email address
+ (NSString*)privateKeyLabelForEmailAddress:(NSString*)emailAddress;


#pragma mark - Key by label

+ (BOOL)havePrivateKeyWithLabel:(NSString*)keyLabel;

+ (NSString*)senderKeyLabelForMessage:(EmailMessage*)message;


#pragma mark - Raw data

+ (NSArray*)dataForPrivateKeyWithLabel:(NSString*)keyLabel;

+ (NSArray*)dataForPrivateKeyWithLabel:(NSString*)keyLabel passphrase:(NSString*)passphrase;


#pragma mark - Keychain refs

+ (BOOL)syncUpdateKeychainRefsForKeyWithLabel:(NSString*)keyLabel encRef:(NSData*)encRef verRef:(NSData*)verRef decRef:(NSData*)decRef sigRef:(NSData*)sigRef;

+ (void)asyncUpdateKeychainRefsForKeyWithLabel:(NSString*)keyLabel encRef:(NSData*)encRef verRef:(NSData*)verRef decRef:(NSData*)decRef sigRef:(NSData*)sigRef withCallback:(void(^)(void))callback;

//return the SecKeyRef for the key with the specified label
+ (SecKeyRef)privateSecKeyRefWithLabel:(NSString*)keyLabel forEncryption:(BOOL)forEncryption;



#pragma mark - Key creation & generation

+ (void)waitUntilDeviceKeyIsGeneratedForDeviceWithUUID:(NSString*)deviceUUID andThenCall:(NSInvocation*)invocation;

+ (void)asyncCreateNewMynigmaPrivateKeyForEmail:(NSString*)emailAddress withCallback:(void(^)(void))callback;

+ (void)asyncMakeNewPrivateKeyWithLabel:(NSString*)keyLabel forEmail:(NSString*)emailAddress withDecRef:(NSData*)decRef andSigRef:(NSData*)sigRef andEncRef:(NSData*)encRef andVerRef:(NSData*)verRef makeCurrentKey:(BOOL)makeCurrentKey dateCreated:(NSDate*)dateCreated isCompromised:(BOOL)isCompromised withCallback:(void(^)(void))callback;

+ (MynigmaPrivateKey*)syncMakeNewPrivateKeyWithEncKeyData:(NSData*)encData andVerKeyData:(NSData*)verData decKeyData:(NSData*)decData sigKeyData:(NSData*)sigData forEmail:(NSString*)email keyLabel:(NSString*)keyLabel inContext:(NSManagedObjectContext*)keyContext;

+ (void)syncMakeNewPrivateKeyWithEncData:(NSData*)encData andVerKeyData:(NSData*)verData decKeyData:(NSData*)decData sigKeyData:(NSData*)sigData forEmail:(NSString*)email keyLabel:(NSString*)keyLabel;


//+ (void)asyncMakeNewPrivateKeyWithLabel:(NSString*)keyLabel forEmail:(NSString*)emailAddress withDecRef:(NSData*)decRef andSigRef:(NSData*)sigRef andEncRef:(NSData*)encRef andVerRef:(NSData*)verRef makeCurrentKey:(BOOL)makeCurrentKey withCallback:(void(^)(void))callback;


@end
