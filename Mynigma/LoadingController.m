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

#import "LoadingController.h"
#import "AppDelegate.h"
#import "LoadingHelper.h"




@interface LoadingController ()

@end

@implementation LoadingController

@synthesize centerView;

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

    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged:)  name:UIDeviceOrientationDidChangeNotification  object:nil];

    centerView.layer.cornerRadius = 10;
    centerView.layer.masksToBounds = YES;
    // Do any additional setup after loading the view from its nib.

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
//    [self correctRotation];
}

//"correct" is a verb in this case
- (void)correctRotation
{
    CGFloat rotationAngle = 0;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation==UIInterfaceOrientationLandscapeLeft)
        rotationAngle = 3*M_PI_2;
    if(orientation==UIInterfaceOrientationPortraitUpsideDown)
        rotationAngle = M_PI;
    if(orientation==UIInterfaceOrientationLandscapeRight)
        rotationAngle = M_PI_2;

    CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(rotationAngle);
    [centerView setTransform:rotationTransform];

}

//orientation has changed? rotate the view!
- (void)orientationChanged:(NSNotification*)notification
{
    [self correctRotation];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//the user has opted to cancel the connection instead of waiting for it to finish...
- (void)cancelButtonHit:(id)sender
{
    [[LoadingHelper sharedInstance] cancelLoading];
}

@end
