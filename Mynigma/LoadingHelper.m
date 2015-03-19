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

#import "LoadingHelper.h"
#import "LoadingController.h"
#import "AppDelegate.h"



#define HAS_NO_VISUAL_EFFECT_VIEW NSClassFromString(@"UIVisualEffectView")==nil

static ConnectionObject* mainConnection;
//static BOOL hasBeenCancelled;



@implementation LoadingHelper


+ (instancetype)sharedInstance
{
    static dispatch_once_t p = 0;
    
    __strong static id sharedObject = nil;
    
    dispatch_once(&p, ^{
        sharedObject = [LoadingHelper new];
    });
    
    return sharedObject;
}



#pragma mark - Loading...


- (void)startLoading:(ConnectionObject*)connection
{
//    if(HAS_NO_VISUAL_EFFECT_VIEW)
//        return;
    
    if(mainConnection)
        return;
    
    mainConnection = connection;
//    hasBeenCancelled = NO;
    [self startLoading];
}

- (void)startLoading
{
    //if(HAS_NO_VISUAL_EFFECT_VIEW)
    //    return;
    
    [self setHasBeenCancelled:NO];
    
    NSString* controller = HAS_NO_VISUAL_EFFECT_VIEW?@"LoadingController2":@"LoadingController";
    
    self.loadingController = [[LoadingController alloc] initWithNibName:controller bundle:[NSBundle mainBundle]];
//    self.loadingController = [[LoadingController alloc] initWithNibName:UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"LoadingController_iPad" : @"LoadingController_iPhone" bundle:[NSBundle mainBundle]];
    
    UIViewController* topViewController = self.loadingController;
    
    [topViewController.view setFrame:[[UIScreen mainScreen] bounds]];
    
    [APPDELEGATE.window addSubview:topViewController.view];
}

- (void)stopLoading
{
//    if(HAS_NO_VISUAL_EFFECT_VIEW)
//        return;
    
    mainConnection = nil;
    NSArray* subviews = [APPDELEGATE.window subviews];
    if(subviews.count>0)
    {
        if(self.loadingController)
        {
            UIView* topMostView = [subviews objectAtIndex:subviews.count-1];
            if([topMostView isEqual:self.loadingController.view])
                [topMostView removeFromSuperview];
        }
        self.loadingController = nil;
    }
}

- (void)cancelLoading
{
//    if(HAS_NO_VISUAL_EFFECT_VIEW)
//        return;
    
    [self setHasBeenCancelled:YES];
//    hasBeenCancelled = YES;
//    
//    if(mainConnection)
//        [mainConnection cancelConnection];
    [self stopLoading];
}

@end
