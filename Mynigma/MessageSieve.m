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





#import "TargetConditionals.h"

#import "AppDelegate.h"

#import "IMAPAccount.h"




#import "MessageSieve.h"
//#import "AppDelegate.h"
//#import "EmailAddress.h"
#import "EmailRecipient.h"
#import "EmailContactDetail+Category.h"
#import "ABContactDetail.h"
#import "Contact+Category.h"
#import "EmailMessage+Category.h"
#import "EmailMessageData.h"
#import "EmailMessageInstance+Category.h"
#import "ABContactDetail+Category.h"

#import <MailCore/MailCore.h>


@implementation MessageSieve //even with multiple threads checking different folders and accounts concurrently looking up entries in the address book and adding new ones is more sensibly done in a single instance of a purpose-built structure (need to update objects and avoid problems with managed object contexts)



- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

+ (void)addEmailContactDetailToContacts:(EmailContactDetail*)emailContactDetail
{
    [ThreadHelper ensureMainThread];

    [MessageSieve addEmailContactDetailToContacts:emailContactDetail inContext:MAIN_CONTEXT];
}

+ (void)addEmailContactDetailToContacts:(EmailContactDetail*)emailContactDetail inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    NSString* name = emailContactDetail.fullName;

    //check if there is a unique contact with a similar name
    NSArray* namePieces = [name componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" .,-"]];
    NSMutableArray* subPredicates = [NSMutableArray new];
    for(NSString* piece in namePieces)
        [subPredicates addObject:[NSPredicate predicateWithFormat:@"self CONTAINS[cd] %@",piece]];
    NSPredicate* predicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
    NSArray* contacts = [ABContactDetail allContactsDict].allKeys;
    NSArray* filteredContacts = [contacts filteredArrayUsingPredicate:predicate];
    if([filteredContacts count]==1 || [filteredContacts count]==2) //allContacts contains keys both of the form "firstName lastName" and "lastName, firstName", so pairs of contacts will be found...
    {
        NSString* filteredContactName = [filteredContacts objectAtIndex:0];
        NSManagedObjectID* contactObjectID = [[ABContactDetail allContactsDict] objectForKey:filteredContactName];
        if(!contactObjectID)
        {
            NSLog(@"ObjectID is nil!!! %@",filteredContactName);
        }
        else
        {
            ABContactDetail* abContactDetail = (ABContactDetail*)[localContext existingObjectWithID:contactObjectID error:nil];

            if([abContactDetail isKindOfClass:[ABContactDetail class]])
            {
                if(abContactDetail.linkedToContact) //every ABContactDetail ought to have a linked Contact
                {
                    Contact* linkedToContact = abContactDetail.linkedToContact;
                    [linkedToContact addEmailAddressesObject:emailContactDetail];
                }
            }
        }
    }
    else
    {
        if([filteredContacts count]==0)
        {
            if(name.length>0) //don't add as contact if no name is supplied
            {
                ABContactDetail* contactDetail = (ABContactDetail*)[NSEntityDescription insertNewObjectForEntityForName:@"ABContactDetail" inManagedObjectContext:localContext];

                Contact* newContact = (Contact*)[NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:localContext];

                [localContext obtainPermanentIDsForObjects:@[contactDetail] error:nil];

                [newContact setAddressBookContact:contactDetail];
                [newContact addEmailAddressesObject:emailContactDetail];

                NSString* cleanedName = [name stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\"'<>"]];

                if([cleanedName rangeOfString:@","].location!=NSNotFound) //probably reversed: "lastName, firstName"
                {
                    NSInteger gap = [cleanedName rangeOfString:@","].location;
                    NSString* lastName = [cleanedName substringToIndex:gap];
                    NSString* firstName = [cleanedName substringFromIndex:gap+1];
                    if([firstName characterAtIndex:0] == ' ')
                        firstName = [firstName substringFromIndex:1];
                    [contactDetail setFirstName:firstName];
                    [contactDetail setLastName:lastName];
                }
                else
                {
                    NSInteger gap = [cleanedName rangeOfString:@" "].location;
                    if(gap!=NSNotFound)
                    {
                        NSString* firstName = [cleanedName substringToIndex:gap];
                        NSString* lastName = [cleanedName substringFromIndex:gap+1];
                        [contactDetail setFirstName:firstName];
                        [contactDetail setLastName:lastName];
                    }
                    else
                    {
                        [contactDetail setFirstName:cleanedName];
                    }
                }

                [contactDetail insertIntoAllContactsDict];
            }
        }
    }
}

