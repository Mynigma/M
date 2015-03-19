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





#import "ViewControllersManager.h"
#import "MoveMessageViewController.h"
#import "UIView+LayoutAdditions.h"
#import "AppDelegate.h"
#import "SelectionAndFilterHelper.h"
#import "JASidePanelController.h"





@implementation ViewControllersManager

+ (instancetype)sharedInstance
{
    static dispatch_once_t p = 0;

    __strong static id sharedObject = nil;

    dispatch_once(&p, ^{
        sharedObject = [self new];
    });

    return sharedObject;
}


- (void)feedbackButton:(id)sender
{
    [self.messagesController performSegueWithIdentifier:@"compo seFeedback" sender:sender];
}

+ (void)showMoveMessageOptions
{
    MoveMessageViewController* moveController = [ViewControllersManager sharedInstance].moveMessageViewController;

    if(moveController)
        return;

    MoveMessageViewController* moveMessageViewController = [MoveMessageViewController new];

    [ViewControllersManager sharedInstance].moveMessageViewController = moveMessageViewController;

    moveMessageViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    moveMessageViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

    //    [viewController.view addSubview:_moveMessageViewController.view];
    //
    //    [_moveMessageViewController.view setUpConstraintsToFitIntoSuperview];
    //
    //    [viewController.view setNeedsLayout];
    //    [viewController.view layoutIfNeeded];

    //    [viewController showDetailViewController:_moveMessageViewController sender:self];
    //    viewController.modalPresentationStyle = UIModalPresentationCurrentContext;

    UIViewController* detailController = [[[ViewControllersManager sharedInstance] splitViewController] detailController];
    [detailController presentViewController:moveMessageViewController animated:YES completion:^{
        //        UIView* view = moveMessageViewController.view;

    }];

    if(![ViewControllersManager isHorizontallyCompact])
    {
//        [[ViewControllersManager sharedInstance].messagesController setEditing:YES animated:YES];

        [[ViewControllersManager sharedInstance].messagesController selectMessageInstances:[SelectionAndFilterHelper selectedMessages]];
    }

    //     presentModalViewController:_moveMessageViewController animated:YES];
}

+ (void)removeMoveMessageOptionsIfNecessary
{
    MoveMessageViewController* moveController = [ViewControllersManager sharedInstance].moveMessageViewController;
    if(moveController)
    {
        [moveController dismissViewControllerAnimated:YES completion:nil];

        [ViewControllersManager sharedInstance].moveMessageViewController = nil;

        if([ViewControllersManager sharedInstance].messagesController.isEditing)
            [[ViewControllersManager sharedInstance].messagesController setEditing:NO animated:YES];
    }
}

+ (BOOL)isShowingMoveMessageOptions
{
    return [ViewControllersManager sharedInstance].moveMessageViewController != nil;
}


+ (void)adjustMoveMessageOptions
{
    CGFloat horizontalAdjustment = ([[ViewControllersManager sharedInstance].splitViewController detailViewObscured])?[[ViewControllersManager sharedInstance].splitViewController masterViewWidth]/2:0;

    [[[self sharedInstance] moveMessageViewController].contentViewController.horizontalCenterConstraint setConstant:-horizontalAdjustment];
}

+ (BOOL)isHorizontallyCompact
{
    if([APPDELEGATE.window respondsToSelector:@selector(traitCollection)])
    {
        return APPDELEGATE.window.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact;
    }
    else
    {
        return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone);
    }
}

+ (BOOL)canDoPopovers
{
    if(RUNNING_AT_LEAST_IOS8)
        return YES;
    
    //must be iOS 7
    //popovers are disabled on the iPhone
    return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
}


#pragma mark - Side panel (accounts & folders list)

+ (BOOL)isSidePanelShown
{
    NSArray* viewControllers = [[ViewControllersManager sharedInstance].splitViewController viewControllers];
    
    UIViewController* masterController = [viewControllers firstObject];
    
    return [(JASidePanelController*)masterController state] == JASidePanelLeftVisible;
}

+ (void)toggleSidePanel
{
    NSArray* viewControllers = [[ViewControllersManager sharedInstance].splitViewController viewControllers];

    UIViewController* masterController = [viewControllers firstObject];

    if([masterController respondsToSelector:@selector(toggleLeftPanel:)])
        [(JASidePanelController*)masterController toggleLeftPanel:self];
}


+ (void)showSidePanel
{
    NSArray* viewControllers = [[ViewControllersManager sharedInstance].splitViewController viewControllers];

    UIViewController* masterController = [viewControllers firstObject];

    if([masterController respondsToSelector:@selector(toggleLeftPanel:)])
        [(JASidePanelController*)masterController showLeftPanelAnimated:YES];
}

+ (void)hideSidePanel
{
    if([ViewControllersManager sharedInstance].splitViewController)
    {
    NSArray* viewControllers = [[ViewControllersManager sharedInstance].splitViewController viewControllers];

    UIViewController* masterController = [viewControllers firstObject];

    if([masterController respondsToSelector:@selector(showCenterPanelAnimated:)])
        [(JASidePanelController*)masterController showCenterPanelAnimated:YES];
    }
    else
    {
        //iOS 7 (iPhone)
        SidePanelController* sidePanelController = [ViewControllersManager sharedInstance].sidePanelController;
        if([sidePanelController respondsToSelector:@selector(showCenterPanelAnimated:)])
            [sidePanelController showCenterPanelAnimated:YES];
    }
}

#pragma mark - Storyboards

+ (UIStoryboard*)menuStoryboard
{
    return [UIStoryboard storyboardWithName:@"SettingsMenu" bundle:nil];
}


+ (UIStoryboard*)setupFlowStoryboard
{
    return [UIStoryboard storyboardWithName:@"SetupFlow" bundle:nil];
}

+ (UIStoryboard*)mainStoryboard
{
    return [UIStoryboard storyboardWithName:@"Main_Universal" bundle:nil];
}



@end
