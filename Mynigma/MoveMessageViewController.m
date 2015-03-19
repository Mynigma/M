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

#import "MoveMessageViewController.h"
#import "MoveMessageImageView.h"
#import "UIView+LayoutAdditions.h"
#import "MoveMessageContentViewController.h"





@interface MoveMessageViewController ()

@end

@implementation MoveMessageViewController

- (void)viewDidLoad
{
    MoveMessageContentViewController* viewController = [[MoveMessageContentViewController alloc] initWithNibName:@"MoveMessageOptionsView" bundle:nil];
    
    self.contentViewController = viewController;
    
    UIView* superview = self.view;
    
    if(NSClassFromString(@"UIVisualEffectView"))
    {
        UIVisualEffect* blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        
        UIVisualEffectView* visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        
        [self.view addSubview:visualEffectView];
        [visualEffectView setUpConstraintsToFitIntoSuperview];

        superview = visualEffectView.contentView;
    }
    
    [superview addSubview:viewController.view];

    [viewController.view setUserInteractionEnabled:YES];
    
    [viewController.view setUpConstraintsToFitIntoSuperview];
    
    [self.view setBackgroundColor:[UIColor clearColor]];

    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}


- (void)selectionDidChange
{
    [self.contentViewController selectionDidChange];
}

@end
