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





#import "ErrorLinkButton.h"
#import "IconListAndColourHelper.h"



@implementation ErrorLinkButton

- (void)awakeFromNib
{
    [self setCursor:[NSCursor pointingHandCursor]];
}

- (void)resetCursorRects
{
    NSAttributedString* attributedString = self.attributedTitle;

    __block BOOL isUnderlined = NO;

    [attributedString enumerateAttribute:NSUnderlineStyleAttributeName inRange:NSMakeRange(0, attributedString.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        if([value isEqual:@(NSUnderlineStyleSingle)])
            isUnderlined = YES;
    }];

    if (self.cursor && isUnderlined)
    {
        [self addCursorRect:[self bounds] cursor: self.cursor];
    } else {
        [super resetCursorRects];
    }
}

- (void)setAttributedTitle:(NSAttributedString *)attributedTitle
{
    [super setAttributedTitle:attributedTitle];
}

- (void)setAttributedStringValue:(NSAttributedString *)attributedStringValue
{
    [super setAttributedStringValue:attributedStringValue];
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
}

@end
