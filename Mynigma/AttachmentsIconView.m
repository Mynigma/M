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





#import "AttachmentsIconView.h"
#import "AttachmentsIconViewDelegate.h"
#import "FileAttachment+Category.h"
#import "AttachmentItem.h"
#import "AttachmentsManager.h"
#import "ComposeWindowController.h"




//used as the context pointer for KVO
static char* someCharString = "blabla";

@implementation AttachmentsIconView

- (void)awakeFromNib
{
    [self registerForDraggedTypes:@[NSFilenamesPboardType, NSURLPboardType]];

    [self setDelegate:[AttachmentsIconViewDelegate sharedInstance]];

    [self setDraggingSourceOperationMask:NSDragOperationNone forLocal:YES];
    [self setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];

    [self addObserver:self forKeyPath:@"selectionIndexes"
              options:NSKeyValueObservingOptionNew context:&someCharString];

    [self setIsEditable:NO];

    [self.heightConstraint setConstant:0];
}


- (BOOL)acceptsFirstResponder
{
    return YES;
}



#pragma mark - KEY ACTIONS

- (void)keyDown:(NSEvent *)theEvent
{
    if([theEvent type] == NSKeyDown)
    {
        NSString* pressedChars = [theEvent characters];
        if ([pressedChars length] == 1)
        {
            unichar pressedUnichar = [pressedChars characterAtIndex:0];

            if ((pressedUnichar == NSDeleteCharacter) ||  (pressedUnichar == 0xf728))
            {
                if(self.isEditable)
                {
                    [self.attachmentsArrayController remove:self];//Objects:self.attachmentsArrayController.selectedObjects];

                    [self showOrHideIfNecessary];
                }
            }

            if((pressedUnichar == NSEnterCharacter) || (pressedUnichar == '\r'))
            {
                [self doubleClickAction:nil];
            }

            if(pressedUnichar == ' ')
            {
                [self saveAsAction:nil];
            }
        }
    }
}


#pragma mark - ATTACHMENT LIST

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(context == &someCharString)
    {
        NSIndexSet* selectionIndexes = change[@"new"];

        NSArray* selectedItems = [self itemsAtIndexes:selectionIndexes];

        for(AttachmentItem* attachmentItem in selectedItems)
        {
            FileAttachment* attachment = attachmentItem.representedObject;

            if(![attachment isDownloaded])
                [attachment urgentlyDownloadWithCallback:nil];
        }
    }
} 
- (NSArray*)itemsAtIndexes:(NSIndexSet*)indexSet
{
    NSMutableArray* returnArray = [NSMutableArray new];
    NSInteger index = indexSet.firstIndex;
    while(index != NSNotFound)
    {
        NSObject* item = [self itemAtIndex:index];
        [returnArray addObject:item];

        index = [indexSet indexGreaterThanIndex:index];
    }

    return returnArray;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"selectionIndexes" context:&someCharString];
    [self unregisterDraggedTypes];
}

- (NSCollectionViewItem *)newItemForRepresentedObject:(id)object
{
    NSCollectionViewItem *newItem = [super newItemForRepresentedObject:object];
    [newItem setSelected:newItem.selected];
    return newItem;
}



#pragma mark - ATTACHMENTS LIST

- (void)showAttachments:(NSSet*)attachments
{
    NSArray* attachmentsArray = [attachments sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"fileName" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"contentid" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"uniqueID" ascending:YES]]];

    if([self.attachmentsArrayController.arrangedObjects count])
        [self.attachmentsArrayController removeObjects:self.attachmentsArrayController.arrangedObjects];

    if(attachmentsArray.count)
        [self.attachmentsArrayController addObjects:attachmentsArray];

    [self showOrHideIfNecessary];
}

- (void)addAttachment:(FileAttachment *)attachment
{
    if(![self.attachmentsArrayController.arrangedObjects containsObject:attachment])
        [self.attachmentsArrayController addObject:attachment];

    [self showOrHideIfNecessary];
}

