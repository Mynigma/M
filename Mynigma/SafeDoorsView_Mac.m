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

#import "SafeDoorsView_Mac.h"
#import "MynigmaFeedback.h"
#import "TintedImageView_Mac.h"
#import "NSView+LayoutAdditions.h"
#import "FeedbackOverlayView.h"



@implementation SafeDoorsView


- (void)awakeFromNib
{
    if(NSClassFromString(@"NSVisualEffectView"))
    {
        //on Yosemite

        //set up the top door
        //UIBlurEffect* blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        NSVisualEffectView* topDoor = [[NSVisualEffectView alloc] init];

        [topDoor setBlendingMode:NSVisualEffectBlendingModeWithinWindow];
        [topDoor setMaterial:NSVisualEffectMaterialLight];

        [self addSubview:topDoor];

        //we'll set up the constraints by hand
        [topDoor setTranslatesAutoresizingMaskIntoConstraints:NO];

        NSLayoutConstraint* leftConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:topDoor attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
        NSLayoutConstraint* rightConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:topDoor attribute:NSLayoutAttributeRight multiplier:1 constant:0];
        NSLayoutConstraint* topConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:topDoor attribute:NSLayoutAttributeTop multiplier:1 constant:0];

        [self addConstraints:@[leftConstraint, topConstraint, rightConstraint]];


        //set up the top door
        NSVisualEffectView* bottomDoor = [[NSVisualEffectView alloc] init];

        [self addSubview:bottomDoor];

        //we'll set up the constraints by hand
        [bottomDoor setTranslatesAutoresizingMaskIntoConstraints:NO];

        leftConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:bottomDoor attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
        rightConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:bottomDoor attribute:NSLayoutAttributeRight multiplier:1 constant:0];
        NSLayoutConstraint* bottomConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:bottomDoor attribute:NSLayoutAttributeBottom multiplier:1 constant:0];

        [self addConstraints:@[leftConstraint, bottomConstraint, rightConstraint]];


        //the gap between the doors - this constraint enforces no gap, i.e. closed doors
        //it's priority will be set low enough so that other constraints can overwrite it if the doors need to be open
        NSLayoutConstraint* gapConstraint = [NSLayoutConstraint constraintWithItem:topDoor attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:bottomDoor attribute:NSLayoutAttributeTop multiplier:1 constant:0];
        [gapConstraint setPriority:800];

        [self addConstraint:gapConstraint];

        //ensure both doors have the same height
        NSLayoutConstraint* sameHeightConstraint = [NSLayoutConstraint constraintWithItem:topDoor attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:bottomDoor attribute:NSLayoutAttributeHeight multiplier:1 constant:0];

        [self addConstraint:sameHeightConstraint];



        //set up the Mynigma logo

        //top half

        TintedImageView* topLogo = [[TintedImageView alloc] init];

        [topLogo setImage:[NSImage imageNamed:@"BG_Muenze"]];

        [topLogo setTintColor:[NSColor blackColor]];

        [topDoor addSubview:topLogo];

        [topLogo setTranslatesAutoresizingMaskIntoConstraints:NO];

        NSLayoutConstraint* topLogoHorizontal = [NSLayoutConstraint constraintWithItem:topDoor attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:topLogo attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];

        //it's half obscured by the bottom edge
        NSLayoutConstraint* topLogoVertical = [NSLayoutConstraint constraintWithItem:topDoor attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:topLogo attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];

        [topDoor addConstraints:@[topLogoHorizontal, topLogoVertical]];

        //make sure the bottom half of the logo is clipped
        [topDoor.layer setMasksToBounds:YES];



        TintedImageView* bottomLogo = [[TintedImageView alloc] init];

        [bottomLogo setImage:[NSImage imageNamed:@"BG_Muenze"]];

        [bottomLogo setTintColor:[NSColor blackColor]];

        [bottomLogo setTranslatesAutoresizingMaskIntoConstraints:NO];

        NSLayoutConstraint* bottomLogoHorizontal = [NSLayoutConstraint constraintWithItem:bottomDoor attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:bottomLogo attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];

        //it's half obscured by the bottom edge
        NSLayoutConstraint* bottomLogoVertical = [NSLayoutConstraint constraintWithItem:bottomDoor attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:bottomLogo attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];

        [bottomDoor addConstraints:@[bottomLogoHorizontal, bottomLogoVertical]];

        //make sure the bottom half of the logo is clipped
        [bottomDoor.layer setMasksToBounds:YES];


        //finally, set up a constraint that will allow us to open the doors if necessary
        self.openTopDoorsConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:topDoor attribute:NSLayoutAttributeBottom multiplier:1 constant:0];

        [self.openTopDoorsConstraint setPriority:1];

        self.openBottomDoorsConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:bottomDoor attribute:NSLayoutAttributeTop multiplier:1 constant:0];

        [self.openBottomDoorsConstraint setPriority:1];

        [self addConstraints:@[self.openTopDoorsConstraint, self.openBottomDoorsConstraint]];
    }
    else
    {
        //on < 10.10 don't show any doors at all
    }

    //set up the feedback view
    NSViewController* feedbackViewController = [[NSViewController alloc] initWithNibName:@"FeedbackView_Mac" bundle:nil];

    [self addSubview:feedbackViewController.view];

    [feedbackViewController.view setUpConstraintsToFitIntoSuperview];

    [self setFeedbackFrameView:(FeedbackOverlayView*)feedbackViewController.view];
}



- (void)openDoorsAnimated:(BOOL)animated
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:animated?1:0];

        [self.openTopDoorsConstraint setPriority:999];
        [self.openBottomDoorsConstraint setPriority:999];

        [self layout];

    [[NSAnimationContext currentContext] setCompletionHandler:^{

        [self setHidden:YES];
    }];

    [NSAnimationContext endGrouping];
}


- (void)closeDoorsAnimated:(BOOL)animated
{
    [self closeDoorsAnimated:animated completion:nil];
}

- (void)closeDoorsAnimated:(BOOL)animated completion:(void(^)(BOOL))completionCallback;
{
    [self setHidden:NO];

    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:animated?1:0];

        [self.openTopDoorsConstraint setPriority:1];
        [self.openBottomDoorsConstraint setPriority:1];

        [self layout];

    [[NSAnimationContext currentContext] setCompletionHandler:^{

        [self setHidden:YES];

        if(completionCallback)
            completionCallback(YES);
    }];

    [NSAnimationContext endGrouping];
}

- (void)toggleDoorsAnimated:(BOOL)animated
{
    if(self.openTopDoorsConstraint.priority > 500)
        [self closeDoorsAnimated:animated];
    else
        [self openDoorsAnimated:animated];
}



#pragma mark - Feedback view

- (void)showMynigmaFeedback:(MynigmaFeedback*)feedback
{
    BOOL showFeedbackWindow = [feedback showFeedbackWindow];

    if(showFeedbackWindow)
    {
        [self.feedbackFrameView setHidden:NO];
    }
    else
    {
        [self.feedbackFrameView setHidden:YES];
    }

    [self.feedbackFrameView setUpWithFeedback:feedback];
    
    [self layout];
}



@end
