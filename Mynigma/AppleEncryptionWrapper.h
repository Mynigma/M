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


@class MynigmaFeedback, SessionKeys;


@interface AppleEncryptionWrapper : NSObject


#pragma mark - HASHING

//hash some data using SHA-512
+ (NSData*)SHA512DigestOfData:(NSData*)data;
+ (NSData*)SHA256DigestOfData:(NSData*)data;

//truncated SHA-512 hash of data
//formatted as five chunks of strings with four characters each
+ (NSArray*)shortDigestChunksOfData:(NSData*)data;

+ (NSString*)nonUniqueIDForEmailAddress:(NSString*)emailAddress;

#pragma mark - AES IMPLEMENTATION

//encrypt a block of data using AES with 256 bit key in CBC mode with random IV (sessionKeyData contains the raw data of the key)
+ (NSData*)AESencryptData:(NSData*)data withSessionKeyData:(NSData*)sessionKeyData withFeedback:(MynigmaFeedback**)mynigmaFeedback;

+ (NSData*)AESencryptData:(NSData*)data withSessionKeyData:(NSData*)sessionKeyData IV:(NSData*)initialVector withFeedback:(MynigmaFeedback**)mynigmaFeedback;

//decrypts a block containing an IV followed by some data encrypted using AES with 256 bit key in CBC mode
+ (NSData*)AESdecryptData:(NSData*)data withSessionKeyData:(NSData*)sessionKeyData withFeedback:(MynigmaFeedback**)mynigmaFeedback;

+ (NSData*)generateNewAESSessionKeyData;

+ (NSData*)generateNewHMACSecret;


#pragma mark - RSA IMPLEMENTATION

+ (NSData*)LEGACY_RSAdecryptData:(NSData*)data withPrivateKeyLabel:(NSString*)keylabel withFeedback:(MynigmaFeedback**)mynigmaFeedback;
+ (SessionKeys*)RSAdecryptData:(NSData*)data withPrivateKeyLabel:(NSString*)keyLabel withFeedback:(MynigmaFeedback**)mynigmaFeedback;

+ (NSData*)RSAencryptData:(NSData*)data withPublicKeyLabel:(NSString*)keylabel withFeedback:(MynigmaFeedback**)mynigmaFeedback;

+ (NSData*)RSASignHash:(NSData*)mHash withKeyLabel:(NSString*)keylabel withFeedback:(MynigmaFeedback**)mynigmaFeedback;

+ (MynigmaFeedback*)RSAVerifySignature:(NSData*)signature ofHash:(NSData*)dataHash version:(NSString*)version withKeyLabel:(NSString*)keyLabel;

//+ (BOOL)LEGACY_RSAverifySignature:(NSData*)signature ofHash:(NSData*)dataHash withKeyLabel:(NSString*)keyLabel;



+ (NSData*)HMACForMessage:(NSData *)message withSecret:(NSData *)secret;


+ (NSData*)randomBytesOfLength:(NSInteger)length;


/**Generates a new RSA key pair, puts it into the keychain and returns the keyLabel together with persistent references to the respective keychain items*/
+ (void)generateNewPrivateKeyPairForEmailAddress:(NSString*)email withCallback:(void(^)(NSString* keyLabel, NSData* encPersRef, NSData* verPersRef, NSData* decPersRef, NSData* sigPersRef))callback;

+ (void)generateNewPrivateKeyPairWithKeyLabel:(NSString*)keyLabel withCallback:(void(^)(NSString* keyLabel, NSData* encPersRef, NSData* verPersRef, NSData* decPersRef, NSData* sigPersRef))callback;


@end
