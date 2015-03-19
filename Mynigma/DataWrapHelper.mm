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





#import "HTMLPurifier.h"
#import "AppDelegate.h"
#import "KeychainHelper.h"
#import "deviceMessage.pb.h"
#import "mynigma.pb.h"
#import "syncData.pb.h"
#import "DataWrapHelper.h"
#import "MynigmaMessage+Category.h"
#import "FileAttachment+Category.h"
#import "EmailRecipient.h"
#import "EncryptionHelper.h"
#import "MynigmaDeclaration.h"
#import "MynigmaPrivateKey+Category.h"
#import "PublicKeyManager.h"
#import "EmailContactDetail+Category.h"
#import "MynigmaPublicKey+Category.h"
#import "UserSettings+Category.h"
#import "IMAPAccountSetting+Category.h"
#import "IMAPAccount.h"
#import "IMAPFolderSetting+Category.h"
#import "EmailMessageData.h"
#import "AccountCreationManager.h"
#import "AttachmentsManager.h"
#import "AppleEncryptionWrapper.h"
#import "MynigmaDevice+Category.h"
#import "DeviceMessage+Category.h"
#import "AccountCheckManager.h"
#import "EmailAddress+Category.h"
#import "NSString+EmailAddresses.h"
#import "MynigmaFeedback.h"





@interface MynigmaPublicKey()

- (void)associateKeyWithEmail:(NSString*)emailString forceMakeCurrent:(BOOL)makeCurrent inContext:(NSManagedObjectContext*)keyContext;

+ (MynigmaPublicKey*)syncMakeNewPublicKeyWithEncKeyData:(NSData*)encKeyData andVerKeyData:(NSData*)verKeyData forEmail:(NSString*)email keyLabel:(NSString*)keyLabel inContext:(NSManagedObjectContext*)keyContext;

@end


@implementation DataWrapHelper


#pragma mark - MESSAGE WRAPPING

+ (NSData*)wrapMessage:(MynigmaMessage*)message
{
    mynigma::payloadPart* payloadPart = new mynigma::payloadPart;

    NSData* recData = message.messageData.addressData;

    if(!recData)
        return nil;

    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:recData];
    NSArray* recArray = [unarchiver decodeObjectForKey:@"recipients"];
    [unarchiver finishDecoding];

    for(EmailRecipient* rec in recArray)
    {
        if(rec.type==TYPE_BCC)
            continue;

        mynigma::payloadPart_emailRecipient* recipient = payloadPart->add_recipients();
        if(rec.name)
            recipient->set_name([rec.name UTF8String]);
        else
            recipient->set_name([rec.email UTF8String]);

        if(rec.email)
            recipient->set_email([rec.email UTF8String]);
        switch(rec.type)
        {
            case TYPE_FROM: recipient->set_type(mynigma::payloadPart_addresseeType_T_FROM);
                break;

            case TYPE_REPLY_TO: recipient->set_type(mynigma::payloadPart_addresseeType_T_REPLY_TO);
                break;

            case TYPE_TO: recipient->set_type(mynigma::payloadPart_addresseeType_T_TO);
                break;

            case TYPE_CC: recipient->set_type(mynigma::payloadPart_addresseeType_T_CC);
                break;

                //(this shouldn't happen):
            case TYPE_BCC: recipient->set_type(mynigma::payloadPart_addresseeType_T_BCC);
                break;
        }
    }

    NSMutableArray* attachmentArray = [NSMutableArray new];

    for(FileAttachment* attachment in message.allAttachments)
    {
        //the payload contains fileName, partID, contentID, size and a hash of the attachment
        mynigma::payloadPart_fileAttachment* att = payloadPart->add_attachments();
        if(attachment.fileName)
        {
            std::string fileNameString = [attachment.fileName UTF8String];

            att->set_filename([attachment.fileName UTF8String]);
        }

        NSString* contentID = attachment.contentid;
        if(!contentID)
        {
            contentID = [self generateContentID];
            [attachment setContentid:contentID];
        }
        att->set_contentid([attachment.contentid UTF8String]);

        if(attachment.size)
            att->set_size(attachment.size.intValue);

        if(attachment.attachedToMessage)
            att->set_isinline(false);
        else
            att->set_isinline(true);

        NSData* attachmentData = [attachment data];

        if(!attachmentData)
        {
            NSLog(@"Failed to attach attachment without data: %@", attachment);
        }

        NSData* hashedValue = [AppleEncryptionWrapper SHA512DigestOfData:attachmentData];
        att->set_hashedvalue((char*)[hashedValue bytes], [hashedValue length]);

        //this is passed along to encryptData: withPublicKeys: andAttachments so that the data can be encrypted with the session key and put into the encryptedData property
        [attachmentArray addObject:attachment];
    }

    if(message.messageData.body)
        payloadPart->set_body([message.messageData.body UTF8String]);
    else
        payloadPart->set_body([@"" UTF8String]);

    if(message.messageData.htmlBody)
        payloadPart->set_htmlbody([message.messageData.htmlBody UTF8String]);
    else
        payloadPart->set_htmlbody([@"" UTF8String]);

    if(message.dateSent)
        payloadPart->set_datesent((int)[message.dateSent timeIntervalSince1970]);
    else
        payloadPart->set_datesent((int)[[NSDate date] timeIntervalSince1970]);

    if(message.messageData.subject)
        payloadPart->set_subject([message.messageData.subject UTF8String]);
    else
        payloadPart->set_subject([@"" UTF8String]);


    if(message.declaration)
    {
        payloadPart->set_declaration((char*)[message.declaration.data bytes],[message.declaration.data length]);
    }
    //TO DO: add a key issue declaration


    int payloadPart_size = payloadPart->ByteSize();
    void* payloadPart_data = malloc(payloadPart_size);
    payloadPart->SerializeToArray(payloadPart_data, payloadPart_size);

    NSData* returnedData = [[NSData alloc] initWithBytes:payloadPart_data length:payloadPart_size];
    
    delete payloadPart;
    free(payloadPart_data);
    
    return returnedData;
}



+ (void)unwrapMessageData:(NSData*)payloadPartData intoMessage:(MynigmaMessage*)newMessage withAttachmentHMACS:(NSArray*)attachmentHMACS andFeedback:(MynigmaFeedback**)mynigmaFeedback
{
    NSManagedObjectContext* localContext = newMessage.managedObjectContext;
    
    [ThreadHelper ensureLocalThread:localContext];

    __block mynigma::payloadPart* payloadPart = new mynigma::payloadPart;

    payloadPart->ParseFromArray([payloadPartData bytes],(int)[payloadPartData length]);

    NSString* body = [[NSString alloc] initWithData:[[NSData alloc] initWithBytes:payloadPart->body().data() length:payloadPart->body().length()] encoding:NSUTF8StringEncoding];
    [newMessage.messageData setBody:body];

    NSString* htmlBody = [[NSString alloc] initWithData:[[NSData alloc] initWithBytes:payloadPart->htmlbody().data() length:payloadPart->htmlbody().length()] encoding:NSUTF8StringEncoding];

    @autoreleasepool
    {
    NSString* cleanedBody = [HTMLPurifier cleanHTML:htmlBody];

    [newMessage.messageData setHtmlBody:cleanedBody];
    }

    NSString* subject = [[NSString alloc] initWithData:[[NSData alloc] initWithBytes:payloadPart->subject().data() length:payloadPart->subject().length()] encoding:NSUTF8StringEncoding];

    NSArray* subjectComponents = [subject componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    subject = [subjectComponents componentsJoinedByString:@""];
    
    [newMessage.messageData setSubject:subject];

    NSArray* sortedArray = [newMessage.allAttachments sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"contentid" ascending:YES]]];

    //if attachmentHMACS is not provided, the old encryption format is used and HMACS need not be set
    if(attachmentHMACS && payloadPart->attachments_size() != attachmentHMACS.count)
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorWrongAttachmentCount message:newMessage];
            
        return;
    }
    
    for(int i=0;i<payloadPart->attachments_size();i++)
    {

        mynigma::payloadPart_fileAttachment* att = new mynigma::payloadPart_fileAttachment;
        *att = payloadPart->attachments(i);

        std::string fileName = att->filename();
        std::string contentIDString = att->contentid();

        NSData* contentIDData = [[NSData alloc] initWithBytes:att->contentid().data() length:att->contentid().size()];

        NSString* contentID = [[NSString alloc] initWithData:contentIDData encoding:NSUTF8StringEncoding];

        NSInteger indexOfAttachment = [[sortedArray valueForKey:@"contentid"] indexOfObject:contentID];

        NSData* fileNameData = [[NSData alloc] initWithBytes:att->filename().data() length:att->filename().size()];

        NSString* filename = [[NSString alloc] initWithData:fileNameData encoding:NSUTF8StringEncoding];

        NSData* hashedValue = [[NSData alloc] initWithBytes:att->hashedvalue().data() length:att->hashedvalue().size()];

        FileAttachment* newAttachment = nil;
        
        if(indexOfAttachment==NSNotFound)
        {
            //if no attachment with this contentid can be found it looks like the attachment is missing - the user should be informed!
            //add an attachment with status @"This attachment is missing"

            NSEntityDescription* attEntity = [NSEntityDescription entityForName:@"FileAttachment" inManagedObjectContext:localContext];
            newAttachment = [[FileAttachment alloc] initWithEntity:attEntity insertIntoManagedObjectContext:localContext];

            [newAttachment setDecryptionStatus:@"This attachment is missing"];
            [newAttachment setFileName:filename];
            [newAttachment setSize:[NSNumber numberWithInt:att->size()]];
            [newAttachment setAttachedToMessage:newMessage];
            [newAttachment setAttachedAllToMessage:newMessage];
            [newAttachment setDownloadProgress:@(-1)];
        }
        else
        {
            //there is an attachment with this contentid, so set the appropriate values
            newAttachment = [sortedArray objectAtIndex:indexOfAttachment];
            
            [newAttachment setDecryptionStatus:@""];
            [newAttachment setFileName:filename];
            [newAttachment setSize:[NSNumber numberWithInt:att->size()]];
            [newAttachment setDownloadProgress:@0.0];
          
            //if it's not inline display the attachment
            if(!(att->isinline()))
                [newAttachment setAttachedToMessage:newAttachment.attachedAllToMessage];

            [newAttachment setHashedValue:hashedValue];
        }
        
        if(attachmentHMACS)
        {
            [newAttachment setHmacValue:attachmentHMACS[i]];
        }

        delete att;
    }

    NSMutableString* newSearchString = [NSMutableString new];

    NSString* fromName = nil;

    NSMutableArray* emailRecArray = [NSMutableArray new];
    for(int i=0;i<payloadPart->recipients_size();i++)
    {

        EmailRecipient* rec = [EmailRecipient new];


        mynigma::payloadPart_emailRecipient* emailRec = new mynigma::payloadPart_emailRecipient;

        *emailRec = payloadPart->recipients(i);

        NSData* nameData = [[NSData alloc] initWithBytes:emailRec->name().data() length:emailRec->name().size()];

        NSData* emailData = [[NSData alloc] initWithBytes:emailRec->email().data() length:emailRec->email().size()];

        NSString* nameString = [[NSString alloc] initWithData:nameData encoding:NSUTF8StringEncoding];

        NSString* emailString = [[NSString alloc] initWithData:emailData encoding:NSUTF8StringEncoding];

        [rec setName:nameString];

        [rec setEmail:emailString];

        if(nameString)
            [newSearchString appendFormat:@"%@,",[nameString lowercaseString]];

        if(emailString)
            [newSearchString appendFormat:@"%@,",[emailString lowercaseString]];

        //there must be at most one from: recipient
        //otherwise the signature cannot be verified

        EmailRecipient* fromRecipient = nil;

        BOOL skipThisRecord = NO;

        switch(emailRec->type())
        {
            case mynigma::payloadPart_addresseeType_T_FROM:
            {
                //no more than one sender address
                if(!fromRecipient)
                {
                    fromRecipient = rec;
                    fromName = [rec displayString];
                }
                else
                    skipThisRecord = YES;

                [rec setType:TYPE_FROM];
                break;
            }
            case mynigma::payloadPart_addresseeType_T_REPLY_TO: [rec setType:TYPE_REPLY_TO];
                if(!fromName)
                    fromName = [rec displayString];
                break;
            case mynigma::payloadPart_addresseeType_T_TO: [rec setType:TYPE_TO];
                break;
            case mynigma::payloadPart_addresseeType_T_CC: [rec setType:TYPE_CC];
                break;
            case mynigma::payloadPart_addresseeType_T_BCC: [rec setType:TYPE_BCC];
                break;
        }

        if(!skipThisRecord)
            [emailRecArray addObject:rec];

        delete emailRec;
    }
    
    if(fromName)
        [newMessage.messageData setFromName:fromName];

    if(newMessage.messageData.subject)
        [newSearchString appendString:subject];

    [newMessage setSearchString:newSearchString];

    NSMutableData* addressData = [NSMutableData new];
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:addressData];
    [archiver encodeObject:emailRecArray forKey:@"recipients"];
    [archiver finishEncoding];

    [newMessage.messageData setAddressData:addressData];

    NSInteger timeInterval = payloadPart->datesent();
    [newMessage setDateSent:[NSDate dateWithTimeIntervalSince1970:timeInterval]];

    delete payloadPart;
}

