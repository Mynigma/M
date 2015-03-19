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





#import "AttachmentsListCell.h"
#import "FileAttachment+Category.h"
#import "AppDelegate.h"
#import "ComposeNewController.h"
#import "AttachmentsDetailListController.h"
#import "DisplayMessageController.h"
#import "ViewControllersManager.h"



@implementation AttachmentsListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureWithAttachment:(FileAttachment*)attachment andDocumentInteractionController:(UIDocumentInteractionController*)documentInteractionController
{
    if(!attachment)
        return;

    self.attachment = attachment;
    self.interactionController = documentInteractionController;

    [self.nameLabel setText:attachment.fileName];
    [self.sizeLabel setText:attachment.sizeString];

    NSArray* icons = documentInteractionController.icons;

    UIImage* bestIcon = icons[0];

    NSInteger index = 0;

    while(++index < icons.count && bestIcon.size.height < 96)
    {
        //keep incrementing until at least 96px are found or the last item is reached
        bestIcon = icons[index];
    }

    [self.typeImageView setImage:bestIcon];

    if([attachment isDownloaded])
    {
        if([attachment isDecrypting])
            [self.statusLabel setText:NSLocalizedString(@"Decrypting", @"Attachments list status")];
        else
            [self.statusLabel setText:NSLocalizedString(@"Downloaded", @"Attachments list status")];

        [self.actionButton setTitle:NSLocalizedString(@"Open", @"Open something Button") forState:UIControlStateNormal];
        [self.actionButton setHidden:NO];

        [self.progressBar setHidden:YES];
        [self.statusLabel setHidden:NO];
    }
    else if([attachment isDownloading])
    {
        [self.progressBar setProgress:attachment.downloadProgress.floatValue animated:YES];

        [self.actionButton setHidden:YES];

        [self.progressBar setHidden:NO];
        [self.statusLabel setHidden:YES];
    }
    else
    {
        [self.statusLabel setText:NSLocalizedString(@"Not downloaded", @"Attachments list status")];

        [self.actionButton setTitle:NSLocalizedString(@"Download", @"Download Button") forState:UIControlStateNormal];
        [self.actionButton setHidden:NO];

        [self.progressBar setHidden:YES];
        [self.statusLabel setHidden:NO];
    }
}


- (UIDocumentInteractionController *) setupControllerWithURL: (NSURL*) fileURL usingDelegate: (id <UIDocumentInteractionControllerDelegate>) interactionDelegate
{
    UIDocumentInteractionController *interactionController =
    [UIDocumentInteractionController interactionControllerWithURL: fileURL];
    interactionController.delegate = interactionDelegate;
    
    return interactionController;
}

- (IBAction)actionButtonTapped:(id)sender
{
    //now checked in AttahcmentsDetailListController
//    if(self.attachment.isDownloaded)
//    {
//        [self.interactionController presentOptionsMenuFromRect:APPDELEGATE.displayMessageController.view.frame inView:APPDELEGATE.displayMessageController.view animated:YES];
//    }
//    else
    {
        [self startDownloadProgress];
        [self.attachment urgentlyDownloadWithCallback:^(NSData *data) {

            [ThreadHelper runAsyncOnMain:^{

            NSURL* attachmentURL = self.attachment.privateURL;

            if(attachmentURL)
                [self.interactionController setURL:attachmentURL];

                [self configureWithAttachment:self.attachment andDocumentInteractionController:self.interactionController];
            }];
        }];
    }
}

- (void)startDownloadProgress
{
    [self.progressBar setProgress:0 animated:NO];
}

- (void)refreshDownloadProgress
{
    //if([self.attachment isDownloaded])
        [self configureWithAttachment:self.attachment andDocumentInteractionController:self.interactionController];
    //else
    //    [self.progressBar setProgress:self.attachment.downloadProgress.floatValue animated:YES];
}




@end
