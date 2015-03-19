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





#import "PullToReloadViewController.h"
#import "ReloadingView.h"
#import "OutlineObject.h"
#import "IMAPFolderSetting+Category.h"
#import "IMAPAccountSetting+Category.h"
#import "AppDelegate.h"

#import "IMAPAccount.h"



@interface PullToReloadViewController ()

@end

@implementation PullToReloadViewController

- (instancetype)init
{
    self = [super initWithNibName:@"PullToReloadViewController" bundle:nil];
    if (self) {
        _reloadingView = (ReloadingView*)self.view;
        [_reloadingView.circularProgressIndicator setUsesThreadedAnimation:YES];
        _isInErrorState = NO;
        _isScrolledToTop = NO;
        _canReload = YES;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSLog(@"PullToReloadViewController loaded with initWithNibName - use init instead(!)");

    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)scrollToTopAnimated:(BOOL)animated withCallback:(void(^)(void))callback
{
    //don't scroll if the reloading view is not actually shown
    NSPoint currentScrollPoint = APPDELEGATE.messagesTable.enclosingScrollView.documentVisibleRect.origin;

    if(currentScrollPoint.y>=0)
    {
        if(callback)
            callback();
        return;
    }

    NSPoint newPoint = NSMakePoint(0, 0);

    //[APPDELEGATE.messagesTable.enclosingScrollView ]

    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:animated?.4:0];

    if(callback)
    {
        [[NSAnimationContext currentContext] setCompletionHandler:^{
            callback();
        }];
    }

    [[APPDELEGATE.messagesTable.superview animator] setBoundsOrigin:newPoint];
    [APPDELEGATE.messagesTable.enclosingScrollView reflectScrolledClipView:(NSClipView*)APPDELEGATE.messagesTable.superview];

    [NSAnimationContext endGrouping];
}

- (void)scrollToActiveHeightAnimated:(BOOL)animated withCallback:(void(^)(void))callback
{
    //don't scroll if the reloading view is not actually shown
    NSPoint currentScrollPoint = APPDELEGATE.messagesTable.enclosingScrollView.documentVisibleRect.origin;

    if(currentScrollPoint.y>=0)
        return;
    
    NSPoint newPoint = NSMakePoint(0, - ACTIVE_RELOAD_HEIGHT);

    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:animated?.6:0];

    if(callback)
    {
        [[NSAnimationContext currentContext] setCompletionHandler:^{
            callback();
        }];
    }

    [[APPDELEGATE.messagesTable.superview animator] setBoundsOrigin:newPoint];
    [APPDELEGATE.messagesTable.enclosingScrollView reflectScrolledClipView:(NSClipView*)APPDELEGATE.messagesTable.superview];

    [NSAnimationContext endGrouping];
}


- (void)startReloadingAnimated:(BOOL)animated withCallback:(void(^)(void))callback
{
    [self setIsInErrorState:NO];

    [self setAlreadyReloadedOnThisScroll:YES];

    [self scrollToActiveHeightAnimated:animated withCallback:callback];
}



- (void)stopReloadingAndScrollOutOfViewAnimated:(BOOL)animated withCallback:(void(^)(void))callback
{
    if(self.hideTimer)
    {
        [self.hideTimer invalidate];
        self.hideTimer = nil;
    }

    [self setCanReload:YES];

    [self scrollToTopAnimated:animated withCallback:^{

        [self setIsInErrorState:NO];


        [self doneReloading];

        if(callback)
            callback();
    }];
}



- (void)resetScrollPointAnimated:(BOOL)animated withCallback:(void(^)(void))callback
{
    if(self.reloadingView.circularProgressIndicator.isHidden)
    {
        if(self.isInErrorState)
            return;

        [self scrollToTopAnimated:animated withCallback:callback];
    }
    else
    {
        CGFloat currentScrollPosition = APPDELEGATE.messagesTable.enclosingScrollView.documentVisibleRect.origin.y;

        if(currentScrollPosition < - ACTIVE_RELOAD_HEIGHT)
            [self scrollToActiveHeightAnimated:animated withCallback:callback];
    }
}


- (void)showErrorWithFeedback:(NSString*)feedbackString
{
    NSSound* sound = [NSSound soundNamed:@"errorLoadingNew.m4a"];

    [sound play];

    [self setIsInErrorState:YES];

    NSImage* image = [NSImage imageNamed:@"darkGreyCross.png"];

    [self.reloadingView.progressImageView setImage:image];

    [self.reloadingView.progressImageView setHidden:NO];

    [self.reloadingView.circularProgressIndicator setHidden:YES];

    [self.reloadingView.feedbackLabel setStringValue:feedbackString];
}


