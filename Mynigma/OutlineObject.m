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





#if TARGET_OS_IPHONE

#else

#import "AccountOrFolderView.h"

#endif


#import "OutlineObject.h"
#import "IMAPAccountSetting.h"
#import "IMAPFolderSetting+Category.h"
#import "Contact+Category.h"
#import "AppDelegate.h"
#import "UserSettings+Category.h"
#import "GmailAccountSetting.h"
#import "GmailLabelSetting.h"
#import "IMAPAccountSetting+Category.h"
#import "IMAPFolderManager.h"
#import "SelectionAndFilterHelper.h"



@implementation OutlineObject


@synthesize sortDate;
@synthesize showSeparator;

@synthesize isEmpty;


@synthesize sortName;
@synthesize sortSection;

@synthesize isStandard;
@synthesize type;

@synthesize folderSetting;
@synthesize accountSetting;
@synthesize contact;

@synthesize greenBoxConstraint;
@synthesize missingImageConstraint;
@synthesize unreadCountConstraint;
@synthesize identifier;


#pragma mark - init methods

- (id)initAsButtonInSection:(NSNumber*)newSection identifier:(NSObject*)newIdentifier title:(NSString*)buttonTitle
{
    self = [super init];
    if (self) {
        [self setIdentifier:newIdentifier];

        [self setButtonTitle:buttonTitle];

        [self setSortSection:newSection];
        [self setIsEmpty:YES];
        [self setIsStandard:NO];
    }
    return self;
}


- (id)initAsEmptyInSection:(NSNumber*)newSection identifier:(NSObject*)newIdentifier separator:(BOOL)newShowSeparator
{
    self = [super init];
    if (self) {
        [self setIdentifier:newIdentifier];

        [self setSortSection:newSection];
        [self setIsEmpty:YES];
        [self setShowSeparator:newShowSeparator];
        [self setIsStandard:NO];
    }
    return self;
}


- (id)initAsStandardWithType:(NSInteger)newType
{
    self = [super init];
    if (self) {
        [self setIdentifier:@(newType)];

        [self setIsEmpty:NO];
        [self setIsStandard:YES];
        [self setType:newType];
        [self setSortSection:[self lookUpSortSection]];
        [self configureAsEmpty];
    }
    return self;
}


- (id)initAsAccount:(IMAPAccountSetting*)newAccountSetting
{
    self = [super init];
    if (self) {
        [self setIdentifier:newAccountSetting];

        [self setAccountSetting:newAccountSetting];
        [self setIsEmpty:NO];
        [self setIsStandard:NO];
        [self setSortSection:[self lookUpSortSection]];
        [self configureAsAccount];
    }
    return self;
}

- (id)initAsContact:(Contact*)newContact
{
    self = [super init];
    if (self) {
        [self setIdentifier:newContact];

        [self setContact:newContact];
        [self setIsStandard:NO];
        [self setIsEmpty:NO];
        [self setSortSection:[self lookUpSortSection]];
        [self setSortName:[newContact displayName]];
        [self configureAsContact];
    }
    return self;
}


- (id)initAsRecentContact:(Contact*)newContact
{
    self = [super init];
    if (self) {
        [self setIdentifier:newContact];

        [self setContact:newContact];
        [self setIsStandard:NO];
        [self setIsEmpty:NO];
        [self setSortSection:[self lookUpSortSection]];
        [self setSortDate:[newContact.dateLastContacted copy]];
        [self configureAsContact];
    }
    return self;
}

- (id)initAsFolder:(IMAPFolderSetting*)folderSett
{
    self = [super init];
    if (self) {
        [self setIdentifier:folderSett];

        [self setFolderSetting:folderSett];
        [self setIsStandard:NO];
        [self setIsEmpty:NO];

        type = -1;

        if([folderSett isKindOfClass:[GmailLabelSetting class]])
            if(folderSett.allMailForAccount)
                type = STANDARD_ALL_FOLDERS;
        if(folderSett.inboxForAccount)
            type = STANDARD_INBOX;
        if(folderSett.outboxForAccount)
            type = STANDARD_OUTBOX;
        if(folderSett.sentForAccount)
            type = STANDARD_SENT;
        if(folderSett.draftsForAccount)
            type = STANDARD_DRAFTS;
        if(folderSett.spamForAccount)
            type = STANDARD_SPAM;
        if(folderSett.binForAccount)
            type = STANDARD_BIN;
        if(type!=-1)
            [self setIsStandard:YES];
        [self setSortSection:[self lookUpSortSection]];

        [self configureAsFolder];
    }
    return self;
}



