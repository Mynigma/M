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
#import <OCMock/OCMock.h>
#import "MynigmaPublicKey+Category.h"
#import "TestHarness.h"
#import "KeychainHelper.h"
#import "MynigmaDevice+Category.h"
#import "TestHelper.h"
#import "NSData+Base64.h"



#define KEY_LABEL @"someTestKeyLabel"
#define SENDER_UUID @"someTestCurrentDevice6372694231"


@interface MynigmaPublicKey()

+ (MynigmaPublicKey*)syncMakeNewPublicKeyWithEncKeyData:(NSData*)encKeyData andVerKeyData:(NSData*)verKeyData forEmail:(NSString*)email keyLabel:(NSString*)keyLabel inContext:(NSManagedObjectContext*)keyContext;

@end


@interface MynigmaPublicKey_Tests : TestHarness

@end

@implementation MynigmaPublicKey_Tests

+ (void)setUp
{
    //pretend the current device has this UUID
    id keychainHelperMock = OCMClassMock([KeychainHelper class]);
    OCMExpect([keychainHelperMock fetchUUIDFromKeychain]).andReturn(SENDER_UUID);


    //make the current device
    [MynigmaDevice currentDevice];

    //create a matching sync key
    [TestHelper makeSampleDevicePublicKeyWithLabel:KEY_LABEL forDeviceUUID:SENDER_UUID];
}

- (void)testSampleKeyDataCanBeExtracted
{
    NSArray* expectedPublicKeyData = [TestHelper publicKeySampleData:@1];

    NSArray* exportedData = [MynigmaPublicKey dataForExistingMynigmaPublicKeyWithLabel:KEY_LABEL];

//    NSString* expectedString = [[NSString alloc] initWithData: expectedPublicKeyData.firstObject encoding:NSUTF8StringEncoding];
//
//    NSString* exportedString = [[NSString alloc] initWithData: exportedData.firstObject encoding:NSUTF8StringEncoding];
//
//    XCTAssertEqualObjects(expectedString, exportedString);

    XCTAssertEqualObjects(expectedPublicKeyData, exportedData);
}


//ensure firstAnchored etc. is set for newly created public keys
- (void)testThatNewPublicKeysHaveCorrectInformation
{
    //test public keys associated with an email address

    NSString* keyLabel = @"testKeyLabel34234@mynigma.org";
    NSString* emailString = @"testEmail@mynigma.org";

    [MynigmaPublicKey removePublicKeyWithLabel:keyLabel alsoRemoveFromKeychain:NO];

    XCTAssertFalse([MynigmaPublicKey havePublicKeyWithLabel:keyLabel]);
    XCTAssertFalse([MynigmaPublicKey havePublicKeyForEmailAddress:emailString]);

    NSArray* samplePublicKeyData = [TestHelper publicKeySampleData:@1];

    MynigmaPublicKey* newEmailPublicKey = [MynigmaPublicKey syncMakeNewPublicKeyWithEncKeyData:samplePublicKeyData.firstObject andVerKeyData:samplePublicKeyData.lastObject forEmail:emailString keyLabel:keyLabel inContext:MAIN_CONTEXT];

    XCTAssert(newEmailPublicKey.firstAnchored);
    XCTAssert(newEmailPublicKey.dateObtained);



    //test public keys associated with a device

    NSString* syncKeyLabel = @"someOtherTestKeyLabel32834894285@mynigma.org";

    [MynigmaPublicKey removePublicKeyWithLabel:syncKeyLabel alsoRemoveFromKeychain:NO];

    XCTAssertFalse([MynigmaPublicKey havePublicKeyWithLabel:syncKeyLabel]);

    MynigmaPublicKey* newDevicePublicKey = [MynigmaPublicKey syncMakeNewPublicKeyWithEncKeyData:samplePublicKeyData.firstObject andVerKeyData:samplePublicKeyData.lastObject forDevice:[MynigmaDevice currentDevice] keyLabel:syncKeyLabel inContext:MAIN_CONTEXT];


    XCTAssert(newDevicePublicKey.firstAnchored);
    XCTAssert(newDevicePublicKey.dateObtained);
}

- (void)testThatParsingHeaderDoesntOverwriteExistingPublicKey
{
    
}

@end
