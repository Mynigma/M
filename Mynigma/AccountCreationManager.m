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
#import "AccountCreationManager.h"
#import "IMAPAccount.h"
#import "IMAPAccountSetting.h"
#import <MailCore/MailCore.h>
#import "KeychainHelper.h"
#import "IdleHelper.h"
#import "GmailAccountSetting.h"
#import "ConnectionItem.h"
#import "EncryptionHelper.h"
#import "AccountCheckManager.h"
#import "EncryptionHelper.h"
#import "GmailLabelSetting.h"
#import "NSString+EmailAddresses.h"
#import "NSData+Base64.h"
#import "FileAttachment+Category.h"
#import "SelectionAndFilterHelper.h"
#import "AlertHelper.h"
#import "UserSettings+Category.h"
#import "OAuthHelper.h"


#if ULTIMATE

#import "EmailFooter.h"
#import "CustomerManager.h"
#import "ServerHelper.h"

#endif


@implementation AccountCreationManager



+ (instancetype)sharedInstance
{
    static dispatch_once_t p = 0;

    __strong static id sharedObject = nil;

    dispatch_once(&p, ^{
        sharedObject = [self new];
    });

    return sharedObject;
}



+ (BOOL)haveAccountForEmail:(NSString*)emailAddress
{
    for(IMAPAccount* account in [AccountCreationManager sharedInstance].allAccounts)
    {
        if([account.emailAddress.canonicalForm isEqual:emailAddress.canonicalForm])
            return YES;
    }

    return NO;
}

+ (IMAPAccount*)accountForEmail:(NSString*)emailAddress
{
    for(IMAPAccount* account in [AccountCreationManager sharedInstance].allAccounts)
    {
        if([account.emailAddress.canonicalForm isEqual:emailAddress.canonicalForm])
            return account;
    }
    
    return nil;
}

+ (void)fillIMAPAccount:(IMAPAccount*)newAccount withAccountSetting:(IMAPAccountSetting*)accountSetting
{

    if(!newAccount)
    {
        newAccount = [IMAPAccount new];
        [newAccount setAccountSetting:accountSetting];
        [newAccount setAccountSettingID:accountSetting.objectID];

        MCOIMAPSession* imapSession = [MCOIMAPSession new];
        [newAccount setQuickAccessSession:imapSession];

        MCOSMTPSession* smtpSession = [MCOSMTPSession new];
        [newAccount setSmtpSession:smtpSession];

        newAccount.idleHelperInbox = [[IdleHelper alloc] initWithIMAPAccount:newAccount];
        newAccount.idleHelperSpam = [[IdleHelper alloc] initWithIMAPAccount:newAccount];

        [EncryptionHelper ensureValidCurrentKeyPairForAccount:accountSetting withCallback:^(BOOL success){ }];
    }


    [newAccount setEmailAddress:accountSetting.emailAddress];

    [newAccount.quickAccessSession setAuthType:accountSetting.incomingAuthType.intValue];
    [newAccount.quickAccessSession setConnectionType:accountSetting.incomingEncryption.intValue];
    [newAccount.quickAccessSession setUsername:accountSetting.incomingUserName];
    [newAccount.quickAccessSession setPort:(accountSetting.incomingPort.unsignedIntValue>0?accountSetting.incomingPort.unsignedIntValue:993)];
    [newAccount.quickAccessSession setHostname:accountSetting.incomingServer];
    
    if (accountSetting.incomingAuthType.intValue == MCOAuthTypeXOAuth2 || accountSetting.incomingAuthType.intValue == MCOAuthTypeXOAuth2Outlook)
    {
        // can't set token, fetch is async
        // accessToken is set before the first account check
    }
    else
    {
        NSString* pwd = [KeychainHelper findPasswordForAccount:accountSetting.objectID incoming:YES];
        [newAccount.quickAccessSession setPassword:pwd];
    }

    [newAccount.quickAccessSession setMaximumConnections:3];

    //   if([accountSetting isKindOfClass:[GmailAccountSetting class]])
    [newAccount.quickAccessSession setAllowsFolderConcurrentAccessEnabled:YES];
    //   else
    //     [imapSession setAllowsFolderConcurrentAccessEnabled:NO];


    //[newAccount setMainSession:[[IMAPSessionHelper alloc] initWithSession:newAccount.imapSession]];

    //if ([newAccount.accountSetting.emailAddress isEqual:@"w.schuettelspeer@yahoo.de"]) {
    //    [newAccount.mainSession logConnections:YES];
    //}


    [newAccount.smtpSession setAuthType:accountSetting.outgoingAuthType.intValue];
    [newAccount.smtpSession setConnectionType:accountSetting.outgoingEncryption.intValue];
    [newAccount.smtpSession setUsername:accountSetting.outgoingUserName];
    [newAccount.smtpSession setPort:(accountSetting.outgoingPort.unsignedIntValue>0?accountSetting.outgoingPort.unsignedIntValue:465)];
    [newAccount.smtpSession setHostname:accountSetting.outgoingServer];
    
    if (accountSetting.incomingAuthType.intValue == MCOAuthTypeXOAuth2 || accountSetting.incomingAuthType.intValue == MCOAuthTypeXOAuth2Outlook)
    {
        // can't set token, fetch is async
        // accessToken is set before the first account check
    }
    else
    {
        NSString* pwd2 = [KeychainHelper findPasswordForAccount:accountSetting.objectID incoming:NO];
        [newAccount.smtpSession setPassword:pwd2];
    }
}