//this method is called for each EmailRecipient found in a newly downloaded message - it adds an EmailContactDetail if necessary and a Contact object (if addToContacts is set)
/**CALL ON MAIN*/
+ (EmailContactDetail*)foundMessageContainingEmail:(NSString*)email andName:(NSString*)name addToContacts:(BOOL)addToContacts
{
    [ThreadHelper ensureMainThread];
    
    return [MessageSieve foundMessageContainingEmail:email andName:name addToContacts:addToContacts inContext:MAIN_CONTEXT];
}

+ (EmailContactDetail*)foundMessageContainingEmail:(NSString*)email andName:(NSString*)name addToContacts:(BOOL)addToContacts inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    BOOL alreadyFoundOne = NO;

    //make a new EmailContactDetail if necessary (or find the existing one)
    EmailContactDetail* emailContactDetail = [EmailContactDetail addEmailContactDetailForEmail:email alreadyFoundOne:&alreadyFoundOne inContext:localContext makeDuplicateIfNecessary:YES];

    //a corresponding email contact detail was found in the store
    if(alreadyFoundOne)
    {
        if(name.length>0)
            if(![name.lowercaseString isEqualToString:email.lowercaseString])
                if(![emailContactDetail.fullName isEqualToString:name])
                {
                    [emailContactDetail setFullName:name];
                }

        return emailContactDetail;
    }
    else //the email contact detail was created afresh - may need to associate it with a contact
    {
        if(name.length>0)
            if(![name.lowercaseString isEqualToString:email.lowercaseString])
                if(![emailContactDetail.fullName isEqualToString:name])
                {
                    [emailContactDetail setFullName:name];
                }

        if(addToContacts)
        {
            [self addEmailContactDetailToContacts:emailContactDetail inContext:localContext];
        }

        return emailContactDetail;
    }

    return emailContactDetail;
}


