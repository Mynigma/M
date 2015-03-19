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





#import "AttachmentOverlayStringTransformer.h"

@implementation AttachmentOverlayStringTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (NSString*)transformedValue:(NSNumber*)value
{
    if(value.floatValue <= -.9)
        return NSLocalizedString(@"Attachment missing", @"Attachment icon overlay");

    if(value.floatValue <= 0.001)
        return NSLocalizedString(@"Click to download", @"Attachment icon overlay");

    if(value.floatValue >= 1.)
        return NSLocalizedString(@"Downloading...", @"Attachment icon overlay");

    return @"";
}

@end
