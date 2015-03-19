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





#import "KeychainHelper.h"
#import "EncryptionHelper.h"
#import "AppDelegate.h"
#import "MynigmaMessage+Category.h"
#import "EmailRecipient.h"
#import "MynigmaPublicKey+Category.h"
#import "FileAttachment+Category.h"
#import <Security/Security.h>
#import "IMAPAccount.h"
#import <MailCore/MailCore.h>
#import "IMAPFolderSetting+Category.h"
#import "IMAPAccountSetting+Category.h"
#import <XCTest/XCTest.h>
#import "TestHarness.h"
#import "NSData+Base64.h"
#import "EmailMessage+Category.h"
#import "MynigmaMessage+Category.h"
#import "EmailMessageData.h"
#import "AppleEncryptionWrapper.h"
#import "DataWrapHelper.h"
#import "AddressDataHelper.h"
#import "OpenSSLWrapper.h"
#import "AppleEncryptionWrapper.h"
#import "MynigmaFeedback.h"
#import "TestHelper.h"
#import "MynigmaPrivateKey+Category.h"

#import <OCMock/OCMock.h>



@interface Encryption_Tests : TestHarness
{
    IMAPAccountSetting* accountSetting;
}

@end


@implementation Encryption_Tests

- (void)setUp
{
    [super setUp];
    
    //testContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    //[testContext setParentContext:MAIN_CONTEXT];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    
    [super tearDown];
}

//- (MynigmaMessage*)sampleMessage
//{
//    //NSEntityDescription* entity = [NSEntityDescription entityForName:@"MynigmaMessage" inManagedObjectContext:testContext];
//    
//    MynigmaMessage* message = [MynigmaMessage findOrMakeMessageWithMessageID:[MODEL generateMessageID:@"mynigmaunittests@mynigma.org"] messageFound:nil]; //[[MynigmaMessage alloc] initWithEntity:entity insertIntoManagedObjectContext:testContext];
//    
//    __block NSMutableArray* emailRecipients = [NSMutableArray new];
//    
//    EmailRecipient* recipient = [EmailRecipient new];
//    [recipient setName:@"Mynigma info"];
//    [recipient setEmail:@"info@mynigma.org"];
//    [recipient setType:TYPE_TO];
//    [emailRecipients addObject:recipient];
//    
//    EmailRecipient* myselfFrom = [EmailRecipient new];
//    [myselfFrom setEmail:@"someEmail@ddress.com"];
//    [myselfFrom setName:@"The sender"];
//    [myselfFrom setType:TYPE_FROM];
//    [emailRecipients addObject:myselfFrom];
//    
//    EmailRecipient* replyTo = [EmailRecipient new];
//    [replyTo setEmail:@"SomeReplyToAddress@yahoo.com"];
//    [replyTo setName:@"Reply to this address please"];
//    [replyTo setType:TYPE_REPLY_TO];
//    [emailRecipients addObject:replyTo];
//    
//    EmailRecipient* ccRecipient = [EmailRecipient new];
//    [ccRecipient setEmail:@"The_CC@Recipient.com"];
//    [ccRecipient setName:@"The CC Recipient"];
//    [ccRecipient setType:TYPE_CC];
//    [emailRecipients addObject:ccRecipient];
//
//    /*
//    EmailRecipient* bccRecipient = [EmailRecipient new];
//    [bccRecipient setEmail:@"The_BCC@Recipient.com"];
//    [bccRecipient setName:@"The BCC Recipient"];
//    [bccRecipient setType:TYPE_BCC];
//    [emailRecipients addObject:bccRecipient];
//    */
//    
//    NSMutableData* addressData = [NSMutableData new];
//    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:addressData];
//    [archiver encodeObject:emailRecipients forKey:@"recipients"];
//    [archiver finishEncoding];
//    
//    [message.messageData setAddressData:addressData];
//
//    [message.messageData setFromName:myselfFrom.name];
//    
//    [message setDateSent:[NSDate dateWithTimeIntervalSince1970:123456]];
//    
//    [message.messageData setSubject:@"Test subject"];
//    
//    [message.messageData setBody:@"This is the body"];
//    
//    [message.messageData setHtmlBody:@"<div>This is the html body</div>"];
//
//
//    NSEntityDescription* entity = [NSEntityDescription entityForName:@"FileAttachment" inManagedObjectContext:MAIN_CONTEXT];
//    
//    FileAttachment* newAttachment = [[FileAttachment alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];
//    
//    [newAttachment setAttachedToMessage:message];
//
//    [newAttachment setAttachedAllToMessage:message];
//    
//    [newAttachment saveDataToPrivateURL:[NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[Encryption_Tests class]] pathForResource:@"Attachment1" ofType:@"png"]]];
//    
//    [newAttachment setFileName:@"Attachment1.png"];
//    
//    [newAttachment setContentid:@"someContentID238424383@mynigma.org"];
//    
//    FileAttachment* secondAttachment = [[FileAttachment alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];
//    
//    [secondAttachment setAttachedToMessage:message];
//
//    [secondAttachment setAttachedAllToMessage:message];
//    
//    [secondAttachment saveDataToPrivateURL:[NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"CV Roman Priebe" ofType:@"pdf"]]];
//    
//    [secondAttachment setFileName:@"CV Roman Priebe.pdf"];
//    
//    [secondAttachment setContentid:@"346ry7eyf7wyr37y8y2r83yr8@mynigma.org"];
//    
//    return message;
//}




