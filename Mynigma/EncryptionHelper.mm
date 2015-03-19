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





#import "TargetConditionals.h"

#if TARGET_OS_IPHONE

#import <Security/SecKey.h>

#else

#endif

#import "AppDelegate.h"
#import "KeychainHelper.h"
#import "EncryptionHelper.h"
#import "UserSettings.h"
#import "MynigmaPrivateKey+Category.h"
#import "IMAPAccountSetting+Category.h"
#import "MynigmaDevice.h"
#import "EmailMessage+Category.h"
#import "FileAttachment+Category.h"
#import "MynigmaMessage+Category.h"
#import "EmailRecipient.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>
#import <CoreFoundation/CoreFoundation.h>
#import <Security/Security.h>
#import "MynigmaPublicKey+Category.h"
#import "EmailContactDetail+Category.h"
#import "MynigmaControlMessage.h"
#import "MynigmaDeclaration.h"
#import "Recipient.h"
#import "DataWrapHelper.h"
#import "mynigma.pb.h"
#import "PublicKeyManager.h"
#import "AttachmentsManager.h"
#import "MynigmaPublicKey+Category.h"
#import "AppleEncryptionWrapper.h"
#import "AddressDataHelper.h"
#import "EmailMessageData.h"
#import "NSString+EmailAddresses.h"
#import "MynigmaFeedback.h"
#import "AlertHelper.h"
#import "SelectionAndFilterHelper.h"
#import "OpenSSLWrapper.h"

#import "ProtocolBuffersDataStructure.h"
#import "VersionDataStructure.h"
#import "HMACDataStructure.h"
#import "EncryptedDataStructure.h"
#import "SessionKeyEntryDataStructure.h"
#import "SessionKeys.h"
#import "DecryptionResult.h"






static NSMutableSet* accountsForWhichKeysAreBeingGenerated;

@implementation EncryptionHelper


+ (NSMutableSet*)keyGenerationAccounts
{
    if(!accountsForWhichKeysAreBeingGenerated)
        accountsForWhichKeysAreBeingGenerated = [NSMutableSet new];

    return accountsForWhichKeysAreBeingGenerated;
}


#pragma mark - KEY GENERATION


+ (void)ensureValidCurrentKeyPairForAccount:(IMAPAccountSetting*)accountSetting withCallback:(void(^)(BOOL))callback
{
    [self ensureValidCurrentKeyPairForAccount:accountSetting lookInKeychain:YES withCallback:callback];
}


//if the user has deleted his account and then adds it again this function finds the old key pair in the keychain. otherwise creates a new pair
+ (void)ensureValidCurrentKeyPairForAccount:(IMAPAccountSetting*)accountSetting lookInKeychain:(BOOL)alsoCheckKeychain withCallback:(void(^)(BOOL))callback
{
    __block NSManagedObjectID* accountSettingObjectID = accountSetting.objectID;

    if([[self keyGenerationAccounts] containsObject:accountSettingObjectID])
        return;

    [[self keyGenerationAccounts] addObject:accountSetting.objectID];

    __block NSString* emailAddress = [accountSetting.emailAddress lowercaseString];

    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

    if([MynigmaPrivateKey havePrivateKeyForEmailAddress:emailAddress])
    {
        //current key pair already exists, so simply return success

        callback(YES);

        [[self keyGenerationAccounts] removeObject:accountSettingObjectID];

        return;
    }

    if(!accountSettingObjectID)
        NSLog(@"Account setting ID is nil while trying to create valid current key pair!!!");

    NSArray* publicKeys = [KeychainHelper listPublicKeychainItems];
    NSArray* privateKeys = [KeychainHelper listPrivateKeychainItems];

    NSString* maxSignFloatDate = @"0";
    NSString* maxEncrFloatDate = @"0";

    NSData* latestEncrPersistentPublicRef = nil;
    NSData* latestSignPersistentPublicRef = nil;
    NSData* latestEncrPersistentPrivateRef = nil;
    NSData* latestSignPersistentPrivateRef = nil;

    NSString* maxKeyLabel = @"";

    if(alsoCheckKeychain)
    {
        for(NSDictionary* dict in privateKeys)
        {

        NSString* label = [dict objectForKey:@"labl"];

        if(!label || [label isEqual:[NSNull null]])
            continue;

        NSData* persistentRef = [dict objectForKey:@"v_PersistentRef"];

        NSRange range = [label rangeOfString:@"Mynigma signature key "];

        if(range.location!=NSNotFound && label.length>range.location+range.length) //signature key pair
        {
            NSString* keyLabel = [label substringFromIndex:range.location+range.length];
            range = [keyLabel rangeOfString:@"|"];
            if(range.location==NSNotFound || keyLabel.length<range.location+range.length)
                continue;
            NSString* email = [keyLabel substringToIndex:range.location];
            NSString* floatDateString = [keyLabel substringFromIndex:range.location+range.length];
            if([email isEqualToString:emailAddress])
            {
                if([maxSignFloatDate compare:floatDateString]!=NSOrderedDescending)
                {
                    NSInteger index = [[publicKeys valueForKey:@"labl"] indexOfObject:label];
                    if(index!=NSNotFound)
                    {
                        maxSignFloatDate = floatDateString;
                        latestSignPersistentPrivateRef = persistentRef;
                        latestSignPersistentPublicRef = [[publicKeys objectAtIndex:index] objectForKey:@"v_PersistentRef"];
                        maxKeyLabel = keyLabel;
                    }
//                    else
//                        NSLog(@"No matching public key found for private key! %@", keyLabel);
                }
            }
        }
        else
        {
            range = [label rangeOfString:@"Mynigma encryption key "];
            if(range.location!=NSNotFound && label.length>range.location+range.length) //encryption key pair
            {
                NSString* keyLabel = [label substringFromIndex:range.location+range.length];
                range = [keyLabel rangeOfString:@"|"];
                if(range.location==NSNotFound || keyLabel.length<range.location+range.length)
                    continue;
                NSString* email = [keyLabel substringToIndex:range.location];
                NSString* floatDateString = [keyLabel substringFromIndex:range.location+range.length];
                if([email isEqualToString:emailAddress])
                {
                    if([maxEncrFloatDate compare:floatDateString]!=NSOrderedDescending)
                    {
                        NSInteger index = [[publicKeys valueForKey:@"labl"] indexOfObject:label];
                        if(index!=NSNotFound)
                        {
                            maxEncrFloatDate = floatDateString;
                            latestEncrPersistentPrivateRef = persistentRef;
                            latestEncrPersistentPublicRef = [[publicKeys objectAtIndex:index] objectForKey:@"v_PersistentRef"];
                            maxKeyLabel = keyLabel;
                        }
//                        else
//                            NSLog(@"No matching public key found for private key!");
                    }
                }
            }
        }
    }
    }
        
    if(latestSignPersistentPrivateRef && latestEncrPersistentPrivateRef && [maxEncrFloatDate isEqualToString:maxSignFloatDate])
    {
        NSDate* date = [NSDate dateWithTimeIntervalSince1970:maxEncrFloatDate.floatValue];

        [MynigmaPrivateKey asyncMakeNewPrivateKeyWithLabel:maxKeyLabel forEmail:emailAddress withDecRef:latestEncrPersistentPrivateRef andSigRef:latestSignPersistentPrivateRef andEncRef:latestEncrPersistentPublicRef andVerRef:latestSignPersistentPublicRef makeCurrentKey:YES dateCreated:date isCompromised:NO withCallback:^{

            if(callback)
                callback(YES);

            [[self keyGenerationAccounts] removeObject:accountSettingObjectID];
        }];

        return;
    }
    else
    {
        [MynigmaPrivateKey asyncCreateNewMynigmaPrivateKeyForEmail:emailAddress withCallback:^{
            if(callback)
                callback(YES);

            [[self keyGenerationAccounts] removeObject:accountSettingObjectID];
        }];
    }

    }];
}


