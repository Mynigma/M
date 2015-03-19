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
#import "MynigmaDevice+Category.h"
#import "DeviceMessage+Category.h"
#import "EmailMessageData.h"
#import "DataWrapHelper.h"
#import <OCMock/OCMock.h>
#import "AlertHelper.h"
#import "TrustEstablishmentThread.h"




@interface DeviceMessage_Tests : XCTestCase

@end

@implementation DeviceMessage_Tests

- (void)testThatConstructingNewDeviceMessagesWorksAsExpected
{
    DeviceMessage* deviceMessage = [DeviceMessage constructNewDeviceMessageInContext:MAIN_CONTEXT];

    XCTAssertNotNil(deviceMessage, @"Device message should be present");

    XCTAssertNotNil(deviceMessage.messageid, @"MessageID should not be nil");

    XCTAssertEqualObjects(deviceMessage.messageData.subject, NSLocalizedString(@"Internal Mynigma message",@"Device message subject"));
}

- (void)testThatConstructingNewDeviceDiscoveryMessagesWorksAsExpected
{
    DeviceMessage* deviceMessage = [DeviceMessage constructNewDeviceDiscoveryMessageInContext:MAIN_CONTEXT];

    XCTAssertNotNil(deviceMessage, @"Device message should be present");

    XCTAssertNotNil(deviceMessage.messageid, @"MessageID should not be nil");

    XCTAssertEqualObjects(deviceMessage.messageData.subject, NSLocalizedString(@"Internal Mynigma message",@"Device message subject"));

    XCTAssertEqualObjects(deviceMessage.burnAfterReading, @NO);

    XCTAssertNil(deviceMessage.expiryDate);

    XCTAssertEqualObjects(deviceMessage.messageCommand, @"DEVICE_DISCOVERY");

    MynigmaDevice* currentDevice = [MynigmaDevice currentDeviceInContext:MAIN_CONTEXT];

    XCTAssertEqualObjects(deviceMessage.sender, currentDevice);

    XCTAssertEqual(deviceMessage.payload.count, 1);

    XCTAssertNotNil(deviceMessage.dateSent);
}







- (void)testThatReceivedDeviceMessageIsDownloadedAndProcessedASAP
{


}


- (void)testThatProcessedDeviceDiscoveryOffersCreationOfNewThread
{
    DeviceMessage* deviceMessage = [DeviceMessage constructNewDeviceDiscoveryMessageInContext:MAIN_CONTEXT];

    [deviceMessage setPayload:@[[@"TestPayload" dataUsingEncoding:NSUTF8StringEncoding]]];

    id alertHelperMock = OCMClassMock([AlertHelper class]);

    XCTestExpectation* informedUser = [self expectationWithDescription:@"informed user about new thread"];

    OCMExpect([alertHelperMock informUserAboutNewlyDiscoveredDevice:[OCMArg any] inAccountSetting:nil]).andDo(^(NSInvocation* invocation){

        [informedUser fulfill];
    });

    [deviceMessage processMessageWithAccountSetting:nil];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testThatUserConfirmingDeviceConnectionResultsInNewThreadCreation
{
    id alertHelperMock = OCMClassMock([AlertHelper class]);

    OCMExpect([alertHelperMock showTwoOptionDialogueWithTitle:[OCMArg any] message:[OCMArg any] OKOption:[OCMArg any] cancelOption:[OCMArg any] suppressionIdentifier:[OCMArg any] callback:[OCMArg any]]).andDo(^(NSInvocation* invocation){

        //the callback is parameter number 6, so argument index number 7, according to the NSInvocation reckoning
        __unsafe_unretained void (^callback)(BOOL success) = nil;
        [invocation getArgument:&callback atIndex:7];

        //pretend the user clicked OK
        if(callback)
            callback(YES);
    });

    XCTestExpectation* startedThread = [self expectationWithDescription:@"thread has been started"];

    id trustEstablishmentThread = OCMClassMock([TrustEstablishmentThread class]);

    OCMExpect([trustEstablishmentThread startNewThreadWithTargetDeviceUUID:nil withCallback:nil]).andDo(^(NSInvocation* invocation){

        [startedThread fulfill];
    });

    [AlertHelper informUserAboutNewlyDiscoveredDevice:nil inAccountSetting:nil];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}



@end
