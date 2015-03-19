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





#import "Unit_Tests.h"
#import "AppDelegate.h"
#import "EmailContactDetail+Category.h"
#import "MynigmaPublicKey+Category.h"

#import "UserSettings.h"
#import "EncryptionHelper.h"
#import "MynigmaMessage+Category.h"
#import "IMAPAccount.h"
#import "IMAPAccountSetting+Category.h"
#import "PublicKeyManager.h"
#import "Recipient.h"
#import "EmailMessageData.h"
#import "EmailMessage+Category.h"
#import "KeychainHelper.h"



@implementation Unit_Tests

- (void)timeoutAfter:(CGFloat)seconds orUntilBoolValueIsTrue:(BOOL*)value
{
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:seconds];

    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
        if([timeoutDate timeIntervalSinceNow] < 0.0)
            break;
    } while (!(*value));
}

- (void)waitForSetupToComplete
{
//    APPDELEGATE.allSetUpDone = NO;
//    [APPDELEGATE applicationDidFinishLaunching:nil];
//
//    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:10];
//
//    do {
//        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
//        if([timeoutDate timeIntervalSinceNow] < 0.0)
//            break;
//    } while (!APPDELEGATE.allSetUpDone);
}

//called before each test
- (void)setUp
{
    [super setUp];
}

//called just once per class
+ (void)setUp
{
    [super setUp];
}

- (void)waitUntilAccount:(IMAPAccountSetting*)accountSetting hasBeenVerifiedWithTimeout:(CGFloat)seconds
{
    NSDate* timeoutDate = [NSDate dateWithTimeIntervalSinceNow:seconds];

    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
        if([timeoutDate timeIntervalSinceNow] < 0.0)
            break;
    } while (!accountSetting.hasBeenVerified.boolValue);
}


- (void)testThatCoreDataStoreOpens
{
//    NSURL* url = [[AppDelegate applicationFilesDirectory] URLByAppendingPathComponent:@"MynigmaUnitTestsTemp.storedata"];
//
//    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:url.path], @"Core Data default store does not exist!");
//
//    XCTAssertNotNil([APPDELEGATE persistentStoreCoordinator], @"Couldn't open persistent store - core data model may be corrupt!!");
}





- (NSData*)makeRandomDataOfLength:(NSInteger)numberOfBytes
{
    NSMutableData* mutableData = [NSMutableData new];

    for(NSInteger byteIndex = 0; byteIndex < numberOfBytes; byteIndex++)
    {
        int randomInt = rand();
        [mutableData appendBytes:&randomInt length:1];
    }

    return mutableData;
}

//- (void)d_testMakeSessionKeys
//{
//    //creates some AES session keys
//    NSData* data1 = [[self makeRandomDataOfLength:128 / 8] base64EncodedDataWithOptions:0];
//    NSData* data2 = [[self makeRandomDataOfLength:128 / 8] base64EncodedDataWithOptions:0];
//
//    [self putData:data1 intoDesktopFile:@"AESSessionKey1.txt"];
//    [self putData:data2 intoDesktopFile:@"AESSessionKey2.txt"];
//
//    NSData* data3 = [[self makeRandomDataOfLength:128 / 8] base64EncodedDataWithOptions:0];
//
//    [self putData:data3 intoDesktopFile:@"16BytesData.txt"];
//}
//
//- (void)d_testMakeTestData
//{
//    //creates some test vectors and puts them in files on the desktop
//    NSData* data1 = [[self makeRandomDataOfLength:128] base64EncodedDataWithOptions:0];
//    NSData* data2 = [[self makeRandomDataOfLength:123] base64EncodedDataWithOptions:0];
//    NSData* data3 = [[self makeRandomDataOfLength:256] base64EncodedDataWithOptions:0];
//    NSData* data4 = [[self makeRandomDataOfLength:255] base64EncodedDataWithOptions:0];
//    NSData* data5 = [[self makeRandomDataOfLength:127] base64EncodedDataWithOptions:0];
//
//    [self putData:data1 intoDesktopFile:@"128BytesData.txt"];
//    [self putData:data2 intoDesktopFile:@"123BytesData.txt"];
//    [self putData:data3 intoDesktopFile:@"256BytesData.txt"];
//    [self putData:data4 intoDesktopFile:@"255BytesData.txt"];
//    [self putData:data5 intoDesktopFile:@"127BytesData.txt"];
//}

