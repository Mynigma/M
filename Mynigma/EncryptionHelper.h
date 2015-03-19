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

@class EmailMessage, EncryptionEngine, MynigmaControlMessage, MynigmaDeclaration, MynigmaMessage, IMAPAccountSetting, FileAttachment, MynigmaFeedback;

@interface EncryptionHelper : NSObject

#pragma mark -
#pragma mark HASHING

//sign some (already hashed) data using RSA
+ (NSData*)signHash:(NSData*)mHash withKeyWithLabel:(NSString*)keyLabel withFeedback:(MynigmaFeedback**)feedback;

+ (MynigmaFeedback*)verifySignature:(NSData*)signatureData ofHash:(NSData*)hashedData version:(NSString*)version withKeyLabel:(NSString*)keyLabel;




#pragma mark -
#pragma mark ENCRYPTION & DECRYPTION

//takes an unencrypted MynigmaMessage object and parses it into an encrypted NSData object that can be attached to a secure message
+ (void)asyncEncryptMessage:(NSManagedObjectID *)messageID withSignatureKeyLabel:(NSString *)signKeyLabel expectedSignatureKeyLabels:(NSArray*)expectedLabels encryptionKeyLabels:(NSArray *)encryptionKeyLabels andCallback:(void (^)(MynigmaFeedback*))successCallback;


//decrypts the data and fills a blank MynigmaMessage object with the decrypted values - then executes the callback with a success/error status code
+ (void)asyncDecryptMessage:(NSManagedObjectID*)message fromData:(NSData*)data withCallback:(void(^)(MynigmaFeedback*))callback;

//decrypts an attachment and puts the decrypted data into its data property - then executes the callback with a win/epic fail story
+ (void)asyncDecryptFileAttachment:(NSManagedObjectID*)attachmentID withCallback:(void(^)(NSData* data, MynigmaFeedback* feedback))callback;




#pragma mark -
#pragma mark KEY PAIR GENERATION

+ (void)ensureValidCurrentKeyPairForAccount:(IMAPAccountSetting*)accountSetting withCallback:(void(^)(BOOL))callback;
+ (void)ensureValidCurrentKeyPairForAccount:(IMAPAccountSetting*)accountSetting lookInKeychain:(BOOL)alsoCheckKeychain withCallback:(void(^)(BOOL))callback;

+ (void)freshCurrentKeyPairForAccount:(IMAPAccountSetting*)accountSetting withCallback:(void(^)(BOOL))callback;


//#pragma mark -
//#pragma mark TESTING
//
//+ (BOOL)syncEncryptMessageForTesting:(MynigmaMessage*)message withSignatureKeyLabel:(NSString *)signKeyLabel expectedKeyLabels:(NSArray*)expectedKeyLabels encryptionKeyLabels:(NSArray*)encryptionKeyLabels inContext:(NSManagedObjectContext*)localContext;
//
//+ (BOOL)syncDecryptMessageForTesting:(NSData*)data intoMessage:(MynigmaMessage*)message inContext:(NSManagedObjectContext*)localContext;
//
//+ (BOOL)syncDecryptAttachmentForTesting:(FileAttachment*)fileAttachment inContext:(NSManagedObjectContext*)localContext
//;


@end