//makes a new current key pair - even if one already exists
+ (void)freshCurrentKeyPairForAccount:(IMAPAccountSetting*)accountSetting withCallback:(void(^)(BOOL))callback
{
    [MynigmaPrivateKey asyncCreateNewMynigmaPrivateKeyForEmail:accountSetting.emailAddress withCallback:^{
        if(callback)
            callback(YES);
    }];
}




#pragma mark -
#pragma mark MEDIUM LEVEL ENCRYPTION METHODS
//medium level methods concerned with already wrapped data


//signs some NSData using the key pair with the specified label
+ (NSData*)signData:(NSData*)data withKeyPairLabel:(NSString*)keyPairLabel withFeedback:(MynigmaFeedback**)mynigmaFeedback
{
    if(![MynigmaPrivateKey havePrivateKeyWithLabel:keyPairLabel])
    {
//        NSLog(@"No suitable private key available!!");
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaSignatureErrorNoKeyForKeyLabel];
        return nil;
    }
    
    if(!data.length)
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaSignatureErrorRSANoData];
        return nil;
    }

    NSData* hashedData = [AppleEncryptionWrapper SHA512DigestOfData:data];

    NSData* signedDataBlob = [AppleEncryptionWrapper RSASignHash:hashedData withKeyLabel:keyPairLabel withFeedback:mynigmaFeedback];

    if(!signedDataBlob.length || *mynigmaFeedback)
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaSignatureErrorEmptySignedData];
        return nil;
    }
    
    return [DataWrapHelper wrapSignedData:data signedDataBlob:signedDataBlob keyLabel:keyPairLabel withFeedback:mynigmaFeedback];
}

//signs a hash value with the private key associated with the specified keyLabel
+ (NSData*)signHash:(NSData*)mHash withKeyWithLabel:(NSString*)keyLabel withFeedback:(MynigmaFeedback**)mynigmaFeedback
{
    if(!keyLabel.length)
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaSignatureErrorNoKeyLabel];
        return nil;
    }
    
    return [AppleEncryptionWrapper RSASignHash:mHash withKeyLabel:keyLabel withFeedback:mynigmaFeedback];
    
//    return [OpenSSLWrapper PSS_RSAsignHash:mHash withKeyWithLabel:keyLabel withFeedback:mynigmaFeedback];
}

+ (MynigmaFeedback*)verifySignature:(NSData*)signatureData ofHash:(NSData*)hashedData version:(NSString*)version withKeyLabel:(NSString*)keyLabel
{
    if(!keyLabel.length)
    {
        return [MynigmaFeedback feedback:MynigmaVerificationErrorNoKeyLabel];
    }
    
//    if([version compare:@"2.11"] == NSOrderedAscending)
//    {
        //old version (less than 2.11.00)
        return [AppleEncryptionWrapper RSAVerifySignature:signatureData ofHash:hashedData version:version withKeyLabel:keyLabel];
//    }
//    else
//        return [OpenSSLWrapper PSS_RSAverifySignature:signatureData ofHash:hashedData withKeyLabel:keyLabel];

}


+ (NSData*)HMACOfData:(NSData*)data withKey:(NSData*)key
{
    return [AppleEncryptionWrapper HMACForMessage:data withSecret:key];
}

+ (BOOL)verifyHMAC:(NSData*)HMAC ofData:(NSData*)data withKey:(NSData*)key
{
    NSData* computedHMAC = [AppleEncryptionWrapper HMACForMessage:data withSecret:key];
    
    if(!computedHMAC.length || !HMAC.length)
    {
        return NO;
    }
    
    return [computedHMAC isEqual:HMAC];
}


