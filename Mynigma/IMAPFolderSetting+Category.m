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





#import "IMAPFolderSetting+Category.h"
#import "EmailMessageInstance.h"
#import "GmailAccountSetting.h"
#import "IMAPAccountSetting+Category.h"
#import "GmailLabelSetting.h"
#import "AppDelegate.h"
#import "IMAPAccount.h"
#import "FolderInfoObject.h"


static NSMutableDictionary* folderInfoObjects;


@implementation IMAPFolderSetting (Category)


- (BOOL)isSpam
{
    return self.spamForAccount!=nil;
}

- (BOOL)isBin
{
    return self.binForAccount!=nil;
}

- (BOOL)isInbox
{
    return self.inboxForAccount!=nil;
}

- (BOOL)isAllMail
{
    return self.allMailForAccount!=nil;
}

- (BOOL)isOutbox
{
    return self.outboxForAccount!=nil;
}

- (BOOL)isSent
{
    return self.sentForAccount!=nil;
}

- (BOOL)isDrafts
{
    return self.draftsForAccount!=nil;
}

- (BOOL)isGmailSystemLabel
{
    if([self isKindOfClass:[GmailLabelSetting class]])
    {
        return [[(GmailLabelSetting*)self isSystemLabel] boolValue];
    }

    return NO;
}

- (BOOL)isImportant
{
    if([self isKindOfClass:[GmailLabelSetting class]])
    {
        return [(GmailLabelSetting*)self importantForAccount]!=nil;
    }

    return NO;
}


- (BOOL)isStarred
{
    if([self isKindOfClass:[GmailLabelSetting class]])
    {
        return [(GmailLabelSetting*)self starredForAccount]!=nil;
    }

    return NO;
}

- (IMAPAccountSetting*)accountSetting
{
    if(self.inIMAPAccount)
        return self.inIMAPAccount;
    
    if(self.outboxForAccount)
        return self.outboxForAccount;

    return nil;
}

- (IMAPAccount*)account
{
    return self.accountSetting.account;
}

- (void)checkFolderUserInitiated:(BOOL)userInitiated
{
    if(self.isOutbox)
        return;

    IMAPAccount* account = [self account];
    if(account)
    {
        [account checkFolder:self userInitiated:userInitiated];
    }
}




- (void)setDone
{
    if(self.objectID)
    {
        FolderInfoObject* infoObject = [self folderInfo];
        [infoObject setIsBusy:NO];
    }
}

- (BOOL)isBusy
{
    if(self.objectID)
    {
        FolderInfoObject* infoObject = [self folderInfo];
        return [infoObject isBusy];
    }
    return NO;
}

- (void)setBusy
{
    if(self.objectID)
    {
        FolderInfoObject* infoObject = [self folderInfo];
        [infoObject setIsBusy:YES];
    }
    //    NSIndexPath* indexPathOfLastRow = [NSIndexPath indexPathForRow:filteredMessages.count inSection:0];
    //    UITableView* messagesTable = APPDELEGATE.messagesController.tableView;
    //    [messagesTable beginUpdates];
    //    [messagesTable reloadRowsAtIndexPaths:@[indexPathOfLastRow] withRowAnimation:UITableViewRowAnimationNone];
    //    [messagesTable endUpdates];
}

- (void)setCompletelyLoaded
{
    if(self.objectID)
    {
        FolderInfoObject* infoObject = [self folderInfo];
        [infoObject setCompletelyLoaded:YES];
    }
    //    NSIndexPath* indexPathOfLastRow = [NSIndexPath indexPathForRow:filteredMessages.count inSection:0];
    //    UITableView* messagesTable = APPDELEGATE.messagesController.tableView;
    //    [messagesTable beginUpdates];
    //    [messagesTable reloadRowsAtIndexPaths:@[indexPathOfLastRow] withRowAnimation:UITableViewRowAnimationNone];
    //    [messagesTable endUpdates];
}

- (BOOL)isCompletelyLoaded
{
    if([self isOutbox])
        return YES;

    if(self.objectID)
    {
        FolderInfoObject* infoObject = [self folderInfo];
        return [infoObject completelyLoaded];
    }

    return NO;
}


- (void)successfulBackLoad
{
    FolderInfoObject* infoObject = [self folderInfo];
    infoObject.successfulBackLoads++;

    //    NSIndexPath* indexPathOfLastRow = [NSIndexPath indexPathForRow:filteredMessages.count inSection:0];
    //    UITableView* messagesTable = APPDELEGATE.messagesController.tableView;
    //    [messagesTable beginUpdates];
    //    [messagesTable reloadRowsAtIndexPaths:@[indexPathOfLastRow] withRowAnimation:UITableViewRowAnimationNone];
    //    [messagesTable endUpdates];
}

- (FolderInfoObject*)folderInfo
{
    @synchronized(folderInfoObjects)
    {
        if(!folderInfoObjects)
            folderInfoObjects = [NSMutableDictionary new];

        FolderInfoObject* infoObject = [folderInfoObjects objectForKey:self.objectID];
        if(infoObject)
            return infoObject;
        else
            return [FolderInfoObject new];
    }
}

- (void)unsuccessfulBackLoad
{
    FolderInfoObject* infoObject = [self folderInfo];
    infoObject.unsuccessfulBackLoads++;

    //NSIndexPath* indexPathOfLastRow = [NSIndexPath indexPathForRow:filteredMessages.count inSection:0];
    //UITableView* messagesTable = APPDELEGATE.messagesController.tableView;
    /*[messagesTable beginUpdates];
     [messagesTable reloadRowsAtIndexPaths:@[indexPathOfLastRow] withRowAnimation:UITableViewRowAnimationNone];
     [messagesTable endUpdates];*/
}

- (void)successfulForwardLoad
{
    FolderInfoObject* infoObject = [self folderInfo];
    infoObject.successfulForwardLoads++;
}

- (void)unsuccessfulForwardLoad
{
    FolderInfoObject* infoObject = [self folderInfo];
    infoObject.unsuccessfulForwardLoads++;
}

+ (IMAPFolderSetting*)folderSettingWithObjectID:(NSManagedObjectID*)folderSettingObjectID inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    if(!folderSettingObjectID)
    {
        NSLog(@"Trying to create IMAPFolderSetting with nil object ID!!");
        return nil;
    }

    NSError* error = nil;
    IMAPFolderSetting* localFolderSetting = (IMAPFolderSetting*)[localContext existingObjectWithID:folderSettingObjectID error:&error];
    if(error)
    {
        NSLog(@"Error creating local folder setting!!! %@", error.localizedDescription);
        return nil;
    }

    return localFolderSetting;
}

- (BOOL)isBackwardLoading
{
    return self.folderInfo.isBackwardLoading;
}

- (void)setIsBackwardLoading:(BOOL)isBackwardLoading
{
    [self.folderInfo setIsBackwardLoading:isBackwardLoading];
}

- (BOOL)isCompletelyBackwardLoaded
{
    return (self.downloadedFromNumber != nil) && (self.downloadedFromNumber.integerValue <=1);
}

- (BOOL)isStandardFolder
{
    //All Mail is a standard folder
    if([self isKindOfClass:[GmailLabelSetting class]] && [(GmailLabelSetting*)self allMailForAccount])
        return YES;

    //and so are these
    return (self.inboxForAccount || self.outboxForAccount || self.sentForAccount || self.draftsForAccount || self.spamForAccount || self.binForAccount);
}

@end
