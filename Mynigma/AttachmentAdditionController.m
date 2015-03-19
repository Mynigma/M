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





#import "AttachmentAdditionController.h"
#import "AttachmentItem.h"
#import "FileAttachment.h"
#import "EmailMessage.h"
#import "AppDelegate.h"
#import "AttachmentsManager.h"

@interface AttachmentAdditionController ()

@end

@implementation AttachmentAdditionController

@synthesize collectionController;
@synthesize collectionView;
//@synthesize message;
@synthesize showInlineAttachments;

@synthesize allAttachments;
@synthesize attachments;


- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    [collectionController setAvoidsEmptySelection:NO];
    [collectionController setSelectsInsertedObjects:NO];

    [collectionView registerForDraggedTypes:@[NSURLPboardType,NSFilenamesPboardType]];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)addFiles:(id)sender
{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setCanCreateDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    
    [openPanel beginWithCompletionHandler:^(NSInteger result){
        if(result==NSFileHandlingPanelOKButton)
        {
            for(NSURL* url in [openPanel URLs])
            {
                if(![[allAttachments valueForKey:@"publicURLString"] containsObject:url.path])
                {
                    FileAttachment* newAttachment = [FileAttachment makeNewAttachmentFromURL:url];

                    if(newAttachment)
                    {
                        [allAttachments addObject:newAttachment];
                        [attachments addObject:newAttachment];

                        //AttachmentItem* newItem = [[AttachmentItem alloc] initWithAttachment:newAttachment];

                        //[collectionController addObject:newItem];
                    }
                }
            }
        }}];
}

- (IBAction)removeFiles:(id)sender
{
    NSArray* arrangedObjects = collectionController.arrangedObjects;
    NSArray* selectedObjects = collectionController.selectedObjects;
    if(selectedObjects.count>0)
    {
        [collectionController removeObjects:selectedObjects];
        NSArray* attachmentsToBeRemoved = [selectedObjects valueForKey:@"fileAttachment"];
        [allAttachments removeObjectsInArray:attachmentsToBeRemoved];
        [attachments removeObjectsInArray:attachmentsToBeRemoved];
    }
    else
    {
        if(arrangedObjects.count)
            [collectionController removeObjects:arrangedObjects];
        
        NSArray* attachmentsToBeRemoved = [arrangedObjects valueForKey:@"fileAttachment"];
        [allAttachments removeObjectsInArray:attachmentsToBeRemoved];
        [attachments removeObjectsInArray:attachmentsToBeRemoved];
    }
}

- (void)resetCollection
{
    return;
    
    //NSSet* allAttachments = [[NSSet setWithArray:self.collectionController.arrangedObjects] valueForKey:@"fileAttachment"];

    [collectionController removeObjects:allAttachments];

    for(FileAttachment* fileAttachment in allAttachments)
    {
//        AttachmentItem* newItem = [AttachmentItem new];
//        [newItem setName:fileAttachment.fileName];
//
//        NSImage* image = [fileAttachment thumbnail];
//
//        [newItem setImage:image];
//
//
//        NSImage *faintImage = [[NSImage alloc] initWithSize:[image size]];
//
//        [faintImage lockFocus];
//        [image drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.3];
//        [faintImage unlockFocus];
//
//        [newItem setFaintImage:faintImage];
//
//
//        [newItem setUrl:[fileAttachment publicURL]];
//        [newItem setFileAttachment:fileAttachment];
        [collectionController addObject:fileAttachment];
    }
    /*
    if(showInlineAttachments)
    {
        [collectionController addObjects:allAttachments];
    }
    else
    {
        [collectionController addObjects:attachments];
    }*/
}

- (BOOL)collectionView:(NSCollectionView *)collectionView canDragItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event
{
    return YES;
}

- (BOOL)collectionView:(NSCollectionView *)collectionView writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard
{
    return YES;
}

+ (BOOL)dropFilesIntoCollectionView:(NSArray*)URLs
{

    return YES;
}

- (BOOL)collectionView:(NSCollectionView *)cv acceptDrop:(id < NSDraggingInfo >)draggingInfo index:(NSInteger)index dropOperation:(NSCollectionViewDropOperation)dropOperation
{
    NSPasteboard *pboard = [draggingInfo draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        for(NSString* fileName in files)
        {
            NSURL* url = [NSURL fileURLWithPath:fileName];
            if(![[allAttachments valueForKey:@"publicURLString"] containsObject:url.path])
            {
                FileAttachment* newAttachment = [FileAttachment makeNewAttachmentFromURL:url];

                if(newAttachment)
                {
                [allAttachments addObject:newAttachment];
                [attachments addObject:newAttachment];

//                AttachmentItem* newItem = [AttachmentItem new];
//                [newItem setName:newAttachment.fileName];
//
//                    [newItem setUrl:url];
//
//
//                NSImage* image = [newAttachment thumbnail];
//
//                [newItem setImage:image];
//
//
//                NSImage *faintImage = [[NSImage alloc] initWithSize:[image size]];
//
//                [faintImage lockFocus];
//                [image drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.3];
//                [faintImage unlockFocus];
//
//                [newItem setFaintImage:faintImage];
//                
//                [newItem setFileAttachment:newAttachment];
                [collectionController addObject:newAttachment];
                }
            }
        }
    }
    return YES;
}

- (NSDragOperation)collectionView:(NSCollectionView *)collectionView validateDrop:(id < NSDraggingInfo >)draggingInfo proposedIndex:(NSInteger *)proposedDropIndex dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation
{
    return NSDragOperationEvery;
}

- (IBAction)closeWindow:(id)sender
{
    [NSApp endSheet:[self window] returnCode:NSOKButton];
    [[self window] orderOut:self];
}

- (IBAction)inlinePreferenceChanged:(id)sender
{
    showInlineAttachments = [(NSButton*)sender state]==NSOnState;
    [self resetCollection];
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


@end