/*
 - (NSManagedObjectID*)siftName:(NSString*)name andEmail:(NSString*)emailAddress addToContacts:(BOOL)addToContacts inContext:(NSManagedObjectContext*)localContext
 {
 //assuming this is already running on an appropriate queue for this context

 //make email address lower case before commencing search
 NSString* email = [emailAddress lowercaseString];


 BOOL alreadyFoundOne = NO;

 //this will add an email contact detail if necessary - and simply return an existing one otherwise
 EmailContactDetail* emailContactDetail = [MODEL addEmailContactDetailForEmail:email inContext:localContext alreadyFoundOne:&alreadyFoundOne];

 //a corresponding email contact detail was found in the store
 if(alreadyFoundOne)
 {
 return emailContactDetail.objectID;
 }
 else //the email contact detail was created afresh - may need to associate it with a contact
 {
 //saving the context every time is too inefficient, so don't do that yet - if an email contact detail is added
 //NSError* error = nil;
 //[localContext save:&error];
 //if(error)
 //{
 //    NSLog(@"Error saving local context: %@",localContext);
 //}
 if(addToContacts)
 {
 __block NSManagedObjectID* emailContactDetailID = emailContactDetail.objectID;

 //the contact lookup is associated with the main thread
 [MAIN_CONTEXT performBlockAndWait:^{
 //check if there is a unique contact with a similar name
 NSArray* namePieces = [name componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" .,-"]];
 NSPredicate* predicate = [NSPredicate predicateWithFormat:@"(firstName IN[cd] %@) AND (lastName IN[cd] %@)",namePieces,[namePieces copy]];
 NSArray* contacts = contactLookup.arrangedObjects;
 NSArray* filteredContacts = [contacts filteredArrayUsingPredicate:predicate];
 if([filteredContacts count]==1)
 {
 ABContactDetail* abContactDetail = [filteredContacts objectAtIndex:0];

 if(abContactDetail)
 {
 EmailContactDetail* emailDetail = (EmailContactDetail*)[MAIN_CONTEXT objectWithID:emailContactDetailID];
 if(abContactDetail.linkedToContact) //every ABContactDetail ought to have a linked Contact
 {
 Contact* linkedToContact = abContactDetail.linkedToContact;
 [linkedToContact addEmailAddressesObject:emailDetail];
 }
 [MAIN_CONTEXT processPendingChanges];
 }
 }
 else
 {
 if([contactLookup.arrangedObjects count]==0 && addToContacts)
 {
 if(name && name.length>0) //don't add as contact if no name is supplied
 {

 ABContactDetail* contactDetail = (ABContactDetail*)[NSEntityDescription insertNewObjectForEntityForName:@"ABContactDetail" inManagedObjectContext:MAIN_CONTEXT];

 Contact* newContact = (Contact*)[NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:MAIN_CONTEXT];
 @synchronized(@"CONTACTS_LOCK")
 {
 [MODEL.allContacts addEntriesFromDictionary:@{[NSString stringWithFormat:@"%@ %@",contactDetail.firstName,contactDetail.lastName]:contactDetail.objectID,[NSString stringWithFormat:@"%@ %@",contactDetail.lastName,contactDetail.firstName]:contactDetail.objectID}];
 }

 [newContact setAddressBookContact:contactDetail];
 EmailContactDetail* emailDetail = (EmailContactDetail*)[MAIN_CONTEXT objectWithID:emailContactDetailID];
 [newContact addEmailAddressesObject:emailDetail];

 NSString* cleanedName = [name stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\"'<>"]];

 if([cleanedName rangeOfString:@","].location!=NSNotFound) //probably reversed: "lastName, firstName"
 {
 NSInteger gap = [cleanedName rangeOfString:@","].location;
 NSString* lastName = [cleanedName substringToIndex:gap];
 NSString* firstName = [cleanedName substringFromIndex:gap+1];
 if([firstName characterAtIndex:0] == ' ')
 firstName = [firstName substringFromIndex:1];
 [contactDetail setFirstName:firstName];
 [contactDetail setLastName:lastName];
 }
 else
 {
 NSInteger gap = [cleanedName rangeOfString:@" "].location;
 if(gap!=NSNotFound)
 {
 NSString* firstName = [cleanedName substringToIndex:gap];
 NSString* lastName = [cleanedName substringFromIndex:gap+1];
 [contactDetail setFirstName:firstName];
 [contactDetail setLastName:lastName];
 }
 else
 {
 [contactDetail setFirstName:cleanedName];
 }
 }
 [MAIN_CONTEXT processPendingChanges];
 }
 }
 }

 }];
 }
 return emailContactDetail.objectID;
 }
 }*/


+ (void)addRecipients:(NSArray*)records ofType:(NSInteger)type toRecordsArray:(NSMutableArray*)recordsArray withSearchString:(NSMutableString*)searchString imapMessage:(MCOIMAPMessage*)imapMessage emailMessage:(EmailMessage*)message updateDateLastContacted:(BOOL)updateDateLastContacted createContact:(BOOL)shouldCreateContact inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    if(records)
        for(MCOAddress* record in records)
        {
            //append to search string, if it's not already in it...
            if(record.mailbox && [searchString rangeOfString:[record.mailbox lowercaseString]].location==NSNotFound)
                [searchString appendFormat:@"%@,",[record.mailbox lowercaseString]];
            if(record.displayName && [searchString rangeOfString:[record.displayName lowercaseString]].location==NSNotFound)
                [searchString appendFormat:@"%@,",[record.displayName lowercaseString]];

            //create a new email recipient object to be added to the address data
            EmailRecipient* rec = [EmailRecipient new];
            [rec setEmail:[record.mailbox lowercaseString]];
            [rec setName:record.displayName];
            [rec setType:type];
            [recordsArray addObject:rec];

            if(updateDateLastContacted)
            {
                //update the dateLastContacted property

                //NSManagedObjectID* messageInstanceObjectID = messageInstance.objectID;

                EmailContactDetail* emailDetail = [MessageSieve foundMessageContainingEmail:record.mailbox andName:record.displayName addToContacts:shouldCreateContact inContext:localContext];
                if(emailDetail)
                {
                    if(!emailDetail.dateLastContacted || [emailDetail.dateLastContacted compare:imapMessage.header.date]==NSOrderedAscending)
                        [emailDetail setDateLastContacted:imapMessage.header.date];

                    for(Contact* contact in emailDetail.linkedToContact)
                    {
                        if(!contact.dateLastContacted || [contact.dateLastContacted compare:imapMessage.header.date]==NSOrderedAscending)
                            [contact setDateLastContacted:imapMessage.header.date];
                        if(contact.numberOfTimesContacted)
                            [contact setNumberOfTimesContacted:@(contact.numberOfTimesContacted.intValue+1)];
                        else
                            [contact setNumberOfTimesContacted:@1];
                    }

//                    if([emailDetail.linkedToContact count]>0)
//                    {
//                        EmailMessageInstance* mainMessageInstance = [EmailMessageInstance messageInstanceWithObjectID:messageInstanceObjectID inContext:localContext];
//                        if(!mainMessageInstance)
//                        {
//                            NSLog(@"Failed to create message instance!!");
//                        }
//                        else
//                            [mainMessageInstance setImportant:@YES];
//                    }
                }
                else
                    NSLog(@"EmailDetail could not be found");
            }
        }
}



