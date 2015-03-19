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





#import "EmailContactDetail+Category.h"
#import "AppDelegate.h"
#import "MynigmaPrivateKey+Category.h"
#import "Contact+Category.h"
#import "ABContactDetail+Category.h"
#import "PublicKeyManager.h"
#import "ABContactDetail+Category.h"


#if TARGET_OS_IPHONE

#import "ContactSuggestions.h"

#endif


static NSMutableDictionary* allContactDetails;

static BOOL haveCollectedAllContactDetails;

static dispatch_queue_t emailContactDetailsQueue;


@implementation EmailContactDetail (Category)


+ (void)collectAllContactDetails
{
    haveCollectedAllContactDetails = NO;

    if(!emailContactDetailsQueue)
        emailContactDetailsQueue = dispatch_queue_create("org.mynigma.emailContactDetailsQueue", NULL);

    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

        //the allContactDetails dictionary contains the objectIDs of all EmailContactDetails, organised by email address
        allContactDetails = [NSMutableDictionary new];

        NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"EmailContactDetail"];

        NSDictionary* properties = [[NSEntityDescription entityForName:@"EmailContactDetail" inManagedObjectContext:localContext] propertiesByName];

        NSPropertyDescription* emailAddressProperty = [properties objectForKey:@"address"];

        NSExpressionDescription* objectIDProperty = [NSExpressionDescription new];
        objectIDProperty.name = @"objectID";
        objectIDProperty.expression = [NSExpression expressionForEvaluatedObject];
        objectIDProperty.expressionResultType = NSObjectIDAttributeType;

        [fetchRequest setPropertiesToFetch:@[emailAddressProperty, objectIDProperty]];
        [fetchRequest setReturnsDistinctResults:YES];
        [fetchRequest setResultType:NSDictionaryResultType];

        NSError* error = nil;
        NSArray* results = [localContext executeFetchRequest:fetchRequest error:&error];
        if(error)
        {
            NSLog(@"Error fetching messages array!!!");
        }

        for(NSDictionary* emailDetailDict in results)
        {
            NSString* emailAddress = [emailDetailDict[@"address"] lowercaseString];

            NSManagedObjectID* objectID = emailDetailDict[@"objectID"];

            if(emailAddress && objectID)
                dispatch_sync(emailContactDetailsQueue, ^{
                    allContactDetails[emailAddress] = objectID;
                });

           }

        //finally add the mynigma info contact, if necessary
        BOOL alreadyHaveMynigmaInfoContact = NO;

        EmailContactDetail* emailDetail = [EmailContactDetail addEmailContactDetailForEmail:@"info@mynigma.org" alreadyFoundOne:&alreadyHaveMynigmaInfoContact inContext:localContext];

        if(!alreadyHaveMynigmaInfoContact)
        {
            if(![[ABContactDetail allContactsDict] objectForKey:@"Mynigma Info"])
            {
                    NSEntityDescription* entityDescription = [NSEntityDescription entityForName:@"Contact" inManagedObjectContext:localContext];

                    Contact* newContact = [[Contact alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:localContext];

                    [newContact addEmailAddressesObject:emailDetail];

                    entityDescription = [NSEntityDescription entityForName:@"ABContactDetail" inManagedObjectContext:localContext];

                    ABContactDetail* addressBookContact = [[ABContactDetail alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:localContext];

                    [addressBookContact setFirstName:@"Mynigma"];
                    [addressBookContact setLastName:@"Info"];

                    [newContact setAddressBookContact:addressBookContact];

                    [localContext obtainPermanentIDsForObjects:@[emailDetail, newContact, addressBookContact] error:nil];
                
                    [addressBookContact insertIntoAllContactsDict];

                    [PublicKeyManager addMynigmaInfoPublicKeyInContext:localContext];
                }
        }

        error = nil;

        [localContext save:&error];

        if(error)
        {
            NSLog(@"Error saving local context after collecting all messages!!! %@", error);
        }

        NSLog(@"Done collecting email contact details.");

        haveCollectedAllContactDetails = YES;

        //load additional contacts (if any) from the address book (asynchronously)
        [MAIN_CONTEXT performBlock:^{
            [ABContactDetail loadAdditionalContactsFromAddressbook];
            }];
    }];
}