- (void)checkDecryptedSampleMessage:(MynigmaMessage*)decryptedMessage
{
    MynigmaMessage* originalMessage = [self sampleEmailMessage];
    
    XCTAssertEqualObjects(originalMessage.messageData.addressData, decryptedMessage.messageData.addressData);

/*
    NSKeyedUnarchiver* keyedUnarchiver1 = [[NSKeyedUnarchiver alloc] initForReadingWithData:originalMessage.addressData];
    NSKeyedUnarchiver* keyedUnarchiver2 = [[NSKeyedUnarchiver  alloc] initForReadingWithData:decryptedMessage.addressData];

    NSLog(@"%@ vs. %@", [keyedUnarchiver1 decodeObjectForKey:@"recipients"], [keyedUnarchiver2 decodeObjectForKey:@"recipients"]);


    [keyedUnarchiver1 finishDecoding];
    [keyedUnarchiver2 finishDecoding];
*/
    
    XCTAssertEqualObjects(originalMessage.messageData.body, decryptedMessage.messageData.body);
    XCTAssertEqualObjects(originalMessage.dateSent, decryptedMessage.dateSent);
    XCTAssertEqualObjects(originalMessage.messageData.fromName, decryptedMessage.messageData.fromName);
    XCTAssertEqualObjects(originalMessage.messageData.htmlBody, decryptedMessage.messageData.htmlBody);
    
    XCTAssertEqual(originalMessage.attachments.count, decryptedMessage.attachments.count);
    XCTAssertEqual(originalMessage.allAttachments.count, decryptedMessage.allAttachments.count);
    
    NSArray* decryptedContentIDs = [[decryptedMessage.allAttachments sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"contentid" ascending:YES]]] valueForKey:@"contentid"];
    
    for(FileAttachment* fileAttachment in [originalMessage.allAttachments sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"contentid" ascending:YES]]])
    {
        NSInteger indexOfDecryptedAttachment = [decryptedContentIDs indexOfObject:fileAttachment.contentid];
        
        if(indexOfDecryptedAttachment!=NSNotFound)
        {
            FileAttachment* decryptedAttachment = [[decryptedMessage.allAttachments sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"contentid" ascending:YES]]] objectAtIndex:indexOfDecryptedAttachment];
            
            XCTAssertNotNil(decryptedAttachment);
            
            XCTAssertEqualObjects(fileAttachment.data, decryptedAttachment.data);
            
            XCTAssertEqualObjects(fileAttachment.fileName, decryptedAttachment.fileName);
        }
        else
            XCTFail();
    }
}