//encrypts some NSData with the specified public keys - also encrypts the attachments passed along
+ (NSData*)encryptData:(NSData*)data withEncryptionKeyLabels:(NSArray*)encryptionKeyLabels expectedSignatureKeyLabels:(NSArray*)expectedSignatureKeyLabels signatureKeyLabel:(NSString*)signatureKeyLabel andAttachments:(NSArray*)attachments inContext:(NSManagedObjectContext*)localContext withFeedback:(MynigmaFeedback**)mynigmaFeedback
{
    [ThreadHelper ensureLocalThread:localContext];

    NSData* sessionKeyData = [AppleEncryptionWrapper generateNewAESSessionKeyData];
    
    NSData* HMACSecretData = [AppleEncryptionWrapper generateNewHMACSecret];
    
    SessionKeys* sessionKeys = [[SessionKeys alloc] initWithAESSessionKey:sessionKeyData andHMACSecret:HMACSecretData];

    NSData* encryptedMessageData = [AppleEncryptionWrapper AESencryptData:data withSessionKeyData:sessionKeyData withFeedback:mynigmaFeedback];

    if(!encryptedMessageData.length || *mynigmaFeedback)
    {
        NSLog(@"Encrypted message data is invalid: %@!!!",encryptedMessageData);
        return nil;
    }

    if(encryptionKeyLabels.count != expectedSignatureKeyLabels.count)
    {
        NSLog(@"Cannot encrypt message: expected key labels and encryption key labels have different counts!!! %ld vs. %ld", (long)encryptionKeyLabels.count, (long)expectedSignatureKeyLabels.count);
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaEncryptionErrorKeyAndLabelCountMismatch];
        return nil;
    }

    mynigma::encryptedData* encryptedData = new mynigma::encryptedData;
    encryptedData->set_version([MYNIGMA_VERSION UTF8String]);
    encryptedData->set_encrmessagedata((char*)[encryptedMessageData bytes], [encryptedMessageData length]);

    
    //first wrap the key introductions
    //for each recipient, take the key the recipient is deemed to expect and use it to sign the key the message is actually signed with
    for(NSInteger index = 0; index < encryptionKeyLabels.count; index++)
    {
        NSString* encryptionKeyLabel = encryptionKeyLabels[index];

        //the expected signature key label is the label of the key that the recipient is deemed to expect
        //it will be used to introduce the actual signature key
        NSString* expectedSignatureKeyLabel = expectedSignatureKeyLabels[index];

        mynigma::encrSessionKeyEntry* entry = encryptedData->add_encrsessionkeytable();

        entry->set_keylabel([encryptionKeyLabel UTF8String]);

        NSData* encryptedSessionKeyData = [AppleEncryptionWrapper RSAencryptData:sessionKeys.concatenatedKeys withPublicKeyLabel:encryptionKeyLabel withFeedback:nil];

        entry->set_encrsessionkey((char*)[encryptedSessionKeyData bytes], [encryptedSessionKeyData length]);

        
            NSData* introductionData = [PublicKeyManager introductionDataFromKeyLabel:expectedSignatureKeyLabel toKeyLabel:signatureKeyLabel];

            if(introductionData)
            {
                //NSData* encryptedIntroductionData = [EncryptionHelper RSAencryptData:introductionData withPublicKey:[self publicKeyWithLabel:publicKeyLabel forEncryption:YES]];
                NSData* encryptedIntroductionData = [AppleEncryptionWrapper AESencryptData:introductionData withSessionKeyData:sessionKeyData withFeedback:nil];

                if(encryptedIntroductionData)
                    entry->set_introductiondata((char*)encryptedIntroductionData.bytes, encryptedIntroductionData.length);
            }
    }

    //add another session key table entry for the signature key
    mynigma::encrSessionKeyEntry* entry = encryptedData->add_encrsessionkeytable();

    entry->set_keylabel([signatureKeyLabel UTF8String]);

    NSData* encryptedSessionKeyData = [AppleEncryptionWrapper RSAencryptData:sessionKeys.concatenatedKeys withPublicKeyLabel:signatureKeyLabel withFeedback:mynigmaFeedback];
    
    if(mynigmaFeedback && *mynigmaFeedback)
    {
        //there was an error encrypting the session key
        //the details are in the feedback structure
        return nil;
    }

    entry->set_encrsessionkey((char*)[encryptedSessionKeyData bytes], [encryptedSessionKeyData length]);

    //now encrypt each attachment and store the result in encryptedData
    for(FileAttachment* fileAttachment in attachments)
    {
        NSData* unencryptedData = [fileAttachment data];

        if(!unencryptedData)
        {
//            NSLog(@"File attachment for message to be encrypted is not downloaded: %@", fileAttachment);

            if(mynigmaFeedback)
                *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaEncryptionErrorAttachmentHasNoData];

            //            [AlertHelper showAlertWithMessage:NSLocalizedString(@"One of the attachments has not yet been downloaded.", @"Error dialog shown while encrypting message") informativeText:NSLocalizedString(@"Please try again when the download has completed.", @"Error dialog shown while encrypting message")];

            return nil;
        }

        NSData* encryptedAttachmentData = [AppleEncryptionWrapper AESencryptData:unencryptedData withSessionKeyData:sessionKeyData withFeedback:mynigmaFeedback];

        if(!encryptedAttachmentData.length || (mynigmaFeedback && *mynigmaFeedback))
        {
            //an error was encountered during AES encryption
            return nil;
        }
        
        NSData* HMACForAttachment = [AppleEncryptionWrapper HMACForMessage:encryptedAttachmentData withSecret:sessionKeys.HMACSecret];
        
        encryptedData->add_attachmentshmac(HMACForAttachment.bytes, HMACForAttachment.length);
        
        [fileAttachment saveDataToPrivateEncryptedURL:encryptedAttachmentData];
    }
    
    int encrData_size = encryptedData->ByteSize();
    void* encr_data = malloc(encrData_size);
    encryptedData->SerializeToArray(encr_data, encrData_size);

    NSData* serialisedEncryptedData = [[NSData alloc] initWithBytes:encr_data length:encrData_size];;
    free(encr_data);
    delete encryptedData;
    
    NSData* HMAC = [self HMACOfData:serialisedEncryptedData withKey:sessionKeys.HMACSecret];
    
    NSString* version = MYNIGMA_VERSION;
    
    //now append an HMAC
    HMACDataStructure* HMACStructure = [[HMACDataStructure alloc] initWithEncryptedData:serialisedEncryptedData HMAC:HMAC version:version];

    return HMACStructure.serialisedData;
}

