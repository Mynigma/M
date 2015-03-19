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

#import "SetupFlowViewController.h"
#import "UIView+LayoutAdditions.h"
#import "SetupFlowPageController.h"
#import "SetupFlowPageControllerFirstInfo.h"
#import "ViewControllersManager.h"
#import "LoadingHelper.h"
#import "NSString+EmailAddresses.h"
#import "LoadingHelper.h"
#import "Setup_SeparateController.h"
#import "MovingPlaceholderTextField.h"




@implementation SetupFlowViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //load the pages from "SetupFlow.xib"
    UIStoryboard* setupFlowStoryboard = [ViewControllersManager setupFlowStoryboard];
    
    for(NSInteger index = 1; index <= 6; index++)
    {
        NSString* identifier = [NSString stringWithFormat:@"Page%ld", (long)index];
        
        UIViewController* loadedPageController = [setupFlowStoryboard instantiateViewControllerWithIdentifier:identifier];
        
        NSString* outletControllerName = [NSString stringWithFormat:@"page%ldController", (long)index];
        
        NSString* outletViewName = [NSString stringWithFormat:@"page%ld", (long)index];
        
        UIView* outletView = [self valueForKey:outletViewName];
        
        [self setValue:loadedPageController forKey:outletControllerName];
        
        [outletView addSubview:loadedPageController.view];
        
        if([loadedPageController respondsToSelector:@selector(setDataProvisionDelegate:)])
            [loadedPageController performSelector:@selector(setDataProvisionDelegate:) withObject:self];
        
        [loadedPageController.view setUpConstraintsToFitIntoSuperview];
        
    }
    
    
    self.numberOfDisplayedPages = 6;
    
    self.currentPage = 0;
    
    self.OAuthSkipped = NO;
    
    self.pageWidth = CGRectGetWidth(self.view.frame);
    
    [self hideAndRevealPages];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

- (IBAction)cancelButtonTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}




#pragma mark - Keyboard view adjustments

- (void)keyboardWillShow:(NSNotification *)sender
{
    CGRect frame = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    CGFloat animationDuration = [sender.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    UIViewAnimationCurve curve = [sender.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    CGRect newFrame = [self.view convertRect:frame fromView:[[UIApplication sharedApplication] delegate].window];
    
    [UIView animateWithDuration:animationDuration delay:0 options:(UIViewAnimationOptions)curve animations:^{
        
        self.bottomMarginConstraint.constant = newFrame.size.height;
        
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        
    } completion:nil];
}


- (void)keyboardWillHide:(NSNotification *)sender
{
    self.bottomMarginConstraint.constant = 0;
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}




- (void)showPage:(BOOL)showPage withIndex:(NSInteger)index
{
    NSString* outletName = [NSString stringWithFormat:@"page%ldController", (long)index];
    
    SetupFlowPageController* outletViewController = [self valueForKey:outletName];
    
    //this will also collapse the width by updating the constraint
    [outletViewController.view setHidden:showPage];
}





#pragma mark - Page control

- (NSInteger)pageControlIndexForPage:(NSInteger)page
{
    return page;
    
    //    switch(page)
    //    {
    //        case 0:
    //            return 0;
    //
    //        case 1:
    //        case 2:
    //            return 1;
    //
    //        case 3:
    //        case 4:
    //            return 2;
    //
    //        case 5:
    //            return 3;
    //
    //        default:
    //            return 4;
    //    }
}

- (NSInteger)pageForPageControlIndex:(NSInteger)pageControlIndex
{
    return pageControlIndex;
    
    //    switch(pageControlIndex)
    //    {
    //        case 0:
    //            return 0;
    //
    //        case 1:
    //            return 1;
    //
    //        case 2:
    //            return 3;
    //
    //        case 3:
    //            return 5;
    //
    //        default:
    //            return 6;
    //    }
}




#pragma mark - UIScrollViewDelegate


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.view.layer removeAllAnimations];
    //    NSLog(@"-> %ld", (long)self.currentPage);
    //    self.currentPage = (NSInteger)floor((scrollView.contentOffset.x - self.pageWidth / 2) / self.pageWidth) + 1;
    //    NSLog(@"<- %ld", (long)self.currentPage);
}


- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    //the animation time in seconds per pixel to be travelled
    CGFloat secondsPerPixel = 1/500.;

    NSInteger newPage = self.currentPage;
    
    if (fabs(velocity.x) < .5)
    {
        newPage = (NSInteger)floor((scrollView.contentOffset.x + self.pageWidth / 2) / self.pageWidth);
        
        if(newPage < 0)
            newPage = 0;
        
        if (newPage >= self.numberOfDisplayedPages)
            newPage = self.numberOfDisplayedPages - 1;
        
        *targetContentOffset = CGPointMake(newPage * self.pageWidth, targetContentOffset->y);
        
        self.currentPage = newPage;
        
        CGFloat yOffset = targetContentOffset->y;
        
        CGPoint newContentOffset = CGPointMake(newPage * self.pageWidth, yOffset);

        //adjust the animation time to the distance of travel
        CGFloat animationTime = secondsPerPixel * fabs(newContentOffset.x - scrollView.contentOffset.x);

        [UIView animateWithDuration:animationTime delay:0 options:0 animations:^{
            
            [scrollView setContentOffset:newContentOffset animated:NO];
            
            //fix the page control
            [UIView animateWithDuration:0 animations:^{
                
                [self.pageControl setNeedsLayout];
                [self.pageControl layoutIfNeeded];
                
                [self.exitButton setNeedsLayout];
                [self.exitButton layoutIfNeeded];
            }];
            
        } completion:^(BOOL completed){
            
            [scrollView setContentOffset:CGPointMake(newPage * self.pageWidth, yOffset)];
            
            [self activateFirstFieldIfApplicable];
            //        if(completed)
            //            self.currentPage = newPage;
        }];
        
        return;
    }
    else
    {
        newPage = velocity.x > 0 ? self.currentPage + 1 : self.currentPage - 1;
        
        if (newPage < 0)
            newPage = 0;
        if (newPage >= self.numberOfDisplayedPages)
            newPage = self.numberOfDisplayedPages - 1;
    }
    
    *targetContentOffset = scrollView.contentOffset; //CGPointMake(newPage * self.pageWidth, targetContentOffset->y);
    
    self.currentPage = newPage;
    
    CGFloat yOffset = targetContentOffset->y;

    CGPoint newContentOffset = CGPointMake(newPage * self.pageWidth, yOffset);

    //adjust the animation time to the distance of travel
    CGFloat animationTime = secondsPerPixel * fabs(newContentOffset.x - scrollView.contentOffset.x);
    
    [UIView animateWithDuration:animationTime delay:0 usingSpringWithDamping:.65 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        
        [scrollView setContentOffset:newContentOffset animated:NO];
        
        //fix the page control
        [UIView animateWithDuration:0 animations:^{
            
            [self.pageControl setNeedsLayout];
            [self.pageControl layoutIfNeeded];
            
            [self.exitButton setNeedsLayout];
            [self.exitButton layoutIfNeeded];
        }];
        
    } completion:^(BOOL completed){
        
        [scrollView setContentOffset:CGPointMake(newPage * self.pageWidth, yOffset)];
        
        [self activateFirstFieldIfApplicable];
        //        if(completed)
        //            self.currentPage = newPage;
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    //    float roundedValue = (NSInteger)floor((scrollView.contentOffset.x - self.pageWidth / 2) / self.pageWidth) + 1;
    //
    //    NSLog(@"-> %ld", (long)self.currentPage);
    //
    //    self.currentPage = roundedValue;
    //
    //    NSLog(@"<- %ld", (long)self.currentPage);
    
    self.pageControl.currentPage = [self pageControlIndexForPage:self.currentPage];
}




#pragma mark - IBActions

- (IBAction)valueChanged:(id)sender
{
    self.currentPage = [self pageForPageControlIndex:self.pageControl.currentPage];
    
    CGPoint newOffset = CGPointMake(self.currentPage * self.pageWidth, 0);
    
    [UIView animateWithDuration:1 delay:.0 usingSpringWithDamping:.75 initialSpringVelocity:.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        [self.scrollView setContentOffset:newOffset animated:NO];
        
        //fix the page control
        [UIView animateWithDuration:0 animations:^{
            
            [self.pageControl setNeedsLayout];
            [self.pageControl layoutIfNeeded];
            
            [self.exitButton setNeedsLayout];
            [self.exitButton layoutIfNeeded];
        }];
        
    } completion:^(BOOL finished){
        
        [self activateFirstFieldIfApplicable];
    }];
}



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

