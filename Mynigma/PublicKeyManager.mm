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





#import "AppDelegate.h"
#import "KeychainHelper.h"


#if ULTIMATE
#import "ServerHelper.h"
#endif

#import "PublicKeyManager.h"
#import "MynigmaPublicKey+Category.h"
#import "EmailContactDetail+Category.h"
#import "MynigmaPrivateKey+Category.h"
#import "mynigma.pb.h"
#import "EncryptionHelper.h"
#import "Recipient.h"
#import "EmailRecipient.h"
#import "UserSettings+Category.h"
#import "IMAPAccountSetting+Category.h"
#import "AppleEncryptionWrapper.h"
#import "NSString+EmailAddresses.h"
#import "NSData+Base64.h"
#import "MynigmaFeedback.h"
#import "DataWrapHelper.h"




@interface MynigmaPublicKey()

+ (void)introducePublicKeyWithEncKeyData:(NSData*)newEncKeyData andVerKeyData:(NSData*)newVerKeyData fromEmail:(NSString*)senderEmail toEmails:(NSArray*)recipients keyLabel:(NSString*)toLabel fromKeyWithLabel:(NSString*)fromLabel;

@end


@implementation PublicKeyManager



#pragma mark - PRIVATE & PUBLIC KEYS

+ (NSArray*)listAllPublicKeys
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MynigmaPublicKey"];
    NSError* error = nil;
    NSArray* result = [MAIN_CONTEXT executeFetchRequest:fetchRequest error:&error];
    if(error)
        NSLog(@"Error trying to fetch Mynigma public key list");
    return result;
}

+ (NSArray*)listAllPrivateKeys
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MynigmaPrivateKey"];
    NSError* error = nil;
    NSArray* result = [MAIN_CONTEXT executeFetchRequest:fetchRequest error:&error];
    if(error)
        NSLog(@"Error trying to fetch Mynigma private key list");
    return result;
}




//+ (NSString*)emailForKeyLabel:(NSString*)keyLabel
//{
//    if(!keyLabel)
//        return nil;
//
//    NSArray* components = [keyLabel componentsSeparatedByString:@"|"];
//
//    if(components.count==2)
//        return components[0];
//
//    return nil;
//}




#if ULTIMATE

//the server has requested this key to be added to the local list of public keys
+ (void)serverSaysAddKey:(NSArray*)record forEmailAddress:(NSString*)email
{
    if(!email || email.length==0)
        return;

    //do not add the key if it is already present
    if([MynigmaPublicKey havePublicKeyWithLabel:record.firstObject])
        return;

    //TO DO: compare the key from the server with the one already present and switch into a suitable error state if there is a mismatch


    if(email.length<1)
    {

    }

    if(record.count<3)
        return;

    NSString* keyLabel = record[0];

    NSString* encDataString = record[1];

    NSString* verDataString = record[2];

    NSData* encKeyData = [encDataString dataUsingEncoding:NSUTF8StringEncoding];

    NSData* verKeyData = [verDataString dataUsingEncoding:NSUTF8StringEncoding];

    //translate the data from the server into a MynigmaPublicKey object
    [MynigmaPublicKey asyncMakeNewPublicKeyWithEncKeyData:encKeyData andVerKeyData:verKeyData forEmail:email keyLabel:keyLabel callback:nil];
}


+ (void)serverSaysReplaceKey:(NSArray *)record forEmailAddress:(NSString *)email
{
    //TO DO: implement
    return;
}

+ (void)serverSaysRevokeKey:(NSArray *)record forEmailAddress:(NSString *)email
{
    //TO DO: implement properly

    return;


//    //EmailContactDetail* emailDetail = [EmailContactDetail addEmailContactDetailForEmail:email];
//
//    //check if the key is already present and dissociate it from the corresponding email contact detail
//    MynigmaPublicKey* publicKey = [MynigmaPublicKey sy
//                                   publicKeyWithLabel:[record objectAtIndex:0] forEmail:email tryKeychain:YES];
//    if(publicKey)
//    {
//        [publicKey removeCurrentKeyForEmail:publicKey.currentKeyForEmail];
//        [publicKey setKeyForEmail:nil];
//        [publicKey setIsCompromised:[NSNumber numberWithBool:YES]];
//        [publicKey setIsCurrentKey:@NO];
//        [MODEL save];
//        return;
//    }
//    else
//    {
//        NSLog(@"Key to be revoked could not be found!!");
//    }
}