+ (NSData*)wrapSignedData:(NSData*)data signedDataBlob:(NSData*)signedDataBlob keyLabel:(NSString*)keyLabel withFeedback:(MynigmaFeedback**)mynigmaFeedback
{
    return [self wrapSignedData:data signedDataBlob:signedDataBlob keyLabel:keyLabel version:MYNIGMA_VERSION withFeedback:(MynigmaFeedback**)mynigmaFeedback];
}


+ (NSData*)wrapSignedData:(NSData*)data signedDataBlob:(NSData*)signedDataBlob keyLabel:(NSString*)keyLabel version:(NSString*)version withFeedback:(MynigmaFeedback**)mynigmaFeedback
{
    mynigma::signedData* signedData = new mynigma::signedData;

    signedData->set_keylabel([keyLabel UTF8String]);
    signedData->set_signature((char*)[signedDataBlob bytes], [signedDataBlob length]);
    signedData->set_data((char*)[data bytes], [data length]);

    signedData->set_version([version UTF8String]);

    int signedData_size = signedData->ByteSize();
    void* signed_data = malloc(signedData_size);
    signedData->SerializeToArray(signed_data,signedData_size);

    NSData* returnData = [[NSData alloc] initWithBytes:signed_data length:signedData_size];
    free(signed_data);
    delete signedData;

    return returnData;
}




#pragma mark - @MARCO: IGNORE...

+ (NSString*)generateContentID
{
    NSDate* currentDate = [NSDate date];

    NSString* timeStamp = [NSString stringWithFormat:@"%f",[currentDate timeIntervalSince1970]];

    NSString *randomString = [NSString stringWithFormat:@"%u",arc4random()];

    return [NSString stringWithFormat:@"%@%@@mynigma.org",timeStamp,randomString];

}

+ (NSData*)keyRefFromPersistentRef:(NSData*)persistentRef
{
    NSDictionary* query = @{(__bridge id)kSecClass:(__bridge id)kSecClassCertificate,
                            (__bridge id)kSecValuePersistentRef:persistentRef};

    //get SecKeyRef from persistent ref
    CFDataRef keyDataRef = NULL;
    OSStatus oserr = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef*)&keyDataRef);

    if(oserr != noErr)
    {
        if(keyDataRef)
            CFRelease(keyDataRef);

        NSLog(@"Error creating key ref from persistent ref: %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:oserr userInfo:nil]);
        return nil;
    }

    //success! return the key ref just obtained
    return CFBridgingRelease(keyDataRef);
}



+ (NSData*)makeIOSPackageIncludingAccountSettings:(BOOL)includeAccounts
{
    return [DataWrapHelper makeAccountDataPackageIncludingPublicKeys:YES includingAccountSettings:includeAccounts passphrase:@"password"];
}

+ (NSData*)makeAccountDataPackage
{
    return [self makeAccountDataPackageIncludingPublicKeys:YES includingAccountSettings:YES];
}

+ (NSData*)makeAccountDataPackageIncludingPublicKeys:(BOOL)includePublicKeys includingAccountSettings:(BOOL)includeAccountSettings
{
    return [self makeAccountDataPackageIncludingPublicKeys:includePublicKeys includingAccountSettings:includeAccountSettings passphrase:@""];
}


