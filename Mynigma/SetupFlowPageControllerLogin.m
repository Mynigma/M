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

#import "SetupFlowPageControllerLogin.h"




@interface SetupFlowPageControllerLogin ()

@end

@implementation SetupFlowPageControllerLogin



- (IBAction)showPrivacyPolicy:(id)sender
{
    NSString* privacyPolicyLocation = NSLocalizedString(@"https://mynigma.org/en/PPApp.html", @"Privacy policy link");
    
    NSURL* privacyPolicyURL = [NSURL URLWithString:privacyPolicyLocation];
    
    [[UIApplication sharedApplication] openURL:privacyPolicyURL];
}


- (IBAction)passwordFieldChanged:(UITextField*)sender
{
    if([sender text].length)
    {
        [self.lockImageView setImage:[UIImage imageNamed:@"BirdClosedEyes128.png"]];
    }
    else
    {
        [self.lockImageView setImage:[UIImage imageNamed:@"BirdOpenEyes128.png"]];
    }
}


@end