#endif


#if ULTIMATE

+ (BOOL)typedRecipient:(Recipient*)recipient quickCheckWithCallback:(void(^)(BOOL found))callback
{
    //first extract the email address
    NSString* email = [recipient displayEmail];
    if(!email)
        return NO;

    //if there is a public key in the store simply return YES
    if([recipient isSafe])
    {
        //probably no need to call back, as display doesn't need to be updated
        //callback(void);
        return YES;
    }

    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

        EmailContactDetail* emailDetail = [EmailContactDetail addEmailContactDetailForEmail:email alreadyFoundOne:nil inContext:localContext];

        NSDate* lastChecked = emailDetail.lastCheckedWithServer;
        NSTimeInterval interval = [lastChecked timeIntervalSinceNow];

        NSInteger numberOfHoursBetweenChecks = 24;

        if(!emailDetail || !lastChecked || (interval>numberOfHoursBetweenChecks*60*60))
        {
            [ThreadHelper runAsyncOnMain:^{

//                IMAPAccountSetting* accountSetting = MODEL.currentUserSettings.preferredAccount;

                [SERVER sendRecipientsToServer:@[recipient] forAccount:[UserSettings currentUserSettings].preferredAccount withCallback:^(NSDictionary* dict, NSError* error){

                    NSDictionary* addList = [dict objectForKey:@"add"];

                    if(addList.count>0)
                        callback(YES);
                    else
                        callback(NO);
                }];

            }];
        }
        else
            callback(NO);

    }];

    return NO;
}


//not properly implemented
//probably unnecessary, as the occassions when large numbers of unsafe recipients are pasted are rare and the adverse effects of checking each address individually are minimal
//+ (BOOL)typedRecipients:(NSArray*)recipients quickCheckWithCallback:(void(^)(void))callback
//{
//    //first extract the email address
//    NSString* email = [recipient displayEmail];
//    if(!email)
//        return NO;
//
//    //if there is a public key in the store simply return YES
//    if([recipient isSafe])
//    {
//        //probably no need to call back, as display doesn't need to be updated
//        //callback(void);
//        return YES;
//    }
//
//    EmailContactDetail* emailDetail = [EmailContactDetail addEmailContactDetailForEmail:email];
//
//    NSDate* lastChecked = emailDetail.lastCheckedWithServer;
//    NSTimeInterval interval = [lastChecked timeIntervalSinceNow];
//
//    NSInteger numberOfHoursBetweenChecks = 24;
//
//    if(!emailDetail || !lastChecked || (interval>numberOfHoursBetweenChecks*60*60))
//    {
//        [SERVER sendRecipientsToServer:@[recipient] forAccount:MODEL.currentUserSettings.preferredAccount withCallback:[callback copy]];
//    }
//
//    return NO;
//}
#endif


+ (BOOL)updatePublicKeyFromMessage:(NSDictionary*)introductionDict
{
    return YES;
}




+ (NSString*)mostRecentOwnKeyLabelUsedBySender:(NSString*)emailAddress
{
    __block NSString* returnValue = nil;

    [ThreadHelper runSyncOnMain:^{

        EmailContactDetail* emailContactDetail = [EmailContactDetail emailContactDetailForAddress:emailAddress];
        if(emailContactDetail)
        {
            returnValue = emailContactDetail.currentReceivedPair.keyLabel;
        }
    }];

    return returnValue;
}


