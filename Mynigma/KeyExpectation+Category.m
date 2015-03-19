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





#import "KeyExpectation+Category.h"
#import "MynigmaPublicKey+Category.h"
#import "EmailAddress+Category.h"
#import "MynigmaPrivateKey+Category.h"
#import "ThreadHelper.h"
#import "AppDelegate.h"



@implementation KeyExpectation (Category)


#pragma mark - PRIVATE METHODS

+ (KeyExpectation*)expectationFrom:(EmailAddress*)fromAddress to:(EmailAddress*)toAddress inContext:(NSManagedObjectContext*)keyContext makeIfNecessary:(BOOL)makeIfNecessary
{
    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"KeyExpectation"];

    NSPredicate* fetchPredicate = [NSPredicate predicateWithFormat:@"(toAddress == %@) AND (fromAddress == %@)", toAddress.address, fromAddress.address];

    [fetchRequest setPredicate:fetchPredicate];

    NSError* error = nil;

    KeyExpectation* result = nil;

    //lock to ensure uniqueness of KeyExpectation objects for a given (toAddress, fromAddress) pair
    //first fetch, then create if none found
    @synchronized(@"KEY_EXPECTATION_LOCK")
    {

        NSArray* results = [keyContext executeFetchRequest:fetchRequest error:&error];

        if(results.count > 0)
        {
            if(results.count > 1)
            {
                NSLog(@"More than one KeyExpectation for the same address combination!!! This should never happen!!");
            }

            result = results.firstObject;
        }
        else
        {
            //none found - create a new one(!)
            if(makeIfNecessary)
            {
                NSEntityDescription* entityDescription = [NSEntityDescription entityForName:@"KeyExpectation" inManagedObjectContext:keyContext];

                KeyExpectation* newKeyExpectation = [[KeyExpectation alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:keyContext];

                [newKeyExpectation setFromAddress:fromAddress];
                [newKeyExpectation setToAddress:toAddress];

                NSError* error = nil;

                [keyContext save:&error];

                if(error)
                {
                    NSLog(@"Error saving key context after adding key expectation!! %@", error);
                }

                //save the main context and the store context, persisting the key expectation to disk
                [CoreDataHelper save];

                result = newKeyExpectation;
            }
        }
    }

    return result;
}










#pragma mark - PUBLIC METHODS

//key to be used for introduction of the actual signature key when sending a message
+ (MynigmaPrivateKey*)signatureKeyForIntroductionFrom:(EmailAddress*)fromAddress to:(EmailAddress*)toAddress inContext:(NSManagedObjectContext*)keyContext
{
    KeyExpectation* expectation = [KeyExpectation expectationFrom:fromAddress to:toAddress inContext:keyContext makeIfNecessary:YES];

    //defaults to the current signature key for the sending address
    if(!expectation.expectedSignatureKey)
    {
        expectation.expectedSignatureKey = [fromAddress currentKey];
    }

    return [expectation.expectedSignatureKey isKindOfClass:[MynigmaPrivateKey class]]?(MynigmaPrivateKey*)expectation.expectedSignatureKey:nil;
}

//key to be used to sign messages from fromAddress to toAddress
+ (MynigmaPrivateKey*)signatureKeyForMessageFrom:(EmailAddress*)fromAddress
{
    MynigmaPublicKey* currentKey = [fromAddress currentKey];

    return [currentKey isKindOfClass:[MynigmaPrivateKey class]]?(MynigmaPrivateKey*)currentKey:nil;
}

//key to be used for encryption when sending a message
+ (MynigmaPublicKey*)encryptionKeyForMessageTo:(EmailAddress*)toAddress
{
    //switch toAddress and fromAddress: the signature key that Alice expects from Bob is also the key she uses to sign messages addressed to him
    return toAddress.currentKey;
}


//from now on, expect messages with this sender/recipient combination to be signed by newPublicKey or accompanied by a valid introduction from newPublicKey to the key used to sign the message
+ (void)updateExpectedSignatureKey:(MynigmaPublicKey*)newPublicKey forMessageFrom:(EmailAddress*)fromAddress to:(EmailAddress*)toAddress withDate:(NSDate*)newAnchorDate
{
    [ThreadHelper runAsyncOnKeyContext:^{

        KeyExpectation* expectation = [KeyExpectation expectationFrom:fromAddress to:toAddress inContext:KEY_CONTEXT makeIfNecessary:YES];

        //only update the key if the current expectation was formed before the new one
        //otherwise key expectations would keep being adjusted to old messages found buried deep in the inbox
        if(!expectation.dateAnchored || [expectation.dateAnchored compare:newAnchorDate] == NSOrderedAscending)
        {
            expectation.dateAnchored = newAnchorDate;

        //set the new expected key
        expectation.expectedSignatureKey = newPublicKey;

        NSError* error = nil;

        [KEY_CONTEXT save:&error];

        if(error)
        {
            NSLog(@"Error saving key context after adding key expectation!! %@", error);
        }

        //save the main context and the store context, persisting the key expectation to disk
        [CoreDataHelper save];
        }
    }];
}

@end
