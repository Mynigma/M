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





#import "TintedImageButton.h"

@implementation TintedImageButton

- (void)awakeFromNib
{
    [super awakeFromNib];

    //ensure the image loaded from the nib is tinted with tintColor
    [self setImage:self.image];
    [self setAlternateImage:self.alternateImage];
}

- (void)setImage:(NSImage*)image
{
    [super setImage:[self tintedImage:image]];
}

- (void)setAlternateImage:(NSImage *)image
{
    [super setAlternateImage:[self tintedImage:image]];
}

- (NSImage*)tintedImage:(NSImage*)image
{
    if(!image || image.size.height == 0 || image.size.width == 0)
    {
        return nil;
    }

    NSImage *icon = [image copy];
    NSSize iconSize = [icon size];
    NSRect iconRect = {NSZeroPoint, iconSize};

    if(!self.tintColour)
        self.tintColour = [NSColor whiteColor];


    [icon lockFocus];
    [[self.tintColour colorWithAlphaComponent: 1] set];
    NSRectFillUsingOperation(iconRect, NSCompositeSourceAtop);
    [icon unlockFocus];

    return icon;
}

@end
