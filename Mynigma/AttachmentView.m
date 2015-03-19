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





#import "AttachmentView.h"
#import "AttachmentListController.h"
#import "AttachmentItem.h"
#import "FileAttachment+Category.h"
#import "AttachmentsIconView.h"




@implementation AttachmentView

@synthesize item;

@synthesize nameField;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self.nameField.cell setWraps:YES];
    }

    return self;
}


- (NSView *)hitTest:(NSPoint)aPoint
{
    // don't allow any mouse clicks for subviews in this view
    if(NSPointInRect(aPoint,[self convertRect:[self bounds] toView:[self superview]]))
    {
        return self;
    }
    else
    {
        return nil;
    }
}

- (void)rightMouseDown:(NSEvent*)theEvent
{
    [super rightMouseDown:theEvent];

    if([theEvent clickCount] == 1)
    {
        AttachmentsIconView* collectionView = (AttachmentsIconView*)self.superview;

        if([collectionView isKindOfClass:[AttachmentsIconView class]])
        {
            [collectionView saveAsAction:nil];
//            NSMenu* rightClickMenu = [[NSMenu alloc] initWithTitle:@"Attachments context menu"];
//
//            NSMenuItem* saveAsItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Save as...", @"Attachment right click context menu item") action:@selector(saveAsAction:) keyEquivalent:@"\n"];
//
//            [saveAsItem setTarget:collectionView];
//
//            [rightClickMenu addItem:saveAsItem];
//
//            [NSMenu popUpContextMenu:rightClickMenu withEvent:theEvent forView:self];
        }
    }
}

-(void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];

    // check for click count above one, which we assume means it's a double click
    if([theEvent clickCount] > 1)
    {
        AttachmentListController* listController = (AttachmentListController*)self.window.delegate;
        if([listController isKindOfClass:[AttachmentListController class]])
            [listController openOrDownloadFiles:self];
    }

    if([theEvent clickCount] == 1)
    {
        if([theEvent modifierFlags] & NSCommandKeyMask)
        {
            AttachmentsIconView* collectionView = (AttachmentsIconView*)self.superview;

            if([collectionView isKindOfClass:[AttachmentsIconView class]])
            {
                [collectionView saveAsAction:nil];
//                NSMenu* rightClickMenu = [[NSMenu alloc] initWithTitle:@"Attachments context menu"];
//
//                NSMenuItem* saveAsItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Save as...", @"Attachment right click context menu item") action:@selector(saveAsAction:) keyEquivalent:@"\n"];
//
//                [saveAsItem setTarget:collectionView];
//
//                [rightClickMenu addItem:saveAsItem];
//
//                [NSMenu popUpContextMenu:rightClickMenu withEvent:theEvent forView:self];
            }

        }
        else if([item.representedObject isKindOfClass:[FileAttachment class]])
        {
            FileAttachment* attachment = (FileAttachment*)item.representedObject;

            [attachment urgentlyDownloadWithCallback:nil];
        }
    }

    if([theEvent clickCount] == 2)
    {
        AttachmentsIconView* collectionView = (AttachmentsIconView*)self.superview;

        if([collectionView isKindOfClass:[AttachmentsIconView class]])
        {
            [collectionView doubleClickAction:nil];
        }
    }
}


- (void)mouseUp:(NSEvent *)theEvent
{
    [super mouseUp:theEvent];
    
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

@end
