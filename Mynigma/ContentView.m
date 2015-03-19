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





#import "ContentView.h"
#import "EmailMessage.h"
#import "EmailMessageData.h"
#import "AppDelegate.h"
#import "ContentViewerCellView.h"
#import "EmailMessageInstance.h"
#import "SelectionAndFilterHelper.h"



@implementation ContentView


//- (void)resetCursorRects
//{
//    if(self.message.messageData.hasImages.boolValue && !self.message.messageData.loadRemoteImages.boolValue)
//    {
//        NSCursor* phCursor = [NSCursor pointingHandCursor];
//        [super addCursorRect:[self visibleRect] cursor:phCursor];
//        [phCursor setOnMouseEntered:YES];
//    }
//    else
//        [super resetCursorRects];
//}


/*
- (NSString*)toolTip
{
    if(message && message.hasImages.boolValue && !message.loadRemoteImages.boolValue)
    {
        return @"Click to load remote images\n(may be tracked by sender!)";
    }
    else
        return nil;
}*/

/*
- (void)addCursorRect:(NSRect)aRect cursor:(NSCursor *)anObj
{
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    //NSBeep();
    return YES;
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    //NSBeep();
}

- (void)addTrackingArea:(NSTrackingArea *)trackingArea
{
    NSBeep();
}

- (NSTrackingRectTag)addTrackingRect:(NSRect)aRect owner:(id)userObject userData:(void *)userData assumeInside:(BOOL)flag
{
    NSLog(@"adding tracking rect");
    return nil;
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    NSLog(@"mouse entered");
}*/

//- (NSView*)hitTest:(NSPoint)aPoint
//{
//    if(self.message.messageData.hasImages.boolValue && !self.message.messageData.loadRemoteImages.boolValue)
//        return self;
//    else
//        return [super hitTest:aPoint];
//}

//- (void)mouseDown:(NSEvent *)theEvent
//{
//    if(self.message.messageData.hasImages.boolValue && !self.message.messageData.loadRemoteImages.boolValue)
//    {
//        [self.message.messageData setLoadRemoteImages:[NSNumber numberWithBool:YES]];
//        ContentViewerCellView* contentViewerCellView = (ContentViewerCellView*)[[[self superview] superview] superview];
//        [contentViewerCellView.showImagesLabel setHidden:YES];
//        [SelectionAndFilterHelper refreshViewerShowingMessage:self.message];
//        [self removeAllToolTips];
//    }
//    else
//        [super mouseDown:theEvent];
//}

//- (IBAction)addFontTrait:(id)sender
//{
//    [[NSFontManager sharedFontManager] addFontTrait:sender];
//}

@end
