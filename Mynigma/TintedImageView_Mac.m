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

#import "TintedImageView_Mac.h"

@implementation TintedImageView

- (void)awakeFromNib
{
    [super awakeFromNib];

    //ensure the image loaded from the nib is tinted with tintColor
    [self setImage:self.image];
}

/* // CRASHES IN 10.9
- (void)setImage:(NSImage*)image
{
    [super setImage:[self tintedImage:image]];
}*/

- (NSImage*)tintedImage:(NSImage*)image
{
    if(!image || image.size.height == 0 || image.size.width == 0)
    {
        return nil;
    }

    NSImage *icon = [image copy];
    NSSize iconSize = [icon size];
    NSRect iconRect = {NSZeroPoint, iconSize};

    if(!_tintColor)
        _tintColor = [NSColor whiteColor]; //crashes here in 10.9


    [icon lockFocus];
    [[_tintColor colorWithAlphaComponent: 1] set];
    NSRectFillUsingOperation(iconRect, NSCompositeSourceAtop);
    [icon unlockFocus];
    
    return icon;
}

- (void)setTintColor:(NSColor *)tintColor
{
    _tintColor = tintColor;
    [self setImage:[self tintedImage:self.image]];
}

@end
