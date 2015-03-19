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
#import "IMAPFolderManager.h"
#import "IMAPAccountSetting+Category.h"
#import "IMAPFolderSetting+Category.h"
#import "GmailLabelSetting.h"
#import "GmailAccountSetting.h"
#import "EmailMessage.h"
#import "EmailMessageInstance+Category.h"
#import "FetchAllFoldersOperation.h"
#import "DisconnectOperation.h"
#import "CreateFolderOperation.h"
#import "AccountCheckManager.h"
#import "SelectionAndFilterHelper.h"




@implementation IMAPFolderManager


//get list of folders from server, update labels
+ (void)updateFoldersWithSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation inLocalContext:(NSManagedObjectContext*)localContext withAccountSettingID:(NSManagedObjectID*)accountSettingID userInitiated:(BOOL)userInitiated withCallback:(void (^)(void))callback
{
    [ThreadHelper ensureLocalThread:localContext];

    FetchAllFoldersOperation* fetchFoldersOperation = [FetchAllFoldersOperation fetchAllFoldersWithSession:session withCallback:^(NSError *error, NSArray *returnedFetchedFolders)
    {

        if(error)
        {
            NSLog(@"Error fetching folders to update list: %@",error.localizedDescription);
            return;
        }

        __block NSArray* fetchedFolders = returnedFetchedFolders;

        [ThreadHelper runSyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

            //if folders were added or deleted, the message list filters should be updated
            //for example, when a new account is added, the filters should be updated *after* the folders were established
            BOOL foldersChanged = NO;

            if(!accountSettingID)
                return;
            IMAPAccountSetting* localAccountSetting = (IMAPAccountSetting*)[localContext objectWithID:accountSettingID];

            NSMutableArray* currentFolders = [[localAccountSetting.folders sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"path" ascending:YES]]] mutableCopy];


            //Use INBOX if it wasn't fetched TODO: -failsave- Check if inbox exists but async is a problem
            if(![[fetchedFolders valueForKey:@"path"] containsObject:@"INBOX"])
            {
                MCOIMAPFolder* inboxfolder = [MCOIMAPFolder new];
                inboxfolder.delimiter = [[session defaultNamespace] mainDelimiter];
                inboxfolder.path = @"INBOX";
                NSMutableArray* fetchyFolders = [NSMutableArray arrayWithObject:inboxfolder];
                fetchedFolders = [fetchyFolders arrayByAddingObjectsFromArray:fetchedFolders];
            }

            for(IMAPFolderSetting* folderSetting in [currentFolders copy])
            {
                if(![[fetchedFolders valueForKey:@"path"] containsObject:folderSetting.path])
                {
                    [localAccountSetting removeFoldersObject:folderSetting];
                    //NSLog(@"Delete 13");

                    [currentFolders removeObject:folderSetting];
                    [localContext deleteObject:folderSetting];

                    //[localContext processPendingChanges];

                    foldersChanged = YES;
                }
            }

            for(MCOIMAPFolder* folder in fetchedFolders)
            {
                if(![[currentFolders valueForKey:@"path"] containsObject:[folder path]])
                    // checks if the folder is a non selectable
                    if(!([folder flags] & MCOIMAPFolderFlagNoSelect))
                    {
                        [IMAPFolderManager createFolderSetting:folder usingSession:session disconnectOperation:disconnectOperation inAccount:localAccountSetting withContext:localContext withPath:folder.path];
                        foldersChanged = YES;
                    }
            }
            
            // All folders are created, now set parent - child relationships
            [IMAPFolderManager setParentChildRelationshipsInAccount:localAccountSetting withSession:session];

            NSError* error = nil;
            [localContext save:&error];
            if(error)
                NSLog(@"Error saving context: %@",error);


            [SelectionAndFilterHelper refreshAllMessages];
            //__block NSManagedObjectID* blockAccountID = localAccountSetting.objectID;


            /* Creates non-existing standard folders */
            //need to execute the callback when the last operation has completed, so count the number of active operations. start at one and decrease by 1 when all operations have been started...
            NSArray* standardFolders = @[@"Inbox",@"Spam",@"Drafts",@"Sent",@"Bin"];

            __block NSInteger threadCounter = standardFolders.count + 1; //add one to be sure that the loop is not exited before all threads are started
            
            //Have plist for language Pref ?

            NSString* namespace = session.defaultNamespace.mainPrefix;

            NSString* identifier = [NSString stringWithFormat:@"Update folders identifier %ld",random()];

            for (NSString* folderName in standardFolders)
            {
                NSString* var = [NSString stringWithFormat:@"%@Folder",folderName.lowercaseString];
                if(![localAccountSetting valueForKey:var])
                {
                        [self createStandardFolderOnServer:[NSString stringWithFormat:@"%@%@",namespace,folderName] usingSession:session disconnectOperation:disconnectOperation withAccountSettingID:accountSettingID  withThreadCount:&threadCounter withIdentifier:identifier userInitiated:userInitiated withCallback:^{
                            [MAIN_CONTEXT performBlock:^{
                                [SelectionAndFilterHelper reloadOutlinePreservingSelection];
                                //[APPDELEGATE updateFilters];
                                callback();
                            }];
                        }];

                        //tehcnically we should wait until the folder is created before updating the list, but never mind...
                        foldersChanged = YES;
                }
                else
                    threadCounter--;
            }


            @synchronized(identifier)
            {
                threadCounter--;

                if(threadCounter<=0)
                {
                    [ThreadHelper runAsyncOnMain:^{
                        [SelectionAndFilterHelper reloadOutlinePreservingSelection];
                        //[APPDELEGATE updateFilters];
                        callback();
                    }];
                }
            }


            //if there was a change to the list of folders (especially if any were added) then update the filters of displayed messages
            if(foldersChanged)
                [SelectionAndFilterHelper updateFilters];
        }];
    }];

    if(userInitiated)
        [fetchFoldersOperation setHighPriority];
    else
        [fetchFoldersOperation setMediumPriority];

    [fetchFoldersOperation addToMailCoreQueueWithDisconnectOperation:disconnectOperation];
}

