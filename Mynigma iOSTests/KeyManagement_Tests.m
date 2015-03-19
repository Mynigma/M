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
#import "IMAPAccountSetting+Category.h"
#import "MynigmaPrivateKey+Category.h"
#import "MynigmaPublicKey+Category.h"
#import "EncryptionHelper.h"
#import "NSData+Base64.h"
#import "PublicKeyManager.h"

@interface MynigmaPrivateKey()

@end


@interface KeyManagement_Tests : TestHarness

@end

@implementation KeyManagement_Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

//- (void)testExtraHeaderPublicKeyData
//{
//    static BOOL done = NO;
//
//    NSEntityDescription* entityDesc = [NSEntityDescription entityForName:@"IMAPAccountSetting" inManagedObjectContext:MAIN_CONTEXT];
//
//    IMAPAccountSetting* testKeySetting1 = [[IMAPAccountSetting alloc] initWithEntity:entityDesc insertIntoManagedObjectContext:MAIN_CONTEXT];
//
//    [testKeySetting1 setEmailAddress:@"someTestEmailAddress@provider.dedfsgkegjesf.com"];
//
//    NSData* encData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"EncKey" ofType:@"txt"]];
//
//    NSData* verData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"VerKey" ofType:@"txt"]];
//
//    NSData* decData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"DecKey" ofType:@"txt"]];
//
//    NSData* sigData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"SigKey" ofType:@"txt"]];
//
//    MynigmaPrivateKey* privateKey1 = [MynigmaPrivateKey privateKeyWithDecData:decData1 sigData:sigData1 encData:encData1 verData:verData1 forEmail:@"someTestEmailAddress@provider.dedfsgkegjesf.com" withLabel:@"someTestEmailAddress@provider.dedfsgkegjesf.com|213772418.903428347"];
//
//    [privateKey1 makeThisTheCurrentKey];
//
//    //[testKeySetting1 setCurrentKeyPairLabel:@"someTestEmailAddress@provider.dedfsgkegjesf.com|213772418.903428347"];
//
//    [EncryptionHelper ensureValidCurrentKeyPairForAccount:testKeySetting1 withCallback:^(BOOL success) {
//
//        XCTAssertTrue(success);
//
//        NSString* keyLabel = testKeySetting1.currentPrivateKeyLabel;
//
//        NSData* keyLabelData = [keyLabel dataUsingEncoding:NSUTF8StringEncoding];
//
//        NSString* keyLabelInBase64 = nil;
//
//        if([keyLabelData respondsToSelector:@selector(base64EncodedStringWithOptions:)])
//        {
//            //available from 10.9
//            keyLabelInBase64 = [keyLabelData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength|NSDataBase64EncodingEndLineWithCarriageReturn|NSDataBase64EncodingEndLineWithLineFeed];
//        }
//        else
//        {
//            //available from 10.6, deprecated in 10.9
//            keyLabelInBase64 = [keyLabelData base64];
//
//            //split into 64 character lines
//            NSMutableArray* chunks = [NSMutableArray new];
//
//            NSInteger index = 0;
//
//            while(index<keyLabelInBase64.length)
//            {
//                NSInteger lengthOfChunk = (index+64<keyLabelInBase64.length)?64:keyLabelInBase64.length-index;
//
//                NSString* substring = [keyLabelInBase64 substringWithRange:NSMakeRange(index, lengthOfChunk)];
//
//                [chunks addObject:substring];
//
//                index+= 64;
//            }
//
//            keyLabelInBase64 = [chunks componentsJoinedByString:@"\r\n"];
//        }
//
//
//        NSString* headerString = [PublicKeyManager headerRepresentationOfPublicKeyWithLabel:keyLabel];
//
//        [PublicKeyManager removeKeyPairWithLabel:keyLabel alsoRemoveFromKeychain:YES];
//
//        BOOL stillHaveKey = [MynigmaPublicKey publicKeyWithLabel:keyLabel forEmail:@"someTestEmailAddress@provider.dedfsgkegjesf.com" tryKeychain:NO]!=nil;
//
//        XCTAssertFalse(stillHaveKey, @"Should have deleted key");
//
//        [PublicKeyManager handleHeaderRepresentationOfPublicKey:headerString withKeyLabel:keyLabelInBase64];
//
//        BOOL nowHaveKey = [MynigmaPublicKey publicKeyWithLabel:keyLabel forEmail:@"someTestEmailAddress@provider.dedfsgkegjesf.com" tryKeychain:NO]!=nil;
//
//        XCTAssertTrue(nowHaveKey, @"Should have added key");
//        
//        done = YES;
//    }];
//    
//    [self waitForConditionToBeSatified:^BOOL
//     {
//         return done;
//     } forNSeconds:30];
//    
//    XCTAssertTrue(done, @"Should be done.");
//}
//
//
//- (void)testKeyDataImportAndExport
//{
//    NSData* decData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"DecKey" ofType:@"txt"]];
//    NSData* sigData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"SigKey" ofType:@"txt"]];
//    NSData* encData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"EncKey" ofType:@"txt"]];
//    NSData* verData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"VerKey" ofType:@"txt"]];
//
//    XCTAssertNotNil(decData1, @"Data file");
//    XCTAssertNotNil(sigData1, @"Data file");
//    XCTAssertNotNil(encData1, @"Data file");
//    XCTAssertNotNil(verData1, @"Data file");
//
//    NSString* keyLabel = [[TestHarness sharedInstance] makeNewKeyForEmail:@"someTestEmailAddress@provider.dedfsgkegjesf.com"];
//
//    NSArray* dataArray = [PublicKeyManager dataForExistingMynigmaPublicKeyWithLabel:keyLabel];
//
//    if(dataArray.count>=2)
//    {
//        NSString* result = [[NSString alloc] initWithData:dataArray[0] encoding:NSUTF8StringEncoding];
//
//        NSLog(@"Result:\n%@", result);
//
//        XCTAssertEqualObjects(dataArray[0], encData1);
//
//        XCTAssertEqualObjects(dataArray[1], verData1);
//    }
//    else
//    {
//        XCTFail(@"Not enough entries in data array!!");
//    }
//}
//
//- (void)testSelfIntroduction
//{
//    //    static BOOL done = NO;
//
//    NSString* email = @"unique.address.342785728319283@gmx.de";
//
//    NSString* keyLabel1 = [self makeNewKeyForEmail:email];
//
//    XCTAssertTrue([MynigmaPublicKey haveCurrentKeyForEmailAddress:email]);
//
//    XCTAssertNotNil([MynigmaPublicKey publicKeyWithLabel:keyLabel1 forEmail:email tryKeychain:NO]);
//
//    NSData* introData = [PublicKeyManager introductionDataFromKeyLabel:keyLabel1 toKeyLabel:keyLabel1];
//
//    XCTAssertNotNil(introData);
//
//    [PublicKeyManager removeKeyPairWithLabel:keyLabel1 alsoRemoveFromKeychain:YES];
//
//    BOOL haveKey = [MynigmaPublicKey publicKeyWithLabel:keyLabel1 forEmail:email tryKeychain:NO]!=nil;
//
//    XCTAssertFalse(haveKey);
//
//    [PublicKeyManager processIntroductionData:introData];
//
//    haveKey = [MynigmaPublicKey publicKeyWithLabel:keyLabel1 forEmail:email tryKeychain:NO]!=nil;
//
//    XCTAssertTrue(haveKey);
//
//    //    done = YES;
//    //
//    //    [self waitForConditionToBeSatified:^BOOL
//    //     {
//    //         return done;
//    //     } forNSeconds:10];
//}



@end
