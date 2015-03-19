//
//  BodyView.m
//  Mynigma
//
//  Created by Roman Priebe on 13/11/13.
//  Copyright (c) 2013 Mynigma UG (haftungsbeschränkt). All rights reserved.
//

#import "BodyView.h"

@implementation BodyWebView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}


- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
    // Drawing code here.
}

- (void)awakeFromNib
{
    
}

#pragma mark -
#pragma mark WEB VIEW DRAG & DROP

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{

    if ([sender draggingSource] == nil)
    {

        NSPasteboard *pboard = [sender draggingPasteboard];

        if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
            NSURL* fileURL;
            fileURL=[NSURL URLFromPasteboard: [sender draggingPasteboard]];

            NSArray *dragTypes = [NSArray arrayWithObject:NSFileContentsPboardType];
            [[sender draggingPasteboard] declareTypes:dragTypes owner:nil];

            NSImage *content = [[NSImage alloc] initWithContentsOfURL:fileURL];
            [[sender draggingPasteboard] setData:[content TIFFRepresentation] forType:NSPasteboardTypeTIFF];
        }
    }

    return [super performDragOperation:sender];
}



@end
