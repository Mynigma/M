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





#import "MynigmaPublicKey+Category.h"
#import "EmailContactDetail+Category.h"
#import "MynigmaDeclaration.h"
#import "AppDelegate.h"

#import "KeychainHelper.h"
#import "MynigmaPrivateKey+Category.h"
#import "PublicKeyManager.h"
#import "EmailRecipient.h"
#import "Recipient.h"
#import "NSString+EmailAddresses.h"
#import "EmailAddress+Category.h"
#import "AddressDataHelper.h"
#import "KeyExpectation+Category.h"
#import "MynigmaDevice+Category.h"
#import "AppleEncryptionWrapper.h"
#import "NSData+Base64.h"



@interface KeyExpectation()

//key to be used for introduction of the actual signature key when sending a message
+ (MynigmaPrivateKey*)signatureKeyForIntroductionFrom:(EmailAddress*)fromAddress to:(EmailAddress*)toAddress inContext:(NSManagedObjectContext*)keyContext;


//key to be used to sign messages from fromAddress to toAddress
+ (MynigmaPrivateKey*)signatureKeyForMessageFrom:(EmailAddress*)fromAddress;


//key to be used for encryption when sending a message
+ (MynigmaPublicKey*)encryptionKeyForMessageTo:(EmailAddress*)toAddress;


@end



@interface EmailAddress()

+ (EmailAddress*)emailAddressForEmail:(NSString*)emailString inContext:(NSManagedObjectContext*)keyContext;

+ (EmailAddress*)emailAddressForEmail:(NSString*)emailString inContext:(NSManagedObjectContext*)keyContext makeIfNecessary:(BOOL)shouldCreate;

@end


@interface MynigmaPrivateKey()

+ (MynigmaPrivateKey*)syncMakeNewPrivateKeyWithLabel:(NSString*)keyLabel forEmail:(NSString*)emailString withDecRef:(NSData*)decRef andSigRef:(NSData*)sigRef andEncRef:(NSData*)encRef andVerRef:(NSData*)verRef dateCreated:(NSDate*)dateCreated isCompromised:(BOOL)isCompromised makeCurrentKey:(BOOL)makeCurrentKey inContext:(NSManagedObjectContext*)keyContext;

@end


@implementation MynigmaPublicKey (Category)


//dictionary mapping keyLabels to keys
static NSMutableDictionary* publicKeyIndex;

//set to YES when the dictionary has been populated
static BOOL haveCompiledPublicKeyIndex = NO;

//private dispatch queue reserved for access to the publicKeyIndex
static dispatch_queue_t publicKeyIndexQueue;




//static BOOL haveFetchedAllKeysFromKeychain = NO;

+ (BOOL)haveCompiledKeyIndex
{
    return haveCompiledPublicKeyIndex;
}

+ (NSMutableDictionary*)keyIndex
{
    if(!publicKeyIndex)
        publicKeyIndex = [NSMutableDictionary new];

    return publicKeyIndex;
}

+ (dispatch_queue_t)keyIndexQueue
{
    if(!publicKeyIndexQueue)
        publicKeyIndexQueue = dispatch_queue_create("org.mynigma.publicKeyIndexQueue", NULL);

    return publicKeyIndexQueue;
}


#pragma mark - INDEXING


+ (void)compilePublicKeyIndex
{
    haveCompiledPublicKeyIndex = NO;

    [EmailAddress compileEmailIndex];

    [ThreadHelper runAsyncOnKeyContext:^{

        //fetch all public keys
        NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MynigmaPublicKey"];

        NSDictionary* properties = [[NSEntityDescription entityForName:@"MynigmaPublicKey" inManagedObjectContext:KEY_CONTEXT] propertiesByName];

        NSPropertyDescription* emailAddressProperty = [properties objectForKey:@"keyLabel"];

        NSExpressionDescription* objectIDProperty = [NSExpressionDescription new];
        objectIDProperty.name = @"objectID";
        objectIDProperty.expression = [NSExpression expressionForEvaluatedObject];
        objectIDProperty.expressionResultType = NSObjectIDAttributeType;

        [fetchRequest setPropertiesToFetch:@[emailAddressProperty, objectIDProperty]];
        [fetchRequest setReturnsDistinctResults:YES];
        [fetchRequest setResultType:NSDictionaryResultType];

        NSError* error = nil;
        NSArray* results = [KEY_CONTEXT executeFetchRequest:fetchRequest error:&error];
        if(error)
        {
            NSLog(@"Error fetching messages array!!!");
        }

        for(NSDictionary* publicKeyDict in results)
        {
            NSString* keyLabel = publicKeyDict[@"keyLabel"];

            NSManagedObjectID* objectID = publicKeyDict[@"objectID"];

            if(objectID.isTemporaryID)
            {
                NSLog(@"Fetched objectID for public key is temporary(!!) %@", objectID);
                continue;
            }

            if(keyLabel && objectID)
            {
                dispatch_sync([MynigmaPublicKey keyIndexQueue], ^{

                    NSManagedObjectID* existingObjectID = [[MynigmaPublicKey keyIndex] objectForKey:keyLabel];

                    //give preference to private keys
                    if(!existingObjectID || ([existingObjectID.entity.name isEqualToString:@"MynigmaPublicKey"] && [objectID.entity.name isEqualToString:@"MynigmaPrivateKey"]))
                        [[MynigmaPublicKey keyIndex] setObject:objectID forKey:keyLabel];
                });
            }
        }

        error = nil;

        [KEY_CONTEXT save:&error];

        if(error)
        {
            NSLog(@"Error saving key context after compiling index! %@", error);
        }

        [CoreDataHelper save];


        haveCompiledPublicKeyIndex = YES;

        NSLog(@"Done compiling public key index");

//        [KeychainHelper fetchAllKeysFromKeychainWithCallback:^{
//
//            NSLog(@"Fetched all keys from keychain");
//        }];
    }];
}







