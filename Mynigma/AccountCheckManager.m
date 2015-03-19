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





#import "AccountCheckManager.h"
#import "IMAPAccountSetting+Category.h"
#import "OutlineObject.h"
#import "IMAPFolderSetting+Category.h"
#import "IMAPAccount.h"
#import "EmailMessageInstance+Category.h"
#import "EmailMessage+Category.h"
#import "ReloadingDelegate.h"
#import "RegistrationHelper.h"
#import "IMAPFolderManager.h"
#import "DeviceConnectionHelper.h"
#import "GmailAccountSetting.h"
#import "IdleHelper.h"
#import "Reachability.h"
#import "AppDelegate.h"
#import "EncryptionHelper.h"
#import "ThreadHelper.h"
#import "DisconnectOperation.h"
#import "SendingManager.h"
#import "UserSettings+Category.h"
#import "MCOIMAPSession+Category.h"
#import "SelectionAndFilterHelper.h"
#import "DownloadHelper.h"
#import "OAuthHelper.h"



#define ACCOUNT_CHECK_VERBOSE NO


#define VERBOSE NO
#define VERBOSE_CHECK NO




static NSMutableSet* iOSBackgroundCheckFolders;
static void (^iOSBackgroundCheckCallback)(BOOL successful, BOOL newMessages);
static BOOL iOSBackgroundCheckAllSuccessful;
static BOOL iOSBackgroundCheckHaveNewMessages;

static NSMutableSet* pulledRefreshFolders;
static void (^pulledRefreshCheckCallback)(NSArray* namesOfFoldersStillBeingChecked, BOOL allSuccessful);
static BOOL pulledRefreshAllSuccessful;

static NSMutableSet* accountsInWhichFoldersAreBeingUpdated;


@implementation AccountCheckManager

- (instancetype)init
{
    self = [super init];
    if (self) {

        lastTriedAccountCheck = [NSDate dateWithTimeIntervalSince1970:0];
        lastSuccessfulAccountCheck = [NSDate dateWithTimeIntervalSince1970:0];

        self.routineCheckTimer = [NSTimer scheduledTimerWithTimeInterval:5*60 target:[AccountCheckManager class] selector:@selector(timerFired:) userInfo:nil repeats:YES];
        if([self.routineCheckTimer respondsToSelector:@selector(setTolerance:)])
        {
            [self.routineCheckTimer setTolerance:60];
        }
    }
    return self;
}

+ (AccountCheckManager*)sharedInstance
{
    static dispatch_once_t p = 0;

    __strong static id sharedObject = nil;

    dispatch_once(&p, ^{
        sharedObject = [AccountCheckManager new];
    });

    return sharedObject;
}

//FACTORS:
//Mac/iOS
//wifi/3G
//battery or plugged in
//last successful check
//last unsuccessful check
//number of checks in the last 10 minutes
//manual reload?
//initial check?
//can MODSEQ?
//can QRESYNC?
//can idle?
//is idling?
//timer fired

#pragma mark - ACTION TRIGGERS

+ (void)timerFired:(NSTimer*)timer
{
    NSLog(@"AccountCheckTimer fired");
    [AccountCheckManager checkAllAccountsUserInitiated:NO];
}

+ (void)appReactivated
{
    [self checkAllAccountsUserInitiated:YES];
}

+ (void)awakeFromSleep
{
    [self checkAllAccountsUserInitiated:YES];
}


//+ (void)accountSettingClicked:(IMAPAccountSetting*)accountSetting
//{
//    IMAPAccount* account = accountSetting.account;
//
//    if([[NSDate date] timeIntervalSinceDate:account.lastTriedAccountCheck]>5)
//    {
//        [self checkAccountSetting:accountSetting];
//    }
//}




+ (void)startUpdatingFolders:(IMAPAccountSetting*)accountSetting
{
    if(!accountsInWhichFoldersAreBeingUpdated)
        accountsInWhichFoldersAreBeingUpdated = [NSMutableSet new];

    [accountsInWhichFoldersAreBeingUpdated addObject:accountSetting];
}

+ (void)doneUpdatingFolders:(IMAPAccountSetting*)accountSetting
{
    [accountsInWhichFoldersAreBeingUpdated removeObject:accountSetting];
}

+ (BOOL)isUpdatingFolders:(IMAPAccountSetting*)accountSetting
{
    return [accountsInWhichFoldersAreBeingUpdated containsObject:accountSetting];
}



+ (void)iOSBackgroundCheckWithCallback:(void(^)(BOOL successful, BOOL newMessages))callback
{
    @synchronized(@"iOS background check")
    {
        NSSet* foldersToBeChecked = [OutlineObject selectedFolderSettingsForSyncing];

        iOSBackgroundCheckCallback = callback;

        iOSBackgroundCheckAllSuccessful = YES;

        iOSBackgroundCheckHaveNewMessages = NO;

        iOSBackgroundCheckFolders = [NSMutableSet new];

        for(IMAPFolderSetting* folderSetting in foldersToBeChecked)
        {
            [iOSBackgroundCheckFolders addObject:folderSetting.objectID];

            IMAPAccount* account = folderSetting.inIMAPAccount.account;

            [account checkFolder:folderSetting userInitiated:NO];
        }
    }
}


