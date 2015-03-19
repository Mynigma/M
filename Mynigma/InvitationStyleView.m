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





#import "InvitationStyleView.h"

@implementation InvitationStyleView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
    NSTableRowView* rowView = (NSTableRowView*)self.superview;

    if([rowView isKindOfClass:[NSTableRowView class]])
    {
        BOOL isSelected = rowView.selected;
    NSColor* darkTextColor = (isSelected) ? [NSColor whiteColor] : [NSColor textColor];

    NSColor *textColor = (isSelected) ? [NSColor whiteColor] : [NSColor disabledControlTextColor];

    //NSColor *lighterTextColor = (backgroundStyle == NSBackgroundStyleDark) ? [NSColor whiteColor] : [NSColor secondarySelectedControlColor];

    [self.textField setTextColor:darkTextColor];
    [self.detailField setTextColor:textColor];
    }


    [super setBackgroundStyle:backgroundStyle];
}

@end