+ (void)createStandardFolderOnServer:(NSString*)folderPath usingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation withAccountSettingID:(NSManagedObjectID*)accountSettingID withThreadCount:(NSInteger*)threadCounter withIdentifier:(NSString*)identifier userInitiated:(BOOL)userInitiated withCallback:(void (^)(void))callback
{
    CreateFolderOperation* createFolderOperation = [CreateFolderOperation createFolderOperationWithPath:folderPath session:session withCallback:^(NSError *error)
    {

        switch(error.code)
        {
            case MCOErrorCreate:
            {
                // couldn't create folder. we assume it's because the folder already exists
                // try Mynigma+Delimiter+FolderName instead, unless the path already starts with Mynigma - don't want unlimited recursion...
                if(![folderPath hasPrefix:@"Mynigma"])
                {
                    if ([[session defaultNamespace] mainDelimiter])
                    {
                        [self createStandardFolderOnServer:[NSString stringWithFormat:@"Mynigma%c%@", [[session defaultNamespace] mainDelimiter], folderPath] usingSession:session disconnectOperation:disconnectOperation withAccountSettingID:accountSettingID withThreadCount:threadCounter withIdentifier:identifier userInitiated:userInitiated withCallback:callback];
                    }
                    else
                    {   // No main delimiter found
                        [self createStandardFolderOnServer:[NSString stringWithFormat:@"Mynigma%c%@", '/', folderPath] usingSession:session disconnectOperation:disconnectOperation withAccountSettingID:accountSettingID withThreadCount:threadCounter withIdentifier:identifier userInitiated:userInitiated withCallback:callback];
                    }
                }
                else
                {
                    @synchronized(identifier)
                    {
                        if(threadCounter)
                        {
                            *threadCounter = *threadCounter - 1;
                            if(*threadCounter <= 0)
                            {
                                callback();
                            }
                        }
                        else
                            callback();
                    }
                }
            }
                break;

            case MCOErrorNone:
            {
                //successfully created folder
                [MAIN_CONTEXT performBlock:^{

                    IMAPAccountSetting* accountSetting = (IMAPAccountSetting*)[MAIN_CONTEXT existingObjectWithID:accountSettingID error:nil];
                    [self createFolderSetting:nil usingSession:session disconnectOperation:disconnectOperation inAccount:accountSetting withContext:MAIN_CONTEXT withPath:folderPath]; //this will automatically set the folder relationship of the accountSetting

                    [CoreDataHelper save];

                    @synchronized(identifier)
                    {
                        if(threadCounter)
                        {
                            *threadCounter = *threadCounter - 1;
                            if(*threadCounter <= 0)
                            {
                                callback();
                            }
                        }
                        else
                            callback();
                    }
                }];
            }
                break;

            default:
            {
                //some other error
                //TO DO: deal with this case in a graceful manner
                @synchronized(identifier)
                {
                    if(threadCounter)
                    {
                        *threadCounter = *threadCounter - 1;
                        if(*threadCounter <= 0)
                        {
                            callback();
                        }
                    }
                    else
                        callback();
                }
            }
        }
    }];

    if(userInitiated)
        [createFolderOperation setHighPriority];
    else
        [createFolderOperation setMediumPriority];

    [createFolderOperation addToMailCoreQueueWithDisconnectOperation:disconnectOperation];
}


