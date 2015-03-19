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





#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "DisplayMessageView.h"
#import "TestHarness.h"
#import "WindowManager.h"
#import "EmailMessage+Category.h"
#import "EmailMessageInstance+Category.h"





@interface DisplayMessageView_Tests : TestHarness

@end

@implementation DisplayMessageView_Tests

- (void)testThatMainContentIsHiddenWhenNoMessageIsSelected
{
    DisplayMessageView* testView = [[WindowManager sharedInstance] displayView];

    XCTAssertNotNil(testView);

    XCTAssertNotNil(testView.hideContentConstraint);
    XCTAssertNotNil(testView.contentFrameView);
    XCTAssertNotNil(testView.placeHolderView);

    [testView showMessageInstance:nil];

    XCTAssertEqual(testView.hideContentConstraint.priority, 999);
    XCTAssert(CGRectGetHeight(testView.contentFrameView.frame) < 1);
    XCTAssert(CGRectGetHeight(testView.placeHolderView.frame) > 100);
}

- (void)testThatMainContentIsShownWhenMessageIsSelected
{
    DisplayMessageView* testView = [[WindowManager sharedInstance] displayView];

    XCTAssertNotNil(testView);

    XCTAssertNotNil(testView.hideContentConstraint);

    //create an arbitrary message
    EmailMessage* newMessage = [EmailMessage findOrMakeMessageWithMessageID:@"someMessageID345345@mynigma.org"];

    EmailMessageInstance* newMessageInstance = [EmailMessageInstance findOrMakeNewInstanceForMessage:newMessage inFolder:nil inContext:MAIN_CONTEXT];

    [testView showMessageInstance:newMessageInstance];

    XCTAssertEqual(testView.hideContentConstraint.priority, 1);
    XCTAssert(CGRectGetHeight(testView.contentFrameView.frame) > 100);
    XCTAssert(CGRectGetHeight(testView.placeHolderView.frame) < 1);
}

@end
