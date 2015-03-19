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
#import "DisplayMessageController.h"





@interface DisplayMessageController_Tests : TestHarness

@end

@implementation DisplayMessageController_Tests




- (void)testThatAllOutletsAreConnected
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main_Universal" bundle:nil];
    
    UINavigationController* navController = [storyboard instantiateViewControllerWithIdentifier:@"displayMessagesNavController"];
    
    DisplayMessageController* testController = (DisplayMessageController*)navController.topViewController;
    
    XCTAssertTrue([testController isKindOfClass:[DisplayMessageController class]]);
    
    //awake the view from nib
    (void)testController.view;
    
    //ensure all the toolbar button are connected
    XCTAssertNotNil(testController.readButton);
    XCTAssertNotNil(testController.flagButton);
    XCTAssertNotNil(testController.replyButton);
    XCTAssertNotNil(testController.replyAllButton);
    XCTAssertNotNil(testController.forwardButton);
    XCTAssertNotNil(testController.separator1);
    XCTAssertNotNil(testController.separator2);
    XCTAssertNotNil(testController.flexibleSpace);

    //ensure they have the correct actions assigned to them
    XCTAssertEqual(testController.readButton.action, @selector(readButtonHit:));
    XCTAssertEqual(testController.flagButton.action, @selector(flagButtonHit:));
    XCTAssertEqual(testController.replyButton.action, @selector(replyButtonHit:));
    XCTAssertEqual(testController.replyAllButton.action, @selector(replyAllButtonHit:));
    XCTAssertEqual(testController.forwardButton.action, @selector(forwardButtonHit:));

    //ensure the recipient fields are set up correctly
    XCTAssertNotNil(testController.toView);
    XCTAssertNotNil(testController.fromView);
    XCTAssertNotNil(testController.replyToView);
    XCTAssertNotNil(testController.ccView);
    XCTAssertNotNil(testController.bccView);
    

    
}



@end
