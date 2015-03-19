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





#import "MultipleSelectionRowView.h"
#import "IconListAndColourHelper.h"


@implementation MultipleSelectionRowView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawSelectionInRect:(NSRect)dirtyRect
{
    if(self.useRoundedRect)
    {
    NSRect selectionRect = NSInsetRect(self.bounds, 2.5, 2.5);
    [[NSColor colorWithCalibratedWhite:.65 alpha:1.0] setStroke];
    [MYNIGMA_COLOUR setFill];
    NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRoundedRect:selectionRect xRadius:6 yRadius:6];
    [selectionPath fill];
    [selectionPath stroke];
    }
    else
    {
        [MYNIGMA_COLOUR setFill];
        NSRectFill(dirtyRect);
    }
}


@end