- (void)testMarcoPSS
{
    NSString* keyLabel1 = @"testKey_dshifhdiuztjhrbrb";

    NSArray* privateKeyData1 = [TestHelper privateKeySampleData:@1];
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"Wait for encryption and decryption to finish"];
    
    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {
        
        [MynigmaPrivateKey syncMakeNewPrivateKeyWithEncData:privateKeyData1[2] andVerKeyData:privateKeyData1[3] decKeyData:privateKeyData1[0] sigKeyData:privateKeyData1[1] forEmail:nil keyLabel:keyLabel1];
        
        NSData* hash = [TestHelper sampleData:@1];
        
        NSData* result = [OpenSSLWrapper PSS_RSAsignHash:hash withKeyWithLabel:keyLabel1 withFeedback:nil];
        
        result = [result base64EncodedDataWithOptions:0];
        
        [TestHelper putData:result intoDesktopFile:@"MarcoPSS.txt"];
        [expectation fulfill];
        NSLog(@"%@", hash);
    }];

    [self waitForExpectationsWithTimeout:20 handler:nil];
}


- (void)testEncryptionAndDecryption
{
    MynigmaMessage* sampleMessage = [self sampleEmailMessage];

    NSString* keyLabel1 = @"testKey_dshifhdifdefesxcsdv";
    NSString* keyLabel2 = @"testKey_dhwfi3jd2ompks2dvsdva";
    NSString* keyLabel3 = @"testKey_dihpx21udoo12hdsjadvd";
//    NSString* keyLabel4 = @"testKey_gydweduqwbiudq";
    
    
    NSArray* encryptionKeyLabels = @[keyLabel1, keyLabel3];
    NSArray* expectedSignatureKeyLabels = @[keyLabel1, keyLabel2];

    id publicKeyClassMock = OCMClassMock([MynigmaPublicKey class]);
    
    OCMStub([publicKeyClassMock encryptionKeyLabelsForRecipients:[OCMArg any] allowErrors:NO]).andReturn(encryptionKeyLabels);
    
    OCMStub([publicKeyClassMock introductionOriginKeyLabelsForRecipients:[OCMArg any] allowErrors:NO]).andReturn(expectedSignatureKeyLabels);
    
    
    id privateKeyClassMock = OCMClassMock([MynigmaPrivateKey class]);
    
    OCMStub([privateKeyClassMock senderKeyLabelForMessage:[OCMArg any]]).andReturn(keyLabel1);
    
    NSArray* privateKeyData1 = [TestHelper privateKeySampleData:@1];
    NSArray* privateKeyData2 = [TestHelper privateKeySampleData:@2];
    NSArray* privateKeyData3 = [TestHelper privateKeySampleData:@3];
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"Wait for encryption and decryption to finish"];

    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

        [MynigmaPrivateKey syncMakeNewPrivateKeyWithEncData:privateKeyData1[2] andVerKeyData:privateKeyData1[3] decKeyData:privateKeyData1[0] sigKeyData:privateKeyData1[1] forEmail:nil keyLabel:keyLabel1];
     
        [MynigmaPrivateKey syncMakeNewPrivateKeyWithEncData:privateKeyData2[2] andVerKeyData:privateKeyData2[3] decKeyData:privateKeyData2[0] sigKeyData:privateKeyData2[1] forEmail:nil keyLabel:keyLabel2];

        [MynigmaPrivateKey syncMakeNewPrivateKeyWithEncData:privateKeyData3[2] andVerKeyData:privateKeyData3[3] decKeyData:privateKeyData3[0] sigKeyData:privateKeyData3[1] forEmail:nil keyLabel:keyLabel3];
    
    
    [sampleMessage encryptForSendingInContext:localContext withCallback:^(MynigmaFeedback *feedback) {
        
        XCTAssertTrue(feedback.isSuccess);
        
        //set some attributes to nil just to be sure that the encryption/decryption doesn't simply leave the message untouched
        [sampleMessage.messageData setHtmlBody:nil];
        [sampleMessage.messageData setBody:nil];
        [sampleMessage.messageData setAddressData:nil];
        [sampleMessage setAttachments:[NSSet new]];
        
        [EncryptionHelper asyncDecryptMessage:sampleMessage.objectID fromData:sampleMessage.mynData withCallback:^(MynigmaFeedback* decryptionError){
        
        XCTAssertTrue(decryptionError.isSuccess);
        
        [self checkDecryptedSampleMessage:sampleMessage];

        XCTAssertNotNil(sampleMessage);
            
            [expectation fulfill];
        }];
    }];
    
    }];
    
    [self waitForExpectationsWithTimeout:60*2 handler:nil];
}


- (void)testManagedObjectContext
{
    XCTAssertNotNil(MAIN_CONTEXT);
    //STAssertNotNil(testContext.parentContext, nil);
}

