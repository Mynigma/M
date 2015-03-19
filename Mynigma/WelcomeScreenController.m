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



#import "WelcomeScreenController.h"
//#import "SetupMasterController.h"


@interface WelcomeScreenController ()

@property CGFloat pageWidth;

@end

@implementation WelcomeScreenController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    //hide the status bar
//    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
//
//    UIView* contentView = [[[NSBundle mainBundle] loadNibNamed:@"SetupFlow" owner:self options:nil] lastObject];
//
//    [contentView setBackgroundColor:[UIColor clearColor]];
//
//    [self.scrollView addSubview:contentView];
//
//    UIView* singleSheet = contentView.subviews.firstObject;
//
//    [contentView setTranslatesAutoresizingMaskIntoConstraints:NO];
//
//    NSLayoutConstraint* contentWidthConstraint = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:singleSheet attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
//
//    NSLayoutConstraint* contentHeightConstraint = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:singleSheet attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
//
//    [self.containerView.superview addConstraints:@[contentWidthConstraint, contentHeightConstraint]];
//
//
//    NSLayoutConstraint* topConstraint = [NSLayoutConstraint constraintWithItem:self.scrollView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeTop multiplier:1 constant:0];
//
//    NSLayoutConstraint* rightConstraint = [NSLayoutConstraint constraintWithItem:self.scrollView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeRight multiplier:1 constant:0];
//
//    NSLayoutConstraint* bottomConstraint = [NSLayoutConstraint constraintWithItem:self.scrollView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
//
//    NSLayoutConstraint* leftConstraint = [NSLayoutConstraint constraintWithItem:self.scrollView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
//
//    [self.scrollView addConstraints:@[topConstraint, rightConstraint, bottomConstraint, leftConstraint]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];

    CGFloat currentWidth = CGRectGetWidth(self.view.frame);

    self.pageWidth = currentWidth;
}



- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
//    if([segue.destinationViewController isKindOfClass:[SetupMasterController class]])
//    {
//        [self setContainerViewController:segue.destinationViewController];
//    }

    [super prepareForSegue:segue sender:sender];
}



- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
//    if(scrollView.contentOffset.x - 10 > (self.pageControl.numberOfPages - 1)*scrollView.frame.size.width)
//    {
//        [self performSegueWithIdentifier:@"loginScreenSegue" sender:self];
//        return;
//    }

    float roundedValue = round(scrollView.contentOffset.x / self.pageWidth);

    self.pageControl.currentPage = roundedValue;
}

- (IBAction)valueChanged:(id)sender
{
    CGPoint newOffset = CGPointMake(self.pageControl.currentPage*self.scrollView.frame.size.width, 0);

    [UIView animateWithDuration:1 delay:.0 usingSpringWithDamping:.75 initialSpringVelocity:.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{

        [self.scrollView setContentOffset:newOffset animated:NO];

    } completion:nil];
}



#pragma mark - IBActions

- (IBAction)handleTap:(id)sender
{
    [self.view endEditing:YES];
}



#pragma mark - Status bar

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}



#pragma mark - Rotation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    //TO DO: fix bug on iPhone - rotation over the top causes incorrect page snap because upside down orientation is not supported

    CGFloat currentWidth = CGRectGetWidth(self.view.frame);

    CGFloat newWidth = CGRectGetHeight(self.view.frame);

    CGPoint offset = self.scrollView.contentOffset;

    offset.x *= newWidth / currentWidth;

    self.pageWidth = newWidth;

    [UIView animateWithDuration:duration animations:^{

        [self.scrollView setContentOffset:offset animated:NO];

    }];
}


@end
