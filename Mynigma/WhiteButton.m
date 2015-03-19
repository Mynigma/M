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





#import "WhiteButton.h"

@implementation WhiteButton

- (void)awakeFromNib
{
    NSMutableAttributedString* attributedTitle = [self.attributedTitle mutableCopy];
    [attributedTitle addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0, attributedTitle.length)];
    [self setAttributedTitle:attributedTitle];

//    [attributedTitle addAttribute:NSForegroundColorAttributeName value:[NSColor controlColor] range:NSMakeRange(0, attributedTitle.length)];
//    [self setAttributedAlternateTitle:attributedTitle];
//
//    [self setAlternateImage:self.image];

//  [self.cell setHighlightsBy:[(NSButtonCell*)self.cell highlightsBy] | (NSChangeGrayCellMask | NSContentsCellMask)];
//[self.cell setHighlightsBy:NSContentsCellMask];
    [self.cell setHighlightsBy:NSNoCellMask];
}

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    NSMutableAttributedString* attributedTitle = [self.attributedTitle mutableCopy];
    [attributedTitle addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0, attributedTitle.length)];
    [self setAttributedTitle:attributedTitle];
}

@end
