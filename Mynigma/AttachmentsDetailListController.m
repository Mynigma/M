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





#import "AttachmentsDetailListController.h"
#import "AttachmentsListCell.h"
#import "FileAttachment+Category.h"
#import "AppDelegate.h"
#import "ComposeNewController.h"
#import "EmailMessage+Category.h"
#import "PictureManager.h"
#import "ViewControllersManager.h"


static UIDocumentInteractionController* _interactionController;

@interface AttachmentsDetailListController ()

@end

@implementation AttachmentsDetailListController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[ViewControllersManager sharedInstance] setAttachmentsListController:self];

    // this is set before, so do not over write
    [self setCanAddAndRemove:self.canAddAndRemoveAttachments?self.canAddAndRemoveAttachments:NO];
}

- (void)dealloc
{
    [[ViewControllersManager sharedInstance] setAttachmentsListController:nil];
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.attachments.count + (self.canAddAndRemoveAttachments?2:0);
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row>=0 && indexPath.row < self.attachments.count && indexPath.row < self.documentInteractionControllers.count)
    {
        AttachmentsListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"attachmentCell" forIndexPath:indexPath];

        FileAttachment* attachment = self.attachments[indexPath.row];

        UIDocumentInteractionController* interactionController = self.documentInteractionControllers[indexPath.row];

        [cell configureWithAttachment:attachment andDocumentInteractionController:interactionController];

        return cell;
    }

    NSString* identifer = @"chooseExistingCell";

    if(indexPath.row == self.attachments.count)
    {
        identifer = @"takeNewCell";
    }

    AttachmentsListCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer forIndexPath:indexPath];

    return cell;
}



#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView
shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row>=0 && indexPath.row < self.attachments.count && indexPath.row < self.documentInteractionControllers.count)
        return YES;
    
    return NO;
}


- (IBAction)actionButtonTap:(UIView*)sender
{
    AttachmentsListCell* cell = nil;

    if([sender isKindOfClass:[AttachmentsListCell class]])
    {
        cell = (AttachmentsListCell*)sender;
    }
    else if([[(UIView*)sender.superview superview] isKindOfClass:[AttachmentsListCell class]])
    {
        cell = (AttachmentsListCell*)sender.superview.superview;
    }
    else if([[[(UIView*)sender.superview superview] superview] isKindOfClass:[AttachmentsListCell class]])
        {
            //need this for iOS 7...
            cell = (AttachmentsListCell*)sender.superview.superview.superview;
        }

    if([cell.attachment isDownloaded])
    {
        if(!self.navigationController)
        {
            UIViewController* mainViewController = self.presentingViewController;
            _interactionController = cell.interactionController;
        
            [self dismissViewControllerAnimated:YES completion:
             ^{
                 CGRect frame = mainViewController.view.frame;
                 frame.size.height = 20;
                 [_interactionController presentOptionsMenuFromRect:frame inView:mainViewController.view animated:YES];
             }];
        }
        else
        {
            //assuming that in this case, the view controller was pushed
            //this should only happen on iOS7 (iPhone), where no popovers are available
            //don't pop the view controller, just present the attachment options...
            _interactionController = cell.interactionController;

            CGRect frame = self.view.frame;
            frame.size.height = 20;
            [_interactionController presentOptionsMenuFromRect:frame inView:self.view animated:YES];
        }
    }
    else
    {
        [cell actionButtonTapped:nil];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row>=0 && indexPath.row < self.attachments.count && indexPath.row < self.documentInteractionControllers.count)
    {
        //an attachment was selected
        AttachmentsListCell* cell = (AttachmentsListCell*)[tableView cellForRowAtIndexPath:indexPath];
        if(cell)
        {
            [self actionButtonTap:cell];
        }
    }
    else
    {
        if(indexPath.row == self.attachments.count)
        {
            //if we are dealing with a popover, the navigation controller will be nil
            if(!self.navigationController)
            {
                //take new photo or video
                [self dismissViewControllerAnimated:YES completion:^{

                    [[PictureManager sharedInstance] takeNewPhotoInViewController:self.callingViewController];
                }];
            }
            else
            {
                [self.navigationController popViewControllerAnimated:YES];
                [[PictureManager sharedInstance] takeNewPhotoInViewController:self.callingViewController];
            }
        }
        else
        {
            if(!self.navigationController)
            {
            //choose existing
            [self dismissViewControllerAnimated:YES completion:^{

                [[PictureManager sharedInstance] pickExistingPhotoInViewController:self.callingViewController];
            }];
            }
            else
            {
                [self.navigationController popViewControllerAnimated:YES];
                [[PictureManager sharedInstance] pickExistingPhotoInViewController:self.callingViewController];
            }
        }
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row>=0 && indexPath.row < self.attachments.count && indexPath.row < self.documentInteractionControllers.count /*&& self.isEditable*/)
        return UITableViewCellEditingStyleDelete;

    return UITableViewCellEditingStyleNone;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 73;
}

- (void)refreshAttachment:(FileAttachment*)fileAttachment
{
    NSInteger index = [self.attachments indexOfObject:fileAttachment];

    if(index == -1 || index == NSNotFound)
    {
        return;
    }

    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];

    AttachmentsListCell* cell = (AttachmentsListCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    if(cell)
    {
        [cell refreshDownloadProgress];
    }
}

- (void)setupWithAttachments:(NSArray*)attachments
{
    NSArray* sortedAttachments = [attachments sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"fileName" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"uniqueID" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"contentid" ascending:YES]]];

    self.attachments = sortedAttachments;
    
    NSMutableArray* newDocumentInteractionControllers = [NSMutableArray new];
    
    for(FileAttachment* attachment in sortedAttachments)
    {
        NSURL* attachmentURL = [attachment privateURL];
        
        BOOL setFileName = NO;
        
        if(!attachmentURL)
        {
            setFileName = YES;
            attachmentURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"~/%@", attachment.fileName]];
        }
        
        UIDocumentInteractionController* interactionController = [UIDocumentInteractionController interactionControllerWithURL:attachmentURL];
        
        if(setFileName)
            [interactionController setName:attachment.fileName];
        
        interactionController.delegate = self;
        
        [newDocumentInteractionControllers addObject:interactionController];
    }
    
    self.documentInteractionControllers = newDocumentInteractionControllers;
    
    [self.tableView reloadData];

}

- (void)setCanAddAndRemove:(BOOL)canAddAndRemove
{
    self.canAddAndRemoveAttachments = canAddAndRemove;
    [self.tableView setEditing:canAddAndRemove animated:NO];
}

- (NSString*)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NSLocalizedString(@"Remove", @"Attachment list delete confirmation button title");
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete)
    {
        //remove the attachment at index path indexPath
        FileAttachment* attachmentToBeRemoved = [self.attachments objectAtIndex:indexPath.row];
        
        if ([[ViewControllersManager sharedInstance].composeController.allAttachments containsObject:attachmentToBeRemoved])
            [[ViewControllersManager sharedInstance].composeController.allAttachments removeObject:attachmentToBeRemoved];
        
        if ([[ViewControllersManager sharedInstance].composeController.attachments containsObject:attachmentToBeRemoved])
            [[ViewControllersManager sharedInstance].composeController.attachments removeObject:attachmentToBeRemoved];
        
        self.attachments = [ViewControllersManager sharedInstance].composeController.allAttachments;
            
        [self setupWithAttachments:self.attachments];
        
        [[ViewControllersManager sharedInstance].composeController updateAttachmentNumber];
    }
}



@end
