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

#import "MoveMessageIconView.h"
#import "TintedImageView.h"
#import "UIView+LayoutAdditions.h"



@implementation MoveMessageIconView

- (void)setUp
{
    if(self.mainImage)
    {
//        TintedImageView* imageView = [[TintedImageView alloc] initWithImage:self.icon];
//        
//        [imageView setTintColor:self.tintColor];
//        
//        [self addSubview:imageView];
//        [imageView setTranslatesAutoresizingMaskIntoConstraints:NO];
//        
//        NSLayoutConstraint* topConstraint = [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:16];
//        NSLayoutConstraint* leftConstraint = [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:26];
//        NSLayoutConstraint* bottomConstraint = [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:36];
//        NSLayoutConstraint* rightConstraint = [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:26];
//
//        [self addConstraints:@[topConstraint, rightConstraint, bottomConstraint, leftConstraint]];
//        
//        
//        UILabel* newLabel = [UILabel new];
//        
//        [newLabel setText:self.labelText];
//        
//        NSLayoutConstraint* centerConstraint = [NSLayoutConstraint constraintWithItem:newLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
//        
//        bottomConstraint = [NSLayoutConstraint constraintWithItem:newLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:16];
//        
//        [self addConstraints:@[centerConstraint, bottomConstraint]];
//        
//        
//        [self setNeedsLayout];
//        [self layoutIfNeeded];
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

@end
