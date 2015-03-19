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

#import "SetupFlowPageCredentials.h"

@implementation SetupFlowPageCredentials


#pragma mark - Setup

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self.settingsTopMarginConstraint setConstant:500];
}





- (IBAction)showSettings:(id)sender
{
    [self.showSettingsButton setHidden:YES];
    [self.buttonSeparator setHidden:YES];
    
    [self.autoDetectCoverLabel setHidden:YES];
    
    [UIView animateWithDuration:1. delay:0 usingSpringWithDamping:.6 initialSpringVelocity:.5 options:0 animations:^{
        
        [self.settingsTopMarginConstraint setConstant:30];
        [self setNeedsLayout];
        [self layoutIfNeeded];
        
    } completion:nil];
}

- (void)hideSettings
{
    [self.showSettingsButton setHidden:NO];
    [self.buttonSeparator setHidden:NO];
    
    [self.autoDetectCoverLabel setHidden:NO];
    
    [self.settingsTopMarginConstraint setConstant:500];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end
