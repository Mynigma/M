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

#import "MovingPlaceholderTextField_Mac.h"


@implementation MovingPlaceholderTextField_Mac


- (void)movePlaceholderToTopAnimated:(BOOL)animated
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:animated?.3:0];
    
        [self.placeholderLabel setFont:[NSFont systemFontOfSize:8]];

        [self.placeholderLabelBottomConstraint setConstant:-CGRectGetHeight(self.frame)];
        [self.placeholderLabelTopConstraint setPriority:1];

    [self.placeholderLabel layout];
    
    [NSAnimationContext endGrouping];
}


- (void)movePlaceholderToBottomAnimated:(BOOL)animated
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:animated?.3:0];
    
        [self.placeholderLabel setFont:self.font];

        [self.placeholderLabelBottomConstraint setConstant:0];
        [self.placeholderLabelTopConstraint setPriority:999];

        [self.placeholderLabel layout];
    
    [NSAnimationContext endGrouping];
}

- (void)setActive:(BOOL)active animated:(BOOL)animated
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:animated?.3:0];

    if(active)
        {
            [self.bottomLineHeightConstraint setConstant:self.bottomLineActiveHeight];
            [self setTintColor:self.bottomLineActiveColour];
            [self.bottomLine setFillColor:self.bottomLineActiveColour];
        }
        else
        {
            [self.bottomLineHeightConstraint setConstant:self.bottomLineHeight];
            [self setTintColor:self.bottomLineColour];
            [self.bottomLine setFillColor:self.bottomLineColour];
        }
        
        [NSAnimationContext endGrouping];
}


- (void)setupStyle
{
    if(!self.bottomLine)
    {
        self.bottomLine = [[NSBox alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), 3)];

        [self.bottomLine setBorderColor:[NSColor clearColor]];
         
        [self.bottomLine setFillColor:self.bottomLineColour];

        [self addSubview:self.bottomLine];

        [self.bottomLine setTranslatesAutoresizingMaskIntoConstraints:NO];

        NSLayoutConstraint* heightConstraint = [NSLayoutConstraint constraintWithItem:self.bottomLine attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:3];

        self.bottomLineHeightConstraint = heightConstraint;

        NSLayoutConstraint* leftConstraint = [NSLayoutConstraint constraintWithItem:self.bottomLine attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:0];

        NSLayoutConstraint* bottomConstraint = [NSLayoutConstraint constraintWithItem:self.bottomLine attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:0];

        NSLayoutConstraint* rightConstraint = [NSLayoutConstraint constraintWithItem:self.bottomLine attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:0];

        [self addConstraints:@[heightConstraint, leftConstraint, bottomConstraint, rightConstraint]];

        NSString* placeholderString = self.placeholderString;

        self.placeholderLabel = [[NSTextField alloc] initWithFrame:self.frame];

        [self addSubview:self.placeholderLabel];

        [self.placeholderLabel setTranslatesAutoresizingMaskIntoConstraints:NO];

        [self.placeholderLabel setStringValue:placeholderString];
        [self.placeholderLabel setTextColor:[NSColor redColor]];

        NSLayoutConstraint* topConstraint = [NSLayoutConstraint constraintWithItem:self.placeholderLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0];

        [topConstraint setPriority:999];

        leftConstraint = [NSLayoutConstraint constraintWithItem:self.placeholderLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:0];

        bottomConstraint = [NSLayoutConstraint constraintWithItem:self.placeholderLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:0];

        rightConstraint = [NSLayoutConstraint constraintWithItem:self.placeholderLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:0];

        [self addConstraints:@[topConstraint, leftConstraint, bottomConstraint, rightConstraint]];

        self.placeholderLabelBottomConstraint = bottomConstraint;
        self.placeholderLabelTopConstraint = topConstraint;

        [self.layer setMasksToBounds:YES];

        if(self.stringValue.length)
        {
            [self movePlaceholderToTopAnimated:NO];
        }
        else
        {
            [self movePlaceholderToBottomAnimated:NO];
        }

        [self setPlaceholderString:@""];
        
        if(!self.internalDelegate)
        {
            [self setInternalDelegate:[MovingPlaceholderTextFieldInternalDelegate new]];

            [super setDelegate:self.internalDelegate];
        }


        [self.placeholderLabel setTextColor:self.placeHolderLabelColour];

        [self setActive:NO animated:NO];
    }
}

- (void)awakeFromNib
{
    [self setupStyle];
}

- (void)prepareForInterfaceBuilder
{
    [self setupStyle];
}

- (void)setDelegate:(id<NSTextFieldDelegate>)delegate
{
    if(!self.internalDelegate)
    {
        [self setInternalDelegate:[MovingPlaceholderTextFieldInternalDelegate new]];
     
        [super setDelegate:self.internalDelegate];
    }
    
    [(MovingPlaceholderTextFieldInternalDelegate*)self.internalDelegate setExternalDelegate:delegate];
}

- (void)setTintColor:(NSColor *)tintColour
{
//    [super setTintColor:tintColor];
    
    _tintColour = tintColour;

    [self setTextColor:tintColour];
//    [self.placeholderLabel setTextColor:tintColor];
}

- (void)setText:(NSString *)text
{
    [self setStringValue:text];
}

- (void)setStringValue:(NSString *)text
{
    [super setStringValue:text];
    
    if(self.stringValue.length)
        [self movePlaceholderToTopAnimated:NO];
    else
        [self movePlaceholderToBottomAnimated:NO];
}


@end