+ (void)manualReloadWithProgressCallback:(void(^)(NSArray* namesOfFoldersStillBeingChecked, BOOL allSuccessful))callback
{
    @synchronized(@"manual reload")
    {
        NSSet* foldersToBeChecked = [OutlineObject selectedFolderSettingsForSyncing];

        pulledRefreshCheckCallback = callback;

        pulledRefreshAllSuccessful = YES;

        pulledRefreshFolders = [NSMutableSet new];

        for(IMAPFolderSetting* folderSetting in foldersToBeChecked)
        {
            [pulledRefreshFolders addObject:folderSetting];

            IMAPAccount* account = folderSetting.inIMAPAccount.account;

            [account checkFolder:folderSetting userInitiated:YES];
        }
    }
}

+ (void)manualReload
{
    [SendingManager sendAnyUnsentMessages];
}

//first check after account is set up by user
+ (void)initialCheckForAccountSetting:(IMAPAccountSetting*)accountSetting
{
    [ThreadHelper ensureMainThread];
    
    if(!accountSetting.shouldUse.boolValue)
        return;

    //set up routine check timer
    [AccountCheckManager sharedInstance];

    [EncryptionHelper ensureValidCurrentKeyPairForAccount:accountSetting withCallback:^(BOOL success) {

#if ULTIMATE
    [accountSetting.account.registrationHelper registerNewAccount];
#endif

    }];

    [self checkAccountSetting:accountSetting userInitiated:YES];

    //[self downloadMissingBodiesInFolder:accountSetting.allMailOrInboxFolder];
}

//check at app start-up
+ (void)startupCheckForAccountSetting:(IMAPAccountSetting*)accountSetting
{
    [ThreadHelper ensureMainThread];
    
    if(!accountSetting.shouldUse.boolValue)
        return;

    //set up routine check timer
    [AccountCheckManager sharedInstance];

#if ULTIMATE
    [accountSetting.account.registrationHelper findOrRequestWelcomeMessage];
#endif

    if (accountSetting.incomingAuthType.intValue == MCOAuthTypeXOAuth2 || accountSetting.incomingAuthType.intValue == MCOAuthTypeXOAuth2Outlook)
    {
        [OAuthHelper refreshAccessTokenForAccountSetting:accountSetting userInitiated:YES withCallback:^(){
            [self checkAccountSetting:accountSetting userInitiated:YES];
        }];
    }
    else
    {
        [self checkAccountSetting:accountSetting userInitiated:YES];
    }
}

//+ (void)changedAccountSelection
//{
//    @synchronized(@"manual reload")
//    {
//        pulledRefreshFolders = [NSMutableSet new];
//
//        pulledRefreshCheckCallback(@[], NO);
//
//        pulledRefreshCheckCallback = nil;
//    }
//}


// this check is to much isn't it?
+ (void)clickedOnAccountSetting:(IMAPAccountSetting*)accountSetting
{
    /*
    if([[accountSetting lastChecked] timeIntervalSinceNow]<-60*10)
    {
        [AccountCheckManager checkAccountSetting:accountSetting userInitiated:NO];
    }
    */
    if(!accountSetting.shouldUse.boolValue)
        return;

    [SendingManager sendAnyUnsentMessages];
}




#pragma mark - CHECKS

+ (void)downloadMissingBodiesInFolder:(IMAPFolderSetting*)folderSetting
{    
    [ThreadHelper ensureMainThread];

    if (!folderSetting)
        return;

    IMAPAccount* account = folderSetting.inIMAPAccount.account;
    
    if(!account.accountSetting.shouldUse.boolValue)
        return;

    [account freshSessionWithScope:^(MCOIMAPSession* downloadSession, DisconnectOperation* disconnectOperation)
    {

     if(VERBOSE)
        NSLog(@"Downloading missing bodies (%@)", folderSetting.displayName);

    BOOL isOniOS = TARGET_OS_IPHONE;

    NSDate* cutoffDate = [NSDate dateWithTimeIntervalSinceNow:-3600*24*(isOniOS?1:14)];

    NSPredicate* recentMessagePredicate = [NSPredicate predicateWithFormat:@"(message.dateSent > %@) AND (message.messageData.htmlBody == nil)", cutoffDate];

    NSSet* filteredSet = [folderSetting.containsMessages filteredSetUsingPredicate:recentMessagePredicate];

    for(EmailMessageInstance* messageInstance in filteredSet)
    {
        //fetch bodies of all messages less than 14 days old.../1 day on iOS
        if(![messageInstance.message isDownloaded])
        {
            if(VERBOSE)
                NSLog(@"Downloading body (%@) UID: %@", folderSetting.displayName, messageInstance.uid);

            [DownloadHelper downloadMessageInstance:messageInstance usingSession:downloadSession disconnectOperation:disconnectOperation];
        }
    }

    }];
}

