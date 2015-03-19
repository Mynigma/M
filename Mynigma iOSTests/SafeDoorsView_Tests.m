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

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "TestHarness.h"
#import "EmailMessage+Category.h"
#import "EmailMessageData.h"
#import "EmailMessageInstance+Category.h"
#import "ViewControllersManager.h"
#import "MessagesController.h"
#import "MynigmaMessage+Category.h"





static NSTimer* timer;
static EmailMessageInstance* messageInstance;



@interface SafeDoorsView_Tests : TestHarness

@end

@implementation SafeDoorsView_Tests


- (void)openDoors
{
    [(MynigmaMessage*)messageInstance.message setDecryptionStatus:@"MF521"];
    
    [[[ViewControllersManager sharedInstance] displayMessageController] showMessageInstance:messageInstance];
    
//    [[[ViewControllersManager sharedInstance] displayMessageController] refreshAnimated:YES alsoRefreshBody:YES];
    
    [self performSelector:@selector(closeDoors) withObject:messageInstance afterDelay:2];
}

- (void)closeDoors
{
    [(MynigmaMessage*)messageInstance.message setDecryptionStatus:@"OK"];
    
    [[[ViewControllersManager sharedInstance] displayMessageController] refreshAnimated:YES alsoRefreshBody:YES];
}

- (void)testOpenDoors
{
    [self expectationWithDescription:@"wait forever"];
    
    MynigmaMessage* newMessage = (MynigmaMessage*)[MynigmaMessage findOrMakeMessageWithMessageID:@"someMessageID34782347" inContext:MAIN_CONTEXT];
    
    messageInstance = [EmailMessageInstance findOrMakeNewInstanceForMessage:newMessage inFolder:nil inContext:MAIN_CONTEXT];
    
    //set a body so the message reports that it's downloaded
    newMessage.messageData.htmlBody = @"Test";
    
    [newMessage setDecryptionStatus:@"OK"];
    
    
    //test this on iPad
    [[[ViewControllersManager sharedInstance] displayMessageController] showMessageInstance:messageInstance];
    
    [self closeDoors];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(openDoors) userInfo:nil repeats:YES];
    
    
    //wait forever
    [self waitForExpectationsWithTimeout:1200 handler:nil];
}



@end
