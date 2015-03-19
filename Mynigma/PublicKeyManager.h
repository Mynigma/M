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

@class MynigmaPublicKey, Recipient, MynigmaPrivateKey;


@interface PublicKeyManager : NSObject

#if ULTIMATE

#pragma mark -
#pragma mark HANDLING OF SERVER RESPONSES

+ (void)serverSaysAddKey:(NSArray*)record forEmailAddress:(NSString*)email;

+ (void)serverSaysReplaceKey:(NSArray*)record forEmailAddress:(NSString*)email;

+ (void)serverSaysRevokeKey:(NSArray*)record forEmailAddress:(NSString*)email;

+ (BOOL)typedRecipient:(Recipient*)recipient quickCheckWithCallback:(void(^)(BOOL found))callback;

#endif



#pragma mark - PUBLIC KEY INQUIRIES

//the label of the user's own public key that was used to encrypt the most recent message from the specified sender
+ (NSString*)mostRecentOwnKeyLabelUsedBySender:(NSString*)emailAddress;




#pragma mark - LISTING KEYS

+ (NSArray*)listAllPublicKeys;

+ (NSArray*)listAllPrivateKeys;



//#pragma mark - DATA METHODS
//
//+ (NSArray*)dataForExistingMynigmaPublicKeyWithLabel:(NSString*)keyLabel;
//
//+ (NSArray*)dataForExistingMynigmaPrivateKeyWithLabel:(NSString*)keyLabel;
//
//+ (NSArray*)dataForExistingMynigmaPrivateKeyWithLabel:(NSString*)keyLabel passphrase:(NSString*)passphrase;



#pragma mark - KEY ADDITION



#pragma mark - INTRODUCTION PARSING

//parses a key introduction from one private key to another - it wraps up both labels and the new public key, then signs the entire package
+ (NSData*)introductionDataFromKeyLabel:(NSString*)fromLabel toKeyLabel:(NSString*)toLabel;

+ (BOOL)processIntroductionData:(NSData*)introductionData fromEmail:(NSString*)senderEmailString toEmails:(NSArray*)recipientEmails;



#pragma mark - KEY DELETION

/**CANNOT BE UNDONE(!!) - HANDLE WITH CARE*/
//+ (BOOL)removePublicKeyWithLabel:(NSString*)publicKeyLabel alsoRemoveFromKeychain:(BOOL)alsoRemoveFromKeychain;

/**CANNOT BE UNDONE(!!) - HANDLE WITH CARE*/
//+ (BOOL)removeKeyPairWithLabel:(NSString*)keyPairLabel alsoRemoveFromKeychain:(BOOL)alsoRemoveFromKeychain;


//+ (NSString*)currentPublicKeyLabelForEmail:(NSString*)emailAddress;


#pragma mark - EXTRA HEADER REPRESENTATION

+ (NSString*)headerRepresentationOfPublicKeyWithLabel:(NSString*)keyLabel;

+ (void)handleHeaderRepresentationOfPublicKey:(NSString*)headerString withKeyLabel:(NSString*)keyLabel fromEmail:(NSString*)senderEmail;


//+ (NSString*)emailForKeyLabel:(NSString*)keyLabel;

+ (void)addMynigmaInfoPublicKey;

+ (BOOL)addMynigmaInfoPublicKeyInContext:(NSManagedObjectContext*)localContext;

@end
