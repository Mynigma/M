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





#import "LittleLogoView.h"

@implementation LittleLogoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

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
    if(self.image.renderingMode != UIImageRenderingModeAlwaysTemplate)
        self.image = [self.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    [self setTintColor:[UIColor lightGrayColor]];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
