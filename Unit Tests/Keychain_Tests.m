//Copyright © 2012 - 2015 Roman Priebe
//
//This file is part of M - Safe email made simple.
//
//M is free software: you can redistribute it and/or modify
//it under the terms of the GNU General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.
//
//M is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU General Public License
//along with M.  If not, see <http://www.gnu.org/licenses/>.
//



#import <XCTest/XCTest.h>
#import "KeychainHelper.h"
#import "IMAPAccountSetting+Category.h"
#import "AppDelegate.h"
#import "MynigmaPrivateKey+Category.h"
#import "MynigmaPublicKey+Category.h"
#import "TestHarness.h"
#import "EncryptionHelper.h"
#import "PublicKeyManager.h"
#import <Security/Security.h>


#define TEST_EMAIL @"testEmail@someProvider.com"
#define INCOMING_PASSWORD @"soM3_P4s5W0rD_dhifhfdjh8H*HE@H(H@(DHI@H29dh9mdndk((@**£"
#define OUTGOING_PASSWORD @"jh*£Ur8ri2hI@E*U*@((Ej"
#define INCOMING_SERVER @"imap.someProvider.com"
#define OUTGOING_SERVER @"smtp.SomePRoViDER.coM"


@interface KeychainHelper()

+ (void)dumpAccessRefForPersistentRefToLog:(NSData*)persistentRef;
+ (void)dumpAccessRefForKeyRefToLog:(SecKeychainItemRef)itemRef;
+ (void)dumpAccessRefToLog:(SecAccessRef)accessRef;

@end

@interface Keychain_Tests : TestHarness

@end

@implementation Keychain_Tests

- (void)setUp
{
    [super setUp];

//    NSEntityDescription* entity = [NSEntityDescription entityForName:@"IMAPAccountSetting" inManagedObjectContext:MAIN_CONTEXT];
//    accountSetting = [[IMAPAccountSetting alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];
//    [accountSetting setEmailAddress:TEST_EMAIL];
//    [accountSetting setIncomingServer:INCOMING_SERVER];
//    [accountSetting setOutgoingServer:OUTGOING_SERVER];
//
//    [accountSetting setDisplayName:@"Test account"];

    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class. 

    //[MAIN_CONTEXT deleteObject:accountSetting];

    [super tearDown];
}


- (void)testBasicAccessRights
{
    __block NSDate* currentDate = [NSDate date];

    __block NSString* keyLabel = [NSString stringWithFormat:@"%@|%f", @"wilhelm.schuettel.speer@gmail.com", [currentDate timeIntervalSince1970]];

    NSURL* verDataURL = [BUNDLE URLForResource:@"VerKey" withExtension:@"txt"];
    NSData* verData = [NSData dataWithContentsOfURL:verDataURL];
    XCTAssertNotNil(verData);

    NSURL* encDataURL = [BUNDLE URLForResource:@"EncKey" withExtension:@"txt"];
    NSData* encData = [NSData dataWithContentsOfURL:encDataURL];
    XCTAssertNotNil(encData);

    [MynigmaPublicKey syncMakeNewPublicKeyWithEncKeyData:encData andVerKeyData:verData forEmail:@"wilhelm.schuettel.speer@gmail.com" keyLabel:keyLabel];

    //[KeychainHelper addPublicKeyWithLabel:keyLabel toKeychainWithEncData:encData verData:verData];

    SecKeychainItemRef encKeyRef = (SecKeychainItemRef)[MynigmaPublicKey publicSecKeyRefWithLabel:keyLabel forEncryption:YES];

    XCTAssertNotNil((__bridge id)encKeyRef);

    if(encKeyRef)
        [self ensureKeyCanOnlyBeAccessedByMynigma:encKeyRef];
}