//this is awfully slow, but if the allMessages dict has not yet been collected together, it's the only option that doesn't block the UI forever or create duplicate messages
+ (EmailContactDetail*)fetchContactDetailFromStoreWithEmail:(NSString*)email inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"EmailContactDetail"];

    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"address = %@", email];

    [fetchRequest setPredicate:predicate];

    NSError* error = nil;
    NSArray* results = [localContext executeFetchRequest:fetchRequest error:&error];

    if(results.count>0)
    {
        return results[0];
    }
    
    return nil;
}




//searches for an EmailContactDetail with the given email and, if none exists, creates a new one. the alreadyFoundOne BOOL is an optional value that upon return will reflect whether the returned EmailContactDetail was found or newly created
+ (void)addEmailContactDetailForEmail:(NSString*)email withCallback:(void(^)(EmailContactDetail* contactDetail))callback
{
    [EmailContactDetail addEmailContactDetailForEmail:email makeDuplicateIfNecessary:NO withCallback:^(EmailContactDetail *contactDetail, BOOL alreadyFoundOne) {
        if(callback)
            callback(contactDetail);
    }];
}

+ (void)addEmailContactDetailForEmail:(NSString*)email makeDuplicateIfNecessary:(BOOL)makeDuplicate withCallback:(void(^)(EmailContactDetail* contactDetail, BOOL alreadyFoundOne))callback
{
    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

        BOOL foundOne = NO;
        
        EmailContactDetail* localEmailContactDetail = [EmailContactDetail addEmailContactDetailForEmail:email alreadyFoundOne:&foundOne inContext:localContext makeDuplicateIfNecessary:makeDuplicate];

        NSManagedObjectID* emailContactDetailObjectID = localEmailContactDetail.objectID;

        [MAIN_CONTEXT performBlock:^{

            EmailContactDetail* mainEmailContactDetail = [EmailContactDetail contactDetailWithObjectID:emailContactDetailObjectID inContext:MAIN_CONTEXT];

            if(callback)
                callback(mainEmailContactDetail, foundOne);
        }];
    }];

    return;
}

+ (EmailContactDetail*)addEmailContactDetailForEmail:(NSString*)passedEmail alreadyFoundOne:(BOOL*)found inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    return [self addEmailContactDetailForEmail:passedEmail alreadyFoundOne:found inContext:localContext makeDuplicateIfNecessary:NO];
}


+ (EmailContactDetail*)addEmailContactDetailForEmail:(NSString*)passedEmail alreadyFoundOne:(BOOL*)found inContext:(NSManagedObjectContext*)localContext makeDuplicateIfNecessary:(BOOL)makeDuplicate
{
    [ThreadHelper ensureLocalThread:localContext];

    NSString* email = [passedEmail lowercaseString];

    if(!email)
        return nil;

    __block NSManagedObjectID* emailObjectID = nil;

    if(!emailContactDetailsQueue)
        emailContactDetailsQueue = dispatch_queue_create("org.mynigma.emailContactDetailsQueue", NULL);

    dispatch_sync(emailContactDetailsQueue, ^{
        emailObjectID = [allContactDetails objectForKey:email];
    });

        if(emailObjectID)
        {
            //an EmailContactDetail already existed when the method was called
            NSError* error = nil;

            EmailContactDetail* contactDetail = (EmailContactDetail*)[localContext existingObjectWithID:emailObjectID error:&error];

            if(!error && contactDetail)
            {
                if(found)
                    *found = YES;
                return contactDetail;
            }

            NSLog(@"Failed to create email contact detail from objectID!! %@ - %@", error, emailObjectID);

            if(!makeDuplicate)
            {
                NSLog(@"Error creating contact detail with email %@", email);
                if(found)
                    *found = NO;
                return nil;
            }

            //proceed and create a duplicate in the given context
            //this may be necessary if the first object was created in a different, as yet unsaved, local context

        }
        else if(!haveCollectedAllContactDetails)
        {
            //haven't found an EmailContact, but it might be because the dictionary has not yet been collected together, so check the store
            EmailContactDetail* contactDetail = [EmailContactDetail fetchContactDetailFromStoreWithEmail:email inContext:localContext];

            if(contactDetail)
            {
                if(found)
                    *found = YES;
                return contactDetail;
            }
        }


        //none exists, so add a new one...
            NSEntityDescription* entity = [NSEntityDescription entityForName:@"EmailContactDetail" inManagedObjectContext:localContext];
            EmailContactDetail* newEmailContactDetail = [[EmailContactDetail alloc] initWithEntity:entity insertIntoManagedObjectContext:localContext];

            [newEmailContactDetail setAddress:email];
            [newEmailContactDetail setSentToServer:[NSNumber numberWithBool:NO]];
            [newEmailContactDetail setNumberOfTimesContacted:[NSNumber numberWithInteger:0]];

        NSError* error = nil;

        if(newEmailContactDetail.objectID.isTemporaryID)
            [localContext obtainPermanentIDsForObjects:@[newEmailContactDetail] error:&error];

        if(error)
        {
            NSLog(@"Failed to obtain permanent ID for newly added email contact detail: %@",newEmailContactDetail);
            error = nil;
        }

#if TARGET_OS_IPHONE

    [APPDELEGATE.contactSuggestions addEmailContactDetailToSuggestions:newEmailContactDetail];

#endif
    

//        [localContext save:&error];
//
//        
//        if(error)
//            {
//                NSLog(@"Failed to save local store before adding email contact detail: %@",newEmailContactDetail);
//                error = nil;
//            }

            emailObjectID = newEmailContactDetail.objectID;

            if(emailObjectID)
                [allContactDetails addEntriesFromDictionary:@{email:emailObjectID}];


            if(found)
                *found = NO;
            return newEmailContactDetail;
}

