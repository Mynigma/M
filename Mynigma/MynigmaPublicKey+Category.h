//Copyright © 2012 - 2015 Roman Priebe
//
//This file is part of M - Safe email made simple.
//
//M is free software: you can redistribute it and/or modify
//it under the terms of the GNU General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.
//
//M is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU General Public License
//along with M.  If not, see <http://www.gnu.org/licenses/>.
//



#import "MynigmaPublicKey.h"



@class MynigmaDevice;

@interface MynigmaPublicKey (Category)



#pragma mark - INDEXING

+ (void)compilePublicKeyIndex;




#pragma mark - ACCESS CURRENT KEY BY EMAIL FROM MAIN CONTEXT

+ (BOOL)havePublicKeyForEmailAddress:(NSString*)email;


+ (NSString*)publicKeyLabelForEmailAddress:(NSString*)emailAddress;





#pragma mark - ACCESS KEYS BY LABEL

+ (BOOL)havePublicKeyWithLabel:(NSString*)keyLabel;


+ (void)asyncMakeNewPublicKeyWithEncKeyData:(NSData*)encKeyData andVerKeyData:(NSData*)verKeyData forEmail:(NSString*)email keyLabel:(NSString*)keyLabel callback:(void(^)(void))callback;


//+ (MynigmaPublicKey*)syncMakeNewPublicKeyWithEncKeyData:(NSData*)encKeyData andVerKeyData:(NSData*)verKeyData forEmail:(NSString*)email keyLabel:(NSString*)keyLabel inContext:(NSManagedObjectContext*)keyContext;

+ (void)syncMakeNewPublicKeyWithEncKeyData:(NSData*)encKeyData andVerKeyData:(NSData*)verKeyData forEmail:(NSString*)email keyLabel:(NSString*)keyLabel;

+ (void)syncMakeNewPublicKeyWithEncKeyData:(NSData*)encKeyData andVerKeyData:(NSData*)verKeyData forDeviceWithUUID:(NSString*)deviceUUID keyLabel:(NSString*)keyLabel;

+ (MynigmaPublicKey*)syncMakeNewPublicKeyWithEncKeyData:(NSData*)encKeyData andVerKeyData:(NSData*)verKeyData forDevice:(MynigmaDevice*)device keyLabel:(NSString*)keyLabel inContext:(NSManagedObjectContext*)keyContext;


#pragma mark - RAW DATA

+ (NSArray*)dataForExistingMynigmaPublicKeyWithLabel:(NSString*)keyLabel;



#pragma mark - Keychain items

+ (BOOL)syncUpdateKeychainRefsForKeyWithLabel:(NSString*)keyLabel encRef:(NSData*)encRef verRef:(NSData*)verRef;

+ (void)asyncUpdateKeychainRefsForKeyWithLabel:(NSString*)keyLabel encRef:(NSData*)encRef verRef:(NSData*)verRef withCallback:(void(^)(void))callback;


+ (SecKeyRef)publicSecKeyRefWithLabel:(NSString*)keyLabel forEncryption:(BOOL)forEncryption;




#pragma mark - RECIPIENTS CONVENIENCE FUNCTIONS

//these use the currentKeyForEmail method to provide the public key labels for a list of recipients
+ (NSArray*)encryptionKeyLabelsForRecipients:(NSArray*)recipients;

//if allow errors is set to NO (default) the method will return nil if there is a problem with any of the recipients (such as no public key found, core data error, etc...)
+ (NSArray*)encryptionKeyLabelsForRecipients:(NSArray*)recipients allowErrors:(BOOL)allowErrors;

+ (NSArray*)introductionOriginKeyLabelsForRecipients:(NSArray*)recipients;

+ (NSArray*)introductionOriginKeyLabelsForRecipients:(NSArray*)recipients allowErrors:(BOOL)allowErrors;

+ (BOOL)isKeyWithLabel:(NSString*)keyLabel validForSignatureFromEmail:(NSString*)emailString;

+ (BOOL)wasKeyWithLabel:(NSString*)keyLabel previouslyValidForSignatureFromEmail:(NSString*)emailString;

+ (BOOL)isKeyWithLabelCurrentKeyForSomeEmailAddress:(NSString*)keyLabel;



+ (NSString*)fingerprintForKeyWithLabel:(NSString*)label;

//+ (void)markAsCompromisedKeyWithLabel:(



@end