- (void)testPasswords
{
    NSEntityDescription* entityDesc = [NSEntityDescription entityForName:@"IMAPAccountSetting" inManagedObjectContext:MAIN_CONTEXT];

    IMAPAccountSetting* testPasswordSetting = [[IMAPAccountSetting alloc] initWithEntity:entityDesc insertIntoManagedObjectContext:MAIN_CONTEXT];

    [testPasswordSetting setEmailAddress:TEST_EMAIL];

    [testPasswordSetting setIncomingServer:INCOMING_SERVER];
    [testPasswordSetting setIncomingPort:@993];

    [testPasswordSetting setOutgoingServer:OUTGOING_SERVER];
    [testPasswordSetting setOutgoingPort:@465];

    [testPasswordSetting setDisplayName:@"Test Account"];


    NSString* imapPassword = [KeychainHelper findPasswordForEmail:TEST_EMAIL andServer:INCOMING_SERVER];

    XCTAssertNil(imapPassword, @"Should not find IMAP password to begin with");

    NSString* smtpPassword = [KeychainHelper findPasswordForEmail:TEST_EMAIL andServer:OUTGOING_SERVER];

    XCTAssertNil(smtpPassword, @"Should not find SMTP password to begin with");

    BOOL saveSuccess = [KeychainHelper savePassword:INCOMING_PASSWORD forAccount:testPasswordSetting.objectID incoming:YES];

    XCTAssertTrue(saveSuccess, @"IMAP Password should be saved");

    saveSuccess = [KeychainHelper savePassword:OUTGOING_PASSWORD forAccount:testPasswordSetting.objectID incoming:NO];

    XCTAssertTrue(saveSuccess, @"SMTP Password should be saved");

    imapPassword = [KeychainHelper findPasswordForEmail:TEST_EMAIL andServer:testPasswordSetting.incomingServer];

    XCTAssertEqualObjects(imapPassword, INCOMING_PASSWORD, @"IMAP password should have been recovered");

    smtpPassword = [KeychainHelper findPasswordForEmail:TEST_EMAIL andServer:testPasswordSetting.outgoingServer];

    XCTAssertEqualObjects(smtpPassword, OUTGOING_PASSWORD, @"SMTP password should have been recovered");

    imapPassword = [KeychainHelper findPasswordForAccount:testPasswordSetting.objectID incoming:YES];

    XCTAssertEqualObjects(imapPassword, INCOMING_PASSWORD, @"IMAP password should be saved for this account");

    smtpPassword = [KeychainHelper findPasswordForAccount:testPasswordSetting.objectID incoming:NO];

    XCTAssertEqualObjects(smtpPassword, OUTGOING_PASSWORD, @"SMTP password should be saved for this account");

    BOOL deleteSuccess = [KeychainHelper removePasswordForAccount:testPasswordSetting.objectID incoming:YES];

    XCTAssertTrue(deleteSuccess, @"IMAP password should have been deleted");

    deleteSuccess = [KeychainHelper removePasswordForAccount:testPasswordSetting.objectID incoming:NO];

    XCTAssertTrue(deleteSuccess, @"SMTP password should have been deleted");

    imapPassword = [KeychainHelper findPasswordForEmail:testPasswordSetting.emailAddress andServer:INCOMING_SERVER];

    XCTAssertNil(imapPassword, @"IMAP password should not be recoverable after deletion");

    smtpPassword = [KeychainHelper findPasswordForEmail:testPasswordSetting.emailAddress andServer:OUTGOING_SERVER];

    XCTAssertNil(smtpPassword, @"SMTP password should not be recoverable after deletion");
}


//- (void)testGenerateTestData
//{
//    [EncryptionHelper ensureValidCurrentKeyPairForAccount:self.accountSetting1 withCallback:^(BOOL result) {
//        NSArray* keyDataArray = [PublicKeyManager dataForExistingMynigmaPrivateKeyWithLabel:self.accountSetting1.currentKeyPairLabel];
//        NSLog(@"%@", keyDataArray);
//        NSInteger count = 0;
//        for(NSData* data in keyDataArray)
//        {
//            count++;
//            NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"/Users/romanpriebe/Desktop/%ld.txt", count]];
//            [[NSFileManager defaultManager] createFileAtPath:url.path contents:data attributes:nil];
//            NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
//        }
//    }];
//    
//}



