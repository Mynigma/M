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





#import "AttachmentItem.h"
#import "AppDelegate.h"
#import "AttachmentView.h"
#import "FileAttachment+Category.h"



@interface AttachmentItem ()

@end

@implementation AttachmentItem

//@synthesize uniqueID;
//@synthesize isSafe;
//@synthesize fileAttachment;
//
//@synthesize contentID;
//@synthesize data;
//@synthesize image;
//
//@synthesize contentType;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        //[(AttachmentView*)self.view setItem:self];
//        isSafe = NO;
//        contentType = @"application/octet-stream";
//
//        [self setupWithFileAttachment:self.representedObject];

    }
    
    return self;
}

//- (void)setupWithFileAttachment:(FileAttachment*)attachment
//{
//    [self setName:attachment.fileName];
//
//    IMAGE* attachmentImage = [attachment thumbnail];
//
//    [self setImage:attachmentImage];
//
//    CGFloat size = 64;
//
//    IMAGE* faintImage = [[NSImage alloc] initWithSize:CGSizeMake(size, size)];
//
//    [faintImage lockFocus];
//    //[attachmentImage drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.3];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSGraphicsContext currentContext]
//     setImageInterpolation:NSImageInterpolationLow];
//
//    [attachmentImage drawInRect:CGRectMake(0, 0, size, size) fromRect:NSZeroRect operation:NSCompositeCopy fraction:0.3];
//
//    [NSGraphicsContext restoreGraphicsState];
//    [faintImage unlockFocus];
//
//    [self setFaintImage:faintImage];
//
//    [self setFileAttachment:attachment];
//}

- (void)setSelected:(BOOL)flag
{
    [super setSelected: flag];
    AttachmentView *view = (AttachmentView*)[self view];

    FileAttachment* attachment = self.representedObject;

    //outlets are assigned neither to the AttachmentItem nor the AttachmentView, so we'll have to do it this way
    //a bit kludgy, but it works

    if(!attachment)
        return;

    NSColor* textColor = [NSColor textColor];

    if(![attachment isDownloaded])
        textColor = [NSColor grayColor];

    NSBox* box = [view.subviews objectAtIndex:0];
    NSColor *color;
    if (flag)
    {
        color = [NSColor colorWithCalibratedRed:41/255. green:52/255. blue:86/255. alpha:1];
        NSView* subView = box.subviews[0];
        NSTextField* nameField = subView.subviews[0];
        [nameField setTextColor:[NSColor whiteColor]];

        if(subView.subviews.count >=5)
        {
            NSTextField* sizeField = subView.subviews[4];
            if([sizeField isKindOfClass:[NSTextField class]])
            {
                [sizeField setTextColor:[NSColor whiteColor]];
            }
        }

    }
    else
    {
        color = [NSColor controlBackgroundColor];
        NSView* subView = box.subviews[0];
         NSTextField* nameField = subView.subviews[0];
        [nameField setTextColor:textColor];

        if(subView.subviews.count >=5)
        {
            NSTextField* sizeField = subView.subviews[4];
            if([sizeField isKindOfClass:[NSTextField class]])
            {
                [sizeField setTextColor:[NSColor alternateSelectedControlColor]];
            }
        }
    }
    [box setCornerRadius:4];
    [box setFillColor:color];
}

- (void)toggleSelectedState
{
    [self setSelected:!self.selected];
}


@end