//case 1: no matching session key package found in encrypted data
- (void)testCase1
{
    NSURL* url = [[NSBundle bundleForClass:[NSClassFromString(@"Unit_Tests") class]] URLForResource:@"TestData1" withExtension:@"txt"];
    NSData* testData = [NSData dataWithContentsOfURL:url];

    XCTAssertNotNil(testData, @"Loading test data 1...");

    /*NSEntityDescription* entity = [NSEntityDescription entityForName:@"MynigmaMessage" inManagedObjectContext:MAIN_CONTEXT];
    MynigmaMessage* message = [[MynigmaMessage alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];

    [message setMessageid:@"unitTestMessage@mynigma.org"];

    [EncryptionHelper syncDecryptMessageForTesting:testData intoMessage:message inContext:MAIN_CONTEXT];

    XCTAssertEqualObjects(message.decryptionStatus, @"A secure connection could not be established with this contact. (Error #1)", @"Test 1 result");*/
}


//- (void)d_testTypedRecipientQuickCheck
//{
//    //make sure there is a valid account setting to check with
////    [self prepareAccounts];
//
//
//    //NOTE: this will only work if the "preferred account" (which should be "mynigmaunittests@gmail.com" after the call to prepareAccounts) is registered with the server under the key provided in the respective key data files
//
//
//    Recipient* rec = [[Recipient alloc] initWithEmail:@"edward.s@leaks.us" andName:@"Wilhelm"];
//
//    XCTAssertFalse([rec isSafe], @"Contact not safe initially");
//
//    __block BOOL finished = NO;
//    //XCTestExpectation* expectation = [self expectationWithDescription:@"finished quick check"];
//
//    //pretend that the preferred account has already been verified
//    IMAPAccountSetting* accountSetting = MODEL.currentUserSettings.preferredAccount;
//
//    [accountSetting setHasBeenVerified:@YES];
//
//    [PublicKeyManager typedRecipient:rec quickCheckWithCallback:^(BOOL success){
//
//        XCTAssertTrue(success);
////        [expectation fulfill];
//        finished = YES;
//    }];
//
//    [self timeoutAfter:100 orUntilBoolValueIsTrue:&finished];
//
////    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
////        XCTAssertNil(error);
////    }];
//
//    XCTAssertTrue([rec isSafe], @"Contact is safe after quick check");
//}

//case 2: error during decryption - no session key extractable
/*
- (void)testCase2
{
    NSData* testData = [NSData dataWithContentsOfURL:[[NSBundle bundleForClass:[NSClassFromString(@"Unit_Tests") class]] URLForResource:@"TestData2" withExtension:@"txt"]];

    XCTAssertNotNil(testData, @"Loading test data 2...");

    NSEntityDescription* entity = [NSEntityDescription entityForName:@"MynigmaMessage" inManagedObjectContext:MAIN_CONTEXT];
    MynigmaMessage* message = [[MynigmaMessage alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];

    [EncryptionHelper syncDecryptMessageForTesting:testData intoMessage:message inContext:MAIN_CONTEXT];

    XCTAssertEqualObjects(message.decryptionStatus, @"No session key could be extracted", @"Test 2 result");
}
*/

//case 2a: the extracted session key does not decrypt the message
//- (void)d_testCase2a
//{
//    NSData* testData = [NSData dataWithContentsOfURL:[[NSBundle bundleForClass:[NSClassFromString(@"Unit_Tests") class]] URLForResource:@"TestData2a" withExtension:@"txt"]];
//
//    XCTAssertNotNil(testData, @"Loading test data 2a...");
//
//    NSEntityDescription* entity = [NSEntityDescription entityForName:@"MynigmaMessage" inManagedObjectContext:MAIN_CONTEXT];
//    MynigmaMessage* message = [[MynigmaMessage alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];
//
//    [EncryptionHelper syncDecryptMessageForTesting:testData intoMessage:message inContext:MAIN_CONTEXT];
//
//    XCTAssertEqualObjects(message.decryptionStatus, @"A secure connection could not be established with this contact. (Error #1)", @"Test 2a result");
//}

