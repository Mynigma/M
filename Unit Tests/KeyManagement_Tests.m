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





#import "KeyManagement_Tests.h"
#import "EncryptionHelper.h"
#import "PublicKeyManager.h"
#import "IMAPAccountSetting+Category.h"
#import "AppDelegate.h"
#import "KeychainHelper.h"
#import "MynigmaPrivateKey+Category.h"
#import "MynigmaPublicKey+Category.h"
#import "NSData+Base64.h"
#import <OCMock/OCMock.h>
#import "TestHelper.h"
#import "NSString+EmailAddresses.h"



@implementation KeyManagement_Tests


- (void)testExtraHeaderPublicKeyData
{
    NSString* keyLabel = @"someTestKeyLabel343823758@mynigma.org";

    NSString* email = @"someTestEmail37482364@mynigma.org";

    NSArray* testKeyData = [TestHelper publicKeySampleData:@1];

    NSLog(@"Test data: %@, %@", [[NSString alloc] initWithData:testKeyData[0] encoding:4], [[NSString alloc] initWithData:testKeyData[1] encoding:4]);

    id publicKeyClassMock = OCMClassMock([MynigmaPublicKey class]);

    OCMExpect([publicKeyClassMock dataForExistingMynigmaPublicKeyWithLabel:keyLabel]).andReturn(testKeyData);


    NSData* keyLabelData = [keyLabel dataUsingEncoding:NSUTF8StringEncoding];

    NSString* keyLabelInBase64 = [keyLabelData base64In64ByteChunks];

    NSString* headerString = [PublicKeyManager headerRepresentationOfPublicKeyWithLabel:keyLabel];

    OCMExpect([publicKeyClassMock syncMakeNewPublicKeyWithEncKeyData:testKeyData[0] andVerKeyData:testKeyData[1] forEmail:[email canonicalForm] keyLabel:keyLabel]);

    [PublicKeyManager handleHeaderRepresentationOfPublicKey:headerString withKeyLabel:keyLabelInBase64 fromEmail:email];

    OCMVerifyAll(publicKeyClassMock);

    [publicKeyClassMock stopMocking];
}


//- (void)testKeyDataImportAndExport
//{
////    NSData* decData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"DecKey" ofType:@"txt"]];
////    NSData* sigData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"SigKey" ofType:@"txt"]];
//    NSData* encData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"EncKey" ofType:@"txt"]];
//    NSData* verData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"VerKey" ofType:@"txt"]];
////
////    XCTAssertNotNil(decData1, @"Data file");
////    XCTAssertNotNil(sigData1, @"Data file");
////    XCTAssertNotNil(encData1, @"Data file");
////    XCTAssertNotNil(verData1, @"Data file");
//
//    NSString* keyLabel = [self keyLabel1];
//
//    NSArray* dataArray = [MynigmaPublicKey dataForExistingMynigmaPublicKeyWithLabel:keyLabel];
//
//    if(dataArray.count>=2)
//    {
//        XCTAssertEqualObjects(dataArray[0], encData1);
//        XCTAssertEqualObjects(dataArray[1], verData1);
//    }
//    else
//    {
//        XCTFail(@"Not enough entries in data array!!");
//    }
//}

@end
