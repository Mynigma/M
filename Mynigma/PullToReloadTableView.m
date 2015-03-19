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





#import "PullToReloadTableView.h"
#import "PullToReloadViewController.h"
#import "ReloadingDelegate.h"



@implementation PullToReloadTableView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {

    }
    return self;
}

//- (void)scrollWheel:(NSEvent *)theEvent
//{
//    NSEventPhase phase = theEvent.phase;
//
//    if(phase & (NSEventPhaseCancelled | NSEventPhaseEnded))
//    {
//        PullToReloadViewController* viewController = [ReloadingDelegate reloadController];
//
//        if(viewController.reloadingView.circularProgressIndicator.isHidden)
//        {
//            [viewController scrollToTopAnimated:YES withCallback:nil];
//        }
//        else
//        {
//            [viewController scrollToActiveHeightAnimated:YES withCallback:nil];
//        }
//    }
//
//    [super scrollWheel:theEvent];
//}

- (NSRect)adjustScroll:(NSRect)proposedVisibleRect
{
    NSRect modifiedRect = [super adjustScroll:proposedVisibleRect];

    if(modifiedRect.origin.y<0 && modifiedRect.origin.y<previousScrollPoint)
    {
        modifiedRect.origin.y = +(modifiedRect.origin.y-previousScrollPoint)/3+previousScrollPoint;
    }

    previousScrollPoint = modifiedRect.origin.y;

    // return the modified rectangle
    return modifiedRect;
}


@end
