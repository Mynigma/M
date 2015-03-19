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





#import "ABContactDetail+Category.h"
#import "AppDelegate.h"
#import "UserSettings.h"
#import <AddressBook/AddressBook.h>
#import "Contact+Category.h"
#import "EmailContactDetail+Category.h"
#import "UserSettings+Category.h"
#import "AlertHelper.h"
#import "AccountCreationManager.h"





static NSMutableDictionary* allContacts;

static BOOL haveCollectedAllContacts;

static dispatch_queue_t contactsQueue;


@implementation ABContactDetail (Category)


//the allContacts dictionary contains the objectIDs of all ABContactDetails, organised by name (both in the "firstName lastName" and the "lastName, firstName" format)
+ (void)collectAllABContacts
{
    haveCollectedAllContacts = NO;

    contactsQueue = dispatch_queue_create("org.mynigma.contactsQueue", NULL);

    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

        allContacts = [NSMutableDictionary new];

        NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ABContactDetail"];
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"linkedToContact.emailAddresses.@count != 0"];
        [fetchRequest setPredicate:predicate];
        NSError* error = nil;
        NSArray* contactList = [localContext executeFetchRequest:fetchRequest error:&error];
        if(error)
            NSLog(@"Error loading all emails while generating completion strings");
        else for(ABContactDetail* contactDetail in contactList)
        {
            NSManagedObjectID* contactDetailObjectID = contactDetail.objectID;
            NSString* firstNameThenLastName = [NSString stringWithFormat:@"%@ %@",contactDetail.firstName,contactDetail.lastName];
            NSString* lastNameCommaFirstName = [NSString stringWithFormat:@"%@ %@",contactDetail.lastName,contactDetail.firstName];

            dispatch_sync(contactsQueue,
                          ^{
                              [allContacts addEntriesFromDictionary:@{firstNameThenLastName:contactDetailObjectID,lastNameCommaFirstName:contactDetailObjectID}];
                          });
        }
        dispatch_async(contactsQueue,
                       ^{
                           NSLog(@"Done collecting contacts.");
                           haveCollectedAllContacts = YES;
                       });
    }];
}


#if TARGET_OS_IPHONE

