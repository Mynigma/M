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
#import "AppDelegate.h"
#import "ConnectionItem.h"
#import <OCMock/OCMock.h>
#import <MailCore/MailCore.h>


typedef void (^SuccessCallbackBlock)(BOOL success);

@interface ConnectionItem_Tests : XCTestCase

@end

@implementation ConnectionItem_Tests


#pragma - mark InitTests

- (void)testInit
{
    ConnectionItem* item = [ConnectionItem new];

    XCTAssertNotNil(item);

    XCTAssertTrue(item.shouldUseForImport);
    XCTAssertEqual(item.sourceOfData, ConnectionItemSourceOfDataUndefined);
    XCTAssertEqual(item.sourceOfPassword, ConnectionItemSourceOfPasswordUndefined);

    XCTAssertNil(item.IMAPError);
    XCTAssertNil(item.SMTPError);

    XCTAssertFalse(item.IMAPSuccess);
    XCTAssertFalse(item.SMTPSuccess);
}

- (void)testInitWithEmail
{
    ConnectionItem* item = [[ConnectionItem alloc] initWithEmail:@"WilhelmSchuettelspeer@gmail.com"];
    
    XCTAssertTrue([item.emailAddress isEqual:@"WilhelmSchuettelspeer@gmail.com"]);
}

- (void) testInitWithAccountSetting
{

}


#pragma - mark MXLookupTests

