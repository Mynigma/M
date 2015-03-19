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





#import "MessageTemplate+Category.h"
#import "AppDelegate.h"
#import "FileAttachment+Category.h"
#import "AddressDataHelper.h"


static NSMutableArray* allTemplates;

@implementation MessageTemplate (Category)


/**CALL ON MAIN*/
+ (NSArray*)listAllTemplates
{
    [ThreadHelper ensureMainThread];

    if(!allTemplates)
    {
        NSFetchRequest* allTemplatesFetch = [NSFetchRequest fetchRequestWithEntityName:@"MessageTemplate"];
        NSError* error = nil;
        NSArray* results = [MAIN_CONTEXT executeFetchRequest:allTemplatesFetch error:&error];

        if(error)
        {
            NSLog(@"Error fetching all message templates!!! %@" , error);
        }
        else
            allTemplates = [results mutableCopy];
    }

    return allTemplates;
}

/**CALL ON MAIN*/
+ (BOOL)haveTemplates
{
    [ThreadHelper ensureMainThread];

    return [MessageTemplate listAllTemplates].count>0;
}

/**CALL ON MAIN*/
+ (void)addNewTemplateWithDisplayName:(NSString*)displayName subject:(NSString*)subject andHTMLBody:(NSString*)HTMLBody recipients:(NSArray*)recipients attachments:(NSArray*)attachments allAttachments:(NSArray*)allAttachments
{
    [ThreadHelper ensureMainThread];

    NSEntityDescription* entity = [NSEntityDescription entityForName:@"MessageTemplate" inManagedObjectContext:MAIN_CONTEXT];
    MessageTemplate* newTemplate = [[MessageTemplate alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];
    [newTemplate setDisplayName:displayName];
    [newTemplate setSubject:subject];
    [newTemplate setHtmlBody:HTMLBody];

    for(FileAttachment* attachment in allAttachments)
    {
        FileAttachment* freshCopy = [attachment copyInContext:MAIN_CONTEXT];

        [newTemplate addAllAttachmentsObject:freshCopy];

        //make all attachments explicit
        //don't want to be sending along any hidden attachments that the user isn't expecting to send(!)

        //if([attachments containsObject:attachment])
            [newTemplate addAttachmentsObject:freshCopy];
    }

    NSData* addressData = [AddressDataHelper addressDataForRecipients:recipients];

    [newTemplate setRecipients:addressData];

    //this forces the allTemplates array to be initialised
    [MessageTemplate listAllTemplates];

    [allTemplates addObject:newTemplate];
}

/**CALL ON MAIN*/
+ (void)removeTemplate:(MessageTemplate*)oldTemplate
{
    [ThreadHelper ensureMainThread];

    if([allTemplates containsObject:oldTemplate])
    {
        [allTemplates removeObject:oldTemplate];
        [MAIN_CONTEXT deleteObject:oldTemplate];
    }
}

@end