#pragma mark - refresh method


//updates the data displayed (such as unread count etc.)
- (void)refresh
{
    if(isStandard)
    {
        [self configureAsStandard];
    }
    else if(self.accountSetting)
    {
        [self configureAsAccount];
    }
    else if(self.folderSetting)
    {
        [self configureAsFolder];
    }
}

- (IMAGE*)displayImage
{
    switch(type)
    {
        case STANDARD_ALL_CONTACTS:
        case STANDARD_RECENT_CONTACTS:
        case STANDARD_ALL_FOLDERS:
            return nil;
        case STANDARD_INBOX:
            return [IMAGE imageNamed:@"inbox64px.png"];
        case STANDARD_OUTBOX:
            return [IMAGE imageNamed:@"outbox64try1.png"];
        case STANDARD_SENT:
            return [IMAGE imageNamed:@"send64px.png"];
        case STANDARD_DRAFTS:
            return [IMAGE imageNamed:@"drafts64px.png"];
        case STANDARD_BIN:
            return [IMAGE imageNamed:@"trash64.png"];
        case STANDARD_SPAM:
            return [IMAGE imageNamed:@"spam64.png"];
        case STANDARD_LOCAL_ARCHIVE:
            return [IMAGE imageNamed:@"archive64px.png"];
        default:
            if(self.folderSetting)
#if TARGET_OS_IPHONE
                return [IMAGE imageNamed:@"folder22in32.png"];
#else
                return [IMAGE imageNamed:@"folderWhite32.png"];
#endif
            if(self.contact)
                return  [self.contact profilePic];
            return nil;
    }
}

- (NSString*)displayName
{
    switch(type)
    {
        case STANDARD_ALL_ACCOUNTS:
            return NSLocalizedString(@"All accounts", nil);
        case STANDARD_ALL_CONTACTS:
            return NSLocalizedString(@"All contacts", nil);
        case STANDARD_RECENT_CONTACTS:
            return NSLocalizedString(@"Recent contacts", nil);
        case STANDARD_ALL_FOLDERS:
            return NSLocalizedString(@"All folders", nil);
        case STANDARD_INBOX:
            return NSLocalizedString(@"Inbox", nil);
        case STANDARD_OUTBOX:
            return NSLocalizedString(@"Outbox", nil);
        case STANDARD_SENT:
            return NSLocalizedString(@"Sent", nil);
        case STANDARD_DRAFTS:
            return NSLocalizedString(@"Drafts", nil);
        case STANDARD_BIN:
            return NSLocalizedString(@"Trash", nil);
        case STANDARD_SPAM:
            return NSLocalizedString(@"Spam", nil);
        case STANDARD_LOCAL_ARCHIVE:
            return NSLocalizedString(@"Local backup", nil);
        default:
            if(self.folderSetting)
                return [self.folderSetting displayName]?[self.folderSetting displayName]:@"";
            if(self.accountSetting)
                return [self.accountSetting displayName]?[self.accountSetting displayName]:@"";
            if(self.contact)
                return [self.contact displayName];
            return @"";
    }
}

- (BOOL)isSafe
{
    if(self.contact)
        return [self.contact isSafe];
    return NO;
}

- (BOOL)isButton
{
    return self.buttonTitle!=nil;
}

#if TARGET_OS_IPHONE

#else

- (void)configureCellView:(AccountOrFolderView*)cellView
{
    if(self.contact)
    {
        CALayer* layer = cellView.imageView.layer;
        NSImage* profilePic = [self displayImage];

        //for(EmailContactDetail* contactDetail in self.contact.emailAddresses


        [cellView.imageView setImage:profilePic];
        if(profilePic)
        {
            [layer setShadowRadius:0];

            [layer setCornerRadius:16];
            [layer setBorderColor:[NSColor colorWithDeviceRed:1 green:1 blue:1 alpha:.7].CGColor];
            [layer setBorderWidth:1];
            [layer setMasksToBounds:YES];

            [cellView.indentationConstraint setConstant:20];

            cellView.imageConstraint.priority = 1;
        }
        else
        {
            [layer setBorderWidth:0];
            cellView.imageConstraint.priority = 999;
        }
        NSString* displayName = [self.contact displayName];
        [cellView.textField setStringValue:displayName?displayName:@""];
        [cellView.statusLabel setStringValue:@""];
        if([self isSafe])
            cellView.safeConstraint.constant = 16;
        else
            cellView.safeConstraint.constant = 0;
    }
    else
    {
        NSImage* pic = [self displayImage];
        [cellView.imageView setImage:pic];
        if(pic)
            [cellView.imageConstraint setPriority:1];
        else
            [cellView.imageConstraint setPriority:999];

        [cellView.textField setStringValue:[self displayName]];

        if(self.indentationLevel)
            [cellView.indentationConstraint setConstant:20 + 20*self.indentationLevel.integerValue];
        else
            [cellView.indentationConstraint setConstant:20];

        NSInteger unreadCount = [self unreadCount];
        if(unreadCount==0)
            [cellView.statusLabel setStringValue:@""];
        else
            [cellView.statusLabel setStringValue:[NSString stringWithFormat:@"%ld", unreadCount]];
    }
}