+ (EmailContactDetail*)emailContactDetailForAddress:(NSString*)emailAddress
{
    [ThreadHelper ensureMainThread];

    return [self emailContactDetailForAddress:emailAddress inContext:MAIN_CONTEXT];
}

+ (EmailContactDetail*)emailContactDetailForAddress:(NSString*)emailAddress inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    NSString* email = [emailAddress lowercaseString];

    if(!email || [email length]==0)
        return nil;

    NSManagedObjectID* emailContactID = [allContactDetails objectForKey:email];

    if(!emailContactID)
    {
        if(!haveCollectedAllContactDetails)
        {
            EmailContactDetail* contactDetail = [EmailContactDetail fetchContactDetailFromStoreWithEmail:email inContext:localContext];

            return contactDetail;
        }
        return nil;
    }

    NSError* error = nil;
    EmailContactDetail* emailContactDetail = (EmailContactDetail*)[localContext existingObjectWithID:emailContactID error:&error];
    if(error)
    {
        NSLog(@"Error reconstructing email contact detail!!");
        return nil;
    }
    return emailContactDetail;
}

//- (MynigmaPrivateKey*)privateKey
//{
//    MynigmaPublicKey* publicKey = self.currentPublicKey;
//
//    //if the current public key is also a private key, return it
//    //otherwise return nil
//    //one might be tempted to look for the private key elsewhere, but it's bad news if the public and private key are out of step - would rather not be able to send a safe message than not be able to open it(!)
//    if([publicKey isKindOfClass:[MynigmaPrivateKey class]])
//        return (MynigmaPrivateKey*)publicKey;
//
//    return nil;
//}
//
//- (MynigmaPublicKey*)publicKey
//{
//    return self.currentPublicKey;
//}


+ (EmailContactDetail*)contactDetailWithObjectID:(NSManagedObjectID*)contactDetailObjectID inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    if(!contactDetailObjectID)
    {
        NSLog(@"Trying to create EmailContactDetail with nil object ID!!");
        return nil;
    }

    NSError* error = nil;
    EmailContactDetail* contactDetail = (EmailContactDetail*)[localContext existingObjectWithID:contactDetailObjectID error:&error];
    
    if(error)
    {
        NSLog(@"Error creating email contact detail!!! %@", error.localizedDescription);
        return nil;
    }

    return contactDetail;
}

+ (NSDictionary*)allAddressesDict
{
    __block NSDictionary* returnValue = nil;

    if(!emailContactDetailsQueue)
        emailContactDetailsQueue = dispatch_queue_create("org.mynigma.emailContactDetailsQueue", NULL);

    dispatch_sync(emailContactDetailsQueue, ^{
        returnValue = [allContactDetails copy];
    });

    return returnValue;
}

- (Contact*)mostFrequentContact
{
    NSSet* allContacts = self.linkedToContact;

    if(allContacts.count==0)
        return nil;

    NSArray* sortedContacts = [allContacts sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"numberOfTimesContacted" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"dateLastContacted" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"addressBookContact.firstName" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"addressBookContact.lastName" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"addressBookContact.uid" ascending:YES]]];

    return sortedContacts[0];
}

@end