//- (void)testCompleteEncryptionAndDecryption
//{
//    [MAIN_CONTEXT performBlockAndWait:^{
//        MynigmaMessage* sampleMessage = [self sampleMessage];
//        
//        BOOL encryptionResult = [EncryptionHelper syncEncryptMessageForTesting:sampleMessage withSignatureKeyLabel:@"1" andEncryptionKeys:@[@"5", @"2", @"1", @"3", @"4"] inContext:MAIN_CONTEXT];
//        XCTAssertTrue(encryptionResult);
//        
//        NSArray* MCOMessages = [IMAPAccount MCOMessagesForEmailMessage:sampleMessage];
//        XCTAssertTrue(MCOMessages.count == 1);
//        
//        //set some attributes to nil just to be sure that the encryption/decryption doesn't simply leave the message untouched
//        [sampleMessage setHtmlBody:nil];
//        [sampleMessage setBody:nil];
//        [sampleMessage setAddressData:nil];
//
//        //NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:sampleMessage.attachments];
//        //[tempSet addObject:value];
//        //sampleMessage.attachments = [NSOrderedSet new];
//
//        /*for(FileAttachment* fileAttachment in sampleMessage.attachments)
//        {
//            [fileAttachment setData:nil];
//        }*/
//
//        //[testContext deleteObject:sampleMessage];
//
//        
//
//        NSData* messageData = [MCOMessages objectAtIndex:0];
//        
//        MCOMessageParser* parser = [[MCOMessageParser alloc] initWithData:messageData];
//        
//        NSArray* attachments = parser.attachments;
//
//
//        //NSEntityDescription* entity = [NSEntityDescription entityForName:@"MynigmaMessage" inManagedObjectContext:testContext];
//
//        //MynigmaMessage* message = [[MynigmaMessage alloc] initWithEntity:entity insertIntoManagedObjectContext:testContext];
//
//        MynigmaMessage* message = (MynigmaMessage*)[MODEL findOrMakeMessageWithMessageID:[MODEL generateMessageID:@"mynigmaunittests.org"] inContext:MAIN_CONTEXT isSafe:YES messageFound:nil]; //[[MynigmaMessage alloc] initWithEntity:entity insertIntoManagedObjectContext:testContext];
//
//       [IMAPAccount populateMessage:message withCoreMessage:parser inFolder:nil andContext:MAIN_CONTEXT];
//
//        //when the message arrives the encrypted data will be put into the encryptedData properties (rather than the data ones)
//
//
//        //STAssertTrue(attachments.count == sampleMessage.attachments.count+1, nil);
//
//        BOOL mynAttachmentFound = NO;
//
//        NSData* mynData = nil;
//
//        for(MCOAttachment* attachment in attachments)
//        {
//            if([attachment.filename isEqualToString:@"Secure message.myn"])
//            {
//                mynData = attachment.data;
//                mynAttachmentFound = YES;
//            }
//        }
//        
//        XCTAssertTrue(mynAttachmentFound);
//
//        [message setMynData:mynData];
//
//        IMAPAccount* account = [MODEL accountForSettingID:message.inFolder.inIMAPAccount.objectID];
//
//        [account attemptDecryptionOfMynigmaMessage:message inContext:MAIN_CONTEXT];
//
//        [self checkDecryptedSampleMessage:message];
//
//        NSLog(@"Encryption test done");
//    }];
//}

- (void)d_testOpenSSLKeyGeneration
{
    __block BOOL doneGeneratingOpenSSLKey = NO;
    
    [self measureBlock:^{
       
        [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {
            
        [OpenSSLWrapper generateNewPrivateKeyPairWithKeyLabel:@"testLabel34234234" withCallback:^(NSString *keyLabel, NSData *encPersRef, NSData *verPersRef, NSData *decPersRef, NSData *sigPersRef) {
           
            doneGeneratingOpenSSLKey =  YES;
        
            }];
        }];
    }];
    
    [self waitForConditionToBeSatisfied:^{ return doneGeneratingOpenSSLKey; } forNSeconds:120];
}