+ (NSString*) fixFolderNameEncoding:(NSString*)folderName
{
    NSMutableString* encodedName = [folderName mutableCopy];

    // to utf8 encoding
    NSData* data = [encodedName dataUsingEncoding:NSUTF8StringEncoding];
     
    encodedName = [[NSMutableString alloc] initWithData:data encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF7_IMAP)];
     
     if (!encodedName){
         encodedName = [[NSMutableString alloc] initWithString:folderName];
     }
    
    return encodedName;
}



+(void) setParentChildRelationshipsInAccount:(IMAPAccountSetting*)localAccountSetting withSession:(MCOIMAPSession*)session
{

    for (IMAPFolderSetting* folderSetting in localAccountSetting.folders)
    {
        NSArray* components = [[session defaultNamespace] componentsFromPath:folderSetting.path];
        if ([components count] > 1)
        {
            if(components.count==2 && ([components[0] isEqual:@"[Gmail]"] ||
                                      [components[0] isEqual:@"[Google Mail]"] ||
                                      [[(NSString*)components[0] lowercaseString]  isEqual:@"inbox"]))
            {
                //it's a Gmail label that's a direct child of the root
                //since the root isn't included in our list of folders, don't treat this as a child
                continue;
            }



            //this folder is a child, set parent and for parent add as child
            
            //Looking for the Parent folder
            NSArray* parentComponents = [components subarrayWithRange:NSMakeRange(0, components.count-1)];
            NSString* parentFolderPath = [[session defaultNamespace] pathForComponents:parentComponents];
            
            IMAPFolderSetting* parentFolder = [IMAPFolderManager findFolderSettingForPath:parentFolderPath inAccount:localAccountSetting];
            
            if (parentFolder)
            {
                [folderSetting setParentFolder:parentFolder];
                if (![[parentFolder subFolders] containsObject:folderSetting])
                    [parentFolder addSubFoldersObject:folderSetting];
            }
            //else no parentfolder found, do not set any relationships
        }
    }
}

+(IMAPFolderSetting*) findFolderSettingForPath:(NSString*)folderPath inAccount:(IMAPAccountSetting*)localAccountSetting
{
    for (IMAPFolderSetting* folderSetting in localAccountSetting.folders)
    {
        if ([folderSetting.path isEqual:folderPath])
        {
            return folderSetting;
        }
    }
    return nil;
}


+(void) setDisplayNameForFolderSetting:(IMAPFolderSetting*)folderSetting withComponents:(NSArray*)components
{
    NSString* displayName;
    
    if ([components count] > 0)
        displayName = components[[components count]-1];
    else if ([folderSetting.path  isEqual:@"INBOX"])
        displayName = @"INBOX";
    else
        displayName = @"NO NAME";
    
    displayName = [IMAPFolderManager fixFolderNameEncoding:displayName];
    
    [folderSetting setDisplayName:displayName];
}