- (void)ensureKeyCanOnlyBeAccessedByMynigma:(SecKeychainItemRef)keyRef
{
    //    [KeychainHelper dumpAccessRefForKeyRefToLog:keyRef];

//    SecTrustedApplicationRef thisApplication = NULL;
//
//    OSStatus status = SecTrustedApplicationCreateFromPath(NULL, &thisApplication);
//
//    if(status != noErr || thisApplication == NULL)
//    {
//        NSLog(@"Error setting access rights for freshly added keychain item! %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);
//
//        return;
//    }
//
//    NSArray* newTrustedAppArray = @[(__bridge id)thisApplication];


    SecAccessRef encAccessRef = NULL;

    OSStatus status = SecKeychainItemCopyAccess(keyRef, &encAccessRef);

    XCTAssertTrue(status == 0);

    CFArrayRef encACLList = NULL;

    status = SecAccessCopyACLList(encAccessRef, &encACLList);

    XCTAssertTrue(status == 0);

    NSInteger ACLCount = CFArrayGetCount(encACLList);

    XCTAssertTrue(ACLCount > 0);

    for(NSInteger i = 0; i < ACLCount; i++)
    {
        SecACLRef ACLRef = (SecACLRef)CFArrayGetValueAtIndex(encACLList, i);

        CFArrayRef applicationListRef = NULL;

        CFStringRef description = NULL;

        SecKeychainPromptSelector promptSelector = 0;

        status = SecACLCopyContents(ACLRef, &applicationListRef, &description, &promptSelector);

        XCTAssertTrue(status == 0);

        XCTAssert(promptSelector == kSecKeychainPromptRequirePassphase);

        XCTAssertNotNil((__bridge id)applicationListRef);

        //NSArray* authorisations = (__bridge NSArray*)SecACLCopyAuthorizations(ACLRef);

        XCTAssertEqual([(__bridge NSArray*)applicationListRef count], 1);
    }


}

- (void)dumpAccessRefToLog:(SecKeychainItemRef)itemRef
{
    SecAccessRef encAccessRef = NULL;

    OSStatus status = SecKeychainItemCopyAccess(itemRef, &encAccessRef);

    XCTAssertTrue(status == 0);

    CFArrayRef encACLList = NULL;

    status = SecAccessCopyACLList(encAccessRef, &encACLList);

    XCTAssertTrue(status == 0);

    NSInteger ACLCount = CFArrayGetCount(encACLList);

    //XCTAssertTrue(ACLCount == 1);

    NSLog(@"\n\n%ld ACL entries:\n", ACLCount);

    for(NSInteger i = 0; i < ACLCount; i++)
    {
        SecACLRef ACLRef = (SecACLRef)CFArrayGetValueAtIndex(encACLList, i);

        CFArrayRef applicationListRef = NULL;

        CFStringRef description = NULL;

        SecKeychainPromptSelector promptSelector = 0;

        status = SecACLCopyContents(ACLRef, &applicationListRef, &description, &promptSelector);

        XCTAssertTrue(status == 0);

        XCTAssert(promptSelector == kSecKeychainPromptRequirePassphase);

        XCTAssertNotNil((__bridge id)applicationListRef);

        NSArray* authorisations = (__bridge NSArray*)SecACLCopyAuthorizations(ACLRef);

        NSLog(@"Application list: %@\nDescription: %@\nPrompt selector: %x\nAuthorizations: %@", applicationListRef, description, promptSelector, authorisations);
    }
}


// Ensures that keychain items can only be accessed by Mynigma
- (void)testKeychainAccessRights
{
    
    NSURL* verDataURL = [BUNDLE URLForResource:@"VerKey" withExtension:@"txt"];
    NSData* verData = [NSData dataWithContentsOfURL:verDataURL];
    XCTAssertNotNil(verData);
    
    NSURL* encDataURL = [BUNDLE URLForResource:@"EncKey" withExtension:@"txt"];
    NSData* encData = [NSData dataWithContentsOfURL:encDataURL];
    XCTAssertNotNil(encData);

    NSString* uniqueEmail = @"unittest@testKeychainAccessRights.mynigma.org";

    NSString* uniqueKeyLabel = @"unittest@testKeychainAccessRights.mynigma.org|12321321424.34324325";

    [KeychainHelper removePublicKeychainItemWithLabel:uniqueKeyLabel];

    [MynigmaPublicKey syncMakeNewPublicKeyWithEncKeyData:encData andVerKeyData:verData forEmail:uniqueEmail keyLabel:uniqueKeyLabel];

    SecKeychainItemRef encKeyRef = (SecKeychainItemRef)[MynigmaPublicKey publicSecKeyRefWithLabel:uniqueKeyLabel forEncryption:YES];

    XCTAssertNotNil((__bridge id)encKeyRef);

    if(encKeyRef)
        [self ensureKeyCanOnlyBeAccessedByMynigma:encKeyRef];
}