- (void)testMXRecordLookupMynigma
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"MX lookup"];

    ConnectionItem* item = [ConnectionItem new];
    [item performMXLookupForHost:@"mynigma.org" withCallback:^(NSString* result){
        if ([@[@"mx.zohomail.com",@"mx2.zohomail.com"] containsObject:result.lowercaseString])
            [expectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:5
                                 handler:^(NSError *error){
                                     // handler is called on _either_ success or failure
                                     XCTAssertNil(error, @"timeout error: %@", error);
                                 }];
    
}

- (void)testMXRecordLookupPijajo {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"MX lookup"];
    
    ConnectionItem* item = [ConnectionItem new];
    [item performMXLookupForHost:@"pijajo.com" withCallback:^(NSString* result){
        if ([@[@"aspmx2.googlemail.com", @"aspmx.l.google.com", @"aspmx3.googlemail.com", @"alt1.aspmx.l.google.com", @"alt2.aspmx.l.google.com"] containsObject:result.lowercaseString])
            [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5
                                 handler:^(NSError *error){
                                     // handler is called on _either_ success or failure
                                     XCTAssertNil(error, @"timeout error: %@", error);
                                 }];
    
}

- (void) testMXRecordAndPlistLookup
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"MX lookup"];
    ConnectionItem* item = [ConnectionItem new];
    
    [item setEmailAddress:@"john@pijajo.com"];
    
    [item performMXLookupWithCallback:^(BOOL foundsomething){
        if(foundsomething)
            if([item.incomingHost isEqual:@"imap.gmail.com"] &&
               [item.outgoingHost isEqual:@"smtp.gmail.com"] &&
               [item.outgoingPort isEqual:@(587)] &&
               [item.incomingPort isEqual:@(993)])
                [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5
                                 handler:^(NSError *error){
                                     // handler is called on _either_ success or failure
                                     XCTAssertNil(error, @"timeout error: %@", error);
                                 }];
}


#pragma - mark ProvidersPlistLookupTests

- (void)testPerformProvidersPlistLookup
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Plist lookup"];
    
    ConnectionItem* item = [ConnectionItem new];

    [item setEmailAddress:@"wilhelm.schuettelspeer@advokat.de"];
    
    [item performProvidersPlistLookupWithCallback:^(BOOL foundSomething) {
       
        if (foundSomething)
            if([item.incomingHost isEqual:@"mail51.mittwald.de"] &&
               [item.outgoingHost isEqual:@"mail51.mittwald.de"] &&
               [item.outgoingPort isEqual:@(465)] &&
               [item.incomingPort isEqual:@(993)])
                [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5
                                 handler:^(NSError *error){
                                     // handler is called on _either_ success or failure
                                     XCTAssertNil(error, @"timeout error: %@", error);
                                 }];
}

- (void)testPerformProvidersPlistLookupFail
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Plist lookup"];
    
    ConnectionItem* item = [ConnectionItem new];
    
    [item setEmailAddress:@"wilhelm@pijajo.com"];
    
    [item performProvidersPlistLookupWithCallback:^(BOOL foundSomething)
    {
        if (!foundSomething)
            if([item.incomingHost isEqual:@"imap.pijajo.com"] &&
               [item.outgoingHost isEqual:@"smtp.pijajo.com"] &&
               !item.outgoingPort &&
               !item.incomingPort &&
               item.sourceOfData == ConnectionItemSourceOfDataGuessed)
                [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error)
    {
                                     // handler is called on _either_ success or failure
                                     XCTAssertNil(error, @"timeout error: %@", error);
                                 }];
}


- (void)testThatLookingForSettingsSucceedsWithMXInformation
{
    ConnectionItem* newConnectionItem = [ConnectionItem new];

    id connectionItemMock = OCMPartialMock(newConnectionItem);

    [connectionItemMock setEmailAddress:@"someEmailAddress@mynigma.org"];

    XCTestExpectation* lookupPerformed = [self expectationWithDescription:@"MXLookup completed"];


    //lookForSettings will first try the providers json - bypass it!
    OCMExpect([connectionItemMock performProvidersPlistLookupWithCallback:[OCMArg any]]).andDo(^(NSInvocation* invocation){

        __unsafe_unretained void (^callback)(BOOL success) = nil;

        [invocation getArgument:&callback atIndex:2];

        NSLog(@"%@", invocation.debugDescription);

        if(callback)
        {
            //pretend that the providers lookup didn't succeed
            callback(NO);
        }

        NSLog(@"Callback: %@", callback);

    });


    NSArray* returnedMXRecords = @[@"alt1.aspmx.l.google.com", @"other.test.host.mynigma.org"];

    OCMExpect([connectionItemMock MXRecordsForHostname:@"mynigma.org"]).andReturn(returnedMXRecords);

    [newConnectionItem lookForSettingsWithCallback:^{

        XCTAssertEqualObjects(newConnectionItem.incomingHost, @"imap.gmail.com");
        XCTAssertEqualObjects(newConnectionItem.incomingPort, @993);
        XCTAssertEqualObjects(newConnectionItem.incomingConnectionType, @(MCOConnectionTypeTLS));

        XCTAssertEqualObjects(newConnectionItem.outgoingHost, @"smtp.gmail.com");
        XCTAssertEqualObjects(newConnectionItem.outgoingPort, @587);
        XCTAssertEqualObjects(newConnectionItem.outgoingConnectionType, @(MCOConnectionTypeStartTLS));

        [lookupPerformed fulfill];
    }];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testThatProvidersLookupSucceedsWithTOnline
{
    ConnectionItem* newConnectionItem = [ConnectionItem new];

    [newConnectionItem setEmailAddress:@"someEmailAddress@t-online.de"];

    XCTestExpectation* lookupPerformed = [self expectationWithDescription:@"Providers lookup completed"];
    
    [newConnectionItem performProvidersPlistLookupWithCallback:^(BOOL foundSomething) {

        XCTAssertEqualObjects(newConnectionItem.incomingHost, @"secureimap.t-online.de");
        XCTAssertEqualObjects(newConnectionItem.incomingPort, @993);
        XCTAssertEqualObjects(newConnectionItem.incomingConnectionType, @(MCOConnectionTypeTLS));

        XCTAssertEqualObjects(newConnectionItem.outgoingHost, @"securesmtp.t-online.de");
        XCTAssertEqualObjects(newConnectionItem.outgoingPort, @465);
        XCTAssertEqualObjects(newConnectionItem.outgoingConnectionType, @(MCOConnectionTypeTLS));

        [lookupPerformed fulfill];
    }];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testThatProvidersLookupSucceedsWithWebDe
{
    ConnectionItem* newConnectionItem = [ConnectionItem new];

    [newConnectionItem setEmailAddress:@"someEmailAddress@web.de"];

    XCTestExpectation* lookupPerformed = [self expectationWithDescription:@"Providers lookup completed"];

    [newConnectionItem performProvidersPlistLookupWithCallback:^(BOOL foundSomething) {

        XCTAssertEqualObjects(newConnectionItem.incomingHost, @"imap.web.de");
        XCTAssertEqualObjects(newConnectionItem.incomingPort, @993);
        XCTAssertEqualObjects(newConnectionItem.incomingConnectionType, @(MCOConnectionTypeTLS));

        XCTAssertEqualObjects(newConnectionItem.outgoingHost, @"smtp.web.de");
        XCTAssertEqualObjects(newConnectionItem.outgoingPort, @587);
        XCTAssertEqualObjects(newConnectionItem.outgoingConnectionType, @(MCOConnectionTypeStartTLS));

        [lookupPerformed fulfill];
    }];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testThatProvidersLookupSucceedsWithPosteo
{
    ConnectionItem* newConnectionItem = [ConnectionItem new];

    [newConnectionItem setEmailAddress:@"someEmailAddress@posteo.de"];

    XCTestExpectation* lookupPerformed = [self expectationWithDescription:@"Providers lookup completed"];

    [newConnectionItem performProvidersPlistLookupWithCallback:^(BOOL foundSomething) {

        XCTAssertEqualObjects(newConnectionItem.incomingHost, @"posteo.de");
        XCTAssertEqualObjects(newConnectionItem.incomingPort, @993);
        XCTAssertEqualObjects(newConnectionItem.incomingConnectionType, @(MCOConnectionTypeTLS));

        XCTAssertEqualObjects(newConnectionItem.outgoingHost, @"posteo.de");
        XCTAssertEqualObjects(newConnectionItem.outgoingPort, @465);
        XCTAssertEqualObjects(newConnectionItem.outgoingConnectionType, @(MCOConnectionTypeTLS));

        [lookupPerformed fulfill];
    }];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}


@end
