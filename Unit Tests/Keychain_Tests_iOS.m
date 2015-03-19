//
//  Keychain_Tests.m
//  Mynigma
//
//  Created by Roman Priebe on 10/09/2013.
//  Copyright (c) 2013 Mynigma UG (haftungsbeschränkt). All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "KeychainHelper_iOS.h"
#import "IMAPAccountSetting.h"
#import "AppDelegate_iOS.h"

#define TEST_EMAIL @"testEmail@someProvider.com"
#define INCOMING_PASSWORD @"soM3_P4s5W0rD_dhif%hfdjh8H*HE@H(H@(DHI@H29dh9mdndk((@**£"
#define OUTGOING_PASSWORD @"jh*£Ur8ri2hI@E*U*@((Ej"
#define INCOMING_SERVER @"imap.someProvider.com"
#define OUTGOING_SERVER @"smtp.SomePRoViDER.coM"

@interface Keychain_Tests : SenTestCase
{
    IMAPAccountSetting* accountSetting;
}

@end

@implementation Keychain_Tests

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
    [KeychainHelper listIMAPPasswordsAndSettingsFoundInKeychain];
}

- (void)testPasswords
{
    NSString* imapPassword = [KeychainHelper findPasswordForEmail:TEST_EMAIL andServer:@"imap.someProvider.com"];

    STAssertNil(imapPassword, @"Should not find IMAP password to begin with");

    NSString* smtpPassword = [KeychainHelper findPasswordForEmail:TEST_EMAIL andServer:@"smtp.someProvider.com"];

    STAssertNil(smtpPassword, @"Should not find SMTP password to begin with");

    BOOL saveSuccess = [KeychainHelper savePassword:INCOMING_PASSWORD forAccount:accountSetting.objectID incoming:YES];

    STAssertTrue(saveSuccess, @"IMAP Password should be saved");

    saveSuccess = [KeychainHelper savePassword:OUTGOING_PASSWORD forAccount:accountSetting.objectID incoming:NO];

    STAssertTrue(saveSuccess, @"SMTP Password should be saved");

    imapPassword = [KeychainHelper findPasswordForEmail:TEST_EMAIL andServer:INCOMING_SERVER];

    STAssertEqualObjects(imapPassword, INCOMING_PASSWORD, @"IMAP password should have been recovered");

    smtpPassword = [KeychainHelper findPasswordForEmail:TEST_EMAIL andServer:OUTGOING_SERVER];

    STAssertEqualObjects(smtpPassword, OUTGOING_PASSWORD, @"SMTP password should have been recovered");

    imapPassword = [KeychainHelper findPasswordForAccount:accountSetting.objectID incoming:YES];

    STAssertEqualObjects(imapPassword, INCOMING_PASSWORD, @"IMAP password should be saved for this account");

    smtpPassword = [KeychainHelper findPasswordForAccount:accountSetting.objectID incoming:NO];

    STAssertEqualObjects(smtpPassword, OUTGOING_PASSWORD, @"SMTP password should be saved for this account");

    BOOL deleteSuccess = [KeychainHelper removePasswordForAccount:accountSetting.objectID incoming:YES];

    STAssertTrue(deleteSuccess, @"IMAP password should have been deleted");

    deleteSuccess = [KeychainHelper removePasswordForAccount:accountSetting.objectID incoming:NO];

    STAssertTrue(deleteSuccess, @"SMTP password should have been deleted");

    imapPassword = [KeychainHelper findPasswordForEmail:TEST_EMAIL andServer:INCOMING_SERVER];

    STAssertNil(imapPassword, @"IMAP password should not be recoverable after deletion");

    smtpPassword = [KeychainHelper findPasswordForEmail:TEST_EMAIL andServer:OUTGOING_SERVER];

    STAssertNil(smtpPassword, @"SMTP password should not be recoverable after deletion");
}

- (void)testPublicKeys
{
    //TO DO: implement
}

@end