//+ (void)doneCheckingFolder:(NSManagedObjectID*)folderObjectID error:(NSError*)error foundNewMessages:(BOOL)newMessages
//{
//    @synchronized(@"iOS background check")
//    {
//        if([iOSBackgroundCheckFolders containsObject:folderObjectID])
//        {
//            if(error)
//                iOSBackgroundCheckAllSuccessful = NO;
//
//            if(newMessages)
//                iOSBackgroundCheckHaveNewMessages = YES;
//
//            if(iOSBackgroundCheckCallback)
//            {
//                iOSBackgroundCheckCallback(iOSBackgroundCheckAllSuccessful, iOSBackgroundCheckHaveNewMessages);
//            }
//            else
//            {
//                NSLog(@"No iOS background check callback set!!!!");
//            }
//
//            [iOSBackgroundCheckFolders removeObject:folderObjectID];
//            
//            if(iOSBackgroundCheckFolders.count==0)
//            {
//                iOSBackgroundCheckCallback = nil;
//            }
//        }
//    }
//
//    [ThreadHelper runAsyncOnMain:^{
//
//    @synchronized(@"manual reload")
//    {
//        IMAPFolderSetting* folderSetting = [IMAPFolderSetting folderSettingWithObjectID:folderObjectID inContext:MAIN_CONTEXT];
//
//        //NSLog(@"Done checking folder %@ in account %@", folderSetting.displayName, folderSetting.inIMAPAccount.displayName);
//        
//        if(folderSetting && [pulledRefreshFolders containsObject:folderSetting])
//        {
//            if(error)
//                pulledRefreshAllSuccessful = NO;
//
//            [pulledRefreshFolders removeObject:folderSetting];
//
//            if(pulledRefreshCheckCallback)
//            {
//                NSArray* sortedFolders = [pulledRefreshFolders sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES]]];
//
//                __block NSMutableArray* namesOfFolders = [[sortedFolders valueForKey:@"displayName"] mutableCopy];
//
//                pulledRefreshCheckCallback(namesOfFolders, pulledRefreshAllSuccessful);
//            }
//            else
//            {
//                NSLog(@"No iOS background check callback set!!!!");
//            }
//
//
//            if(pulledRefreshFolders.count==0)
//            {
//                pulledRefreshCheckCallback = nil;
//            }
//        }
//    }
//
//    }];
//
//
//#if TARGET_OS_IPHONE
//#else
//
//    [ThreadHelper runAsyncOnMain:^{
//
//        if(!error)
//            [ReloadingDelegate doneCheckingFolder:folderObjectID];
//        else
//            [ReloadingDelegate errorCheckingFolder:folderObjectID];
//    }];
//#endif
//}





+ (void)checkAllAccountsUserInitiated:(BOOL)userInitiated
{
    [SelectionAndFilterHelper refreshAllMessages];
    for(IMAPAccountSetting* accountSetting in [UserSettings usedAccounts])
    {
        if (accountSetting.incomingAuthType.intValue == MCOAuthTypeXOAuth2 || accountSetting.incomingAuthType.intValue == MCOAuthTypeXOAuth2Outlook)
        {
            [OAuthHelper refreshAccessTokenForAccountSetting:accountSetting userInitiated:userInitiated withCallback:^(){
                [AccountCheckManager checkAccountSetting:accountSetting userInitiated:userInitiated];
            }];
        }
        else
        {
            //NSLog(@"Checking account %@", account.accountSetting.displayName);
            [AccountCheckManager checkAccountSetting:accountSetting userInitiated:userInitiated];
        }
    }
}