/**CALL ON MAIN*/
+ (NSData*)makeAccountDataPackageIncludingPublicKeys:(BOOL)includePublicKeys includingAccountSettings:(BOOL)includeAccountSettings passphrase:(NSString*)passphrase
{
    [ThreadHelper ensureMainThread];

    mynigma::confidentialAccountData* accountData = new mynigma::confidentialAccountData;

    /*private keys*/
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MynigmaPrivateKey"];
    NSArray* keyPairs = [MAIN_CONTEXT executeFetchRequest:fetchRequest error:nil];

    for(MynigmaPrivateKey* keyPair in keyPairs)
    {
        //the private key data

        NSArray* pemData = [MynigmaPrivateKey dataForPrivateKeyWithLabel:keyPair.keyLabel passphrase:passphrase];

        if(pemData && pemData.count>=4)
        {
        NSData* decPemData = pemData[0];

        NSData* sigPemData = pemData[1];

            NSData* encPemData = pemData[2];

            NSData* verPemData = pemData[3];

        if(encPemData && sigPemData && decPemData && verPemData)
        {
            mynigma::privateKey* newPrivateKey = accountData->add_privkeys();

            newPrivateKey->set_encrkeydata(encPemData.bytes, encPemData.length);
            newPrivateKey->set_verkeydata(verPemData.bytes, verPemData.length);
            newPrivateKey->set_decrkeydata(decPemData.bytes, decPemData.length);
            newPrivateKey->set_signkeydata(sigPemData.bytes, sigPemData.length);

            newPrivateKey->set_version([MYNIGMA_VERSION UTF8String]);

            newPrivateKey->set_datecreated([keyPair.dateCreated timeIntervalSince1970]);

            //private key label
            newPrivateKey->set_keylabel([keyPair.keyLabel UTF8String]);

            newPrivateKey->set_iscompromised(keyPair.isCompromised.boolValue);

            newPrivateKey->set_iscurrent(keyPair.isCurrentKey.boolValue);

            if(keyPair.emailAddress)
                newPrivateKey->set_email([keyPair.emailAddress UTF8String]);

            for(EmailContactDetail* contactDetail in keyPair.currentSentForEmail)
            {
                newPrivateKey->add_currentreceivedforemail([contactDetail.address UTF8String]);
            }

            for(EmailContactDetail* contactDetail in keyPair.currentReceivedForEmail)
            {
                newPrivateKey->add_currentsentforemail([contactDetail.address UTF8String]);
            }
        }
        }
        else
            return nil;
    }

    if(includePublicKeys)
    {
    fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MynigmaPublicKey"];
    NSArray* publicKeys = [MAIN_CONTEXT executeFetchRequest:fetchRequest error:nil];

    /*public keys*/
    for(MynigmaPublicKey* publicKey in publicKeys)
    {
        NSArray* pemData = [MynigmaPublicKey dataForExistingMynigmaPublicKeyWithLabel:publicKey.keyLabel];

        if(pemData && pemData.count>=2)
        {
            NSData* encrPemData = pemData[0];

            NSData* verPemData = pemData[1];

        if(encrPemData && verPemData)
        {
            mynigma::publicKey* newPublicKey = accountData->add_pubkeys();

            newPublicKey->set_encrkeydata(encrPemData.bytes, encrPemData.length);
            newPublicKey->set_verkeydata(verPemData.bytes, verPemData.length);

            newPublicKey->set_version([MYNIGMA_VERSION UTF8String]);

            newPublicKey->set_datecreated([publicKey.dateCreated timeIntervalSince1970]);
            newPublicKey->set_datedeclared([publicKey.dateDeclared timeIntervalSince1970]);
            newPublicKey->set_dateobtained([publicKey.dateObtained timeIntervalSince1970]);

            //private key label
            newPublicKey->set_keylabel([publicKey.keyLabel UTF8String]);

            newPublicKey->set_iscompromised(publicKey.isCompromised.boolValue);
            newPublicKey->set_fromserver(publicKey.fromServer.boolValue);

            newPublicKey->set_iscurrent(publicKey.isCurrentKey.boolValue);

            if(publicKey.emailAddress)
                newPublicKey->set_email([publicKey.emailAddress UTF8String]);

            for(EmailContactDetail* contactDetail in publicKey.currentKeyForEmail)
            {
                newPublicKey->add_currentkeyforemail([contactDetail.address UTF8String]);
            }

            for(MynigmaPublicKey* introKey in publicKey.introducesKeys)
            {
                newPublicKey->add_introduceskeys([introKey.keyLabel UTF8String]);
            }

            for(MynigmaPublicKey* introKey in publicKey.isIntroducedByKeys)
            {
                newPublicKey->add_isintroducedbykeys([introKey.keyLabel UTF8String]);
            }
        }
            else
                return nil;
        }
    }

    }

    if(includeAccountSettings)
    {

    /*account settings*/
    for(IMAPAccountSetting* accountSetting in [UserSettings currentUserSettings].accounts)
    {
        mynigma::accountLoginData* loginData = accountData->add_accounts();

        loginData->set_email([accountSetting.emailAddress UTF8String]);

        loginData->set_inhostname([accountSetting.incomingServer UTF8String]);
        loginData->set_inusername([accountSetting.incomingUserName UTF8String]);
        NSString* password = [KeychainHelper findPasswordForAccount:accountSetting.objectID incoming:YES];
        loginData->set_inpassword([password UTF8String]);
        loginData->set_inport(accountSetting.incomingPort.intValue);
        loginData->set_inencryption(accountSetting.incomingEncryption.intValue);
        loginData->set_inauthtype(accountSetting.incomingAuthType.intValue);

        loginData->set_outhostname([accountSetting.outgoingServer UTF8String]);
        loginData->set_outusername([accountSetting.outgoingUserName UTF8String]);
        password = [KeychainHelper findPasswordForAccount:accountSetting.objectID incoming:NO];
        loginData->set_outpassword([password UTF8String]);
        loginData->set_outport(accountSetting.outgoingPort.intValue);
        loginData->set_outencryption(accountSetting.outgoingEncryption.intValue);
        loginData->set_outauthtype(accountSetting.outgoingAuthType.intValue);

        loginData->set_displayname([accountSetting.displayName UTF8String]);
        loginData->set_copyintosent(accountSetting.sentMessagesCopiedIntoSentFolder.boolValue);
        loginData->set_senderemail([accountSetting.senderEmail UTF8String]);
        loginData->set_sendername([accountSetting.senderName UTF8String]);
    }

    }

    int data_size = accountData->ByteSize();
    void* data_buffer = malloc(data_size);

    accountData->SerializeToArray(data_buffer,data_size);

    NSData* confidentialAccountsData = [[NSData alloc] initWithBytes:data_buffer length:data_size];

    delete accountData;
    free(data_buffer);

    return confidentialAccountsData;
}

+ (void)unwrapAccountDataPackage:(NSData*)data withCallback:(void(^)(NSArray* importedPrivateKeyLabels, NSArray* errorLabels))callback
{
    [self unwrapAccountDataPackage:data passphrase:@"" withCallback:callback];
}

+ (NSString*)emailForKeyLabel:(NSString*)keyLabel
{
    if(!keyLabel)
        return nil;

    NSArray* components = [keyLabel componentsSeparatedByString:@"|"];

    if(components.count==2)
        return components[0];

    return nil;
}


//#warning REWRITE

+ (void)unwrapAccountDataPackage:(NSData*)data passphrase:(NSString*)passphrase withCallback:(void(^)(NSArray* importedPrivateKeyLabels, NSArray* errorLabels))callback
{
    return;

//    mynigma::confidentialAccountData* accountData = new mynigma::confidentialAccountData;
//
//    accountData->ParseFromArray([data bytes],(int)[data length]);
//
//    if(!accountData)
//    {
//        if(callback)
//            callback(nil, nil);
//        return;
//    }
//
//    NSMutableArray* importedLabels = [NSMutableArray new];
//    NSMutableArray* errorLabels = [NSMutableArray new];
//
//    for(int i=0; i<accountData->privkeys_size(); i++)
//    {
//        mynigma::privateKey* privKey = new mynigma::privateKey;
//        *privKey = accountData->privkeys(i);
//
//        NSString* keyLabel = [[NSString alloc] initWithBytes:privKey->keylabel().data() length:privKey->keylabel().length() encoding:NSUTF8StringEncoding];
//
//        NSString* email = [self emailForKeyLabel:keyLabel];
//        
//        if([MynigmaPrivateKey privateKeyWithLabel:keyLabel forEmail:email tryKeychain:YES]==nil)
//        {
//            NSData* decKeyData = [NSData dataWithBytes:privKey->decrkeydata().data() length:privKey->decrkeydata().size()];
//
//            NSData* sigKeyData = [NSData dataWithBytes:privKey->signkeydata().data() length:privKey->signkeydata().size()];
//
//            NSData* encKeyData = [NSData dataWithBytes:privKey->encrkeydata().data() length:privKey->encrkeydata().size()];
//
//            NSData* verKeyData = [NSData dataWithBytes:privKey->verkeydata().data() length:privKey->verkeydata().size()];
//
//            if(decKeyData && sigKeyData && encKeyData && verKeyData)
//            {
//                MynigmaPrivateKey* keyPair = [MynigmaPrivateKey makePrivateKeyObjectWithLabel:keyLabel forEmail:/*[PublicKeyManager emailForKeyLabel:keyLabel]*/nil];
//
//                if([KeychainHelper addPrivateKeyWithLabel:keyLabel toKeychainWithEncData:encKeyData verData:verKeyData decData:decKeyData sigData:sigKeyData passphrase:passphrase])
//                    [importedLabels addObject:keyLabel];
//                else
//                {
//                    //this should never happen: the only reason for addPrivateKey to fail would be if there is a different key already in the keychain, but we have tested for that...
//                    [errorLabels addObject:keyLabel];
//                    [MAIN_CONTEXT deleteObject:keyPair];
//
//                    //[MAIN_CONTEXT processPendingChanges];
//
//                    continue;
//                }
//
//                for(int j=0; j<privKey->currentreceivedforemail_size(); j++)
//                {
//                    NSString* address = [[NSString alloc] initWithBytes:privKey->currentsentforemail(j).data() length:privKey->currentreceivedforemail(j).length() encoding:NSUTF8StringEncoding];
//
//                    [EmailContactDetail addEmailContactDetailForEmail:address withCallback:^(EmailContactDetail *contactDetail) {
//                    if(contactDetail)
//                    {
//                        [keyPair addCurrentReceivedForEmailObject:contactDetail];
//                    }
//                    }];
//
//                }
//
//                for(int j=0; j<privKey->currentsentforemail_size(); j++)
//                {
//                    NSString* address = [[NSString alloc] initWithBytes:privKey->currentsentforemail(j).data() length:privKey->currentsentforemail(j).length() encoding:NSUTF8StringEncoding];
//
//                    [EmailContactDetail addEmailContactDetailForEmail:address withCallback:^(EmailContactDetail *contactDetail) {
//                        [keyPair addCurrentSentForEmailObject:contactDetail];
//                   }];
//                 }
//            }
//        }
//    }
//
//
//    /*public keys*/
//    for(int i=0; i<accountData->pubkeys_size(); i++)
//    {
//        mynigma::publicKey* publicKey = new mynigma::publicKey;
//        *publicKey = accountData->pubkeys(i);
//
//        NSString* keyLabel = [[NSString alloc] initWithBytes:publicKey->keylabel().data() length:publicKey->keylabel().length() encoding:NSUTF8StringEncoding];
//
//        if(![KeychainHelper havePublicKeychainItemWithLabel:keyLabel])
//        {
//            NSData* encKeyData = [NSData dataWithBytes:publicKey->encrkeydata().data() length:publicKey->encrkeydata().size()];
//
//            NSData* verKeyData = [NSData dataWithBytes:publicKey->verkeydata().data() length:publicKey->verkeydata().size()];
//
//            NSData* emailData = [NSData dataWithBytes:publicKey->email().data() length:publicKey->email().size()];
//
//            NSString* email = [[NSString alloc] initWithData:emailData encoding:NSUTF8StringEncoding];
//
//            if(encKeyData && verKeyData && email)
//            {
//                [MynigmaPublicKey publicKeyWithEncKeyData:encKeyData andVerKeyData:verKeyData forEmail:email keyLabel:keyLabel];
//
//                for(int j=0; j<publicKey->currentkeyforemail_size(); j++)
//                {
//                    NSString* address = [[NSString alloc] initWithBytes:publicKey->currentkeyforemail(j).data() length:publicKey->currentkeyforemail(j).length() encoding:NSUTF8StringEncoding];
//
//                }
//
//            }
//        }
//    }
//
//    for(int i=0; i<accountData->accounts_size(); i++)
//    {
//        mynigma::accountLoginData* loginData = new mynigma::accountLoginData;
//        *loginData = accountData->accounts(i);
//
//        NSString* emailAddress = [[NSString alloc] initWithBytes:loginData->email().data() length:loginData->email().size() encoding:NSUTF8StringEncoding];
//
//        if([AccountCreationManager haveAccountForEmail:emailAddress])
//            continue;
//
//        IMAPAccount* account = [AccountCreationManager temporaryAccountWithEmail:emailAddress];
//
//        //takes an IMAPAccountSetting and creates a suitable IMAPAccountSetting for it - the account becomes permanent (i.e. stored)
//        [AccountCreationManager makeAccountPermanent:account];
//        
//        IMAPAccountSetting* accountSetting = account.accountSetting;
//
//        [MAIN_CONTEXT obtainPermanentIDsForObjects:@[accountSetting] error:nil];
//
//        [accountSetting setEmailAddress:emailAddress];
//
//        NSString* displayName = [[NSString alloc] initWithBytes:loginData->displayname().data() length:loginData->displayname().size() encoding:NSUTF8StringEncoding];
//
//        [accountSetting setDisplayName:displayName];
//
//        NSString* senderEmail = [[NSString alloc] initWithBytes:loginData->senderemail().data() length:loginData->senderemail().size() encoding:NSUTF8StringEncoding];
//
//        [accountSetting setSenderEmail:senderEmail];
//
//        NSString* senderName = [[NSString alloc] initWithBytes:loginData->sendername().data() length:loginData->sendername().size() encoding:NSUTF8StringEncoding];
//
//        [accountSetting setSenderName:senderName];
//
//        [accountSetting setIncomingServer:[[NSString alloc] initWithBytes:loginData->inhostname().data() length:loginData->inhostname().size() encoding:NSUTF8StringEncoding]];
//        [accountSetting setIncomingUserName:[[NSString alloc] initWithBytes:loginData->inusername().data() length:loginData->inusername().size() encoding:NSUTF8StringEncoding]];
//        [accountSetting setIncomingAuthType:@(loginData->inauthtype())];
//        [accountSetting setIncomingEncryption:@(loginData->inencryption())];
//        [accountSetting setIncomingPort:@(loginData->inport())];
//        [KeychainHelper savePassword:[[NSString alloc] initWithBytes:loginData->inpassword().data() length:loginData->inpassword().size() encoding:NSUTF8StringEncoding] forAccount:accountSetting.objectID incoming:YES];
//
//        [accountSetting setOutgoingServer:[[NSString alloc] initWithBytes:loginData->outhostname().data() length:loginData->outhostname().size() encoding:NSUTF8StringEncoding]];
//        [accountSetting setOutgoingUserName:[[NSString alloc] initWithBytes:loginData->outusername().data() length:loginData->outusername().size() encoding:NSUTF8StringEncoding]];
//        [accountSetting setOutgoingAuthType:@(loginData->outauthtype())];
//        [accountSetting setOutgoingEncryption:@(loginData->outencryption())];
//        [accountSetting setOutgoingPort:@(loginData->outport())];
//        [KeychainHelper savePassword:[[NSString alloc] initWithBytes:loginData->outpassword().data() length:loginData->outpassword().size() encoding:NSUTF8StringEncoding] forAccount:accountSetting.objectID incoming:NO];
//
//        [accountSetting setHasBeenVerified:[NSNumber numberWithBool:NO]];
//
//        if(MODEL.usersOwnEmailAddresses)
//            MODEL.usersOwnEmailAddresses =[MODEL.usersOwnEmailAddresses arrayByAddingObject:emailAddress];
//        else
//            MODEL.usersOwnEmailAddresses = @[emailAddress];
//
//        if(![MODEL.currentUserSettings preferredAccount])
//            [MODEL.currentUserSettings setPreferredAccount:accountSetting];
//
//        NSEntityDescription* outboxEntity = [NSEntityDescription entityForName:@"IMAPFolderSetting" inManagedObjectContext:MAIN_CONTEXT];
//        IMAPFolderSetting* newOutboxFolder = [[IMAPFolderSetting alloc] initWithEntity:outboxEntity insertIntoManagedObjectContext:MAIN_CONTEXT];
//        [accountSetting setOutboxFolder:newOutboxFolder];
//        [newOutboxFolder setDisplayName:@"Outbox"];
//        [newOutboxFolder setIsShownAsStandard:[NSNumber numberWithBool:NO]];
//        [newOutboxFolder setStatus:@""];
//
//        [MODEL setAccounts:[MODEL.accounts arrayByAddingObject:account]];
//        if(index==0)
//            [accountSetting setPreferredAccountForUser:accountSetting.user];
//        [[Model userSettings] addAccountsObject:accountSetting];
//        [AccountCheckManager initialCheckForAccountSetting:accountSetting];
//    }
//    [MODEL saveWithCallback:^{
//    if(callback)
//        callback(importedLabels, errorLabels);
//    }];
}