- (void)d_testGassmannKey
{
//    NSURL* dataURL = [BUNDLE URLForResource:@"Public encryption key: gassmann@advokat.de|1379074867.735981" withExtension:@"pem"];
//
//    NSData* theData = [NSData dataWithContentsOfURL:dataURL];
//
//    XCTAssertNotNil(theData);
//
//    MynigmaPublicKey* publicKey = [MynigmaPublicKey syncMakeNewPublicKeyWithEncKeyData:theData andVerKeyData:theData forEmail:@"gassmann@advokat.de" keyLabel:@"newLabel"];
//
//    XCTAssertNotNil(publicKey);
}

//- (void)d_testAddAndRemoveNewKey
//{
//    //[PublicKeyManager removeKeyPairWithLabel:self.accountSetting1.currentKeyPairLabel];
//    [EncryptionHelper ensureValidCurrentKeyPairForAccount:self.accountSetting1 withCallback:^(BOOL success) {
//
//        XCTAssertTrue(success);
//
//
//        NSLog(@"Now");
//        
//    }];
//
//    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:1000];
//
//    do {
//        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
//        if([timeoutDate timeIntervalSinceNow] < 0.0)
//            break;
//    } while (YES);
//
//}


//- (void)d_testImport
//{
//    MynigmaPrivateKey* newKeyPair = [MynigmaPrivateKey privateKeyWithLabel:@"roman.priebe@gmail.com|1374137755.141907" forEmail:@"roman.priebe@gmail.com" tryKeychain:YES];
//
//    XCTAssertNotNil(newKeyPair);
//
//    
//}

- (void)testPrivateKeys
{
    NSData* decData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"DecKey" ofType:@"txt"]];
    NSData* sigData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"SigKey" ofType:@"txt"]];
    NSData* encData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"EncKey" ofType:@"txt"]];
    NSData* verData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"VerKey" ofType:@"txt"]];


    XCTAssertNotNil(decData1, @"Data file");
    XCTAssertNotNil(sigData1, @"Data file");
    XCTAssertNotNil(encData1, @"Data file");
    XCTAssertNotNil(verData1, @"Data file");


    NSEntityDescription* entity = [NSEntityDescription entityForName:@"MynigmaPrivateKey" inManagedObjectContext:MAIN_CONTEXT];
    MynigmaPrivateKey* newKeyPair = [[MynigmaPrivateKey alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];

    [newKeyPair setVersion:MYNIGMA_VERSION];
    [newKeyPair setDateCreated:[NSDate date]];
    [newKeyPair setIsCompromised:[NSNumber numberWithBool:NO]];

    __block NSDate* currentDate = [NSDate date];

    __block NSString* keyLabel = [NSString stringWithFormat:@"%@|%f", @"wilhelm.schuettelspeer@gmail.com", [currentDate timeIntervalSince1970]];

    [newKeyPair setKeyLabel:keyLabel];

    XCTAssertFalse([KeychainHelper havePrivateKeychainItemWithLabel:keyLabel], @"Ensuring that key isn't in keychain to begin with...");

    XCTAssertTrue([KeychainHelper addPrivateKeyWithLabel:keyLabel toKeychainWithEncData:encData1 verData:verData1 decData:decData1 sigData:sigData1], @"Add new private key");


    XCTAssertTrue([KeychainHelper havePrivateKeychainItemWithLabel:keyLabel], @"Check for new key");

    NSArray* result = [KeychainHelper dataForPrivateKeychainItemWithLabel:keyLabel];

    if(result && result.count>=4)
    {
        //the private keys are exported with a passphrase, so the data won't match
        //XCTAssertEqualObjects(result[0], decData1);
        //XCTAssertEqualObjects(result[1], sigData1);
        XCTAssertEqualObjects(result[2], encData1);
        XCTAssertEqualObjects(result[3], verData1);
    }
    else
        XCTFail();

    XCTAssertTrue([KeychainHelper removePrivateKeychainItemWithLabel:keyLabel], @"Remove new key");

    [newKeyPair setPublicEncrKeyRef:nil];

    XCTAssertFalse([KeychainHelper havePrivateKeychainItemWithLabel:keyLabel], @"Check that removal was successful");

    [MAIN_CONTEXT deleteObject:newKeyPair];
}

