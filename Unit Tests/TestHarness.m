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





#import "TestHarness.h"
#import "IMAPAccountSetting+Category.h"
#import "AppDelegate.h"
#import "IMAPAccount.h"
#import "AccountCreationManager.h"
#import "MynigmaPrivateKey+Category.h"
#import "EmailContactDetail+Category.h"
#import "KeychainHelper.h"
#import "MynigmaPublicKey+Category.h"

#import "NSData+Base64.h"
#import "UserSettings.h"
#import <OCMock/OCMock.h>


@interface MynigmaPrivateKey()

+ (MynigmaPrivateKey*)syncMakeNewPrivateKeyWithEncKeyData:(NSData*)encData andVerKeyData:(NSData*)verData decKeyData:(NSData*)decData sigKeyData:(NSData*)sigData forEmail:(NSString*)email keyLabel:(NSString*)keyLabel inContext:(NSManagedObjectContext*)keyContext;

@end

//these hold the standard accounts - only set up once and shared between all tests
static IMAPAccountSetting* accountSetting1;
static IMAPAccountSetting* accountSetting2;
static IMAPAccount* account1;
static IMAPAccount* account2;


@implementation TestHarness

#pragma mark - WAITING FOR CONDITIONS

//wait for ten seconds or until the condition is satisfied
- (void)waitForConditionToBeSatisfied:(BOOL(^)())conditionBlock
{
    [self waitForConditionToBeSatisfied:conditionBlock forNSeconds:10];
}

//wait for n seconds or until the condition is satisfied
- (void)waitForConditionToBeSatisfied:(BOOL(^)())conditionBlock forNSeconds:(NSInteger)seconds
{
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:seconds];

    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
        if([timeoutDate timeIntervalSinceNow] < 0.0)
            break;
    } while (!conditionBlock());

    XCTAssertTrue(conditionBlock(), @"Condition failed to become true before timeout occurred (TestHarness)");
}


#pragma mark - ACCOUNTS SETUP

+ (void)prepareTestData
{
    if(account1)
    {
        //already initialised
        //TO DO: perhaps clean up the accounts and account settings to ensure that tests do not interfere with each other
        return;
    }

    NSString* email1 = @"mynigmaunittests1@gmail.com";
    NSString* email2 = @"mynigmaunittests2@gmail.com";
//    NSString* email3 = @"mynigmaunittests3@gmail.com";

    account1 = [AccountCreationManager temporaryAccountWithEmail:email1];

    [account1.quickAccessSession setPassword:@"; DROP TABLE PASSWORDS2"];
    [account1.smtpSession setPassword:@"; DROP TABLE PASSWORDS2"];
    [AccountCreationManager makeAccountPermanent:account1];

    //_imapSesionMock = [IMAPSessionMock new];

    NSError* error = nil;
    accountSetting1 = (IMAPAccountSetting*)[MAIN_CONTEXT existingObjectWithID:account1.accountSettingID error:&error];
//    XCTAssertNil(error);

    NSData* decData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"DecKey" ofType:@"txt"]];
    NSData* sigData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"SigKey" ofType:@"txt"]];
    NSData* encData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"EncKey" ofType:@"txt"]];
    NSData* verData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"VerKey" ofType:@"txt"]];