+ (void)saveAsDialogue
{
#if TARGET_OS_IPHONE
#else

    NSSavePanel* saveAsPanel = [NSSavePanel new];

    [saveAsPanel setAllowsOtherFileTypes:NO];
    [saveAsPanel setAllowedFileTypes:@[@"myn"]];
    [saveAsPanel setCanCreateDirectories:YES];
    [saveAsPanel setCanSelectHiddenExtension:NO];
    [saveAsPanel setMessage:NSLocalizedString(@"Never back up your key to an insecure location!",@"key backup save dialog")];
    [saveAsPanel setDirectoryURL:[NSURL URLWithString:@"/"]];
    [saveAsPanel setRepresentedFilename:NSLocalizedString(@"Key backup.myn",@"Key backup file name")];
    [saveAsPanel setNameFieldStringValue:NSLocalizedString(@"Key backup.myn", @"Key backup file name")];

    if([saveAsPanel runModal]==NSOKButton)
    {
        NSData* wrappedData = [DataWrapHelper makeAccountDataPackageIncludingPublicKeys:NO includingAccountSettings:NO];

        if(!wrappedData)
        {
                NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Error backing up key",@"alert window") defaultButton:NSLocalizedString(@"OK",@"OK button") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Failed to create key package",@"alert window")];
                [alert runModal];

                return;
        }

        NSURL* url = saveAsPanel.URL;

        [url startAccessingSecurityScopedResource];

        NSError* error = nil;

        [wrappedData writeToURL:url options:NSDataWritingAtomic error:&error];

        if(error)
        {
            NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Error saving key",@"alert window") defaultButton:NSLocalizedString(@"OK",@"OK button") alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", error.localizedFailureReason];
            [alert runModal];
        }
        else
        {
            NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Success",@"alert window") defaultButton:NSLocalizedString(@"OK",@"OK button") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Your key has been backed up",@"alert window")];
            [alert runModal];
        }


        [url stopAccessingSecurityScopedResource];
    }
#endif

}



+ (void)openDialogue
{
    
#if TARGET_OS_IPHONE
#else

    NSOpenPanel* openPanel = [NSOpenPanel new];
    [openPanel setAllowsOtherFileTypes:NO];
    [openPanel setAllowedFileTypes:@[@"myn"]];
    [openPanel setCanCreateDirectories:NO];
    [openPanel setCanSelectHiddenExtension:NO];
    [openPanel setMessage:NSLocalizedString(@"Please select the Mynigma key backup file",@"key restore (open) dialog")];
    [openPanel setDirectoryURL:[NSURL URLWithString:@"/"]];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowsMultipleSelection:NO];

    if([openPanel runModal]==NSOKButton)
    {
        NSURL* url = openPanel.URL;

        NSData* wrappedData = [NSData dataWithContentsOfURL:url];

        [url startAccessingSecurityScopedResource];

        [DataWrapHelper unwrapAccountDataPackage:wrappedData withCallback:^(NSArray* importedPrivateKeyLabels, NSArray* errorLabels){
            if(importedPrivateKeyLabels && errorLabels.count==0)
            {
                NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Success",@"alert window") defaultButton:NSLocalizedString(@"OK",@"OK button") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Your keys have been restored",@"alert window")];
                [alert runModal];
            }
            else
            {
                NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Error",@"alert window") defaultButton:NSLocalizedString(@"OK",@"OK button") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"An error occurred during key import",@"alert window")];
                [alert runModal];
            }

        }];

        [url stopAccessingSecurityScopedResource];
        

    }
#endif

}



+ (NSData*)wrapDeviceMessage:(DeviceMessage*)deviceMessage
{
    mynigma::deviceMessage* protoDeviceMessage = new mynigma::deviceMessage;

    NSString* messageKind = deviceMessage.messageCommand;

    if(messageKind)
        protoDeviceMessage->set_message_kind([messageKind UTF8String]);

    if(deviceMessage.dateSent)
        protoDeviceMessage->set_sent_date([deviceMessage.dateSent timeIntervalSince1970]);

    NSString* senderUUID = [deviceMessage.sender deviceId];

    if(senderUUID)
        protoDeviceMessage->set_sender_uuid([senderUUID UTF8String]);

    for(MynigmaDevice* recipientDevice in deviceMessage.targets)
    {
        if(recipientDevice.deviceId)
        {
            protoDeviceMessage->add_recipient_uuids([recipientDevice.deviceId UTF8String]);
        }
        else
            NSLog(@"Recipient device is missing UUID!! %@", recipientDevice);
    }
    
    if(deviceMessage.expiryDate)
        protoDeviceMessage->set_expiry_date([deviceMessage.expiryDate timeIntervalSince1970]);

    protoDeviceMessage->set_burn_after_reading(deviceMessage.burnAfterReading);

    for(NSData* payloadPacket in deviceMessage.payload)
    {
        if([payloadPacket isKindOfClass:[NSData class]])
        {
            protoDeviceMessage->add_payload(payloadPacket.bytes, payloadPacket.length);
        }
        else
        {
            NSLog(@"Invalid payload packet!! %@", payloadPacket);
        }
    }

    if(deviceMessage.threadID)
        protoDeviceMessage->set_thread_id([deviceMessage.threadID UTF8String]);

    int device_message_size = protoDeviceMessage->ByteSize();
    void* device_message_data = malloc(device_message_size);
    protoDeviceMessage->SerializeToArray(device_message_data, device_message_size);

    NSData* returnData = [[NSData alloc] initWithBytes:device_message_data length:device_message_size];
    free(device_message_data);
    delete protoDeviceMessage;

    return returnData;
}

