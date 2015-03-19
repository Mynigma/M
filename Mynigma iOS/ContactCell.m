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





#import "ContactCell.h"
#import "IconListAndColourHelper.h"

@implementation ContactCell

@synthesize nameField;
@synthesize detailLabel;
@synthesize picView;

@synthesize isSelected;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:isSelected animated:NO];

    if(isSelected)
    {
        CALayer* layer = nameField.layer;

        [layer setShadowColor:CGColorRetain([[UIColor whiteColor] CGColor])];
        [layer setShadowOffset:CGSizeMake(0, 0)];
        [layer setShadowOpacity:.4];
        [layer setShadowRadius:1];

        layer = detailLabel.layer;

        [layer setShadowColor:CGColorRetain([[UIColor whiteColor] CGColor])];
        [layer setShadowOffset:CGSizeMake(0, 0)];
        [layer setShadowOpacity:.4];
        [layer setShadowRadius:1];

        layer = picView.layer;

        [layer setCornerRadius:16];
        [layer setBorderColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1].CGColor];
        [layer setBorderWidth:1];
        [layer setMasksToBounds:YES];

        [layer setShadowColor:CGColorRetain([[UIColor whiteColor] CGColor])];
        [layer setShadowOffset:CGSizeMake(0, 0)];
        [layer setShadowOpacity:.7];
        [layer setShadowRadius:4];

        //[self setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"LeftMenuButton.png"]]];

        [self setBackgroundColor:SELECTION_BLUE_COLOUR];

    }
    else
    {
        CALayer* layer = nameField.layer;
        [layer setShadowRadius:0];

        layer = detailLabel.layer;
        [layer setShadowRadius:0];

        layer = picView.layer;
        [layer setShadowRadius:0];

        [layer setCornerRadius:16];
        [layer setBorderColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:.7].CGColor];
        [layer setBorderWidth:1];
        [layer setMasksToBounds:YES];

        //[self setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"LeftMenuButtonDown.png"]]];

        [self setBackgroundColor:DARK_BLUE_COLOUR];//[UIColor colorWithRed:41/255. green:52/255. blue:86/255. alpha:1]];
    }

    // Configure the view for the selected state
}

@end