-(void)d_testAppleKeyGeneration
{
    __block BOOL doneGeneratingAppleKey = NO;
    
    [self measureBlock:^{
        
        [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {
            
        [AppleEncryptionWrapper generateNewPrivateKeyPairWithKeyLabel:@"testLabel34234234" withCallback:^(NSString *keyLabel, NSData *encPersRef, NSData *verPersRef, NSData *decPersRef, NSData *sigPersRef) {
            
            doneGeneratingAppleKey = YES;
        }];
            
        }];
    }];
    
    [self waitForConditionToBeSatisfied:^{ return doneGeneratingAppleKey; } forNSeconds:120];
}


- (void)testKomsatIPhoneKey
{
    __block NSDate* currentDate = [NSDate date];

    __block NSString* keyLabel = [NSString stringWithFormat:@"%@|%f", @"wilhelm.schuettel.speer@gmail.com", [currentDate timeIntervalSince1970]];

    NSURL* verDataURL = [BUNDLE URLForResource:@"verTestDataKomsat_iPhone" withExtension:@"txt"];
    NSData* verData = [NSData dataWithContentsOfURL:verDataURL];
    XCTAssertNotNil(verData);

    NSURL* encDataURL = [BUNDLE URLForResource:@"encTestDataKomsat_iPhone" withExtension:@"txt"];
    NSData* encData = [NSData dataWithContentsOfURL:encDataURL];
    XCTAssertNotNil(encData);


    NSString* senderEmailString = @"wilhelm.schuettel.speer@gmail.com";



    NSString* base64edEncKeyData = [[NSString alloc] initWithData:encData encoding:NSUTF8StringEncoding];

    NSString* base64edVerKeyData = [[NSString alloc] initWithData:verData encoding:NSUTF8StringEncoding];


    NSString* completeEncString = [NSString stringWithFormat:@"MIICIjANBgkqhkiG9w0BAQEFAAOCAg8A%@", base64edEncKeyData];


    NSString* completeVerString = [NSString stringWithFormat:@"MIICIjANBgkqhkiG9w0BAQEFAAOCAg8A%@", base64edVerKeyData];

    //split into 64 character lines
    NSMutableArray* chunks = [NSMutableArray new];

    NSInteger index = 0;

    while(index<completeEncString.length)
    {
        NSInteger lengthOfChunk = (index+64<completeEncString.length)?64:completeEncString.length-index;

        NSString* substring = [completeEncString substringWithRange:NSMakeRange(index, lengthOfChunk)];

        [chunks addObject:substring];

        index+= 64;
    }

    NSString* joinedEncString = [chunks componentsJoinedByString:@"\n"];

    NSString* armouredEncDataString = [NSString stringWithFormat:@"-----BEGIN RSA PUBLIC KEY-----\n%@\n-----END RSA PUBLIC KEY-----\n", joinedEncString];

    chunks = [NSMutableArray new];

    index = 0;

    while(index<completeVerString.length)
    {
        NSInteger lengthOfChunk = (index+64<completeVerString.length)?64:completeVerString.length-index;

        NSString* substring = [completeVerString substringWithRange:NSMakeRange(index, lengthOfChunk)];

        [chunks addObject:substring];

        index+= 64;
    }


    NSString* joinedVerString = [chunks componentsJoinedByString:@"\n"];

    NSString* armouredVerDataString = [NSString stringWithFormat:@"-----BEGIN RSA PUBLIC KEY-----\n%@\n-----END RSA PUBLIC KEY-----\n", joinedVerString];
    
    encData = [armouredEncDataString dataUsingEncoding:NSUTF8StringEncoding];

    verData = [armouredVerDataString dataUsingEncoding:NSUTF8StringEncoding];

    [MynigmaPublicKey syncMakeNewPublicKeyWithEncKeyData:encData andVerKeyData:verData forEmail:senderEmailString keyLabel:keyLabel];


    XCTAssert([MynigmaPublicKey havePublicKeyForEmailAddress:senderEmailString]);

    XCTAssert([MynigmaPublicKey havePublicKeyWithLabel:keyLabel]);
}


#pragma mark - Encryption Tests as on Windows