#pragma mark - CORE DATA STORE (PRIVATE METHODS)


///**Creates a new public key with the given keyLabel and data (DOES NOT CHECK IF THERE IS AN EXISTING KEY - PRIVATE METHOD)*/
//+ (MynigmaPublicKey*)syncMakeNewPublicKeyWithLabel:(NSString*)keyLabel forEmail:(NSString*)emailString withEncRef:(NSData*)encRef andVerRef:(NSData*)verRef makeCurrentKey:(BOOL)makeCurrentKey inContext:(NSManagedObjectContext*)keyContext
//{
//    if(!keyLabel)
//        return nil;
//
//    emailString = [emailString canonicalForm];
//
//    NSEntityDescription* entityDescription = [NSEntityDescription entityForName:@"MynigmaPublicKey" inManagedObjectContext:keyContext];
//    MynigmaPublicKey* publicKey = [[MynigmaPublicKey alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:keyContext];
//
//    [publicKey setKeyLabel:keyLabel];
//
//    [publicKey setPublicEncrKeyRef:encRef];
//    [publicKey setPublicVerifyKeyRef:verRef];
//
//    [publicKey setIsCompromised:@NO];
//
//    [publicKey associateKeyWithEmail:emailString forceMakeCurrent:makeCurrentKey inContext:keyContext];
//
//    [publicKey setIsCompromised:@NO];
//
//    [publicKey setDateCreated:[NSDate date]];
//
//    [publicKey setVersion:MYNIGMA_VERSION];
//
//    [publicKey setEmailAddress:emailString];
//
//    NSError* error = nil;
//
//    [keyContext obtainPermanentIDsForObjects:@[publicKey] error:&error];
//
//    if(error)
//        NSLog(@"Error obtaining permanent ID for newly added public key: %@", error);
//
//    NSManagedObjectID* objectID = publicKey.objectID;
//
//    dispatch_sync([MynigmaPublicKey keyIndexQueue], ^{
//
//        publicKeyIndex[keyLabel] = objectID;
//    });
//
//
//    return publicKey;
//}



- (void)associateKeyWithEmail:(NSString*)emailString forceMakeCurrent:(BOOL)makeCurrent inContext:(NSManagedObjectContext*)keyContext
{
    if(!emailString.length)
        return;

    EmailAddress* emailAddress = [EmailAddress emailAddressForEmail:emailString inContext:keyContext makeIfNecessary:YES];

    //add this key to the list of keys associated with this email address
    [emailAddress addAllKeysObject:self];

    //if there is no current key or the forceMakeCurrent flag is set, make this the current key
    if(!emailAddress.currentKey || makeCurrent)
    {
        [emailAddress setCurrentKey:self];

        //the anchor date is important for synchronisation between devices
        //essentially, it's the date the key was first found
        //earlier anchor dates take precedence
        //the dates of messages are irrelevant, as headers can be spoofed
        [emailAddress setDateCurrentKeyAnchored:[NSDate date]];
    }
}






#pragma mark - ACCESS CURRENT KEY BY EMAIL

//+ (MynigmaPublicKey*)publicKeyForEmailAddress:(NSString*)emailString
//{
//    [ThreadHelper ensureMainThread];
//
//    emailString = [emailString canonicalForm];
//
//    EmailAddress* emailAddress = [EmailAddress main_emailAddressForEmail:emailString];
//
//    return emailAddress.currentKey;
//}