+ (BOOL)unwrapData:(NSData*)deviceMessageData intoDeviceMessage:(DeviceMessage*)deviceMessage
{
    if(!deviceMessageData.length)
        return NO;

    mynigma::deviceMessage* protoDeviceMessage = new mynigma::deviceMessage;

    protoDeviceMessage->ParseFromArray([deviceMessageData bytes],(int)[deviceMessageData length]);

    if(!protoDeviceMessage)
    {
        return NO;
    }

//    
//    already set through the header fields:
//    
//    NSString* messageKind = [[NSString alloc] initWithBytes:protoDeviceMessage->message_kind().data() length:protoDeviceMessage->message_kind().size() encoding:NSUTF8StringEncoding];
//
//    if(messageKind)
//        [deviceMessage setMessageCommand:messageKind];
//    

    long long unixSentDate = protoDeviceMessage->sent_date();

    if(unixSentDate>0)
        [deviceMessage setDateSent:[NSDate dateWithTimeIntervalSince1970:unixSentDate]];

    long long unixExpiryDate = protoDeviceMessage->expiry_date();

    if(unixExpiryDate>0)
        [deviceMessage setExpiryDate:[NSDate dateWithTimeIntervalSince1970:unixExpiryDate]];

//    for(int i=0; i<protoDeviceMessage->recipient_uuids_size(); i++)
//    {
//        NSString* recipientUUID = [[NSString alloc] initWithBytes:protoDeviceMessage->recipient_uuids(i).data() length:protoDeviceMessage->recipient_uuids(i).size() encoding:NSUTF8StringEncoding];
//
//        if(recipientUUID)
//        {
//            MynigmaDevice* recipientDevice = [MynigmaDevice deviceWithUUID:recipientUUID addIfNotFound:YES inContext:deviceMessage.managedObjectContext];
//            if(recipientDevice)
//            {
//                [deviceMessage addTargetsObject:recipientDevice];
//                //[newRecipientsArray addObject:recipientDevice];
//            }
//        }
//    }

    NSMutableArray* newPayloadArray = [NSMutableArray new];

    for(int i=0; i<protoDeviceMessage->payload_size(); i++)
    {
        NSData* payloadData = [NSData dataWithBytes:protoDeviceMessage->payload(i).data() length:protoDeviceMessage->payload(i).size()];

        if(payloadData)
            [newPayloadArray addObject:payloadData];
    }

    [deviceMessage setPayload:newPayloadArray];

    [deviceMessage setBurnAfterReading:@(protoDeviceMessage->burn_after_reading())];

//    NSString* threadID = [[NSString alloc] initWithBytes:protoDeviceMessage->thread_id().data() length:protoDeviceMessage->thread_id().size() encoding:NSUTF8StringEncoding];
//
//    if(threadID)
//        [deviceMessage setThreadID:threadID];
//    
    delete protoDeviceMessage;
    
    return YES;
}

//+ (DeviceMessage*)unwrapDeviceMessage:(NSData*)deviceMessageData
//{
//    mynigma::deviceMessage* protoDeviceMessage = new mynigma::deviceMessage;
//
//    protoDeviceMessage->ParseFromArray([deviceMessageData bytes],(int)[deviceMessageData length]);
//
//    if(!protoDeviceMessage)
//    {
//        return nil;
//    }
//
//    return nil;
//
//    DeviceMessage* deviceMessage = nil;//[DeviceMessage ];
//
//    NSString* messageKind = [[NSString alloc] initWithBytes:protoDeviceMessage->message_kind().data() length:protoDeviceMessage->message_kind().size() encoding:NSUTF8StringEncoding];
//
//    if(messageKind)
//        [deviceMessage setMessageCommand:messageKind];
//
//    NSInteger unixSentDate = protoDeviceMessage->sent_date();
//
//    if(unixSentDate>0)
//        [deviceMessage setDateSent:[NSDate dateWithTimeIntervalSince1970:unixSentDate]];
//
//    NSInteger unixExpiryDate = protoDeviceMessage->expiry_date();
//
//    if(unixExpiryDate>0)
//        [deviceMessage setExpiryDate:[NSDate dateWithTimeIntervalSince1970:unixExpiryDate]];
//
//    NSString* senderUUID = [[NSString alloc] initWithBytes:protoDeviceMessage->sender_uuid().data() length:protoDeviceMessage->sender_uuid().length() encoding:NSUTF8StringEncoding];
//
//    if(senderUUID)
//        [deviceMessage setSender:[MynigmaDevice deviceWithUUID:senderUUID]];
//
//    //NSMutableArray* newRecipientsArray = [NSMutableArray new];
//
//    for(int i=0; i<protoDeviceMessage->recipient_uuids_size(); i++)
//    {
//        NSString* recipientUUID = [[NSString alloc] initWithBytes:protoDeviceMessage->recipient_uuids(i).data() length:protoDeviceMessage->recipient_uuids(i).size() encoding:NSUTF8StringEncoding];
//
//        if(recipientUUID)
//        {
//            MynigmaDevice* recipientDevice = [MynigmaDevice deviceWithUUID:recipientUUID addIfNotFound:YES];
//            if(recipientDevice)
//            {
//                [deviceMessage addTargetsObject:recipientDevice];
//                //[newRecipientsArray addObject:recipientDevice];
//            }
//        }
//    }
//
//    //[deviceMessage setTargets:newRecipientsArray];
//
//    NSMutableArray* newPayloadArray = [NSMutableArray new];
//
//    for(int i=0; i<protoDeviceMessage->payload_size(); i++)
//    {
//        NSData* payloadData = [NSData dataWithBytes:protoDeviceMessage->payload(i).data() length:protoDeviceMessage->payload(i).size()];
//
//        if(payloadData)
//            [newPayloadArray addObject:payloadData];
//    }
//
//    [deviceMessage setPayload:newPayloadArray];
//
//    [deviceMessage setBurnAfterReading:@(protoDeviceMessage->burn_after_reading())];
//
//    NSString* threadID = [[NSString alloc] initWithBytes:protoDeviceMessage->thread_id().data() length:protoDeviceMessage->thread_id().size() encoding:NSUTF8StringEncoding];
//
//    if(threadID)
//        [deviceMessage setThreadID:threadID];
//
//    delete protoDeviceMessage;
//    
//    return deviceMessage;
//}

+ (NSData*)wrapDeviceDiscoveryData:(MynigmaDevice*)mynigmaDevice
{
    mynigma::deviceDiscoveryData* protoDeviceDiscoveryData = new mynigma::deviceDiscoveryData;

    protoDeviceDiscoveryData->set_name([mynigmaDevice.displayName UTF8String]);

    NSString* deviceID = mynigmaDevice.deviceId;

    if(deviceID)
        protoDeviceDiscoveryData->set_uuid([mynigmaDevice.deviceId UTF8String]);

    protoDeviceDiscoveryData->set_type([mynigmaDevice.type UTF8String]);

    for(IMAPAccountSetting* accountSetting in [UserSettings currentUserSettings].accounts)
    {
        if(accountSetting.emailAddress)
        {
            protoDeviceDiscoveryData->add_emailadresses([accountSetting.emailAddress UTF8String]);
        }
    }

    for(MynigmaPrivateKey* privateKey in [PublicKeyManager listAllPrivateKeys])
    {
        if(privateKey.keyLabel)
        {
            protoDeviceDiscoveryData->add_privatekeylabels([privateKey.keyLabel UTF8String]);
        }
    }

    int device_message_size = protoDeviceDiscoveryData->ByteSize();
    void* device_message_data = malloc(device_message_size);
    protoDeviceDiscoveryData->SerializeToArray(device_message_data, device_message_size);

    NSData* returnData = [[NSData alloc] initWithBytes:device_message_data length:device_message_size];
    free(device_message_data);
    delete protoDeviceDiscoveryData;

    return returnData;
}

+ (MynigmaDevice*)unwrapDeviceDiscoveryData:(NSData*)deviceDiscoveryData withDate:(NSDate*)dateFound inContext:(NSManagedObjectContext*)localContext
{
    mynigma::deviceDiscoveryData* protoDeviceDiscoveryData = new mynigma::deviceDiscoveryData;

    protoDeviceDiscoveryData->ParseFromArray([deviceDiscoveryData bytes],(int)[deviceDiscoveryData length]);

    NSString* UUID = [[NSString alloc] initWithBytes:protoDeviceDiscoveryData->uuid().data() length:protoDeviceDiscoveryData->uuid().size() encoding:NSUTF8StringEncoding];

    if(!UUID)
    {
        NSLog(@"Unable to unwrap device discovery data: no UUID!");
        return nil;
    }
    
    if([UUID isEqual:[MynigmaDevice currentDeviceInContext:localContext].deviceId])
    {
        //no need to parse any data concerning the current device(!)
        //we already know the info and don't want an attacker to be able to change it...
        return nil;
    }

    MynigmaDevice* device = [MynigmaDevice deviceWithUUID:UUID addIfNotFound:YES inContext:localContext];

    if(device.lastUpdatedInfo && [device.lastUpdatedInfo compare:dateFound]!=NSOrderedAscending)
    {
        //the device info being processed is no more recent than the one in the store - abort
        return device;
    }

    NSString* displayName = [[NSString alloc] initWithBytes:protoDeviceDiscoveryData->name().data() length:protoDeviceDiscoveryData->name().size() encoding:NSUTF8StringEncoding];

    if(displayName)
        [device setDisplayName:displayName];

    NSString* deviceType = [[NSString alloc] initWithBytes:protoDeviceDiscoveryData->type().data() length:protoDeviceDiscoveryData->type().size() encoding:NSUTF8StringEncoding];

    if(deviceType)
        [device setType:deviceType];

    delete protoDeviceDiscoveryData;

    return device;
}



