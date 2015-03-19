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





#import "AccountCell.h"
#import "CustomBadge.h"
#import "IMAPAccountSetting.h"
#import "AppDelegate.h"
#import "OutlineObject.h"
#import "IconListAndColourHelper.h"
#import "SelectionAndFilterHelper.h"


@implementation AccountCell

@synthesize nameLabel;
@synthesize detailLabel;
@synthesize unreadBadge;
@synthesize accountImageView;
@synthesize backgroundImage;
@synthesize representedObject;
@synthesize imageConstraint;

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
    if(accountImageView.image)
        [imageConstraint setPriority:1];
    else
        [imageConstraint setPriority:999];

    OutlineObject* top = [SelectionAndFilterHelper sharedInstance].topSelection;
    OutlineObject* bottom = [SelectionAndFilterHelper sharedInstance].bottomSelection;

    BOOL isSelected = ([top isEqual:representedObject] || [bottom isEqual:representedObject]);
    
    [super setSelected:isSelected animated:NO];

    if(isSelected)
    {
        CALayer* layer = nameLabel.layer;

        [layer setShadowColor:CGColorRetain([[UIColor whiteColor] CGColor])];
        [layer setShadowOffset:CGSizeMake(0, 0)];
        [layer setShadowOpacity:.4];
        [layer setShadowRadius:1];

        layer = accountImageView.layer;

        [layer setShadowColor:CGColorRetain([[UIColor whiteColor] CGColor])];
        [layer setShadowOffset:CGSizeMake(0, 0)];
        [layer setShadowOpacity:.7];
        [layer setShadowRadius:4];

         [self setBackgroundColor:SELECTION_BLUE_COLOUR];
    }
    else
    {
        CALayer* layer = nameLabel.layer;
        [layer setShadowRadius:0];

        layer = accountImageView.layer;
        [layer setShadowRadius:0];

        [self setBackgroundColor:DARK_BLUE_COLOUR];
    }
}

- (void)setSelected:(BOOL)selected
{
    [self setSelected:selected animated:YES];
}


@end
