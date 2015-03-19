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





#import "AttachmentsIconViewDelegate.h"
#import "AttachmentsIconView.h"
#import "AttachmentItem.h"
#import "FileAttachment+Category.h"



@implementation AttachmentsIconViewDelegate

+ (AttachmentsIconViewDelegate*)sharedInstance
{
    static dispatch_once_t p = 0;

    __strong static id sharedObject = nil;

    dispatch_once(&p, ^{
        sharedObject = [AttachmentsIconViewDelegate new];
    });

    return sharedObject;
}





- (BOOL)collectionView:(NSCollectionView *)collectionView canDragItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event
{
    if([collectionView isKindOfClass:[AttachmentsIconView class]])
    {
        AttachmentsIconView* iconView = (AttachmentsIconView*)collectionView;

        NSArray* items = [iconView itemsAtIndexes:indexes];

        //the NSURLPboardType can only hold a single URL
        for(AttachmentItem* item in items)
        {
            FileAttachment* attachment = (FileAttachment*)item.representedObject;
            NSURL* fileURL = attachment.URL;
            if(!fileURL)
                return NO;
        }

        return YES;
    }

    return NO;
}

//- (NSImage *)collectionView:(NSCollectionView *)collectionView draggingImageForItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event offset:(NSPointPointer)dragImageOffset

//- (NSArray *)collectionView:(NSCollectionView *)collectionView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropURL forDraggedItemsAtIndexes:(NSIndexSet *)indexes

//- (NSDragOperation)collectionView:(NSCollectionView *)collectionView validateDrop:(id < NSDraggingInfo >)draggingInfo proposedIndex:(NSInteger *)proposedDropIndex dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation

- (BOOL)collectionView:(NSCollectionView *)collectionView writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard
{
    if([collectionView isKindOfClass:[AttachmentsIconView class]])
    {
        AttachmentsIconView* iconView = (AttachmentsIconView*)collectionView;

        NSArray* items = [iconView itemsAtIndexes:indexes];

        NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
        [pboard clearContents];

        //the NSURLPboardType can only hold a single URL
        if(items.count == 1)
        {
            AttachmentItem* item = items.firstObject;
            FileAttachment* attachment = (FileAttachment*)item.representedObject;
            NSURL* fileURL = attachment.URL;
            if(fileURL)
            {
                [pboard addTypes:@[NSURLPboardType] owner:nil];
                [fileURL writeToPasteboard:pboard];
            }
        }

        NSMutableArray* fileNamesList = [NSMutableArray new];

        for(AttachmentItem* item in items)
        {
            FileAttachment* attachment = (FileAttachment*)item.representedObject;
            NSURL* fileURL = attachment.URL;
            NSString* fileName = fileURL.path;

           if(fileName)
                [fileNamesList addObject:fileName];
        }

        if(fileNamesList.count)
        {
            [pboard addTypes:@[NSFilenamesPboardType] owner:nil];
            [pboard setPropertyList:fileNamesList forType:NSFilenamesPboardType];
        }

        [pboard addTypes:@[NSFilesPromisePboardType] owner:self];
    }
    
    return YES;
}

- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString
                                                              *)type
{
//    if ([type isEqual:NSFileContentsPboardType]) { // never gets called.
//        NSData *data = [self createData];
//        NSFileWrapper *wrapper = [[[NSFileWrapper alloc]
//                                   initRegularFileWithContents:data] autorelease];
//        [wrapper setPreferredFilename:@"draggedData"];
//        [sender writeFileWrapper:wrapper];
//    } if ([type isEqual:NSFileContentsPboardType]) { // never gets
//        called.
//        // do same as above, but write out the file wrapper to a temp
//        directory
//    }
}

- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination
{
    return @[];
}

@end