//    XCTAssertNotNil(decData1, @"Data file");
//    XCTAssertNotNil(sigData1, @"Data file");
//    XCTAssertNotNil(encData1, @"Data file");
//    XCTAssertNotNil(verData1, @"Data file");
//

    NSString* keyLabel1 = @"unitTestKey1";

    MynigmaPrivateKey* privateKey = [MynigmaPrivateKey syncMakeNewPrivateKeyWithEncKeyData:encData1 andVerKeyData:verData1 decKeyData:decData1 sigKeyData:sigData1 forEmail:email1 keyLabel:keyLabel1 inContext:MAIN_CONTEXT];


    //IMAPAccountSetting* accountSetting = MODEL.currentUserSettings.preferredAccount;


    account2 = [IMAPAccount new];

    account2 = [AccountCreationManager temporaryAccountWithEmail:email2];
    [account2.quickAccessSession setPassword:@"speerschuettel1"];
    [account2.smtpSession setPassword:@"speerschuettel1"];
    [AccountCreationManager makeAccountPermanent:account2];

    error = nil;
    accountSetting2 = (IMAPAccountSetting*)[MAIN_CONTEXT existingObjectWithID:account2.accountSettingID error:&error];


    NSData* decData2 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"DecKey2" ofType:@"txt"]];
    NSData* sigData2 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"SigKey2" ofType:@"txt"]];
    NSData* encData2 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"EncKey2" ofType:@"txt"]];
    NSData* verData2 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"VerKey2" ofType:@"txt"]];

    NSString* keyLabel2 = @"unitTestKey2";

    privateKey = [MynigmaPrivateKey syncMakeNewPrivateKeyWithEncKeyData:encData2 andVerKeyData:verData2 decKeyData:decData2 sigKeyData:sigData2 forEmail:email2 keyLabel:keyLabel2 inContext:MAIN_CONTEXT];


    NSData* decData3 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"UnitTestKey_Dec" ofType:@"txt"]];
    NSData* sigData3 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"UnitTestKey_Sig" ofType:@"txt"]];
    NSData* encData3 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"UnitTestKey_Enc" ofType:@"txt"]];
    NSData* verData3 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"UnitTestKey_Ver" ofType:@"txt"]];


    __block NSString* keyLabel = @"UnitTestKey";

    [MynigmaPrivateKey syncMakeNewPrivateKeyWithEncKeyData:encData3 andVerKeyData:verData3 decKeyData:decData3 sigKeyData:sigData3 forEmail:email2 keyLabel:keyLabel inContext:MAIN_CONTEXT];


//    XCTAssertNil(error);
}


- (IMAPAccount*)account1
{
    return account1;
}

- (IMAPAccount*)account2
{
    return account2;
}

- (IMAPAccountSetting*)accountSetting1
{
    return accountSetting1;
}

- (IMAPAccountSetting*)accountSetting2
{
    return accountSetting2;
}

- (NSString*)keyLabel1
{
    return @"unitTestKey1";
}

- (NSString*)keyLabel2
{
    return @"unitTestKey2";
}


#pragma mark - KEY SETUP

- (NSString*)makeNewKeyForEmail:(NSString*)email
{
    NSData* decData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"DecKey" ofType:@"txt"]];
    NSData* sigData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"SigKey" ofType:@"txt"]];
    NSData* encData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"EncKey" ofType:@"txt"]];
    NSData* verData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"VerKey" ofType:@"txt"]];


    XCTAssertNotNil(decData1, @"Data file");
    XCTAssertNotNil(sigData1, @"Data file");
    XCTAssertNotNil(encData1, @"Data file");
    XCTAssertNotNil(verData1, @"Data file");


    __block NSDate* currentDate = [NSDate date];

    __block NSString* keyLabel = [NSString stringWithFormat:@"%@|%f", email, [currentDate timeIntervalSince1970]];

    [MynigmaPrivateKey syncMakeNewPrivateKeyWithEncKeyData:encData1 andVerKeyData:verData1 decKeyData:decData1 sigKeyData:sigData1 forEmail:email keyLabel:keyLabel inContext:MAIN_CONTEXT];

    //[KeychainHelper addPrivateKeyToKeychainWithEncData:encData1 verData:verData1 decData:decData1 sigData:sigData1 andPrivateKey:newKeyPair];
    
    
    return keyLabel;
}


#pragma mark - CLASS SETUP

////set up - this is called once per subclass
+ (void)setUp
{
    [super setUp];

    //mocj the CoreDataHelper to ensure the unit tests data store is used instead of the usual one
    id coreDataHelperMock = OCMClassMock([CoreDataHelper class]);

    //unit tests should bypass the normal store
    OCMExpect([coreDataHelperMock coreDataStoreURL]).andReturn([[AppDelegate applicationFilesDirectory] URLByAppendingPathComponent:@"MynigmaUnitTests.storedata"]);

    //use an in-memory store for unit tests
    OCMExpect([coreDataHelperMock coreDataStoreType]).andReturn(NSInMemoryStoreType);



//
//    //sets up some accounts, keys, email messages, etc...
//    [self prepareTestData];
//
//    //this will ensure that setup has been completed by the AppDelegate
//    CGFloat setUpTimeoutSecs = 10.0;
//
//    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:setUpTimeoutSecs];
//
//    do {
//        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
//        if([timeoutDate timeIntervalSinceNow] < 0.0)
//            break;
//    } while (!APPDELEGATE.allSetUpDone);
}


+ (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

//+ (TestHarness*)sharedInstance
//{
//    static TestHarness* sharedInst;
//    if(!sharedInst)
//        sharedInst = [TestHarness new];
//    return sharedInst;
//}



@end
