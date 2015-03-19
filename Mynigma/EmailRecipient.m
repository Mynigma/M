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





#if TARGET_OS_IPHONE
#define FONT UIFont
#else
#define FONT NSFont
#endif

#import "AppDelegate.h"
#import "EmailRecipient.h"
#import "MynigmaPublicKey+Category.h"
#import "EmailContactDetail+Category.h"
#import "Recipient.h"
#import "MynigmaPrivateKey+Category.h"
#import "AccountCreationManager.h"
#import "NSString+EmailAddresses.h"




@implementation EmailRecipient

@synthesize email;
@synthesize name;
@synthesize type;


- (NSString*)displayString
{
    if(name)
        if(name.length>0)
            return name;
    if(email)
        if(email.length>0)
        return email;
    return NSLocalizedString(@"Anonymous",@"Unknown email address");
}

- (NSAttributedString*)attributedDisplayStringWithType:(BOOL)withType isNominative:(BOOL)isNominative
{
    NSString* typeString = [NSString new];
    if(type==TYPE_FROM)
        typeString = NSLocalizedString(@" (from)",@"Email send from");
    if(type==TYPE_REPLY_TO)
        typeString = NSLocalizedString(@" (reply to)",@"Email reply to");
    if(type==TYPE_TO)
        typeString = @"";
    if(type==TYPE_CC)
        typeString = NSLocalizedString(@" (cc)",@"email carboncopy");
    if(type==TYPE_BCC)
        typeString = NSLocalizedString(@" (bcc)",@"email blindcc");
    if([email isUsersAddress])
    {
        NSMutableDictionary* attributes = [NSMutableDictionary new];

        attributes[NSFontAttributeName] = [FONT boldSystemFontOfSize:12];

#if TARGET_OS_IPHONE

#else

        attributes[NSToolTipAttributeName] = email?email:NSLocalizedString(@"(no email)", @"(no email)");

#endif

        NSString* meString = [isNominative?NSLocalizedString(@"me (nominative)", @"me (nominative)"):NSLocalizedString(@"me (dative)", @"me (dative)") stringByAppendingString:withType?typeString:@""];

        if(!meString)
            meString = @"me";

        return [[NSAttributedString alloc] initWithString:meString attributes:attributes];
    }
    
    if(name.length>0)
    {
        NSMutableDictionary* attributes = [NSMutableDictionary new];

        attributes[NSFontAttributeName] = [FONT boldSystemFontOfSize:12];

#if TARGET_OS_IPHONE

#else

        attributes[NSToolTipAttributeName] = email?email:NSLocalizedString(@"(no email)", @"(no email)");
        
#endif

        NSString* noNameString = [name?name:NSLocalizedString(@"(no name)", @"(no name)") stringByAppendingString:withType?typeString:@""];

        if(!noNameString)
            noNameString = @"(no name)";

            return [[NSAttributedString alloc] initWithString:noNameString attributes:attributes];
    }

    NSString* emailString = email?email:NSLocalizedString(@"(no email)", @"(no email)");

    return [[NSAttributedString alloc] initWithString:emailString attributes:@{NSFontAttributeName:[FONT boldSystemFontOfSize:12]}];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject: [self email] forKey:@"email"];
    [aCoder encodeObject: [self name] forKey: @"name"];
    [aCoder encodeObject: [NSNumber numberWithInteger:[self type]] forKey: @"type"];
    
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if((self = [self init]))
    {
        [self setEmail:[aDecoder decodeObjectForKey:@"email"]];
        [self setName:[aDecoder decodeObjectForKey: @"name"]];
        [self setType:[[aDecoder decodeObjectForKey: @"type"] integerValue]];
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    if(object == self)
        return YES;
    if(!object)
        return NO;
    if([object isKindOfClass:[EmailRecipient class]])
    {
        EmailRecipient* obj = (EmailRecipient*)object;
        return [[self.email lowercaseString] isEqualToString:[obj.email lowercaseString]];
    }
    return NO;
}

- (NSUInteger)hash
{
    return [self.email hash];
}

- (BOOL)isSafe
{
    //reply-to addresses need neither a public nor a private key, since they don't actually receive the message...
    if(type==TYPE_REPLY_TO)
        return YES;

    //the sender address needs to be associated with a private key, not just a public one...
    if(type==TYPE_FROM)
    {
        return [MynigmaPrivateKey havePrivateKeyForEmailAddress:self.email];
    }

    return [MynigmaPublicKey havePublicKeyForEmailAddress:self.email];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@" %@<%@>(%ld)", self.name, self.email, (long)self.type];
}

- (Recipient*)recipient
{
    Recipient* newRec = [[Recipient alloc] initWithEmail:self.email andName:self.name];

    [newRec setType:self.type];

    return newRec;
}


- (NSString*)longDisplayString
{
    return [NSString stringWithFormat:@"%@ <%@>", self.displayString, self.email];
}


- (BOOL)isSafeAsNonSender
{
    //reply-to addresses need neither a public nor a private key, since they don't actually receive the message...
    if(type==TYPE_REPLY_TO)
        return YES;
    
    if(type==TYPE_FROM)
    {
        //If the sender address is set up it needs to be associated with a private key, not just a public one...
        if([AccountCreationManager haveAccountForEmail:self.email])
            return [MynigmaPrivateKey havePrivateKeyForEmailAddress:self.email];
    }
    
    return [MynigmaPublicKey havePublicKeyForEmailAddress:self.email];
}


@end