+ (BOOL)havePublicKeyForEmailAddress:(NSString*)emailString
{
    __block BOOL returnValue = NO;

    [ThreadHelper runSyncOnKeyContext:^(NSManagedObjectContext* keyContext) {

        EmailAddress* emailAddress = [EmailAddress emailAddressForEmail:emailString inContext:keyContext];

        MynigmaPublicKey* publicKey = (MynigmaPublicKey*)emailAddress.currentKey;

        if([publicKey isKindOfClass:[MynigmaPublicKey class]])
            returnValue = YES;
    }];

    return returnValue;
}

+ (NSString*)publicKeyLabelForEmailAddress:(NSString*)emailString
{
    __block NSString* returnValue = nil;

    [ThreadHelper runSyncOnKeyContext:^(NSManagedObjectContext* keyContext) {

        EmailAddress* emailAddress = [EmailAddress emailAddressForEmail:emailString inContext:keyContext];

        MynigmaPublicKey* publicKey = (MynigmaPublicKey*)emailAddress.currentKey;

        if([publicKey isKindOfClass:[MynigmaPublicKey class]])
            returnValue = publicKey.keyLabel;
    }];

    return returnValue;
}







+ (NSString*)keyLabelForSignatureIntroductionFrom:(NSString*)fromEmailString to:(NSString*)toEmailString
{
    if([[fromEmailString canonicalForm] isEqualToString:[toEmailString canonicalForm]])
        return [MynigmaPublicKey publicKeyLabelForEmailAddress:fromEmailString];

    __block NSString* returnValue = nil;

    [ThreadHelper runSyncOnKeyContext:^(NSManagedObjectContext *keyContext) {

        EmailAddress* fromAddress = [EmailAddress emailAddressForEmail:fromEmailString inContext:keyContext makeIfNecessary:YES];

        EmailAddress* toAddress = [EmailAddress emailAddressForEmail:toEmailString inContext:keyContext makeIfNecessary:YES];

        MynigmaPublicKey* publicKey = [KeyExpectation signatureKeyForIntroductionFrom:fromAddress to:toAddress inContext:keyContext];

        returnValue = publicKey.keyLabel;
    }];

    return returnValue;
}



#pragma mark - ACCESS KEYS BY LABEL



+ (BOOL)havePublicKeyWithLabel:(NSString*)keyLabel
{
    if(!keyLabel)
        return NO;

    __block BOOL returnValue = NO;

    if([MynigmaPublicKey haveCompiledKeyIndex])
    {
        dispatch_sync([MynigmaPublicKey keyIndexQueue], ^{

            NSManagedObjectID* keyObjectID = [MynigmaPublicKey keyIndex][keyLabel];

            returnValue = (keyObjectID != nil);
        });

        return returnValue;
    }
    else
    {
        //the index hasn't been compiled yet: run a fetch request
        [ThreadHelper runSyncOnKeyContext:^(NSManagedObjectContext *keyContext) {

            NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MynigmaPublicKey"];
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"keyLabel == %@",keyLabel]];
            NSError* error = nil;
            NSInteger numberOfKeys = [keyContext countForFetchRequest:fetchRequest error:&error];

            if(error)
                NSLog(@"Error trying to fetch mynigma private key");
            else
            {
                if(numberOfKeys>1)
                {
                    NSLog(@"More than one private key with label %@", keyLabel);
                }

                returnValue = numberOfKeys>0;
            }

        }];

        return returnValue;
    }
}


+ (void)asyncMakeNewPublicKeyWithEncKeyData:(NSData*)encKeyData andVerKeyData:(NSData*)verKeyData forEmail:(NSString*)email keyLabel:(NSString*)keyLabel callback:(void(^)(void))callback
{
    [ThreadHelper runAsyncOnKeyContext:^{

        [MynigmaPublicKey syncMakeNewPublicKeyWithEncKeyData:encKeyData andVerKeyData:verKeyData forEmail:email keyLabel:keyLabel inContext:KEY_CONTEXT];

        if(callback)
            callback();
    }];
}

+ (void)syncMakeNewPublicKeyWithEncKeyData:(NSData*)encKeyData andVerKeyData:(NSData*)verKeyData forEmail:(NSString*)email keyLabel:(NSString*)keyLabel
{
    [ThreadHelper runSyncOnKeyContext:^(NSManagedObjectContext *keyContext) {

        [MynigmaPublicKey syncMakeNewPublicKeyWithEncKeyData:encKeyData andVerKeyData:verKeyData forEmail:email keyLabel:keyLabel inContext:keyContext];
    }];
}

