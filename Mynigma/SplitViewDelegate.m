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





#import "SplitViewDelegate.h"
#import "SplitViewController.h"
#import "ViewControllersManager.h"


@implementation SplitViewDelegate

#pragma mark - UISplitViewControllerDelegate

//- (UISplitViewControllerDisplayMode)targetDisplayModeForActionInSplitViewController:(UISplitViewController *)svc
//{
//    return UISplitViewControllerDisplayModePrimaryOverlay;
//}

#pragma mark - iOS 8 delegates

// Available from iOS 8
- (void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode
{
    if (![svc respondsToSelector:@selector(traitCollection)])
    {
        // this wont be called prior to iOS 8
    }
    
    else
        
    {
        if(svc.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular)
        {
            UIViewController* rightHandSideViewController = [svc.viewControllers.lastObject topViewController];
            
            UIBarButtonItem* backButton = [[rightHandSideViewController navigationItem] leftBarButtonItem];
            
            if(displayMode == UISplitViewControllerDisplayModePrimaryHidden)
            {
                [(backButton.customView).layer setTransform:CATransform3DMakeRotation(M_PI, 0, 0, 1)];
                
                [[ViewControllersManager sharedInstance].splitViewController setMasterViewWidth:0];
            }
            else
            {
                //enforce correct rotation direction by using 2*M_PI - epsilon
                [backButton.customView.layer setTransform:CATransform3DMakeRotation(2*M_PI-.000001, 0, 0, 1)];
                
                [[ViewControllersManager sharedInstance].splitViewController setMasterViewWidth:[svc.viewControllers.firstObject view].frame.size.width];
            }
            
            [[ViewControllersManager sharedInstance].splitViewController setDetailViewObscured:(displayMode == UISplitViewControllerDisplayModePrimaryOverlay)];
            [[ViewControllersManager sharedInstance].splitViewController setDetailViewSquashed:(displayMode == UISplitViewControllerDisplayModeAllVisible)];

        }

    }
}

#pragma mark - iOS 7 delegates

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    if(![viewController respondsToSelector:@selector(traitCollection)])
    {
    UIImage* image = [UIImage imageNamed:@"rightArrowHead"];
    
    //the image will be rendered in the tint colour whenever it is highlighted
    [barButtonItem setTintColor:[UIColor whiteColor]];
    
    [barButtonItem setImage:image];
    
    UIViewController* rightHandSideViewController = [splitController.viewControllers.lastObject topViewController];
    [rightHandSideViewController.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
        
    [[ViewControllersManager sharedInstance].splitViewController setMasterViewWidth:0];
        
        [[ViewControllersManager sharedInstance].splitViewController setDetailViewObscured:NO];
        [[ViewControllersManager sharedInstance].splitViewController setDetailViewSquashed:NO];
    }
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    if(![viewController respondsToSelector:@selector(traitCollection)])
    {
    UIViewController* rightHandSideViewController = [splitController.viewControllers.lastObject topViewController];
    [rightHandSideViewController.navigationItem setLeftBarButtonItem:nil animated:YES];
        
    [[ViewControllersManager sharedInstance].splitViewController setMasterViewWidth:[splitController.viewControllers.firstObject view].frame.size.width];
        
            [[ViewControllersManager sharedInstance].splitViewController setDetailViewObscured:YES];
            [[ViewControllersManager sharedInstance].splitViewController setDetailViewSquashed:NO];
    }
}


- (void)splitViewController:(UISplitViewController *)svc popoverController:(UIPopoverController *)pc willPresentViewController:(UIViewController *)aViewController
{
    //iOS 7
    
    [[ViewControllersManager sharedInstance].splitViewController setMasterViewWidth:[svc.viewControllers.firstObject view].frame.size.width];
}

@end