+ (NSData*)introductionDataFromKeyLabel:(NSString*)oldKeyLabel toKeyLabel:(NSString*)newKeyLabel
{
        //if there is no fromLabel, that is, there is no previous key to introduce the new one with, simply sign the introduction with the introduced key
        if(!oldKeyLabel)
            oldKeyLabel = newKeyLabel;

        if(oldKeyLabel && newKeyLabel)
        {
            NSArray* newPemData = [MynigmaPublicKey dataForExistingMynigmaPublicKeyWithLabel:newKeyLabel];

            if(newPemData.count<2)
            {
                NSLog(@"Public key with label %@ has invalid data!", newKeyLabel);
                return nil;
            }

            NSData* newEncPemData = newPemData[0];

            NSData* newVerPemData = newPemData[1];

            mynigma::keyIntroduction* introduction = new mynigma::keyIntroduction;

            introduction->set_newenckey((char*)newEncPemData.bytes, newEncPemData.length);

            introduction->set_newverkey((char*)newVerPemData.bytes, newVerPemData.length);

            introduction->set_version([MYNIGMA_VERSION UTF8String]);

            introduction->set_oldkeylabel([oldKeyLabel UTF8String]);

            introduction->set_newkeylabel([newKeyLabel UTF8String]);
            
            int introduction_data_size = introduction->ByteSize();
            void* introduction_data = malloc(introduction_data_size);
            introduction->SerializeToArray(introduction_data,introduction_data_size);

            // sign introduction data with old key label
            NSData* introductionData = [[NSData alloc] initWithBytes:introduction_data length:introduction_data_size];
            
            NSData* hashedData = [AppleEncryptionWrapper SHA512DigestOfData:introductionData];
            
            NSData* signatureWithOldKeyLabel = [EncryptionHelper signHash:hashedData withKeyWithLabel:oldKeyLabel withFeedback:nil];
            
            NSData* signedDataWithOldKeyLabel = [DataWrapHelper wrapSignedData:introductionData signedDataBlob:signatureWithOldKeyLabel keyLabel:oldKeyLabel withFeedback:nil];
            
            // sign the signed introduction data with new key label
            NSData* hashedData2 =[AppleEncryptionWrapper SHA512DigestOfData:signedDataWithOldKeyLabel];
            
            NSData* signatureWithNewKeyLabel = [EncryptionHelper signHash:hashedData2 withKeyWithLabel:newKeyLabel withFeedback:nil];
            
            NSData* returnData = [DataWrapHelper wrapSignedData:signedDataWithOldKeyLabel signedDataBlob:signatureWithNewKeyLabel keyLabel:newKeyLabel withFeedback: nil];
            
            free(introduction_data);

            return returnData;
        }

    return nil;
}