+ (NSString*)extractVersionFromData:(NSData*)data
{
    VersionDataStructure* versionDataStructure = [VersionDataStructure parseFromProtocolBuffersData:data];
    
    return versionDataStructure.version;
}


+ (DecryptionResult*)decryptData:(NSData*)data fromEmail:(NSString*)emailString toEmails:(NSArray*)recipientEmails inContext:(NSManagedObjectContext*)localContext withFeedback:(MynigmaFeedback**)mynigmaFeedback
{
    [ThreadHelper ensureLocalThread:localContext];

    NSString* versionString = [self extractVersionFromData:data];
    
    if([versionString compare:@"2.11"] != NSOrderedDescending)
    {
        //it's an old version without an HMAC
        //warn the user and continue with the legacy method
        
        NSArray* LEGACY_decryptionResult = [self LEGACY_decryptData:data fromEmail:emailString toEmails:recipientEmails inContext:localContext withFeedback:mynigmaFeedback];
        
        DecryptionResult* result = [[DecryptionResult alloc] initWithDecryptedData:LEGACY_decryptionResult.firstObject HMACSecretData:nil AESSessionKey:LEGACY_decryptionResult.lastObject attachmentHMACS:nil deprecatedVersion:YES];
        
        return result;
    }
    
    //OK, it's the new version
    //go ahead with HMAC verification
    
    HMACDataStructure* HMACStructure = [HMACDataStructure parseFromProtocolBuffersData:data];
    
    NSData* encryptedData = HMACStructure.encryptedData;
    
    if(!encryptedData.length)
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorNoData];
        return nil;
    }
    
    EncryptedDataStructure* encryptedDataStructure = [EncryptedDataStructure parseFromProtocolBuffersData:encryptedData];
    
    BOOL keyFound = NO;
    NSString* keyPairLabel = nil;
    NSData* encrSessionKeyData = nil;
    NSData* encrIntroData = nil;
    
    NSMutableArray* keyLabels = [NSMutableArray new];
    
    //first find the correct keyLabel
    for(SessionKeyEntryDataStructure* sessionKeyEntry in encryptedDataStructure.encrSessionKeyTable)
    {
        NSString* keyLabel = sessionKeyEntry.keyLabel;
        
        if(keyLabel.length)
        {
            [keyLabels addObject:keyLabel];
            
            BOOL foundKeyPairLabel = [MynigmaPrivateKey havePrivateKeyWithLabel:keyLabel];
            if(foundKeyPairLabel)
            {
                keyPairLabel = keyLabel;
                encrSessionKeyData = sessionKeyEntry.encrSessionKey;
                encrIntroData = sessionKeyEntry.introductionData;
                keyFound = YES;
                break;
            }
        }
        else
            NSLog(@"One of the key labels was empty");
    }
    
    
    if(!keyFound)
    {
        //        NSLog(@"\n\nError: decryption key missing!!");
        //        NSLog(@"\nKey labels: %@", keyLabels);
        
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorNoKey];
        return nil;
    }
    
    if(!encrSessionKeyData.length)
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorNoData];
        return nil;
    }
    
    //a key was found
    SessionKeys* sessionKeys = [AppleEncryptionWrapper RSAdecryptData:encrSessionKeyData withPrivateKeyLabel:keyPairLabel withFeedback:mynigmaFeedback];
    
    if(mynigmaFeedback && *mynigmaFeedback && [*mynigmaFeedback isError])
    {
        //an error was encountered during RSA decryption
        //details are in the feedback object
        return nil;
    }
    
    if(sessionKeys)
    {
        if(![self verifyHMAC:HMACStructure.HMAC ofData:encryptedData withKey:sessionKeys.HMACSecret])
        {
            if(mynigmaFeedback)
                *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorInvalidHMAC];
            
            return nil;
        }
        
        NSData* messageData = encryptedDataStructure.encrMessageData;
        
        //if there is a key introduction process this before attempting to decrypt the message
        if(encrIntroData.length)
        {
            //no feedback needs to be provided, as errors in introduction parsing shouldn't be presented to the user
            NSData* decryptedIntroductionData = [AppleEncryptionWrapper AESdecryptData:encrIntroData withSessionKeyData:sessionKeys.AESSessionKey withFeedback:nil];
            
            [PublicKeyManager processIntroductionData:decryptedIntroductionData fromEmail:emailString toEmails:recipientEmails];
        }
        
        NSData* decryptedData = [AppleEncryptionWrapper AESdecryptData:messageData withSessionKeyData:sessionKeys.AESSessionKey withFeedback:mynigmaFeedback];
        
        if(decryptedData.length && !(mynigmaFeedback && *mynigmaFeedback && [*mynigmaFeedback isError]))
        {
            return [[DecryptionResult alloc] initWithDecryptedData:decryptedData HMACSecretData:sessionKeys.HMACSecret AESSessionKey:sessionKeys.AESSessionKey attachmentHMACS:encryptedDataStructure.attachmentHMACs deprecatedVersion:NO];
        }
        else
        {
            //            NSLog(@"Failed to decrypt main message data!!!");
            if(mynigmaFeedback && !*mynigmaFeedback)
                *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorMessageCorrupt];
            
            return nil;
        }
    }
    else
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorNoSessionKey];
        
        return nil;
    }
}

