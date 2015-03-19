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





#import "FeedbackView.h"
#import "EmailMessage+Category.h"
#import "MynigmaMessage+Category.h"
#import "MynigmaFeedback.h"
#import "BlueTextButton.h"


#define BUTTON_HEIGHT 32

@implementation FeedbackView

- (void)awakeFromNib
{
    [self setWantsLayer:YES];
    [self setCornerRadius:3];

    //[self setFeedBackString:nil];
    [self.feedBackLabel setStringValue:@""];

    [self.progressBar setHidden:YES];
}


- (void)hideFeedback
{
    [self showFeedback:nil withTryAgainAction:nil target:nil];
}

- (void)showFeedbackForMessage:(EmailMessage*)message
{
    MynigmaFeedback* feedback = [message feedback];

    if(!feedback.showFeedbackWindow)
    {
        [self hideFeedback];
        return;
    }

    [self setHidden:NO];

    [self.feedBackLabel setStringValue:feedback.localizedDescription?feedback.localizedDescription:@""];

    if(feedback.showProgressIndicator)
    {
        [self.firstButton setHidden:YES];
        [self.secondButton setHidden:YES];
        [self.thirdButton setHidden:YES];
        [self.fourthButton setHidden:YES];

        [self.progressBar setHidden:NO];
        [self.progressBar startAnimation:nil];

        [self.buttonsHeightConstraint setConstant:32];
    }
else
{
    [self setMessage:message];

    [self setError:feedback];

    [self.progressBar setHidden:YES];
    [self.progressBar stopAnimation:nil];

    if(feedback.localizedRecoveryOptions.count >= 1)
    {
        [self.firstButton setHidden:NO];
        [self.firstButton setTitle:feedback.localizedRecoveryOptions[0]];
    }

    if(feedback.localizedRecoveryOptions.count >= 2)
    {
        [self.secondButton setHidden:NO];
        [self.secondButton setTitle:feedback.localizedRecoveryOptions[1]];
    }

    if(feedback.localizedRecoveryOptions.count >= 3)
    {
        [self.thirdButton setHidden:NO];
        [self.thirdButton setTitle:feedback.localizedRecoveryOptions[2]];
    }

    if(feedback.localizedRecoveryOptions.count >= 4)
    {
        [self.fourthButton setHidden:NO];
        [self.fourthButton setTitle:feedback.localizedRecoveryOptions[3]];
    }


    NSInteger numberOfButtons = feedback.localizedRecoveryOptions.count;

    [self.buttonsHeightConstraint setConstant:numberOfButtons*BUTTON_HEIGHT];
}
}



- (void)showFeedback:(NSString*)feedback withTryAgainAction:(SEL)tryAgainAction target:(id)target
{
    [self.feedBackLabel setStringValue:feedback?feedback:@""];

    self.actionSelector = tryAgainAction;
    self.actionTarget = target;

    if(!feedback)
    {
        [self setHidden:YES];
        return;
    }
    else
    {
        [self setHidden:NO];
    }

    if(tryAgainAction && target)
    {
        [self.firstButton setHidden:NO];
        [self.progressBar setHidden:YES];
        [self.firstButton setStringValue:NSLocalizedString(@"Try again", @"Feedback view")];
        [self.buttonsHeightConstraint setConstant:1*BUTTON_HEIGHT];
    }
    else
    {
        [self.firstButton setHidden:YES];
        [self.progressBar setHidden:NO];
        [self.buttonsHeightConstraint setConstant:1*BUTTON_HEIGHT];
    }

    [self.secondButton setHidden:YES];
    [self.thirdButton setHidden:YES];
    [self.fourthButton setHidden:YES];
}

- (IBAction)firstButtonClicked:(id)sender
{
    if(self.actionTarget && self.actionSelector)
    {
        IMP imp = [self.actionTarget methodForSelector:self.actionSelector];
        void (*func)(id, SEL) = (void *)imp;
        func(self.actionTarget, self.actionSelector);
        //[self.actionTarget performSelector:self.actionSelector];
    }
    else if(self.error && self.message)
    {
        [self.message attemptRecoveryFromError:self.error optionIndex:0];
    }
}

- (IBAction)secondButtonClicked:(id)sender
{
    if(self.error && self.message)
    {
        [self.message attemptRecoveryFromError:self.error optionIndex:1];
    }
}

- (IBAction)thirdButtonClicked:(id)sender
{
    if(self.error && self.message)
    {
        [self.message attemptRecoveryFromError:self.error optionIndex:2];
    }
}

- (IBAction)fourthButtonClicked:(id)sender
{
    if(self.error && self.message)
    {
        [self.message attemptRecoveryFromError:self.error optionIndex:3];
    }
}



- (IBAction)buttonClicked:(id)sender
{
    if(self.actionTarget && self.actionSelector)
    {
        IMP imp = [self.actionTarget methodForSelector:self.actionSelector];
        void (*func)(id, SEL) = (void *)imp;
        func(self.actionTarget, self.actionSelector);
        //[self.actionTarget performSelector:self.actionSelector];
    }
}

- (void)dealloc
{
    [self setActionTarget:nil];
}



@end
