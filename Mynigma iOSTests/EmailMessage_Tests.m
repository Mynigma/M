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
#import "EmailMessage+Category.h"
#import "DeviceMessage+Category.h"
#import "MynigmaMessage+Category.h"




@interface EmailMessage_Tests : TestHarness

@end

@implementation EmailMessage_Tests

- (void)testThatDownloadFailsWithoutInstances
{
//    EmailMessage* newMessage = [EmailMessage findOrMakeMessageWithMessageID:@"someTestMessageID"];
//
//    XCTAssertEqual(newMessage.instances.count, 0);
//
//    [newMessage downloadUrgently];

    //TO DO
}

- (void)testSuccessfulDownloadOfEmailMessage
{
    //EmailMessage* newMessage = [EmailMessage findOrMakeMessageWithMessageID:@"someTestMessageID"];

    //TO DO
}


- (void)testThatCreatedDeviceMessagesHaveTheCorrectType
{
    EmailMessage* message = [DeviceMessage findOrMakeMessageWithMessageID:@"someMessageID4536"];
    XCTAssert([message isMemberOfClass:[DeviceMessage class]]);
}

- (void)testThatCreatedEmailMessagesHaveTheCorrectType
{
    EmailMessage* message = [EmailMessage findOrMakeMessageWithMessageID:@"someMessageID342434"];
    XCTAssert([message isMemberOfClass:[EmailMessage class]]);
}

- (void)testThatCreatedMynigmaMessagesHaveTheCorrectType
{
    EmailMessage* message = [MynigmaMessage findOrMakeMessageWithMessageID:@"someMessageID2352345"];
    XCTAssert([message isMemberOfClass:[MynigmaMessage class]]);
}

- (void)testClassMismatchWantSafeMessageHaveNormal
{
    NSString* duplicateMessageID = @"someMessageID235434532";

    EmailMessage* normalMessage = [EmailMessage findOrMakeMessageWithMessageID:duplicateMessageID];

    XCTAssertNotNil(normalMessage);

    MynigmaMessage* newSafeMessage = [MynigmaMessage findOrMakeMessageWithMessageID:duplicateMessageID];

    XCTAssertNil(newSafeMessage);
}


@end
