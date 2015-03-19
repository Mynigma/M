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





#import "PullToReloadClipView.h"
#import "ReloadingView.h"
#import "AppDelegate.h"
#import "ReloadViewController.h"
#import "MessageListController.h"
#import "MessagesTable.h"
#import "PullToReloadViewController.h"
#import "ReloadingDelegate.h"


@implementation PullToReloadClipView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.

    }
    return self;
}


- (void)setDocumentView:(NSView *)aView
{
    [super setDocumentView:aView];

    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_8)
    {
        [self addReloadingView];
    }
}

- (BOOL)isFlipped
{
	return YES;
}

- (void)addReloadingView
{
    PullToReloadViewController* reloadController = [ReloadingDelegate reloadController];

    ReloadingView* reloadingView = reloadController.reloadingView;

    [reloadController loadView];

    NSScrollView* scrollView = (NSScrollView*)self.superview;

    //first remove any previous observers set
    [[NSNotificationCenter defaultCenter] removeObserver:reloadController];

    //now observe the scroll - the notfication is available from Mac OS 10.9 onwards
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_8)
    {

    [[NSNotificationCenter defaultCenter] addObserver:reloadController selector:@selector(didScroll:) name:NSScrollViewDidLiveScrollNotification object:scrollView];

    [[NSNotificationCenter defaultCenter] addObserver:reloadController selector:@selector(didEndScroll:) name:NSScrollViewDidEndLiveScrollNotification object:scrollView];

    }

    NSView* containerView = self;

    if(![[containerView subviews] containsObject:reloadingView])
    {
        [containerView addSubview:reloadingView];

        [reloadingView setTranslatesAutoresizingMaskIntoConstraints:NO];

        NSLayoutConstraint* leftConstraint = [NSLayoutConstraint constraintWithItem:containerView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:reloadingView attribute:NSLayoutAttributeLeft multiplier:1 constant:0];

        NSLayoutConstraint* topConstraint = [NSLayoutConstraint constraintWithItem:containerView  attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:reloadingView attribute:NSLayoutAttributeBottom multiplier:1 constant:0];

        NSLayoutConstraint* rightConstraint = [NSLayoutConstraint constraintWithItem:containerView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:reloadingView attribute:NSLayoutAttributeRight multiplier:1 constant:0];

        //if(reloadingView.constraints.count>0)
        //    [reloadingView removeConstraints:reloadingView.constraints];

        [containerView addConstraints:@[leftConstraint, topConstraint, rightConstraint]];
    }

    //if([scrollView.subviews containsObject:self.documentView])
    //    [self.documentView removeFromSuperview];

    //[self addSubview:self.documentView positioned:NSWindowAbove relativeTo:nil];
}

- (NSRect)documentRect
{
	NSRect superDocumentRect = [super documentRect];

    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_8)
    {
        superDocumentRect.origin.y -= TOTAL_PULL_HEIGHT;
        superDocumentRect.size.height += TOTAL_PULL_HEIGHT;

        //this doesn't seem to be necessary
//        if(superDocumentRect.size.height < self.frame.size.height + TOTAL_PULL_HEIGHT)
//            superDocumentRect.size.height = self.frame.size.height + TOTAL_PULL_HEIGHT;
    }

    return superDocumentRect;
}

//- (void)setBoundsOrigin:(NSPoint)newOrigin
//{
//    newOrigin.y = -200;
//
//    [super setBoundsOrigin:newOrigin];
//}

//- (void)setFrameOrigin:(NSPoint)newOrigin
//{
//    newOrigin.y = -200;
//
//    [super setFrameOrigin:newOrigin];
//}


- (NSInteger)indexFromPoint:(NSPoint)point
{
    //0 -> 0

    //-ACTIVE_RELOAD_HEIGHT -> 11

    //-TOTAL_RELOAD_HEIGHT -> 12

    NSInteger index = point.y/(-ACTIVE_RELOAD_HEIGHT)*11;

    //last notch should take much longer

    NSInteger triggerPoint = -TOTAL_PULL_HEIGHT/(-1.*ACTIVE_RELOAD_HEIGHT)*11;

    if(index>11 && index<triggerPoint)
        index = 11;

    return index;
}

- (void)scrollToPoint:(NSPoint)newOrigin
{
    //NSLog(@"Scroll to point: %f", newOrigin.y);

    //0 -> 12

    //36 -> 11

    //72 -> 0

    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_8)
    {
        NSInteger index = [self indexFromPoint:newOrigin];

        if([ReloadingDelegate reloadController].isCurrentlyReloading)
        {

        }
        else if([[ReloadingDelegate reloadController] shouldReload])
        {
            if(index>=12)
            {
                NSSound* sound = [NSSound soundNamed:@"startReloadingNew.mp3"];

                [sound play];
                
                [ReloadingDelegate startNewLoad];
            }
            else
            {
                [ReloadingDelegate pullWithIndex:index];
            }
        }
    }

    [super scrollToPoint:newOrigin];
}

- (NSPoint)constrainScrollPoint:(NSPoint)proposedNewOrigin {

//    if(![ReloadingDelegate reloadController].isScrolledToTop && proposedNewOrigin.y<0)
//    {
//        proposedNewOrigin.y = 0;
//
//        return proposedNewOrigin;
//    }

    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_8)
    {

    if(proposedNewOrigin.y<-TOTAL_PULL_HEIGHT)
    {
        proposedNewOrigin.y = -TOTAL_PULL_HEIGHT;

        return proposedNewOrigin;
    }

    if(proposedNewOrigin.y<0)
    {
        return proposedNewOrigin;
    }
        
    }

    proposedNewOrigin = [super constrainScrollPoint:proposedNewOrigin];

//    if(!APPDELEGATE.reloadViewController.canReload)
//    {
//        if(proposedNewOrigin.y < RELOAD_HEIGHT_LARGE)
//        {
//            if(![APPDELEGATE.reloadViewController isScrolling])
//                proposedNewOrigin.y = RELOAD_HEIGHT_LARGE;
//        }
//
//        return proposedNewOrigin;
//    }
//
//
//
//    if([APPDELEGATE.reloadViewController showSmallHeight])
//    {
//        //if(proposedNewOrigin.y < 0)
//        //    proposedNewOrigin.y = 0;
//    }
//    else
//    {
//        if(proposedNewOrigin.y < RELOAD_HEIGHT_LARGE)
//        {
//            if(![APPDELEGATE.reloadViewController isScrolling])
//                proposedNewOrigin.y = RELOAD_HEIGHT_LARGE;
//        }
//    }

	return proposedNewOrigin;
}

//
//- (void)scrollWheel:(NSEvent *)theEvent
//{
//    const NSEventPhase eventPhase = theEvent.phase;
//
//    if(eventPhase & (NSEventPhaseEnded | NSEventPhaseCancelled))
//    {
//        [APPDELEGATE.reloadViewController resetScrollPointAnimated:YES withCallback:^{
//             APPDELEGATE.reloadViewController.isScrolling = NO;
//        }];
//    }
//    else
//        APPDELEGATE.reloadViewController.isScrolling = YES;
//
//    [super scrollWheel:theEvent];
//}



@end