#pragma mark - SYNC DATA

+ (NSData*)makeCompleteSyncDataPackage
{
    [ThreadHelper ensureMainThread];

    /*private keys*/
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MynigmaPrivateKey"];

    NSArray* keyPairs = [MAIN_CONTEXT executeFetchRequest:fetchRequest error:nil];

    fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MynigmaPublicKey"];

    NSArray* publicKeys = [MAIN_CONTEXT executeFetchRequest:fetchRequest error:nil];

    fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"EmailContactDetail"];

    NSArray* contactDetail = [MAIN_CONTEXT executeFetchRequest:fetchRequest error:nil];

    return [DataWrapHelper makeSyncDataPackageWithPrivateKeys:keyPairs andPublicKeys:publicKeys andEmailContactDetails:contactDetail passphrase:@"password"];
}


+ (NSData*)makeSyncDataPackageWithPrivateKeys:(NSArray*)privateKeys andPublicKeys:(NSArray*)publicKeys andEmailContactDetails:(NSArray*)contactDetails passphrase:(NSString*)passphrase
{
    [ThreadHelper ensureMainThread];

    mynigma::syncData* syncData = new mynigma::syncData;

    /*private keys*/
    for(MynigmaPrivateKey* keyPair in privateKeys)
    {
        //the private key data

        NSArray* pemData = [MynigmaPrivateKey dataForPrivateKeyWithLabel:keyPair.keyLabel passphrase:passphrase];

        if(pemData && pemData.count>=4)
        {
            NSData* decPemData = pemData[0];

            NSData* sigPemData = pemData[1];

            NSData* encPemData = pemData[2];

            NSData* verPemData = pemData[3];

            if(encPemData && sigPemData && decPemData && verPemData)
            {
                mynigma::syncPrivateKey* newPrivateKey = syncData->add_privkeys();

//                required bytes encrKeyData = 1;
                newPrivateKey->set_encrkeydata(encPemData.bytes, encPemData.length);

//                required bytes verKeyData = 2;
                newPrivateKey->set_verkeydata(verPemData.bytes, verPemData.length);

//                required string keyLabel = 3;
                newPrivateKey->set_keylabel([keyPair.keyLabel UTF8String]);

//                optional int32 dateCreated = 4;
                newPrivateKey->set_datecreated([keyPair.dateCreated timeIntervalSince1970]);

//                optional bool isCompromised = 5;
                newPrivateKey->set_iscompromised(keyPair.isCompromised.boolValue);

//                optional string version = 6;
                newPrivateKey->set_version([MYNIGMA_VERSION UTF8String]);

//                repeated string currentKeyForEmail = 7;
                for(EmailAddress* emailAddress in keyPair.currentForEmailAddress)
                {
                    newPrivateKey->add_currentkeyforemail([emailAddress.address UTF8String]);
                }

//                optional int32 dateObtained = 8;
                newPrivateKey->set_dateobtained([[keyPair dateObtained] timeIntervalSince1970]);

//                optional int32 dateDeclared = 9;
                newPrivateKey->set_datedeclared([[keyPair dateObtained] timeIntervalSince1970]);

//                optional int32 dateFirstAnchored = 10;
                newPrivateKey->set_datefirstanchored([[keyPair firstAnchored] timeIntervalSince1970]);

//                optional bool fromServer = 11;
                newPrivateKey->set_fromserver(keyPair.fromServer.boolValue);

//                repeated string introducesKeys = 12;
                for(MynigmaPublicKey* introducedKey in keyPair.introducesKeys)
                {
                    newPrivateKey->add_introduceskeys([introducedKey.keyLabel UTF8String]);
                }

//                repeated string isIntroducedByKeys = 13;
                for(MynigmaPublicKey* introducingKey in keyPair.isIntroducedByKeys)
                {
                    newPrivateKey->add_isintroducedbykeys([introducingKey.keyLabel UTF8String]);
                }

//                repeated string emailAddresses = 14;
                for(EmailAddress* emailAddress in keyPair.emailAddresses)
                {
                    newPrivateKey->add_emailaddresses([emailAddress.address UTF8String]);
                }

//                optional bytes decrKeyData = 15;
                newPrivateKey->set_decrkeydata(decPemData.bytes, decPemData.length);

//                optional bytes signKeyData = 16;
                newPrivateKey->set_signkeydata(sigPemData.bytes, sigPemData.length);

            }
        }
        else
            return nil;
    }

        /*public keys*/
        for(MynigmaPublicKey* publicKey in publicKeys)
        {
            NSArray* pemData = [MynigmaPublicKey dataForExistingMynigmaPublicKeyWithLabel:publicKey.keyLabel];

            if(pemData && pemData.count>=2)
            {
                NSData* encPemData = pemData[0];

                NSData* verPemData = pemData[1];

                if(encPemData && verPemData)
                {
                    mynigma::syncPublicKey* newPublicKey = syncData->add_pubkeys();

                    //                required bytes encrKeyData = 1;
                    newPublicKey->set_encrkeydata(encPemData.bytes, encPemData.length);

                    //                required bytes verKeyData = 2;
                    newPublicKey->set_verkeydata(verPemData.bytes, verPemData.length);

                    //                required string keyLabel = 3;
                    newPublicKey->set_keylabel([publicKey.keyLabel UTF8String]);

                    //                optional int32 dateCreated = 4;
                    newPublicKey->set_datecreated([publicKey.dateCreated timeIntervalSince1970]);

                    //                optional bool isCompromised = 5;
                    newPublicKey->set_compromised(publicKey.isCompromised.boolValue);

                    //                optional string version = 6;
                    newPublicKey->set_version([MYNIGMA_VERSION UTF8String]);

                    //                repeated string currentKeyForEmail = 7;
                    for(EmailAddress* emailAddress in publicKey.currentForEmailAddress)
                    {
                        newPublicKey->add_currentkeyforemail([emailAddress.address UTF8String]);
                    }

                    //                optional int32 dateObtained = 8;
                    newPublicKey->set_dateobtained([[publicKey dateObtained] timeIntervalSince1970]);

                    //                optional int32 dateDeclared = 9;
                    newPublicKey->set_datedeclared([[publicKey dateObtained] timeIntervalSince1970]);

                    //                optional int32 dateFirstAnchored = 10;
                    newPublicKey->set_datefirstanchored([[publicKey firstAnchored] timeIntervalSince1970]);

                    //                optional bool fromServer = 11;
                    newPublicKey->set_fromserver(publicKey.fromServer.boolValue);

                    //                repeated string introducesKeys = 12;
                    for(MynigmaPublicKey* introducedKey in publicKey.introducesKeys)
                    {
                        newPublicKey->add_introduceskeys([introducedKey.keyLabel UTF8String]);
                    }

                    //                repeated string isIntroducedByKeys = 13;
                    for(MynigmaPublicKey* introducingKey in publicKey.isIntroducedByKeys)
                    {
                        newPublicKey->add_isintroducedbykeys([introducingKey.keyLabel UTF8String]);
                    }
                    
                    //                repeated string emailAddresses = 14;
                    for(EmailAddress* emailAddress in publicKey.emailAddresses)
                    {
                        newPublicKey->add_emailaddresses([emailAddress.address UTF8String]);
                    }
                }
            }
        }

    /*contact details*/
    for(EmailContactDetail* contactDetail in contactDetails)
    {
        mynigma::contactDetail* newContactDetail = syncData->add_contacts();

        NSString* emailAddress = contactDetail.address;

        if(emailAddress)
            newContactDetail->set_emailaddress(emailAddress.UTF8String);

        NSString* fullName = contactDetail.fullName;

        if(fullName)
            newContactDetail->set_fullname(fullName.UTF8String);

        NSInteger numberOfTimesContacted = contactDetail.numberOfTimesContacted.integerValue;

        newContactDetail->set_numberoftimescontacted((int)numberOfTimesContacted);
    }


    int data_size = syncData->ByteSize();
    void* data_buffer = malloc(data_size);

    syncData->SerializeToArray(data_buffer,data_size);

    NSData* confidentialAccountsData = [[NSData alloc] initWithBytes:data_buffer length:data_size];

    delete syncData;
    free(data_buffer);

    return confidentialAccountsData;
}