#endif

#pragma mark - configuration methods


- (void)configureAsEmpty
{
}


- (void)configureAsStandard
{
    [self setShowSeparator:NO];
}

- (void)configureAsAccount
{
    [self setShowSeparator:NO];
}

- (void)configureAsFolder
{
    [self setShowSeparator:NO];
}

- (void)configureAsContact
{
    [self setShowSeparator:NO];
}


- (BOOL)isEqual:(OutlineObject*)object
{
    if(![object isKindOfClass:[OutlineObject class]])
        return NO;

    if(object.sortDate)
    {
        if(![object.sortDate isEqual:self.sortDate])
            return NO;
    }
    if(self.sortDate)
        return NO;

    return [object.identifier isEqual:self.identifier];
}

- (NSUInteger)hash
{
    return [identifier hash] + [sortDate hash];
}

- (NSNumber*)lookUpSortSection
{
    if(accountSetting)
        return @3;

    if(folderSetting)
        return @12;

    if(contact)
        return @5;

    switch(type)
    {
        case STANDARD_ALL_ACCOUNTS:
            return @2;
        case STANDARD_ALL_FOLDERS:
            return @5;
        case STANDARD_INBOX:
            return @6;
        case STANDARD_OUTBOX:
            return @7;
        case STANDARD_SENT:
            return @8;
        case STANDARD_DRAFTS:
            return @9;
        case STANDARD_BIN:
            return @10;
        case STANDARD_SPAM:
            return @11;
        case STANDARD_ALL_CONTACTS:
            return @2;
        case STANDARD_RECENT_CONTACTS:
            return @3;
        case STANDARD_LOCAL_ARCHIVE:
            return @14;

    }

    NSLog(@"No sort section found, returning 20! %@", self);
    return @20;
}


- (BOOL)isAccount
{
    if(self.accountSetting)
        return YES;
    if(type==STANDARD_ALL_ACCOUNTS)
        return YES;
    return NO;
}

- (BOOL)isContactsOption
{
    if(type==STANDARD_ALL_CONTACTS || type==STANDARD_RECENT_CONTACTS)
        return YES;
    return NO;
}

- (BOOL)isContact
{
    if(self.contact)
        return YES;
    return NO;
}

- (BOOL)isFolder
{
    if(self.folderSetting)
        return YES;
    if(type==STANDARD_ALL_FOLDERS || type==STANDARD_BIN || type==STANDARD_DRAFTS || type==STANDARD_INBOX || type==STANDARD_OUTBOX || type==STANDARD_SENT || type==STANDARD_SPAM)
        return YES;
    return NO;
}

- (BOOL)isLocalArchive
{
    return type==STANDARD_LOCAL_ARCHIVE;
}

- (BOOL)isOutbox
{
    if(type == STANDARD_OUTBOX)
        return YES;

    return NO;
}

- (NSSet*)associatedFoldersForAccountSettings:(NSSet*)accounts
{
    if(![self isFolder])
        return [NSSet set];

    if(!isStandard)
    {
        if(folderSetting)
            return [NSSet setWithObject:folderSetting];
        else
            return [NSSet set];
    }

    if(type==STANDARD_ALL_FOLDERS)
    {
        NSMutableSet* newSet = [NSMutableSet new];
        for(IMAPAccountSetting* accountSett in accounts)
        {
            if([accountSett isKindOfClass:[GmailAccountSetting class]] && [(GmailAccountSetting*)accountSett allMailFolder])
            {
                [newSet addObject:[(GmailAccountSetting*)accountSett allMailFolder]];
            }
            else
            {
                for(IMAPFolderSetting* folderSett in accountSett.folders)
                {
                    if(folderSett.isShownAsStandard.boolValue)
                        [newSet addObject:folderSett];
                }
            }
        }
        return newSet;
    }


    NSMutableSet* newSet = [NSMutableSet new];
    for(IMAPAccountSetting* accountSett in accounts)
    {
        NSString* folderKey = [self folderKey];
        if(folderKey.length>0)
        {
            //if([accountSetting respondsToSelector:@selector(folderKey)])
            {
                IMAPFolderSetting* folder = [accountSett valueForKey:folderKey];
                if(folder)
                    [newSet addObject:folder];
                //else
                //  NSLog(@"No folder for key %@ in account %@", folderKey, accountSetting);
            }
        }
        else if(folderSetting)
        {
            [newSet addObject:folderSetting];
        }
    }
    return newSet;
}


