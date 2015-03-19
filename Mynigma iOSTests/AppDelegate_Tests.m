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
#import "AppDelegate.h"


@interface AppDelegate_Tests : XCTestCase

@end

@implementation AppDelegate_Tests

- (void)testThatAllOutletsAreSetUp
{
    AppDelegate* appDelegate = APPDELEGATE;

    XCTAssertNotNil(appDelegate.foldersBox);
    XCTAssertNotNil(appDelegate.contactsBox);

//    XCTAssertNotNil(appDelegate.foldersLabel);
//    XCTAssertNotNil(appDelegate.contactsLabel);


    //the search field at the top right of the window
    XCTAssertNotNil(appDelegate.searchField);

    //various buttons in the window
    XCTAssertNotNil(appDelegate.showFlaggedButton);
    XCTAssertNotNil(appDelegate.showUnreadButton);
    XCTAssertNotNil(appDelegate.showSafeButton);

    XCTAssertNotNil(appDelegate.showFoldersButton);
    XCTAssertNotNil(appDelegate.showContactsButton);
    XCTAssertNotNil(appDelegate.showAttachmentsButton);

    //the contact list on the left hand side
    XCTAssertNotNil(appDelegate.contactTable);

    //the main window
    XCTAssertNotNil(appDelegate.window);


    //the message list table view
    XCTAssertNotNil(appDelegate.messagesTable);

    XCTAssertNotNil(appDelegate.messageListController);

    //the split view containing contact/folder outline view, message list table view and the content viewer
    XCTAssertNotNil(appDelegate.mainSplitView);
    XCTAssertNotNil(appDelegate.mainSplitViewDelegate);

    XCTAssertNotNil(appDelegate.messageListScrollView);
    
    XCTAssertNotNil(appDelegate.refreshInboxButton);
}

@end