/*
//case 3: signature key label not known, no valid introduction
- (void)testCase3
{
    NSData* testData = [NSData dataWithContentsOfURL:[[NSBundle bundleForClass:[NSClassFromString(@"Unit_Tests") class]] URLForResource:@"TestData1" withExtension:@"txt"]];

    XCTAssertNotNil(testData, @"Loading test data 3...");

    NSEntityDescription* entity = [NSEntityDescription entityForName:@"MynigmaMessage" inManagedObjectContext:MAIN_CONTEXT];
    MynigmaMessage* message = [[MynigmaMessage alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];

    [EncryptionHelper syncDecryptMessageForTesting:testData intoMessage:message inContext:MAIN_CONTEXT];

    XCTAssertEqualObjects(message.decryptionStatus, @"A secure connection has not yet been established with this contact.", @"Test 3 result");
}
*/

//case 4: signature key label not known, valid self-introduction
//- (void)d_testCase4
//{
//    [self waitForSetupToComplete];
//    
//    NSData* testData = [NSData dataWithContentsOfURL:[[NSBundle bundleForClass:[NSClassFromString(@"Unit_Tests") class]] URLForResource:@"TestData4" withExtension:@"txt"]];
//
//    XCTAssertNotNil(testData, @"Loading test data 4...");
//
//    NSEntityDescription* entity = [NSEntityDescription entityForName:@"MynigmaMessage" inManagedObjectContext:MAIN_CONTEXT];
//    MynigmaMessage* message = [[MynigmaMessage alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];
//
//    entity = [NSEntityDescription entityForName:@"EmailMessageData" inManagedObjectContext:MAIN_CONTEXT];
//    EmailMessageData* messageData = [[EmailMessageData alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];
//    [message setMessageData:messageData];
//
//    [EncryptionHelper syncDecryptMessageForTesting:testData intoMessage:message inContext:MAIN_CONTEXT];
//
//    XCTAssertTrue([message isDecrypted], @"Decryption successful - test case 4");
//}

/*
//case 5: signature key label known, origin: message
- (void)testCase5
{
    NSData* testData = [NSData dataWithContentsOfURL:[[NSBundle bundleForClass:[NSClassFromString(@"Unit_Tests") class]] URLForResource:@"TestData1" withExtension:@"txt"]];

    XCTAssertNotNil(testData, @"Loading test data 5...");

}

//case 6: signature key label known, origin: only server, invalid introduction
- (void)testCase6
{
    NSData* testData = [NSData dataWithContentsOfURL:[[NSBundle bundleForClass:[NSClassFromString(@"Unit_Tests") class]] URLForResource:@"TestData1" withExtension:@"txt"]];

    XCTAssertNotNil(testData, @"Loading test data 6...");

}

//case 7: signature key label known, origin: only server, valid introduction
- (void)testCase7
{
    NSData* testData = [NSData dataWithContentsOfURL:[[NSBundle bundleForClass:[NSClassFromString(@"Unit_Tests") class]] URLForResource:@"TestData1" withExtension:@"txt"]];

    XCTAssertNotNil(testData, @"Loading test data 7...");

}
*/

- (void)testAppDelegate
{
    id appDelegate = APPDELEGATE;
    XCTAssertTrue([appDelegate isKindOfClass:[AppDelegate class]],
                 @"Cannot find the application delegate.");
}

- (void)tearDown
{
    // Tear-down code here.

    [super tearDown];
}

- (void)testPublicKeychainItemsPerformance
{
    [self measureBlock:^{

        [KeychainHelper listPublicKeychainItems];
    }];
}

- (void)testPublicKeychainPropertiesPerformance
{
    [self measureBlock:^{

        [KeychainHelper listPublicKeychainProperties];
    }];
}

@end
