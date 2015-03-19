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

#import <UIKit/UIKit.h>
#import "MovingPlaceHolderTextFieldInternalDelegate.h"



IB_DESIGNABLE

@interface MovingPlaceholderTextField : UITextField



- (void)movePlaceholderToTopAnimated:(BOOL)animated;
- (void)movePlaceholderToBottomAnimated:(BOOL)animated;

- (void)setActive:(BOOL)active animated:(BOOL)animated;



@property IBInspectable UIColor* placeHolderLabelColour;

@property IBInspectable UIColor* bottomLineColour;
@property IBInspectable UIColor* bottomLineActiveColour;
@property IBInspectable CGFloat bottomLineHeight;
@property IBInspectable CGFloat bottomLineActiveHeight;


@property UIView* bottomLine;
@property UILabel* placeholderLabel;


@property NSLayoutConstraint* bottomLineHeightConstraint;

@property NSLayoutConstraint* placeholderLabelBottomConstraint;
@property NSLayoutConstraint* placeholderLabelTopConstraint;



@end
