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



#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "TestHarness.h"
#import "SharedSecretTrustController.h"

@interface SharedSecretTrustController_Tests : TestHarness

@end

@implementation SharedSecretTrustController_Tests


- (void)testThatUserConfirmationResultsInDeviceBeingAdded
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main_Universal" bundle:nil];

    SharedSecretTrustController* trustController = (SharedSecretTrustController*)[storyboard instantiateViewControllerWithIdentifier:@"sharedSecretController"];

    XCTAssertNotNil(trustController);

    [trustController matchConfirmed:nil];

    
}


- (void)testThatUserCancellationResultsInDeviceNotBeingAdded
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main_Universal" bundle:nil];

    SharedSecretTrustController* trustController = (SharedSecretTrustController*)[storyboard instantiateViewControllerWithIdentifier:@"sharedSecretController"];

    XCTAssertNotNil(trustController);

    [trustController matchDenied:nil];
}



@end
