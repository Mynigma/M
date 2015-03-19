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
#import "AppDelegate.h"
#import "NSData+Base64.h"
#import "OpenSSLWrapper.h"
#import <OCMock/OCMock.h>
#import "TestHelper.h"
#import "MynigmaPublicKey+Category.h"





@interface SMIMEMessage_Tests : TestHarness

@end

@implementation SMIMEMessage_Tests


- (void)testVerificationOf_4_8
{
    NSURL* messageDataURL = [BUNDLE URLForResource:@"4.8" withExtension:@"eml"];

    XCTAssertNotNil(messageDataURL);

    NSData* messageDataInBase64 = [NSData dataWithContentsOfURL:messageDataURL];

    XCTAssertNotNil(messageDataInBase64);

    NSData* messageData = [NSData dataWithBase64Data:messageDataInBase64];

    XCTAssertNotNil(messageData);


    NSString* keyLabel = @"someTestKeyLabel";

    NSError* error = nil;




    NSArray* publicKeyData = [TestHelper publicKeySampleData:@2];


    id publicKeyClassMock = OCMClassMock([MynigmaPublicKey class]);

    OCMStub([publicKeyClassMock dataForExistingMynigmaPublicKeyWithLabel:keyLabel]).andReturn(publicKeyData);


    NSData* unwrappedData = [OpenSSLWrapper verifySignedData:messageData withPublicKeyLabel:keyLabel error:&error];
    

    XCTAssertNil(error);

    XCTAssertNotNil(unwrappedData);

    NSData* expectedData = nil;

    XCTAssertEqualObjects(unwrappedData, expectedData);
}



@end
