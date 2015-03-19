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

#import "MoveMessageContentViewController.h"
#import "ViewControllersManager.h"
#import "SelectionAndFilterHelper.h"
#import "AppDelegate.h"
#import "EmailMessage+Category.h"
#import "EmailMessageInstance+Category.h"
#import "ComposeNewController.h"
#import "TintedImageView.h"
#import "JASidePanelController.h"



@interface MoveMessageContentViewController ()

@end

@implementation MoveMessageContentViewController

- (void)viewDidLoad
{
//    BOOL singleMessageSelected = [SelectionAndFilterHelper selectedMessages].count == 1;
    
//    [self.replyOptionView setEnabled:singleMessageSelected];
//    [self.replyAllOptionView setEnabled:singleMessageSelected];
//    [self.forwardOptionView setEnabled:singleMessageSelected];

    CGFloat horizontalAdjustment = ([[ViewControllersManager sharedInstance].splitViewController detailViewObscured])?[[ViewControllersManager sharedInstance].splitViewController masterViewWidth]/2:0;

    [self.horizontalCenterConstraint setConstant:-horizontalAdjustment];
    
    //in horizontally regular environments, the "Select more" option can be enabled automatically
    if(![ViewControllersManager isHorizontallyCompact])
    {
        [[ViewControllersManager sharedInstance].messagesController setEditing:YES animated:YES];
    }
    
    [self selectionDidChange];
}



#pragma mark - Move message & more IBActions

- (IBAction)pickedOptionMoveToTrash:(id)sender
{
    [ViewControllersManager removeMoveMessageOptionsIfNecessary];
    [APPDELEGATE deleteSelectedMessages:self];
}

- (IBAction)pickedOptionMoveToSpam:(id)sender
{
    [ViewControllersManager removeMoveMessageOptionsIfNecessary];
    [APPDELEGATE markSelectedMessagesAsSpam:nil];
}

- (IBAction)pickedOptionSelectMore:(id)sender
{
    NSArray* selectedMessageInstances = [SelectionAndFilterHelper selectedMessages];
    //in a compact environment the message move option view obscures the message list, so it needs to be removed
    if([ViewControllersManager isHorizontallyCompact])
    {
        [ViewControllersManager removeMoveMessageOptionsIfNecessary];
    }
    
    [[[ViewControllersManager sharedInstance] messagesController] setEditing:YES animated:YES];

//    if(APPDELEGATE.window.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact)
//    {
    [[[ViewControllersManager sharedInstance] messagesController] selectMessageInstances:selectedMessageInstances];
//    }
}


//- (IBAction)pickedOptionReply:(id)sender
//{
//    if(!self.replyOptionView.isEnabled)
//        return;
//    
//    [ViewControllersManager removeMoveMessageOptionsIfNecessary];
//
//    EmailMessageInstance* selectedInstance = [SelectionAndFilterHelper selectedMessages].firstObject;
//    
//    if([selectedInstance.message isKindOfClass:[EmailMessage class]])
//    {
//        DisplayMessageController* displayController = [[ViewControllersManager sharedInstance] displayMessageController];
//        [displayController performSegueWithIdentifier:@"replySegue" sender:self];
//    }
//}
//
//- (IBAction)pickedOptionReplyAll:(id)sender
//{
//    if(!self.replyAllOptionView.isEnabled)
//        return;
//
//    [ViewControllersManager removeMoveMessageOptionsIfNecessary];
//
//    EmailMessageInstance* selectedInstance = [SelectionAndFilterHelper selectedMessages].firstObject;
//    
//    if([selectedInstance.message isKindOfClass:[EmailMessage class]])
//    {
//        DisplayMessageController* displayController = [[ViewControllersManager sharedInstance] displayMessageController];
//        [displayController performSegueWithIdentifier:@"replyAllSegue" sender:self];
//    }
//}
//
//- (IBAction)pickedOptionForward:(id)sender
//{
//    if(!self.forwardOptionView.isEnabled)
//        return;
//
//    [ViewControllersManager removeMoveMessageOptionsIfNecessary];
//
//    EmailMessageInstance* selectedInstance = [SelectionAndFilterHelper selectedMessages].firstObject;
//    
//    if([selectedInstance.message isKindOfClass:[EmailMessage class]])
//    {
//        DisplayMessageController* displayController = [[ViewControllersManager sharedInstance] displayMessageController];
//        [displayController performSegueWithIdentifier:@"forwardSegue" sender:self];
//    }
//}