/**CALL ON MAIN*/
+ (void)unwrapSyncDataPackage:(NSData*)data withCallback:(void(^)(NSArray* importedPrivateKeyLabels, NSArray* importedPublicKeyLabels, NSArray* importedAccounts, NSArray* importedContactDetails, NSArray* errors))callback passphrase:(NSString*)passphrase inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureMainThread];

    mynigma::syncData* syncData = new mynigma::syncData;

    syncData->ParseFromArray([data bytes],(int)[data length]);

    if(!syncData)
    {
        if(callback)
            callback(nil, nil, nil, nil, @[[NSError errorWithDomain:@"syncData import" code:1 userInfo:nil]]);
        return;
    }

    NSMutableArray* importedPrivateKeys = [NSMutableArray new];
    NSMutableArray* importedPublicKeys = [NSMutableArray new];
    NSMutableArray* importedAccounts = [NSMutableArray new];
    NSMutableArray* importedContactDetails = [NSMutableArray new];
    NSMutableArray* errors = [NSMutableArray new];

    //first import the private keys
    for(int i=0; i<syncData->privkeys_size(); i++)
    {
        mynigma::syncPrivateKey* privKey = new mynigma::syncPrivateKey;
        *privKey = syncData->privkeys(i);

        //                required string keyLabel = 3;
        NSString* keyLabel = [[NSString alloc] initWithBytes:privKey->keylabel().data() length:privKey->keylabel().length() encoding:NSUTF8StringEncoding];

        //only add the key if we don't already have one
        //give preference to existing items in keychain, even if they have no associated objects in the store


        if(![MynigmaPrivateKey havePrivateKeyWithLabel:keyLabel])
        {
            //                optional bytes decrKeyData = 15;
            NSData* decKeyData = [NSData dataWithBytes:privKey->decrkeydata().data() length:privKey->decrkeydata().size()];

            //                optional bytes signKeyData = 16;
            NSData* sigKeyData = [NSData dataWithBytes:privKey->signkeydata().data() length:privKey->signkeydata().size()];

            //                required bytes encrKeyData = 1;
            NSData* encKeyData = [NSData dataWithBytes:privKey->encrkeydata().data() length:privKey->encrkeydata().size()];

            //                required bytes verKeyData = 2;
            NSData* verKeyData = [NSData dataWithBytes:privKey->verkeydata().data() length:privKey->verkeydata().size()];

            if(decKeyData && sigKeyData && encKeyData && verKeyData)
            {
                MynigmaPrivateKey* privateKey = [MynigmaPrivateKey syncMakeNewPrivateKeyWithEncKeyData:encKeyData andVerKeyData:verKeyData decKeyData:decKeyData sigKeyData:sigKeyData forEmail:nil keyLabel:keyLabel inContext:localContext];

                [importedPrivateKeys addObject:privateKey];

                //                optional int32 dateCreated = 4;
                long long unixCreationDate = privKey->datecreated();

                if(unixCreationDate>0)
                    [privateKey setDateCreated:[NSDate dateWithTimeIntervalSince1970:unixCreationDate]];


                //                optional bool isCompromised = 5;
                BOOL isCompromised = privKey->iscompromised();

                [privateKey setIsCompromised:@(isCompromised)];


                //                optional string version = 6;
                NSString* versionString = [[NSString alloc] initWithBytes:privKey->keylabel().data() length:privKey->keylabel().length() encoding:NSUTF8StringEncoding];

                [privateKey setVersion:versionString];


                //                repeated string currentKeyForEmail = 7;
                for(int j=0; j<privKey->currentkeyforemail_size(); j++)
                {
                    NSString* emailString = [[NSString alloc] initWithBytes:privKey->currentkeyforemail(j).data() length:privKey->currentkeyforemail(j).size() encoding:NSUTF8StringEncoding];

                    if(emailString)
                        [privateKey associateKeyWithEmail:emailString forceMakeCurrent:NO inContext:localContext];
                }


                //                optional int32 dateObtained = 8;
                long long unixObtainDate = privKey->dateobtained();

                if(unixObtainDate>0)
                    [privateKey setDateObtained:[NSDate dateWithTimeIntervalSince1970:unixObtainDate]];


                //                optional int32 dateDeclared = 9;
                long long unixDeclaredDate = privKey->datedeclared();

                if(unixDeclaredDate>0)
                    [privateKey setDateDeclared:[NSDate dateWithTimeIntervalSince1970:unixDeclaredDate]];


                //                optional int32 dateFirstAnchored = 10;
                long long unixAnchoredDate = privKey->datefirstanchored();

                if(unixAnchoredDate>0)
                    [privateKey setFirstAnchored:[NSDate dateWithTimeIntervalSince1970:unixAnchoredDate]];


                //                optional bool fromServer = 11;
                BOOL fromServer = privKey->fromserver();

                [privateKey setFromServer:@(fromServer)];


                //                repeated string introducesKeys = 12;
                for(int j=0; j<privKey->introduceskeys_size(); j++)
                {
                    NSString* keyLabel = [[NSString alloc] initWithBytes:privKey->introduceskeys(j).data() length:privKey->introduceskeys(j).size() encoding:NSUTF8StringEncoding];

                    if(keyLabel)
                    {
                        //TO DO: add later

                        //introduction relationships currently not synchronised

//                        MynigmaPublicKey* publicKey = [MynigmaPublicKey ]
//                        [privateKey addIntroducesKeysObject:<#(MynigmaPublicKey *)#>];
                    }
                }
                

                //                repeated string isIntroducedByKeys = 13;

                //TO DO: add later

                //introduction relationships currently not synchronised

//                for(MynigmaPublicKey* introducingKey in keyPair.isIntroducedByKeys)
//                {
//                    newPrivateKey->add_isintroducedbykeys([introducingKey.keyLabel UTF8String]);
//                }

                //                repeated string emailAddresses = 14;


                //TO DO: add email addresses
                //do there even need to be synchronised?
                //not sure...


                //                for(int j=0; j<privKey->emailaddresses_size(); j++)
//                {
//                    NSString* emailAddress = [[NSString alloc] initWithBytes:privKey->emailaddresses(j).data() length:privKey->emailaddresses(j).size() encoding:NSUTF8StringEncoding];
//
//                    //[EmailAddress ]
//                }

            }
        }
    }


    /*public keys*/
    for(int i=0; i<syncData->pubkeys_size(); i++)
    {
        mynigma::syncPublicKey* pubKey = new mynigma::syncPublicKey;
        *pubKey = syncData->pubkeys(i);

        NSString* keyLabel = [[NSString alloc] initWithBytes:pubKey->keylabel().data() length:pubKey->keylabel().length() encoding:NSUTF8StringEncoding];

        if(![MynigmaPublicKey havePublicKeyWithLabel:keyLabel])
        {
            NSData* encKeyData = [NSData dataWithBytes:pubKey->encrkeydata().data() length:pubKey->encrkeydata().size()];

            NSData* verKeyData = [NSData dataWithBytes:pubKey->verkeydata().data() length:pubKey->verkeydata().size()];

            if(encKeyData && verKeyData)
            {
                NSString* emailString = [self emailForKeyLabel:keyLabel];

                MynigmaPublicKey* publicKey = [MynigmaPublicKey syncMakeNewPublicKeyWithEncKeyData:encKeyData andVerKeyData:verKeyData forEmail:emailString keyLabel:keyLabel inContext:localContext];

                [importedPublicKeys addObject:publicKey];

                //                optional int32 dateCreated = 4;
                long long unixCreationDate = pubKey->datecreated();

                if(unixCreationDate>0)
                    [publicKey setDateCreated:[NSDate dateWithTimeIntervalSince1970:unixCreationDate]];


                //                optional bool isCompromised = 5;
                BOOL isCompromised = pubKey->compromised();

                [publicKey setIsCompromised:@(isCompromised)];


                //                optional string version = 6;
                NSString* versionString = [[NSString alloc] initWithBytes:pubKey->keylabel().data() length:pubKey->keylabel().length() encoding:NSUTF8StringEncoding];

                [publicKey setVersion:versionString];


                //                repeated string currentKeyForEmail = 7;
                for(int j=0; j<pubKey->currentkeyforemail_size(); j++)
                {
                    NSString* emailString = [[NSString alloc] initWithBytes:pubKey->currentkeyforemail(j).data() length:pubKey->currentkeyforemail(j).size() encoding:NSUTF8StringEncoding];

                    if(emailString)
                        [publicKey associateKeyWithEmail:emailString forceMakeCurrent:NO inContext:localContext];
                }


                //                optional int32 dateObtained = 8;
                long long unixObtainDate = pubKey->dateobtained();

                if(unixObtainDate>0)
                    [publicKey setDateObtained:[NSDate dateWithTimeIntervalSince1970:unixObtainDate]];


                //                optional int32 dateDeclared = 9;
                long long unixDeclaredDate = pubKey->datedeclared();

                if(unixDeclaredDate>0)
                    [publicKey setDateDeclared:[NSDate dateWithTimeIntervalSince1970:unixDeclaredDate]];


                //                optional int32 dateFirstAnchored = 10;
                long long unixAnchoredDate = pubKey->datefirstanchored();

                if(unixAnchoredDate>0)
                    [publicKey setFirstAnchored:[NSDate dateWithTimeIntervalSince1970:unixAnchoredDate]];


                //                optional bool fromServer = 11;
                BOOL fromServer = pubKey->fromserver();

                [publicKey setFromServer:@(fromServer)];


                //                repeated string introducesKeys = 12;
                for(int j=0; j<pubKey->introduceskeys_size(); j++)
                {
                    NSString* keyLabel = [[NSString alloc] initWithBytes:pubKey->introduceskeys(j).data() length:pubKey->introduceskeys(j).size() encoding:NSUTF8StringEncoding];

                    if(keyLabel)
                    {
                        //TO DO: add later

                        //introduction relationships currently not synchronised

                        //                        MynigmaPublicKey* publicKey = [MynigmaPublicKey ]
                        //                        [privateKey addIntroducesKeysObject:<#(MynigmaPublicKey *)#>];
                    }
                }


                //                repeated string isIntroducedByKeys = 13;

                //TO DO: add later

                //introduction relationships currently not synchronised

                //                for(MynigmaPublicKey* introducingKey in keyPair.isIntroducedByKeys)
                //                {
                //                    newPrivateKey->add_isintroducedbykeys([introducingKey.keyLabel UTF8String]);
                //                }
                
                //                repeated string emailAddresses = 14;
                
                
                //TO DO: add email addresses
                //do there even need to be synchronised?
                //not sure...
                
                
                //                for(int j=0; j<privKey->emailaddresses_size(); j++)
                //                {
                //                    NSString* emailAddress = [[NSString alloc] initWithBytes:privKey->emailaddresses(j).data() length:privKey->emailaddresses(j).size() encoding:NSUTF8StringEncoding];
                //
                //                    //[EmailAddress ]
                //                }
                








//                for(int j=0; j<publicKey->currentkeyforemail_size(); j++)
//                {
//                    NSString* address = [[NSString alloc] initWithBytes:publicKey->currentkeyforemail(j).data() length:publicKey->currentkeyforemail(j).length() encoding:NSUTF8StringEncoding];
//
//                    [EmailContactDetail addEmailContactDetailForEmail:address withCallback:^(EmailContactDetail *contactDetail) {
//                    if(contactDetail)
//                    {
//                        [newPublicKey addCurrentKeyForEmailObject:contactDetail];
//                    }
//                    }];
//                }

            }
        }
    }




