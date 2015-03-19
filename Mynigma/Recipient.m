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
#define MENUITEM UIMenuItem
#else
#define MENUITEM NSMenuItem
#endif

#import "AppDelegate.h"

#import "EmailContactDetail+Category.h"
#import "Contact+Category.h"
#import "Recipient.h"
#import "MynigmaPublicKey+Category.h"
#import "EmailRecipient.h"
#import "MynigmaPrivateKey+Category.h"
#import "NSString+EmailAddresses.h"



@implementation Recipient

@synthesize contactDetail;
@synthesize type;

- (id)initWithEmail:(NSString*)newEmail andName:(NSString*)newName
{
    self = [super init];
    if(self)
    {
        email = newEmail;
        name = newName;
        type = TYPE_TO;
//        [MAIN_CONTEXT performBlockAndWait:^{
//
//            contactDetail = [EmailContactDetail addEmailContactDetailForEmail:email];
//
//        NSSet* contactSet = contactDetail.linkedToContact;
//
//        if([contactSet isKindOfClass:[NSSet class]])
//        {
//            if(contactSet.count>0)
//                contactObject = [contactSet anyObject];
//        }
//        else
//            NSLog(@"Set of linked contacts is not an NSSet: %@",contactSet);
//        }];
    }
    return self;
}

/*
//inits the Recipient object and sets the appropriate 
- (id)initWithEmail:(NSString*)newEmail andName:(NSString*)newName inContext:(NSManagedObjectContext*)localContext
{
    self = [super init];
    if(self)
    {
        email = newEmail;
        name = newName;
        type = TYPE_TO;
        BOOL alreadyFoundOne = NO;
        //find or create an email contact detail
        [MAIN_CONTEXT performBlockAndWait:^{
            NSManagedObjectID* emailID = [MODEL addEmailContactDetailForEmail:newEmail alreadyFoundOne:nil];
        if(!alreadyFoundOne)
        {
            //the EmailContactDetail is new, so there is no Contact attached - nothing else to do
        }
            else
            {
        //the EmailContactDetail already existed, so look for a suitable Contact and add it if necessary (all on the main thread)
            EmailContactDetail* emailContactDetail = (EmailContactDetail*)[MAIN_CONTEXT objectWithID:emailID];
        if(!emailContactDetail)
        {
            NSLog(@"No email contact detail could be created!!! %@",emailID);
        }
        else
        {
            contactDetail = emailContactDetail;
            
        NSSet* contactSet = emailContactDetail.linkedToContact;
        if(contactSet && [contactSet isKindOfClass:[NSSet class]])
        {
            if(contactSet.count==1)
            {
                NSArray* contactArray = [contactSet sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"addressBookContact.uid" ascending:YES]]];
                contactObject = [contactArray objectAtIndex:0];
            }
        }
        else
            NSLog(@"Set of linked contacts is not an NSSet: %@",contactSet);
            }
            }
        }];
    }
    return self;
}

*/

- (id)initWithEmailContactDetail:(EmailContactDetail*)detail
{
    [ThreadHelper ensureMainThread];

    self = [super init];
    if(self)
    {
        type = TYPE_TO;
        contactDetail = detail;
        if(!detail || ![detail isKindOfClass:[EmailContactDetail class]])
        {
            NSLog(@"Failed to init email contact detail, passed object: %@",detail);
            return self;
        }
        NSSet* contactSet = contactDetail.linkedToContact;

        if(!contactSet)
            [contactDetail setLinkedToContact:[NSSet set]];

        if([contactSet isKindOfClass:[NSSet class]])
        {
            contactObject = [contactDetail mostFrequentContact];
        }
        else
            NSLog(@"Set of linked contacts is not an NSSet: %@",contactSet);
    }
    return self;
}

- (id)initWithContact:(Contact*)contact
{
    self = [super init];
    if(self)
    {
        type = TYPE_TO;
        contactObject = contact;
        contactDetail = [contact mostFrequentEmail];
    }
    return self;
}


- (NSString*)displayName
{
    if(name)
        if(name.length>0)
            return name;
    if(email)
        if(email.length>0)
            return email;
    Contact* contact = [self associatedContact];
    if(contact)
        return [contact displayName];
    if(contactDetail)
        return contactDetail.address;
    return NSLocalizedString(@"Anonymous",@"Unknown email address");
}


- (NSAttributedString*)attributedDisplayNameWithType:(BOOL)withType
{
    NSString* typeString = [NSString new];
    switch(type)
    {
        case TYPE_FROM: typeString = NSLocalizedString(@" (from)",nil); break;
        case TYPE_REPLY_TO: typeString = NSLocalizedString(@" (reply to)",nil); break;
        case TYPE_TO: typeString = NSLocalizedString(@" (to)",nil); break;
        case TYPE_CC: typeString = NSLocalizedString(@" (cc)",nil); break;
        case TYPE_BCC: typeString = NSLocalizedString(@" (bcc)",nil); break;
    }
    if(name && name.length>0)
        return [[NSAttributedString alloc] initWithString:name attributes:@{}];

    NSString* emailString = self.displayEmail;

    if(!emailString)
        emailString = @"";

    return [[NSAttributedString alloc] initWithString:[emailString stringByAppendingString:withType?typeString:@""] attributes:@{}];
}


- (NSString*)displayEmail
{
    if(email)
        return email;
    if(contactDetail)
        return contactDetail.address;
    if(contactObject)
    {
        EmailContactDetail* emailContactDetail = [contactObject mostFrequentEmail];
        if(emailContactDetail)
            return emailContactDetail.address;
    }
    return NSLocalizedString(@"No email address",nil);
}


