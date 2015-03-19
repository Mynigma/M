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

#import "MovingPlaceHolderTextFieldInternalDelegate.h"
#import "MovingPlaceholderTextField.h"
#include <objc/message.h>



@implementation MovingPlaceholderTextFieldInternalDelegate


- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if([textField isKindOfClass:[MovingPlaceholderTextField class]])
    {
        [(MovingPlaceholderTextField*)textField movePlaceholderToTopAnimated:YES];

        [(MovingPlaceholderTextField*)textField setActive:YES animated:YES];
    }

    if([self.externalDelegate respondsToSelector:@selector(textFieldDidBeginEditing:)])
        [self.externalDelegate performSelector:@selector(textFieldDidBeginEditing:) withObject:textField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if([textField isKindOfClass:[MovingPlaceholderTextField class]])
    {
    }

    if([self.externalDelegate respondsToSelector:@selector(textFieldDidEndEditing:)])
        [self.externalDelegate performSelector:@selector(textFieldDidEndEditing:) withObject:textField];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if([self.externalDelegate respondsToSelector:@selector(textFieldShouldReturn:)])
        return [self.externalDelegate textFieldShouldReturn:textField];

    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if([self.externalDelegate respondsToSelector:@selector(textFieldShouldEndEditing:)])
        return [self.externalDelegate textFieldShouldEndEditing:textField];
    
    return YES;
}

//- (BOOL)respondsToSelector:(SEL)aSelector
//{
//    if(aSelector == @selector(textFieldDidBeginEditing:))
//        return YES;
//
//    if(aSelector == @selector(textFieldDidEndEditing:))
//        return YES;
//
//    return [self.externalDelegate respondsToSelector:aSelector];
//}


@end