+ (IMAPAccount*)createFromLoadedAccountSetting:(IMAPAccountSetting*)accountSetting
{
    IMAPAccount* newAccount = [IMAPAccount new];
    [newAccount setAccountSetting:accountSetting];
    [newAccount setAccountSettingID:accountSetting.objectID];

    MCOIMAPSession* imapSession = [MCOIMAPSession new];
    [newAccount setQuickAccessSession:imapSession];

    MCOSMTPSession* smtpSession = [MCOSMTPSession new];
    [newAccount setSmtpSession:smtpSession];

    newAccount.idleHelperInbox = [[IdleHelper alloc] initWithIMAPAccount:newAccount];
    newAccount.idleHelperSpam = [[IdleHelper alloc] initWithIMAPAccount:newAccount];

    [EncryptionHelper ensureValidCurrentKeyPairForAccount:accountSetting withCallback:^(BOOL success){ }];

    [AccountCreationManager fillIMAPAccount:newAccount withAccountSetting:accountSetting];

    return newAccount;
}

+ (BOOL)tryToFindProviderDetailsWithEmail:(NSString*)email forAccount:(IMAPAccount*)imapAccount
{
    MCOMailProvider *accountProvider = [MCOMailProvidersManager.sharedManager providerForEmail:email];

    if (!accountProvider) {
        //NSLog(@"No provider available for email: %@", email);
        return NO;
    }

    NSArray *imapServices = accountProvider.imapServices;
    if (imapServices.count != 0)
    {
        MCONetService *imapService = [imapServices objectAtIndex:0];
        [imapAccount.quickAccessSession setHostname:imapService.hostname];
        [imapAccount.quickAccessSession setPort:imapService.port];
        switch(imapService.connectionType)
        {
            case MCOConnectionTypeClear: [imapAccount.quickAccessSession setConnectionType:MCOConnectionTypeClear];
                break;
            case MCOConnectionTypeStartTLS: [imapAccount.quickAccessSession setConnectionType:MCOConnectionTypeStartTLS];
                break;
            case MCOConnectionTypeTLS: [imapAccount.quickAccessSession setConnectionType:MCOConnectionTypeTLS];
                break;
        }
    }

    NSArray* smtpServices = accountProvider.smtpServices;
    if (smtpServices.count != 0)
    {
        MCONetService *smtpService = [smtpServices objectAtIndex:0];
        [imapAccount.smtpSession setHostname:smtpService.hostname];
        [imapAccount.smtpSession setPort:smtpService.port];
        switch(smtpService.connectionType)
        {
            case MCOConnectionTypeClear: [imapAccount.smtpSession setConnectionType:MCOConnectionTypeClear];
                break;
            case MCOConnectionTypeStartTLS: [imapAccount.smtpSession setConnectionType:MCOConnectionTypeStartTLS];
                //[imapAccount.smtpSession setAuthType:MCOAuthTypeSASLLogin];
                break;
            case MCOConnectionTypeTLS: [imapAccount.smtpSession setConnectionType:MCOConnectionTypeTLS];
                break;
        }
    }

    return YES;
}