+(BOOL) setFolderTypeWithFlags:(NSUInteger)flags forFolderSetting:(IMAPFolderSetting*)newFolderSetting
{
    switch (flags)
    {
        case MCOIMAPFolderFlagAllMail: {
            [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:YES]];
            if([newFolderSetting isKindOfClass:[GmailLabelSetting class]])
            {
                [(GmailLabelSetting*)newFolderSetting setAllMailForAccount:(GmailAccountSetting*)newFolderSetting.inIMAPAccount];
                [(GmailLabelSetting*)newFolderSetting setLabelName:@"\\All"];
            }
            break;
        }
        
        case MCOIMAPFolderFlagSpam: {
            [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:NO]];
            [newFolderSetting setSpamForAccount:newFolderSetting.inIMAPAccount];
            if([newFolderSetting isKindOfClass:[GmailLabelSetting class]])
                [(GmailLabelSetting*)newFolderSetting setLabelName:@"\\Junk"];
            break;
        }
            
        case MCOIMAPFolderFlagTrash: {
            [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:NO]];
            [newFolderSetting setBinForAccount:newFolderSetting.inIMAPAccount];
            if([newFolderSetting isKindOfClass:[GmailLabelSetting class]])
                [(GmailLabelSetting*)newFolderSetting setLabelName:@"\\Trash"];
            break;
        }
            
        case MCOIMAPFolderFlagDrafts: {
            [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:NO]];
            [newFolderSetting setDraftsForAccount:newFolderSetting.inIMAPAccount];
            if([newFolderSetting isKindOfClass:[GmailLabelSetting class]])
                [(GmailLabelSetting*)newFolderSetting setLabelName:@"\\Draft"];
            break;
        }
            
        case MCOIMAPFolderFlagInbox: {
            [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:YES]];
            [newFolderSetting setInboxForAccount:newFolderSetting.inIMAPAccount];
            if([newFolderSetting isKindOfClass:[GmailLabelSetting class]])
            {
                [(GmailLabelSetting*)newFolderSetting setLabelName:@"\\Inbox"];
                [(GmailLabelSetting*)newFolderSetting setIsSystemLabel:@YES];
            }
            break;
        }

        case MCOIMAPFolderFlagSentMail: {
            [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:YES]];
            [newFolderSetting setSentForAccount:newFolderSetting.inIMAPAccount];
            if([newFolderSetting isKindOfClass:[GmailLabelSetting class]])
                [(GmailLabelSetting*)newFolderSetting setLabelName:@"\\Sent"];
            break;
        }
         
        case MCOIMAPFolderFlagStarred: {
            [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:YES]];
            if([newFolderSetting isKindOfClass:[GmailLabelSetting class]])
            {
                [(GmailLabelSetting*)newFolderSetting setLabelName:@"\\Starred"];
                [(GmailLabelSetting*)newFolderSetting setStarredForAccount:(GmailAccountSetting*)newFolderSetting.accountSetting];
            }
            break;
        }
    
        case MCOIMAPFolderFlagImportant: {
            [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:YES]];
            if([newFolderSetting isKindOfClass:[GmailLabelSetting class]])
            {
                
                [(GmailLabelSetting*)newFolderSetting setLabelName:@"\\Important"];
                [(GmailLabelSetting*)newFolderSetting setImportantForAccount:(GmailAccountSetting*)newFolderSetting.accountSetting];
            }
            break;
        }
            
        default: {
            // new folder flag introduced cannot handle this, treat as "normal" folder
            return NO;
        }
    }
    
    return YES;
}

+ (BOOL) checkAndSetSpecialFolderSetting:(IMAPFolderSetting*)newFolderSetting
{
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"ProviderDetails" ofType:@"plist"];
    NSDictionary* providerDict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    
    NSDictionary* folderDict = [providerDict objectForKey:newFolderSetting.inIMAPAccount.incomingServer];
    
    if (!folderDict)
        // provider not yet in our list
        return NO;
    
    // the actual folder dict
    folderDict = [folderDict objectForKey:@"folder"];
    
    NSString* path = [IMAPFolderManager fixFolderNameEncoding:newFolderSetting.path];
    
    // now check if the current folderSetting is a special folder
    NSString* folder = [folderDict objectForKey:path];
    
    if (!folder)
    {
        // do the old way
        return NO;
    }
    
    if ([folder isEqual:@"all mail"])
    {
        if([newFolderSetting isKindOfClass:[GmailLabelSetting class]])
        {
            //should never reach this point but you never know
            [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:YES]];
            [(GmailLabelSetting*)newFolderSetting setAllMailForAccount:(GmailAccountSetting*)newFolderSetting.inIMAPAccount];
            return YES;
        }
    }
    
    if ([folder isEqual:@"archive"])
    {
        [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:NO]];
        return YES;
    }
    
    if ([folder isEqual:@"inbox"])
    {
        [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:YES]];
        [newFolderSetting setInboxForAccount:newFolderSetting.inIMAPAccount];
        return YES;
    }
    
    if ([folder isEqual:@"spam"])
    {
        [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:NO]];
        [newFolderSetting setSpamForAccount:newFolderSetting.inIMAPAccount];
        return YES;
    }
    
    if ([folder isEqual:@"trash"])
    {
        [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:NO]];
        [newFolderSetting setBinForAccount:newFolderSetting.inIMAPAccount];
        return YES;
    }
    
    if ([folder isEqual:@"drafts"])
    {
        [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:NO]];
        [newFolderSetting setDraftsForAccount:newFolderSetting.inIMAPAccount];
        return YES;
    }
    
    if ([folder isEqual:@"notes"])
    {
        [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:NO]];
        return YES;
    }
    
    if ([folder isEqual:@"sent"])
    {
        [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:YES]];
        [newFolderSetting setSentForAccount:newFolderSetting.inIMAPAccount];
        return YES;
    }
    
    // hugh, it's in the plist but not in here? Add case for this special folder
    return NO;
}

