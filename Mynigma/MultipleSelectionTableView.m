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





#import "MultipleSelectionTableView.h"

@implementation MultipleSelectionTableView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extend
{
    [super selectRowIndexes:indexes byExtendingSelection:YES];

//    NSIndexSet* selectedIndexes = [self selectedRowIndexes];
//
//    NSMutableIndexSet* newSelectedIndexes = [selectedIndexes mutableCopy];
//
//    NSInteger index = indexes.firstIndex;
//
//    while(index!=NSNotFound)
//    {
//        if([selectedIndexes containsIndex:index])
//            [newSelectedIndexes removeIndex:index];
//        else
//            [newSelectedIndexes addIndex:index];
//
//        index = [indexes indexGreaterThanIndex:index];
//    }
//
//    [super selectRowIndexes:newSelectedIndexes byExtendingSelection:NO];
}

- (void)mouseDown:(NSEvent *)theEvent {

    NSPoint globalLocation = [theEvent locationInWindow];
    NSPoint localLocation = [self convertPoint:globalLocation fromView:nil];
    NSInteger clickedRow = [self rowAtPoint:localLocation];

    if (clickedRow != -1) {

        if([self.selectedRowIndexes containsIndex:clickedRow])
            [self deselectRow:clickedRow];
        else
            [super mouseDown:theEvent];
    }
    else
        [super mouseDown:theEvent];
}

@end