- (void)adjustAfterRotationWithDuration:(CGFloat)animationDuration
{
    CGPoint targetOffset = CGPointMake(self.currentPage * self.pageWidth, self.scrollView.contentOffset.y);

    [UIView animateWithDuration:animationDuration animations:^{

        [self.scrollView setContentOffset:targetOffset animated:NO];
    }];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    self.pageWidth = CGRectGetHeight(self.view.bounds);

    //this crashes on iOS7, for some reason
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
        [self adjustAfterRotationWithDuration:duration];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    self.pageWidth = CGRectGetHeight(self.view.bounds);

    [self adjustAfterRotationWithDuration:.3];
}


#pragma mark - Hiding and revealing pages

- (void)hideAndRevealPages
{
    //pages with indices 0 - 5 are always shown
    
    //    if ()
    //    {
    //
    //    }
    //    }
    //page with index 6 is shown iff OAuth shouldn't be used
    //page with index 7 is the opposite
    if([self.connectionItem.emailAddress isValidEmailAddress] && !self.connectionItem.canUseOAuth)
    {
        [self showPage:YES withIndex:7];
    }
    else
    {
        [self showPage:NO withIndex:7];
    }
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}







- (void)setSkipOAuth:(BOOL)skipOAuth
{
    [self setOAuthSkipped:skipOAuth];
    [self hideAndRevealPages];
}


- (void)moveToPage:(NSInteger)pageIndex
{
    [self hideAndRevealPages];
    [self setCurrentPage:pageIndex];
    [self valueChanged:nil];
}

- (void)doneEnteringSenderName
{
//    if([self.connectionItem.emailAddress isValidEmailAddress])
//    {
//        [[LoadingHelper sharedInstance] startLoading];
//        
//        [self.connectionItem lookForSettingsWithCallback:^{
//            
//            [[LoadingHelper sharedInstance] stopLoading];
//            
//            if([[LoadingHelper sharedInstance] hasBeenCancelled])
//                return;
//            
//            
//            BOOL canUseOAuth = [self.connectionItem canUseOAuth];
//            
//            // todo switch provider cases...
//            if(canUseOAuth)
//            {
//                NSString* incomingServer = [self.connectionItem incomingHost];
//                if ([incomingServer isEqual:@"imap.gmail.com"])
//                    [self launchGoogleOAuth];
//                else if ([incomingServer isEqual:@"imap-mail.outlook.com"])
//                    [self launchOutlookOAuth];
//                else if ([incomingServer isEqual:@"imap.mail.yahoo.com"] || [incomingServer isEqual:@"imap.mail.yahoo.co.jp"])
//                    [self launchYahooOAuth];
//            }
//            else
//                [self launchPasswordLogin];
    
//  UIViewController* presentingController = self.presentingViewController;
    
//    [self dismissViewControllerAnimated:NO completion:^{
    
    //don't proceed unless a sender name is entered
    if(!self.connectionItem.fullName.length)
        return;
    
    UINavigationController* navController = [self.storyboard instantiateViewControllerWithIdentifier:@"setupSeparateController"];
    
    Setup_SeparateController* setupController = (Setup_SeparateController*)navController.topViewController;
    
    (void)setupController.view;
    
    [setupController updateFieldValuesWithConnectionItem:self.connectionItem];
    
    [self presentViewController:navController animated:YES completion:nil];
    
//    }];

//
//            [[LoadingHelper sharedInstance] stopLoading];
//        }];
//    }
}

- (void)changedName:(NSString*)name
{
    //update the connectionItem
    self.connectionItem = [ConnectionItem new];
    [self.connectionItem setFullName:name];
}

- (ConnectionItem*)getConnectionItem
{
    return self.connectionItem;
}


- (void)launchPasswordLogin
{
    UINavigationController* navController = [self.storyboard instantiateViewControllerWithIdentifier:@"setupSeparateController"];

    Setup_SeparateController* setupController = (Setup_SeparateController*)navController.topViewController;

    (void)setupController.view;
    
    [setupController updateFieldValuesWithConnectionItem:self.connectionItem];
    
    [self presentViewController:navController animated:YES completion:nil];
}




- (void)activateFirstFieldIfApplicable
{
//    NSInteger index = self.currentPage+1;
//    
//    NSString* outletName = [NSString stringWithFormat:@"page%ldController", (long)index];
//    
//    SetupFlowPageController* outletViewController = [self valueForKey:outletName];
//    
//    if([outletViewController isKindOfClass:[SetupFlowPageControllerFirstInfo class]])
//    {
//        [[(SetupFlowPageControllerFirstInfo*)outletViewController senderNameTextField] becomeFirstResponder];
//    }
}


@end