//this takes a folderName found on the server and tries to attach the respective inboxFolder, spamFolder, etc. of the newly created IMAPFolderSetting
//also determines if folder is "shown as standard", i.e. shown when only the account is selected

+ (void)setFolderType:(IMAPFolderSetting*)newFolderSetting usingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation forMCOIMAPFolder:(MCOIMAPFolder*)folder
{
    NSString* folderPath = newFolderSetting.path?newFolderSetting.path:@"";
    NSArray* components  = [[session defaultNamespace] componentsFromPath:folderPath];
    
    //set display name
    [IMAPFolderManager setDisplayNameForFolderSetting:newFolderSetting withComponents:components];
    
    
    //check for gmail system label
    if([newFolderSetting isKindOfClass:[GmailLabelSetting class]])
    {

        [(GmailLabelSetting*)newFolderSetting setIsSystemLabel:@NO];
        
        if ([components count] > 0)
            if([components[0] isEqual:@"[Gmail]"] || [components[0] isEqual:@"[Google Mail]"])
                [(GmailLabelSetting*)newFolderSetting setIsSystemLabel:@YES];
    }
    
    //look for flags, makes finding standard folders easy - currently used by google,yahoo
    NSUInteger flags = [folder flags];
    if (flags)
    {
        if ([IMAPFolderManager setFolderTypeWithFlags:flags forFolderSetting:newFolderSetting])
            return;
    }
    
    // fallback for gmail Inbox
    if([newFolderSetting isKindOfClass:[GmailLabelSetting class]])
        if(![(GmailLabelSetting*)newFolderSetting labelName])
        {
            if([folderPath isEqualToString:@"INBOX"])
            {
                [(GmailLabelSetting*)newFolderSetting setLabelName:@"\\Inbox"];
                [(GmailLabelSetting*)newFolderSetting setIsSystemLabel:@YES];
            }
            else
                [(GmailLabelSetting*)newFolderSetting setLabelName:folderPath];
        }

    
    //Set the Mynigma folder
//    if([folderPath isEqualToString:@"Mynigma"])
//    {
//        [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:NO]];
//        [newFolderSetting setMynigmaFolderForAccount:newFolderSetting.inIMAPAccount];
//        return;
//    }

    // check if special folder for provider
    if ([IMAPFolderManager checkAndSetSpecialFolderSetting:newFolderSetting])
        return;
    
    //failed, use old method
    NSDictionary* folderDict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FolderNames" ofType:@"plist"]];

    NSString* displayName = newFolderSetting.displayName;
    
    for (NSString* name in folderDict[@"all mail"])
    {
        if([newFolderSetting isKindOfClass:[GmailLabelSetting class]] && [folderPath rangeOfString:name].location!=NSNotFound)
        {
            [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:YES]];
            [(GmailLabelSetting*)newFolderSetting setAllMailForAccount:(GmailAccountSetting*)newFolderSetting.inIMAPAccount];
            return;
        }
    }

    for (NSString* name in folderDict[@"archive"])
    {
        if([[displayName lowercaseString] rangeOfString:name].location!=NSNotFound)
        {
            [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:NO]];
            return;
        }
    }

    for (NSString* name in folderDict[@"inbox"])
    {
        if([[displayName lowercaseString] rangeOfString:name].location!=NSNotFound)
        {
            [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:YES]];
            if ([displayName isEqual:@"INBOX"])
                [newFolderSetting setInboxForAccount:newFolderSetting.inIMAPAccount];
            else if(!newFolderSetting.inIMAPAccount.inboxFolder)
            {
                [newFolderSetting setInboxForAccount:newFolderSetting.inIMAPAccount];
            }
            return;
        }
    }

    for (NSString* name in folderDict[@"spam"])
    {
        if([[displayName lowercaseString] rangeOfString:name].location!=NSNotFound)
        {
            [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:NO]];
            if(!newFolderSetting.inIMAPAccount.spamFolder)
            {
                [newFolderSetting setSpamForAccount:newFolderSetting.inIMAPAccount];
            }
            return;
        }
    }

    for (NSString* name in folderDict[@"bin"])
    {
        if([[displayName lowercaseString] rangeOfString:name].location!=NSNotFound)
        {
            [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:NO]];
            if(!newFolderSetting.inIMAPAccount.binFolder)
                [newFolderSetting setBinForAccount:newFolderSetting.inIMAPAccount];
            return;
        }
    }

    for (NSString* name in folderDict[@"drafts"])
    {
        if([[displayName lowercaseString] rangeOfString:name].location!=NSNotFound)
        {
            [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:NO]];
            if(!newFolderSetting.inIMAPAccount.draftsFolder)
                [newFolderSetting setDraftsForAccount:newFolderSetting.inIMAPAccount];
            return;
        }
    }

    for (NSString* name in folderDict[@"notes"])
    {
        if([[displayName lowercaseString] rangeOfString:name].location!=NSNotFound)
        {
            [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:NO]];
            return;
        }
    }

    for (NSString* name in folderDict[@"sent"])
    {
        //for iCloud should use "Sent messages" folder, so check this before "Sent" folder
        if([[displayName lowercaseString] rangeOfString:name].location!=NSNotFound)
        {
            [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:YES]];
            if(!newFolderSetting.inIMAPAccount.sentFolder)
                [newFolderSetting setSentForAccount:newFolderSetting.inIMAPAccount];
            return;
        }
    }

    [newFolderSetting setIsShownAsStandard:[NSNumber numberWithBool:YES]];
}