//returns a pair of the form (decryptedData, sessionKey)
+ (NSArray*)LEGACY_decryptData:(NSData*)data fromEmail:(NSString*)emailString toEmails:(NSArray*)recipientEmails inContext:(NSManagedObjectContext*)localContext withFeedback:(MynigmaFeedback**)mynigmaFeedback
{
    mynigma::encryptedData* encryptedData = new mynigma::encryptedData;

    encryptedData->ParseFromArray([data bytes], (int)[data length]);
    BOOL keyFound = NO;
    NSString* keyPairLabel = nil;
    NSData* encrSessionKeyData = nil;
    NSData* encrIntroData = nil;

    NSMutableArray* keyLabels = [NSMutableArray new];

    //first find the correct keyLabel
    for(int i=0;i<encryptedData->encrsessionkeytable_size();i++)
    {
        mynigma::encrSessionKeyEntry* entry = new mynigma::encrSessionKeyEntry;
        *entry = encryptedData->encrsessionkeytable(i);

        NSData* keyLabelData = [[NSData alloc] initWithBytes:entry->keylabel().data() length:entry->keylabel().size()];
        NSData* foundEncrSessionKeyData = [[NSData alloc] initWithBytes:entry->encrsessionkey().data() length:entry->encrsessionkey().size()];

        NSData* foundEncrIntroData = [[NSData alloc] initWithBytes:entry->introductiondata().data() length:entry->introductiondata().size()];

        NSString* keyLabel = [[NSString alloc] initWithData:keyLabelData encoding:NSUTF8StringEncoding];
        if(keyLabel && keyLabel.length>0)
        {
            [keyLabels addObject:keyLabel];

            BOOL foundKeyPairLabel = [MynigmaPrivateKey havePrivateKeyWithLabel:keyLabel];
            if(foundKeyPairLabel)
            {
                keyPairLabel = keyLabel;
                encrSessionKeyData = foundEncrSessionKeyData;
                encrIntroData = foundEncrIntroData;
                keyFound = YES;
                break;
            }
        }
        else
            NSLog(@"One of the key labels was empty");
        delete entry;
    }


    if(!keyFound)
    {
//        NSLog(@"\n\nError: decryption key missing!!");
//        NSLog(@"\nKey labels: %@", keyLabels);

        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorNoKey];
        return nil;
    }

    if(encrSessionKeyData.length==0)
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorNoData];
        return nil;
    }

    //a key was found
    NSData* sessionKeyData = [AppleEncryptionWrapper LEGACY_RSAdecryptData:encrSessionKeyData withPrivateKeyLabel:keyPairLabel withFeedback:mynigmaFeedback];

    if(*mynigmaFeedback)
    {
        //an error was encountered during RSA decryption
        //details are in the feedback object
        return nil;
    }
    
    if(sessionKeyData)
    {
        NSData* messageData = [[NSData alloc] initWithBytes:encryptedData->encrmessagedata().data() length:encryptedData->encrmessagedata().size()];
        //NSData* versionData = [[NSData alloc] initWithBytes:encryptedData->version().data() length:encryptedData->version().size()];

        //NSLog(@"Version: %@",[[NSString alloc] initWithData:versionData encoding:NSUTF8StringEncoding]);

        delete encryptedData;

        //if there is a key introduction process this before attempting to decrypt the message
        if(encrIntroData.length)
        {
            //no feedback needs to be provided, as errors in introduction parsing shouldn't be presented to the user
            NSData* decryptedIntroductionData = [AppleEncryptionWrapper AESdecryptData:encrIntroData withSessionKeyData:sessionKeyData withFeedback:nil];

            [PublicKeyManager processIntroductionData:decryptedIntroductionData fromEmail:emailString toEmails:recipientEmails];
        }

        NSData* decryptedData = [AppleEncryptionWrapper AESdecryptData:messageData withSessionKeyData:sessionKeyData withFeedback:mynigmaFeedback];

        if(decryptedData.length && !(mynigmaFeedback && *mynigmaFeedback))
        {
            return @[decryptedData, sessionKeyData];
        }
        else
        {
//            NSLog(@"Failed to decrypt main message data!!!");
            if(mynigmaFeedback)
                *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorMessageCorrupt];

            return nil;
        }
    }
    else
    {
        delete encryptedData;

        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorNoSessionKey];

        return nil;
    }
}

