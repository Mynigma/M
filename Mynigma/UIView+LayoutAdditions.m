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

#import "UIView+LayoutAdditions.h"

@implementation UIView (LayoutAdditions)

- (void)setUpConstraintsToFitIntoSuperview
{
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];

    UIView* superview = self.superview;

    if(!superview)
        return;

    NSLayoutConstraint* topConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    NSLayoutConstraint* leftConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
    NSLayoutConstraint* bottomConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
    NSLayoutConstraint* rightConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeRight multiplier:1 constant:0];
    //NSLayoutConstraint* heightConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:1];


    [superview addConstraints:@[topConstraint, leftConstraint, bottomConstraint, rightConstraint]];
//
//    [superview layoutIfNeeded];
}

- (void)fixHeightAndWidth
{
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];

    CGFloat fixedHeight = MAX(self.frame.size.height, 0);
    CGFloat fixedWidth = MAX(self.frame.size.width, 0);

    NSLayoutConstraint* widthConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1. constant:fixedWidth];

    NSLayoutConstraint* heightConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1. constant:fixedHeight];

    [self removeConstraints:self.constraints];

    [self addConstraints:@[widthConstraint, heightConstraint]];

    [self.superview layoutIfNeeded];
}


@end
