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





#import "MessageCell.h"
#import "EmailMessage+Category.h"
#import "AppDelegate.h"
#import "MessagesController.h"
#import "EmailMessageInstance+Category.h"
#import "IconListAndColourHelper.h"



@implementation MessageCell

@synthesize messageInstance;
@synthesize nameLabel;
@synthesize bodyView;
@synthesize pictureView;
@synthesize subjectLabel;
@synthesize dateLabel;

@synthesize topLeftIcon;
@synthesize centerLeftIcon;
@synthesize bottomLeftIcon;

@synthesize topLeftBox;
@synthesize bottomLeftBox;

@synthesize leftBarWidthConstraint;

@synthesize extraIcon1;
@synthesize extraIcon2;
@synthesize extraIcon3;
@synthesize extraIcon4;

@synthesize downloadProgressView;

@synthesize coinView;
@synthesize feedbackActivityIndicator;
@synthesize feedbackActivityIndicatorConstraint;
@synthesize feedBackContainer;
@synthesize messageContainer;

@synthesize iconDistanceConstraint;

@synthesize feedBackLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    //if(downloadProgressView)
    //    [self startAnimation];
}

- (void)updateSelectionStatus
{
    BOOL selected = (self.selected || self.highlighted);
    
    if(selected)
    {
        [self.messageContainer setBackgroundColor:NAVBAR_COLOUR];
    }
    else
        [self.messageContainer setBackgroundColor:[UIColor whiteColor]];
    
    //this needs to be here, for some reason...
    //otherwise the background colour for the loack box will switch back to clear
    [self setUpLockBox];

    for(UILabel* label in self.allLabels)
        [label setHighlighted:selected];
    
    for(UIImageView* imageView in self.allIcons)
        [imageView setHighlighted:selected];
}

- (void)setUpLockBox
{
    NSArray* leftIcons = (self.messageInstance!=nil)?[IconListAndColourHelper leftEdgeIconsForMessageInstance:messageInstance]:[IconListAndColourHelper leftEdgeIconsForMessage:self.message];
    
    switch(leftIcons.count)
    {
        case 0:
        {
            [leftBarWidthConstraint setConstant:0];
            break;
        }
        case 1:
        {
            [leftBarWidthConstraint setConstant:10];
            UIColor* colour = [leftIcons[0] objectForKey:@"colour"];

            [topLeftBox setBackgroundColor:colour];
            [bottomLeftBox setBackgroundColor:colour];
            break;
        }
        case 2:
        {
            [leftBarWidthConstraint setConstant:10];
            UIColor* colour1 = [leftIcons[0] objectForKey:@"colour"];
            UIColor* colour2 = [leftIcons[1] objectForKey:@"colour"];

            [topLeftBox setBackgroundColor:colour1];
            [bottomLeftBox setBackgroundColor:colour2];
            break;
        }
        default:
        {
            NSLog(@"Unsupported number of left edge icons!");
        }
    }
}

- (void)setUpIcons
{

    NSArray* extraIcons = (self.messageInstance!=nil)?[IconListAndColourHelper otherIconsForMessageInstance:messageInstance]:[IconListAndColourHelper otherIconsForMessage:self.message];
    if(extraIcons.count>0)
    {
        UIImage* whiteImage = [extraIcons[0] objectForKey:@"image"];

        UIImage* greyImage = [whiteImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

        [extraIcon1 setHighlightedImage:whiteImage];
        [extraIcon1 setImage:greyImage];
        [extraIcon1 showTheLogo];
    }
    else
    {
        [extraIcon1 setHighlightedImage:nil];
        [extraIcon1 setImage:nil];
        [extraIcon1 hideTheLogo];
    }

    if(extraIcons.count>1)
    {
        UIImage* whiteImage = [extraIcons[1] objectForKey:@"image"];

        UIImage* greyImage = [whiteImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        [extraIcon2 setHighlightedImage:whiteImage];
        [extraIcon2 setImage:greyImage];
        [extraIcon2 showTheLogo];
    }
    else
    {
        [extraIcon2 setImage:nil];
        [extraIcon2 setHighlightedImage:nil];
        [extraIcon2 hideTheLogo];
    }

    if(extraIcons.count>2)
    {
        UIImage* whiteImage = [extraIcons[2] objectForKey:@"image"];

        UIImage* greyImage = [whiteImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        [extraIcon3 setHighlightedImage:whiteImage];
        [extraIcon3 setImage:greyImage];
        [extraIcon3 showTheLogo];
    }
    else
    {
        [extraIcon3 setImage:nil];
        [extraIcon3 setHighlightedImage:nil];
        [extraIcon3 hideTheLogo];
    }

    if(extraIcons.count>3)
    {
        UIImage* whiteImage = [extraIcons[3] objectForKey:@"image"];

        UIImage* greyImage = [whiteImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        [extraIcon4 setHighlightedImage:whiteImage];
        [extraIcon4 setImage:greyImage];
        [extraIcon4 showTheLogo];
    }
    else
    {
        [extraIcon4 setImage:nil];
        [extraIcon4 setHighlightedImage:nil];
        [extraIcon4 hideTheLogo];
    }

    [iconDistanceConstraint setConstant:extraIcons.count>0?(2+22*extraIcons.count):0];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    if(messageInstance && ![messageContainer isHidden])
    {
        [self updateSelectionStatus];
    }
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if(messageInstance && ![messageContainer isHidden])
    {
        [self updateSelectionStatus];
    }

}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    if(messageInstance && ![messageContainer isHidden])
    {
        [self updateSelectionStatus];
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    if(messageInstance && ![messageContainer isHidden])
    {
        [self updateSelectionStatus];
    }
}


@end
