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





#import "Contact+Category.h"
#import "AppDelegate.h"
#import "ABContactDetail.h"
#import "MessageSieve.h"
#import "UserSettings.h"
#import <AddressBook/AddressBook.h>
#import "EmailContactDetail+Category.h"
#import "SelectionAndFilterHelper.h"




@implementation Contact (Category)

- (BOOL)isSafe
{
    for(EmailContactDetail* contactDetail in self.emailAddresses)
        if([contactDetail currentPublicKey]!=nil)
            return YES;

    return NO;
}

/**CALL ON MAIN*/
+ (void)addEmailAddressDetailToContacts:(EmailContactDetail*)contactDetail
{
    [ThreadHelper ensureMainThread];

    [MessageSieve addEmailContactDetailToContacts:contactDetail];

    [SelectionAndFilterHelper reloadOutlinePreservingSelection];
}



//returns the email contact detail that the given contact has used most frequently (and thus can be used by default)
- (EmailContactDetail*)mostFrequentEmail
{
    NSInteger maxValue = -1;
    EmailContactDetail* returnAddress = nil;
    for(EmailContactDetail* email in self.emailAddresses)
    {
        if(email.numberOfTimesContacted.integerValue>maxValue)
        {
            maxValue = email.numberOfTimesContacted.integerValue;
            returnAddress = email;
        }
    }
    return returnAddress;
}


//returns the name that should be displayed for the given contact
- (NSString*)displayName
{
      if(self.addressBookContact)
        {
            NSString* firstName = self.addressBookContact.firstName;
            NSString* lastName = self.addressBookContact.lastName;
            if(firstName && lastName)
                return [NSString stringWithFormat:@"%@ %@", firstName, lastName];
            if(firstName)
                return firstName;
            if(lastName)
                return lastName;
        }

    //if it's a contact with no name to show and a single email address, display the address instead
    if(self.emailAddresses.count==1)
    {
        EmailContactDetail* emailAddress = (EmailContactDetail*)self.emailAddresses.anyObject;
        return emailAddress.address;
    }

    return NSLocalizedString(@"Anonymous",@"Unknown email address");
}

//returns the image associated with the given contact, or a generic anonymous image
- (IMAGE*)profilePic
{
    if(self.addressBookContact.image)
            return [[IMAGE alloc] initWithData:self.addressBookContact.image];

    return [IMAGE imageNamed:@"account32.png"];
}

- (BOOL)haveProfilePic
{
    if(self.addressBookContact.image)
            return YES;

    return NO;
}


@end