+ (BOOL)processIntroductionData:(NSData*)introductionData fromEmail:(NSString*)senderEmailString toEmails:(NSArray*)recipientEmails
{
    if(!introductionData.length)
        return NO;

    // parse the protocol buffers structure "signedData"
    // (the signed keyIntroduction data that was signed using the new key)
    mynigma::signedData* signedDataNew = new mynigma::signedData;
    signedDataNew->ParseFromArray([introductionData bytes], (int)[introductionData length]);
    
    if(signedDataNew)
    {
        NSData* signedDataWithOldKeyLabel = [[NSData alloc] initWithBytes:signedDataNew->data().data() length:signedDataNew->data().size()];
        
        NSString* keyLabelNew = [[NSString alloc] initWithData:[[NSData alloc] initWithBytes:signedDataNew->keylabel().data() length:signedDataNew->keylabel().size()] encoding:NSUTF8StringEncoding];
        
        NSData* signatureWithNewKeyLabel = [[NSData alloc] initWithBytes:signedDataNew->signature().data() length:signedDataNew->signature().size()];

        // parse the protocol buffers structure "signedData"
        // (the keyIntroduction data that was signed using the old key)
        mynigma::signedData* signedDataOld = new mynigma::signedData;
        
        if(signedDataWithOldKeyLabel)
            signedDataOld->ParseFromArray([signedDataWithOldKeyLabel bytes], (int)[signedDataWithOldKeyLabel length]);
        
        if (signedDataOld)
        {
            NSData* keyIntroductionData = [[NSData alloc] initWithBytes:signedDataOld->data().data() length:signedDataOld->data().size()];
            
            NSString* keyLabelOld = [[NSString alloc] initWithData:[[NSData alloc] initWithBytes:signedDataOld->keylabel().data() length:signedDataOld->keylabel().size()] encoding:NSUTF8StringEncoding];
            
            NSData* signatureWithOldKeyLabel = [[NSData alloc] initWithBytes:signedDataOld->signature().data() length:signedDataOld->signature().size()];
            
            mynigma::keyIntroduction* introduction = new mynigma::keyIntroduction;
            
            if(keyIntroductionData)
                introduction->ParseFromArray([keyIntroductionData bytes], (int)[keyIntroductionData length]);
            
            if (introduction)
            {
                NSString* oldKeyLabel = [[NSString alloc] initWithData:[[NSData alloc] initWithBytes:introduction->oldkeylabel().data() length:introduction->oldkeylabel().size()] encoding:NSUTF8StringEncoding];
                
                NSString* newKeyLabel = [[NSString alloc] initWithData:[[NSData alloc] initWithBytes:introduction->newkeylabel().data() length:introduction->newkeylabel().size()] encoding:NSUTF8StringEncoding];
                
                NSData* newEncKeyData = [[NSData alloc] initWithBytes:introduction->newenckey().data() length:introduction->newenckey().size()];
                
                NSData* newVerKeyData = [[NSData alloc] initWithBytes:introduction->newverkey().data() length:introduction->newverkey().size()];

                NSString* version = [[NSString alloc] initWithData:[[NSData alloc] initWithBytes:introduction->version().data() length:introduction->version().size()] encoding:NSUTF8StringEncoding];
                
                //check that the keyLabels coincide
                if (([newKeyLabel isEqual:keyLabelNew]) && ([oldKeyLabel isEqual:keyLabelOld]))
                {
                    // add new key to keychain
                    if(![MynigmaPublicKey havePublicKeyWithLabel:newKeyLabel])
                    {
                        //the origin public key may not yet exist
                        //in this case we need to create it before verifying the introduction
                        if (newEncKeyData && newVerKeyData && senderEmailString && oldKeyLabel)
                            [MynigmaPublicKey syncMakeNewPublicKeyWithEncKeyData:newEncKeyData andVerKeyData:newVerKeyData forEmail:senderEmailString keyLabel:oldKeyLabel];
                    }
                    
                    //check signature for new keylabel
                    NSData* hashedData = [AppleEncryptionWrapper SHA512DigestOfData:signedDataWithOldKeyLabel];
                    
                    MynigmaFeedback* signatureFeedback =  [EncryptionHelper verifySignature:signatureWithNewKeyLabel ofHash:hashedData version:version withKeyLabel:newKeyLabel];
                    
                    if(signatureFeedback.isSuccess)
                    {
                        //check signature for old keylabel
                        hashedData = [AppleEncryptionWrapper SHA512DigestOfData:keyIntroductionData];
                        
                        MynigmaFeedback* signatureFeedback2 =  [EncryptionHelper verifySignature:signatureWithOldKeyLabel ofHash:hashedData version:version withKeyLabel:oldKeyLabel];
                        
                        if(signatureFeedback2.isSuccess)
                        {
                            // make new public key the current key for email address
                            [MynigmaPublicKey introducePublicKeyWithEncKeyData:newEncKeyData andVerKeyData:newVerKeyData fromEmail:senderEmailString toEmails:recipientEmails keyLabel:newKeyLabel fromKeyWithLabel:oldKeyLabel];
                            
                            return YES;
                        }
                        else
                        {
                            NSLog(@"Invalid signature with old key label in introduction data!! From: %@ to: %@", oldKeyLabel, newKeyLabel);
                        }
                    }
                    else
                    {
                        NSLog(@"Invalid signature with new key label in introduction data!! From: %@ to: %@", oldKeyLabel, newKeyLabel);
                    }
                }
                else
                {
                        //this case should not occur
                        NSLog(@"someone seems to have tampered with the key labels...");
                }
            }
        }
    }
    
    return NO;
    
//    //parse the protocol buffers structure "keyIntroduction"
//    mynigma::keyIntroduction* introduction = new mynigma::keyIntroduction;
//    introduction->ParseFromArray([introductionData bytes], (int)[introductionData length]);
//
//    if(introduction)
//    {
//        NSString* fromLabel = [[NSString alloc] initWithData:[[NSData alloc] initWithBytes:introduction->oldkeylabel().data() length:introduction->oldkeylabel().size()] encoding:NSUTF8StringEncoding];
//
//        NSString* toLabel = [[NSString alloc] initWithData:[[NSData alloc] initWithBytes:introduction->newkeylabel().data() length:introduction->newkeylabel().size()] encoding:NSUTF8StringEncoding];
//
//
//        NSData* newEncKeyData = [[NSData alloc] initWithBytes:introduction->newenckey().data() length:introduction->newenckey().size()];
//
//        NSData* newVerKeyData = [[NSData alloc] initWithBytes:introduction->newverkey().data() length:introduction->newverkey().size()];
//
//
////        NSString* encDataStringBase64 = [newEncKeyData base64];
////
////        NSString* verDataStringBase64 = [newVerKeyData base64];
////
//        NSString* version = [[NSString alloc] initWithData:[[NSData alloc] initWithBytes:introduction->version().data() length:introduction->version().size()] encoding:NSUTF8StringEncoding];
//
//        NSMutableData* dataToBeSigned = [NSMutableData dataWithData:[fromLabel dataUsingEncoding:NSUTF8StringEncoding]];
//        [dataToBeSigned appendData:[toLabel dataUsingEncoding:NSUTF8StringEncoding]];
//        [dataToBeSigned appendData:newEncKeyData];
//        [dataToBeSigned appendData:newVerKeyData];
//        [dataToBeSigned appendData:[version dataUsingEncoding:NSUTF8StringEncoding]];
//
//        //NSData* hashedData = [AppleEncryptionWrapper SHA512DigestOfData:dataToBeSigned];
//
//        //NSData* signatureData = [[NSData alloc] initWithBytes:introduction->signature().data() length:introduction->signature().size()];
//
//        if(![MynigmaPublicKey havePublicKeyWithLabel:fromLabel])
//        {
//            //the origin public key may not yet exist
//            //in this case we need to create it before verifying the introduction
//            [MynigmaPublicKey syncMakeNewPublicKeyWithEncKeyData:newEncKeyData andVerKeyData:newVerKeyData forEmail:senderEmailString keyLabel:fromLabel];
//        }
//
//        MynigmaFeedback* signatureFeedback =  [EncryptionHelper verifySignature:signatureData ofHash:hashedData version:version withKeyLabel:fromLabel];
//
//        if(signatureFeedback.isSuccess)
//        {
//            //the signature is valid, so proceed by setting the new key
//
//            [MynigmaPublicKey introducePublicKeyWithEncKeyData:newEncKeyData andVerKeyData:newVerKeyData fromEmail:senderEmailString toEmails:recipientEmails keyLabel:toLabel fromKeyWithLabel:fromLabel];
//
//            return YES;
//        }
//        else
//        {
//            NSLog(@"Invalid signature in introduction data!! From: %@ to: %@", fromLabel, toLabel);
//        }
//    }
//
//    return NO;
}

