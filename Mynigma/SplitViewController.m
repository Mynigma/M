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





#import "SplitViewController.h"
#import "AppDelegate.h"
#import "ComposeNewController.h"
#import "DisplayMessageController.h"
#import "SplitViewDelegate.h"
#import "DisplayMessageController.h"
#import "ViewControllersManager.h"
#import "SidePanelController.h"
#import "UserSettings+Category.h"
#import "AlertHelper.h"
#import "SelectionAndFilterHelper.h"



@interface SplitViewController ()

@end

@implementation SplitViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.showWelcomeScreenAfterAppearance = NO;
    self.completedInitialAppearance = NO;
}

- (void)viewDidLoad
{
    [self setPresentsWithGesture:YES];

    [super viewDidLoad];
    
    [[ViewControllersManager sharedInstance] setSplitViewController:self];
}


- (void)viewDidAppear:(BOOL)animated
{   
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    
    if(self.showWelcomeScreenAfterAppearance)
    {
        [AlertHelper showWelcomeSheet];
        
        self.showWelcomeScreenAfterAppearance = NO;
    }
    
    self.completedInitialAppearance = YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES; // support all types of orientation
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if([ViewControllersManager sharedInstance].composeController)
        [[ViewControllersManager sharedInstance].composeController didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}


- (IBAction)changeMessageListVisibility:(id)sender
{
    if([self respondsToSelector:@selector(displayMode)])
    {
        //iOS 8

        [UIView animateWithDuration:.3 animations:^{

            if(self.displayMode == UISplitViewControllerDisplayModePrimaryOverlay || self.displayMode == UISplitViewControllerDisplayModeAllVisible)
            {
                [self setPreferredDisplayMode:UISplitViewControllerDisplayModePrimaryHidden];
            }
            else
            {
                [self setPreferredDisplayMode:UISplitViewControllerDisplayModeAllVisible];
            }

            [[ViewControllersManager sharedInstance].displayMessageController adjustWidthIfNeededWithAnimations];
        }];
    }
    else
    {
        //iOS 7
        
        [[ViewControllersManager sharedInstance].displayMessageController adjustWidthIfNeededWithAnimations];
    }
}

- (UIViewController*)detailController
{
    UIViewController* viewController = self.viewControllers.lastObject;
    
    if([viewController isKindOfClass:[SidePanelController class]])
    {
        viewController = [(SidePanelController*)viewController centerPanel];
    }
    
    if([viewController isKindOfClass:[UINavigationController class]])
    {
        viewController = [(UINavigationController*)viewController topViewController];
    }
    
    return viewController;
}

- (IBAction)unwindToSplitViewController:(UIStoryboardSegue*)unwindSegue
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}

- (void)showWelcomeScreenWhenLoaded
{
    if([UserSettings currentUserSettings].accounts.count==0) //no IMAPAccountSetting present, so show the welcome screen
    {
        if(self.completedInitialAppearance)
            [AlertHelper showWelcomeSheet];
        else
            self.showWelcomeScreenAfterAppearance = YES;
    }
}
    
@end
