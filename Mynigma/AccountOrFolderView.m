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





#define FOLDERSVIEW_BACKGROUND_COLOUR [NSColor colorWithDeviceRed:41/255. green:52/255. blue:86/255. alpha:1]

#import <QuartzCore/QuartzCore.h>
#import "AccountOrFolderView.h"
#import "AccountRowView.h"

@implementation AccountOrFolderView

@synthesize representedObject;
@synthesize imageConstraint;
@synthesize unreadContraint;
@synthesize imageView;
@synthesize statusImage;
@synthesize statusLabel;
@synthesize textField;
@synthesize safeConstraint;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}



- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle {

    [super setBackgroundStyle:backgroundStyle];

//    if(backgroundStyle==NSBackgroundStyleDark)
//    {
//        [textField setTextColor:[NSColor blueColor]];
        [textField setTextColor:[NSColor whiteColor]];
        [self.nameField setTextColor:[NSColor whiteColor]];
        [self.unreadTextField setTextColor:[NSColor whiteColor]];
        
        NSColor *color = [NSColor whiteColor];
        NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[self.unreadButton attributedTitle]];
        NSRange titleRange = NSMakeRange(0, [colorTitle length]);
        [colorTitle addAttribute:NSForegroundColorAttributeName value:color range:titleRange];
        
        [self.unreadButton setAttributedTitle:colorTitle];
//    }
//    else
//    {
//        [textField setTextColor:[NSColor redColor]];
//        [self.nameField setTextColor:[NSColor redColor]];
//        [self.unreadTextField setTextColor:[NSColor redColor]];
//        
//        NSColor *color = [NSColor redColor];
//        NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[self.unreadButton attributedTitle]];
//        NSRange titleRange = NSMakeRange(0, [colorTitle length]);
//        [colorTitle addAttribute:NSForegroundColorAttributeName value:color range:titleRange];
//        [self.unreadButton setAttributedTitle:colorTitle];
//}
    
    /*
    [imageConstraint setPriority:1];
    if(representedObject)
        if([representedObject respondsToSelector:@selector(displayImage)])
            if(![(AbstractFolder*)representedObject displayImage])
                [imageConstraint setPriority:999];
*/
    /*
    if([(AccountRowView*)self.superview isSelected])
    {
        CALayer* layer = statusImage.layer;

        [layer setShadowColor:CGColorRetain([[NSColor whiteColor] CGColor])];
        [layer setShadowOffset:CGSizeMake(0, 0)];
        [layer setShadowOpacity:.4];
        [layer setShadowRadius:1];

        [textField setTextColor:[NSColor whiteColor]];
        layer = textField.layer;

        NSShadow* newShadow = [NSShadow new];
        [newShadow setShadowColor:[NSColor colorWithCalibratedWhite:1 alpha:.4]];
        [newShadow setShadowOffset:NSMakeSize(0,0)];
        [newShadow setShadowBlurRadius:4];
        [textField setShadow:newShadow];
    }
    else
    {
        CALayer* layer = statusImage.layer;
        [layer setShadowRadius:0];

        [textField setTextColor:[NSColor colorWithDeviceRed:225/255. green:231/255. blue:239/255. alpha:1]];
        layer = textField.layer;
        [layer setShadowRadius:0];
    }*/


    /*
     if(backgroundStyle == NSBackgroundStyleDark)
     {
     [self.imageView setImage:[NSImage imageNamed:isAccount?@"accountWhite32.png":@"folderWhite32.png"]];
     [self.textField setTextColor:[NSColor whiteColor]];
     }
     else
     {
     [self.imageView setImage:[NSImage imageNamed:isAccount?@"account32.png":@"folder32.png"]];
     if(isGray)
     [self.textField setTextColor:[NSColor controlShadowColor]];
     else
     [self.textField setTextColor:[NSColor selectedKnobColor]];
     }*/
}



- (NSArray *)draggingImageComponents
{
    // Start with what is already there (this is an image and text component)
    NSMutableArray *result = [NSMutableArray array];//[[super draggingImageComponents] mutableCopy];

    NSRect viewBounds = [self bounds];
    NSBitmapImageRep *imageRep = [self bitmapImageRepForCachingDisplayInRect:viewBounds];
    [self cacheDisplayInRect:viewBounds toBitmapImageRep:imageRep];

    NSImage *draggedImage = [[NSImage alloc] initWithSize:[imageRep size]];
    [draggedImage addRepresentation:imageRep];

    NSImage* resultImage = [[NSImage alloc] initWithSize:viewBounds.size];
    [resultImage lockFocus];

    [FOLDERSVIEW_BACKGROUND_COLOUR setFill];
    [NSBezierPath fillRect:viewBounds];
    [draggedImage drawAtPoint:NSMakePoint(0, 0) fromRect:self.bounds operation:NSCompositeSourceOver fraction:1.0];
    
    [resultImage unlockFocus];

    NSDraggingImageComponent *iconComponent = [NSDraggingImageComponent draggingImageComponentWithKey:NSDraggingImageComponentIconKey];
    iconComponent.contents = resultImage;

    viewBounds = [self convertRect:viewBounds fromView:self];
    iconComponent.frame = viewBounds;

    [result addObject:iconComponent];
    return result;
}


- (BOOL)allowsVibrancy
{
//    return NO;
    return YES;
}


@end