//    //now add the accounts
//    for(int i=0; i<syncData->accounts_size(); i++)
//    {
//        mynigma::accountLoginData* loginData = new mynigma::accountLoginData;
//        *loginData = syncData->accounts(i);
//
//        NSString* emailAddress = [[NSString alloc] initWithBytes:loginData->email().data() length:loginData->email().size() encoding:NSUTF8StringEncoding];
//
//        NSArray* registeredEmailAddresses = [AccountCreationManager registeredEmailAddresses];
//
//        //add the account if it hasn't already been registered
//        if(emailAddress && ![registeredEmailAddresses containsObject:emailAddress])
//        {
//
//            if([AccountCreationManager haveAccountForEmail:emailAddress])
//                continue;
//
//            IMAPAccount* account = [AccountCreationManager temporaryAccountWithEmail:emailAddress];
//
//            //takes an IMAPAccountSetting and creates a suitable IMAPAccountSetting for it - the account becomes permanent (i.e. stored)
//            [AccountCreationManager makeAccountPermanent:account];
//
//            IMAPAccountSetting* accountSetting = account.accountSetting;
//
//            [MAIN_CONTEXT obtainPermanentIDsForObjects:@[accountSetting] error:nil];
//
//
//        [accountSetting setEmailAddress:emailAddress];
//
//        [accountSetting setDisplayName:emailAddress];
//
//        [accountSetting setIncomingServer:[[NSString alloc] initWithBytes:loginData->inhostname().data() length:loginData->inhostname().size() encoding:NSUTF8StringEncoding]];
//        [accountSetting setIncomingUserName:[[NSString alloc] initWithBytes:loginData->inusername().data() length:loginData->inusername().size() encoding:NSUTF8StringEncoding]];
//        [accountSetting setIncomingAuthType:@(loginData->inauthtype())];
//        [accountSetting setIncomingEncryption:@(loginData->inencryption())];
//        [accountSetting setIncomingPort:@(loginData->inport())];
//        [KeychainHelper savePassword:[[NSString alloc] initWithBytes:loginData->inpassword().data() length:loginData->inpassword().size() encoding:NSUTF8StringEncoding] forAccount:accountSetting.objectID incoming:YES];
//
//        [accountSetting setOutgoingServer:[[NSString alloc] initWithBytes:loginData->outhostname().data() length:loginData->outhostname().size() encoding:NSUTF8StringEncoding]];
//        [accountSetting setOutgoingUserName:[[NSString alloc] initWithBytes:loginData->outusername().data() length:loginData->outusername().size() encoding:NSUTF8StringEncoding]];
//        [accountSetting setOutgoingAuthType:@(loginData->outauthtype())];
//        [accountSetting setOutgoingEncryption:@(loginData->outencryption())];
//        [accountSetting setOutgoingPort:@(loginData->outport())];
//        [KeychainHelper savePassword:[[NSString alloc] initWithBytes:loginData->outpassword().data() length:loginData->outpassword().size() encoding:NSUTF8StringEncoding] forAccount:accountSetting.objectID incoming:NO];
//
//        [accountSetting setHasBeenVerified:[NSNumber numberWithBool:NO]];
//
//        if([NSString usersAddresses])
//            [NSString setUsersAddresses:[[NSString usersAddresses] arrayByAddingObject:emailAddress]];
//        else
//            [NSString setUsersAddresses:@[emailAddress]];
//
//        if(![[UserSettings currentUserSettings] preferredAccount])
//            [[UserSettings currentUserSettings] setPreferredAccount:accountSetting];
//
//        NSEntityDescription* outboxEntity = [NSEntityDescription entityForName:@"IMAPFolderSetting" inManagedObjectContext:MAIN_CONTEXT];
//        IMAPFolderSetting* newOutboxFolder = [[IMAPFolderSetting alloc] initWithEntity:outboxEntity insertIntoManagedObjectContext:MAIN_CONTEXT];
//        [accountSetting setOutboxFolder:newOutboxFolder];
//        [newOutboxFolder setDisplayName:@"Outbox"];
//        [newOutboxFolder setIsShownAsStandard:[NSNumber numberWithBool:NO]];
//        [newOutboxFolder setStatus:@""];
//
//        [[AccountCreationManager sharedInstance] setAllAccounts:[MODEL.accounts arrayByAddingObject:account]];
//        if(index==0)
//            [accountSetting setPreferredAccountForUser:accountSetting.user];
//        [MODEL.currentUserSettings addAccountsObject:accountSetting];
//        [AccountCheckManager initialCheckForAccountSetting:accountSetting];
//
//        }
//    }

    //add contact details
    for(int i=0; i<syncData->contacts_size(); i++)
    {
        mynigma::contactDetail* emailContactDetail = new mynigma::contactDetail;
        *emailContactDetail = syncData->contacts(i);

        NSString* emailAddress = [[[NSString alloc] initWithBytes:emailContactDetail->emailaddress().data() length:emailContactDetail->emailaddress().length() encoding:NSUTF8StringEncoding] lowercaseString];

        //create a new email contact detail or re-use an existing one
        [EmailContactDetail addEmailContactDetailForEmail:emailAddress withCallback:^(EmailContactDetail *newContactDetail) {

        if(newContactDetail)
        {

//
//            protocol buffers definition:
//
//            message contactDetail
//            {
//                optional string firstName = 1;
//                optional string lastName = 2;
//                optional string emailAddress = 3;
//                optional string currentSentKey = 4;
//                optional int32 dateSentKey = 5;
//                optional string currentReceivedKey = 6;
//                optional int32 dateReceivedKey = 7;
//                optional int32 numberOfTimesContacted = 8;
//                optional int32 lastCheckedWithServer = 9;
//                optional string fullName = 10;
//                optional int32 lastInfoChange = 11;
//            }
//

//            NSString* firstName = [[NSString alloc] initWithBytes:emailContactDetail->firstname().data() length:emailContactDetail->firstname().length() encoding:NSUTF8StringEncoding];
//
//            NSString* lastName = [[NSString alloc] initWithBytes:emailContactDetail->lastname().data() length:emailContactDetail->firstname().length() encoding:NSUTF8StringEncoding];

            //update the currentSentKey if necessary
//            NSInteger UNIXDateSentKey = emailContactDetail->datesentkey();
//
//            if(UNIXDateSentKey>0)
//            {
//                NSDate* dateSentKey = [NSDate dateWithTimeIntervalSince1970:UNIXDateSentKey];
//
//                //only update the sent key if the new one is more recent than the existing one in the store
//                if(!newContactDetail.currentSentDate || [dateSentKey compare:newContactDetail.currentSentDate]==NSOrderedAscending)
//                {
//                    NSString* currentSentKeyLabel = [[NSString alloc] initWithBytes:emailContactDetail->currentsentkey().data() length:emailContactDetail->currentsentkey().length() encoding:NSUTF8StringEncoding];
//
//                    MynigmaPrivateKey* privateKey = [MynigmaPrivateKey privateKeyWithLabel:currentSentKeyLabel];
//
//                    if(privateKey)
//                    {
//                        [newContactDetail setCurrentSentDate:dateSentKey];
//                        [newContactDetail setCurrentSentPair:privateKey];
//                    }
//                }
//            }

            //now update the current received key
//            NSInteger UNIXDateReceivedKey = emailContactDetail->datereceivedkey();
//
//            if(UNIXDateReceivedKey>0)
//            {
//                NSDate* dateSentKey = [NSDate dateWithTimeIntervalSince1970:UNIXDateReceivedKey];
//
//                //only update the sent key if the new one is more recent than the existing one in the store
//                if(!newContactDetail.currentReceivedDate || [dateSentKey compare:newContactDetail.currentReceivedDate]==NSOrderedAscending)
//                {
//                    NSString* currentReceivedKeyLabel = [[NSString alloc] initWithBytes:emailContactDetail->currentreceivedkey().data() length:emailContactDetail->currentreceivedkey().length() encoding:NSUTF8StringEncoding];
//
//                    MynigmaPrivateKey* privateKey = [MynigmaPrivateKey privateKeyWithLabel:currentReceivedKeyLabel];
//
//                    if(privateKey)
//                    {
//                        [newContactDetail setCurrentReceivedDate:dateSentKey];
//                        [newContactDetail setCurrentReceivedPair:privateKey];
//                    }
//               }
//            }

            //update the number of times contacted
            //this is a little inexact - just take the maximum of the two values
            //if the same address is contacted on several devices this will almost certainly result in an underestimate
            //never mind
            NSInteger numberOfTimesContacted = emailContactDetail->numberoftimescontacted();

            if(numberOfTimesContacted > newContactDetail.numberOfTimesContacted.integerValue)
                [newContactDetail setNumberOfTimesContacted:@(numberOfTimesContacted)];


            NSInteger UNIXLastCheckedWithServer = emailContactDetail->lastcheckedwithserver();

            if(UNIXLastCheckedWithServer > 0)
            {
                NSDate* lastCheckedWithServer = [NSDate dateWithTimeIntervalSince1970:UNIXLastCheckedWithServer];

                if(!newContactDetail.lastCheckedWithServer || [lastCheckedWithServer compare:newContactDetail.lastCheckedWithServer]==NSOrderedAscending)
                {
                    [newContactDetail setLastCheckedWithServer:lastCheckedWithServer];
                }
            }

            //now update the public key for this contact
            //this doesn't necessarily happen when the public keys are processed, since the public key might not be in that list or there might already be a different public key in the store
            //in the latter case this is the correct place to update the key, since we have the last


        }

        }];
    }


    [CoreDataHelper saveWithCallback:^{

    if(callback)
        callback(importedPrivateKeys, importedPublicKeys, importedAccounts, importedContactDetails, errors);

    }];
}



@end
