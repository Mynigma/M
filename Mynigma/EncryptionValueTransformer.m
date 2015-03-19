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





#import "EncryptionValueTransformer.h"
#import <MailCore/MailCore.h>

@implementation EncryptionValueTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (NSNumber*)transformedValue:(NSNumber*)value
{
    if(value == nil)
        return @0;

    switch (value.integerValue)
    {
        case MCOConnectionTypeClear:
            return @2;
        case MCOConnectionTypeStartTLS:
            return @1;
        case MCOConnectionTypeTLS:
        default:
            return @0;
    }
}

- (NSNumber*)reverseTransformedValue:(NSNumber*)value
{
    if(value == nil)
        return @(MCOConnectionTypeTLS);

    switch(value.integerValue)
    {
        case 2:
            return @(MCOConnectionTypeClear);
        case 1:
            return @(MCOConnectionTypeStartTLS);
        case 0:
        default:
            return @(MCOConnectionTypeTLS);
    }
}


@end
