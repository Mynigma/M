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





#import "EmailAddress+Category.h"
#import "ThreadHelper.h"
#import "AppDelegate.h"
#import "NSString+EmailAddresses.h"




static NSMutableDictionary* emailIndex;

BOOL haveCompiledEmailIndex;

static dispatch_queue_t emailIndexingQueue;



@implementation EmailAddress (Category)


#pragma mark - PRIVATE METHODS

+ (dispatch_queue_t)emailIndexQueue
{
    if(!emailIndexingQueue)
        emailIndexingQueue = dispatch_queue_create("org.mynigma.emailIndexQueue", NULL);

    return emailIndexingQueue;
}

+ (EmailAddress*)fetchEmailAddressFromStoreForEmail:(NSString*)emailString inContext:(NSManagedObjectContext*)keyContext
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"EmailAddress"];

    emailString = [emailString canonicalForm];

    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"address == %@", emailString];

    [fetchRequest setPredicate:predicate];

    NSError* error = nil;
    NSArray* results = [keyContext executeFetchRequest:fetchRequest error:&error];

    if(results.count>1)
    {
        NSLog(@"More than one EmailAddress object with address %@ - this should never happen(!!!!)", emailString);
    }

    return results.firstObject;
}





#pragma mark - PUBLIC METHODS


+ (void)compileEmailIndex
{
    [ThreadHelper runAsyncOnKeyContext:^{

        haveCompiledEmailIndex = NO;

        //create a fresh index
        emailIndex = [NSMutableDictionary new];

        //fetch all email addresses
        NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"EmailAddress"];

        NSDictionary* properties = [[NSEntityDescription entityForName:@"EmailAddress" inManagedObjectContext:KEY_CONTEXT] propertiesByName];

        NSPropertyDescription* emailAddressProperty = [properties objectForKey:@"address"];

        NSExpressionDescription* objectIDProperty = [NSExpressionDescription new];
        objectIDProperty.name = @"objectID";
        objectIDProperty.expression = [NSExpression expressionForEvaluatedObject];
        objectIDProperty.expressionResultType = NSObjectIDAttributeType;

        [fetchRequest setPropertiesToFetch:@[emailAddressProperty, objectIDProperty]];
        [fetchRequest setReturnsDistinctResults:YES];
        [fetchRequest setResultType:NSDictionaryResultType];

        NSError* error = nil;
        NSArray* results = [KEY_CONTEXT executeFetchRequest:fetchRequest error:&error];
        if(error)
        {
            NSLog(@"Error fetching messages array!!!");
        }

        for(NSDictionary* publicKeyDict in results)
        {
            NSString* emailAddress = publicKeyDict[@"address"];

            NSManagedObjectID* objectID = publicKeyDict[@"objectID"];

            if(objectID.isTemporaryID)
            {
                NSLog(@"Fetched objectID for public key is temporary(!!) %@", objectID);
                continue;
            }

            if(emailAddress && objectID)
                dispatch_sync([self emailIndexQueue], ^{
                    [emailIndex setObject:objectID forKey:emailAddress];
                });
        }
        
        haveCompiledEmailIndex = YES;
        
        NSLog(@"Done compiling email address index");
        
    }];
}

+ (EmailAddress*)emailAddressForEmail:(NSString*)emailString inContext:(NSManagedObjectContext*)keyContext
{
    return [EmailAddress emailAddressForEmail:emailString inContext:keyContext makeIfNecessary:NO];
}

+ (EmailAddress*)emailAddressForEmail:(NSString*)emailString inContext:(NSManagedObjectContext*)keyContext makeIfNecessary:(BOOL)shouldCreate
{
    emailString = [emailString canonicalForm];

    if(!emailString)
        return nil;

    if(!haveCompiledEmailIndex)
    {
        EmailAddress* emailAddress = [self fetchEmailAddressFromStoreForEmail:emailString inContext:keyContext];

        if(emailAddress)
            return emailAddress;

        //no email address exists

        if(!shouldCreate)
            return nil;

        //need to create a new object
    }

    __block NSManagedObjectID* objectID = nil;

    @synchronized(@"EmailAddress_LOCK")
    {

    dispatch_sync([EmailAddress emailIndexQueue], ^{

        objectID = emailIndex[emailString];

        //insert a null object to prevent adding the same email twice without blocking the thread
        if(!objectID && shouldCreate)
            emailIndex[emailString] = [NSNull null];
    });

    }

    if(!objectID)
    {
        if(shouldCreate)
        {
            NSEntityDescription* entityDescription = [NSEntityDescription entityForName:@"EmailAddress" inManagedObjectContext:keyContext];
            EmailAddress* newAddress = [[EmailAddress alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:keyContext];

            NSError* error = nil;

            [keyContext obtainPermanentIDsForObjects:@[newAddress] error:&error];

            if(error)
            {
                NSLog(@"Error obtaining permanent objectID for EmailAddress object: %@", error);
            }

            dispatch_sync([EmailAddress emailIndexQueue], ^{
                
                emailIndex[emailString] = newAddress.objectID;

            });

            [newAddress setDateAdded:[NSDate date]];

            [newAddress setAddress:emailString];

            return newAddress;
        }
        else
        {
            return nil;
        }
    }

    if(![objectID isKindOfClass:[NSManagedObjectID class]])
        return nil;

    NSError* error = nil;

    EmailAddress* emailAddress = (EmailAddress*)[keyContext existingObjectWithID:objectID error:&error];

    if(error)
        NSLog(@"Error creating email address from objectID on main context: %@", error);
    
    return emailAddress;
}




@end