+ (IMAPAccount*)temporaryAccountWithEmail:(NSString*)email
{
    NSArray* emailComponents = [email componentsSeparatedByString:@"@"];

    NSString* incomingServer = [NSString stringWithFormat:@"imap.%@",[emailComponents objectAtIndex:1]];
    NSString* outgoingServer = [NSString stringWithFormat:@"smtp.%@",[emailComponents objectAtIndex:1]];

    IMAPAccount* newAccount = [IMAPAccount new];

    MCOIMAPSession* imapSession = [MCOIMAPSession new];

    [newAccount setQuickAccessSession:imapSession];

    [imapSession setAuthType:MCOAuthTypeSASLPlain|MCOAuthTypeSASLLogin];
    [imapSession setConnectionType:MCOConnectionTypeTLS];
    [imapSession setUsername:email];
    [imapSession setPort:993];
    [imapSession setHostname:incomingServer];

    [imapSession setMaximumConnections:3];

    //if([@[@"gmail.com",@"googlemail.com"] containsObject:[emailComponents objectAtIndex:1]])
    [imapSession setAllowsFolderConcurrentAccessEnabled:YES];
    //else
    //    [imapSession setAllowsFolderConcurrentAccessEnabled:NO];


    //[newAccount setMainSession:[[IMAPSessionHelper alloc] initWithSession:imapSession]];

    newAccount.idleHelperSpam = [[IdleHelper alloc] initWithIMAPAccount:newAccount];
    newAccount.idleHelperInbox = [[IdleHelper alloc] initWithIMAPAccount:newAccount];


    MCOSMTPSession* smtpSession = [MCOSMTPSession new];
    [newAccount setSmtpSession:smtpSession];
    [smtpSession setAuthType:MCOAuthTypeSASLPlain|MCOAuthTypeSASLLogin];
    [smtpSession setConnectionType:MCOConnectionTypeTLS];
    [smtpSession setUsername:email];
    [smtpSession setPort:465];
    [smtpSession setHostname:outgoingServer];
    //[smtpSession setPassword:password];

    [newAccount setEmailAddress:[email lowercaseString]];

    [AccountCreationManager tryToFindProviderDetailsWithEmail:email forAccount:newAccount];

    return newAccount;
}