- (NSString*)folderKey
{
    switch(type)
    {
        case STANDARD_ALL_FOLDERS:
            return @"allMailFolder";
        case STANDARD_INBOX:
            return @"inboxFolder";
        case STANDARD_OUTBOX:
            return @"outboxFolder";
        case STANDARD_SENT:
            return @"sentFolder";
        case STANDARD_DRAFTS:
            return @"draftsFolder";
        case STANDARD_BIN:
            return @"binFolder";
        case STANDARD_SPAM:
            return @"spamFolder";
        default:
            return @"";
    }
}


- (NSSet*)accountSettings
{
    if(accountSetting)
    {
        if(accountSetting.shouldUse.boolValue)
            return [NSSet setWithObject:accountSetting];
    }
    else
    {
        NSMutableSet* returnValue = [NSMutableSet new];

        for(IMAPAccountSetting* accountSett in [UserSettings usedAccounts])
        {
            if(accountSett.shouldUse.boolValue)
                [returnValue addObject:accountSett];
        }

        return returnValue;
    }

    return [NSSet set];
}


- (NSInteger)unreadCount
{
    if([self isFolder])
    {
        if(!isStandard)
    {
        if(folderSetting && !folderSetting.spamForAccount)
        {
            if(folderSetting.outboxForAccount)
                return folderSetting.containsMessages.count;
            else
                return folderSetting.unreadMessages.count;
        }
        else
            return 0;
    }
    else
    {
        NSInteger unreadCount = 0;

        NSSet* accountSettings = [[SelectionAndFilterHelper sharedInstance].topSelection accountSettings];

        NSSet* folderSettings = [self associatedFoldersForAccountSettings:accountSettings];
        for(IMAPFolderSetting* folderSett in folderSettings)
            if(!folderSett.spamForAccount)
            {
                if(folderSett.outboxForAccount)
                {
                    unreadCount += folderSett.containsMessages.count;
                }
                else
                {
                    if([folderSett isKindOfClass:[GmailLabelSetting class]])
                    {
                        if(folderSett.allMailForAccount)
                            unreadCount += folderSett.unreadMessages.count;
                        else
                            unreadCount += [(GmailLabelSetting*)folderSett attachedToUnreadMessages].count;
                    }
                    else
                        unreadCount += folderSett.unreadMessages.count;
                }
            }

        return unreadCount;
    }
    }
    if([self isAccount])
    {
        NSInteger unreadCount = 0;
        if(type==STANDARD_ALL_ACCOUNTS)
        {
            for(IMAPAccountSetting* accountSett in [UserSettings usedAccounts])
            {

                if([accountSett isKindOfClass:[GmailAccountSetting class]])
                {
                    if([(GmailAccountSetting*)accountSett allMailFolder])
                        unreadCount += [(GmailAccountSetting*)accountSett allMailFolder].unreadMessages.count;
                }
                else
                {
                    for(IMAPFolderSetting* folderSett in accountSett.folders)
                        if(folderSett.isShownAsStandard.boolValue)
                        {
                            unreadCount += folderSett.unreadMessages.count;
                        }
                }
            }
            return unreadCount;
        }
        else
        {
            if(!accountSetting)
                return 0;

            if([accountSetting isKindOfClass:[GmailAccountSetting class]])
            {
                if([(GmailAccountSetting*)accountSetting allMailFolder])
                    return [(GmailAccountSetting*)accountSetting allMailFolder].unreadMessages.count;
            }

            for(IMAPFolderSetting* folderSett in accountSetting.folders)
                if(folderSett.isShownAsStandard.boolValue)
                {
                    unreadCount += folderSett.unreadMessages.count;
                }
            
            return unreadCount;
        }
    }
    return 0;
}