//unwraps and verifies the signature of data
+ (MynigmaFeedback*)unwrapAndVerifySignature:(NSData*)data withMessage:(MynigmaMessage*)message andAttachmentHMACs:(NSArray*)attachmentHMACs
{
    //parse the protocol buffers structure "signedData"
    mynigma::signedData* signedData = new mynigma::signedData;
    signedData->ParseFromArray([data bytes], (int)[data length]);
    NSData* keyLabelData = [[NSData alloc] initWithBytes:signedData->keylabel().data() length:signedData->keylabel().size()];
    NSData* messageData = [[NSData alloc] initWithBytes:signedData->data().data() length:signedData->data().size()];
    NSData* signatureData = [[NSData alloc] initWithBytes:signedData->signature().data() length:signedData->signature().size()];
    NSData* versionData = [[NSData alloc] initWithBytes:signedData->version().data() length:signedData->signature().size()];
    
    if(!messageData.length)
    {
        return [MynigmaFeedback feedback:MynigmaDecryptionErrorNoMessageData];
    }

    if(!keyLabelData.length)
    {
        return [MynigmaFeedback feedback:MynigmaVerificationErrorNoKeyLabelData];
    }
    
    NSString* version = [[NSString alloc] initWithData:versionData encoding:NSUTF8StringEncoding];

    MynigmaFeedback* feedback = nil;

    //unwrap the data
    //need the sender address specified in the signed part to verify the signature
    //after all, this is the address that will be displayed to the user
    [DataWrapHelper unwrapMessageData:messageData intoMessage:message withAttachmentHMACS:attachmentHMACs andFeedback:&feedback];

    if([feedback isError])
    {
        return feedback;
    }
    
    
    //the signature key label
    NSString* signatureKeyLabel = [[NSString alloc] initWithData:keyLabelData encoding:NSUTF8StringEncoding];

    if(!signatureKeyLabel.length)
        return [MynigmaFeedback feedback:MynigmaVerificationErrorNoKeyLabel];

    //find the matching key
    BOOL havePublicKey = [MynigmaPublicKey havePublicKeyWithLabel:signatureKeyLabel];

    if(!havePublicKey)
    {
        return [MynigmaFeedback feedback:MynigmaVerificationErrorNoKey];
    }

    NSData* hashedMessageData = [AppleEncryptionWrapper SHA512DigestOfData:messageData];

    MynigmaFeedback* verificationFeedback = [AppleEncryptionWrapper RSAVerifySignature:signatureData ofHash:hashedMessageData version:version withKeyLabel:signatureKeyLabel];
    
    if(verificationFeedback.isError)
    {
        NSLog(@"Error: signature could not be verified!");
        return verificationFeedback;
    }

    //if there is a problem with the signature, display an error or a warning
    //errors are unrecoverable (e.g.: "No session key provided")
    //warnings are shown in addition to the decrypted data (e.g. "This message was encrypted using S/MIME with a weak hash (SHA1)")
    //some errors can be overridden by the user if necessary (e.g.: "This message was signed using an old version of Mynigma. Would you like to display it anyway?")
    //they will usually turn into warnings

    EmailRecipient* senderEmail = [AddressDataHelper senderAsEmailRecipientForMessage:message addIfNotFound:NO];

    NSString* emailAddress = senderEmail.email;

    //introductions are parts of a MynigmaMessage that present the public key the message was signed with
    //if the recipient is known to expect a different signature key, the introduction will be signed using that key
    //upon parsing the introduction, the recipient will update the expected signature key
    //the introductions have already been parsed at this point, so the signature key should now be the expected key for the sender

    BOOL validKey = [MynigmaPublicKey isKeyWithLabel:signatureKeyLabel validForSignatureFromEmail:emailAddress];

    if(!validKey)
    {
//        BOOL keyUsedToBeValid = [MynigmaPublicKey wasKeyWithLabel:signatureKeyLabel previouslyValidForSignatureFromEmail:emailAddress];
//
//        if(keyUsedToBeValid)
//            return [MynigmaFeedback feedback:MynigmaVerificationErrorPreviouslyValidKey];

        return [MynigmaFeedback feedback:MynigmaVerificationErrorInvalidSignature];
    }

    /*
    //check if the version is current enough
    //deprecated versions of Mynigma should produce a warning
    if([version compare:DEPRECATED_VERSION] != NSOrderedDescending)
    {
        //there are currently no deprecated versions
        return [MynigmaFeedback verificationWarningDeprecatedMynigmaVersion];
    }
    
    //deprecated versions of Mynigma known to be
    if([version compare:DEPRECATED_VERSION] == NSOrderedDescending)
    {
        //there are currently no deprecated versions
        return [MynigmaFeedback verificationWarningDeprecatedMynigmaVersion];
    }
    */

    //this indicates success
    return [MynigmaFeedback feedback:MynigmaVerificationSuccess];
}





#pragma mark -
#pragma mark SYNCHRONOUS MESSAGE ENCRYPTION/DECRYPTION


+ (MynigmaFeedback*)syncDecryptMessage:(MynigmaMessage*)message fromData:(NSData *)data
{
    NSManagedObjectContext* localContext = message.managedObjectContext;
    
    [ThreadHelper ensureLocalThread:localContext];

    EmailRecipient* senderEmailRecipient = [AddressDataHelper senderAsEmailRecipientForMessage:message];

    NSString* senderEmail = senderEmailRecipient.email;

    NSArray* recipientsArray = [AddressDataHelper nonSenderEmailRecipientsForMessage:message];

    //first decrypt the data
    MynigmaFeedback* decryptionFeedback = nil;
    
    DecryptionResult* decryptionResult = [self decryptData:data fromEmail:senderEmail toEmails:recipientsArray inContext:localContext withFeedback:&decryptionFeedback];

    if(decryptionFeedback)
    {
        return decryptionFeedback;
    }
    
    
        NSData* decryptedData = decryptionResult.decryptedData;
        NSData* sessionKeyData = decryptionResult.AESSessionKey;
    NSData* HMACSecretData = decryptionResult.HMACSecretData;
    NSArray* attachmentHMACs = decryptionResult.attachmentHMACs;

    //sanity check:
    //decryptData should return data whenever the feedback is nil
        if(decryptedData && sessionKeyData && HMACSecretData)
        {
            [message setSessionKeyData:sessionKeyData];
            [message setHmacSecretData:HMACSecretData];

            //now unwrap the data and verify the signature

            //now check that the signature is valid
            MynigmaFeedback* signatureVerificationFeedback = [self unwrapAndVerifySignature:decryptedData withMessage:message andAttachmentHMACs:attachmentHMACs];

            if(decryptionResult.deprecatedVersion)
            {
                MynigmaFeedback* feedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorOldEncryptionFormat];

                if(signatureVerificationFeedback.code > 0)
                    feedback.additionalCode = @(signatureVerificationFeedback.code);
                
                return feedback;
            }

            //will be [MynigmaFeedback verificationSuccess] if the signature verification succeeded
            return signatureVerificationFeedback;
        }

    //this should never happen, whatever the input
    return [MynigmaFeedback feedback:MynigmaDecryptionErrorInternalError];
}




