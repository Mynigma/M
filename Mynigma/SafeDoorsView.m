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

#import "SafeDoorsView.h"
#import "TintedImageView.h"
#import "UIView+LayoutAdditions.h"
#import "FeedbackOverlayView.h"
#import "MynigmaFeedback.h"
#import "SafeDoorsViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>



@implementation SafeDoorsView


- (void)awakeFromNib
{
    if(NSClassFromString(@"UIVisualEffectView"))
    {
        //on iOS 8
        
        SafeDoorsViewController* loadedDoorsController = [[SafeDoorsViewController alloc] initWithNibName:@"DoorsView" bundle:nil];
        
        [self addSubview:loadedDoorsController.view];
        
        [loadedDoorsController.view setUpConstraintsToFitIntoSuperview];
        
        self.openDoorsConstraint = loadedDoorsController.openDoorsConstraint;
        self.openBottomDoorsConstraint = loadedDoorsController.openBottomDoorsConstraint;
        self.bottomDoorView = loadedDoorsController.bottomDoorView;
        self.topDoorView = loadedDoorsController.topDoorView;
  
//        //set up the top door
//        UIBlurEffect* blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
//        UIVisualEffectView* topDoor = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
//        
//        
//        [topDoor.contentView setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:.5]];
//        
//        [self addSubview:topDoor];
//        
//        //we'll set up the constraints by hand
//        [topDoor setTranslatesAutoresizingMaskIntoConstraints:NO];
//        
//        NSLayoutConstraint* leftConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:topDoor attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
//        NSLayoutConstraint* rightConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:topDoor attribute:NSLayoutAttributeRight multiplier:1 constant:0];
//        NSLayoutConstraint* topConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:topDoor attribute:NSLayoutAttributeTop multiplier:1 constant:0];
//        
//        [self addConstraints:@[leftConstraint, topConstraint, rightConstraint]];
//        
//
//        //set up the top door
//        UIVisualEffectView* bottomDoor = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
//        
//        [bottomDoor.contentView setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:.5]];
//
//        [self addSubview:bottomDoor];
//        
//        //we'll set up the constraints by hand
//        [bottomDoor setTranslatesAutoresizingMaskIntoConstraints:NO];
//        
//        leftConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:bottomDoor attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
//        rightConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:bottomDoor attribute:NSLayoutAttributeRight multiplier:1 constant:0];
//        NSLayoutConstraint* bottomConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:bottomDoor attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
//        
//        [self addConstraints:@[leftConstraint, bottomConstraint, rightConstraint]];
//
//        
//        //the gap between the doors - this constraint enforces no gap, i.e. closed doors
//        //it's priority will be set low enough so that other constraints can overwrite it if the doors need to be open
//        NSLayoutConstraint* gapConstraint = [NSLayoutConstraint constraintWithItem:topDoor attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:bottomDoor attribute:NSLayoutAttributeTop multiplier:1 constant:0];
//        [gapConstraint setPriority:800];
//        
//        [self addConstraint:gapConstraint];
//        
//        //ensure both doors have the same height
//        NSLayoutConstraint* sameHeightConstraint = [NSLayoutConstraint constraintWithItem:topDoor attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:bottomDoor attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
//        
//        [self addConstraint:sameHeightConstraint];
//        
//        
//        
//        UIVibrancyEffect* vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
//
//        
//    
//        
//        //set up the Mynigma logo
//        
//        //top half
//        
//        //first need a vibrancy view
//        UIVisualEffectView* topVibrancyView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
//
//        [topDoor.contentView addSubview:topVibrancyView];
//        
//        [topVibrancyView setTranslatesAutoresizingMaskIntoConstraints:NO];
//        
//        [topVibrancyView setUpConstraintsToFitIntoSuperview];
//        
//        
//        UIImageView* topLogo = [[TintedImageView alloc] initWithImage:[UIImage imageNamed:@"BG_Muenze"]];
//        
//        [topLogo setTintColor:[UIColor blackColor]];
//        
//        [topVibrancyView.contentView addSubview:topLogo];
//        
//        [topLogo setTranslatesAutoresizingMaskIntoConstraints:NO];
//
//        NSLayoutConstraint* topLogoHorizontal = [NSLayoutConstraint constraintWithItem:topVibrancyView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:topLogo attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
//        
//        //it's half obscured by the bottom edge
//        NSLayoutConstraint* topLogoVertical = [NSLayoutConstraint constraintWithItem:topVibrancyView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:topLogo attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
//        
//        [topVibrancyView addConstraints:@[topLogoHorizontal, topLogoVertical]];
//        
//        //make sure the bottom half of the logo is clipped
//        [topDoor setClipsToBounds:YES];
//        
//        
//        //bottom half
//        UIVisualEffectView* bottomVibrancyView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
//        
//        [bottomDoor.contentView addSubview:bottomVibrancyView];
//        
//        [bottomVibrancyView setTranslatesAutoresizingMaskIntoConstraints:NO];
//
//        [bottomVibrancyView setUpConstraintsToFitIntoSuperview];
//
//        
//        UIImageView* bottomLogo = [[TintedImageView alloc] initWithImage:[UIImage imageNamed:@"BG_Muenze"]];
//        
//        [bottomLogo setTintColor:[UIColor blackColor]];
//
//        [bottomVibrancyView.contentView addSubview:bottomLogo];
//        
//        [bottomLogo setTranslatesAutoresizingMaskIntoConstraints:NO];
//
//        NSLayoutConstraint* bottomLogoHorizontal = [NSLayoutConstraint constraintWithItem:bottomVibrancyView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:bottomLogo attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
//        
//        //it's half obscured by the bottom edge
//        NSLayoutConstraint* bottomLogoVertical = [NSLayoutConstraint constraintWithItem:bottomVibrancyView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:bottomLogo attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
//        
//        [bottomVibrancyView addConstraints:@[bottomLogoHorizontal, bottomLogoVertical]];
//        
//        //make sure the bottom half of the logo is clipped
//        [bottomVibrancyView setClipsToBounds:YES];
//        
//        
//        
//        
//        //set up the borders
//        
//        //top left
//        UIVisualEffectView* superview = topDoor;
//        
//        UIVisualEffectView* subview = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
//        
//        [subview.contentView setBackgroundColor:[UIColor blackColor]];
//        
//        [superview.contentView addSubview:subview];
//        
//        [subview setTranslatesAutoresizingMaskIntoConstraints:NO];
//        
//        
//        leftConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
//        
//        rightConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:topLogo attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
//        
//        bottomConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
//        
//        NSLayoutConstraint* heightConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:2];
//        
//        [superview addConstraints:@[leftConstraint, bottomConstraint, rightConstraint, heightConstraint]];
//        
//        
//        //top right
//        subview = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
//        
//        [subview.contentView setBackgroundColor:[UIColor blackColor]];
//        
//        [superview.contentView addSubview:subview];
//        
//        [subview setTranslatesAutoresizingMaskIntoConstraints:NO];
//        
//        
//        leftConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:topLogo attribute:NSLayoutAttributeRight multiplier:1 constant:0];
//        
//        rightConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeRight multiplier:1 constant:0];
//        
//        bottomConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
//        
//        heightConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:2];
//        
//        [superview addConstraints:@[leftConstraint, bottomConstraint, rightConstraint, heightConstraint]];
//        
//        
//
//        
//        superview = bottomDoor;
//
//        //bottom left
//        subview = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
//        
//        [subview.contentView setBackgroundColor:[UIColor blackColor]];
//        
//        [superview.contentView addSubview:subview];
//        
//        [subview setTranslatesAutoresizingMaskIntoConstraints:NO];
//        
//        leftConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
//        
//        rightConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:bottomLogo attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
//        
//        topConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeTop multiplier:1 constant:0];
//        
//        heightConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:1];
//        
//        [superview addConstraints:@[leftConstraint, topConstraint, rightConstraint, heightConstraint]];
//
//        
//        
//        //bottom right
//        subview = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
//        
//        [subview.contentView setBackgroundColor:[UIColor blackColor]];
//        
//        [superview.contentView addSubview:subview];
//        
//        [subview setTranslatesAutoresizingMaskIntoConstraints:NO];
//        
//        
//        leftConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:bottomLogo attribute:NSLayoutAttributeRight multiplier:1 constant:0];
//        
//        rightConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeRight multiplier:1 constant:0];
//        
//        topConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeTop multiplier:1 constant:0];
//        
//        heightConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:1];
//        
//        [superview addConstraints:@[leftConstraint, topConstraint, rightConstraint, heightConstraint]];
//       
//        
//        
//        
//        
//        
//
//        
//        //finally, set up a constraint that will allow us to open the doors if necessary
//        self.openTopDoorsConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:topDoor attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
//        
//        [self.openTopDoorsConstraint setPriority:1];
//        
//        self.openBottomDoorsConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:bottomDoor attribute:NSLayoutAttributeTop multiplier:1 constant:0];
//        
//        [self.openBottomDoorsConstraint setPriority:1];
//        
//        [self addConstraints:@[self.openTopDoorsConstraint, self.openBottomDoorsConstraint]];
    }
    else
    {
        //on iOS 7 don't show any doors at all
    }
    
    //set up the feedback view
    UIViewController* feedbackViewController = [[UIViewController alloc] initWithNibName:@"FeedbackView" bundle:nil];
    
    [self addSubview:feedbackViewController.view];
    
    [feedbackViewController.view setUpConstraintsToFitIntoSuperview];
    
    [self setFeedbackFrameView:(FeedbackOverlayView*)feedbackViewController.view];
}