- (EmailContactDetail*)associatedEmailContactDetail
{
    if(contactDetail)
        return contactDetail;
    if(contactObject)
    {
        EmailContactDetail* emailContactDetail = [contactObject mostFrequentEmail];
        if(emailContactDetail)
            return emailContactDetail;
    }
//    if(email)
//    {
//        EmailContactDetail* emailContactDetail = [EmailContactDetail addEmailContactDetailForEmail:email];
//
//        return emailContactDetail;
//    }
    return nil;
}


- (Contact*)associatedContact
{
    if(contactObject)
        return contactObject;
    if(contactDetail)
    {
        NSSet* contactSet = contactDetail.linkedToContact;

        if(!contactSet)
            [contactDetail setLinkedToContact:[NSSet set]];

        if([contactSet isKindOfClass:[NSSet class]])
        {
            if(contactSet.count>0)
            {
            NSArray* sortedContacts = [contactSet sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"addressBookContact.uid" ascending:YES]]];
            return [sortedContacts objectAtIndex:0];
            }
        }
        else
            NSLog(@"Set of linked contacts is not an NSSet: %@",contactSet);
    }
    return nil;
}


//must be run on main context
- (NSArray*)listPossibleEmailContactDetails
{
    [ThreadHelper ensureMainThread];

    NSMutableSet* emailContactDetails = [NSMutableSet new];
    
    //first collect all emailcontactdetails associated with this contact
    if(contactObject)
        [emailContactDetails unionSet:contactObject.emailAddresses];
        //return [contactObject.emailAddresses sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"address" ascending:YES]]];
    if(contactDetail)
        [emailContactDetails addObject:contactDetail];
    if(email)
    {
        EmailContactDetail* emailContactDetail = [EmailContactDetail emailContactDetailForAddress:email];
        if(emailContactDetail)
            [emailContactDetails addObject:emailContactDetail];
        else
            NSLog(@"Could not find existing email contact detail in listPossibleEmailContactDetails");
    }
    return [emailContactDetails sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"address" ascending:YES]]];
}

/*
- (NSImage*)displayPic
{
    Contact* contact = [self associatedContact];
    if(contact)
        return [MODEL profilePicOfContact:contact];
    return [NSImage imageNamed:@"anonymous.png"];
}*/


- (void)setToType:(id)sender
{
    type = TYPE_TO;
}

- (void)setCcType:(id)sender
{
    type = TYPE_CC;
}

- (void)setBccType:(id)sender
{
    type = TYPE_BCC;
}

- (void)setReplyToType:(id)sender
{
    type = TYPE_REPLY_TO;
}

- (BOOL)isSafe
{
    //reply-to addresses need neither a public nor a private key, since they don't actually receive the message...
    if(type==TYPE_REPLY_TO)
        return YES;

    //the sender address needs to be associated with a private key, not just a public one...
    if(type==TYPE_FROM)
    {
        return [MynigmaPrivateKey havePrivateKeyForEmailAddress:self.displayEmail];
    }

    return [MynigmaPublicKey havePublicKeyForEmailAddress:self.displayEmail];
}

//use this method to determine display colours
//it will show recipients as green in the from: field even if there is only a public key available (but no private one)
- (BOOL)isSafeAsNonSender
{
    //reply-to addresses need neither a public nor a private key, since they don't actually receive the message...
    if(type==TYPE_REPLY_TO)
        return YES;

    //the sender address needs to be associated with a private key, not just a public one...
    if(type==TYPE_FROM)
    {
        //only expect a public key if the email address belongs to the user himself
        if([self.displayEmail isUsersAddress])
            return [MynigmaPrivateKey havePrivateKeyForEmailAddress:self.displayEmail];
    }

    return [MynigmaPublicKey havePublicKeyForEmailAddress:self.displayEmail];
}



//called on main thread
//- (void)makeEmailContactDetailIfNecessary
//{
//    [ThreadHelper ensureMainThread];
//
//    if(!contactObject && !contactDetail && email)
//    {
//        contactDetail = [EmailContactDetail addEmailContactDetailForEmail:email alreadyFoundOne:nil];
//        NSSet* contactSet = contactDetail.linkedToContact;
//        if([contactSet isKindOfClass:[NSSet class]])
//        {
//            NSArray* contactArray = [contactSet sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"addressBookContact.uid" ascending:YES]]];
//            if(contactArray.count==1)
//                contactObject = [contactArray objectAtIndex:0];
//        }
//    }
//}

- (EmailRecipient*)emailRecipient
{
    EmailRecipient* emailRec = [EmailRecipient new];

    [emailRec setEmail:self.displayEmail];
    [emailRec setName:self.displayName];
    [emailRec setType:self.type];

    return emailRec;
}


- (NSString*)longDisplayString
{
    return [NSString stringWithFormat:@"%@<%@>", self.displayName?self.displayName:@"", self.displayEmail?self.displayEmail:@""];
}



//returns whether a given list of recipients is safe (i.e. whether a message sent to these recipients will be safe or open)
+ (BOOL)recipientListIsSafe:(NSArray*)recipients
{
    BOOL isSafe = YES;
    for(NSObject* rec in recipients)
    {
        if([rec isKindOfClass:[Recipient class]])
        {
            if(![(Recipient*)rec isSafe])
            {
                isSafe = NO;
                break;
            }
        }
        else if([rec isKindOfClass:[EmailRecipient class]])
        {
            if(![(EmailRecipient*)rec isSafe])
            {
                isSafe = NO;
                break;
            }
        }
        else
        {
            isSafe = NO;
            break;
        }
    }
    return isSafe;
}


@end
