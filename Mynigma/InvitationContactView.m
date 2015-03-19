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





#import "InvitationContactView.h"
#import <QuartzCore/QuartzCore.h>

@implementation InvitationContactView

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
    CALayer* layer = self.imageView.layer;

    [layer setCornerRadius:16];
    [layer setBorderColor:[NSColor whiteColor].CGColor];
    [layer setBorderWidth:1];
    [layer setMasksToBounds:YES];
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
    BOOL isSelected = self.pickBox.state == NSOnState;

    NSColor* darkTextColor = (isSelected) ? [NSColor whiteColor] : [NSColor textColor];

    NSColor *textColor = (isSelected) ? [NSColor whiteColor] : [NSColor disabledControlTextColor];

    NSColor *lighterTextColor = (isSelected) ? [NSColor whiteColor] : [NSColor secondarySelectedControlColor];

    [self.textField setTextColor:darkTextColor];
    [self.emailField setTextColor:textColor];
    [self.hasUsedMynigmaField setTextColor:lighterTextColor];

    [super setBackgroundStyle:backgroundStyle];
}



@end
