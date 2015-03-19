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
#import "KeychainHelper.h"
#import "IMAPAccountSetting.h"
#import "AppDelegate.h"
#import <XCTest/XCTest.h>
#import "MynigmaPrivateKey.h"
#import "MynigmaPublicKey.h"
#import "TestHarness.h"
#import "AccountCreationManager.h"
#import "ConnectionItem.h"
#import <OCMock/OCMock.h>




#define TEST_EMAIL @"testEmail@someProvider.com"
#define INCOMING_PASSWORD @"soM3_P4s5W0rD_dhif%hfdjh8H*HE@H(H@(DHI@H29dh9mdndk((@**£"
#define OUTGOING_PASSWORD @"jh*£Ur8ri2hI@E*U*@((Ej"
#define INCOMING_SERVER @"imap.someProvider.com"
#define OUTGOING_SERVER @"smtp.SomePRoViDER.coM"

@interface Keychain_iOSTests : TestHarness
{
    IMAPAccountSetting* accountSetting;
}

@end

@interface KeychainHelper (Testing)

+ (NSData*)addPrivateKeyWithData:(NSData*)keyData toKeychainWithLabel:(NSString*)keyLabel forEncryption:(BOOL)forEncryption withPassphrase:(NSString*)passphrase;

+ (NSData*)addPublicKeyWithData:(NSData*)data toKeychainWithLabel:(NSString*)keyLabel forEncryption:(BOOL)forEncryption;

@end

@implementation Keychain_iOSTests

