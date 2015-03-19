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

#import "MovingPlaceholderTextField.h"


@implementation MovingPlaceholderTextField


- (void)movePlaceholderToTopAnimated:(BOOL)animated
{
    //don't move placeholder if it's already in place
    if(self.placeholderLabelTopConstraint.priority < 500)
        return;
    
    [UIView animateWithDuration:animated?.3:0 animations:^{

        [self.placeholderLabel setFont:[UIFont systemFontOfSize:8]];

        [self.placeholderLabelBottomConstraint setConstant:-CGRectGetHeight(self.frame)];
        [self.placeholderLabelTopConstraint setPriority:1];

        [self setNeedsLayout];
        [self layoutIfNeeded];
    }];
}


- (void)movePlaceholderToBottomAnimated:(BOOL)animated
{
    //don't move placeholder if it's already in place
    if(self.placeholderLabelTopConstraint.priority > 500)
        return;
    
    [UIView animateWithDuration:animated?.3:0 animations:^{

        [self.placeholderLabel setFont:self.font];

        [self.placeholderLabelBottomConstraint setConstant:0];
        [self.placeholderLabelTopConstraint setPriority:999];

        [self setNeedsLayout];
        [self layoutIfNeeded];
    }];
}

- (void)setActive:(BOOL)active animated:(BOOL)animated
{
    [UIView animateWithDuration:animated?.3:0 animations:^{

        if(active)
        {
            [self.bottomLineHeightConstraint setConstant:self.bottomLineActiveHeight];
            [self setTintColor:self.bottomLineActiveColour];
            [self.bottomLine setBackgroundColor:self.bottomLineActiveColour];
        }
        else
        {
            [self.bottomLineHeightConstraint setConstant:self.bottomLineHeight];
            [self setTintColor:self.bottomLineColour];
            [self.bottomLine setBackgroundColor:self.bottomLineColour];
        }
        
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }];
}


- (void)setupStyle
{
    if(!self.bottomLine)
    {
        self.bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), 3)];

        [self.bottomLine setBackgroundColor:self.bottomLineColour];

        [self addSubview:self.bottomLine];

        [self.bottomLine setTranslatesAutoresizingMaskIntoConstraints:NO];

        NSLayoutConstraint* heightConstraint = [NSLayoutConstraint constraintWithItem:self.bottomLine attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:3];

        self.bottomLineHeightConstraint = heightConstraint;

        NSLayoutConstraint* leftConstraint = [NSLayoutConstraint constraintWithItem:self.bottomLine attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:0];

        NSLayoutConstraint* bottomConstraint = [NSLayoutConstraint constraintWithItem:self.bottomLine attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:0];

        NSLayoutConstraint* rightConstraint = [NSLayoutConstraint constraintWithItem:self.bottomLine attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:0];

        [self addConstraints:@[heightConstraint, leftConstraint, bottomConstraint, rightConstraint]];

        NSString* placeholderString = self.placeholder;

        self.placeholderLabel = [[UILabel alloc] initWithFrame:self.frame];

        [self addSubview:self.placeholderLabel];

        [self.placeholderLabel setTranslatesAutoresizingMaskIntoConstraints:NO];

        [self.placeholderLabel setText:placeholderString];
        [self.placeholderLabel setTextColor:[UIColor redColor]];

        NSLayoutConstraint* topConstraint = [NSLayoutConstraint constraintWithItem:self.placeholderLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0];

        [topConstraint setPriority:999];

        leftConstraint = [NSLayoutConstraint constraintWithItem:self.placeholderLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:0];

        bottomConstraint = [NSLayoutConstraint constraintWithItem:self.placeholderLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:0];

        rightConstraint = [NSLayoutConstraint constraintWithItem:self.placeholderLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:0];

        [self addConstraints:@[topConstraint, leftConstraint, bottomConstraint, rightConstraint]];

        self.placeholderLabelBottomConstraint = bottomConstraint;
        self.placeholderLabelTopConstraint = topConstraint;

        [self setClipsToBounds:NO];

        if(self.text.length)
        {
            [self movePlaceholderToTopAnimated:NO];
        }
        else
        {
            [self movePlaceholderToBottomAnimated:NO];
        }

        [self setPlaceholder:@""];
        
        [self.placeholderLabel setTextColor:self.placeHolderLabelColour];

        [self setActive:NO animated:NO];
        
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
}

- (void)awakeFromNib
{
    [self setupStyle];
    
    [super awakeFromNib];
}

- (void)prepareForInterfaceBuilder
{
    [self setupStyle];
    
    [super prepareForInterfaceBuilder];
}

- (BOOL)resignFirstResponder
{
    BOOL result = [super resignFirstResponder];
    
    if(result)
    {
       if(!self.text.length)
            [self movePlaceholderToBottomAnimated:YES];
    
        [self setActive:NO animated:YES];
    }
    
    return result;
}

- (BOOL)becomeFirstResponder
{
    BOOL result = [super becomeFirstResponder];
    
    if (result)
    {
        [self movePlaceholderToTopAnimated:YES];
        [self setActive:YES animated:YES];
    }
    return result;
}


- (void)setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];

    [self setTextColor:tintColor];
//    [self.placeholderLabel setTextColor:tintColor];
}

- (void)setText:(NSString *)text
{
    [super setText:text];

    if(self.text.length)
        [self movePlaceholderToTopAnimated:NO];
    else
        [self movePlaceholderToBottomAnimated:NO];
    
    [self layoutIfNeeded];
}

- (void)layoutSubviews
{
    [self layoutIfNeeded];
    [super layoutSubviews];
}

@end
