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





#import "AppDelegate.h"
#import "ContactSuggestions.h"
#import "Contact+Category.h"
#import "ABContactDetail.h"
#import "EmailContactDetail+Category.h"
#import "EmailRecipient.h"
#import "Recipient.h"
#import "AddressDataHelper.h"
#import "ABContactDetail+Category.h"



@implementation ContactSuggestions

@synthesize emailAddressesController;


- (id)init
{
    self = [super init];
    if (self) {
        suggestionsDict = [NSMutableDictionary new];
        priorityList = [NSArray new];
        priorityDict = [NSMutableDictionary new];
    }
    return self;
}

- (void)initialFetchDone
{
    for(Contact* contact in APPDELEGATE.contacts.fetchedObjects)
    {
        [suggestionsDict addEntriesFromDictionary:@{[contact displayName]:contact.objectID}];
        [priorityDict addEntriesFromDictionary:@{[contact displayName]:contact.numberOfTimesContacted}];
    }

    NSFetchRequest* fetchAllEmailContactDetails = [NSFetchRequest fetchRequestWithEntityName:@"EmailContactDetail"];

    NSArray* allEmailContactDetails = [MAIN_CONTEXT executeFetchRequest:fetchAllEmailContactDetails error:nil];

    for(EmailContactDetail* emailDetail in allEmailContactDetails)
    {
        [suggestionsDict addEntriesFromDictionary:@{emailDetail.address:emailDetail.objectID}];
        [priorityDict addEntriesFromDictionary:@{emailDetail.address:emailDetail.numberOfTimesContacted}];
    }

    priorityList = [priorityDict keysSortedByValueUsingSelector:@selector(compare:)];
    //NSLog(@"%lu objects in priority list",(unsigned long)priorityList.count);
    //for(NSObject* key in priorityDict.allKeys)
    //    NSLog(@"%@", key);
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {

}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    //the sections shouldn't change
    switch(type) {
        case NSFetchedResultsChangeInsert:

            break;

        case NSFetchedResultsChangeDelete:
            break;

            default:
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{

        switch(type) {

        case NSFetchedResultsChangeInsert:
            if([anObject isKindOfClass:[Contact class]])
            {
                Contact* contact = (Contact*)anObject;
                [suggestionsDict addEntriesFromDictionary:@{[contact displayName]:contact.objectID}];
                [priorityDict addEntriesFromDictionary:@{[contact displayName]:contact.numberOfTimesContacted}];
                for(EmailContactDetail* emailDetail in contact.emailAddresses)
                {
                    [suggestionsDict addEntriesFromDictionary:@{emailDetail.address:contact.objectID}];
                    [priorityDict addEntriesFromDictionary:@{emailDetail.address:@(contact.numberOfTimesContacted.integerValue + ([contact isSafe]?1000:0))}];
                }
            }

                //this is never called: the NSArrayController only takes care of Contact objects
            if([anObject isKindOfClass:[EmailContactDetail class]])
            {
                EmailContactDetail* emailContactDetail = (EmailContactDetail*)anObject;

                [suggestionsDict addEntriesFromDictionary:@{emailContactDetail.address:emailContactDetail.objectID}];
                [priorityDict addEntriesFromDictionary:@{emailContactDetail.address:emailContactDetail.numberOfTimesContacted?emailContactDetail.numberOfTimesContacted:@0}];
            }
            break;

        case NSFetchedResultsChangeDelete:
            break;

        case NSFetchedResultsChangeUpdate:
            break;

        case NSFetchedResultsChangeMove:
            break;
    }
}

- (void)addEmailContactDetailToSuggestions:(EmailContactDetail*)contactDetail
{
    if(!contactDetail.address)
        return;

    [suggestionsDict addEntriesFromDictionary:@{contactDetail.address:contactDetail.objectID}];
    [priorityDict addEntriesFromDictionary:@{contactDetail.address:contactDetail.numberOfTimesContacted?contactDetail.numberOfTimesContacted:@0}];

    priorityList = [priorityDict keysSortedByValueUsingSelector:@selector(compare:)];
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    priorityList = [priorityDict keysSortedByValueUsingSelector:@selector(compare:)];
    //NSLog(@"%lu objects in priority list",(unsigned long)priorityList.count);
}



- (NSString*)getSuggestionForPartialString:(NSString*)partialString1
{
    NSString* partialString = [partialString1 stringByReplacingOccurrencesOfString:@"\u200B" withString:@""];
    if(partialString.length>0)
    {
        /*unichar c = [partialString characterAtIndex:partialString.length-1];
         // Increment as usual:
         c++;
         // And to turn it into a 1-character string again:
         NSString* partialStringIncremented = [partialString stringByReplacingCharactersInRange:NSMakeRange(partialString.length-1, 1) withString:
         [NSString stringWithCharacters:&c length:1]];*/
        for(NSInteger index = priorityList.count-1;index>=0;index--)
        {
            if([[priorityList[index] lowercaseString] hasPrefix:[partialString lowercaseString]])
            {
                return [priorityList[index] stringByReplacingCharactersInRange:NSMakeRange(0,partialString.length) withString:@""];
            }
        }
        /*NSPredicate* filterPredicate  = [NSPredicate predicateWithFormat:@"(self >= %@) && (self < %@)",[partialString lowercaseString],[partialStringIncremented lowercaseString];
         NSArray* filteredArray = [priorityList filteredArrayUsingPredicate:filterPredicate];
         if(filteredArray.count>0)
         {
         NSString* newString = filteredArray[filteredArray.count-1];
         return [newString stringByReplacingCharactersInRange:NSMakeRange(0,partialString.length) withString:@""];
         }*/
    }
    return @"";
}

- (NSArray*)contactObjectIDsForPartialString:(NSString*)passedString maxNumber:(NSInteger)maxNumber
{
    NSString* partialString = [passedString stringByReplacingOccurrencesOfString:@"\u200B" withString:@""];

    NSMutableArray* returnValue = [NSMutableArray new];

    if(partialString.length>0)
    {
        for(NSInteger index = priorityList.count-1;index>=0;index--)
        {
            if([[priorityList[index] lowercaseString] hasPrefix:[partialString lowercaseString]])
            {
                NSManagedObjectID* contactObjectID = [suggestionsDict objectForKey:priorityList[index]];

                if(contactObjectID)
                {
                    [returnValue addObject:contactObjectID];

                    if(returnValue.count>=maxNumber)
                        return returnValue;
                }
            }
        }
    }

    return returnValue;
}

- (NSManagedObjectID*)suggestionObjectIDforPartialString:(NSString *)partialString
{
    if(partialString.length>0)
    {
        for(NSInteger index = priorityList.count-1;index>=0;index--)
        {
            if([[priorityList[index] lowercaseString] hasPrefix:[partialString lowercaseString]])
            {
                return [suggestionsDict objectForKey:priorityList[index]];
            }
        }

    }
    return nil;
}

- (Recipient*)recipientForString:(NSString*)string
{
    if(!string)
        return nil;

    NSManagedObjectID* contactID = [suggestionsDict objectForKey:string];

    if(contactID)
    {
        NSError* error = nil;
        NSManagedObject* contact = (Contact*)[MAIN_CONTEXT existingObjectWithID:contactID error:&error];
        if(error)
        {
            NSLog(@"Error creating contact from objectID!!! %@", error.description);
            return nil;
        }

        if([contact isKindOfClass:[Contact class]])
        {

        NSString* email = [[(Contact*)contact mostFrequentEmail] address];
        NSString* name = [(Contact*)contact displayName];

        Recipient* rec = [[Recipient alloc] initWithEmail:email andName:name];

        return rec;
        }
        else if([contact isKindOfClass:[EmailContactDetail class]])
        {
            NSString* email = [(EmailContactDetail*)contact address];
            NSString* name = [(EmailContactDetail*)contact fullName];

            NSSet* linkedContacts = [(EmailContactDetail*)contact linkedToContact];

            if(linkedContacts.count>0)
            {
                Contact* contact = linkedContacts.anyObject;

                name = [contact displayName];
            }

            Recipient* rec = [[Recipient alloc] initWithEmail:email andName:name];

            return rec;
        }
        else
            return nil;
    }
    else
    {
        //check if the email address is valid. if not simply return
        NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}";
        NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
        if([emailTest evaluateWithObject:string])
        {
            Recipient* rec = [[Recipient alloc] initWithEmail:string andName:string];
            return rec;
        }
    }
    
    return nil;
}

- (EmailRecipient*)emailRecipientForString:(NSString*)string
{
    if(!string)
        return nil;

    NSManagedObjectID* contactID = [suggestionsDict objectForKey:string];

    if(contactID)
    {
        NSError* error = nil;
        Contact* contact = (Contact*)[MAIN_CONTEXT existingObjectWithID:contactID error:&error];
        if(error)
        {
            NSLog(@"Error creating contact from objectID!!! %@", error.description);
            return nil;
        }

        EmailRecipient* rec = [EmailRecipient new];
        [rec setEmail:[[contact mostFrequentEmail] address]];
        [rec setName:[contact displayName]];

        return rec;
    }
    else
    {
        //check if the email address is valid. if not simply return
        NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}";
        NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
        if([emailTest evaluateWithObject:string])
        {
            EmailRecipient* rec = [EmailRecipient new];
            [rec setEmail:string];
            [rec setName:string];
            return rec;
        }
    }
    
    return nil;
}



@end
