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





#import "ContactCompletionHelper.h"
#import "EmailContactDetail+Category.h"
#import "ABContactDetail+Category.h"
#import "AppDelegate.h"
#import "Contact.h"




@implementation ContactCompletionHelper


//TO DO: implement
+ (NSArray*)completionsForSubstring:(NSString*)substring withPreviousQueries:(NSMutableDictionary*)allQueries
{
//    NSMutableArray* result = [NSMutableArray new];
//
//    NSArray* unfilteredSuggestions = nil;
//
//    NSArray* allPreviousSubstrings = allQueries.allKeys;
//
//    NSString* largestPreviousSubstring = nil;
//
//    for(NSString* previousString in allPreviousSubstrings)
//    {
//        if([substring.lowercaseString hasPrefix:previousString.lowercaseString])
//        {
//            if(previousString.length > largestPreviousSubstring.length)
//                largestPreviousSubstring = previousString;
//        }
//    }
//
//    if(largestPreviousSubstring)
//    {
//        unfilteredSuggestions = allQueries[largestPreviousSubstring];
//    }
//    else
//    {
//        //no previous suggestions to work with, have to use the complete list...
//
//        //all EmailContactDetail objects
//        NSDictionary* allAddressesDict = [EmailContactDetail allAddressesDict];
//
//        //all ABContactDetail objects
//        NSDictionary* allContactsDict = [ABContactDetail allContactsDict];
//
//        for(NSString* detailString in allContactsDict.allKeys)
//        {
//            if(detailString && [detailString.lowercaseString hasPrefix:substring.lowercaseString])
//            {
//                NSManagedObjectID* contactDetailID = allContactsDict[detailString];
//                ABContactDetail* contactDetail = (ABContactDetail*)[MAIN_CONTEXT existingObjectWithID:contactDetailID error:nil];
//                if([contactDetail isKindOfClass:[ABContactDetail class]] && contactDetail.linkedToContact.emailAddresses.count)
//                    [result addObject:detailString];
//            }
//        }
//
//
//    }
//
//    for(NSString* emailAddress in allAddressesArr)
//    {
//        if(emailAddress && [[emailAddress lowercaseString] hasPrefix:[substring lowercaseString]])
//            [result addObject:emailAddress];
//    }
//
//    [result sortUsingComparator:^NSComparisonResult(id string1, id string2)
//     {
//         BOOL hasMynigma1 = NO;
//         BOOL hasMynigma2 = NO;
//         NSInteger value1 = 0;
//         NSInteger value2 = 0;
//         NSManagedObjectID* emailContactDetail1ID = [allAddressesDict objectForKey:string1];
//         if([emailContactDetail1ID isKindOfClass:[NSManagedObjectID class]])
//         {
//             NSError* error = nil;
//             EmailContactDetail* emailContactDetail1 = (EmailContactDetail*)[MAIN_CONTEXT existingObjectWithID:emailContactDetail1ID error:&error];
//             if(error)
//                 NSLog(@"Error: %@\nwhile fetching email contact detail with ID: %@",error,emailContactDetail1ID);
//             if([emailContactDetail1 isKindOfClass:[EmailContactDetail class]])
//             {
//                 value1 = emailContactDetail1.numberOfTimesContacted.integerValue;
//                 if([MynigmaPublicKey havePublicKeyForEmailAddress:emailContactDetail1.address])
//                     hasMynigma1 = YES;
//             }
//         }
//         NSManagedObjectID* emailContactDetail2ID = [allAddressesDict objectForKey:string2];
//         if([emailContactDetail2ID isKindOfClass:[NSManagedObjectID class]])
//         {
//             NSError* error = nil;
//             EmailContactDetail* emailContactDetail2 = (EmailContactDetail*)[MAIN_CONTEXT existingObjectWithID:emailContactDetail2ID error:&error];
//             if(error)
//                 NSLog(@"Error: %@\nwhile fetching email contact detail with ID: %@",error,emailContactDetail2ID);
//             if([emailContactDetail2 isKindOfClass:[EmailContactDetail class]])
//             {
//                 value2 = emailContactDetail2.numberOfTimesContacted.integerValue;
//                 if([MynigmaPublicKey havePublicKeyForEmailAddress:emailContactDetail2.address])
//                     hasMynigma2 = YES;
//             }
//         }
//
//         NSManagedObjectID* abContactDetailID = [allContactsDict objectForKey:string1];
//         if(abContactDetailID)
//         {
//             NSError* error = nil;
//             ABContactDetail* abContactDetail = (ABContactDetail*)[MAIN_CONTEXT existingObjectWithID:abContactDetailID error:&error];
//             if(error)
//                 NSLog(@"Error: %@\nwhile fetching AB contact detail with ID: %@",error,emailContactDetail1ID);
//             if(abContactDetail)
//             {
//                 value1 = abContactDetail.linkedToContact.numberOfTimesContacted.integerValue;
//                 if([abContactDetail.linkedToContact mostFrequentEmail].currentPublicKey)
//                     hasMynigma1 = YES;
//             }
//         }
//
//         abContactDetailID = [allContactsDict objectForKey:string2];
//         if(abContactDetailID)
//         {
//             NSError* error = nil;
//             ABContactDetail* abContactDetail = (ABContactDetail*)[MAIN_CONTEXT existingObjectWithID:abContactDetailID error:&error];
//             if(error)
//                 NSLog(@"Error: %@\nwhile fetching AB contact detail with ID: %@",error,emailContactDetail1ID);
//             if(abContactDetail)
//             {
//                 value2 = abContactDetail.linkedToContact.numberOfTimesContacted.integerValue;
//                 if([abContactDetail.linkedToContact mostFrequentEmail].currentPublicKey)
//                     hasMynigma2 = YES;
//             }
//         }
//         if(hasMynigma1 && !hasMynigma2)
//             return NSOrderedAscending;
//         if(hasMynigma2 && !hasMynigma1)
//             return NSOrderedDescending;
//         if(value1>value2)
//             return NSOrderedAscending;
//         if(value1<value2)
//             return NSOrderedDescending;
//         return [string2 compare:string1];
//     }];
//    
//    if (substring && result)
//        [lastEmailAddressesQueries setObject:result forKey:substring];
//    
//    return result;

    return nil;
}

@end
