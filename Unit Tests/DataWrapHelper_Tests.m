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





#import <XCTest/XCTest.h>
#import "DeviceConnectionHelper.h"
#import "DataWrapHelper.h"
#import "TestHarness.h"
#import "EncryptionHelper.h"
#import "PublicKeyManager.h"
#import "MynigmaPublicKey+Category.h"
#import "MynigmaPrivateKey+Category.h"
#import "IMAPAccountSetting+Category.h"
#import "AppDelegate.h"
#import "KeychainHelper.h"
#import "EmailMessage+Category.h"
#import "EmailMessageData.h"
#import "EmailRecipient.h"
#import "AddressDataHelper.h"
#import "MynigmaMessage.h"
#import "NSString+EmailAddresses.h"



@interface DataWrapHelper_Tests : TestHarness

@end

@implementation DataWrapHelper_Tests

- (void)setUp
{
    [super setUp];


}

- (void)tearDown
{
/*
 bsiz = 4096;
 class = keys;
 decr = 1;
 drve = 0;
 encr = 0;
 esiz = 4096;
 kcls = 1;
 klbl = <e4916273 73cb0b84 8ef09202 fe372680 456660ab>;
 labl = "Mynigma encryption key wilhelm.schuettelspeer@gmail.com|1396781827.864806";
 perm = 1;
 sign = 0;
 type = 42;
 unwp = 0;
 vrfy = 0;
 wrap = 0;


 
 
 bsiz = 4096;
 class = keys;
 decr = 0;
 drve = 0;
 encr = 0;
 esiz = 4096;
 kcls = 1;
 klbl = <fcaa1fd3 ede84348 3f810c34 a9a91a47 da933ada>;
 labl = "Mynigma signature key wilhelm.schuettelspeer@gmail.com|1396781827.864806";
 perm = 1;
 sign = 1;
 type = 42;
 unwp = 0;
 vrfy = 0;
 wrap = 0;

 
 
 
 bsiz = 2048;
 class = keys;
 decr = 0;
 drve = 1;
 encr = 1;
 esiz = 2048;
 kcls = 0;
 klbl = <f9578e03 3c11e51e dc622abb 87fa5ec1 7344f3bb>;
 labl = "Mac App Submission: R Priebe";
 perm = 1;
 sign = 0;
 type = 42;
 unwp = 0;
 vrfy = 1;
 wrap = 0;

 
 
 */

    [super tearDown];
}

- (void)d_testWrapAndUnwrap
{
    NSData* decData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"DecKey" ofType:@"txt"]];
    NSData* sigData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"SigKey" ofType:@"txt"]];
    NSData* encData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"EncKey" ofType:@"txt"]];
    NSData* verData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"VerKey" ofType:@"txt"]];


    XCTAssertNotNil(decData1, @"Data file");
    XCTAssertNotNil(sigData1, @"Data file");
    XCTAssertNotNil(encData1, @"Data file");
    XCTAssertNotNil(verData1, @"Data file");




//    NSEntityDescription* entity = [NSEntityDescription entityForName:@"MynigmaPrivateKey" inManagedObjectContext:MAIN_CONTEXT];
//    MynigmaPrivateKey* newKeyPair = [[MynigmaPrivateKey alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];
//
//    [newKeyPair setVersion:MYNIGMA_VERSION];
//    [newKeyPair setDateCreated:[NSDate date]];
//    [newKeyPair setIsCompromised:[NSNumber numberWithBool:NO]];

    __block NSDate* currentDate = [NSDate date];

    __block NSString* keyLabel = [NSString stringWithFormat:@"%@|%f", @"wilhelm.schuettelspeer@gmail.com", [currentDate timeIntervalSince1970]];

    //[newKeyPair setKeyLabel:keyLabel];

    XCTAssertFalse([KeychainHelper havePrivateKeychainItemWithLabel:keyLabel], @"Ensuring that key isn't in keychain to begin with...");

    XCTAssertNotNil([MynigmaPrivateKey syncMakeNewPrivateKeyWithEncKeyData:encData1 andVerKeyData:verData1 decKeyData:decData1 sigKeyData:sigData1 forEmail:@"wilhelm.schuettelspeer@gmail.com" keyLabel:keyLabel inContext:MAIN_CONTEXT]);

    NSData* wrappedData = [DataWrapHelper makeAccountDataPackage];

    [MynigmaPrivateKey removePrivateKeyWithLabel:keyLabel alsoRemoveFromKeychain:YES];

        XCTAssertFalse([MynigmaPrivateKey havePrivateKeyWithLabel:keyLabel]);

    __block BOOL done = NO;

        [DataWrapHelper unwrapAccountDataPackage:wrappedData withCallback:^(NSArray* importedPrivateKeyLabels, NSArray* errorLabels){

            XCTAssertTrue([importedPrivateKeyLabels containsObject:keyLabel], @"");

            XCTAssertTrue([MynigmaPrivateKey havePrivateKeyWithLabel:keyLabel]);

            done = YES;
    }];

    [self waitForConditionToBeSatisfied:^BOOL
     {
         return done;
     } forNSeconds:10];

    XCTAssertTrue(done);
}

- (void)testCase1
{
    NSString* newMessageID = [@"mynigma@mynigma.org" generateMessageID];
    MynigmaMessage* newMessage = [MynigmaMessage findOrMakeMessageWithMessageID:newMessageID];
    
    [newMessage setDateSent:[NSDate dateWithTimeIntervalSince1970:123456]];
    
    [newMessage.messageData setSubject:@"Test subject"];
    
    [newMessage.messageData setBody:@"This is the body"];
    
    [newMessage.messageData setHtmlBody:@"<div>This is the html body</div>"];

    
    __block NSMutableArray* emailRecipients = [NSMutableArray new];
    
    EmailRecipient* recipient = [EmailRecipient new];
    [recipient setName:@"Recipient name"];
    [recipient setEmail:@"info@mynigma.org"];
    [recipient setType:TYPE_TO];
    [emailRecipients addObject:recipient];
    
    NSData* addressData = [AddressDataHelper addressDataForEmailRecipients:emailRecipients];
    
    [newMessage.messageData setAddressData:addressData];
    
    NSData* bytes = [DataWrapHelper wrapMessage:newMessage];
    
    //NSString* bytesInBase64 = [bytes base64EncodedStringWithOptions:0];
    
    MynigmaMessage* restoredMessage = [MynigmaMessage findOrMakeMessageWithMessageID:newMessageID];
    [DataWrapHelper unwrapMessageData:bytes intoMessage:restoredMessage withAttachmentHMACS:nil andFeedback:nil];
    
    // assert that original message and restored message coincide
    XCTAssertEqualObjects(newMessage, restoredMessage);
}

@end
