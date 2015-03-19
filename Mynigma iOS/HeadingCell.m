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





#import "HeadingCell.h"

@implementation HeadingCell

@synthesize txtLabel;
@synthesize isOpen;
@synthesize arrowHeadImage;

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
    [super setSelected:selected animated:animated];

    [self setBackgroundColor:[UIColor colorWithRed:52/255. green:64/255. blue:97/255. alpha:1]];

    [arrowHeadImage setImage:[UIImage imageNamed:isOpen?@"downArrowHead.png":@"rightArrowHead.png"]];

    //[self setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"LeftMenuButtonDownNarrow.png"]]];

    // Configure the view for the selected state
}

@end