- (void)setUp
{
    [super setUp];

    NSEntityDescription* entity = [NSEntityDescription entityForName:@"IMAPAccountSetting" inManagedObjectContext:MAIN_CONTEXT];
    accountSetting = [[IMAPAccountSetting alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];
    [accountSetting setEmailAddress:TEST_EMAIL];
    [accountSetting setIncomingServer:INCOMING_SERVER];
    [accountSetting setOutgoingServer:OUTGOING_SERVER];

    [accountSetting setDisplayName:@"Test account"];

    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class. 

    [MAIN_CONTEXT deleteObject:accountSetting];

    [super tearDown];
}

- (void)testMailAppList
{
    [KeychainHelper listLocalKeychainItems];
}

- (void)testPasswords
{
    NSString* imapPassword = [KeychainHelper findPasswordForEmail:TEST_EMAIL andServer:@"imap.someProvider.com"];

    XCTAssertNil(imapPassword, @"Should not find IMAP password to begin with");

    NSString* smtpPassword = [KeychainHelper findPasswordForEmail:TEST_EMAIL andServer:@"smtp.someProvider.com"];

    XCTAssertNil(smtpPassword, @"Should not find SMTP password to begin with");

    BOOL saveSuccess = [KeychainHelper savePassword:INCOMING_PASSWORD forAccount:accountSetting.objectID incoming:YES];

    XCTAssertTrue(saveSuccess, @"IMAP Password should be saved");

    saveSuccess = [KeychainHelper savePassword:OUTGOING_PASSWORD forAccount:accountSetting.objectID incoming:NO];

    XCTAssertTrue(saveSuccess, @"SMTP Password should be saved");

    imapPassword = [KeychainHelper findPasswordForEmail:TEST_EMAIL andServer:INCOMING_SERVER];

    XCTAssertEqualObjects(imapPassword, INCOMING_PASSWORD, @"IMAP password should have been recovered");

    smtpPassword = [KeychainHelper findPasswordForEmail:TEST_EMAIL andServer:OUTGOING_SERVER];

    XCTAssertEqualObjects(smtpPassword, OUTGOING_PASSWORD, @"SMTP password should have been recovered");

    imapPassword = [KeychainHelper findPasswordForAccount:accountSetting.objectID incoming:YES];

    XCTAssertEqualObjects(imapPassword, INCOMING_PASSWORD, @"IMAP password should be saved for this account");

    smtpPassword = [KeychainHelper findPasswordForAccount:accountSetting.objectID incoming:NO];

    XCTAssertEqualObjects(smtpPassword, OUTGOING_PASSWORD, @"SMTP password should be saved for this account");

    BOOL deleteSuccess = [KeychainHelper removePasswordForAccount:accountSetting.objectID incoming:YES];

    XCTAssertTrue(deleteSuccess, @"IMAP password should have been deleted");

    deleteSuccess = [KeychainHelper removePasswordForAccount:accountSetting.objectID incoming:NO];

    XCTAssertTrue(deleteSuccess, @"SMTP password should have been deleted");

    imapPassword = [KeychainHelper findPasswordForEmail:TEST_EMAIL andServer:INCOMING_SERVER];

    XCTAssertNil(imapPassword, @"IMAP password should not be recoverable after deletion");

    smtpPassword = [KeychainHelper findPasswordForEmail:TEST_EMAIL andServer:OUTGOING_SERVER];

    XCTAssertNil(smtpPassword, @"SMTP password should not be recoverable after deletion");

}

//- (void)testPrivateKeys
//{
//    NSData* decData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"PrivDec1" ofType:@"pem"]];
//    NSData* sigData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"PrivSig1" ofType:@"pem"]];
//    NSData* encData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"PubEnc1" ofType:@"pem"]];
//    NSData* verData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"PubVer1" ofType:@"pem"]];
//
//
//    NSEntityDescription* entity = [NSEntityDescription entityForName:@"MynigmaPrivateKey" inManagedObjectContext:MAIN_CONTEXT];
//    MynigmaPrivateKey* newKeyPair = [[MynigmaPrivateKey alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];
//
//    [newKeyPair setVersion:MYNIGMA_VERSION];
//    [newKeyPair setDateCreated:[NSDate date]];
//    [newKeyPair setIsCompromised:[NSNumber numberWithBool:NO]];
//
//    __block NSDate* currentDate = [NSDate date];
//
//    __block NSString* keyLabel = [NSString stringWithFormat:@"%@|%f", @"wilhelm.schuettelspeer@gmail.com", [currentDate timeIntervalSince1970]];
//
//    [newKeyPair setKeyLabel:keyLabel];
//
//    XCTAssertFalse([KeychainHelper havePrivateKeychainItemWithLabel:keyLabel], @"Ensuring that key isn't in keychain to begin with...");
//
//    XCTAssertTrue([KeychainHelper addPrivateKeyToKeychainWithEncData:encData1 verData:verData1 decData:decData1 sigData:sigData1 andPrivateKey:newKeyPair], @"Add new private key");
//
//
//    XCTAssertTrue([KeychainHelper havePrivateKeychainItemWithLabel:keyLabel], @"Check for new key");
//
//    NSArray* privateKeys = [KeychainHelper listPrivateKeychainItems];
//    NSArray* publicKeys = [KeychainHelper listPublicKeychainItems];
//
//    NSLog(@"Private keys:%@\nPublic keys:\n%@", privateKeys, publicKeys);
//
//    NSArray* result = [KeychainHelper dataForPrivateKeychainItemWithLabel:keyLabel];
//
//    if(result && result.count>=4)
//    {
//        XCTAssertEqualObjects(result[0], decData1);
//        XCTAssertEqualObjects(result[1], sigData1);
//        XCTAssertEqualObjects(result[2], encData1);
//        XCTAssertEqualObjects(result[3], verData1);
//    }
//    else
//        XCTFail();
//
//    //it won't match: the key is exported with a passphrase...
//    //XCTAssertTrue([KeychainHelper doesPrivateKeychainItemWithLabel:keyLabel matchDecData:decData1 sigData:sigData1 encData:encData1 verData:verData1]);
//
//    XCTAssertTrue([KeychainHelper removePrivateKeychainItemWithLabel:keyLabel], @"Remove new key");
//
//    [newKeyPair setPublicEncrKeyRef:nil];
//
//    XCTAssertFalse([KeychainHelper havePrivateKeychainItemWithLabel:keyLabel], @"Check that removal was successful");
//}

//- (void)testPublicKeys
//{
//    NSData* encData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"PubEnc1" ofType:@"pem"]];
//    NSData* verData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"PubVer1" ofType:@"pem"]];
//    NSData* encData2 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"PubEnc2" ofType:@"pem"]];
//    NSData* verData2 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"PubVer2" ofType:@"pem"]];
//
//
//    NSEntityDescription* entity = [NSEntityDescription entityForName:@"MynigmaPublicKey" inManagedObjectContext:MAIN_CONTEXT];
//    MynigmaPublicKey* newPublicKey = [[MynigmaPublicKey alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];
//
//    [newPublicKey setVersion:MYNIGMA_VERSION];
//    [newPublicKey setDateCreated:[NSDate date]];
//    [newPublicKey setIsCompromised:[NSNumber numberWithBool:NO]];
//
//    __block NSDate* currentDate = [NSDate date];
//
//    __block NSString* keyLabel = [NSString stringWithFormat:@"%@|%f", @"wilhelm.schuettelspeer@gmail.com", [currentDate timeIntervalSince1970]];
//
//    [newPublicKey setKeyLabel:keyLabel];
//
//    XCTAssertFalse([KeychainHelper havePublicKeychainItemWithLabel:keyLabel]);
//
//    XCTAssertTrue([KeychainHelper addPublicKeyToKeychainWithEncData:encData2 verData:verData2 andMynigmaPublicKey:newPublicKey]);
//
//    XCTAssertTrue([KeychainHelper havePublicKeychainItemWithLabel:keyLabel]);
//
//    NSArray* result = [KeychainHelper dataForPublicKeychainItemWithLabel:keyLabel];
//
//    if(result && result.count>=2)
//    {
//        XCTAssertEqualObjects(result[0], encData2);
//        XCTAssertEqualObjects(result[1], verData2);
//    }
//    else
//        XCTFail();
//
//    XCTAssertTrue([KeychainHelper doesPublicKeychainItemWithLabel:keyLabel matchEncData:encData2 andVerData:verData2]);
//
//    XCTAssertFalse([KeychainHelper doesPublicKeychainItemWithLabel:keyLabel matchEncData:encData1 andVerData:verData1]);
//
//    XCTAssertTrue([KeychainHelper removePublicKeychainItemWithLabel:keyLabel]);
//
//    [newPublicKey setPublicEncrKeyRef:nil];
//
//    XCTAssertFalse([KeychainHelper havePublicKeychainItemWithLabel:keyLabel]);
//}

- (void)testDevCert
{
    NSString* fileName = @"Apple ID r.priebe.04@cantab.net key";

    NSData* data = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:fileName ofType:@"p12"]];

    XCTAssertNotNil(data);
    
    NSData* privateKeyPersistentRef = [KeychainHelper addPrivateKeyWithData:data toKeychainWithLabel:@"someLabel@gmail.com|124.342432" forEncryption:YES withPassphrase:@"password"];

    XCTAssertNotNil(privateKeyPersistentRef);
}

