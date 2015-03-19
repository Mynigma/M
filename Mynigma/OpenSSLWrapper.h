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



@class MynigmaFeedback;


@interface OpenSSLWrapper : NSObject

+ (NSData*)DERFileFromPEMKey:(NSData*)PEMData withPassphrase:(NSString*)passphrase;

+ (NSData*)PKCS12FileFromPKCS8Key:(NSData*)PKCS8Data withPassphrase:(NSString*)passphrase;



+ (BOOL)verifySignature:(NSData*)signature ofHash:(NSData*)dataHash withKeyLabel:(NSString*)keyLabel;

+ (NSData*)signHash:(NSData*)mHash withKeyWithLabel:(NSString*)keyLabel;


+ (NSData*)RSAencryptData:(NSData*)data withPublicKeyWithLabel:(NSString*)keyLabel;

+ (NSData*)RSAdecryptData:(NSData*)data withPublicKeyWithLabel:(NSString*)keyLabel;


+ (MynigmaFeedback*)PSS_RSAverifySignature:(NSData*)signature ofHash:(NSData*)dataHash withKeyLabel:(NSString*)keyLabel;

+ (NSData*)PSS_RSAsignHash:(NSData*)mHash withKeyWithLabel:(NSString*)keyLabel withFeedback:(MynigmaFeedback**)mynigmaFeedback;









+ (NSArray*)generateRSAKeyPairData;

+ (NSData*)HMACForMessage:(NSData*)message withSecret:(NSData*)secret;

+ (void)generateNewPrivateKeyPairWithKeyLabel:(NSString*)keyLabel withCallback:(void(^)(NSString* keyLabel, NSData* encPersRef, NSData* verPersRef, NSData* decPersRef, NSData* sigPersRef))callback;



#pragma mark - Cryptographic Message Syntax (CMS) & S/MIME

+ (NSData*)encryptData:(NSData*)data withPublicKeyLabels:(NSArray*)publicKeyLabels error:(NSError**)error;
+ (NSData*)decryptData:(NSData*)data withKeyLabel:(NSString*)keyLabel error:(NSError**)error;

+ (NSData*)signData:(NSData*)data withPrivateKeyLabel:(NSString*)keyLabel error:(NSError**)error;
+ (NSData*)verifySignedData:(NSData*)data withPublicKeyLabel:(NSString*)keyLabel error:(NSError**)error;



#pragma mark - Importing S/MIME keys

//+ (BOOL)importSMIMEKeyFromData:(NSData*)fileData error:(NSError**)error;


@end
