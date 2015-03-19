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
#import "TestHarness.h"
#import "OpenSSLWrapper.h"
#import <OCMock/OCMock.h>
#import "MynigmaPublicKey+Category.h"
#import "TestHelper.h"
#import "KeychainHelper.h"
#import "MynigmaFeedback.h"




@interface OpenSSLWrapper_Tests : TestHarness

@end


@implementation OpenSSLWrapper_Tests


- (void)testBasicSMIMEEncryptionAndDecryption
{
    NSData* someTestData = [@"This is some test data" dataUsingEncoding:NSUTF8StringEncoding];

    NSString* keyLabel = @"someTestKeyLabel3423532@mynigma.org";

    NSArray* publicKeySampleData = [TestHelper publicKeySampleData:@2];

    NSArray* privateKeySampleData = [TestHelper privateKeySampleData:@2];

    //mock the public key data
    id publicKeyClassMock = OCMClassMock([MynigmaPublicKey class]);
    OCMStub([publicKeyClassMock dataForExistingMynigmaPublicKeyWithLabel:keyLabel]).andReturn(publicKeySampleData);


    //mock the private key data
    id privateKeyClassMock = OCMClassMock([MynigmaPrivateKey class]);
    OCMStub([privateKeyClassMock dataForPrivateKeyWithLabel:keyLabel]).andReturn(privateKeySampleData);


    NSError* error = nil;

    NSData* encryptedData = [OpenSSLWrapper encryptData:someTestData withPublicKeyLabels:@[keyLabel] error:nil];
    XCTAssertNil(error);

    NSData* decryptedData = [OpenSSLWrapper decryptData:encryptedData withKeyLabel:keyLabel error:nil];
    XCTAssertNil(error);


    XCTAssertEqualObjects(someTestData, decryptedData);
}

- (void)testBasicSMIMESignatureAndVerification
{
    NSData* someTestData = [@"This is some test data" dataUsingEncoding:NSUTF8StringEncoding];

    NSString* keyLabel = @"someTestKeyLabel3423532@mynigma.org";

    NSArray* publicKeySampleData = [TestHelper publicKeySampleData:@2];

    NSArray* privateKeySampleData = [TestHelper privateKeySampleData:@2];


    //mock the public key data
    id publicKeyClassMock = OCMClassMock([MynigmaPublicKey class]);
    OCMStub([publicKeyClassMock dataForExistingMynigmaPublicKeyWithLabel:keyLabel]).andReturn(publicKeySampleData);

    //mock the private key data
    id privateKeyClassMock = OCMClassMock([MynigmaPrivateKey class]);
    OCMStub([privateKeyClassMock dataForPrivateKeyWithLabel:keyLabel]).andReturn(privateKeySampleData);

    NSError* error = nil;

    NSData* signedData = [OpenSSLWrapper signData:someTestData withPrivateKeyLabel:keyLabel error:&error];
    XCTAssertNil(error);

    NSData* extractedData = [OpenSSLWrapper verifySignedData:signedData withPublicKeyLabel:keyLabel error:&error];
    XCTAssertNil(error);

    XCTAssertEqualObjects(someTestData, extractedData);
}





#pragma mark - PSS padded signature & verification

- (void)testBasicSignatureAndVerificationWithPSSPadding
{
    NSData* dataToBeSigned = [TestHelper sampleData:@4];

    XCTAssert(dataToBeSigned);

    NSString* keyLabel = @"someTestKeyLabel3428578@mynigma.org";

    NSArray* publicKeySampleData = [TestHelper publicKeySampleData:@2];
    
    NSArray* privateKeySampleData = [TestHelper privateKeySampleData:@2];


    //mock the public key data
    id keychainClassMock = OCMClassMock([KeychainHelper class]);
    OCMStub([keychainClassMock dataForPublicKeychainItemWithLabel:keyLabel]).andReturn(publicKeySampleData);
    
    OCMStub([keychainClassMock dataForPrivateKeychainItemWithLabel:keyLabel]).andReturn(privateKeySampleData);


    NSData* signedData = [OpenSSLWrapper PSS_RSAsignHash:dataToBeSigned withKeyWithLabel:keyLabel withFeedback:nil];

    MynigmaFeedback* verificationResult = [OpenSSLWrapper PSS_RSAverifySignature:signedData ofHash:dataToBeSigned withKeyLabel:keyLabel];

    XCTAssert(verificationResult.isSuccess);
}

@end
