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





#import "LinkButton.h"
#import "AppDelegate.h"
#import "IconListAndColourHelper.h"

@implementation LinkButton

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.

        }
    return self;
}

- (void)awakeFromNib
{
    [self setCursor:[NSCursor pointingHandCursor]];

    NSMutableAttributedString* linkStyleTitle = [self.attributedTitle?self.attributedTitle:[NSAttributedString new] mutableCopy];
    [linkStyleTitle addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, linkStyleTitle.length)];
    [linkStyleTitle addAttribute:NSForegroundColorAttributeName value:DARKISH_BLUE_COLOUR range:NSMakeRange(0, linkStyleTitle.length)];
    [self setAttributedTitle:linkStyleTitle];
    [self setNeedsLayout:YES];
}


- (void)resetCursorRects
{
    if (self.cursor) {
        [self addCursorRect:[self bounds] cursor: self.cursor];
    } else {
        [super resetCursorRects];
    }
}

@end
