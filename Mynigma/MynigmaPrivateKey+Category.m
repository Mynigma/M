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





#import "MynigmaPrivateKey+Category.h"
#import "EmailContactDetail+Category.h"
#import "PublicKeyManager.h"
#import "AppDelegate.h"

#import "KeychainHelper.h"
#import "UserSettings.h"
#import "IMAPAccountSetting+Category.h"
#import "EmailRecipient.h"
#import "AddressDataHelper.h"
#import "EmailMessageInstance+Category.h"
#import "MynigmaPublicKey+Category.h"
#import "AppleEncryptionWrapper.h"
#import "EmailAddress+Category.h"
#import "NSString+EmailAddresses.h"
#import "MynigmaDevice+Category.h"


//static NSNumber* isGeneratingDeviceKey;

@interface EmailAddress()

+ (EmailAddress*)emailAddressForEmail:(NSString*)emailString inContext:(NSManagedObjectContext*)keyContext;

@end


@interface MynigmaPublicKey()

- (void)associateKeyWithEmail:(NSString*)emailString forceMakeCurrent:(BOOL)makeCurrent inContext:(NSManagedObjectContext*)keyContext;

- (BOOL)matchesEncData:(NSData*)encryptionData andVerData:(NSData*)verificationData;

+ (MynigmaPublicKey*)publicKeyWithLabel:(NSString*)keyLabel inContext:(NSManagedObjectContext*)keyContext;

+ (BOOL)removePublicKeyWithLabel:(NSString*)publicKeyLabel alsoRemoveFromKeychain:(BOOL)alsoRemoveFromKeychain;


+ (BOOL)haveCompiledKeyIndex;
+ (NSMutableDictionary*)keyIndex;
+ (dispatch_queue_t)keyIndexQueue;

@end


static NSMutableArray* syncKeyGenerationCallbackInvocations;



@implementation MynigmaPrivateKey (Category)


#pragma mark - PRIVATE METHODS

#pragma mark - Core data store

