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





#import "BodyInputView.h"
#import "objc/runtime.h"

@interface RemoveInputAccessoryHelper : NSObject @end

@implementation RemoveInputAccessoryHelper

- (id)inputAccessoryView
{
    return nil;
}

@end



@implementation BodyInputView


- (void)removeInputAccessoryView
{
    UIView* subview;

    for (UIView* view in self.scrollView.subviews) {
        if([[view.class description] hasPrefix:@"UIWeb"])
            subview = view;
    }

    if(subview == nil) return;

    NSString* name = [NSString stringWithFormat:@"%@_RemoveInputAccessoryHelper", subview.class.superclass];
    Class newClass = NSClassFromString(name);

    if(newClass == nil)
    {
        newClass = objc_allocateClassPair(subview.class, [name cStringUsingEncoding:NSASCIIStringEncoding], 0);
        if(!newClass) return;

        Method method = class_getInstanceMethod([RemoveInputAccessoryHelper class], @selector(inputAccessoryView));
        class_addMethod(newClass, @selector(inputAccessoryView), method_getImplementation(method), method_getTypeEncoding(method));

        objc_registerClassPair(newClass);
    }

    object_setClass(subview, newClass);
}

- (void)setHeightTo:(CGFloat)newHeight
{
    [self setHidden:NO];
    [self.heightConstraint setConstant:newHeight];
    [self setNeedsLayout];
}

- (void)makeInvisible
{
    [self.heightConstraint setConstant:0];
    [self setNeedsLayout];
    [self setHidden:YES];
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.scrollView setContentOffset:CGPointMake(0, 0)];
}

- (void)layoutIfNeeded
{
    [super layoutIfNeeded];
    [self.scrollView setContentOffset:CGPointMake(0, 0)];
}


@end