//iOS
//load any contacts from the address book that have been added since the last app launch
+ (void)loadAdditionalContactsFromAddressbook
{
    if([UserSettings usedAccounts].count == 0)
        return;

    ABAddressBookRef addressBook;
    CFErrorRef errorRef;
    addressBook = ABAddressBookCreateWithOptions(NULL, &errorRef);
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef errorRef) {

        if(granted)
        {
            [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

                //fetch all address book contact details in the store
                NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ABContactDetail"];
                NSError* error = nil;
                NSMutableArray* localContactsArray = [[localContext executeFetchRequest:fetchRequest error:&error] mutableCopy];
                if(error)
                    NSLog(@"Error loading contacts into local array while updating address book");

                //list of all people in the address book
                NSArray* people = (NSArray*)CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(addressBook));

                for(int i=0;i<people.count;i++)
                {
                    ABRecordRef person = CFBridgingRetain(people[i]);

                    //check if uid exists in the store
                    NSInteger index = [[localContactsArray valueForKey:@"uid"] indexOfObject:[NSString stringWithFormat:@"%d",ABRecordGetRecordID(person)]];

                    //if so, update the contact if necessary
                    if(index!=NSNotFound)
                    {
                        //the existing contact
                        ABContactDetail* existingContact = [localContactsArray objectAtIndex:index];



                        //set the contact's image, if there isn't one already...
                        if(![existingContact image])
                        {
                            if(ABPersonHasImageData(person))
                            {
                                NSData* imageData = (NSData*)CFBridgingRelease(ABPersonCopyImageData(person));
                                UIImage* oldImage = [UIImage imageWithData:imageData];
                                CGSize newSize = CGSizeMake(64,64);
                                UIGraphicsBeginImageContextWithOptions(newSize, YES, 0.0);
                                [oldImage drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
                                UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
                                UIGraphicsEndImageContext();
                                NSData* newData = UIImageJPEGRepresentation(newImage, 0);
                                if(newImage)
                                    [existingContact setImage:newData];
                            }
                        }


                        //update first and last names, if they have changed...
                        NSString* newName = (NSString*)CFBridgingRelease(ABRecordCopyValue(person, kABPersonFirstNameProperty));
                        if(newName)
                            [existingContact setFirstName:newName];
                        newName = (NSString*)CFBridgingRelease(ABRecordCopyValue(person, kABPersonLastNameProperty));
                        if(newName)
                            [existingContact setLastName:newName];



                        //iterate through the email adresses
                        NSMutableArray* allEmails = [NSMutableArray new];

                        //now check if there are any new email addresses
                        ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);

                        //go through the email addresses associated with the contact in the store
                        for(NSUInteger index = 0; index<ABMultiValueGetCount(emails); index++)
                        {
                            //the email address
                            NSString* emailAddress = [(NSString*)CFBridgingRelease(ABMultiValueCopyValueAtIndex(emails, index)) lowercaseString];

                            EmailContactDetail* emailContactDetail = [EmailContactDetail addEmailContactDetailForEmail:emailAddress alreadyFoundOne:nil inContext:localContext];

                            if(![emailContactDetail.linkedToContact containsObject:existingContact.linkedToContact])
                            {
                                [emailContactDetail addLinkedToContactObject:existingContact.linkedToContact];
                            }

                            [allEmails addObject:emailAddress];
                        }

                        //remove email contact details of contacts no longer linked to in the address book app
                        NSSet* allEmailAddresses = [NSSet setWithSet:existingContact.linkedToContact.emailAddresses];
                        for(EmailContactDetail* emailContactDetail in allEmailAddresses)
                        {
                            if(![allEmails containsObject:emailContactDetail.address])
                            {
                                [emailContactDetail removeLinkedToContactObject:existingContact.linkedToContact];
                            }
                        }
                    }
                    else
                    {
                        //it's a new contact

                        //check if it has email addresses set
                        ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
                        if (!emails || ABMultiValueGetCount(emails) == 0)
                            continue;


                        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Contact" inManagedObjectContext:localContext];

                        Contact* newContact = [[Contact alloc] initWithEntity:entity insertIntoManagedObjectContext:localContext];
                        entity = [NSEntityDescription entityForName:@"ABContactDetail" inManagedObjectContext:localContext];

                        ABContactDetail* newContactDetail = [[ABContactDetail alloc] initWithEntity:entity insertIntoManagedObjectContext:localContext];

                        [localContext obtainPermanentIDsForObjects:@[newContactDetail] error:nil];

                        [newContactDetail insertIntoAllContactsDict];

                        [newContact setAddressBookContact:newContactDetail];
                        [localContactsArray addObject:newContactDetail];

                        //iterate through the email adresses
                        NSMutableArray* allEmails = [NSMutableArray new];

                        //ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
                        for(NSUInteger index = 0;index<ABMultiValueGetCount(emails);index++)
                        {
                            NSString* emailAddress = [(NSString*)CFBridgingRelease(ABMultiValueCopyValueAtIndex(emails, index)) lowercaseString];

                            EmailContactDetail* emailContactDetail = [EmailContactDetail addEmailContactDetailForEmail:emailAddress alreadyFoundOne:nil inContext:localContext];

                            if(![emailContactDetail.linkedToContact containsObject:newContactDetail.linkedToContact])
                            {
                                [emailContactDetail addLinkedToContactObject:newContactDetail.linkedToContact];
                            }

                            [allEmails addObject:emailAddress];
                        }

                        //set names
                        [newContactDetail setFirstName:(NSString*)CFBridgingRelease(ABRecordCopyValue(person, kABPersonFirstNameProperty))];
                        [newContactDetail setLastName:(NSString*)CFBridgingRelease(ABRecordCopyValue(person, kABPersonLastNameProperty))];
                        [newContactDetail setUid:[NSString stringWithFormat:@"%d",ABRecordGetRecordID(person)]];

                        //set the image
                        NSData* imageData = (NSData*)CFBridgingRelease(ABPersonCopyImageData(person));
                        if(imageData)
                        {
                            UIImage* oldImage = [UIImage imageWithData:imageData];
                            CGSize newSize = CGSizeMake(64,64);
                            UIGraphicsBeginImageContextWithOptions(newSize, YES, 0.0);
                            [oldImage drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
                            UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
                            UIGraphicsEndImageContext();
                            NSData* newData = UIImageJPEGRepresentation(newImage, 0);
                            if(newImage)
                                [newContactDetail setImage:newData];
                        }
                    }
                }

                error = nil;
                [localContext save:&error];
                if(error)
                    NSLog(@"Error saving temporary context for address book loading: %@",error);

                [CoreDataHelper save];

            }];

        }
    });
}

#else