//- (void)testRSAEncryption
//{
//    NSData* inputData = [self readBase64DataFromFile:@"108BytesData" extension:@"txt"];
//
//    XCTAssertNotNil(inputData);
//
//    NSData* encryptedData = [AppleEncryptionWrapper RSAencryptData:inputData withPublicKeyLabel:@"UnitTestKey"];
//
//    NSData* decryptedData = [AppleEncryptionWrapper RSAdecryptData:encryptedData withPrivateKeyLabel:@"UnitTestKey"];
//
//    XCTAssertEqualObjects(inputData, decryptedData);
//}
//
//- (void)testRSAEncryptionFromWindows
//{
//    NSData* inputData = [self readBase64DataFromFile:@"108BytesData" extension:@"txt"];
//
//    XCTAssertNotNil(inputData);
//
//    NSData* encryptedData = [self readBase64DataFromFile:@"WindowsRSAEncrypted108BytesData" extension:@"txt"];
//
//    NSData* decryptedData = [AppleEncryptionWrapper RSAdecryptData:encryptedData withPrivateKeyLabel:@"UnitTestKey"];
//
//    XCTAssertEqualObjects(inputData, decryptedData);
//}

//- (void)testRSASignature
//{
//    //input is already a SHA512 hash of some data
//    NSData* inputData = [self readBase64DataFromFile:@"SHA512DigestOf255BytesData" extension:@"txt"];
//
//    XCTAssertNotNil(inputData);
//
//    NSData* signedData = [AppleEncryptionWrapper RSASignHash:inputData withKeyLabel:@"UnitTestKey"];
//
//    BOOL verificationSuccessful = [AppleEncryptionWrapper RSAverifySignature:signedData ofHash:inputData withKeyLabel:@"UnitTestKey"];
//
//    XCTAssertTrue(verificationSuccessful);
//
//    NSData* windowsSignedData = [self readBase64DataFromFile:@"RSASignedSHA512DigestOf255BytesData" extension:@"txt"];
//
//    XCTAssertEqualObjects(signedData, windowsSignedData);
//
////    verificationSuccessful = [AppleEncryptionWrapper RSAverifySignature:windowsSignedData ofHash:inputData withKeyLabel:@"UnitTestKey"];
////
////    XCTAssertTrue(verificationSuccessful);
//}


//- (void)testSHA512DigestOn255BytesData
//{
//    NSData* inputData = [self readBase64DataFromFile:@"255BytesData" extension:@"txt"];
//
//    XCTAssertNotNil(inputData);
//    
//    NSData* hashedData = [AppleEncryptionWrapper SHA512DigestOfData:inputData];
//
//    XCTAssertNotNil(hashedData);
//
//    NSData* windowsHashedData = [self readBase64DataFromFile:@"SHA512DigestOf255BytesData" extension:@"txt"];
//
//    XCTAssertEqualObjects(hashedData, windowsHashedData);
//}
//
//- (void)testSHA512DigestOn108BytesData
//{
//    NSData* inputData = [self readBase64DataFromFile:@"108BytesData" extension:@"txt"];
//
//    XCTAssertNotNil(inputData);
//
//    NSData* hashedData = [AppleEncryptionWrapper SHA512DigestOfData:inputData];
//
//    XCTAssertNotNil(hashedData);
//
//    NSData* windowsHashedData = [self readBase64DataFromFile:@"SHA512DigestOf108BytesData" extension:@"txt"];
//
//    XCTAssertEqualObjects(hashedData, windowsHashedData);
//}

