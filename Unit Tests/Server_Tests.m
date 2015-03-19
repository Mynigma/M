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





#import "Server_Tests.h"
#import "ServerHelper.h"
#import "AppDelegate.h"
#import "IMAPAccountSetting.h"
#import "IMAPAccount.h"

#import "Recipient.h"
#import "EncryptionHelper.h"


@implementation Server_Tests




- (void)setUp
{
    [super setUp];

//    setUpDone = NO;
//    [APPDELEGATE setSetUpCallback:^{
//        setUpDone = YES;
//    }];
//
//    [APPDELEGATE applicationDidFinishLaunching:nil];
//
//    CGFloat setUpTimeoutSecs = 10.0;
//
//    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:setUpTimeoutSecs];
//
//    do {
//        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
//        if([timeoutDate timeIntervalSinceNow] < 0.0)
//            break;
//    } while (!setUpDone);
//
//
//    isDone = NO;
//    success = NO;
//    
//    IMAPAccount* newIMAPAccount1 = [IMAPAccount new];
//    
//    [newIMAPAccount1 temporaryAccountWithEmail:@"Wilhelm.Schuettelspeer@GMX.de"];
//    [newIMAPAccount1.imapSession setPassword:@"speerschuettel"];
//    [newIMAPAccount1.smtpSession setPassword:@"speerschuettel"];
//    [newIMAPAccount1 makeAccountPermanent];
//    
//    NSError* error = nil;
//    accountSetting1 = (IMAPAccountSetting*)[MAIN_CONTEXT existingObjectWithID:newIMAPAccount1.settingID error:&error];
//    XCTAssertNil(error);
//    [accountSetting1 setCurrentKeyPairLabel:@"1"];
//
//    [newIMAPAccount1 startupCheckAccount];
//    
//    
//    IMAPAccount* newIMAPAccount2 = [IMAPAccount new];
//    
//    [newIMAPAccount2 temporaryAccountWithEmail:@"Wilhelm.Schuettelspeer@outlook.com"];
//    [newIMAPAccount2.imapSession setPassword:@"speerschuettel1"];
//    [newIMAPAccount2.smtpSession setPassword:@"speerschuettel1"];
//    [newIMAPAccount2 makeAccountPermanent];
//    
//    error = nil;
//    accountSetting2 = (IMAPAccountSetting*)[MAIN_CONTEXT existingObjectWithID:newIMAPAccount2.settingID error:&error];
//    
//    XCTAssertNil(error);
//    
//    [accountSetting2 setCurrentKeyPairLabel:@"2"];
//    [accountSetting2 setIncomingServer:@"imap-mail.outlook.com"];
//    [newIMAPAccount2 startupCheckAccount];

}

- (void)tearDown
{
    // [MAIN_CONTEXT deleteObject:accountSetting1];
    //[MAIN_CONTEXT deleteObject:accountSetting2];
    //[MODEL saveContextToStore];
    
    [super tearDown];
}

- (void)testRomanPriebeAtGmailHash
{
    NSArray* result = [[ServerHelper sharedInstance] hashContacts:@[@"roman.priebe@gmail.com"]];

    NSLog(@"Hash: %@", result);
}


- (BOOL)responseIsOK:(NSDictionary*)dict withError:(NSError*)error
{
    return !error && [[dict objectForKey:@"response"] isEqualTo:@"OK"];
}

- (void)testS000
{

/*

    XCTAssertTrue(setUpDone, @"Set up should have finished");
    
    [SERVER requestWelcomeMessageForAccount:accountSetting1 withCallback:^(NSDictionary *dict, NSError *error) {
        //STAssertTrue([self responseIsOK:dict withError:error], nil);
        NSLog(@"Tested token request 1/2 - response: %@", dict);
        [SERVER requestWelcomeMessageForAccount:accountSetting2 withCallback:^(NSDictionary *dict, NSError *error) {
            //STAssertTrue([self responseIsOK:dict withError:error], nil);
            NSLog(@"Tested token request 2/2 - response: %@", dict);

        }];

    }];

    CGFloat timeoutSecs = 10.0;

    NSDate* timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeoutSecs];
    
    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
        if([timeoutDate timeIntervalSinceNow] < 0.0)
            break;
    } while (!accountSetting1.hasBeenVerified.boolValue || !accountSetting2.hasBeenVerified.boolValue);

    XCTAssertTrue(accountSetting1.hasBeenVerified.boolValue, @"Account 1 verification");
    XCTAssertTrue(accountSetting2.hasBeenVerified.boolValue, @"Account 2 verification");

    //the accounts have been verified - or a timeout has occurred

    //send the first account's contacts to the server

    [ServerHelper sendAllContactsToServerWithAccount:accountSetting1 withCallback:^(NSDictionary *dict, NSError *error) {

        XCTAssertNil(error, @"Account1 contacts sent");

        //add the first account as a contact of the second

        Recipient* rec = [[Recipient alloc] initWithEmail:accountSetting1.emailAddress andName:@"Test1"];
        [ServerHelper sendRecipientsToServer:@[rec] forAccount:accountSetting2 withCallback:^(NSDictionary *dict, NSError *error) {

            XCTAssertNil(error, @"Account2 contacts sent");


        }];




    }];





    //send an empty new contacts request from the second account


    //delete the first account


    //send an empty new contacts request from the second account


    //delete the second account

    //now remove the accounts

    [ServerHelper removeAllRecordsForAccount:accountSetting1 withCallback:^(NSDictionary *dict, NSError *error) {

        NSLog(@"Response1: %@ error: %@", dict, error);

        XCTAssertTrue([self responseIsOK:dict withError:error], @"Server response to remove action 1");

        [ServerHelper removeAllRecordsForAccount:accountSetting2 withCallback:^(NSDictionary *dict, NSError *error) {

            NSLog(@"Response2: %@ error: %@", dict, error);

            XCTAssertTrue([self responseIsOK:dict withError:error], @"Server response to remove action 2");

            isDone = YES;
        }];
    }];

    timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeoutSecs];

    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
        if([timeoutDate timeIntervalSinceNow] < 0.0)
            break;
    } while (!isDone);
*/
}


@end