//Mac OS
+ (void)loadAdditionalContactsFromAddressbookWithCallback:(void(^)(void))callback
{
    [ThreadHelper ensureMainThread];

    if([UserSettings usedAccounts].count == 0)
    {
        if(callback)
            callback();

        return;
    }

    ABAddressBook *addressBook;
    addressBook = [ABAddressBook sharedAddressBook];
    NSArray* people = [addressBook people];

    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

        //fetch all address book contact details in the store
        NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ABContactDetail"];
        NSError* error = nil;
        NSMutableArray* localContactsArray = [[localContext executeFetchRequest:fetchRequest error:&error] mutableCopy];
        if(error)
            NSLog(@"Error loading contacts into local array while updating address book");

        NSArray* uidIndexArray = [localContactsArray valueForKey:@"uid"];

        for(ABPerson* person in people)
        {
            //check if uid exists
            NSInteger index = [uidIndexArray indexOfObject:person.uniqueId];
            if(index!=NSNotFound && index<localContactsArray.count)
            {

                ABContactDetail* newABContact = [localContactsArray objectAtIndex:index];

                //set the contact's image, if there isn't one already...
                if(![newABContact image] && [person imageData].length>0)
                {
                    NSImageView* kView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 64, 64)];
                    [kView setImageScaling:NSImageScaleProportionallyUpOrDown];
                    NSImage* abImage = [[NSImage alloc] initWithData:[person imageData]];
                    [kView setImage:abImage];

                    NSRect kRect = kView.frame;
                    NSBitmapImageRep* kRep = [kView bitmapImageRepForCachingDisplayInRect:kRect];
                    [kView cacheDisplayInRect:kRect toBitmapImageRep:kRep];

                    NSData* kData = [kRep representationUsingType:NSJPEGFileType properties:@{NSImageCompressionFactor:@0}];

                    if(kData)
                        [newABContact setImage:kData];
                }

                //update first and last names, if they have changed...
                NSString* newName = [person valueForProperty:kABFirstNameProperty];
                if(newName)
                    if(![newName isEqualToString:newABContact.firstName])
                        [newABContact setFirstName:newName];

                newName = [person valueForProperty:kABLastNameProperty];
                if(newName)
                    if(![newName isEqualToString:newABContact.lastName])
                        [newABContact setLastName:newName];

                //iterate through the email adresses
                ABMultiValue* emails = [person valueForProperty:kABEmailProperty];

                NSMutableArray* allEmails = [NSMutableArray new];

                for(NSUInteger index = 0;index<[emails count];index++)
                {
                    NSString* emailAddress = [[emails valueAtIndex:index] lowercaseString];

                    EmailContactDetail* emailContactDetail = [EmailContactDetail addEmailContactDetailForEmail:emailAddress alreadyFoundOne:nil inContext:localContext];

                    if(![emailContactDetail.linkedToContact containsObject:newABContact.linkedToContact])
                    {
                        [emailContactDetail addLinkedToContactObject:newABContact.linkedToContact];
                    }

                    [allEmails addObject:emailAddress];
                }

                //remove email contact details of contacts no longer linked to in the address book app
                NSSet* allEmailAddresses = [NSSet setWithSet:newABContact.linkedToContact.emailAddresses];
                for(EmailContactDetail* emailContactDetail in allEmailAddresses)
                {
                    if(![allEmails containsObject:emailContactDetail.address])
                    {
                        [emailContactDetail removeLinkedToContactObject:newABContact.linkedToContact];
                    }
                }
            }
            else
            {
                //it's a new contact

                //check if it has email addresses set
                ABMultiValue* emails = [person valueForProperty:kABEmailProperty];
                if (!emails || [emails count] == 0)
                    continue;

                NSEntityDescription *entity = [NSEntityDescription entityForName:@"Contact" inManagedObjectContext:localContext];

                Contact* newContact = [[Contact alloc] initWithEntity:entity insertIntoManagedObjectContext:localContext];
                entity = [NSEntityDescription entityForName:@"ABContactDetail" inManagedObjectContext:localContext];

                ABContactDetail* newContactDetail = [[ABContactDetail alloc] initWithEntity:entity insertIntoManagedObjectContext:localContext];

                [localContext obtainPermanentIDsForObjects:@[newContactDetail] error:nil];

                [newContactDetail insertIntoAllContactsDict];

                [newContact setAddressBookContact:newContactDetail];
                [localContactsArray addObject:newContactDetail];

                //iterate through the email adresses
                //ABMultiValue* emails = [person valueForProperty:kABEmailProperty];

                NSMutableArray* allEmails = [NSMutableArray new];

                for(NSUInteger index = 0;index<[emails count];index++)
                {
                    NSString* emailAddress = [[emails valueAtIndex:index] lowercaseString];

                    EmailContactDetail* emailContactDetail = [EmailContactDetail addEmailContactDetailForEmail:emailAddress alreadyFoundOne:nil inContext:localContext];

                    if(![emailContactDetail.linkedToContact containsObject:newContactDetail.linkedToContact])
                    {
                        [emailContactDetail addLinkedToContactObject:newContactDetail.linkedToContact];
                    }

                    [allEmails addObject:emailAddress];
                }

                //set names
                [newContactDetail setFirstName:[person valueForProperty:kABFirstNameProperty]];
                [newContactDetail setLastName:[person valueForProperty:kABLastNameProperty]];
                [newContactDetail setUid:[person valueForProperty:kABUIDProperty]];

                //set the image
                if([person imageData].length>0)
                {
                    NSImageView* kView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 64, 64)];
                    [kView setImageScaling:NSImageScaleProportionallyUpOrDown];
                    NSImage* abImage = [[NSImage alloc] initWithData:[person imageData]];
                    [kView setImage:abImage];

                    NSRect kRect = kView.frame;
                    NSBitmapImageRep* kRep = [kView bitmapImageRepForCachingDisplayInRect:kRect];
                    [kView cacheDisplayInRect:kRect toBitmapImageRep:kRep];

                    NSData* kData = [kRep representationUsingType:NSJPEGFileType properties:@{NSImageCompressionFactor:@0}];
                    
                    if(kData)
                        [newContactDetail setImage:kData];
                }
            }
        }
        
        error = nil;
        [localContext save:&error];
        if(error)
            NSLog(@"Error saving temporary context for address book loading: %@",error);
        
        [CoreDataHelper save];
        
        [ThreadHelper runAsyncOnMain:^{
            
            if(callback)
                callback();
        }];
    }];
}

