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





#import "WindowManager.h"
#import "ComposeWindowController.h"
#import "SeparateViewerWindowController.h"
#import "InvitationWindowController.h"
#import "AlertHelper.h"
#import "AppDelegate.h"
#import "GTMOAuth2WindowController.h"
#import "OAuthHelper.h"




//keep a strong reference to all currently displayed windows so they don't disappear on disallocation
static NSMutableSet* setOfShownWindows;



@implementation WindowManager

+ (instancetype)sharedInstance
{
    static dispatch_once_t p = 0;

    __strong static id sharedObject = nil;

    dispatch_once(&p, ^{
        sharedObject = [self new];
    });

    return sharedObject;
}


+ (NSMutableSet*)shownWindows
{
    if(!setOfShownWindows)
        setOfShownWindows = [NSMutableSet new];

    return setOfShownWindows;
}


+ (void)showNewMessageWindowWithRecipient:(EmailRecipient*)emailRecipient
{
    ComposeWindowController* composeController = [[ComposeWindowController alloc] initWithWindowNibName:@"ComposeWindowController"];

    [composeController showWindow:self];

    [composeController showFreshMessageToEmailRecipient:emailRecipient];

    [self.shownWindows addObject:composeController];
}

+ (void)showMessageWindowWithRecipients:(NSArray*)emailRecipients subject:(NSString*)subject body:(NSString*)bodyString
{
    ComposeWindowController* composeController = [[ComposeWindowController alloc] initWithWindowNibName:@"ComposeWindowController"];

    [composeController showWindow:self];

    [composeController showFreshMessageToRecipients:emailRecipients withSubject:subject body:bodyString];

    [self.shownWindows addObject:composeController];
}


+ (void)showNewMessageWindow
{
    ComposeWindowController* composeController = [[ComposeWindowController alloc] initWithWindowNibName:@"ComposeWindowController"];

    [composeController showWindow:self];

    [composeController showFreshEmptyMessage];

    [self.shownWindows addObject:composeController];
}

+ (ComposeWindowController*)showFreshMessageWindow
{
    ComposeWindowController* composeController = [[ComposeWindowController alloc] initWithWindowNibName:@"ComposeWindowController"];

    [composeController showWindow:self];

    [self.shownWindows addObject:composeController];

    return composeController;
}

+ (ComposeWindowController*)showInvitationMessageForRecipients:(NSArray*)emailRecipients style:(NSString*)styleString
{
    ComposeWindowController* composeController = [[ComposeWindowController alloc] initWithWindowNibName:@"ComposeWindowController"];

    [composeController showWindow:self];

    [composeController showInvitationMessageForRecipients:emailRecipients style:styleString];

    [self.shownWindows addObject:composeController];

    return composeController;
}

+ (ComposeWindowController*)showInvitationMessageForEmailRecipient:(EmailRecipient*)emailRecipient
{
    [AlertHelper showInvitationSheet];

    [(InvitationWindowController*)[AlertHelper sharedInstance].sheetController selectEmailRecipient:emailRecipient];

    return nil;
}

+ (SeparateViewerWindowController*)openMessageInstanceInWindow:(EmailMessageInstance*)messageInstance
{
    [ThreadHelper ensureMainThread];

    SeparateViewerWindowController* viewerController = [[SeparateViewerWindowController alloc] initWithWindowNibName:@"SeparateViewerWindowController"];
    [viewerController showWindow:self];
    [viewerController showMessageInstance:messageInstance];
    [self.shownWindows addObject:viewerController];
    return viewerController;
}

+ (ComposeWindowController*)openDraftMessageInstanceInWindow:(EmailMessageInstance*)messageInstance
{
    [ThreadHelper ensureMainThread];

    ComposeWindowController* viewerController = [[ComposeWindowController alloc] initWithWindowNibName:@"ComposeWindowController"];
    [viewerController showWindow:self];
    [viewerController showDraftMessageInstance:messageInstance];

    [self.shownWindows addObject:viewerController];
    return viewerController;
}

+ (void)startSetupAssistant
{
    
    
    NSViewController* setupViewController = [WindowManager sharedInstance].setupViewController;
    if(!setupViewController)
    {
        NSViewController *viewController = [[NSViewController alloc] initWithNibName:@"SetupView" bundle:nil];
        [WindowManager sharedInstance].setupViewController = viewController;

        NSView* setupView = viewController.view;
        NSView* superview = [APPDELEGATE mainSplitView].superview;

        [superview addSubview:setupView];

        [setupView setTranslatesAutoresizingMaskIntoConstraints:NO];

        NSLayoutConstraint* topConstraint = [NSLayoutConstraint constraintWithItem:setupView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeTop multiplier:1 constant:33];
        NSLayoutConstraint* leftConstraint = [NSLayoutConstraint constraintWithItem:setupView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
        NSLayoutConstraint* bottomConstraint = [NSLayoutConstraint constraintWithItem:setupView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
        NSLayoutConstraint* rightConstraint = [NSLayoutConstraint constraintWithItem:setupView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeRight multiplier:1 constant:0];

        [superview addConstraints:@[topConstraint, leftConstraint, bottomConstraint, rightConstraint]];

        [superview setNeedsLayout:YES];
    }
    else
    {
        [[WindowManager sharedInstance].setupViewController.view removeFromSuperview];
        [WindowManager sharedInstance].setupViewController = nil;
    }
}

+ (void)showComposeFeedbackWindow
{
    ComposeWindowController* viewerController = [[ComposeWindowController alloc] initWithWindowNibName:@"ComposeWindowController"];
    [viewerController showWindow:self];
    [viewerController showNewFeedbackMessageInstance];
    [self.shownWindows addObject:viewerController];
}

+ (void)showBugReporterWindow
{
    ComposeWindowController* viewerController = [[ComposeWindowController alloc] initWithWindowNibName:@"ComposeWindowController"];
    [viewerController showWindow:self];
    [viewerController showNewBugReporterMessageInstance];
    [self.shownWindows addObject:viewerController];
}

+ (void)removeWindow:(NSWindowController*)windowToBeReleased
{
    if([[self shownWindows] containsObject:windowToBeReleased])
        [[self shownWindows] removeObject:windowToBeReleased];
}


- (DisplayMessageView*)displayView
{
    return APPDELEGATE.displayView;
}

+ (void)showOAuthLoginForConnectionItem:(ConnectionItem*)connectionItem withCallback:(void(^)(void))callback
{
    GTMOAuth2WindowController* windowController = [OAuthHelper getOAuthControllerWithConnectionItem:connectionItem withCallback:^(NSError *error, GTMOAuth2Authentication* auth) {

        if(callback)
            callback();
    }];
    
    if(windowController)
    {
        [OAuthHelper signInSheetModalForWindow:APPDELEGATE.window controller:windowController];
        
        [AlertHelper showOAuthSheet:windowController];
    }
}



@end