//




#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

+ (NSString*)headerRepresentationOfPublicKeyWithLabel:(NSString*)keyLabel
{
        if(!keyLabel)
            return nil;

        NSArray* dataArray = [MynigmaPublicKey dataForExistingMynigmaPublicKeyWithLabel:keyLabel];

        if(dataArray.count < 2)
            return nil;

        NSData* encData = dataArray[0];

        NSData* verData = dataArray[1];

        NSString* encString = nil;

        if([encData respondsToSelector:@selector(base64EncodedStringWithOptions:)])
        {
            //available from 10.9
            encString = [encData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength|NSDataBase64EncodingEndLineWithCarriageReturn|NSDataBase64EncodingEndLineWithLineFeed];
        }
        else
        {
            //available from 10.6, deprecated in 10.9
            encString = [encData base64Encoding];

            //split into 64 character lines
            NSMutableArray* chunks = [NSMutableArray new];

            NSInteger index = 0;

            while(index<encString.length)
            {
                NSInteger lengthOfChunk = (index+64<encString.length)?64:encString.length-index;

                NSString* substring = [encString substringWithRange:NSMakeRange(index, lengthOfChunk)];

                [chunks addObject:substring];

                index+= 64;
            }

            encString = [chunks componentsJoinedByString:@"\r\n"];
        }


        NSString* verString = nil;

        if([verData respondsToSelector:@selector(base64EncodedStringWithOptions:)])
        {
            //available from 10.9
            verString = [verData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength|NSDataBase64EncodingEndLineWithCarriageReturn|NSDataBase64EncodingEndLineWithLineFeed];
        }
        else
        {
            //available from 10.6, deprecated in 10.9
            verString = [verData base64Encoding];

            //split into 64 character lines
            NSMutableArray* chunks = [NSMutableArray new];

            NSInteger index = 0;

            while(index<verString.length)
            {
                NSInteger lengthOfChunk = (index+64<verString.length)?64:verString.length-index;

                NSString* substring = [verString substringWithRange:NSMakeRange(index, lengthOfChunk)];

                [chunks addObject:substring];

                index+= 64;
            }

            verString = [chunks componentsJoinedByString:@"\r\n"];
        }

        NSString* completeString = [NSString stringWithFormat:@"%@\r\n -\r\n %@", encString, verString];

    return completeString;
}


