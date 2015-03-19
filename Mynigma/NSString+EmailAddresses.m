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





#import "NSString+EmailAddresses.h"
#import "AppDelegate.h"

#import "EmailRecipient.h"


static NSArray* usersOwnEmailAddresses;


@implementation NSString (EmailAddresses)

- (NSString*)canonicalForm
{
    NSString* returnValue = self.lowercaseString;

    returnValue = [returnValue stringByReplacingOccurrencesOfString:@"@googlemail." withString:@"@gmail." options:0 range:NSMakeRange(0, returnValue.length)];

    returnValue = [returnValue stringByReplacingOccurrencesOfString:@"@mac.com" withString:@"@icloud.com" options:0 range:NSMakeRange(0, returnValue.length)];

    returnValue = [returnValue stringByReplacingOccurrencesOfString:@"@me.com" withString:@"@icloud.com" options:0 range:NSMakeRange(0, returnValue.length)];


    NSArray* components = [returnValue componentsSeparatedByString:@"@"];

    NSString* userPart = [components firstObject];

    NSString* domainPart = [components lastObject];


    if([domainPart hasPrefix:@"gmail."])
    {
        //google ignores dots in email addresses
        userPart = [userPart stringByReplacingOccurrencesOfString:@"." withString:@""];

        //it also ignores anything following a '+' sign
        NSArray* userPartComponents = [userPart componentsSeparatedByString:@"+"];

        userPart = userPartComponents.firstObject;
    }

    returnValue = [NSString stringWithFormat:@"%@@%@", userPart, domainPart];

    if([returnValue isValidEmailAddress])
        return returnValue;

    return nil;
}

- (BOOL)isValidEmailAddress
{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];

    return [emailTest evaluateWithObject:self];
}


#pragma mark - User's own addresses

+ (void)setUsersAddresses:(NSArray*)usersAddresses
{
    usersOwnEmailAddresses = usersAddresses;
}

+ (NSArray*)usersAddresses
{
    return [usersOwnEmailAddresses copy];
}

- (BOOL)isUsersAddress
{
    NSString* canonicalAddress = [self canonicalForm];
    return [usersOwnEmailAddresses containsObject:canonicalAddress];
}

- (Recipient*)parseAsRecipient
{
    return [self parseAsEmailRecipient].recipient;
}

- (EmailRecipient*)parseAsEmailRecipient
{
    if([self isValidEmailAddress])
    { //yes, it's a valid email
        EmailRecipient* newRecipient = [EmailRecipient new];
        [newRecipient setEmail:self];
        [newRecipient setName:self];
        return newRecipient;
    }
    else
    { //not an email
      //check if it's "Name<email@provider.com>"

        NSInteger openBracketLocation = [self rangeOfString:@"<"].location;
        NSInteger closeBracketLocation = [self rangeOfString:@">"].location;
        if(openBracketLocation!=NSNotFound && closeBracketLocation!=NSNotFound)
        {
            NSString* name = [[self substringToIndex:openBracketLocation] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

            if(openBracketLocation+1<closeBracketLocation)
            {
                NSString* email = [[self substringWithRange:NSMakeRange(openBracketLocation+1, closeBracketLocation-openBracketLocation-1)] lowercaseString];
                if([email isValidEmailAddress])
                {
                    EmailRecipient* newRecipient = [EmailRecipient new];
                    [newRecipient setEmail:email];
                    [newRecipient setName:name];
                    return newRecipient;
                }
            }
        }
    }

    return nil;
}




#pragma mark - MessageID generation

//generates a new message ID - it's a timestamp followed by a random string, followed by "@" and the provider part of the given email address
- (NSString*)generateMessageID
{
    NSString* canonicalEmailAddress = [self canonicalForm];

    NSArray* emailComponents = [canonicalEmailAddress componentsSeparatedByString:@"@"];

    if(emailComponents.count != 2)
    {
        return nil;
    }

    NSDate* currentDate = [NSDate date];

    NSString* timeStamp = [NSString stringWithFormat:@"%f",[currentDate timeIntervalSince1970]];

    NSString *randomString = [NSString stringWithFormat:@"%u",arc4random()];

    return [NSString stringWithFormat:@"%@%@@%@",timeStamp,randomString,[emailComponents objectAtIndex:1]];
}

@end
