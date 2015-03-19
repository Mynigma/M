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





#import "SetupView.h"
#import "SetupScreensViewController.h"
#import "AppDelegate.h"
#import "WindowManager.h"



@implementation SetupView

- (void)awakeFromNib
{
    self.setupScreensViewController = [[SetupScreensViewController alloc] initWithNibName:@"SetupScreens" bundle:nil];

    self.setupScreensViewController.currentPage = 1;

    [self.setupScreensViewController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.contentView addSubview:self.setupScreensViewController.view];

    NSView* setupView = self.setupScreensViewController.view;
    NSView* superview = self.contentView;

    NSLayoutConstraint* topConstraint = [NSLayoutConstraint constraintWithItem:setupView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    NSLayoutConstraint* leftConstraint = [NSLayoutConstraint constraintWithItem:setupView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
    NSLayoutConstraint* bottomConstraint = [NSLayoutConstraint constraintWithItem:setupView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
    NSLayoutConstraint* widthConstraint = [NSLayoutConstraint constraintWithItem:self.setupScreensViewController.pageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
    

    [superview addConstraints:@[topConstraint, leftConstraint, bottomConstraint, widthConstraint]];

    [self.backgroundImage.layer setZPosition:10];
    [self.contentView.layer setZPosition:20];

    //[superview setNeedsLayout:YES];

    [APPDELEGATE.mainSplitView setHidden:YES];
}


- (void)mouseDown:(NSEvent *)theEvent
{
    //don't pass this on to the underlying subviews...
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    //don't pass this on to the underlying subviews...
}

- (IBAction)nextButton:(id)sender
{
    if(![self.setupScreensViewController canGoForward])
    {
        [self removeFromSuperview];
        [WindowManager sharedInstance].setupViewController = nil;
        [APPDELEGATE.mainSplitView setHidden:NO];
    }

    [self.setupScreensViewController nextScreen];

    [self setCorrectButtonTitles];
}

- (IBAction)backButton:(id)sender
{
    if(![self.setupScreensViewController canGoBack])
    {
        [self removeFromSuperview];
        [WindowManager sharedInstance].setupViewController = nil;
        [APPDELEGATE.mainSplitView setHidden:NO];
    }

    [self.setupScreensViewController previousScreen];

    [self setCorrectButtonTitles];
}

- (void)setCorrectButtonTitles
{
    if([self.setupScreensViewController canGoUp])
    {
        [self.backButton setTitle:NSLocalizedString(@"Back", @"Back button")];
        [self.backButton setImage:[NSImage imageNamed:@"upButton"]];
        [self.nextButton setHidden:YES];
        return;
    }

    [self.nextButton setHidden:NO];

    if([self.setupScreensViewController canGoBack])
    {
        [self.backButton setTitle:NSLocalizedString(@"Back", @"Back button")];
        [self.backButton setImage:[NSImage imageNamed:@"backButton"]];
    }
    else
    {
        [self.backButton setTitle:[@" " stringByAppendingString:NSLocalizedString(@"Cancel", @"Cancel Button")]];
        [self.backButton setImage:[NSImage imageNamed:@"cancelButton"]];
    }

    if([self.setupScreensViewController canGoForward])
    {
        [self.nextButton setTitle:NSLocalizedString(@"Next", @"Next button")];
        [self.nextButton setImage:[NSImage imageNamed:@"nextButton"]];
    }
    else
    {
        [self.nextButton setTitle:NSLocalizedString(@"Done", @"Done button")];
        [self.nextButton setImage:[NSImage imageNamed:@"doneButton"]];
    }
}

@end