+ (void)setAddressDataAndSearchStringForMessage:(MCOIMAPMessage*)imapMessage intoMessage:(EmailMessage*)message inContext:(NSManagedObjectContext *)localContext
{
    NSMutableString* newSearchString = [[NSMutableString alloc] initWithString:@""];
    NSMutableArray* newRecordsArray = [NSMutableArray new];

    MCOAddress* record = imapMessage.header.from;
    if(record)
    {
        if(record.displayName && record.displayName.length>0)
            [message.messageData setFromName:record.displayName];
        else
            [message.messageData setFromName:record.mailbox];

        [MessageSieve addRecipients:@[record] ofType:1 toRecordsArray:newRecordsArray withSearchString:newSearchString imapMessage:imapMessage emailMessage:message updateDateLastContacted:YES createContact:NO inContext:localContext];

        //check if it is a mac user - if so, try to add/fetch an EmailContactDetail and record the fact that a Mac was used
        if(imapMessage.header.userAgent && [imapMessage.header.userAgent rangeOfString:@"Apple Mail"].location != NSNotFound)
        {
            //it's a Mac!!
            EmailContactDetail* localContactDetail = [EmailContactDetail addEmailContactDetailForEmail:record.mailbox alreadyFoundOne:nil inContext:localContext];
            if(localContactDetail)
            {
                if(!localContactDetail.hasUsedMac.boolValue)
                {
                    [localContactDetail setHasUsedMac:@YES];
                }
            }
        }

    }
    NSArray* records = imapMessage.header.replyTo;
    if(records)
    {
        [MessageSieve addRecipients:records ofType:2 toRecordsArray:newRecordsArray withSearchString:newSearchString imapMessage:imapMessage emailMessage:message updateDateLastContacted:YES createContact:NO inContext:localContext];
    }

    records = imapMessage.header.to;
    if(records)
    {
        BOOL messageIsSentBySelf = [message isSentByMe];
        
        [MessageSieve addRecipients:records ofType:3 toRecordsArray:newRecordsArray withSearchString:newSearchString imapMessage:imapMessage emailMessage:message updateDateLastContacted:YES createContact:messageIsSentBySelf inContext:localContext];
    }
    records = imapMessage.header.cc;
    if(records)
    {
        [MessageSieve addRecipients:records ofType:4 toRecordsArray:newRecordsArray withSearchString:newSearchString imapMessage:imapMessage emailMessage:message updateDateLastContacted:NO createContact:NO inContext:localContext];
    }
    records = imapMessage.header.bcc;
    if(records)
    {
        [MessageSieve addRecipients:records ofType:5 toRecordsArray:newRecordsArray withSearchString:newSearchString imapMessage:imapMessage emailMessage:message updateDateLastContacted:NO createContact:NO inContext:localContext];
    }

    if(imapMessage.header.subject)
        [newSearchString appendString:imapMessage.header.subject];

    [message setSearchString:newSearchString];

    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:newRecordsArray forKey:@"recipients"];
    [archiver finishEncoding];
    [message.messageData setAddressData:data];
}

@end