/**Creates a public key with the given data and label and returns it, provided that no conflicting key (same label, different data) exists*/
+ (MynigmaPublicKey*)syncMakeNewPublicKeyWithEncKeyData:(NSData*)encKeyData andVerKeyData:(NSData*)verKeyData forEmail:(NSString*)email keyLabel:(NSString*)keyLabel inContext:(NSManagedObjectContext*)keyContext
{
    if(!keyLabel || !encKeyData || !encKeyData)
    {
        NSLog(@"Cannot make new public key with label %@ and data %@, %@", keyLabel, encKeyData, verKeyData);
        return nil;
    }

    MynigmaPublicKey* publicKey = [MynigmaPublicKey publicKeyWithLabel:keyLabel inContext:keyContext];

    if(publicKey)
    {
        //already have a key - just compare it with the current data and return the existing key only if the data matches
        if([publicKey matchesEncData:encKeyData andVerData:verKeyData])
        {
            //don't forget to associate the key with the current email, if necessary
            [publicKey associateKeyWithEmail:email forceMakeCurrent:NO inContext:keyContext];

            return publicKey;
        }

        //no luck, the key doesn't match
        return nil;
    }
    else
    {
        //ok, no key with such a label exists so far. add a new one:

        //first deal with the keychain
        //we can't have zombie key objects wandering around
        //that don't have a corresponding item in the keychain
        NSArray* persistentRefs = nil;

        if([KeychainHelper havePublicKeychainItemWithLabel:keyLabel])
        {
            if([KeychainHelper doesPublicKeychainItemWithLabel:keyLabel matchEncData:encKeyData andVerData:verKeyData])
            {
                //if the key is actually a private key, it should be extracted from the keychain
                //don't add a public key, use a private key instead(!)
                if([KeychainHelper havePrivateKeychainItemWithLabel:keyLabel])
                {
                    persistentRefs = [KeychainHelper dataForPrivateKeychainItemWithLabel:keyLabel];
                    
                    if(persistentRefs.count != 4)
                        return nil;
                    
                    return [MynigmaPrivateKey syncMakeNewPrivateKeyWithEncKeyData:persistentRefs[2] andVerKeyData:persistentRefs[3] decKeyData:persistentRefs[0] sigKeyData:persistentRefs[1] forEmail:nil keyLabel:keyLabel inContext:keyContext];
                }
                
                persistentRefs = [KeychainHelper persistentRefsForPublicKeychainItemWithLabel:keyLabel];
            }
            else
            {
                NSLog(@"Trying to add public key that doesn't match the data already in the keychain!!");
                return nil;
            }
        }
        else
        {
            //add a fresh keychain item
            persistentRefs = [KeychainHelper addPublicKeyWithLabel:keyLabel toKeychainWithEncData:encKeyData verData:verKeyData];
        }

        if(persistentRefs.count == 2)
        {
            email = email.canonicalForm;

            NSEntityDescription* entityDescription = [NSEntityDescription entityForName:@"MynigmaPublicKey" inManagedObjectContext:keyContext];
            MynigmaPublicKey* publicKey = [[MynigmaPublicKey alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:keyContext];
            [publicKey setKeyLabel:keyLabel];
            [publicKey setIsCompromised:[NSNumber numberWithBool:NO]];
            [publicKey setEmailAddress:email];

            NSDate* date = [NSDate date];

            [publicKey setFirstAnchored:date];
            [publicKey setDateObtained:date];

            [publicKey setPublicEncrKeyRef:persistentRefs.firstObject];
            [publicKey setPublicVerifyKeyRef:persistentRefs.lastObject];

            [publicKey associateKeyWithEmail:email forceMakeCurrent:NO inContext:keyContext];

            NSError* error = nil;

            [keyContext obtainPermanentIDsForObjects:@[publicKey] error:&error];

            if(error)
            {
                NSLog(@"Error obtaining permanent objectID for new public key: %@", error);
            }

            error = nil;

            [keyContext save:&error];

            if(error)
            {
                NSLog(@"Error saving key context after adding key to keychain! %@", error);
            }

            [CoreDataHelper save];

            NSManagedObjectID* objectID = publicKey.objectID;

            if(keyLabel && objectID)
            {
                dispatch_sync([MynigmaPublicKey keyIndexQueue], ^{

                    NSManagedObjectID* existingObjectID = [[MynigmaPublicKey keyIndex] objectForKey:keyLabel];

                    //give preference to private keys
                    if(!existingObjectID || ([existingObjectID.entity.name isEqualToString:@"MynigmaPublicKey"] && [objectID.entity.name isEqualToString:@"MynigmaPrivateKey"]))
                        [[MynigmaPublicKey keyIndex] setObject:objectID forKey:keyLabel];
                });
            }

            return publicKey;
        }
        else
        {
            NSLog(@"Failed to add public key with label %@ and data %@, %@ to keychain!!!", keyLabel, encKeyData, verKeyData);
            return nil;
        }
    }
}


+ (void)syncMakeNewPublicKeyWithEncKeyData:(NSData*)encKeyData andVerKeyData:(NSData*)verKeyData forDeviceWithUUID:(NSString*)deviceUUID keyLabel:(NSString*)keyLabel
{
    [ThreadHelper runSyncOnKeyContext:^(NSManagedObjectContext *keyContext) {

        MynigmaDevice* device = [MynigmaDevice deviceWithUUID:deviceUUID addIfNotFound:YES inContext:keyContext];

        [MynigmaPublicKey syncMakeNewPublicKeyWithEncKeyData:encKeyData andVerKeyData:verKeyData forDevice:device keyLabel:keyLabel inContext:keyContext];
    }];
}


+ (MynigmaPublicKey*)syncMakeNewPublicKeyWithEncKeyData:(NSData*)encKeyData andVerKeyData:(NSData*)verKeyData forDevice:(MynigmaDevice*)device keyLabel:(NSString*)keyLabel inContext:(NSManagedObjectContext*)keyContext
{
    if(!keyLabel || !encKeyData || !encKeyData)
    {
        NSLog(@"Cannot make new public key with label %@ and data %@, %@", keyLabel, encKeyData, verKeyData);
        return nil;
    }

    MynigmaPublicKey* publicKey = [MynigmaPublicKey publicKeyWithLabel:keyLabel inContext:keyContext];

    if(publicKey)
    {
        //already have a key - just compare it with the current data and return the existing key only if the data matches
        if([publicKey matchesEncData:encKeyData andVerData:verKeyData])
            return publicKey;

        //no luck, the key doesn't match
        return nil;
    }
    else
    {
        //ok, no key with such a label exists so far. add a new one:

        //first deal with the keychain
        //we can't have zombie key objects wandering around
        //that don't have a corresponding item in the keychain
        NSArray* persistentRefs = nil;

        if([KeychainHelper havePublicKeychainItemWithLabel:keyLabel])
        {
            if([KeychainHelper doesPublicKeychainItemWithLabel:keyLabel matchEncData:encKeyData andVerData:verKeyData])
            {
                persistentRefs = [KeychainHelper persistentRefsForPublicKeychainItemWithLabel:keyLabel];
            }
            else
            {
                NSLog(@"Trying to add public key that doesn't match the data already in the keychain!!");
                return nil;
            }
        }
        else
        {
            //add a fresh keychain item
            persistentRefs = [KeychainHelper addPublicKeyWithLabel:keyLabel toKeychainWithEncData:encKeyData verData:verKeyData];
        }

        if(persistentRefs.count == 2)
        {
            NSEntityDescription* entityDescription = [NSEntityDescription entityForName:@"MynigmaPublicKey" inManagedObjectContext:keyContext];
            MynigmaPublicKey* publicKey = [[MynigmaPublicKey alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:keyContext];
            [publicKey setKeyLabel:keyLabel];
            [publicKey setIsCompromised:[NSNumber numberWithBool:NO]];

            [publicKey setPublicEncrKeyRef:persistentRefs.firstObject];
            [publicKey setPublicVerifyKeyRef:persistentRefs.lastObject];

            NSDate* date = [NSDate date];

            [publicKey setFirstAnchored:date];
            [publicKey setDateObtained:date];

            [publicKey addSyncKeyForDeviceObject:device];

            NSError* error = nil;

            [keyContext obtainPermanentIDsForObjects:@[publicKey] error:&error];

            if(error)
            {
                NSLog(@"Error obtaining permanent objectID for new public key: %@", error);
            }

            error = nil;

            [keyContext save:&error];

            if(error)
            {
                NSLog(@"Error saving key context after adding key to keychain! %@", error);
            }

            [CoreDataHelper save];

            NSManagedObjectID* objectID = publicKey.objectID;

            if(keyLabel && objectID)
            {
                dispatch_sync([MynigmaPublicKey keyIndexQueue], ^{
                    NSManagedObjectID* existingObjectID = [[MynigmaPublicKey keyIndex] objectForKey:keyLabel];

                    //give preference to private keys
                    if(!existingObjectID || ([existingObjectID.entity.name isEqualToString:@"MynigmaPublicKey"] && [objectID.entity.name isEqualToString:@"MynigmaPrivateKey"]))
                        [[MynigmaPublicKey keyIndex] setObject:objectID forKey:keyLabel];
                });
            }

            return publicKey;
        }
        else
        {
            NSLog(@"Failed to add public key with label %@ and data %@, %@ to keychain!!!", keyLabel, encKeyData, verKeyData);
            return nil;
        }
    }
}

+ (void)introducePublicKeyWithEncKeyData:(NSData*)newEncKeyData andVerKeyData:(NSData*)newVerKeyData fromEmail:(NSString*)senderEmail toEmails:(NSArray*)recipients keyLabel:(NSString*)toLabel fromKeyWithLabel:(NSString*)fromLabel
{
    if(!newEncKeyData || !newVerKeyData || !senderEmail || !toLabel || !fromLabel)
        return;

    [ThreadHelper runSyncOnKeyContext:^(NSManagedObjectContext *keyContext) {

        MynigmaPublicKey* fromPublicKey = [MynigmaPublicKey publicKeyWithLabel:fromLabel inContext:keyContext];

        EmailAddress* emailAddress = [EmailAddress emailAddressForEmail:senderEmail inContext:keyContext];

        MynigmaPublicKey* currentKey = emailAddress.currentKey;

        if(!currentKey || [fromPublicKey isEqual:currentKey])
        {
            MynigmaPublicKey* newPublicKey = [MynigmaPublicKey syncMakeNewPublicKeyWithEncKeyData:newEncKeyData andVerKeyData:newVerKeyData forEmail:senderEmail keyLabel:toLabel inContext:keyContext];

            if(newPublicKey)
            {
                if(currentKey)
                    [newPublicKey addIsIntroducedByKeysObject:currentKey];

                [newPublicKey associateKeyWithEmail:senderEmail forceMakeCurrent:YES inContext:keyContext];
                //                [emailAddress addAllKeysObject:newPublicKey];
                //
                //                [emailAddress setCurrentKey:newPublicKey];

                NSError* error = nil;

                [keyContext save:&error];

                if(error)
                {
                    NSLog(@"Error saving key context after adding key to keychain! %@", error);
                }

                [CoreDataHelper save];
            }
        }
    }];
}


/**Find a public key with the given keyLabel and, upon failure, optionally looks in the keychain (email is only needed for the latter)*/
+ (MynigmaPublicKey*)publicKeyWithLabel:(NSString*)keyLabel inContext:(NSManagedObjectContext*)keyContext
{
    if(!keyLabel)
        return nil;

    __block MynigmaPublicKey* returnValue = nil;

    if([MynigmaPublicKey haveCompiledKeyIndex])
    {
        __block NSManagedObjectID* keyObjectID = nil;

        dispatch_sync([MynigmaPublicKey keyIndexQueue], ^{

            keyObjectID = [MynigmaPublicKey keyIndex][keyLabel];

        });

        if(!keyObjectID)
            return nil;

        NSError* error = nil;

        returnValue = (MynigmaPublicKey*)[keyContext existingObjectWithID:keyObjectID error:&error];

        if(error)
            NSLog(@"Error getting private key from objectID!!");

        return returnValue;
    }
    else
    {
        //the index hasn't been compiled yet: run a fetch request
        NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MynigmaPublicKey"];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"keyLabel == %@",keyLabel]];
        NSError* error = nil;
        NSArray* result = [keyContext executeFetchRequest:fetchRequest error:&error];

        if(error)
            NSLog(@"Error trying to fetch mynigma private key");
        else
        {
            if(result.count>1)
            {
                NSLog(@"More than one private key with label %@", keyLabel);
            }

            returnValue = result.firstObject;
        }

        return returnValue;
    }
}






#pragma mark - DATA COMPARISON


- (BOOL)matchesEncData:(NSData*)encryptionData andVerData:(NSData*)verificationData
{
    if(!encryptionData || !verificationData)
        return NO;

    NSData* encrData = [KeychainHelper dataForPersistentRef:self.publicEncrKeyRef];

    NSData* verData = [KeychainHelper dataForPersistentRef:self.publicVerifyKeyRef];

    if([encrData isEqual:encryptionData] && [verificationData isEqual:verData])
        return YES;

    return NO;
}
























#pragma mark - RECIPIENTS CONVENIENCE FUNCTIONS


+ (NSArray*)introductionOriginKeyLabelsForRecipients:(NSArray*)recipients
{
    return [MynigmaPublicKey introductionOriginKeyLabelsForRecipients:recipients allowErrors:NO];
}

+ (NSArray*)introductionOriginKeyLabelsForRecipients:(NSArray*)recipients allowErrors:(BOOL)allowErrors
{
    NSMutableArray* returnValue = [NSMutableArray new];

    EmailRecipient* senderRecipient = [AddressDataHelper senderAmongRecipients:recipients];

    for(NSObject* rec in recipients)
    {
        if([rec isKindOfClass:[Recipient class]])
        {
            NSString* publicKeyLabel = [MynigmaPublicKey keyLabelForSignatureIntroductionFrom:senderRecipient.email to:[(Recipient*)rec displayEmail]];

            if(publicKeyLabel)
                [returnValue addObject:publicKeyLabel];
            else
            {
                NSLog(@"No public key found for recipient!!!! %@", rec);

                if(!allowErrors)
                    return nil;
            }
        }
        else if([rec isKindOfClass:[EmailRecipient class]])
        {
            NSString* publicKeyLabel = [MynigmaPublicKey keyLabelForSignatureIntroductionFrom:senderRecipient.email to:[(EmailRecipient*)rec email]];

            if(publicKeyLabel)
                [returnValue addObject:publicKeyLabel];
            else
            {
                NSLog(@"No public key found for email recipient!!!! %@", rec);

                if(!allowErrors)
                    return nil;
            }
        }
        else
        {
            NSLog(@"Unexpected rec type: %@", rec);
            if(!allowErrors)
                return nil;
        }
    }

    return returnValue;
}

+ (NSArray*)encryptionKeyLabelsForRecipients:(NSArray*)recipients
{
    return [MynigmaPublicKey encryptionKeyLabelsForRecipients:recipients allowErrors:NO];
}

+ (NSArray*)encryptionKeyLabelsForRecipients:(NSArray*)recipients allowErrors:(BOOL)allowErrors
{
    NSMutableArray* returnValue = [NSMutableArray new];

    EmailRecipient* senderRecipient = [AddressDataHelper senderAmongRecipients:recipients];

    if(!senderRecipient)
    {
        NSLog(@"Cannot get keys: no sender among recipients!!");
        return nil;
    }

    for(NSObject* rec in recipients)
    {
        if([rec isKindOfClass:[Recipient class]])
        {
            NSString* publicKeyLabel = [MynigmaPublicKey publicKeyLabelForEmailAddress:[(Recipient*)rec displayEmail]];

            if(publicKeyLabel)
                [returnValue addObject:publicKeyLabel];
            else
            {
                NSLog(@"No public key found for recipient!!!! %@", rec);

                if(!allowErrors)
                    return nil;
            }
        }
        else if([rec isKindOfClass:[EmailRecipient class]])
        {
            NSString* publicKeyLabel = [MynigmaPublicKey publicKeyLabelForEmailAddress:[(EmailRecipient*)rec email]];

            if(publicKeyLabel)
                [returnValue addObject:publicKeyLabel];
            else
            {
                NSLog(@"No public key found for email recipient!!!! %@", rec);

                if(!allowErrors)
                    return nil;
            }
        }
        else
        {
            NSLog(@"Unexpected rec type: %@", rec);
            if(!allowErrors)
                return nil;
        }
    }

    return returnValue;
}

+ (BOOL)isKeyWithLabel:(NSString*)keyLabel validForSignatureFromEmail:(NSString*)emailString
{
    if(!keyLabel)
        return NO;

    return [keyLabel isEqualToString:[MynigmaPublicKey publicKeyLabelForEmailAddress:emailString]];
}


+ (BOOL)wasKeyWithLabel:(NSString*)keyLabel previouslyValidForSignatureFromEmail:(NSString*)emailString
{
    __block BOOL returnValue = NO;

    [ThreadHelper runSyncOnKeyContext:^(NSManagedObjectContext *keyContext)
     {

         EmailAddress* emailAddress = [EmailAddress emailAddressForEmail:emailString inContext:keyContext];

         NSSet* previouslyValidKeys = emailAddress.allKeys;

         for(MynigmaPublicKey* publicKey in previouslyValidKeys)
         {
             if([publicKey.keyLabel isEqualToString:keyLabel])
                 returnValue = YES;
         }
     }];

    return returnValue;
}


+ (BOOL)isKeyWithLabelCurrentKeyForSomeEmailAddress:(NSString*)keyLabel
{
    __block BOOL returnValue = NO;
    
    [ThreadHelper runSyncOnKeyContext:^(NSManagedObjectContext *keyContext)
     {
         MynigmaPublicKey* publicKey = [MynigmaPublicKey publicKeyWithLabel:keyLabel inContext:keyContext];
         
         returnValue = publicKey.currentForEmailAddress.count > 0;
     }];
    
    return returnValue;
}


+ (NSArray*)dataForExistingMynigmaPublicKeyWithLabel:(NSString*)keyLabel
{
    if(!keyLabel)
        return nil;

    __block NSData* encrData = nil;

    __block NSData* verData = nil;

    [ThreadHelper runSyncOnKeyContext:^(NSManagedObjectContext *keyContext)
    {
         MynigmaPublicKey* publicKey = [MynigmaPublicKey publicKeyWithLabel:keyLabel inContext:keyContext];

         if(publicKey)
         {
             encrData = [KeychainHelper dataForPersistentRef:publicKey.publicEncrKeyRef];

             verData = [KeychainHelper dataForPersistentRef:publicKey.publicVerifyKeyRef];
         }
     }];

    if(encrData && verData)
        return @[encrData, verData];

    return nil;
}


+ (BOOL)syncUpdateKeychainRefsForKeyWithLabel:(NSString*)keyLabel encRef:(NSData*)encRef verRef:(NSData*)verRef
{
    if(!keyLabel || !encRef || !verRef)
    {
        NSLog(@"Cannot sync update keychain refs %@, %@ for key label %@", encRef, verRef, keyLabel);
        return NO;
    }

    __block BOOL returnValue = NO;

    [ThreadHelper runSyncOnKeyContext:^(NSManagedObjectContext *keyContext)
     {
         MynigmaPublicKey* publicKey = [MynigmaPublicKey publicKeyWithLabel:keyLabel inContext:keyContext];

         if(publicKey)
         {
             [publicKey setPublicEncrKeyRef:encRef];
             [publicKey setPublicVerifyKeyRef:verRef];

             returnValue = YES;
         }
     }];

    return returnValue;
}

+ (void)asyncUpdateKeychainRefsForKeyWithLabel:(NSString*)keyLabel encRef:(NSData*)encRef verRef:(NSData*)verRef withCallback:(void(^)(void))callback
{
    if(!keyLabel || !encRef || !verRef)
    {
        NSLog(@"Cannot async update keychain refs %@, %@ for key label %@", encRef, verRef, keyLabel);
        return;
    }

    [ThreadHelper runAsyncOnKeyContext:^{

        MynigmaPublicKey* publicKey = [MynigmaPublicKey publicKeyWithLabel:keyLabel inContext:KEY_CONTEXT];

        [publicKey setPublicEncrKeyRef:encRef];
        [publicKey setPublicVerifyKeyRef:verRef];

        NSError* error = nil;

        [KEY_CONTEXT save:&error];

        if(error)
        {
            NSLog(@"Error saving key context after updating public keychain refs! %@", error);
        }

        [CoreDataHelper saveWithCallback:^{

            if(callback)
                callback();
        }];
    }];
}





#pragma mark - ACCESS FROM ARBITRARY THREAD


+ (SecKeyRef)publicSecKeyRefWithLabel:(NSString*)keyLabel forEncryption:(BOOL)forEncryption
{
    if(!keyLabel)
        return nil;

    __block SecKeyRef keyRef = NULL;

    [ThreadHelper runSyncOnKeyContext:^(NSManagedObjectContext *keyContext) {

        MynigmaPublicKey* publicKey = [MynigmaPublicKey publicKeyWithLabel:keyLabel inContext:keyContext];
        
        if(!publicKey)
        {
            NSLog(@"No public key found for label: %@", keyLabel);
            return;
        }
        
        NSData* persistentRef = forEncryption?publicKey.publicEncrKeyRef:publicKey.publicVerifyKeyRef;
        
        if(!persistentRef)
        {
            NSLog(@"No public persistent ref found for key label: %@", keyLabel);
            return;
        }
        
        keyRef = [KeychainHelper keyRefForPersistentRef:persistentRef];
        
    }];
    
    return keyRef;
}

+ (BOOL)removePublicKeyWithLabel:(NSString*)publicKeyLabel alsoRemoveFromKeychain:(BOOL)alsoRemoveFromKeychain
{
    __block BOOL returnValue = NO;
    
    [ThreadHelper runSyncOnKeyContext:^(NSManagedObjectContext *keyContext)
     {
         
         MynigmaPublicKey* publicKey = [MynigmaPublicKey publicKeyWithLabel:publicKeyLabel inContext:keyContext];

         [publicKey removeCurrentForEmailAddress:publicKey.currentForEmailAddress];

         if([publicKey isKindOfClass:[MynigmaPublicKey class]])
         {
             NSString* keyLabel = publicKey.keyLabel;

             if(keyLabel)
             {
                 NSManagedObjectID* objectID = publicKey.objectID;

                 dispatch_sync([MynigmaPublicKey keyIndexQueue], ^{

                     if([[[MynigmaPublicKey keyIndex] objectForKey:keyLabel] isEqual:objectID])
                         [[MynigmaPublicKey keyIndex] removeObjectForKey:keyLabel];
             });

                 [keyContext deleteObject:publicKey];

                 returnValue = YES;//(error != nil);
            }
             else
                 returnValue = NO;
         }
         
         if(alsoRemoveFromKeychain)
             if(![KeychainHelper removePublicKeychainItemWithLabel:publicKeyLabel])
                 returnValue = NO;
         
     }];
    
    return returnValue;
}


+ (NSString*)fingerprintForKeyWithLabel:(NSString*)label
{
    NSArray* dataArray = [MynigmaPublicKey dataForExistingMynigmaPublicKeyWithLabel:label];
    
    if(dataArray.count != 2)
        return @"-- error --";
    
    NSMutableData* concatenatedData = [NSMutableData dataWithData:dataArray[0]];
    
    [concatenatedData appendData:dataArray[1]];
    [concatenatedData appendData:[label dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSData* hashValue = [AppleEncryptionWrapper SHA256DigestOfData:concatenatedData];
    
    NSString* hashInBase64 = [hashValue base64];
    
    //delete the trailing '=' character...
    hashInBase64 = [hashInBase64 substringToIndex:hashInBase64.length-1];
    
    return hashInBase64;
}

@end
