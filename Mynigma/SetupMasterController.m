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





#import "SetupMasterController.h"

@interface SetupMasterController ()

@end

@implementation SetupMasterController

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

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    //[self scrollRight:nil];
}

//- (IBAction)scrollRight:(id)sender
//{
//    UIView *newView = [[[NSBundle mainBundle]
//                        loadNibNamed:@"Setup_1"
//                        owner:self options:nil]
//                       firstObject];
//
//    //    [UIView animateWithDuration:3 animations:^{
//    //        [self setView:newView];
//    //    }];
//
//    //     transitionWithView:newView duration:3 options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
//    //        <#code#>
//    //    } completion:<#^(BOOL finished)completion#>]
//
//    UIView* fromView = self.view.subviews[0];
//
//    [UIView transitionWithView:self.view
//                      duration:0.4
//                       options:UIViewAnimationOptionTransitionFlipFromLeft
//                    animations:^{
//                        [self setView:newView]; }
//                    completion:NULL];
//
//}
//
//- (IBAction)scrollLeft:(id)sender
//{
//
//}

@end
