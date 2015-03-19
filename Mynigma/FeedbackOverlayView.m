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

#import "FeedbackOverlayView.h"
#import "MynigmaFeedback.h"




@implementation FeedbackOverlayView

- (void)awakeFromNib
{
    [self.roundedCornerView.layer setCornerRadius:5];
}



- (void)setUpWithFeedback:(MynigmaFeedback*)feedback
{
    if(!feedback)
        return;
    
    [self setFeedback:feedback];
    
    //activity indicator
    
    BOOL showActivityIndicator = [feedback showProgressIndicator];
    
    if(showActivityIndicator && !self.activityIndicator.isAnimating)
        [self.activityIndicator startAnimating];
    
    [self.activityIndicator setHidden:!showActivityIndicator];
    [self.hideActivityIndicatorConstraint setPriority:showActivityIndicator?1:999];
    
    
    //main message
    
    [self.messageTextLabel setText:feedback.localizedDescription?feedback.localizedDescription:NSLocalizedString(@"Unspecified error", nil)];
    
    
    //buttons
    NSInteger numberOfButtons = feedback.localizedRecoveryOptions.count;
    
    CGFloat neededHeight = numberOfButtons?(numberOfButtons * 48 - 1):-1;
    
    [self.totalButtonsHeightConstraint setConstant:neededHeight];
    
    for(NSInteger index = 0; index < numberOfButtons; index++)
    {
        UIButton* button = [self valueForKey:[NSString stringWithFormat:@"button%ld", (long)index+1]];
        
        [button setTitle:feedback.localizedRecoveryOptions[index] forState:UIControlStateNormal];
        
        //set up the actions for the buttons
        NSString* recoveryActionName = [NSString stringWithFormat:@"recoveryOption%ldPicked:", (long)index];
        SEL recoveryAction = NSSelectorFromString(recoveryActionName);
        [button addTarget:self action:recoveryAction forControlEvents:UIControlEventTouchUpInside];
    }
}



- (IBAction)recoveryOption0Picked:(id)sender
{
    [self.feedback recoveryOption0Picked:sender];
}

- (IBAction)recoveryOption1Picked:(id)sender
{
    [self.feedback recoveryOption1Picked:sender];
}

- (IBAction)recoveryOption2Picked:(id)sender
{
    [self.feedback recoveryOption2Picked:sender];
}

- (IBAction)recoveryOption3Picked:(id)sender
{
    [self.feedback recoveryOption3Picked:sender];
}

- (IBAction)recoveryOption4Picked:(id)sender
{
    [self.feedback recoveryOption4Picked:sender];
}

- (IBAction)recoveryOption5Picked:(id)sender
{
    [self.feedback recoveryOption5Picked:sender];
}


@end