- (void)showSuccessWithFeedback:(NSString*)feedbackString
{
    NSSound* sound = [NSSound soundNamed:@"successfulLoadNew.m4a"];

    [sound play];
    
    //show the check mark
    NSImage* image = [NSImage imageNamed:@"darkGreyCheck.png"];

    [self.reloadingView.progressImageView setImage:image];

    [self.reloadingView.progressImageView setHidden:NO];

    [self.reloadingView.circularProgressIndicator setHidden:YES];

    [self.reloadingView.feedbackLabel setStringValue:feedbackString];

    [self.reloadingView setNeedsDisplay:YES];

    [self hideAnimated:YES inSeconds:1];
}

- (void)timerFired:(NSTimer*)theTimer
{
    NSDictionary* userInfo = theTimer.userInfo;

    NSNumber* animated = [userInfo objectForKey:@"animated"];

    [self stopReloadingAndScrollOutOfViewAnimated:animated.boolValue withCallback:^{

        //superluous: already called by stopReloadingAndScroll...
        //[self doneReloading];
    }];

    self.hideTimer = nil;
}


- (void)hideAnimated:(BOOL)animated inSeconds:(NSTimeInterval)seconds
{
    self.hideTimer = [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(timerFired:) userInfo:@{@"animated":@(animated)} repeats:NO];
}

- (void)showActiveWithFeedback:(NSString*)feedbackString
{
    [self setAlreadyReloadedOnThisScroll:YES];

    [self.reloadingView.progressImageView setHidden:YES];

    [self.reloadingView.circularProgressIndicator setHidden:NO];

    [self.reloadingView.circularProgressIndicator startAnimation:nil];

    [self.reloadingView.feedbackLabel setStringValue:feedbackString];

    [self.reloadingView setNeedsDisplay:YES];
}

- (void)showEmptyWithFeedback:(NSString*)feedbackString
{
    [self setCanReload:NO];

    NSImage* image = [NSImage imageNamed:@"darkGreyCross.png"];

    [self.reloadingView.progressImageView setImage:image];

    [self.reloadingView.progressImageView setHidden:NO];

    [self.reloadingView.circularProgressIndicator setHidden:YES];

    [self.reloadingView.feedbackLabel setStringValue:feedbackString];
}


- (void)showPullWithFeedback:(NSString*)feedbackString withIndex:(NSInteger)pullIndex
{
    if(!self.canReload)
        return;

    if(!self.reloadingView.circularProgressIndicator.isHidden)
        return;

    if(self.isInErrorState && pullIndex<12)
        return;

    if(pullIndex<1)
        pullIndex = 1;

    if(pullIndex>12)
    {
        pullIndex = 12;
    }

    NSString* imageFileName = [NSString stringWithFormat:@"progress%lu.png", (long)pullIndex];

    NSImage* image = [NSImage imageNamed:imageFileName];

    if(pullIndex>=1)
    {
        [self.reloadingView.progressImageView setImage:image];
    }

    [self.reloadingView.progressImageView setHidden:NO];

    [self.reloadingView.circularProgressIndicator setHidden:YES];

    [self.reloadingView.feedbackLabel setStringValue:feedbackString];
}


- (void)didScroll:(NSNotification*)notification
{

}

- (void)didEndScroll:(NSNotification*)notification
{
    [self setAlreadyReloadedOnThisScroll:NO];

    //first check that the scroll view is showing at least part of the reload view
    //if so, adjust the scroll point

    NSScrollView* scrollView = (NSScrollView*)notification.object;

    if(![scrollView isKindOfClass:[NSScrollView class]])
        return;

    CGFloat currentScrollPosition = scrollView.documentVisibleRect.origin.y;

    if(currentScrollPosition<0)
    {
        [self resetScrollPointAnimated:YES withCallback:nil];
    }

    if(currentScrollPosition<=0)
    {
        [self setIsScrolledToTop:YES];
    }
    else
    {
        [self setIsScrolledToTop:NO];
    }
}

- (BOOL)isCurrentlyReloading
{
    return !self.reloadingView.circularProgressIndicator.isHidden;
}

- (void)doneReloading
{
    [self.reloadingView.circularProgressIndicator setHidden:YES];
    [self.reloadingView.progressImageView setHidden:NO];
}

- (BOOL)shouldReload
{
    return (self.canReload && !self.alreadyReloadedOnThisScroll);
}



@end