+ (MynigmaPrivateKey*)makePrivateKeyObjectWithLabel:(NSString*)keyLabel forEmail:(NSString *)email inContext:(NSManagedObjectContext*)keyContext
{
    email = email.canonicalForm;

    NSEntityDescription* entityDescription = [NSEntityDescription entityForName:@"MynigmaPrivateKey" inManagedObjectContext:keyContext];
    MynigmaPrivateKey* privateKey = [[MynigmaPrivateKey alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:keyContext];

    [privateKey setKeyLabel:keyLabel];

    [privateKey setEmailAddress:email];

    [privateKey associateKeyWithEmail:email forceMakeCurrent:NO inContext:keyContext];

    [privateKey setDateCreated:[NSDate date]];

    [privateKey setVersion:MYNIGMA_VERSION];

    [privateKey setIsCompromised:@NO];

    NSError* error = nil;

    [keyContext obtainPermanentIDsForObjects:@[privateKey] error:&error];

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

    NSManagedObjectID* objectID = privateKey.objectID;

    if(keyLabel && objectID)
    {
        dispatch_sync([MynigmaPublicKey keyIndexQueue], ^{
            [[MynigmaPublicKey keyIndex] setObject:objectID forKey:keyLabel];
        });
    }

    return privateKey;
}

//+ (MynigmaPrivateKey*)key_senderKeyForMessage:(EmailMessage*)message
//{
//    [ThreadHelper ensureNotMainThread];
//
//    EmailRecipient* fromEmailRec = [AddressDataHelper senderAsEmailRecipientForMessage:message addIfNotFound:YES];
//
//    NSString* fromEmail = fromEmailRec.email;
//
//    if(!fromEmail)
//    {
//        NSLog(@"No sender email address found!!");
//        return nil;
//    }
//
//    EmailAddress* emailAddress = [EmailAddress emailAddressForEmail:fromEmail];
//
//    MynigmaPrivateKey* senderPrivateKey = (MynigmaPrivateKey*)emailAddress.currentKey;
//
//    if([senderPrivateKey isKindOfClass:[MynigmaPrivateKey class]])
//        return senderPrivateKey;
//
//    return nil;
//}

//+ (BOOL)key_havePrivateKeyWithLabel:(NSString*)keyLabel
//{
//    [ThreadHelper ensureNotMainThread];
//
//    MynigmaPrivateKey* privateKey = [MynigmaPrivateKey key_privateKeyWithLabel:keyLabel];
//
//    return (privateKey!=nil);
//}


////returns the MynigmaPublicKey with the given keyLabel, if any
//+ (MynigmaPrivateKey*)key_privateKeyWithLabel:(NSString*)keyLabel forEmail:(NSString *)email tryKeychain:(BOOL)lookInKeychain
//{
//    [ThreadHelper ensureNotMainThread];
//
//    //first check that the key label is not nil
//    if(!keyLabel)
//        return nil;
//
//    //fetch the key with the specified label from the store
//    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MynigmaPrivateKey"];
//    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"keyLabel == %@",keyLabel]];
//    NSError* error = nil;
//    NSArray* result = [KEY_CONTEXT executeFetchRequest:fetchRequest error:&error];
//    if(error)
//        NSLog(@"Error trying to fetch mynigma private key");
//    else
//    {
//        if([result count]>1)
//            NSLog(@"More than one private key with the same ID!"); //this should never happen
//        if([result count]>=1)
//        {
//            return [result objectAtIndex:0];
//        }
//        else if(lookInKeychain)
//        {
//            NSLog(@"Looking for private key in keychain");
//            //no matching MynigmaPrivateKey was found - look in the keychain!
//            if([KeychainHelper havePrivateKeychainItemWithLabel:keyLabel])
//            {
//                NSLog(@"Found private key in keychain: %@", keyLabel);
//                //a private key
//                NSArray* persistentRefs = [KeychainHelper persistentRefsForPrivateKeychainItemWithLabel:keyLabel];
//
//                if([persistentRefs count]==4)
//                {
//
//                    NSData* decrKeyRef = persistentRefs[0];
//                    NSData* signKeyRef = persistentRefs[1];
//                    NSData* encrKeyRef = persistentRefs[2];
//                    NSData* verKeyRef = persistentRefs[3];
//
//
//                    MynigmaPrivateKey* privateKey = [MynigmaPrivateKey key_makeNewPrivateKeyWithLabel:keyLabel forEmail:email.lowercaseString withDecRef:decrKeyRef andSigRef:signKeyRef andEncRef:encrKeyRef andVerRef:verKeyRef makeCurrentKey:YES];
//
//
//                                        NSError* error = nil;
//
//                                        [KEY_CONTEXT save:&error];
//
//                                        if(error)
//                                        {
//                                            NSLog(@"Error saving key context after creating private key!! %@", error);
//                                        }
//
//                    [MODEL save];
//
//                    return privateKey;
//                }
//                else
//                {
//                    NSLog(@"KeychainHelper: havePublicKey returns YES, but persistent refs are invalid: %@", persistentRefs);
//                }
//
//            }
//        }
//    }
//    return  nil;
//}
//
//+ (MynigmaPrivateKey*)key_makeNewPrivateKeyWithLabel:(NSString*)keyLabel forEmail:(NSString*)emailString withDecRef:(NSData*)decRef andSigRef:(NSData*)sigRef andEncRef:(NSData*)encRef andVerRef:(NSData*)verRef makeCurrentKey:(BOOL)makeCurrentKey
//{
//    if([MynigmaPrivateKey key_havePrivateKeyWithLabel:keyLabel])
//        return nil;
//
//    NSEntityDescription* entityDescription = [NSEntityDescription entityForName:@"MynigmaPrivateKey" inManagedObjectContext:KEY_CONTEXT];
//    MynigmaPrivateKey* privateKey = [[MynigmaPrivateKey alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:KEY_CONTEXT];
//
//
//    [privateKey setKeyLabel:keyLabel];
//
//    [privateKey setIsCompromised:[NSNumber numberWithBool:NO]];
//
//    [privateKey setDateCreated:[NSDate date]];
//
//    [privateKey setVersion:MYNIGMA_VERSION];
//
//    [privateKey setEmailAddress:emailString];
//
//    [privateKey associateKeyWithEmail:emailString forceMakeCurrent:makeCurrentKey];
//
//    [privateKey setPrivateDecrKeyRef:decRef];
//    [privateKey setPrivateSignKeyRef:sigRef];
//    [privateKey setPublicEncrKeyRef:encRef];
//    [privateKey setPublicVerifyKeyRef:verRef];
//
//    return privateKey;
//}
//






#pragma mark - Key by email address


+ (BOOL)havePrivateKeyForEmailAddress:(NSString*)emailString
{
    __block BOOL returnValue = NO;

    [ThreadHelper runSyncOnKeyContext:^(NSManagedObjectContext* keyContext) {

        EmailAddress* emailAddress = [EmailAddress emailAddressForEmail:emailString inContext:keyContext];

        MynigmaPrivateKey* privateKey = (MynigmaPrivateKey*)emailAddress.currentKey;

        if([privateKey isKindOfClass:[MynigmaPrivateKey class]])
            returnValue = YES;
    }];

    return returnValue;
}


+ (NSString*)privateKeyLabelForEmailAddress:(NSString*)emailString
{
    __block NSString* returnValue = nil;

    [ThreadHelper runSyncOnKeyContext:^(NSManagedObjectContext* keyContext) {

        EmailAddress* emailAddress = [EmailAddress emailAddressForEmail:emailString inContext:keyContext];

        MynigmaPrivateKey* privateKey = (MynigmaPrivateKey*)emailAddress.currentKey;

        if([privateKey isKindOfClass:[MynigmaPrivateKey class]])
            returnValue = privateKey.keyLabel;
    }];

    return returnValue;
}





#pragma mark - Key by label


+ (MynigmaPrivateKey*)privateKeyWithLabel:(NSString*)keyLabel inContext:(NSManagedObjectContext*)keyContext
{
    if(!keyLabel)
        return nil;

    __block MynigmaPrivateKey* returnValue = nil;

    if([MynigmaPublicKey haveCompiledKeyIndex])
    {
        __block NSManagedObjectID* keyObjectID = nil;

        dispatch_sync([MynigmaPublicKey keyIndexQueue], ^{

            keyObjectID = [MynigmaPublicKey keyIndex][keyLabel];

        });

        if(!keyObjectID)
            return nil;

        NSError* error = nil;

        //check if it's actually a private key
        if([keyObjectID.entity.name isEqualToString:@"MynigmaPrivateKey"])
            returnValue = (MynigmaPrivateKey*)[keyContext existingObjectWithID:keyObjectID error:&error];

        if(error)
            NSLog(@"Error getting private key from objectID!!");

        return returnValue;
    }
    else
    {
        //the index hasn't been compiled yet: run a fetch request
        NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MynigmaPrivateKey"];
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


+ (BOOL)havePrivateKeyWithLabel:(NSString*)keyLabel
{
    if(!keyLabel)
        return NO;

    __block BOOL returnValue = NO;

    if([MynigmaPublicKey haveCompiledKeyIndex])
    {
        dispatch_sync([MynigmaPublicKey keyIndexQueue], ^{

            NSManagedObjectID* keyObjectID = [MynigmaPublicKey keyIndex][keyLabel];

            //check if it's actually a private key
            returnValue = [keyObjectID.entity.name isEqualToString:@"MynigmaPrivateKey"];
        });

        return returnValue;
    }
    else
    {
        //the index hasn't been compiled yet: run a fetch request
        [ThreadHelper runSyncOnKeyContext:^(NSManagedObjectContext *keyContext)
         {

             NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MynigmaPrivateKey"];
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


+ (NSString*)senderKeyLabelForMessage:(EmailMessage*)message
{
    EmailRecipient* emailRecipient = [AddressDataHelper senderAsEmailRecipientForMessage:message];

    return [MynigmaPrivateKey privateKeyLabelForEmailAddress:emailRecipient.email];
}



#pragma mark - Raw data

+ (BOOL)syncUpdateKeychainRefsForKeyWithLabel:(NSString*)keyLabel encRef:(NSData*)encRef verRef:(NSData*)verRef decRef:(NSData*)decRef sigRef:(NSData*)sigRef
{
    __block BOOL returnValue = NO;

    [ThreadHelper runSyncOnKeyContext:^(NSManagedObjectContext* keyContext){

        MynigmaPrivateKey* privateKey = [MynigmaPrivateKey privateKeyWithLabel:keyLabel inContext:keyContext];

        if(privateKey)
        {
            [privateKey setPublicEncrKeyRef:encRef];
            [privateKey setPublicVerifyKeyRef:verRef];

            [privateKey setPrivateDecrKeyRef:decRef];
            [privateKey setPrivateSignKeyRef:sigRef];

            NSError* error = nil;

            [keyContext save:&error];

            if(error)
            {
                NSLog(@"Error saving key context after updating public keychain refs! %@", error);
            }

            [CoreDataHelper save];

            returnValue = YES;
        }
    }];

    return returnValue;
}

+ (NSArray*)dataForPrivateKeyWithLabel:(NSString*)keyLabel
{
    return [self dataForPrivateKeyWithLabel:keyLabel passphrase:@""];
}


+ (NSArray*)dataForPrivateKeyWithLabel:(NSString*)keyLabel passphrase:(NSString*)passphrase
{
    if(!keyLabel)
        return nil;

    NSArray* dataArray = [KeychainHelper dataForPrivateKeychainItemWithLabel:keyLabel passphrase:passphrase];

    if(dataArray.count<4)
    {
        NSLog(@"Couldn't find data for private key export!!!");
        return nil;
    }

    NSData* decrData = dataArray[0];

    NSData* sigData = dataArray[1];

    NSData* encrData = dataArray[2];

    NSData* verData = dataArray[3];

    if(decrData && sigData && encrData && verData)
        return @[decrData, sigData, encrData, verData];

    return nil;
}







#pragma mark - RAW DATA

- (BOOL)matchesEncData:(NSData*)encryptionData decData:(NSData*)decryptionData verData:(NSData*)verificationData sigData:(NSData*)signatureData
{
    if(!encryptionData || !decryptionData || !verificationData || !signatureData)
        return NO;

    NSArray* dataArray = [KeychainHelper dataForPrivateKeychainItemWithLabel:self.keyLabel];

    if(dataArray.count<4)
        return NO;

    NSData* decrData = dataArray[0];

    NSData* sigData = dataArray[1];

    NSData* encrData = dataArray[2];

    NSData* verData = dataArray[3];

    if([encryptionData isEqual:encrData] && [decryptionData isEqual:decrData] && [verificationData isEqual:verData] && [signatureData isEqual:sigData])
        return YES;

    return NO;
}




+ (void)asyncUpdateKeychainRefsForKeyWithLabel:(NSString*)keyLabel encRef:(NSData*)encRef verRef:(NSData*)verRef decRef:(NSData*)decRef sigRef:(NSData*)sigRef withCallback:(void(^)(void))callback
{
    [ThreadHelper runAsyncOnKeyContext:^{

        MynigmaPrivateKey* privateKey = [MynigmaPrivateKey privateKeyWithLabel:keyLabel inContext:KEY_CONTEXT];

        if(privateKey)
        {
            [privateKey setPublicEncrKeyRef:encRef];
            [privateKey setPublicVerifyKeyRef:verRef];

            [privateKey setPrivateDecrKeyRef:decRef];
            [privateKey setPrivateSignKeyRef:sigRef];

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
        }
    }];
}


+ (SecKeyRef)privateSecKeyRefWithLabel:(NSString*)keyLabel forEncryption:(BOOL)forEncryption
{
    //if the keyLabel is invalid return immediately
    if(!keyLabel)
    {
        NSLog(@"Trying to find key with nil label!!!");
        return nil;
    }

    __block SecKeyRef keyRef = NULL;

    [ThreadHelper runSyncOnKeyContext:^(NSManagedObjectContext *keyContext) {

        MynigmaPrivateKey* privateKey = [MynigmaPrivateKey privateKeyWithLabel:keyLabel inContext:keyContext];

        NSData* persistentRef = forEncryption?privateKey.privateDecrKeyRef:privateKey.privateSignKeyRef;

        if(!persistentRef)
        {
            NSLog(@"No private key found for label: %@", keyLabel);
            return;
        }

        keyRef = [KeychainHelper keyRefForPersistentRef:persistentRef];

    }];

    return keyRef;
}





#pragma mark - KEY PAIR GENERATION

+ (void)asyncCreateNewMynigmaPrivateKeyForEmail:(NSString*)emailAddress withCallback:(void(^)(void))callback
{
    NSString* email = [emailAddress canonicalForm];

    if(!email)
        return;

    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

        [AppleEncryptionWrapper generateNewPrivateKeyPairForEmailAddress:email withCallback:^(NSString *keyLabel, NSData *encPersRef, NSData *verPersRef, NSData *decPersRef, NSData *sigPersRef) {

            [MynigmaPrivateKey asyncMakeNewPrivateKeyWithLabel:keyLabel forEmail:email withDecRef:decPersRef andSigRef:sigPersRef andEncRef:encPersRef andVerRef:verPersRef makeCurrentKey:YES dateCreated:[NSDate date] isCompromised:NO withCallback:callback];
        }];
    }];
}


+ (void)waitUntilDeviceKeyIsGeneratedForDeviceWithUUID:(NSString*)deviceUUID andThenCall:(NSInvocation*)invocation
{
    [ThreadHelper ensureMainThread];
    
    @synchronized(self)
    {
        if(!syncKeyGenerationCallbackInvocations)
        {
            //no key generation in progress
            //check if a key has already been generated
            if(![MynigmaDevice haveKeyForDeviceWithUUID:deviceUUID])
                [self asyncCreateNewMynigmaPrivateKeyForDeviceWithUUID:deviceUUID withCallback:^{
                
                    if([invocation isKindOfClass:[NSInvocation class]])
                    {
                        [invocation invoke];
                    }
                }];
            else if([invocation isKindOfClass:[NSInvocation class]])
            {
                [invocation invoke];
            }

        }
        else
        {
            //a key is currently being generated
            if([invocation isKindOfClass:[NSInvocation class]])
            {
                [syncKeyGenerationCallbackInvocations addObject:invocation];
            }
        }
    }
}

+ (void)asyncCreateNewMynigmaPrivateKeyForDeviceWithUUID:(NSString*)deviceUUID withCallback:(void(^)(void))callback
{
    if(!deviceUUID)
        return;
    
    @synchronized(self)
    {
        if(syncKeyGenerationCallbackInvocations)
            return;
        
        syncKeyGenerationCallbackInvocations = [NSMutableArray new];
    }
    
    NSString* keyLabel = [NSString stringWithFormat:@"deviceSync@%@", deviceUUID];

    if([MynigmaPrivateKey havePrivateKeyWithLabel:keyLabel])
    {
        //already have the device key, so just associate it(!)
        [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

            MynigmaDevice* device = [MynigmaDevice deviceWithUUID:deviceUUID addIfNotFound:YES inContext:localContext];

            MynigmaPrivateKey* privateKey = [MynigmaPrivateKey privateKeyWithLabel:keyLabel inContext:localContext];

            [device setSyncKey:privateKey];

            [localContext save:nil];

            [CoreDataHelper saveWithCallback:^{
                
            @synchronized(self)
            {
                for(NSInvocation* invocation in syncKeyGenerationCallbackInvocations)
                {
                    [invocation invoke];
                }
                
                syncKeyGenerationCallbackInvocations = nil;
            }

            if(callback)
                callback();
            }];
        }];
    }

    //look for the device key in the keychain
    NSArray* privateKeychainItems = [KeychainHelper listPrivateKeychainItems];

    NSString* signatureKeyLabel = [NSString stringWithFormat:@"Mynigma signature key %@", keyLabel];

    NSString* encryptionKeyLabel = [NSString stringWithFormat:@"Mynigma encryption key %@", keyLabel];

    NSData* persistentSignatureRef = nil;

    NSData* persistentDecryptionRef = nil;

    //iterate through the keychain items, looking for the device sync key
    for(NSDictionary* dict in privateKeychainItems)
    {
        NSString* label = [dict objectForKey:@"labl"];

        if(!label || [label isEqual:[NSNull null]])
            continue;

        NSData* persistentRef = [dict objectForKey:@"v_PersistentRef"];

        //it's the signature key
        if([label isEqualToString:signatureKeyLabel])
            persistentSignatureRef = persistentRef;

        //it's the encryption key
        if([label isEqualToString:encryptionKeyLabel])
            persistentDecryptionRef = persistentRef;
    }
    
    NSArray* publicKeychainItems = [KeychainHelper listPublicKeychainItems];
    
    NSData* persistentVerificationRef = nil;
    
    NSData* persistentEncryptionRef = nil;
    

    //iterate through the keychain items, looking for the device sync key
    for(NSDictionary* dict in publicKeychainItems)
    {
        NSString* label = [dict objectForKey:@"labl"];
        
        if(!label || [label isEqual:[NSNull null]])
            continue;
        
        NSData* persistentRef = [dict objectForKey:@"v_PersistentRef"];
        
        //it's the signature key
        if([label isEqualToString:signatureKeyLabel])
            persistentVerificationRef = persistentRef;
        
        //it's the encryption key
        if([label isEqualToString:encryptionKeyLabel])
            persistentEncryptionRef = persistentRef;
    }
   

    if(persistentDecryptionRef && persistentSignatureRef && persistentEncryptionRef && persistentVerificationRef)
    {
        //found both
        //use the keychain item instead of generating a new one

        [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

            [MynigmaPrivateKey asyncMakeNewPrivateKeyWithLabel:keyLabel forEmail:nil withDecRef:persistentDecryptionRef andSigRef:persistentSignatureRef andEncRef:persistentEncryptionRef andVerRef:persistentVerificationRef makeCurrentKey:NO dateCreated:[NSDate date] isCompromised:NO withCallback:^{

                [localContext performBlock:^{

                MynigmaDevice* device = [MynigmaDevice deviceWithUUID:deviceUUID addIfNotFound:YES inContext:localContext];

                MynigmaPrivateKey* privateKey = [MynigmaPrivateKey privateKeyWithLabel:keyLabel inContext:localContext];

                [device setSyncKey:privateKey];

                [localContext save:nil];

                    [CoreDataHelper saveWithCallback:^{
                
                    @synchronized(self)
                    {
                        for(NSInvocation* invocation in syncKeyGenerationCallbackInvocations)
                        {
                            [invocation invoke];
                        }
                        
                        syncKeyGenerationCallbackInvocations = nil;
                    }

                if(callback)
                    callback();
                        
                    }];
            }];

            }];
        }];

    }

    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

        [AppleEncryptionWrapper generateNewPrivateKeyPairWithKeyLabel:keyLabel withCallback:^(NSString *keyLabel, NSData *encPersRef, NSData *verPersRef, NSData *decPersRef, NSData *sigPersRef) {

            [MynigmaPrivateKey asyncMakeNewPrivateKeyWithLabel:keyLabel forEmail:nil withDecRef:decPersRef andSigRef:sigPersRef andEncRef:encPersRef andVerRef:verPersRef makeCurrentKey:NO dateCreated:[NSDate date] isCompromised:NO withCallback:^{

                [localContext performBlock:^{

                    MynigmaDevice* device = [MynigmaDevice deviceWithUUID:deviceUUID addIfNotFound:YES inContext:localContext];

                    MynigmaPrivateKey* privateKey = [MynigmaPrivateKey privateKeyWithLabel:keyLabel inContext:localContext];

                    [device setSyncKey:privateKey];

                    [localContext save:nil];

                    [CoreDataHelper saveWithCallback:^{
                        
                    @synchronized(self)
                    {
                        for(NSInvocation* invocation in syncKeyGenerationCallbackInvocations)
                        {
                            [invocation invoke];
                        }
                        
                        syncKeyGenerationCallbackInvocations = nil;
                    }
                    
                    if(callback)
                        callback();
                    }];
                }];
            }];
        }];
    }];
}


+ (MynigmaPrivateKey*)syncMakeNewPrivateKeyWithLabel:(NSString*)keyLabel forEmail:(NSString*)emailString withDecRef:(NSData*)decRef andSigRef:(NSData*)sigRef andEncRef:(NSData*)encRef andVerRef:(NSData*)verRef dateCreated:(NSDate*)dateCreated isCompromised:(BOOL)isCompromised makeCurrentKey:(BOOL)makeCurrentKey inContext:(NSManagedObjectContext*)keyContext
{
    if(!keyLabel)
        return nil;

    if([MynigmaPrivateKey havePrivateKeyWithLabel:keyLabel])
        return nil;
    
    MynigmaPublicKey* existingPublicKey = [MynigmaPublicKey publicKeyWithLabel:keyLabel inContext:keyContext];
    
    MynigmaPrivateKey* privateKey = [MynigmaPrivateKey makePrivateKeyObjectWithLabel:keyLabel forEmail:emailString inContext:keyContext];

    if(makeCurrentKey)
        [privateKey associateKeyWithEmail:emailString forceMakeCurrent:makeCurrentKey inContext:keyContext];

    [privateKey setVersion:MYNIGMA_VERSION];

    [privateKey setPrivateDecrKeyRef:decRef];
    [privateKey setPrivateSignKeyRef:sigRef];
    [privateKey setPublicEncrKeyRef:encRef];
    [privateKey setPublicVerifyKeyRef:verRef];

    [privateKey setIsCompromised:@(isCompromised)];
    [privateKey setDateCreated:dateCreated];
    [privateKey setFirstAnchored:dateCreated];

    NSError* error = nil;

    [KEY_CONTEXT obtainPermanentIDsForObjects:@[privateKey] error:&error];

    if(error)
        NSLog(@"Error obtaining permanent ID for newly added private key: %@", error);

    NSManagedObjectID* objectID = privateKey.objectID;

    dispatch_sync([MynigmaPublicKey keyIndexQueue], ^{

        self.keyIndex[keyLabel] = objectID;
    });
    
    if(privateKey && existingPublicKey)
        [keyContext deleteObject:existingPublicKey];
    
    return privateKey;
}


+ (void)asyncMakeNewPrivateKeyWithLabel:(NSString*)keyLabel forEmail:(NSString*)emailString withDecRef:(NSData*)decRef andSigRef:(NSData*)sigRef andEncRef:(NSData*)encRef andVerRef:(NSData*)verRef makeCurrentKey:(BOOL)makeCurrentKey dateCreated:(NSDate*)dateCreated isCompromised:(BOOL)isCompromised withCallback:(void(^)(void))callback
{
    if([MynigmaPrivateKey havePrivateKeyWithLabel:keyLabel])
        return;

    [ThreadHelper runAsyncOnKeyContext:^{

        [MynigmaPrivateKey syncMakeNewPrivateKeyWithLabel:keyLabel forEmail:emailString withDecRef:decRef andSigRef:sigRef andEncRef:encRef andVerRef:verRef dateCreated:dateCreated isCompromised:isCompromised makeCurrentKey:makeCurrentKey inContext:KEY_CONTEXT];

        if(callback)
            callback();
    }];
}

+ (void)syncMakeNewPrivateKeyWithEncData:(NSData*)encData andVerKeyData:(NSData*)verData decKeyData:(NSData*)decData sigKeyData:(NSData*)sigData forEmail:(NSString*)email keyLabel:(NSString*)keyLabel
{
    [ThreadHelper runSyncOnKeyContext:^(NSManagedObjectContext *keyContext) {

        [MynigmaPrivateKey syncMakeNewPrivateKeyWithEncKeyData:encData andVerKeyData:verData decKeyData:decData sigKeyData:sigData forEmail:email keyLabel:keyLabel inContext:keyContext];
    }];
}


+ (MynigmaPrivateKey*)syncMakeNewPrivateKeyWithEncKeyData:(NSData*)encData andVerKeyData:(NSData*)verData decKeyData:(NSData*)decData sigKeyData:(NSData*)sigData forEmail:(NSString*)email keyLabel:(NSString*)keyLabel inContext:(NSManagedObjectContext*)keyContext
{
    if(!keyLabel || !encData || !verData || !decData || !sigData)
    {
        NSLog(@"Cannot make new private key with label %@ and data %@, %@, %@, %@", keyLabel, encData, verData, decData, sigData);
        return nil;
    }

    MynigmaPublicKey* publicKey = [MynigmaPublicKey publicKeyWithLabel:keyLabel inContext:keyContext];

    if(publicKey)
    {
        //already have a public key - if it's a private key the only thing left to do is check that the data matches
        if([publicKey isKindOfClass:[MynigmaPrivateKey class]])
        {
            if([(MynigmaPrivateKey*)publicKey matchesEncData:encData decData:decData verData:verData sigData:sigData])
                return (MynigmaPrivateKey*)publicKey;
            else
                return nil;
        }
        else
        {
            //it's a public key, not a private one
            //first check if the (partial) data matches, then replace the old key with a new, private one
            if([publicKey matchesEncData:encData andVerData:verData])
            {
                MynigmaPrivateKey* privateKey = [MynigmaPrivateKey makePrivateKeyObjectWithLabel:keyLabel forEmail:email.canonicalForm inContext:keyContext];

                [privateKey setCurrentKeyForEmail:publicKey.currentKeyForEmail];
                [privateKey setIntroducesKeys:publicKey.introducesKeys];
                [privateKey setIsIntroducedByKeys:publicKey.isIntroducedByKeys];

                [privateKey setKeyForEmail:publicKey.keyForEmail];

                if(![KeychainHelper addPrivateKeyWithLabel:keyLabel toKeychainWithEncData:encData verData:verData decData:decData sigData:sigData])
                {
                    NSLog(@"Failed to add private key to keychain - public key already existed...");
                }

                //remove the public key, because we now have a private key instead
                [keyContext deleteObject:publicKey];

                NSError* error = nil;

                [keyContext save:&error];

                if(error)
                {
                    NSLog(@"Error saving key context after creating private key and deleting public one %@", error);
                }

                [CoreDataHelper save];

                return privateKey;
            }
            else
            {
                //no luck, the key doesn't match
                return nil;
            }
        }
    }
    else
    {
        //ok, no key with such a label exists so far. add a new one:

        //first deal with the keychain
        //we can't have zombie key objects wandering around
        //that don't have a corresponding item in the keychain
        NSArray* persistentRefs = nil;

        if([KeychainHelper havePrivateKeychainItemWithLabel:keyLabel])
        {
            if([KeychainHelper doesPrivateKeychainItemWithLabel:keyLabel matchDecData:decData sigData:sigData encData:encData verData:verData])
            {
                persistentRefs = [KeychainHelper persistentRefsForPrivateKeychainItemWithLabel:keyLabel];
            }
            else
            {
                //this may very well happen: keys are exported with a passphrase

                //TO DO: look into the possibility of exporting keys without a passphrase (perhaps after setting an appropriate ACL entry)

                persistentRefs = [KeychainHelper persistentRefsForPrivateKeychainItemWithLabel:keyLabel];

                NSLog(@"Trying to add private key that doesn't match the data already in the keychain!!");

                //overwrite

                //return nil;
            }
        }
        else
        {
            //add a fresh keychain item
            persistentRefs = [KeychainHelper addPrivateKeyWithLabel:keyLabel toKeychainWithEncData:encData verData:verData decData:decData sigData:sigData];
        }

        if(persistentRefs.count == 4)
        {
            MynigmaPrivateKey* privateKey = [MynigmaPrivateKey makePrivateKeyObjectWithLabel:keyLabel forEmail:email.lowercaseString inContext:keyContext];

            [privateKey setPrivateDecrKeyRef:persistentRefs[0]];
            [privateKey setPrivateSignKeyRef:persistentRefs[1]];
            [privateKey setPublicEncrKeyRef:persistentRefs[2]];
            [privateKey setPublicVerifyKeyRef:persistentRefs[3]];

            [privateKey setIsCompromised:@NO];

            NSError* error = nil;

            [keyContext save:&error];

            if(error)
            {
                NSLog(@"Error saving key context after adding private key to keychain!! %@", error);
            }

            [CoreDataHelper save];
            return privateKey;
        }
        else
        {
            NSLog(@"Failed to add private key with label %@ and data %@, %@, %@, %@ to keychain!!!", keyLabel, encData, verData, decData, sigData);
            
            return nil;
        }
    }
}



+ (BOOL)removePrivateKeyWithLabel:(NSString*)keyPairLabel alsoRemoveFromKeychain:(BOOL)alsoRemoveFromKeychain
{
    __block BOOL returnValue = NO;
    
    [ThreadHelper runSyncOnKeyContext:^(NSManagedObjectContext* keyContext)
     {
         MynigmaPrivateKey* keyPair = [MynigmaPrivateKey privateKeyWithLabel:keyPairLabel inContext:keyContext];

         [keyPair removeCurrentForEmailAddress:keyPair.currentForEmailAddress];

         if(alsoRemoveFromKeychain)
             [KeychainHelper removePrivateKeychainItemWithLabel:keyPairLabel];

         if(keyPairLabel)
         {
             NSManagedObjectID* objectID = keyPair.objectID;

             dispatch_sync([MynigmaPublicKey keyIndexQueue], ^{

                 if([[[MynigmaPublicKey keyIndex] objectForKey:keyPairLabel] isEqual:objectID])
                     [[MynigmaPublicKey keyIndex] removeObjectForKey:keyPairLabel];
             });
         }

         if([keyPair isKindOfClass:[MynigmaPrivateKey class]])
         {
             [keyContext deleteObject:keyPair];
         }

         //just in case a MynigmaPublicKey has been added, too...
         [MynigmaPublicKey removePublicKeyWithLabel:keyPairLabel alsoRemoveFromKeychain:alsoRemoveFromKeychain];
         
         NSError* error = nil;
         
         [keyContext save:&error];
         
         if(error)
         {
             NSLog(@"Error saving key context after updating public keychain refs! %@", error);
         }
         
         [CoreDataHelper save];
         
         returnValue = (error != nil);
     }];
    
    return returnValue;
}




@end