- (NSString*)description
{
    NSMutableString* newString = [NSMutableString new];

    if([identifier isKindOfClass:[Contact class]])
        [newString appendFormat:@"Outline object: %@\n", [(Contact*)identifier displayName]];
    if([identifier isKindOfClass:[IMAPAccountSetting class]])
        [newString appendFormat:@"Outline object: %@\n", [(IMAPAccountSetting*)identifier displayName]];
    if([identifier isKindOfClass:[IMAPFolderSetting class]])
        [newString appendFormat:@"Outline object: %@\n", [(IMAPFolderSetting*)identifier displayName]];
    if(isStandard)
        [newString appendFormat:@"Outline object: %ld", (long)type];
    if(newString.length==0)
        [newString appendString:@"Outline object: empty"];
    //[newString appendFormat:@"OutlineObject:\nsort section: %@\nis standard: %@\ntype: %ld\nkey: %@\naccount setting: %@\nfolder setting: %@\ncontact: %@\n", sortSection, isStandard?@"YES":@"NO", type, [self folderKey], [accountSetting displayName], [folderSetting displayName], [MODEL nameOfContact:contact]];

    return newString;

}

- (NSData*)dataForDragAndDrop
{
    if([self isFolder])
    {
        if([self isStandard])
        {
            Byte typeByte = self.type;
            return [NSData dataWithBytes:&typeByte length:1];
        }
        else
        {
            NSManagedObjectID* objectID = self.folderSetting.objectID;

            NSURL* uriRep = [objectID URIRepresentation];

            NSData* serializedURI = [NSKeyedArchiver archivedDataWithRootObject:uriRep];

            return serializedURI;
        }
    }
    return nil;
}

+ (OutlineObject*)objectFromDragAndDropData:(NSData*)data
{
    if(data.length==1)
    {
        Byte dataByte = (Byte)data.bytes;
        return [[OutlineObject alloc] initAsStandardWithType:dataByte];
    }
    NSURL* url = [NSKeyedUnarchiver unarchiveObjectWithData:data];

    NSManagedObjectID* objectID = [[CoreDataHelper sharedInstance].persistentStoreCoordinator managedObjectIDForURIRepresentation:url];

    if(objectID)
    {
        IMAPFolderSetting* folderSetting = (IMAPFolderSetting*)[MAIN_CONTEXT existingObjectWithID:objectID error:nil];

        return [[OutlineObject alloc] initAsFolder:folderSetting];
    }
    return nil;
}

+ (NSSet*)selectedFolderSettingsForSyncing
{
    OutlineObject* accountSelection = [SelectionAndFilterHelper sharedInstance].topSelection;

    OutlineObject* foldersSelection = [SelectionAndFilterHelper sharedInstance].bottomSelection;

#if TARGET_OS_IPHONE

#else

    if([SelectionAndFilterHelper sharedInstance].showContacts)
    {
        accountSelection = [[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_ACCOUNTS];

        foldersSelection = [[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_FOLDERS];
    }

#endif
    
    NSSet* accountSettings = [accountSelection accountSettings];
    NSSet* folderSettingsToBeChecked = [foldersSelection associatedFoldersForAccountSettings:accountSettings];
    
    NSMutableSet* returnValue = [NSMutableSet new];

    for(IMAPFolderSetting* folderSetting in folderSettingsToBeChecked)
    {
        if(!folderSetting.inIMAPAccount.shouldUse.boolValue)
            continue;

        if([IMAPFolderManager hasAllMailFolder:folderSetting.accountSetting])
        {
            if([folderSetting isSpam] || [folderSetting isBin])
            {
                //the spam and bin folders actually need to be checked
                [returnValue addObject:folderSetting];
            }
            else
            {
                //for all others just check the All Mail folder
                IMAPFolderSetting* allMailFolder = folderSetting.accountSetting.allMailOrInboxFolder;
                [returnValue addObject:allMailFolder];
            }
        }
        else
        {
            if(![folderSetting isOutbox])// && ![folderSetting isDrafts])
                [returnValue addObject:folderSetting];
        }
    }

    return returnValue;
}

+ (NSSet*)selectedFolderSettingsForFiltering
{
    NSSet* accountSettings = [[SelectionAndFilterHelper sharedInstance].topSelection accountSettings];

    NSMutableSet* usedAccountSettings = [NSMutableSet new];

    for(IMAPAccountSetting* accountSetting in accountSettings)
    {
        if(accountSetting.shouldUse.boolValue)
            [usedAccountSettings addObject:accountSetting];
    }

    return [[SelectionAndFilterHelper sharedInstance].bottomSelection associatedFoldersForAccountSettings:usedAccountSettings];
}


@end