+ (void)loadAdditionalContactsFromAddressbook
{
    [ABContactDetail loadAdditionalContactsFromAddressbookWithCallback:nil];
}

#endif


+ (void)loadAdditionalContactsFromAddressbookWithExplanation
{
    if([UserSettings usedAccounts].count == 0)
        return;

    NSString* userDefaultsKey = @"Mynigma_haveExplainedContactsAccess";

    NSNumber* haveExplainedContactsAccess = [[NSUserDefaults standardUserDefaults] objectForKey:userDefaultsKey];

    if(haveExplainedContactsAccess.boolValue)
    {
        [ABContactDetail loadAdditionalContactsFromAddressbook];
    }
    else
    {

#if TARGET_OS_IPHONE

        [AlertHelper showAlertWithTitle:NSLocalizedString(@"Use address book to populate recent contacts list", @"alert view") message:NSLocalizedString(@"Mynigma can populate its contact list with email addresses and profile pictures from the Contacts app, if you grant permission. All data will stay on this device.", @"") callback:^{

            [ABContactDetail loadAdditionalContactsFromAddressbook];

        }];

#else

        NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Mynigma can populate its contact list with email addresses and photos from the Contacts app, if you grant permission.", @"") defaultButton:NSLocalizedString(@"OK", @"OK button") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"All data will stay on this computer. Nothing will be shared with us or any third party.", @"")];

        [alert runModal];

        [ABContactDetail loadAdditionalContactsFromAddressbook];

#endif

        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:userDefaultsKey];
    }
}


+ (NSDictionary*)allContactsDict
{
    __block NSDictionary* returnValue = nil;
    
    dispatch_sync(contactsQueue,
                  ^{
                      returnValue = [allContacts copy];
                  });
    
    return returnValue;
}

- (void)insertIntoAllContactsDict
{
    if(self.objectID.isTemporaryID)
    {
        NSLog(@"Attempting to register temporary objectID in allContacts dict!!");
        [self.managedObjectContext obtainPermanentIDsForObjects:@[self] error:nil];
    }
    
    NSManagedObjectID* contactDetailObjectID = self.objectID;
    NSString* firstNameThenLastName = [NSString stringWithFormat:@"%@ %@",self.firstName,self.lastName];
    NSString* lastNameCommaFirstName = [NSString stringWithFormat:@"%@ %@",self.lastName,self.firstName];
    
    dispatch_async(contactsQueue,
                   ^{
                       [allContacts addEntriesFromDictionary:@{firstNameThenLastName:contactDetailObjectID,lastNameCommaFirstName:contactDetailObjectID}];
                   });
}


- (void)removeContactFromAllContactsDict
{
    NSString* firstNameThenLastName = [NSString stringWithFormat:@"%@ %@",self.firstName,self.lastName];
    NSString* lastNameCommaFirstName = [NSString stringWithFormat:@"%@ %@",self.lastName,self.firstName];
    
    dispatch_async(contactsQueue,
                   ^{
                       [allContacts removeObjectForKey:firstNameThenLastName];
                       [allContacts removeObjectForKey:lastNameCommaFirstName];
                   });
}



@end
