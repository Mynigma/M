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

#import "MoveMessageImageView.h"
#import "TintedImageView.h"




@implementation MoveMessageImageView

- (void)setUp
{
    self.isEnabled = YES;
    
    [self setBackgroundColor:[UIColor clearColor]];

    if(self.mainImage)
    {        
        TintedImageView* imageView = [[TintedImageView alloc] initWithImage:self.mainImage];
        
        self.imageView = imageView;
        
        [imageView setTintColor:self.tintColor];
        
        [self addSubview:imageView];
        [imageView setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        NSLayoutConstraint* topConstraint = [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:16];
        NSLayoutConstraint* centerConstraint = [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
//        NSLayoutConstraint* bottomConstraint = [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:-36];
//        NSLayoutConstraint* rightConstraint = [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:-26];
        
        [self addConstraints:@[topConstraint, centerConstraint]];
        
        
        UILabel* newLabel = [UILabel new];
        
        self.textLabel = newLabel;
        
        [newLabel setText:self.labelText];
        [newLabel setTextColor:self.tintColor];
        [newLabel setTextAlignment:NSTextAlignmentCenter];
        
        [newLabel setAdjustsFontSizeToFitWidth:YES];
        [newLabel setMinimumScaleFactor:.25];
        
        [self addSubview:newLabel];
        [newLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        NSLayoutConstraint* leftConstraint = [NSLayoutConstraint constraintWithItem:newLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:5];
        
        NSLayoutConstraint* rightConstraint = [NSLayoutConstraint constraintWithItem:newLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:-5];
        
        NSLayoutConstraint* bottomConstraint = [NSLayoutConstraint constraintWithItem:newLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:-10];
        
        [self addConstraints:@[rightConstraint, bottomConstraint, leftConstraint]];
        
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
}

- (void)awakeFromNib
{
    [self setUp];
}

- (void)prepareForInterfaceBuilder
{
    [self setUp];
}


- (void)setEnabled:(BOOL)enabled
{
    self.isEnabled = enabled;
    
    [self.textLabel setTextColor:enabled?self.tintColor:self.disabledTintColour];
    [self.imageView setTintColor:enabled?self.tintColor:self.disabledTintColour];
}



@end