+ (NSData*)syncDecryptFileAttachment:(FileAttachment*)fileAttachment inContext:(NSManagedObjectContext*)localContext withFeedback:(MynigmaFeedback**)mynigmaFeedback
{
    [ThreadHelper ensureLocalThread:localContext];

    MynigmaMessage* message = (MynigmaMessage*)fileAttachment.attachedAllToMessage;
    if(!message || ![message isKindOfClass:[MynigmaMessage class]])
    {
//        NSLog(@"Failed to create message for attachment decryption!!!");
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorInvalidAttachmentObjectID];
        return nil;
        //        return @{RESULT:@"Failed to create message in local context."};
    }

    if(!message.sessionKeyData)
    {
//        NSLog(@"Message has no session key data, so attachment cannot be decrypted!!!");
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorNoSessionKey];
        return nil;
//        return @{RESULT:@"The message has no session key data"};
    }

    NSData* encryptedData = [fileAttachment encryptedData];

    if(!encryptedData.length)
    {
//        NSLog(@"This attachment has not yet been downloaded");
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorAttachmentNotDownloaded];
        return nil;
//        return @{RESULT:@"Not yet downloaded"};
    }
    
    //check the HMAC, if present
    if(fileAttachment.hmacValue && ![self verifyHMAC:fileAttachment.hmacValue ofData:encryptedData withKey:message.hmacSecretData])
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorInvalidHMAC];
        return nil;
    }

    NSData* decryptedData = [AppleEncryptionWrapper AESdecryptData:encryptedData withSessionKeyData:message.sessionKeyData withFeedback:mynigmaFeedback];

    if(!decryptedData.length || (mynigmaFeedback && *mynigmaFeedback))
    {
        return nil;
    }
    
    NSData* decryptedDataHash = [AppleEncryptionWrapper SHA512DigestOfData:decryptedData];

    if(!decryptedDataHash.length)
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorAttachmentHashIsEmpty];
        return nil;
    }
    
    //compare the computed hash of the decrypted data to the expected hashValue provided in the message body
    
    if(!fileAttachment.hashedValue.length)
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorNoHashValue];
        return nil;
    }

    if([decryptedDataHash isEqualToData:fileAttachment.hashedValue])
    {
        [fileAttachment saveDataToPrivateURL:decryptedData];

        NSError* error = nil;
        [localContext save:&error];
        if(error)
        {
            NSLog(@"Error saving local context after attachment decryption!!! %@",error);
        }

        [SelectionAndFilterHelper refreshMessage:message.objectID];
        [CoreDataHelper save];

        return decryptedData;
    }
    else
    {
        NSLog(@"Invalid hash!!!");
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorInvalidHash];
        
        return nil;
    }

}

//synchronously signs a message with the private key whose label is provided and then encrypts it with the specified public keys
+ (NSData*)syncEncryptMessage:(MynigmaMessage*)message withSignatureKeyLabel:(NSString*)signKeyLabel encryptionKeyLabels:(NSArray*)encryptionKeys expectedSignatureKeyLabels:(NSArray*)expectedSignatureKeys inLocalContext:(NSManagedObjectContext*)localContext withMynigmaFeedback:(MynigmaFeedback**)mynigmaFeedback
{
    [ThreadHelper ensureLocalThread:localContext];

    NSData* payloadPartData = [DataWrapHelper wrapMessage:message];

    if(!payloadPartData.length)
    {
//        NSLog(@"Payload data is nil!!!");
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaEncryptionErrorEmptyPayload];
        return nil;
    }
    
    NSData* signedData = [self signData:payloadPartData withKeyPairLabel:signKeyLabel withFeedback:mynigmaFeedback];

    if(!signedData.length || (mynigmaFeedback && *mynigmaFeedback))
    {
//        NSLog(@"Signature operation failed!!!! %@ - %@", signKeyLabel ,payloadPartData);
        return nil;
    }

    NSData* signedEncryptedData = [self encryptData:signedData withEncryptionKeyLabels:encryptionKeys expectedSignatureKeyLabels:expectedSignatureKeys signatureKeyLabel:signKeyLabel andAttachments:[message.allAttachments sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"contentid" ascending:YES]]] inContext:localContext withFeedback:mynigmaFeedback];

    if(!signedEncryptedData.length || (mynigmaFeedback && *mynigmaFeedback))
    {
//        NSLog(@"MynData is invalid!!!! %@", signedEncryptedData);
        return nil;
    }

    return signedEncryptedData;
}




#pragma mark -
#pragma mark PUBLIC METHODS

//takes an unencrypted MynigmaMessage object and parses it into an encrypted NSData objects that are then attached to the message - the mynAttachment "Secure message.myn" is stored as NSData in message.mynData, the encrypted version of each fileAttachment in fileAttachment.encryptedData
+ (void)asyncEncryptMessage:(NSManagedObjectID *)messageID withSignatureKeyLabel:(NSString *)signKeyLabel expectedSignatureKeyLabels:(NSArray*)expectedLabels encryptionKeyLabels:(NSArray *)encryptionKeyLabels andCallback:(void (^)(MynigmaFeedback*))successCallback
{
    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext)
    {
        //first recreate the message from the object ID
        NSError* error = nil;
        MynigmaMessage* message = (MynigmaMessage*)[localContext existingObjectWithID:messageID error:&error];

        if(error || !message || ![message isKindOfClass:[MynigmaMessage class]])
        {
            NSLog(@"MynigmaMessage could not be reconstructed!!! Error: %@",error);
            if(successCallback)
                successCallback([MynigmaFeedback feedback:MynigmaEncryptionErrorNoMessageForObjectID]);
            return;
        }
        
        MynigmaFeedback* mynigmaFeedback = nil;

        NSData* signedEncryptedData = [self syncEncryptMessage:message withSignatureKeyLabel:signKeyLabel encryptionKeyLabels:encryptionKeyLabels expectedSignatureKeyLabels:expectedLabels inLocalContext:localContext withMynigmaFeedback:&mynigmaFeedback];

        //sign and encrypt the message and its attachments

        if(!signedEncryptedData.length || mynigmaFeedback)
        {
            if(successCallback)
                successCallback(mynigmaFeedback);
            return;
        }
        
        [message setMynData:signedEncryptedData];
        error = nil;
        [localContext save:&error];
        if(error)
        {
            NSLog(@"Error saving local context after creating encrypted myn data!!!");
            if(successCallback)
                successCallback([MynigmaFeedback feedback:MynigmaEncryptionErrorSavingLocalContext]);
        }
        else
        {
            [SelectionAndFilterHelper refreshMessage:messageID];
            if(successCallback)
                successCallback([MynigmaFeedback feedback:MynigmaEncryptionSuccess]);
        }
    }];
}

