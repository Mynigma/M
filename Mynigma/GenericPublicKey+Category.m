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


#import "GenericPublicKey+Category.h"
#import "ThreadHelper.h"
#import "CommonHeader.h"
#import "MynigmaPublicKey+Category.h"
#import "SMIMEPublicKey+Category.h"
#import "PGPPublicKey+Category.h"




@implementation GenericPublicKey (Category)



#pragma mark - Listing key labels

+ (NSArray*)listAllPublicKeyLabels;
{
    __block NSArray* returnValue = nil;

    [ThreadHelper runSyncOnMain:^{

        //fetch all public keys
        NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"GenericPublicKey"];

        NSDictionary* properties = [[NSEntityDescription entityForName:@"GenericPublicKey" inManagedObjectContext:MAIN_CONTEXT] propertiesByName];

        NSPropertyDescription* keyLabelProperty = [properties objectForKey:@"keyLabel"];

        [fetchRequest setPropertiesToFetch:@[keyLabelProperty]];
        [fetchRequest setReturnsDistinctResults:YES];
        [fetchRequest setResultType:NSDictionaryResultType];

        returnValue = [MAIN_CONTEXT executeFetchRequest:fetchRequest error:nil];
    }];
    
    return returnValue;
}

+ (NSArray*)listAllPrivateKeyLabels
{
    __block NSArray* returnValue = nil;

    [ThreadHelper runSyncOnMain:^{

        //fetch all public keys
        NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"GenericPublicKey"];

        NSDictionary* properties = [[NSEntityDescription entityForName:@"GenericPublicKey" inManagedObjectContext:MAIN_CONTEXT] propertiesByName];

        NSPropertyDescription* keyLabelProperty = [properties objectForKey:@"keyLabel"];

        [fetchRequest setPropertiesToFetch:@[keyLabelProperty]];
        [fetchRequest setReturnsDistinctResults:YES];
        [fetchRequest setResultType:NSDictionaryResultType];

        returnValue = [MAIN_CONTEXT executeFetchRequest:fetchRequest error:nil];
    }];
    
    return returnValue;
}


#pragma mark - Listing all keys

+ (NSArray*)listAllPublicKeys
{
    [ThreadHelper ensureMainThread];

        //fetch all public keys
        NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"GenericPublicKey"];

        return [MAIN_CONTEXT executeFetchRequest:fetchRequest error:nil];
}



#pragma mark - Querying keys

+ (BOOL)havePublicKeyWithKeyLabel:(NSString*)keyLabel
{
    return NO;

//    if(!keyLabel)
//        return NO;
//
//    __block BOOL returnValue = NO;
//
//    if([MynigmaGenericKey haveCompiledKeyIndex])
//    {
//        dispatch_sync([MynigmaGenericKey keyIndexQueue], ^{
//
//            NSManagedObjectID* keyObjectID = [MynigmaGenericKey keyIndex][keyLabel];
//
//            returnValue = (keyObjectID != nil);
//        });
//
//        return returnValue;
//    }
//    else
//    {
//        //the index hasn't been compiled yet: run a fetch request
//        [ThreadHelper runSyncOnKeyContext:^(NSManagedObjectContext *keyContext) {
//
//            NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MynigmaGenericKey"];
//            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"keyLabel == %@",keyLabel]];
//            NSError* error = nil;
//            NSInteger numberOfKeys = [keyContext countForFetchRequest:fetchRequest error:&error];
//
//            if(error)
//                NSLog(@"Error trying to fetch mynigma private key");
//            else
//            {
//                if(numberOfKeys>1)
//                {
//                    NSLog(@"More than one private key with label %@", keyLabel);
//                }
//
//                returnValue = numberOfKeys>0;
//            }
//            
//        }];
//        
//        return returnValue;
//    }
}

+ (BOOL)havePrivateKeyWithKeyLabel:(NSString*)keyLabel
{
    return NO;
}



//#pragma mark - Data export
//
//+ (NSArray*)dataForPublicKeyWithLabel:(NSString*)keyLabel;
//+ (NSArray*)dataForPrivateKeyWithLabel:(NSString*)keyLabel;

#pragma mark - Key properties

+ (NSDictionary*)propertiesOfKeyWithLabel:(NSString*)keyLabel
{
    //TO DO: implement
    return nil;
}


@end
