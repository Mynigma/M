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





#import "DeviceItem.h"
#import "DeviceView.h"
#import "IconListAndColourHelper.h"



@interface DeviceItem ()

@end

@implementation DeviceItem

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}


- (void)setSelected:(BOOL)flag
{
    [super setSelected: flag];

    [self setDeviceImage:[NSImage imageNamed:@"iPhone_4S_small.png"]];
    
    DeviceView *deviceView = (DeviceView*)[self view];
    if([deviceView isKindOfClass:[DeviceView class]])
    {
        NSBox* box = (NSBox*)[deviceView subviews][0];
        NSColor *color;
        if (flag)
        {
            color = DARK_BLUE_COLOUR;
            [self setTextColor:[NSColor whiteColor]];
        }
        else
        {
            color = [NSColor clearColor];
            [self setTextColor:[NSColor controlTextColor]];
        }
        [box setCornerRadius:4];
        [box setFillColor:color];
    }
}

@end