- (void)testPublicKeys
{
    NSData* encData2 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"EncKey2" ofType:@"txt"]];
    NSData* verData2 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"VerKey2" ofType:@"txt"]];

    __block NSString* keyLabel = [NSString stringWithFormat:@"%@|%f", @"wilhelm.schuettelspeer@gmail.com", [[NSDate date] timeIntervalSince1970]];


    XCTAssertFalse([KeychainHelper havePublicKeychainItemWithLabel:keyLabel]);

    XCTAssertTrue([KeychainHelper addPublicKeyWithLabel:keyLabel toKeychainWithEncData:encData2 verData:verData2]);

    XCTAssertTrue([KeychainHelper havePublicKeychainItemWithLabel:keyLabel]);

    NSArray* persistentRefs = [KeychainHelper persistentRefsForPublicKeychainItemWithLabel:keyLabel];

    XCTAssertEqual(persistentRefs.count, 2);

    NSData* newEncData2 = [KeychainHelper dataForPersistentRef:persistentRefs.firstObject];

    XCTAssertEqualObjects(newEncData2, encData2);

    NSData* newVerData2 = [KeychainHelper dataForPersistentRef:persistentRefs.lastObject];

    XCTAssertEqualObjects(newVerData2, verData2);

    //XCTAssertTrue([KeychainHelper doesPublicKey:keyLabel matchEncData:encData2 andVerData:verData2]);

    //XCTAssertFalse([KeychainHelper doesPublicKeyWithLabel:keyLabel matchEncData:encData1 andVerData:verData1]);

    [MynigmaPublicKey removePublicKeyWithLabel:keyLabel alsoRemoveFromKeychain:YES];


    XCTAssertFalse([KeychainHelper havePublicKeychainItemWithLabel:keyLabel]);
}


- (void)d_testExportAndImportKeyAsRawData
{
    NSData* decData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"DecKey" ofType:@"txt"]];
    NSData* sigData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"SigKey" ofType:@"txt"]];
    NSData* encData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"EncKey" ofType:@"txt"]];
    NSData* verData1 = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:@"VerKey" ofType:@"txt"]];


    XCTAssertNotNil(decData1, @"Data file");
    XCTAssertNotNil(sigData1, @"Data file");
    XCTAssertNotNil(encData1, @"Data file");
    XCTAssertNotNil(verData1, @"Data file");


    NSEntityDescription* entity = [NSEntityDescription entityForName:@"MynigmaPrivateKey" inManagedObjectContext:MAIN_CONTEXT];
    MynigmaPrivateKey* newKeyPair = [[MynigmaPrivateKey alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];

    [newKeyPair setVersion:MYNIGMA_VERSION];
    [newKeyPair setDateCreated:[NSDate date]];
    [newKeyPair setIsCompromised:[NSNumber numberWithBool:NO]];

    __block NSDate* currentDate = [NSDate date];

    __block NSString* keyLabel = [NSString stringWithFormat:@"%@|%f", @"wilhelm.schuettelspeer@gmail.com", [currentDate timeIntervalSince1970]];

    [newKeyPair setKeyLabel:keyLabel];

    [KeychainHelper addPrivateKeyWithLabel:keyLabel toKeychainWithEncData:encData1 verData:verData1 decData:decData1 sigData:sigData1];

    NSData* data = [KeychainHelper rawDataExportPrivateKeyWithLabel:keyLabel];

    XCTAssertNotNil(data);

    BOOL result = [KeychainHelper importPrivateKeyRawData:data withLabel:[keyLabel stringByAppendingString:@"ext"]];

    XCTAssertTrue(result);
}


@end