//- (void)testAESEncryptionOn127BytesData
//{
//    NSData* inputData = [self readBase64DataFromFile:@"127BytesData" extension:@"txt"];
//
//    XCTAssertNotNil(inputData);
//
//    NSData* sessionKey1 = [self readBase64DataFromFile:@"AESSessionKey1" extension:@"txt"];
//
//    XCTAssertNotNil(sessionKey1);
//
//    NSData* IV = [self readBase64DataFromFile:@"16BytesData" extension:@"txt"];
//
//    NSData* AESEncryptedData = [AppleEncryptionWrapper AESencryptData:inputData withSessionKeyData:sessionKey1 IV:IV];
//
//    XCTAssertNotNil(AESEncryptedData);
//
//    [self putData:[AESEncryptedData base64EncodedDataWithOptions:0] intoDesktopFile:@"AESEncrypted127BytesData.txt"];
//
////    NSData* correctData = [self readBase64DataFromFile:@"AESEncrypted127BytesData" extension:@"txt"];
////
////    XCTAssertEqualObjects(AESEncryptedData, correctData);
//}
//
//- (void)testAESEncryptionOn128BytesData
//{
//    NSData* inputData = [self readBase64DataFromFile:@"128BytesData" extension:@"txt"];
//
//    XCTAssertNotNil(inputData);
//
//    NSData* sessionKey1 = [self readBase64DataFromFile:@"AESSessionKey1" extension:@"txt"];
//
//    XCTAssertNotNil(sessionKey1);
//
//    NSData* IV = [self readBase64DataFromFile:@"16BytesData" extension:@"txt"];
//
//    NSData* AESEncryptedData = [AppleEncryptionWrapper AESencryptData:inputData withSessionKeyData:sessionKey1 IV:IV];
//
//    XCTAssertNotNil(AESEncryptedData);
//
//    [self putData:[AESEncryptedData base64EncodedDataWithOptions:0] intoDesktopFile:@"AESEncrypted128BytesData.txt"];
//
////    NSData* correctData = [self readBase64DataFromFile:@"AESEncrypted128BytesData" extension:@"txt"];
////
////    XCTAssertEqualObjects(AESEncryptedData, correctData);
//}

//- (void)testWrapSignedData
//{
//    NSData* inputData = [self readBase64DataFromFile:@"SHA512DigestOf255BytesData" extension:@"txt"];
//
//    XCTAssertNotNil(inputData);
//
//    NSData* signature = [self readBase64DataFromFile:@"RSASignedSHA512DigestOf255BytesData" extension:@"txt"];
//
//    XCTAssertNotNil(signature);
//
//    NSString* keyLabel = @"UnitTestKey";
//    NSString* version = @"2.03.19";
//
//    NSData* wrappedData = [DataWrapHelper wrapSignedData:inputData signedDataBlob:signature keyLabel:keyLabel version:version];
//
//    XCTAssertNotNil(wrappedData);
//
////    [self putData:[wrappedData base64EncodedDataWithOptions:0] intoDesktopFile:@"wrappedSignedData.txt"];
//
//    NSData* correctWrappedSignedData = [self readBase64DataFromFile:@"wrappedSignedData" extension:@"txt"];
//
//    XCTAssertEqualObjects(wrappedData, correctWrappedSignedData);
//}

- (MynigmaMessage*)sampleEmailMessage
{
    MynigmaMessage* newMessage = [MynigmaMessage findOrMakeMessageWithMessageID:@"newUnitTestMessage_testEncryptMessage@mynigma.org" messageFound:nil];

    [newMessage.messageData setBody:@"This is the body"];
    [newMessage.messageData setHtmlBody:@"<html>This is the html body</html>"];
    [newMessage.messageData setSubject:@"This is the subject"];

    EmailRecipient* toRecipient = [EmailRecipient new];
    [toRecipient setEmail:@"TYPE_TO@example.com"];
    [toRecipient setType:TYPE_TO];

    EmailRecipient* ccRecipient = [EmailRecipient new];
    [ccRecipient setEmail:@"TYPE_CC@example.com"];
    [ccRecipient setType:TYPE_CC];

    NSData* addressData = [AddressDataHelper addressDataForEmailRecipients:@[toRecipient, ccRecipient]];

    [newMessage.messageData setAddressData:addressData];

    [newMessage setDateSent:[NSDate dateWithTimeIntervalSince1970:0]];

    return newMessage;
}

//- (void)testWrapPayloadPart
//{
//    MynigmaMessage* message = [self sampleEmailMessage];
//
//    NSData* wrappedMessage = [DataWrapHelper wrapMessage:message];
//
//    [self putData:[wrappedMessage base64EncodedDataWithOptions:0] intoDesktopFile:@"wrappedMessageData.txt"];
//}
//
//- (void)testEncryptMessage
//{
//    
//}
//
//- (void)d_testPutRandomDataOnDesktop
//{
//    for(NSInteger index = 0; index < 5; index++)
//    {
//        NSData* randomData = [AppleEncryptionWrapper randomBytesOfLength:256];
//
//    NSData* base64Data = [randomData base64EncodedDataWithOptions:0];
//
//    [self putData:base64Data intoDesktopFile:[NSString stringWithFormat:@"Sample_Data%ld.txt", index]];
//    }
//}

@end