- (void)testPrivateKeyImport
{
    NSString* keyLabel = @"wilhelm.schuettelspeer@gmail.com|1374071660.432515";
    NSString* keychainItemLabel = [NSString stringWithFormat:@"Mynigma encryption key %@", keyLabel];

    NSData* pemFileData = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:keychainItemLabel ofType:@"pem"]];
    
    NSData* p12FileData = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:keychainItemLabel ofType:@"p12"]];

    NSData* privateKeyPersistentRef = [KeychainHelper addPrivateKeyWithData:p12FileData toKeychainWithLabel:keyLabel forEncryption:YES withPassphrase:@"password"];

    XCTAssertNotNil(privateKeyPersistentRef);

    NSData* publicKeyPersistentRef = [KeychainHelper addPublicKeyWithData:pemFileData toKeychainWithLabel:keyLabel forEncryption:YES];

    XCTAssertNotNil(publicKeyPersistentRef);
}


- (void)testKeyGenerationUIBlock
{
//    id accountCreationManagerClassMock = OCMClassMock([AccountCreationManager class]);
//    
//    OCMStub([accountCreationManagerClassMock haveAccountFor])
    
    NSString* emailAddress = @"wilhelm.schuettelspeer@gmail.com";
    
//    XCTestExpectation* expectation = [self expectationWithDescription:@"complete key generation"];
    
    ConnectionItem* connectionItem = [[ConnectionItem alloc] initWithEmail:emailAddress];
    
    [connectionItem setPassword:@"speerschuettel"];
    
    [connectionItem lookForSettingsWithCallback:^{
    
        [AccountCreationManager makeNewAccountWithLocalKeychainItem:connectionItem];
        
    }];
   
    [self waitForConditionToBeSatisfied:^BOOL{
        
//        BOOL condition = [MynigmaPrivateKey havePrivateKeyForEmailAddress:emailAddress];
        
//        return condition;
        
        return NO;
        
    } forNSeconds:1200];
}


@end