- (void)hideDoors
{
    [self.bottomDoorView setHidden:YES];
    [self.topDoorView setHidden:YES];
}

- (void)openDoorsAnimated:(BOOL)animated
{
    
    BOOL isCurrentlyClosed = self.openDoorsConstraint.priority < 500;
    
    if (isCurrentlyClosed)
    {
    [UIView animateWithDuration:animated?1:0 delay:animated?.3:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{

//        [self.openTopDoorsConstraint setPriority:999];
        [self.openBottomDoorsConstraint setPriority:999];
        
        [self.openDoorsConstraint setPriority:999];
        
        [self setNeedsLayout];
        [self layoutIfNeeded];

    } completion:^(BOOL finished) {
        
        //this will mess up the animation, for some reason...
//        if(finished)
//            [self setHidden:YES];
    }];
    
    [self performSelector:@selector(hideDoors) withObject:nil afterDelay:1.3];
        
    }
}


- (void)closeDoorsAnimated:(BOOL)animated
{
    [self closeDoorsAnimated:animated completion:nil];
}

- (void)closeDoorsAnimated:(BOOL)animated completion:(void(^)(BOOL))completionCallback;
{
    BOOL isCurrentlyOpen = self.openDoorsConstraint.priority > 500;

    [self.bottomDoorView setHidden:NO];
    [self.topDoorView setHidden:NO];

    if(isCurrentlyOpen)
    {
    [UIView animateWithDuration:animated?1:0 animations:^{
        
        [self.openBottomDoorsConstraint setPriority:1];
        
        [self.openDoorsConstraint setPriority:1];
        
        [self layoutSubviews];
        
        [self setNeedsLayout];
        [self layoutIfNeeded];
        
        [self.bottomDoorView setFrame:self.bottomDoorView.superview.bounds];

        // vibrate + sound for the animation, needs fine tuning
        if (animated)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                SystemSoundID addedSound;
                AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"locked" ofType:@"mp3"]], &addedSound);
                AudioServicesPlaySystemSound(addedSound);

            });
        }
    } completion:completionCallback];
    }
    else
    {
    if (completionCallback)
        completionCallback(YES);
    }
}

- (void)toggleDoorsAnimated:(BOOL)animated
{
    if(self.openDoorsConstraint.priority > 500)
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
        [self setUserInteractionEnabled:YES];
    }
    else
    {
        [self.feedbackFrameView setHidden:YES];
        [self setUserInteractionEnabled:NO];
    }
    
    [self.feedbackFrameView setUpWithFeedback:feedback];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}



@end