- (void)addAttachmentsFromSet:(NSSet*)attachments
{
    for(FileAttachment* attachment in attachments)
        if(![self.attachmentsArrayController.arrangedObjects containsObject:attachment])
            [self.attachmentsArrayController addObject:attachment];

    [self showOrHideIfNecessary];
}

- (void)addAttachments:(NSArray*)attachments
{
    for(FileAttachment* attachment in attachments)
        if(![self.attachmentsArrayController.arrangedObjects containsObject:attachment])
            [self.attachmentsArrayController addObject:attachment];

    [self showOrHideIfNecessary];
}

- (void)removeAttachments:(NSArray*)attachments
{
    if(attachments.count)
        [self.attachmentsArrayController removeObjects:attachments];

    [self showOrHideIfNecessary];
}

- (NSArray*)allURLs
{
    NSMutableArray* returnValue = [NSMutableArray new];

    for(FileAttachment* attachment in self.attachmentsArrayController.arrangedObjects)
    {
        NSURL* URL = attachment.URL;
        if(URL.path)
            [returnValue addObject:URL.path];
    }

    return returnValue;
}

- (NSArray*)allAttachments
{
    NSMutableArray* returnValue = [NSMutableArray new];

    for(FileAttachment* attachment in self.attachmentsArrayController.arrangedObjects)
    {
        [returnValue addObject:attachment];
    }

    return returnValue;
}


#pragma mark - SHOW / HIDE

- (void)showOrHideIfNecessary
{
    BOOL showAttachmentsView = ([self.attachmentsArrayController.content count]>0);

    [self.heightConstraint.animator setConstant:showAttachmentsView?120:0];

    [self setNeedsLayout:YES];
    [self.superview layoutSubtreeIfNeeded];
}


#pragma mark - UI ACTIONS

- (IBAction)doubleClickAction:(id)sender
{
    for(FileAttachment* attachment in self.attachmentsArrayController.selectedObjects)
    {
        [AttachmentsManager openAttachment:attachment];
    }
}

- (IBAction)saveAsAction:(id)sender
{
    NSArray* attachments = self.attachmentsArrayController.selectedObjects;
    if(attachments.count)
    {
        [AttachmentsManager promptUserToSaveAttachments:attachments withWindow:self.window];
    }
}

//- (void)mouseDown:(NSEvent *)theEvent
//{
//    ComposeWindowController* composeController = (ComposeWindowController*)self.window.delegate;
//
//    if([composeController isKindOfClass:[ComposeWindowController class]])
//        [composeController addAttachment:self];
//
//}

#pragma mark DRAG & DROP

-(NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    return NSDragOperationCopy;
}

-(NSDragOperation) draggingUpdated:(id<NSDraggingInfo>)sender
{
    return NSDragOperationCopy;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    ComposeWindowController* composeController = (ComposeWindowController*)self.window.delegate;

    //only allow drags into a compose window...
    if(![composeController isKindOfClass:[ComposeWindowController class]])
        return NO;


    NSPasteboard *pboard = [sender draggingPasteboard];

    if ([[pboard types] containsObject:NSFilenamesPboardType])
    {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];


        //otherwise go through the list and add each as an explicit attachment
        for(NSString* fileName in files)
        {
            NSURL* url = [NSURL fileURLWithPath:fileName];

            NSSet* allAttachments = [NSSet setWithArray:self.attachmentsArrayController.arrangedObjects];

            if(![[allAttachments valueForKey:@"publicURLString"] containsObject:url.path])
            {
                FileAttachment* newAttachment = [FileAttachment makeNewAttachmentFromURL:url];

                if(newAttachment)
                {
                    //                        AttachmentItem* newItem = [AttachmentItem new];
                    //                        [newItem setName:newAttachment.fileName];
                    //                        [newItem setImage:newAttachment.thumbnail];
                    //                        [newItem setFileAttachment:newAttachment];
                    [self addAttachment:newAttachment];
                    
                    [composeController setIsDirty:YES];
                }
            }
        }
    }

    return YES;
}

@end