- (IBAction)pickedOptionMarkUnread:(id)sender
{
    [ViewControllersManager removeMoveMessageOptionsIfNecessary];
    [SelectionAndFilterHelper markSelectedMessagesAsRead];
}

- (IBAction)pickedOptionMarkStarred:(id)sender
{
    [ViewControllersManager removeMoveMessageOptionsIfNecessary];
    [SelectionAndFilterHelper markSelectedMessagesAsFlagged];
}

- (IBAction)pickedOptionMoveElsewhere:(id)sender
{
    //we need to show the folders list and ensure that the message(s) are moved into whatever folder is selected
    //also need to disable all option other than cancel
    //if the folder list is collapsed without a folder being selected, no action should be taken, but the more options menu should be closed
    
    if ([ViewControllersManager isSidePanelShown])
    {
        // pressed button 2nd time -> collapse sidepanel and enable all options
        [ViewControllersManager hideSidePanel];
        [self enableAllOptions];
    }
    else
    {
        // disable all other options and show the side panel
        [ViewControllersManager showSidePanel];

        [self.moveToSpamOptionView setEnabled:NO];
        [self.moveToTrashOptionView setEnabled:NO];
        [self.selectMoreOptionView setEnabled:NO];
    
        [self.markUnreadOptionView setEnabled:NO];
        [self.markStarredOptionView setEnabled:NO];
    }
    
}


- (IBAction)pickedOptionCancel:(id)sender
{
    //if the selection of a folder was cancelled, close the side panel
    [ViewControllersManager hideSidePanel];

    [ViewControllersManager removeMoveMessageOptionsIfNecessary];
}


- (void)selectionDidChange
{
    if ([SelectionAndFilterHelper selectedMessages].count == 0)
        [self disableAllOptions];
    else
        [self enableAllOptions];
    
    if([SelectionAndFilterHelper selectedMessagesAreAllRead])
    {
        [self.markUnreadOptionView.imageView setImage:[UIImage imageNamed:@"unread48"]];
        [self.markUnreadOptionView.textLabel setText:NSLocalizedString(@"Mark unread", nil)];
    }
    else
    {
        [self.markUnreadOptionView.imageView setImage:[UIImage imageNamed:@"read48"]];
        [self.markUnreadOptionView.textLabel setText:NSLocalizedString(@"Mark read", nil)];
    }
    
    if([SelectionAndFilterHelper selectedMessagesAreAllFlagged])
    {
        [self.markStarredOptionView.imageView setImage:[UIImage imageNamed:@"unstarred48"]];
        [self.markStarredOptionView.textLabel setText:NSLocalizedString(@"Unstar", nil)];
    }
    else
    {
        [self.markStarredOptionView.imageView setImage:[UIImage imageNamed:@"starred48"]];
        [self.markStarredOptionView.textLabel setText:NSLocalizedString(@"Star", nil)];
    }
}


- (void)disableAllOptions
{
    [self.moveToSpamOptionView setEnabled:NO];
    [self.moveToTrashOptionView setEnabled:NO];
    [self.selectMoreOptionView setEnabled:NO];
    
    [self.markUnreadOptionView setEnabled:NO];
    [self.markStarredOptionView setEnabled:NO];
    
    [self.moveElsewhereOptionView setEnabled:NO];
}

- (void)enableAllOptions
{
    [self.moveToSpamOptionView setEnabled:YES];
    [self.moveToTrashOptionView setEnabled:YES];
    
    if([ViewControllersManager isHorizontallyCompact])
    {
        // automatically activated on iPads
        [self.selectMoreOptionView setEnabled:YES];
    }
    else
    {
        [self.selectMoreOptionView setEnabled:NO];    
    }
    
    [self.markUnreadOptionView setEnabled:YES];
    [self.markStarredOptionView setEnabled:YES];
    
    [self.moveElsewhereOptionView setEnabled:YES];
    
}


@end
