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





#import "ContactCellView.h"

@implementation ContactCellView

@synthesize fbView;
@synthesize skypeView;
@synthesize detailView;
@synthesize lockView;
@synthesize groupImage1;
@synthesize groupImage2;
@synthesize groupImage3;
@synthesize groupImage4;
@synthesize groupImage5;
@synthesize groupImage6;
@synthesize groupImage7;
@synthesize groupImage8;
@synthesize groupImage9;
@synthesize contact;
@synthesize hasPicture;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        [self.textField setStringValue:@"This is alternative text"];
        
    }
    
    return self;
}


- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle {
    NSColor *textColor = (backgroundStyle == NSBackgroundStyleDark) ? [NSColor whiteColor] : [NSColor controlShadowColor];
    self.detailView.textColor = textColor;
    if(!hasPicture)
        [self.imageView setImage:[NSImage imageNamed:(backgroundStyle == NSBackgroundStyleDark)?@"accountWhite32.png":@"account32.png"]];
    
    
    if(!lockView.isHidden)
    {
        [lockView setImage:(backgroundStyle == NSBackgroundStyleDark)?[NSImage imageNamed:@"secureLockWhite32.png"]:[NSImage imageNamed:@"secureLock32.png"]];
    }
    [super setBackgroundStyle:backgroundStyle];
}

/*
- (void)drawRect:(NSRect)dirtyRect
{
    if(![self backgroundStyle]==NSBackgroundStyleDark && ![[APPDELEGATE.contactTable selectedRowIndexes] containsIndex:[APPDELEGATE.contactTable rowForView:self]])
    {
        if(contact && contact.hasMynigma && contact.hasMynigma.boolValue)
        {
            [[NSColor colorWithDeviceRed:245./255 green:255./255 blue:245./255 alpha:1] set];
            NSRectFill(self.frame);
        }
        else
        {
            
            //if([[self window] firstResponder]==APPDELEGATE.contactTable)
            //{
            [[NSColor whiteColor] set];
            NSRectFill(self.frame);
            //}
         }
    }
    else
    {
            [[NSColor colorWithDeviceRed:56./255 green:116./255 blue:215./255 alpha:1] set];
            NSRectFill(self.frame);
           // if(contact && contact.hasMynigma && contact.hasMynigma.boolValue && !lockView.isHidden)
             //   [lockView setImage:[NSImage imageNamed:@"secureLockWhite32.png"]];
    }
}*/
/*
- (NSArray *)draggingImageComponents {
    // Start with what is already there (this is an image and text component)
    NSMutableArray *result = [NSMutableArray array];//[[super draggingImageComponents] mutableCopy];
    
    // Snapshot the color view and add it in
    NSRect viewBounds = [self bounds];
    NSBitmapImageRep *imageRep = [self bitmapImageRepForCachingDisplayInRect:viewBounds];
    [self cacheDisplayInRect:viewBounds toBitmapImageRep:imageRep];
    
    NSImage *draggedImage = [[NSImage alloc] initWithSize:[imageRep size]];
    [draggedImage addRepresentation:imageRep];
    
    // Add in another component
    NSDraggingImageComponent *colorComponent = [NSDraggingImageComponent draggingImageComponentWithKey:@"Color"];
    colorComponent.contents = draggedImage;
    
    // Convert the frame to our coordinate system
    viewBounds = [self convertRect:viewBounds fromView:self];
    colorComponent.frame = viewBounds;
    
    [result addObject:colorComponent];
    return result;
}*/



@end
