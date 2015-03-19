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





#import "MynTokenIBField.h"
#import "MynTokenFieldController.h"
#import "MynTokenField.h"


@implementation MynTokenIBField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        MynTokenFieldController* tokenFieldController = [[MynTokenFieldController alloc] initWithNibName:@"MynTokenFieldController" bundle:nil];

        UIView* tokenView = tokenFieldController.view;

        [tokenView setTranslatesAutoresizingMaskIntoConstraints:NO];

        self.tokenFieldController = tokenFieldController;

        [self addSubview:tokenView];

        NSLayoutConstraint* topConstraint = [NSLayoutConstraint constraintWithItem:tokenView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0];

        NSLayoutConstraint* rightConstraint = [NSLayoutConstraint constraintWithItem:tokenView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:0];

        NSLayoutConstraint* bottomConstraint = [NSLayoutConstraint constraintWithItem:tokenView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:0];

        NSLayoutConstraint* leftConstraint = [NSLayoutConstraint constraintWithItem:tokenView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:0];

        [self addConstraints:@[topConstraint, rightConstraint, bottomConstraint, leftConstraint]];

        [self setShouldHide:NO];
    }

    return self;
}


- (void)awakeFromNib
{
    [self.tokenFieldController setTokenFieldDelegate:self.tokenFieldDelegate];
}


//- (CGSize)intrinsicContentSize
//{
//    CGSize tokenFieldSize = [self.tokenFieldController.tokenField intrinsicContentSize];
//
//    CGFloat tableViewHeight = self.tokenFieldController.tokenFieldView.tableViewHeightConstraint.constant;
//
//    CGFloat height = tokenFieldSize.height + 1 + tableViewHeight;
//
//    return CGSizeMake(tokenFieldSize.width, height);
//}


- (void)setPrompt:(NSString*)prompt
{
    [self.tokenFieldController.tokenField setPromptText:prompt];
}


- (NSArray*)recipients
{
    return [self.tokenFieldController.tokenField.tokens valueForKey:@"representedObject"];
}


- (NSArray*)tokens
{
    return self.tokenFieldController.tokenField.tokens;
}


- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    [self setShouldHide:hidden];
    [self invalidateIntrinsicContentSize];
}

- (BOOL)isHidden
{
    return self.shouldHide;
}

- (void)toggleHidden
{
    [self setHidden:!self.isHidden];
}

- (CGSize)intrinsicContentSize
{
    CGFloat width = self.window.screen.bounds.size.width;

    if(self.rightMargin)
        width -= self.rightMargin.floatValue;

    if(self.shouldHide)
        return CGSizeMake(width, 0);

    CGFloat height = self.tokenFieldController.tokenField.tokenFieldHeightConstraint.constant + 1 + self.tokenFieldController.tokenFieldView.tableViewHeightConstraint.constant;

    //NSLog(@"Height: %f", height);

    return CGSizeMake(width, height);
}

- (void)removeAllTokens
{
    [self.tokenFieldController.tokenField removeAllTokens];
}

- (void)addTokenWithTitle:(NSString*)title representedObject:(id)representedObject
{
    [self.tokenFieldController.tokenField addTokenWithTitle:title representedObject:representedObject];
}

- (void)addTokenWithTitle:(NSString*)title representedObject:(id)representedObject tintColour:(UIColor*)colour
{
    TIToken* token = [self.tokenFieldController.tokenField addTokenWithTitle:title representedObject:representedObject];
    [token setTintColor:colour];
}

- (void)setEnabled:(BOOL)enabled
{
    [self.tokenFieldController.tokenField setEnabled:enabled];
}

- (void)hideIfEmpty
{
    if(self.tokenFieldController.tokenField.tokens.count==0)
        [self setHidden:YES];
    else
        [self setHidden:NO];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [self.tokenFieldController.tokenField setBackgroundColor:backgroundColor];
}

- (void)layoutSubviews
{
    [self.tokenFieldController.tokenField layoutTokensAnimated:YES];
    [super layoutSubviews];
}

@end