+ (void)createFolderSetting:(MCOIMAPFolder*)folder usingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation inAccount:(IMAPAccountSetting*)newAccountSetting withContext:(NSManagedObjectContext*)localContext withPath:(NSString*)path
{
    IMAPFolderSetting* newFolderSetting = nil;
    NSEntityDescription* newEntity = nil;
    if([newAccountSetting isKindOfClass:[GmailAccountSetting class]])
    {
        newEntity = [NSEntityDescription entityForName:@"GmailLabelSetting" inManagedObjectContext:localContext];
        newFolderSetting = [[GmailLabelSetting alloc] initWithEntity:newEntity insertIntoManagedObjectContext:localContext];
    }
    else
    {
        newEntity = [NSEntityDescription entityForName:@"IMAPFolderSetting" inManagedObjectContext:localContext];
        newFolderSetting = [[IMAPFolderSetting alloc] initWithEntity:newEntity insertIntoManagedObjectContext:localContext];
    }

    [newFolderSetting setPath:path];
    [newFolderSetting setUidNext:@1];
    [newFolderSetting setInIMAPAccount:newAccountSetting];

    [self setFolderType:newFolderSetting usingSession:session disconnectOperation:disconnectOperation forMCOIMAPFolder:folder];

    [localContext obtainPermanentIDsForObjects:@[newFolderSetting] error:nil];

    [newAccountSetting addFoldersObject:newFolderSetting];
}

#pragma mark - helper

+ (IMAPFolderSetting*)yieldInboxOrAllMailFolder:(IMAPAccountSetting*)accountSetting
{
    if ([self hasAllMailFolder:accountSetting])
        return [(GmailAccountSetting*)accountSetting allMailFolder];
    else
        return accountSetting.inboxFolder;
}



#pragma mark - All Mail Folder

+ (BOOL)hasAllMailFolder:(IMAPAccountSetting*)accountSetting
{
    return [accountSetting isKindOfClass:[GmailAccountSetting class]] && [(GmailAccountSetting*)accountSetting allMailFolder]!=nil;
}



+ (BOOL)isSpam:(IMAPFolderSetting*)folderSetting
{
    return folderSetting.spamForAccount!=nil;
}

+ (BOOL)isBin:(IMAPFolderSetting*)folderSetting
{
    return folderSetting.binForAccount!=nil;
}

+ (BOOL)isDrafts:(IMAPFolderSetting*)folderSetting
{
    return folderSetting.draftsForAccount!=nil;
}

+ (BOOL)isInbox:(IMAPFolderSetting*)folderSetting
{
    return folderSetting.inboxForAccount!=nil;
}

+ (BOOL)isAllMail:(IMAPFolderSetting*)folderSetting
{
    return folderSetting.allMailForAccount!=nil;
}

+ (BOOL)isSent:(IMAPFolderSetting*)folderSetting
{
    return folderSetting.sentForAccount!=nil;
}

+ (BOOL)isOutbox:(IMAPFolderSetting*)folderSetting
{
    return folderSetting.outboxForAccount!=nil;
}






@end
