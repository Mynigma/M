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





#import "AppDelegate.h"


#import "AttachmentListController.h"
#import "AttachmentItem.h"
#import "EmailMessage.h"
#import "IMAPFolderSetting.h"
#import "IMAPAccountSetting.h"
#import "IMAPAccount.h"
#import "AttachmentsManager.h"


@interface AttachmentListController ()

@end

@implementation AttachmentListController

@synthesize collectionController;
@synthesize collectionView;
@synthesize inlineCheckButton;


- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }

    return self;
}

- (void)windowWillLoad
{
    [collectionView setMinItemSize:NSMakeSize(110,110)];
    [collectionView setMaxItemSize:NSMakeSize(110,110)];
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    [collectionController setSelectsInsertedObjects:NO];
    [collectionController setAvoidsEmptySelection:NO];

    [collectionView registerForDraggedTypes:@[NSURLPboardType,NSFilenamesPboardType]];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)openOrDownloadFiles:(id)sender
{
//    if(collectionController.selectedObjects.count>0)
//    {
//        for(AttachmentItem* item in collectionController.selectedObjects)
//        {
//            FileAttachment* fileAttachment = item.fileAttachment;
//            [AttachmentsManager openAttachment:fileAttachment];
//        }
//    }
//    else
//    {
//        for(AttachmentItem* item in collectionController.arrangedObjects)
//        {
//            FileAttachment* fileAttachment = item.fileAttachment;
//            [AttachmentsManager openAttachment:fileAttachment];
//        }
//    }
}

- (IBAction)saveAs:(id)sender
{
//    if(collectionController.selectedObjects.count==1)
//    {
//        AttachmentItem* attItem = collectionController.selectedObjects[0];
//        FileAttachment* fileAttachment = attItem.fileAttachment;
//
//        if([fileAttachment isDownloaded])
//            [AttachmentsManager promptUserToSaveAttachment:fileAttachment];
//        else
//        {
//            NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Attachment not downloaded", @"Attachment not yet downloaded alert") defaultButton:NSLocalizedString(@"OK", @"OK button") alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please download the attachment before saving it."];
//            [alert runModal];
//        }
//    }
//    else if(collectionController.selectedObjects.count>1)
//    {
//        BOOL allDownloaded = YES;
//
//        NSMutableArray* attachmentsArray = [NSMutableArray new];
//
//        for(AttachmentItem* attItem in collectionController.selectedObjects)
//        {
//            FileAttachment* fileAttachment = attItem.fileAttachment;
//            [attachmentsArray addObject:fileAttachment];
//            if(![fileAttachment isDownloaded])
//            {
//                allDownloaded = NO;
//                break;
//            }
//        }
//
//        if(!allDownloaded)
//        {
//            NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Error saving attachments", @"Attachment save operation error message") defaultButton:NSLocalizedString(@"OK", @"OK button") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Some of these attachments have not yet been downloaded", @"Some attachments not downloaded error explanation")];
//            [alert runModal];
//            return;
//        }
//
//        [AttachmentsManager promptUserToSaveAttachments:attachmentsArray];
//    }
//    else
//    {
//        if([(NSArray*)collectionController.arrangedObjects count]==1)
//        {
//            AttachmentItem* attItem = collectionController.arrangedObjects[0];
//            FileAttachment* fileAttachment = attItem.fileAttachment;
//
//            if([fileAttachment isDownloaded])
//                [AttachmentsManager promptUserToSaveAttachment:fileAttachment];
//            else
//            {
//                NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Attachment not downloaded", @"Attachment not yet downloaded alert") defaultButton:NSLocalizedString(@"OK", @"OK button") alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please download the attachment before saving it."];
//                [alert runModal];
//            }
//            return;
//        }
//        else if([(NSArray*)collectionController.arrangedObjects count]>1)
//        {
//            BOOL allDownloaded = YES;
//
//            NSMutableArray* attachmentsArray = [NSMutableArray new];
//
//            for(AttachmentItem* attItem in collectionController.arrangedObjects)
//            {
//                FileAttachment* fileAttachment = attItem.fileAttachment;
//                [attachmentsArray addObject:fileAttachment];
//                if(![fileAttachment isDownloaded])
//                {
//                    allDownloaded = NO;
//                    break;
//                }
//            }
//
//            if(!allDownloaded)
//            {
//                NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Error saving attachments", @"Attachment save operation error message") defaultButton:NSLocalizedString(@"OK", @"OK button") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Some of these attachments have not yet been downloaded", @"Some attachments not downloaded error explanation")];
//                [alert runModal];
//                return;
//            }
//
//            [AttachmentsManager promptUserToSaveAttachments:attachmentsArray];
//        }
//    }
//
}


-(BOOL)collectionView:(NSCollectionView *)collectionView canDragItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event
{
    return YES;
}

- (BOOL)collectionView:(NSCollectionView *)collectionView writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard
{
    return YES;
}

- (BOOL)collectionView:(NSCollectionView *)cv acceptDrop:(id < NSDraggingInfo >)draggingInfo index:(NSInteger)index dropOperation:(NSCollectionViewDropOperation)dropOperation
{
    return NO;
}

- (NSDragOperation)collectionView:(NSCollectionView *)collectionView validateDrop:(id < NSDraggingInfo >)draggingInfo proposedIndex:(NSInteger *)proposedDropIndex dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation
{
    return NSDragOperationNone;
}

- (IBAction)closeWindow:(id)sender
{
    [NSApp endSheet:[self window] returnCode:NSOKButton];
    [[self window] orderOut:self];
}

/*
 - (void)mouseUp:(NSEvent *)event
 {
 NSInteger clickCount = [event clickCount];
 if (2 == clickCount) NSLog(@"Yeah!!");
 }*/

- (IBAction)inlineCheckButtonClicked:(id)sender
{
    
}

@end
