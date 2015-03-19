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





#import "MessageListIconView.h"

@implementation MessageListIconView

- (void)hideTheLogo
{
    [self setHidden:YES];
    [self.hideConstraint setPriority:999];
    //[self.superview layoutSubviews];
}

- (void)showTheLogo
{
    [self setHidden:NO];
    [self.hideConstraint setPriority:1];
    //[self.superview layoutSubviews];
}

- (void)setImage:(NSImage *)newImage withTintColour:(NSColor*)tintColour
{
    if(!newImage)
        return;

    NSImage *icon = [newImage copy];
    NSSize iconSize = [icon size];
    NSRect iconRect = {NSZeroPoint, iconSize};

    if(iconSize.height == 0 || iconSize.width == 0)
        return;

    [icon lockFocus];
    [[tintColour colorWithAlphaComponent: 1] set];
    NSRectFillUsingOperation(iconRect, NSCompositeSourceAtop);
    [icon unlockFocus];

    [super setImage:icon];
}

@end