+ (void)handleHeaderRepresentationOfPublicKey:(NSString*)headerString withKeyLabel:(NSString*)keyLabel fromEmail:(NSString*)emailString
{
    NSArray* components = [headerString componentsSeparatedByString:@"-"];

    if(components.count < 2)
        return;

    NSMutableString* encString = [components[0] mutableCopy];

    NSMutableString* verString = [components[1] mutableCopy];

    [encString replaceOccurrencesOfString:@"\r\n " withString:@"" options:0 range:NSMakeRange(0, encString.length)];

    NSData* unBase64edEncStringData = nil;

    if([NSData instancesRespondToSelector:@selector(initWithBase64EncodedString:options:)])
    {
        unBase64edEncStringData = [[NSData alloc] initWithBase64EncodedString:encString options:NSDataBase64DecodingIgnoreUnknownCharacters];
    }
    else
    {
        unBase64edEncStringData = [[NSData alloc] initWithBase64Encoding:encString];
    }


    NSString* unBase64edEncString = [[NSString alloc] initWithData:unBase64edEncStringData encoding:NSUTF8StringEncoding];

    [verString replaceOccurrencesOfString:@"\r\n " withString:@"" options:0 range:NSMakeRange(0, verString.length)];

    NSData* unBase64edVerStringData = nil;

    if([NSData instancesRespondToSelector:@selector(initWithBase64EncodedString:options:)])
    {
        unBase64edVerStringData = [[NSData alloc] initWithBase64EncodedString:verString options:NSDataBase64DecodingIgnoreUnknownCharacters];
    }
    else
    {
        unBase64edVerStringData = [[NSData alloc] initWithBase64Encoding:verString];
    }

    NSString* unBase64edVerString = [[NSString alloc] initWithData:unBase64edVerStringData encoding:NSUTF8StringEncoding];


    NSData* unBase64edKeyLabelData = nil;

    if([NSData instancesRespondToSelector:@selector(initWithBase64EncodedString:options:)])
    {
        unBase64edKeyLabelData = [[NSData alloc] initWithBase64EncodedString:keyLabel options:NSDataBase64DecodingIgnoreUnknownCharacters];
    }
    else
    {
        unBase64edKeyLabelData = [[NSData alloc] initWithBase64Encoding:keyLabel];
    }


    NSString* unBase64edKeyLabel = [[NSString alloc] initWithData:unBase64edKeyLabelData encoding:NSUTF8StringEncoding];

    NSData* encData = [unBase64edEncString dataUsingEncoding:NSUTF8StringEncoding];

    NSData* verData = [unBase64edVerString dataUsingEncoding:NSUTF8StringEncoding];

    NSString* email = [emailString canonicalForm];

    if(email.length && encData.length && verData.length)
    {
        [MynigmaPublicKey syncMakeNewPublicKeyWithEncKeyData:encData andVerKeyData:verData forEmail:email keyLabel:unBase64edKeyLabel];
    }
}

#pragma GCC diagnostic pop

+ (void)addMynigmaInfoPublicKey
{
    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

       [PublicKeyManager addMynigmaInfoPublicKeyInContext:localContext];
    }];
}

+ (BOOL)addMynigmaInfoPublicKeyInContext:(NSManagedObjectContext*)localContext
{
    NSString* email = @"info@mynigma.org";
    
    EmailContactDetail* contactDetail = [EmailContactDetail emailContactDetailForAddress:email inContext:localContext];
    if(contactDetail)
    {
        if(![MynigmaPublicKey havePublicKeyForEmailAddress:email])
        {
            NSData* encData = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"Mynigma encryption key info@mynigma.org|1377619023.914025" ofType:@"pem"]];
            NSData* verData = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"Mynigma signature key info@mynigma.org|1377619023.914025" ofType:@"pem"]];
            
            if(!encData || !verData)
            {
                NSLog(@"Failed to load mynigma info key data!!! %@ %@", encData, verData);
                return NO;
            }
            
            NSString* keyLabel = @"info@mynigma.org|1377619023.914025";
            
            [MynigmaPublicKey asyncMakeNewPublicKeyWithEncKeyData:encData andVerKeyData:verData forEmail:@"info@mynigma.org" keyLabel:keyLabel callback:nil];
        }
    }
    else
        NSLog(@"Failed to create contact detail for mynigma info!!!");
    
    return NO;
}


@end