+ (void)makeAccountPermanent:(IMAPAccount*)account
{
    if(!account)
        return;

    IMAPAccountSetting* newAccountSetting;

    NSString* email = [account.emailAddress lowercaseString];

    NSArray* emailComponents = [email componentsSeparatedByString:@"@"];

    //gmail accounts get a "GmailAccountSetting", mostly to be able to set labels etc.
    if([@[@"gmail.com",@"googlemail.com",@"gmail.de",@"googlemail.de"] containsObject:[emailComponents objectAtIndex:1]])
    {
        NSEntityDescription* entity = [NSEntityDescription entityForName:@"GmailAccountSetting" inManagedObjectContext:MAIN_CONTEXT];
        newAccountSetting = [[GmailAccountSetting alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];
        [MAIN_CONTEXT obtainPermanentIDsForObjects:@[newAccountSetting] error:nil];
        [newAccountSetting setSentMessagesCopiedIntoSentFolder:[NSNumber numberWithBool:NO]];
    }
    else
    {
        NSEntityDescription* entity = [NSEntityDescription entityForName:@"IMAPAccountSetting" inManagedObjectContext:MAIN_CONTEXT];
        newAccountSetting = [[IMAPAccountSetting alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];
        [MAIN_CONTEXT obtainPermanentIDsForObjects:@[newAccountSetting] error:nil];
        [newAccountSetting setSentMessagesCopiedIntoSentFolder:[NSNumber numberWithBool:YES]];
    }

    [newAccountSetting setDisplayName:[AccountCreationManager displayNameForEmail:account.emailAddress]];

    //account will be verified once a token has been received and sent back to the server. until then it's unverified
    [newAccountSetting setHasBeenVerified:[NSNumber numberWithBool:NO]];
    [newAccountSetting setEmailAddress:email];
    [newAccountSetting setIncomingServer:account.quickAccessSession.hostname.lowercaseString];
    [newAccountSetting setOutgoingServer:account.smtpSession.hostname.lowercaseString];

    //if(!IS_IN_TESTING_MODE)
    {
        //add this account setting to the current user's list
        [[UserSettings currentUserSettings] addAccountsObject:newAccountSetting];

        NSMutableArray* newAccountArray = [NSMutableArray arrayWithArray:[AccountCreationManager sharedInstance].allAccounts?[AccountCreationManager sharedInstance].allAccounts:@[]];
        [newAccountArray addObject:account];
        [[AccountCreationManager sharedInstance] setAllAccounts:newAccountArray];

        if(![NSString usersAddresses])
            [NSString setUsersAddresses:@[]];

        NSString* canonicalAddress = account.emailAddress.canonicalForm;

        if(canonicalAddress.length)
            [NSString setUsersAddresses:[[NSString usersAddresses] arrayByAddingObject:canonicalAddress]];

        if(![[UserSettings currentUserSettings] preferredAccount])
            [[UserSettings currentUserSettings] setPreferredAccount:newAccountSetting];

        if(account.quickAccessSession.authType != MCOAuthTypeXOAuth2 && account.quickAccessSession.authType != MCOAuthTypeXOAuth2Outlook)
        {
            [KeychainHelper savePassword:account.quickAccessSession.password forAccount:newAccountSetting.objectID incoming:YES];
            [KeychainHelper savePassword:account.smtpSession.password forAccount:newAccountSetting.objectID incoming:NO];
        }
    }

    //set appropriate values for the account setting
    [newAccountSetting setIncomingUserName:account.quickAccessSession.username];
    [newAccountSetting setOutgoingUserName:account.smtpSession.username];
    [newAccountSetting setOutgoingEmail:email];
    [newAccountSetting setIncomingPort:[NSNumber numberWithInteger:account.quickAccessSession.port]];
    [newAccountSetting setIncomingEncryption:[NSNumber numberWithInteger:account.quickAccessSession.connectionType]];
    [newAccountSetting setOutgoingPort:[NSNumber numberWithInteger:account.smtpSession.port]];
    [newAccountSetting setOutgoingEncryption:[NSNumber numberWithInteger:account.smtpSession.connectionType]];
    [newAccountSetting setHasRequestedWelcomeMessage:[NSNumber numberWithBool:NO]];
    [newAccountSetting setSenderEmail:email];
    [newAccountSetting setSenderName:NSFullUserName()];
    [newAccountSetting setHasBeenVerified:[NSNumber numberWithBool:NO]];
    [newAccountSetting setIncomingAuthType:[NSNumber numberWithInt:account.quickAccessSession.authType]];
    [newAccountSetting setOutgoingAuthType:[NSNumber numberWithInt:account.smtpSession.authType]];

    //if(![newAccountSetting isKindOfClass:[GmailAccountSetting class]])
    //    [imapSession setAllowsFolderConcurrentAccessEnabled:NO];
    //else
    [account.quickAccessSession setAllowsFolderConcurrentAccessEnabled:YES];

#if ULTIMATE
    
    NSString* footerString = [CustomerManager preInstalledFooterForUsername:account.quickAccessSession.username];
    
    if (footerString)
    {
        NSEntityDescription* footerEntity = [NSEntityDescription entityForName:@"EmailFooter" inManagedObjectContext:MAIN_CONTEXT];
        EmailFooter* corporateFooter = [[EmailFooter alloc] initWithEntity:footerEntity insertIntoManagedObjectContext:MAIN_CONTEXT];
        
        [corporateFooter setName:[CustomerManager customerString]];
        
        [corporateFooter setHtmlContent:footerString];
        [newAccountSetting setFooter:corporateFooter];

        //now create the inline attachments and add them to the footer
        NSArray* footers = [CustomerManager inlineAttachmentsForFooter];
        for(NSDictionary* footerIndex in footers)
        {
            NSString* base64Image = footerIndex[@"data"];

            NSData* imageData = [NSData dataWithBase64String:base64Image];

            //check if it's a valid image
            IMAGE* inlineImage = [[IMAGE alloc] initWithData:imageData];

            if(inlineImage)
            {
                FileAttachment* newAttachment = [FileAttachment makeAttachmentWithInlineImageData:imageData fileName:footerIndex[@"fileName"] contentType:footerIndex[@"contentType"] contentID:footerIndex[@"contentID"] inContext:MAIN_CONTEXT];

                [corporateFooter addInlineImagesObject:newAttachment];
            }
            else
            {
                NSLog(@"Invalid image data in corporate footer!! %@", imageData);
            }
        }
    }
    else
    {
        //set up the standard footer
        EmailFooter* standardFooter = [UserSettings currentUserSettings].standardFooter;
        [newAccountSetting setFooter:standardFooter];
    }

#else
    //set up the standard footer
    EmailFooter* standardFooter = [UserSettings currentUserSettings].standardFooter;
    [newAccountSetting setFooter:standardFooter];

#endif
    [newAccountSetting setShouldUse:@YES];

    account.accountSetting = newAccountSetting;

    account.accountSettingID = newAccountSetting.objectID;

    NSEntityDescription* entity = [NSEntityDescription entityForName:@"IMAPFolderSetting" inManagedObjectContext:MAIN_CONTEXT];
    IMAPFolderSetting* newOutboxFolder = [[IMAPFolderSetting alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];
    [newAccountSetting setOutboxFolder:newOutboxFolder];
    [newOutboxFolder setDisplayName:@"Outbox"];
    [newOutboxFolder setIsShownAsStandard:[NSNumber numberWithBool:NO]];
    [newOutboxFolder setStatus:@""];

//#if TARGET_OS_IPHONE
//    
//    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Setting up encryption" message:@"Mynigma will now set up the encryption in account " delegate:self cancelButtonTitle:NSLocalizedString(@"OK, got it!", nil) otherButtonTitles:nil];
//    
//    [alert show];
//
//
//#endif
    
    [EncryptionHelper ensureValidCurrentKeyPairForAccount:newAccountSetting withCallback:^(BOOL success){
        
//#if TARGET_OS_IPHONE
//        
//        [alert dismissWithClickedButtonIndex:0 animated:YES];
//
//        [AlertHelper showAlertWithTitle:NSLocalizedString(@"Great!", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Encryption setup is complete for the address %@. You can now send safe messages to other Mynigma users! Just send an open message first. Their reply will be encrypted.", nil), email] callback:^{}];
//
//#endif

    }];

    [CoreDataHelper save];

    [SelectionAndFilterHelper updateFilters];
}


+ (NSString*)displayNameForEmail:(NSString*)emailAddress
{
    NSSet* existingNames = [[UserSettings currentUserSettings].accounts valueForKey:@"displayName"];

    NSArray* emailComponents = [[emailAddress lowercaseString] componentsSeparatedByString:@"@"];
    NSString* mainPart = nil;
    if([@[@"gmail.com",@"googlemail.com",@"gmail.de",@"googlemail.de"] containsObject:[emailComponents objectAtIndex:1]])
    {
        mainPart = @"Gmail";
    }
    if([@[@"me.com",@"icloud.com"] containsObject:[emailComponents objectAtIndex:1]])
    {
        mainPart = @"iCloud";
    }
    if([@[@"gmx.de"] containsObject: [emailComponents objectAtIndex:1]])
    {
        mainPart = @"GMX";
    }
    if(!mainPart)
    {
        NSString* newMainPart;
        NSRange range = [[emailComponents objectAtIndex:1] rangeOfString:@"."];
        if(range.location!=NSNotFound)
        {
            newMainPart = [[[emailComponents objectAtIndex:1] substringToIndex:range.location] lowercaseString];
        }
        else
            newMainPart = [emailComponents objectAtIndex:1];

        //capitalize first letter
        NSString *firstCapChar = [[newMainPart substringToIndex:1] capitalizedString];
        mainPart = [newMainPart stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:firstCapChar];
    }
    NSString* proposedName = mainPart;
    if(![existingNames containsObject:proposedName])
    {
        return proposedName;
    }
    for(NSInteger index = 2;index<10;index++)
    {
        proposedName = [NSString stringWithFormat:@"%@ %ld",mainPart,(long)index];
        if(![existingNames containsObject:proposedName])
            return proposedName;
    }
    return mainPart;
}


+ (NSArray*)registeredEmailAddresses
{
    NSMutableArray* emails = [NSMutableArray new];

    for(IMAPAccountSetting* accountSetting in [UserSettings currentUserSettings].accounts)
    {
        [emails addObject:accountSetting.emailAddress];
    }

    return emails;
}


+ (void)useConnectionItem:(ConnectionItem*)connectionItem;
{
    [ThreadHelper ensureMainThread];

    //don't add the account if the email address is invalid(!)
    if(![connectionItem.emailAddress isValidEmailAddress])
        return;

    IMAPAccountSetting* existingSetting = nil;

    for(IMAPAccountSetting* accountSetting in [UserSettings currentUserSettings].accounts)
    {
        if([accountSetting.emailAddress isEqual:connectionItem.emailAddress])
            existingSetting = accountSetting;
    }

    if(existingSetting)
    {
        [existingSetting setShouldUse:@(connectionItem.shouldUseForImport)];

        //update the values

        [existingSetting setIncomingServer:connectionItem.incomingHost.lowercaseString];
        [existingSetting setOutgoingServer:connectionItem.outgoingHost.lowercaseString];

        //add this account setting to the current user's list
        [[UserSettings currentUserSettings] addAccountsObject:existingSetting];

        if(![NSString usersAddresses])
            [NSString setUsersAddresses:@[]];

        NSString* canonicalAddress = connectionItem.emailAddress.canonicalForm;

        if(canonicalAddress.length)
            [NSString setUsersAddresses:[[NSString usersAddresses] arrayByAddingObject:canonicalAddress]];

        if(![[UserSettings currentUserSettings] preferredAccount])
            [[UserSettings currentUserSettings] setPreferredAccount:existingSetting];

        //set appropriate values for the account setting
        [existingSetting setIncomingUserName:connectionItem.incomingUsername];
        [existingSetting setOutgoingUserName:connectionItem.outgoingUsername];
        [existingSetting setOutgoingEmail:connectionItem.emailAddress];
        [existingSetting setIncomingPort:connectionItem.incomingPort];
        [existingSetting setIncomingEncryption:connectionItem.incomingConnectionType];
        [existingSetting setOutgoingPort:connectionItem.outgoingPort];
        [existingSetting setOutgoingEncryption:connectionItem.outgoingConnectionType];

        [existingSetting setSenderEmail:connectionItem.emailAddress];
        [existingSetting setIncomingAuthType:connectionItem.incomingAuth];
        [existingSetting setOutgoingAuthType:connectionItem.outgoingAuth];

        if(connectionItem.incomingAuth.intValue != MCOAuthTypeXOAuth2 && connectionItem.incomingAuth.intValue != MCOAuthTypeXOAuth2Outlook)
        {
            [KeychainHelper saveAsyncPassword:connectionItem.incomingPassword forAccountSetting:existingSetting incoming:YES withCallback:^(BOOL success){

                [KeychainHelper saveAsyncPassword:connectionItem.outgoingPassword forAccountSetting:existingSetting incoming:NO withCallback:^(BOOL success){

#if ULTIMATE
                        if(existingSetting.hasBeenVerified.boolValue)
                            [SERVER sendNewContactsToServerWithAccount:existingSetting withCallback:nil];
#endif

                        [AccountCheckManager startupCheckForAccountSetting:existingSetting];

                }];
            }];
        }
    }
    else
    {
        //create a new one!
        [AccountCreationManager makeNewAccountWithLocalKeychainItem:connectionItem];
    }
}

+ (void)disuseAllAccounts
{
    [ThreadHelper ensureMainThread];

    for(IMAPAccountSetting* accountSetting in [UserSettings currentUserSettings].accounts)
    {
        [accountSetting setShouldUse:@NO];
    }
}

+ (void)resetIMAPAccountsFromAccountSettings
{
    [ThreadHelper ensureMainThread];

    UserSettings* currentUserSettings = [UserSettings currentUserSettings];
    
    NSMutableArray* newAccountsArray = [NSMutableArray new];

    for(IMAPAccountSetting* setting in [[currentUserSettings accounts] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES]]])
    {
        [setting setStatus:@""];
        if([setting isKindOfClass:[GmailAccountSetting class]])
        {
            IMAPAccount* newAccount = [AccountCreationManager createFromLoadedAccountSetting:setting];
            [newAccountsArray addObject:newAccount];
            for(GmailLabelSetting* labelSetting in setting.folders)
            {
                [labelSetting setStatus:@""];
            }
            //NSLog(@"%@",setting);
            //[newAccount checkAccount];
        }
        else
        {
            IMAPAccount* newAccount = [AccountCreationManager createFromLoadedAccountSetting:setting];
            [newAccountsArray addObject:newAccount];
            for(IMAPFolderSetting* folderSetting in setting.folders)
            {
                [folderSetting setStatus:@""];
            }
        }

        //if(!setting.hasBeenVerified.boolValue)
        //    [setting setHasRequestedWelcomeMessage:@NO];

        if(!setting.currentKeyPairLabel)
        {
            //get a valid key pair (generating new one if necessary)
            [EncryptionHelper ensureValidCurrentKeyPairForAccount:setting withCallback:^(BOOL success){}];
        }
    }
    
    [[AccountCreationManager sharedInstance] setAllAccounts:newAccountsArray];
}


+ (BOOL)makeNewAccountWithLocalKeychainItem:(ConnectionItem*)localItem
{
    if([self haveAccountForEmail:localItem.emailAddress])
        return NO;

    NSString* email = [localItem.emailAddress lowercaseString];

    IMAPAccount* newAccount = [IMAPAccount new];

    MCOIMAPSession* imapSession = [MCOIMAPSession new];

    [newAccount setQuickAccessSession:imapSession];

    [imapSession setAuthType:localItem.incomingAuth.intValue];
    [imapSession setConnectionType:localItem.incomingConnectionType.intValue];
    [imapSession setUsername:localItem.incomingUsername];
    [imapSession setPort:localItem.incomingPort.intValue];
    [imapSession setHostname:localItem.incomingHost.lowercaseString];
    [imapSession setPassword:localItem.incomingPassword];
    
    [imapSession setOAuth2Token:localItem.OAuth2Token];

    [imapSession setMaximumConnections:3];

    //if([@[@"gmail.com",@"googlemail.com"] containsObject:[emailComponents objectAtIndex:1]])
    [imapSession setAllowsFolderConcurrentAccessEnabled:YES];
    //else
    //    [imapSession setAllowsFolderConcurrentAccessEnabled:NO];

//    [newAccount setMainSession:[[IMAPSessionHelper alloc] initWithSession:imapSession]];

    MCOSMTPSession* smtpSession = [MCOSMTPSession new];
    [newAccount setSmtpSession:smtpSession];
    [smtpSession setAuthType:localItem.outgoingAuth.intValue];
    [smtpSession setConnectionType:localItem.outgoingConnectionType.intValue];
    [smtpSession setUsername:localItem.outgoingUsername];
    [smtpSession setPort:localItem.outgoingPort.intValue];
    [smtpSession setHostname:localItem.outgoingHost.lowercaseString];
    [smtpSession setPassword:localItem.outgoingPassword];
    
    [smtpSession setOAuth2Token:localItem.OAuth2Token];

    [newAccount setEmailAddress:[email lowercaseString]];

    [self makeAccountPermanent:newAccount];

    //set the idle helpers after making the account permanent, as the init method accesses the IMAPAccountSetting
    newAccount.idleHelperSpam = [[IdleHelper alloc] initWithIMAPAccount:newAccount];
    newAccount.idleHelperInbox = [[IdleHelper alloc] initWithIMAPAccount:newAccount];


#if TARGET_OS_IPHONE

    if(localItem.fullName.length>0)
        [newAccount.accountSetting setSenderName:localItem.fullName];
    else
        [newAccount.accountSetting setSenderName:NSLocalizedString(@"Anonymous", @"Unknown email address")];

#else


#endif

    [AccountCheckManager initialCheckForAccountSetting:newAccount.accountSetting];

    return YES;
}


+ (void)makeOrUpdateAccountWithConnectionItem:(ConnectionItem*)localItem
{
    IMAPAccount* newAccount = [self accountForEmail:localItem.emailAddress];
    
    MCOIMAPSession* imapSession = newAccount.quickAccessSession;

    if(!newAccount)
    {
        newAccount = [IMAPAccount new];
    }
    
    if(!imapSession)
    {
        imapSession = [MCOIMAPSession new];
    }
    
    NSString* email = [localItem.emailAddress lowercaseString];
    
    [newAccount setQuickAccessSession:imapSession];
    
    [imapSession setAuthType:localItem.incomingAuth.intValue];
    [imapSession setConnectionType:localItem.incomingConnectionType.intValue];
    [imapSession setUsername:localItem.incomingUsername];
    [imapSession setPort:localItem.incomingPort.intValue];
    [imapSession setHostname:localItem.incomingHost.lowercaseString];
    [imapSession setPassword:localItem.incomingPassword];
    
    [imapSession setOAuth2Token:localItem.OAuth2Token];
    
    [imapSession setMaximumConnections:3];
    
    //if([@[@"gmail.com",@"googlemail.com"] containsObject:[emailComponents objectAtIndex:1]])
    [imapSession setAllowsFolderConcurrentAccessEnabled:YES];
    //else
    //    [imapSession setAllowsFolderConcurrentAccessEnabled:NO];
    
    //    [newAccount setMainSession:[[IMAPSessionHelper alloc] initWithSession:imapSession]];
    
    MCOSMTPSession* smtpSession = [MCOSMTPSession new];
    [newAccount setSmtpSession:smtpSession];
    [smtpSession setAuthType:localItem.outgoingAuth.intValue];
    [smtpSession setConnectionType:localItem.outgoingConnectionType.intValue];
    [smtpSession setUsername:localItem.outgoingUsername];
    [smtpSession setPort:localItem.outgoingPort.intValue];
    [smtpSession setHostname:localItem.outgoingHost.lowercaseString];
    [smtpSession setPassword:localItem.outgoingPassword];
    
    [smtpSession setOAuth2Token:localItem.OAuth2Token];
    
    [newAccount setEmailAddress:[email lowercaseString]];
    
    if(!newAccount.accountSetting)
    {
        [self makeAccountPermanent:newAccount];
    }
    
    //set the idle helpers after making the account permanent, as the init method accesses the IMAPAccountSetting
    newAccount.idleHelperSpam = [[IdleHelper alloc] initWithIMAPAccount:newAccount];
    newAccount.idleHelperInbox = [[IdleHelper alloc] initWithIMAPAccount:newAccount];
    
    
#if TARGET_OS_IPHONE
    
    if(localItem.fullName.length>0)
        [newAccount.accountSetting setSenderName:localItem.fullName];
    else
        [newAccount.accountSetting setSenderName:NSLocalizedString(@"Anonymous", @"Unknown email address")];
    
#else
    
    
#endif
    
    [AccountCheckManager initialCheckForAccountSetting:newAccount.accountSetting];
}



#pragma mark -
#pragma mark CONNECTION TESTS

+ (MCOIMAPSession*)testIncomingServerUsingIMAPAccount:(IMAPAccount*)account withCallback:(void (^)(NSError*, MCOIMAPSession*))callback
{
    [ThreadHelper ensureMainThread];

    MCOIMAPSession* newImapSession = [MCOIMAPSession new];
    [newImapSession setAuthType:account.quickAccessSession.authType];
    [newImapSession setUsername:account.quickAccessSession.username];
    [newImapSession setPassword:account.quickAccessSession.password];
    [newImapSession setOAuth2Token:account.quickAccessSession.OAuth2Token];
    [newImapSession setHostname:account.quickAccessSession.hostname];
    [newImapSession setPort:account.quickAccessSession.port];
    [newImapSession setConnectionType:account.quickAccessSession.connectionType];
    [newImapSession setConnectionLogger:nil];

    MCOIMAPOperation* checkOperation = [newImapSession checkAccountOperation];
    [checkOperation start:[^(NSError *error) {
        callback(error, newImapSession);
    } copy]];

    return newImapSession;
}

+ (MCOSMTPSession*)testOutgoingServerUsingAccount:(IMAPAccount*)account withCallback:(void (^)(NSError*, MCOSMTPSession*))callback fromAddress:(NSString*)fromAddress
{
    [ThreadHelper ensureMainThread];
    
    MCOSMTPSession* newSmtpSession = [MCOSMTPSession new];
    [newSmtpSession setUsername:account.smtpSession.username];
    [newSmtpSession setPassword:account.smtpSession.password];
    [newSmtpSession setOAuth2Token:account.smtpSession.OAuth2Token];
    [newSmtpSession setHostname:account.smtpSession.hostname];
    [newSmtpSession setPort:account.smtpSession.port];
    [newSmtpSession setConnectionType:account.smtpSession.connectionType];
    [newSmtpSession setAuthType:account.smtpSession.authType];
    [newSmtpSession setConnectionLogger:nil];

    MCOSMTPOperation * op = [newSmtpSession checkAccountOperationWithFrom:[MCOAddress addressWithMailbox:fromAddress]];
    [op start:[^(NSError * error) {
        callback(error, newSmtpSession);
    } copy]];

    return newSmtpSession;
}





@end
