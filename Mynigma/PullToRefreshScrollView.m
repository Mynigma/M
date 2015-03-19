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





#import "PullToRefreshScrollView.h"
#import "AppDelegate.h"
#import "ReloadViewController.h"
#import "PullToReloadClipView.h"
#import "ReloadingView.h"



@implementation PullToRefreshScrollView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

NSComparisonResult compareSubviews(NSView* view1, NSView* view2, void* context)
{
    if([view1 isKindOfClass:[ReloadingView class]])
        return NSOrderedAscending;

    if([view2 isKindOfClass:[ReloadingView class]])
        return NSOrderedDescending;

    return NSOrderedAscending;
}

- (void)addSubview:(NSView *)aView
{
    [super addSubview:aView];

//    [self sortSubviewsUsingFunction:compareSubviews context:nil];
//
//    NSLog(@"Subviews: %@", self.subviews);
}


@end