+ (void)checkAccountSetting:(IMAPAccountSetting*)accountSetting userInitiated:(BOOL)userInitiated
{
    [ThreadHelper ensureMainThread];
    
    if(!accountSetting.shouldUse.boolValue)
        return;

    //lastTriedAccountCheck = [NSDate date];

    if(VERBOSE_CHECK)
    {
        NSLog(@"%@ | Checking Account", accountSetting.emailAddress);
    }

    if(accountSetting.supportsIDLE==nil)
    {
        //haven't checked capabilities yet
        [self checkCapabilitiesForAccountSetting:accountSetting withCallback:^{
            [self checkAccountSetting:accountSetting userInitiated:userInitiated];
        }];
        return;
    }

    if(!accountSetting)
    {
        NSLog(@"Trying to check account with no accountSetting set!!!!");
        return;
    }
    
    [accountSetting setLastChecked:[NSDate date]];

    NSManagedObjectID* accountSettingObjectID = accountSetting.objectID;

    IMAPAccount* account = accountSetting.account;

    [account sendAnyUnsentMessages];

    MCOIMAPSession* newSession = [account freshSession];

    DisconnectOperation* disconnectOperation = [DisconnectOperation operationWithIMAPSession:newSession withCallback:nil];

    //update folder list

    if(![self isUpdatingFolders:accountSetting])
    {
        [self startUpdatingFolders:accountSetting];

        [IMAPFolderManager updateFoldersWithSession:newSession disconnectOperation:disconnectOperation inLocalContext:MAIN_CONTEXT withAccountSettingID:accountSettingObjectID userInitiated:userInitiated withCallback:^{

            [ThreadHelper runAsyncOnMain:^{

                [self doneUpdatingFolders:accountSetting];

                if(POST_DEVICE_MESSAGES)
                {
                    if(!accountSetting.mynigmaFolder)
                        [accountSetting setMynigmaFolder:accountSetting.spamFolder];

                    [DeviceConnectionHelper postDeviceDiscoveryMessageWithAccountSetting:accountSetting];
                }

                if([IMAPFolderManager hasAllMailFolder:accountSetting])
                {
                    IMAPFolderSetting* allMailFolder = [(GmailAccountSetting*)accountSetting allMailFolder];
                    if(allMailFolder)
                    {
                        [account.idleHelperInbox idle:allMailFolder];
                        [account checkFolder:allMailFolder userInitiated:userInitiated];
                    }

                    IMAPFolderSetting* spamFolder = [(GmailAccountSetting*)accountSetting spamFolder];
                    if(spamFolder)
                    {
                        [account.idleHelperSpam idle:spamFolder];
                        [account checkFolder:spamFolder userInitiated:userInitiated];
                    }

                    if(accountSetting.binFolder)
                    {
                        [account checkFolder:accountSetting.binFolder userInitiated:userInitiated];
                    }

                }
                else
                {
                    if(accountSetting.inboxFolder)
                    {
                        [account.idleHelperInbox idle:accountSetting.inboxFolder];
                        [account checkFolder:accountSetting.inboxFolder userInitiated:userInitiated];
                    }

                    if(accountSetting.spamFolder)
                    {
                        [account.idleHelperSpam idle:accountSetting.spamFolder];
                        [account checkFolder:accountSetting.spamFolder userInitiated:userInitiated];
                    }

                    for(IMAPFolderSetting* folderSetting in accountSetting.folders)
                    {
                        if(!folderSetting.inboxForAccount && !folderSetting.spamForAccount)
                        {
                            [account checkFolder:folderSetting userInitiated:userInitiated];
                        }
                    }
                }

                [self downloadMissingBodiesInFolder:accountSetting.allMailOrInboxFolder];
            }];
        }];
    }
}

// Checks the servers capabilities
+ (void)checkCapabilitiesForAccountSetting:(IMAPAccountSetting*)accountSetting withCallback:(void(^)(void))callback
{
    [ThreadHelper ensureMainThread];

    if(accountSetting)
    {
        if(!accountSetting.shouldUse.boolValue)
            return;
        
        IMAPAccount* account = accountSetting.account;

        MCOIMAPCapabilityOperation * op = [account.quickAccessSession capabilityOperation];

        [op start:^(NSError* error, MCOIndexSet* capabilities)
        {

            [ThreadHelper runAsyncOnMain:^{

                if (!error && capabilities)
                {    //do something

                    // Check for Idle
                    if ([capabilities containsIndex:MCOIMAPCapabilityIdle])
                        accountSetting.supportsIDLE = @(YES);
                    else
                        accountSetting.supportsIDLE = @(NO);

                    // Check for ModSeq (msg sync)
                    if ([capabilities containsIndex:MCOIMAPCapabilityCondstore] || [capabilities containsIndex:MCOIMAPCapabilityQResync])
                        accountSetting.supportsMODSEQ = @(YES);
                    else
                        accountSetting.supportsMODSEQ = @(NO);

                    // Check for QRESYNC
                    if([capabilities containsIndex:MCOIMAPCapabilityQResync])
                        accountSetting.supportsQRESYNC = @YES;
                    else
                        accountSetting.supportsQRESYNC = @NO;
                }
                if(callback)
                    callback();
            }];
        }];
    }
}



#pragma mark - DISPATCH & OPERATION QUEUES

+ (dispatch_queue_t)mailcoreDispatchQueue
{
    //    return dispatch_get_main_queue();
    static dispatch_queue_t mailcoreDispQueue = nil;

    if(!mailcoreDispQueue)
        mailcoreDispQueue = dispatch_queue_create("org.mynigma.mailcoreDispatchQueue", NULL);

    return mailcoreDispQueue;
}

+ (NSOperationQueue*)mailcoreOperationQueue
{
    static NSOperationQueue* theMailCoreOperationQueue;

    if(!theMailCoreOperationQueue)
    {
        theMailCoreOperationQueue = [NSOperationQueue new];

        [theMailCoreOperationQueue setMaxConcurrentOperationCount:20];
    }

    return theMailCoreOperationQueue;
}

+ (NSOperationQueue*)searchSignUpOperationQueue
{
    static NSOperationQueue* theSignUpSearchOperationQueue;

    if(!theSignUpSearchOperationQueue)
    {
        theSignUpSearchOperationQueue = [NSOperationQueue new];

        [theSignUpSearchOperationQueue setMaxConcurrentOperationCount:5];
    }

    return theSignUpSearchOperationQueue;
}

