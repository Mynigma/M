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





#import "AttachmentListView.h"
#import "FileAttachment+Category.h"
#import "ThreadHelper.h"



@implementation AttachmentListView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (IBAction)open:(id)sender
{
    [ThreadHelper ensureMainThread];

    if([self.theAttachment canBeSavedByUser])
    {
        NSURL* attachmentURL = [self.theAttachment privateURL];

        [[UIApplication sharedApplication] openURL:attachmentURL];
    }
    else if([self.theAttachment canBeDownloaded])
    {
        [self.theAttachment urgentlyDownloadWithCallback:nil];
    }
}

- (void)fillWithAttachment:(FileAttachment*)attachment
{
    self.theAttachment = attachment;

    [self.topLabel setText:attachment.fileName?attachment.fileName:@""];

    UIDocumentInteractionController* docController = [[UIDocumentInteractionController alloc] init];

    docController.name = attachment.fileName;

    NSArray* icons = docController.icons;

    UIImage* image = nil;

    if(icons.count>0)
        image = icons[0];

    [self.icon setImage:image];

    NSURL* attachmentURL = [attachment privateURL];

    BOOL canOpen = [[UIApplication sharedApplication] canOpenURL:attachmentURL];
    
    if([attachment canBeSavedByUser] && canOpen)
    {
        [self.openButton setHidden:NO];
        [self.openButton setTitle:@"Open" forState:UIControlStateNormal];
    }
    else if([attachment canBeDownloaded])
    {
        [self.openButton setHidden:NO];
        [self.openButton setTitle:@"Download" forState:UIControlStateNormal];
    }
    else
        [self.openButton setHidden:YES];


    NSString* sizeString = nil;

    NSUInteger size = attachment.size.unsignedIntegerValue;
    if(size>1024*1024)
        sizeString = [NSString stringWithFormat:@"%.1f MB",ceil((1.*size)/1024/1024)];
    else
        sizeString = [NSString stringWithFormat:@"%.0f KB",ceil((1.*size)/1024)];


    if(attachment.isDownloading)
    {
        [self.progressView setHidden:NO];
        [self.progressView setProgress:attachment.downloadProgress.floatValue];

        NSString* downloadedSizeString = nil;

        NSUInteger downloadedSize = size*attachment.downloadProgress.floatValue;
        if(size>1024*1024)
            downloadedSizeString = [NSString stringWithFormat:@"%.1f",ceil((1.*downloadedSize)/1024/1024)];
        else
            downloadedSizeString = [NSString stringWithFormat:@"%.0f",ceil((1.*downloadedSize)/1024)];

        NSString* detailString = [NSString stringWithFormat:@"Downloading... (%@ of %@)", downloadedSizeString, sizeString];

        [self.detailLabel setText:detailString];
    }
    else
    {
        [self.progressView setHidden:YES];
        [self.detailLabel setText:sizeString];
    }
}

- (void)refresh
{
    [self fillWithAttachment:self.theAttachment];
}

@end
