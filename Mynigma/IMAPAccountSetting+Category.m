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





#import "IMAPAccountSetting+Category.h"
#import "GmailAccountSetting.h"
#import "IMAPFolderManager.h"
#import "AppDelegate.h"
#import "UserSettings+Category.h"
#import "IMAPAccount.h"
#import "MynigmaPrivateKey+Category.h"
#import "NSString+EmailAddresses.h"
#import "IMAPFolderSetting+Category.h"
#import "EmailMessageInstance+Category.h"
#import "EmailMessageController.h"
#import "EmailMessage+Category.h"
#import "AccountCreationManager.h"
#import "SelectionAndFilterHelper.h"
#import "CoreDataHelper.h"






@implementation IMAPAccountSetting (Category)

- (IMAPFolderSetting*)allMailOrInboxFolder
{
    if([IMAPFolderManager hasAllMailFolder:self])
        return [(GmailAccountSetting*)self allMailFolder];
    else
        return self.inboxFolder;
}


+ (IMAPAccountSetting*)accountSettingForEmail:(NSString*)email
{
    [ThreadHelper ensureMainThread];

    for(IMAPAccountSetting* accountSetting in [UserSettings currentUserSettings].accounts)
    {
        if([email.lowercaseString isEqual:accountSetting.emailAddress])
        {
            return accountSetting;
        }
    }

    return nil;
}

+ (IMAPAccountSetting*)accountSettingForSenderEmail:(NSString*)email
{
    [ThreadHelper ensureMainThread];

    for(IMAPAccountSetting* accountSetting in [UserSettings currentUserSettings].accounts)
    {
        if([email.canonicalForm isEqual:accountSetting.senderEmail.canonicalForm])
        {
            return accountSetting;
        }
    }

    return nil;
}

+ (IMAPAccountSetting*)accountSettingForAccount:(IMAPAccount*)account inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    NSManagedObjectID* accountObjectID = account.accountSettingID;

    NSError* error = nil;

    IMAPAccountSetting* accountSetting = (IMAPAccountSetting*)[localContext existingObjectWithID:accountObjectID error:&error];

    if(error)
    {
        NSLog(@"Error creating account setting!!! %@", error);
    }

    return accountSetting;
}

- (NSString*)currentPrivateKeyLabel
{
    NSString* email = self.emailAddress;

    return [MynigmaPrivateKey privateKeyLabelForEmailAddress:email];
}

- (IMAPAccount*)account
{
    NSManagedObjectID* accountSettingObjectID = self.objectID;

    for(IMAPAccount* account in [AccountCreationManager sharedInstance].allAccounts)
    {
        if([account.accountSettingID isEqual:accountSettingObjectID])
            return account;
    }

    return nil;
}

- (void)emptyTrash
{
    NSMutableArray* messageInstanceObjectIDs = [NSMutableArray new];

    NSArray* messagesToBeDeleted = [self.binFolder.containsMessages sortedArrayUsingDescriptors:[EmailMessageController sharedInstance].messageInstanceSortDescriptors];

    NSError* error = nil;

    [MAIN_CONTEXT obtainPermanentIDsForObjects:messagesToBeDeleted error:&error];

    if(error)
        NSLog(@"Error obtaining permanent objectIDs for messages while emptying trash!! %@", error);

    for(EmailMessageInstance* messageInstance in messagesToBeDeleted)
    {
        if([messageInstance.message isDeviceMessage])
            [messageInstanceObjectIDs addObject:messageInstance.objectID];
    }

    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

        NSInteger counter = 0;

        for(NSManagedObjectID* messageInstanceObjectID in messageInstanceObjectIDs)
        {
            EmailMessageInstance* messageInstance = [EmailMessageInstance messageInstanceWithObjectID:messageInstanceObjectID inContext:localContext];

            counter++;

            [messageInstance moveToBinOrDelete];

            if(counter%20 == 0)
            {
                [localContext save:nil];

                [CoreDataHelper save];
            }
        }

        [localContext save:nil];

        [CoreDataHelper save];
    }];
}


- (void)removeAccountWithCallback:(void(^)(void))callback
{
    NSManagedObjectID* accountSettingObjectID = self.objectID;

    //mark account as unused
    [self setShouldUse:@NO];
    [AccountCreationManager resetIMAPAccountsFromAccountSettings];

    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext)
     {

         IMAPAccountSetting* localAccountSetting = (IMAPAccountSetting*)[localContext objectWithID:accountSettingObjectID];

         if(!localAccountSetting)
             return;

         [[UserSettings currentUserSettingsInContext:localContext] removeAccountsObject:localAccountSetting];

         if([[UserSettings currentUserSettingsInContext:localContext].preferredAccount isEqual:localAccountSetting])
         {
             [[UserSettings currentUserSettingsInContext:localContext] setPreferredAccount:[UserSettings currentUserSettingsInContext:localContext].accounts.anyObject];
         }

         [localContext deleteObject:localAccountSetting];

         NSError* error = nil;

         [localContext save:&error];

         if(error)
             NSLog(@"Error saving local context after deleting acocunt setting! %@", error);

         [SelectionAndFilterHelper reloadOutlinePreservingSelection];
         [SelectionAndFilterHelper updateFilters];
         
         if(callback)
             callback();
     }];
}

@end