+ (NSOperationQueue*)userActionOperationQueue
{
    static NSOperationQueue* theUserActionOperationQueue;

    if(!theUserActionOperationQueue)
    {
        theUserActionOperationQueue = [NSOperationQueue new];

        [theUserActionOperationQueue setMaxConcurrentOperationCount:10];
    }

    return theUserActionOperationQueue;
}

//+ (NSOperationQueue*)idleOperationQueue
//{
//    static NSOperationQueue* theIdleOperationQueue;
//
//    if(!theIdleOperationQueue)
//        theIdleOperationQueue = [NSOperationQueue new];
//
//    [theIdleOperationQueue setMaxConcurrentOperationCount:20];
//
//    return theIdleOperationQueue;
//}


#pragma mark - AccountCheckDelegate

//this is for messages that we know exist (we have found a UID, but no matching message in the store, etc...)
+ (BOOL)shouldStartCheckingNewMessagesInFolder:(IMAPFolderSetting*)folderSetting  userInitiated:(BOOL)userInitiated
{
    if (userInitiated)
    {
        if(ACCOUNT_CHECK_VERBOSE)
        {
            NSLog(@"Starting user initiated new check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
        }
        [folderSetting setLastNewCheck:[NSDate date]];
        return YES;
    }
    
    if (!folderSetting.lastNewCheck)
    {
        if(ACCOUNT_CHECK_VERBOSE)
        {
            NSLog(@"Starting new check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
        }
        [folderSetting setLastNewCheck:[NSDate date]];
        return YES;
    }
    
#if TARGET_OS_IPHONE
    // when was the folder checked last
    // Inbox more frequently  10 vs 20
    // check wifi (30min) vs 3G (1h)
    // (2do include idle)
    // check battery > 5%
    if ([[UIDevice currentDevice] batteryLevel]>0.05)
    {
        if([Reachability isOnWIFI])
        {
            if (folderSetting.inboxForAccount || folderSetting.isAllMail)
            {
                if([folderSetting.lastNewCheck timeIntervalSinceNow]<-60*10)
                {
                    if(ACCOUNT_CHECK_VERBOSE)
                    {
                        NSLog(@"Starting new check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
                    }
                    [folderSetting setLastNewCheck:[NSDate date]];
                    return YES;
                }
            
            }
            else
            {
                if([folderSetting.lastNewCheck timeIntervalSinceNow]<-60*30)
                {
                    if(ACCOUNT_CHECK_VERBOSE)
                    {
                        NSLog(@"Starting new check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
                    }
                    [folderSetting setLastNewCheck:[NSDate date]];
                    return YES;
                }
            }
        }
        else
        {
            if (folderSetting.inboxForAccount || folderSetting.isAllMail)
            {
                if([folderSetting.lastNewCheck timeIntervalSinceNow]<-60*20)
                {
                    if(ACCOUNT_CHECK_VERBOSE)
                    {
                        NSLog(@"Starting new check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
                    }
                    [folderSetting setLastNewCheck:[NSDate date]];
                    return YES;
                }
                
            }
            else
            {
                if([folderSetting.lastNewCheck timeIntervalSinceNow]<-60*60)
                {
                    if(ACCOUNT_CHECK_VERBOSE)
                    {
                        NSLog(@"Starting new check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
                    }
                    [folderSetting setLastNewCheck:[NSDate date]];
                    return YES;
                }
            }
        }
    }
#else
    // checking battery is "way" more complicated than on iOS
    // so for now... it is. Inbox more frequently
    if (folderSetting.inboxForAccount || folderSetting.allMailForAccount)
        if([folderSetting.lastNewCheck timeIntervalSinceNow]<-60*5)
        {
            if(ACCOUNT_CHECK_VERBOSE)
            {
                NSLog(@"Starting new check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
            }
            [folderSetting setLastNewCheck:[NSDate date]];
            return YES;
        }
    
    
    if([folderSetting.lastNewCheck timeIntervalSinceNow]<-60*10)
    {
        if(ACCOUNT_CHECK_VERBOSE)
        {
            NSLog(@"Starting new check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
        }
        [folderSetting setLastNewCheck:[NSDate date]];
        return YES;
    }
    
#endif
    
    return NO;
}

// combine with need check old messages
+ (BOOL)shouldStartCheckingOldMessagesInFolder:(IMAPFolderSetting*)folderSetting  userInitiated:(BOOL)userInitiated
{
    /* USER INITIATED CHECKS */
    if (userInitiated)
    {
        // not yet checked at initial check after setup, don't do it, only set date
        if (!folderSetting.lastOldCheck)
        {
            if(ACCOUNT_CHECK_VERBOSE)
            {
                NSLog(@"Starting old check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
            }
            [folderSetting setLastOldCheck:[NSDate date]];
            return YES;
        }
        
        // if can modsec but not qresync we should check once a day, in order to catch deleted msgs
        if (folderSetting.account.canModSeq && !folderSetting.account.canQResync)
        {
            if([folderSetting.lastOldCheck timeIntervalSinceNow]<-60*60*24)
            {
                if(ACCOUNT_CHECK_VERBOSE)
                {
                    NSLog(@"Starting old check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
                }
                [folderSetting setLastOldCheck:[NSDate date]];
                return YES;
            }
        }
        
#if TARGET_OS_IPHONE
        // when was the folder checked last
        // check wifi 1h vs 3G (2h)
        // check battery > 10%
        if ([[UIDevice currentDevice] batteryLevel]>0.1)
        {
            if([Reachability isOnWIFI])
            {
                if([folderSetting.lastOldCheck timeIntervalSinceNow]<-60*60*1)
                {
                    if(ACCOUNT_CHECK_VERBOSE)
                    {
                        NSLog(@"Starting old check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
                    }
                    [folderSetting setLastOldCheck:[NSDate date]];
                    return YES;
                }
            }
            else
            {
                if([folderSetting.lastOldCheck timeIntervalSinceNow]<-60*60*2)
                {
                    if(ACCOUNT_CHECK_VERBOSE)
                    {
                        NSLog(@"Starting old check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
                    }
                    [folderSetting setLastOldCheck:[NSDate date]];
                    return YES;
                }
            }
        }
#else
        // checking battery is "way" more complicated than on iOS
        // so for now, 1h it is. Inbox more frequently
        if (folderSetting.inboxForAccount || folderSetting.allMailForAccount)
            if([folderSetting.lastOldCheck timeIntervalSinceNow]<-60*60*30)
            {
                if(ACCOUNT_CHECK_VERBOSE)
                {
                    NSLog(@"Starting old check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
                }
                [folderSetting setLastOldCheck:[NSDate date]];
                return YES;
            }
        
        
        if([folderSetting.lastOldCheck timeIntervalSinceNow]<-60*60*1)
        {
            if(ACCOUNT_CHECK_VERBOSE)
            {
                NSLog(@"Starting old check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
            }
            [folderSetting setLastOldCheck:[NSDate date]];
            return YES;
        }
        
#endif
        
        return NO;
    }
    
    else
        
    {
        
        /* TIMED CHECKS */
        
        // not yet checked
        if (!folderSetting.lastOldCheck)
        {
            // well don't check, wait for user initiation
            return NO;
        }
        
        // if can modsec but not qresync we should check once a day, in order to catch deleted msgs
        if (folderSetting.account.canModSeq && !folderSetting.account.canQResync)
        {
            if([folderSetting.lastOldCheck timeIntervalSinceNow]<-60*60*12)
            {
                if(ACCOUNT_CHECK_VERBOSE)
                {
                    NSLog(@"Starting old check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
                }
                [folderSetting setLastOldCheck:[NSDate date]];
                return YES;
            }
        }
        
#if TARGET_OS_IPHONE
        // when was the folder checked last
        // check wifi (12h) vs 3G (24h)
        // check battery > 10%
        if ([[UIDevice currentDevice] batteryLevel]>0.1)
        {
            if([Reachability isOnWIFI])
            {
                if([folderSetting.lastOldCheck timeIntervalSinceNow]<-60*60*12)
                {
                    if(ACCOUNT_CHECK_VERBOSE)
                    {
                        NSLog(@"Starting old check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
                    }
                    [folderSetting setLastOldCheck:[NSDate date]];
                    return YES;
                }
            }
            else
            {
                if([folderSetting.lastOldCheck timeIntervalSinceNow]<-60*60*24)
                {
                    if(ACCOUNT_CHECK_VERBOSE)
                    {
                        NSLog(@"Starting old check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
                    }
                    [folderSetting setLastOldCheck:[NSDate date]];
                    return YES;
                }
            }
        }
#else
        // checking battery is "way" more complicated than on iOS
        // so for now, 4h it is. Inbox more frequently
        if (folderSetting.inboxForAccount || folderSetting.allMailForAccount)
            if([folderSetting.lastOldCheck timeIntervalSinceNow]<-60*60*2)
            {
                if(ACCOUNT_CHECK_VERBOSE)
                {
                    NSLog(@"Starting old check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
                }
                [folderSetting setLastOldCheck:[NSDate date]];
                return YES;
            }
        
        
        if([folderSetting.lastOldCheck timeIntervalSinceNow]<-60*60*4)
        {
            if(ACCOUNT_CHECK_VERBOSE)
            {
                NSLog(@"Starting old check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
            }
            [folderSetting setLastOldCheck:[NSDate date]];
            return YES;
        }
        
#endif
        
        return NO;
    }
    
}

+ (BOOL)shouldStartCheckingOldMessagesWithMODSEQInFolder:(IMAPFolderSetting*)folderSetting userInitiated:(BOOL)userInitiated
{
    if (userInitiated)
    {
        // not yet checked at initial check after setup, don't do it, only set date
        if (!folderSetting.lastMODSEQCheck)
        {
            if(ACCOUNT_CHECK_VERBOSE)
            {
                NSLog(@"Starting old MODSEQ check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
            }
            [folderSetting setLastMODSEQCheck:[NSDate date]];
            return YES;
        }
        
        
#if TARGET_OS_IPHONE
        // when was the folder checked last
        // check wifi (12h) vs 3G (24h)
        // check battery > 10%
        if ([[UIDevice currentDevice] batteryLevel]>0.1)
        {
            if([Reachability isOnWIFI])
            {
                if([folderSetting.lastMODSEQCheck timeIntervalSinceNow]<-60*60*2)
                {
                    if(ACCOUNT_CHECK_VERBOSE)
                    {
                        NSLog(@"Starting old MODSEQ check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
                    }
                    [folderSetting setLastMODSEQCheck:[NSDate date]];
                    return YES;
                }
            }
            else
            {
                if([folderSetting.lastMODSEQCheck timeIntervalSinceNow]<-60*60*4)
                {
                    if(ACCOUNT_CHECK_VERBOSE)
                    {
                        NSLog(@"Starting old MODSEQ check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
                    }
                    [folderSetting setLastMODSEQCheck:[NSDate date]];
                    return YES;
                }
            }
        }
        
#else
        // checking battery is "way" more complicated than on iOS
        // so for now, 1h it is. Inbox more frequently (1/2h)
        if (folderSetting.inboxForAccount || folderSetting.allMailForAccount)
            if([folderSetting.lastMODSEQCheck timeIntervalSinceNow]<-60*30)
            {
                if(ACCOUNT_CHECK_VERBOSE)
                {
                    NSLog(@"Starting old MODSEQ check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
                }
                [folderSetting setLastMODSEQCheck:[NSDate date]];
                return YES;
            }
        
        if([folderSetting.lastMODSEQCheck timeIntervalSinceNow]<-60*60*1)
        {
            if(ACCOUNT_CHECK_VERBOSE)
            {
                NSLog(@"Starting old MODSEQ check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
            }
            [folderSetting setLastMODSEQCheck:[NSDate date]];
            return YES;
        }
        
#endif
        
        return NO;
        
    }
    
    else
        
    {
        // not yet checked
        if (!folderSetting.lastMODSEQCheck)
        {
            // do this on user initiated check
            return NO;
        }
        
        
#if TARGET_OS_IPHONE
        // when was the folder checked last
        // check wifi (12h) vs 3G (24h)
        // check battery > 10%
        if ([[UIDevice currentDevice] batteryLevel]>0.1)
        {
            if([Reachability isOnWIFI])
            {
                if([folderSetting.lastMODSEQCheck timeIntervalSinceNow]<-60*60*6)
                {
                    if(ACCOUNT_CHECK_VERBOSE)
                    {
                        NSLog(@"Starting old MODSEQ check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
                    }
                    [folderSetting setLastMODSEQCheck:[NSDate date]];
                    return YES;
                }
            }
            else
            {
                if([folderSetting.lastMODSEQCheck timeIntervalSinceNow]<-60*60*12)
                {
                    if(ACCOUNT_CHECK_VERBOSE)
                    {
                        NSLog(@"Starting old MODSEQ check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
                    }
                    [folderSetting setLastMODSEQCheck:[NSDate date]];
                    return YES;
                }
            }
        }
        
#else
        // checking battery is "way" more complicated than on iOS
        // so for now, 2h it is. Inbox more frequently (1h)
        if (folderSetting.inboxForAccount || folderSetting.allMailForAccount)
            if([folderSetting.lastMODSEQCheck timeIntervalSinceNow]<-60*60*1)
            {
                if(ACCOUNT_CHECK_VERBOSE)
                {
                    NSLog(@"Starting old MODSEQ check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
                }
                [folderSetting setLastMODSEQCheck:[NSDate date]];
                return YES;
            }
        
        if([folderSetting.lastMODSEQCheck timeIntervalSinceNow]<-60*60*2)
        {
            if(ACCOUNT_CHECK_VERBOSE)
            {
                NSLog(@"Starting old MODSEQ check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
            }
            [folderSetting setLastMODSEQCheck:[NSDate date]];
            return YES;
        }
        
#endif
        
        return NO;
    }
}

// Is called at the beginning of check folder
+ (BOOL)shouldStartCheckingFolder:(IMAPFolderSetting*)folderSetting userInitiated:(BOOL)userInitiated
{

    if (userInitiated)
    {
        if(ACCOUNT_CHECK_VERBOSE)
        {
            NSLog(@"Starting user initiated folder check %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
        }
        return YES;
    }
    
    
    // if last (new) check is very recent, don't auto check
    if (!folderSetting.lastNewCheck || [folderSetting.lastNewCheck timeIntervalSinceNow]<-60)
    {
        if(ACCOUNT_CHECK_VERBOSE)
        {
            NSLog(@"Starting folder check %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
        }
        return YES;
    }
    
    
#if TARGET_OS_IPHONE
    // if not user initiated check last time new msg check and old msg check
#else
    // if not user initiated check last time new msg check and old msg check
#endif
    
    return NO;
}

+ (BOOL)shouldMergeLocalChangesInFolder:(IMAPFolderSetting*)folderSetting userInitiated:(BOOL)userInitiated
{
    
#if TARGET_OS_IPHONE
    // when was the folder checked last
    // check wifi (10min) vs 3G (20min)
    // check battery > 10%
    if ([[UIDevice currentDevice] batteryLevel]>0.1)
    {
        if([Reachability isOnWIFI])
        {
            if([folderSetting.lastOldCheck timeIntervalSinceNow]<-60*10)
            {
                if(ACCOUNT_CHECK_VERBOSE)
                {
                    NSLog(@"Starting merging local changes in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
                }
//don't set this: it is also set by shoudlCheckOldMessages etc. (!!)
//                [folderSetting setLastOldCheck:[NSDate date]];
                return YES;
            }
        }
        else
        {
            if([folderSetting.lastOldCheck timeIntervalSinceNow]<-60*20)
            {
                if(ACCOUNT_CHECK_VERBOSE)
                {
                    NSLog(@"Starting merging local changes in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
                }
//                [folderSetting setLastOldCheck:[NSDate date]];
                return YES;
            }
        }
    }
    
#else
    //merging is only done if there are messages to merge, so this shouldn't be too much of a problem, at least on the desktop
    if(ACCOUNT_CHECK_VERBOSE)
            {
                NSLog(@"Starting merging local changes in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
            }
            return YES;

#endif
    
    return NO;
}


+ (void)didCheckNewMessagesInFolder:(NSString*)folderName inAccount:(NSString*)accountName
{
    if(ACCOUNT_CHECK_VERBOSE)
    {
        NSLog(@"Completed new check in folder %@ (%@)", folderName, accountName);
    }
}

+ (void)didCheckOldMessagesInFolder:(IMAPFolderSetting*)folderSetting
{
    if(ACCOUNT_CHECK_VERBOSE)
    {
        NSLog(@"Completed old check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
    }
}

+ (void)didCheckOldMessagesWithMODSEQInFolder:(IMAPFolderSetting*)folderSetting
{
    if(ACCOUNT_CHECK_VERBOSE)
    {
        NSLog(@"Completed old check in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
    }
}

+ (void)didCheckFolder:(IMAPFolderSetting*)folderSetting error:(NSError*)error foundNewMessages:(BOOL)newMessages
{
    if(ACCOUNT_CHECK_VERBOSE)
    {
        NSLog(@"Completed folder check %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
    }
    
    __block NSManagedObjectID* folderID = folderSetting.objectID;


        @synchronized(@"iOS background check")
        {
            if([iOSBackgroundCheckFolders containsObject:folderID])
            {
                if(error)
                    iOSBackgroundCheckAllSuccessful = NO;
    
                if(newMessages)
                    iOSBackgroundCheckHaveNewMessages = YES;
    
                if(iOSBackgroundCheckCallback)
                {
                    iOSBackgroundCheckCallback(iOSBackgroundCheckAllSuccessful, iOSBackgroundCheckHaveNewMessages);
                }
                else
                {
                    NSLog(@"No iOS background check callback set!!!!");
                }
    
                [iOSBackgroundCheckFolders removeObject:folderID];
    
                if(iOSBackgroundCheckFolders.count==0)
                {
                    iOSBackgroundCheckCallback = nil;
                }
            }
        }
    
        [ThreadHelper runAsyncOnMain:^{
    
        @synchronized(@"manual reload")
        {
            IMAPFolderSetting* folderSettingOnMain = [IMAPFolderSetting folderSettingWithObjectID:folderID inContext:MAIN_CONTEXT];
    
            //NSLog(@"Done checking folder %@ in account %@", folderSetting.displayName, folderSetting.inIMAPAccount.displayName);
    
            if(folderSettingOnMain && [pulledRefreshFolders containsObject:folderSettingOnMain])
            {
                if(error)
                    pulledRefreshAllSuccessful = NO;
    
                [pulledRefreshFolders removeObject:folderSettingOnMain];
    
                if(pulledRefreshCheckCallback)
                {
                    NSArray* sortedFolders = [pulledRefreshFolders sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES]]];
    
                    __block NSMutableArray* namesOfFolders = [[sortedFolders valueForKey:@"displayName"] mutableCopy];
    
                    pulledRefreshCheckCallback(namesOfFolders, pulledRefreshAllSuccessful);
                }
                else
                {
                    NSLog(@"No iOS background check callback set!!!!");
                }
    
    
                if(pulledRefreshFolders.count==0)
                {
                    pulledRefreshCheckCallback = nil;
                }
            }
        }
    
        }];
    
    
    #if TARGET_OS_IPHONE
    #else
    
        [ThreadHelper runAsyncOnMain:^{
    
            if(!error)
                [ReloadingDelegate doneCheckingFolder:folderID];
            else
                [ReloadingDelegate errorCheckingFolder:folderID];
        }];
    #endif

}

+ (void)didMergeLocalChangesInFolder:(IMAPFolderSetting*)folderSetting
{
    if(ACCOUNT_CHECK_VERBOSE)
    {
        NSLog(@"Done merging local changes in folder %@ (%@)", folderSetting.displayName, folderSetting.accountSetting.displayName);
    }
}


@end
