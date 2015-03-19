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





#import "AuthenticationChoiceTransformer.h"
#import <MailCore/MailCore.h>

@implementation AuthenticationChoiceTransformer

+ (NSArray*)items
{
    return @[@"default", @"LOGIN", @"PLAIN", @"none", @"CRAMMD5", @"GSSAPI", @"DigestMD5", @"SRP", @"NTLM", @"KerberosV4"/*, @"OAuth2", @"OAuth2Outlook"*/];
}

- (NSNumber*)transformedValue:(NSNumber*)value
{
    switch(value.integerValue)
    {
        case MCOAuthTypeSASLLogin | MCOAuthTypeSASLPlain:
            return @0;

        case MCOAuthTypeSASLLogin:
            return @1;

        case MCOAuthTypeSASLPlain:
            return @2;

        case MCOAuthTypeSASLNone:
            return @3;

        case MCOAuthTypeSASLCRAMMD5:
            return @4;

        case MCOAuthTypeSASLGSSAPI:
            return @5;

        case MCOAuthTypeSASLDIGESTMD5:
            return @6;

        case MCOAuthTypeSASLSRP:
            return @7;

        case MCOAuthTypeSASLNTLM:
            return @8;

        case MCOAuthTypeSASLKerberosV4:
            return @9;

        case MCOAuthTypeXOAuth2:
            return @10;
            
        case MCOAuthTypeXOAuth2Outlook:
            return @11;

        default:
            return @0;
    }
}

- (NSNumber*)reverseTransformedValue:(NSNumber*)value
{
    switch(value.integerValue)
    {
        case 0:
            return @(MCOAuthTypeSASLLogin | MCOAuthTypeSASLPlain);

        case 1:
        return @(MCOAuthTypeSASLLogin);

        case 2:
        return @(MCOAuthTypeSASLPlain);

        case 3:
        return @(MCOAuthTypeSASLNone);

        case 4:
        return @(MCOAuthTypeSASLCRAMMD5);

        case 5:
        return @(MCOAuthTypeSASLGSSAPI);

        case 6:
        return @(MCOAuthTypeSASLDIGESTMD5);

        case 7:
        return @(MCOAuthTypeSASLSRP);

        case 8:
        return @(MCOAuthTypeSASLNTLM);

        case 9:
        return @(MCOAuthTypeSASLKerberosV4);

        case 10:
        return @(MCOAuthTypeXOAuth2);

        case 11:
        return @(MCOAuthTypeXOAuth2Outlook);
            
        default:
            return @(MCOAuthTypeSASLLogin | MCOAuthTypeSASLPlain);
    }
}

@end
