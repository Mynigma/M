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
#import "EncryptionHelper.h"
#import "KeychainHelper.h"
#import "PublicKeyManager.h"
#import "IMAPAccountSetting+Category.h"
#import "AppDelegate.h"
#import "MynigmaPrivateKey+Category.h"
#import "MynigmaPublicKey+Category.h"
#import <OCMock/OCMock.h>
#import "TestHelper.h"


@interface MynigmaPublicKey()

+ (void)introducePublicKeyWithEncKeyData:(NSData*)newEncKeyData andVerKeyData:(NSData*)newVerKeyData fromEmail:(NSString*)senderEmail toEmails:(NSArray*)recipients keyLabel:(NSString*)toLabel fromKeyWithLabel:(NSString*)fromLabel;
+ (MynigmaPublicKey*)publicKeyWithLabel:(NSString*)keyLabel inContext:(NSManagedObjectContext*)keyContext;
//+ (NSArray*)dataForExistingMynigmaPublicKeyWithLabel:(NSString*)keyLabel;

@end



@interface PublicKeyManager_Tests : TestHarness

@end

@implementation PublicKeyManager_Tests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testPublicKeyExport
{
    NSString* keyLabel1 = @"3478235623784678234";
    
    NSArray* privateKeyData1 = [TestHelper privateKeySampleData:@3];
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"Wait for callback to return"];
    
    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {
        
        [MynigmaPrivateKey syncMakeNewPrivateKeyWithEncData:privateKeyData1[2] andVerKeyData:privateKeyData1[3] decKeyData:privateKeyData1[0] sigKeyData:privateKeyData1[1] forEmail:nil keyLabel:keyLabel1];
    
        NSArray* publicKeys = [MynigmaPublicKey dataForExistingMynigmaPublicKeyWithLabel:keyLabel1];
        
        XCTAssertEqualObjects(publicKeys[0], privateKeyData1[2]);
        XCTAssertEqualObjects(publicKeys[1], privateKeyData1[3]);
        
//        MynigmaPublicKey* publicKey = [
        
//        NSLog(@"----> %@", [KeychainHelper public])
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testSelfIntroduction
{
    NSString* email = @"someTestEmailAddress32423957@mynigma.org";

    NSString* keyLabel = @"someKeyLabel57483578375@mynigma.org";

    NSArray* publicKeySampleData = [TestHelper publicKeySampleData:@3];


    //mock the MynigmaPublicKey class to return sample data
    id publicKeyClassMock = OCMClassMock([MynigmaPublicKey class]);

    OCMStub([publicKeyClassMock dataForExistingMynigmaPublicKeyWithLabel:keyLabel]).andReturn(publicKeySampleData);



    NSData* introData = [PublicKeyManager introductionDataFromKeyLabel:keyLabel toKeyLabel:keyLabel];

    XCTAssertNotNil(introData);


    OCMExpect([publicKeyClassMock introducePublicKeyWithEncKeyData:publicKeySampleData[0] andVerKeyData:publicKeySampleData[1] fromEmail:email toEmails:@[@"dummyTestEmail1@myngimaUnitTests.com"] keyLabel:keyLabel fromKeyWithLabel:keyLabel]).andDo(nil);


    XCTAssertTrue([PublicKeyManager processIntroductionData:introData fromEmail:email toEmails:@[@"dummyTestEmail1@myngimaUnitTests.com"]]);

    OCMVerifyAll(publicKeyClassMock);
}


@end