//decrypts the data and fills a newly created, blank MynigmaMessage object with the decrypted values - then executes the callback with a success/error status code
+ (void)asyncDecryptMessage:(NSManagedObjectID *)messageID  fromData:(NSData *)data withCallback:(void (^)(MynigmaFeedback*))callback
{
    if(data.length==0)
    {
        NSLog(@"Attempting to decrypt empty data!");
        callback([MynigmaFeedback feedback:MynigmaDecryptionErrorNoData]);
        return;
    }

    //don't do this on the main thread: create a dedicated managed object context of private queue concurrency type...
    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

        MynigmaMessage* newMessage = (MynigmaMessage*)[localContext objectWithID:messageID];
        if(!newMessage)
        {
            NSLog(@"Failed to recreate mynigma message from object ID!!!");
            callback([MynigmaFeedback feedback:MynigmaDecryptionErrorNoMessageForObjectID]);
            return;
        }

        MynigmaFeedback* decryptionError = [self syncDecryptMessage:newMessage fromData:data];

        NSString* decryptionStatus = decryptionError?[NSString stringWithFormat:@"%ld", (long)decryptionError.code]:@"OK";

        [newMessage setDecryptionStatus:decryptionStatus];

        NSError* error  = nil;
        [localContext save:&error];
        if(error)
        {
            NSLog(@"Error saving local context after decrypting message: %@",error);
            callback([MynigmaFeedback feedback:MynigmaDecryptionErrorSavingLocalContext]);
            return;
        }

        [SelectionAndFilterHelper refreshMessage:newMessage.objectID];

        callback(decryptionError);
    }];
}

//decrypts the data from an attachment using the session key provided, puts it into the data property and then executes the callback with a win/epic fail story
+ (void)asyncDecryptFileAttachment:(NSManagedObjectID*)attachmentID withCallback:(void(^)(NSData* data, MynigmaFeedback* feedback))callback
{
    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext)
    {
        FileAttachment* fileAttachment = (FileAttachment*)[localContext objectWithID:attachmentID];

        if(!fileAttachment || ![fileAttachment isKindOfClass:[FileAttachment class]])
        {
//            NSLog(@"File attachment could not be recreated!!!");
            callback(nil, [MynigmaFeedback feedback:MynigmaFeedbackDecryptionErrorNoAttachmentForObjectID]);
            return;
        }

        MynigmaFeedback* mynigmaFeedback = nil;
        
        NSData* decryptedData = [self syncDecryptFileAttachment:fileAttachment inContext:localContext withFeedback:&mynigmaFeedback];

        if(decryptedData && !mynigmaFeedback)
        {
            callback(decryptedData, [MynigmaFeedback feedback:MynigmaDecryptionSuccess]);
        }
        else
            callback(nil, mynigmaFeedback);

    }];
}



//#pragma mark -
//#pragma mark TESTING
//
//+ (BOOL)syncEncryptMessageForTesting:(MynigmaMessage*)message withSignatureKeyLabel:(NSString *)signKeyLabel expectedKeyLabels:(NSArray*)expectedKeyLabels encryptionKeyLabels:(NSArray *)encryptionKeyLabels inContext:(NSManagedObjectContext*)localContext
//{
//    [ThreadHelper ensureLocalThread:localContext];
//
//    NSData* encryptedMessage = [self syncEncryptMessage:message withSignatureKeyLabel:signKeyLabel encryptionKeyLabels:encryptionKeyLabels expectedSignatureKeyLabels:expectedKeyLabels inLocalContext:localContext];
//
//    [message setMynData:encryptedMessage];
//
//    return encryptedMessage!=nil;
//}
//
//+ (BOOL)syncDecryptMessageForTesting:(NSData*)data intoMessage:(MynigmaMessage*)message inContext:(NSManagedObjectContext*)localContext
//{
//    [ThreadHelper ensureLocalThread:localContext];
//    
//    MynigmaFeedback* decryptionError = [self syncDecryptMessage:message inContext:localContext fromData:data];
//
//    //decryptionStatus is either the string @"OK", indicating no error
//    //or the code of the error, in the form of a string
//    NSString* decryptionStatus = decryptionError?[NSString stringWithFormat:@"%ld", (long)decryptionError.code]:@"OK";
//
//    [message setDecryptionStatus:decryptionStatus];
//
//    if(decryptionError)
//    {
//        return NO;
//    }
//    
//    for(FileAttachment* fileAttachment in message.allAttachments)
//    {
//        NSDictionary* attachmentDecryptionDict = [self syncDecryptFileAttachment:fileAttachment inContext:localContext];
//        
//        if(![[attachmentDecryptionDict objectForKey:RESULT] isEqualToString:@"OK"])
//            return NO;
//    }
//    
//    return YES;
//}
//
//+ (BOOL)syncDecryptAttachmentForTesting:(FileAttachment*)fileAttachment inContext:(NSManagedObjectContext*)localContext
//{
//    [ThreadHelper ensureLocalThread:localContext];
//    
//    NSDictionary* attachmentDecryptionDict = [self syncDecryptFileAttachment:fileAttachment inContext:localContext];
//    
//    [fileAttachment setDecryptionStatus:[attachmentDecryptionDict objectForKey:RESULT]];
//    
//    return [[attachmentDecryptionDict objectForKey:RESULT] isEqualToString:@"OK"];
//}


@end
