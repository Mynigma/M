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





#import "MessageRowView.h"
#import "MessageCellView.h"
#import "EmailMessage.h"
#import "AppDelegate.h"
#import "MynigmaMessage.h"

#import "IconListAndColourHelper.h"
#import "EmailMessageInstance+Category.h"


@implementation MessageRowView

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
    [[NSColor whiteColor] setFill];

    NSRectFill(dirtyRect);

    [super drawRect:dirtyRect];

//    //NSView* cellView = [self.subviews objectAtIndex:0];
//    [[NSColor whiteColor] setFill];
//
//    if(cellView && [cellView isKindOfClass:[MessageCellView class]])
//    {
//        NSInteger index = [APPDELEGATE.messagesTable rowForView:cellView];
//        if(index!=NSNotFound && index>=0)
//        {
//            //if(![APPDELEGATE.messagesTable.selectedRowIndexes containsIndex:index])
//            {
//       EmailMessage* message = [(MessageCellView*)cellView message];
//        
//        NSArray* leftIcons = [APPDELEGATE leftEdgeIconsForMessage:message];
//        CGFloat offsetFromTop = 0;
//        NSInteger index = 1;
//        for(NSDictionary* iconDict in leftIcons)
//        {
//            NSRect drawingRect = self.bounds;
//            
//            //the coloured rect stretches to the width of the left border
//            drawingRect.size.width = LEFT_BORDER_OFFSET;
//            
//            CGFloat totalHeight = drawingRect.size.height-1;
//            
//            //if it's the last item take exactly the space that's left - this prevents rounding errors leading to drawing outside the proper area
//            if(index==leftIcons.count)
//                drawingRect.size.height = totalHeight - offsetFromTop;
//            else //otherwise just divide the total height (minus 1 for the border) by the number of icons
//                drawingRect.size.height = totalHeight/leftIcons.count;
//            
//            //the vertical origin is the distance to the top minus the height of the rectangle
//            drawingRect.origin.y = offsetFromTop;
//            
//            //the next icon should be offset from the top by the the height of the current item
//            offsetFromTop +=drawingRect.size.height;
//            
//            //set the fill colour to the value given in the iconDict
//            [[iconDict objectForKey:@"colour"] setFill];
//            
//            //fill it!
//            NSBezierPath* selectionPath = [NSBezierPath bezierPathWithRect:drawingRect];
//            [selectionPath fill];
//            
//            //the icon itself is drawn by MessageCellView
//            
//            //next index
//            index++;
//        }
//            }
//        }
//        else
//        {
//            NSLog(@"Row not found for message cell view!!!");
//        }
//   }
//    else
//        NSLog(@"The row has no message cell view!!!");

}

- (void)drawSelectionInRect:(NSRect)dirtyRect
{
    NSView* cellView = ([self.subviews count] > 0)?[self.subviews objectAtIndex:0]:nil;
    
    if([cellView isKindOfClass:[MessageCellView class]])
    {
        EmailMessageInstance* messageInstance = [(MessageCellView*)cellView messageInstance];
        NSArray* leftIcons = (messageInstance!=nil)?[IconListAndColourHelper leftEdgeIconsForMessageInstance:messageInstance]:[IconListAndColourHelper leftEdgeIconsForMessage:[(MessageCellView*)cellView message]];
        if(leftIcons.count>0)
        {
            dirtyRect.origin.x += LEFT_BORDER_OFFSET + .5;//(messageInstance.isUnread?1:0); //hack
            dirtyRect.size.width -= LEFT_BORDER_OFFSET + .5;//(messageInstance.isUnread?1:0);
        }

        //dirtyRect.size.width -= 1;

        //[[NSColor colorWithCalibratedRed:41/255. green:52/255. blue:86/255. alpha:1] setFill];
        [ACCOUNT_SELECTION_COLOUR setFill];
        NSRectFill(dirtyRect);
    }
    //[super drawSelectionInRect:dirtyRect];
}



- (BOOL)isEmphasized
{
    return self.isSelected;
}

@end
