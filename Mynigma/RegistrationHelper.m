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
#import "AppDelegate_iOS.h"
#import "Model_iOS.h"
#else
#import "AppDelegate.h"

#endif

#import "RegistrationHelper.h"
#import "IMAPAccount.h"
#import "IMAPAccountSetting.h"
#import <MailCore/MailCore.h>
#import "ServerHelper.h"
#import "IMAPFolderSetting.h"
#import "SearchOperation.h"
#import "AccountCheckManager.h"
#import "FetchMessagesOperation.h"
#import "CoreDataHelper.h"





static NSMutableDictionary* latestSignUpRequests;

@implementation RegistrationHelper


//init a new RegistrationHelper - one for each account to be registered
- (id)initWithAccount:(IMAPAccount*)newAccount
{
    self = [super init];
    if (self) {
        account = newAccount;
        accountSetting = newAccount.accountSetting;
        alreadyRunning = NO;
    }
    return self;
}

//looks through the inbox and spam folders and initiates a search for the sign up message in each
- (void)latestSignUpMessageInInboxOrSpamWithCallback:(void(^)(NSString* token, NSError* error))callback
{
    __block NSString* signupToken = nil;
    __block NSError* anyError = nil;

    //first check the inbox folder
    NSLog(@"Checking the inbox folder");
    if(!accountSetting.inboxFolder)
    {
        callback(nil, [NSError errorWithDomain:@"SignUpMessageSearch" code:413 userInfo:nil]);
    }

    [self findTokenInFolder:accountSetting.inboxFolder withCallback:^(NSString *token, NSError *error)
    {
        if(error)
            anyError = error;

        if(token)
        {
            signupToken = token;
        }

        if(signupToken)
            NSLog(@"Found a token!");
        else
            NSLog(@"No token found!");

        //now the spam folder
        NSLog(@"Checking the spam folder");

        if(!accountSetting.spamFolder)
        {
            callback(signupToken, [NSError errorWithDomain:@"SignUpMessageSearch" code:414 userInfo:nil]);
        }

    [self findTokenInFolder:accountSetting.spamFolder withCallback:^(NSString *token, NSError *error)
        {

        if(error)
            anyError = error;

        if(token)
        {
            signupToken = token;
        }

        callback(signupToken, anyError);
    }];
    }];
}


//searches the IMAP server message list by messageID to find the sign-up message (this message should contain the valid token)
- (void)findTokenInFolder:(IMAPFolderSetting*)folder withCallback:(void(^)(NSString*, NSError*))callback
{
    if(!folder)
    {
        callback(nil, [NSError errorWithDomain:@"SignUpMessageSearch" code:4 userInfo:nil]);
        return;
    }

    NSString* folderPath = folder.path;

    //search by messageID
    NSString* messageID = accountSetting.signUpMessageID;

    //if there is no messageID (likely because the request to the server failed) then simply return
    if(!messageID)
    {
        NSLog(@"No sign up message ID");
        callback(nil, [NSError errorWithDomain:@"SignUpMessageSearch" code:105 userInfo:nil]);
        return;
    }

    MCOIMAPSearchExpression* searchExpression = [MCOIMAPSearchExpression searchHeader:@"X-Mynigma-Signup" value:messageID];

    NSOperationQueue* queue = [AccountCheckManager searchSignUpOperationQueue];

    SearchOperation* searchOperation = [SearchOperation searchByExpression:searchExpression inFolder:folderPath session:account.quickAccessSession withCallback:^(NSError *error, MCOIndexSet *searchResult)
    {
        if(searchResult.count==0 || error!=nil)
        {
            callback(nil, error);
            return;
        }
        
        //NSLog(@"searchByExpression found %d emails.",searchResult.count);

        FetchMessagesOperation* fetchOperation = [FetchMessagesOperation fetchMessagesByUIDOperationWithRequestKind:MCOIMAPMessagesRequestKindUid|MCOIMAPMessagesRequestKindHeaders|MCOIMAPMessagesRequestKindExtraHeaders indexSet:searchResult folderPath:folderPath session:account.quickAccessSession withCallback:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages){

            NSArray* sortedMessages = [messages sortedArrayUsingComparator:^NSComparisonResult(MCOIMAPMessage* obj1, MCOIMAPMessage* obj2)
             {
                return [obj2.header.date compare:obj1.header.date]; //reverse order
            }];
            if(sortedMessages.count==0)
            {
                callback(nil, error);
                return;
            }
            MCOIMAPMessage* mostRecentMessage = [sortedMessages objectAtIndex:0];
            
            NSString* token = [mostRecentMessage.header extraHeaderValueForName:@"X-Mynigma-Token"];
            
            callback(token, nil);
        }];

        [fetchOperation setHighPriority];

        if(fetchOperation)
            [queue addOperation:fetchOperation];
    }];

    [searchOperation setHighPriority];

    if(searchOperation)
        [queue addOperation:searchOperation];
}




- (void)tryToConfirmSignUpWithCallback:(void(^)(BOOL responseOK, NSError* error))callback
{
    //search by messageID
    NSString* messageID = accountSetting.signUpMessageID;

    //if there is no messageID (likely because the request to the server failed) then simply return
    if(messageID) //did server send a message?
    {
    [self latestSignUpMessageInInboxOrSpamWithCallback:[^(NSString *token, NSError *error)
     {
         if(token)
             [SERVER confirmSignUpForAccount:accountSetting withToken:token andCallback:[^(NSDictionary *dict, NSError *error) {
                 NSString* response = [dict objectForKey:@"response"];

                 if([response isEqualToString:@"OK"])
                 {
                     NSLog(@"Confirmed sign-up");
                     callback(YES, nil);
                 }
                 else
                 {
                     NSLog(@"Failed to confirm sign-up with latest token: response dict is %@", dict);
                     callback(NO, error);
                 }
             } copy]];
         else
         {
             NSLog(@"Failed to confirm sign-up: no sign-up message found");
             callback(NO, error);
         }
     } copy]];
    }
    else
        callback(NO,nil);
}





- (NSDate*)lastSignUpMessageRequestDate
{
    NSString* email = accountSetting.emailAddress;

    return [latestSignUpRequests objectForKey:email];
}


- (void)registerNewAccount
{
    if(!accountSetting)
        accountSetting = (IMAPAccountSetting*)[MAIN_CONTEXT existingObjectWithID:account.accountSettingID error:nil];

    if(!account.quickAccessSession || !accountSetting || !accountSetting.emailAddress)
        [self performSelector:@selector(registerNewAccount) withObject:nil afterDelay:1];
    
    if(!latestSignUpRequests)
        latestSignUpRequests = [NSMutableDictionary new];
    latestSignUpRequests[accountSetting.emailAddress] = [NSDate date];
    [self requestWelcomeMessage];
}


//only called by findOrRequestWelcomeMessage
- (void) requestWelcomeMessage
{
    [SERVER requestWelcomeMessageForAccount:accountSetting withCallback:^(NSDictionary* dict, NSError* error) {
        
        NSString* response = [dict objectForKey:@"response"];
        NSString* messageID =  [dict objectForKey:@"messageID"];
        
        if([response isEqualToString:@"OK"])
        {
            NSLog(@"Requested welcome message");
            
            if(!latestSignUpRequests)
                latestSignUpRequests = [NSMutableDictionary new];
            latestSignUpRequests[accountSetting.emailAddress] = [NSDate date];
            
            if (messageID)
            {
                [accountSetting setSignUpMessageID:messageID];

                [CoreDataHelper save];

                //try to find the welcome message after 5 seconds...
                [self performSelector:@selector(findOrRequestWelcomeMessage) withObject:nil afterDelay:5];
            }
            else
            {
                NSLog(@"Received no messageID");
                //try again after 30 seconds...
                [self performSelector:@selector(findOrRequestWelcomeMessage) withObject:nil afterDelay:30];
            }
            
        }
        else if([response isEqualToString:@"NO_TOKEN"] || [response isEqualToString:@"WRONG_TOKEN"])
        {
            NSLog(@"Welcome message request failed: response dict is %@", dict);
            
            
            if(self.callbackForTests)
                self.callbackForTests(response, nil);
            
            //try again after 30 seconds...
            [self performSelector:@selector(findOrRequestWelcomeMessage) withObject:accountSetting afterDelay:30];
        }
        else if([response isEqualToString:@"WRONG_KEY_ID"])
        {
            NSLog(@"Wrong key ID!!!!");
            
#if TARGET_OS_IPHONE
#else
            NSAlert* alert = [NSAlert alertWithMessageText:@"Error: already registered!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The address %@ has already been registered using a different key...", accountSetting.emailAddress];
            [alert runModal];
#endif
            
            if(self.callbackForTests)
                self.callbackForTests(response, nil);
        }
        
        
    }];
}


// tries to confirm Signup, determines wheather to request a new welcome message
- (void)findOrRequestWelcomeMessage
{
    //don't run several of these at once...
    if(alreadyRunning)
        return;

    alreadyRunning = YES;

    if(!accountSetting)
        accountSetting = (IMAPAccountSetting*)[MAIN_CONTEXT existingObjectWithID:account.accountSettingID error:nil];

    if(TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)
        return;

    //only need to look for the sign-up message if the account has not already been verified...
    if(accountSetting.hasBeenVerified.boolValue)
        return;

    if(!account.quickAccessSession || !accountSetting || !accountSetting.emailAddress)
    {
        alreadyRunning = NO;
        [self performSelector:@selector(findOrRequestWelcomeMessage) withObject:nil afterDelay:1];
        return;
    }
    
    //first try to sign up with the latest token, if any...
    [self tryToConfirmSignUpWithCallback:^(BOOL responseOK, NSError* error)
     {
         alreadyRunning = NO;

         if(error)
         {
             //don't request a new token if the lack of a suitable sign-up message is due to a connection error - just retry to 10 seconds
             //errors with domain @"SignUpMessageSearch" should lead to abort (no inbox folder, no spam folder, etc...)
             if(![error.domain isEqual:@"SignUpMessageSearch"])
                 [self performSelector:@selector(findOrRequestWelcomeMessage) withObject:nil afterDelay:10];
         }
         else if(!responseOK)
         {
             NSDate* currentTime = [NSDate date];
             NSDate* lastSignUpRequestDate = [self lastSignUpMessageRequestDate];
             
             //request another msg
             if(!lastSignUpRequestDate || [currentTime timeIntervalSinceDate:lastSignUpRequestDate]>600)
             {
                 [self requestWelcomeMessage];
             }
             else
             {
                 //take another Look
                 [self performSelector:@selector(findOrRequestWelcomeMessage) withObject:nil afterDelay:5];
             }

         }
         else
         {
             if(self.callbackForTests)
                 self.callbackForTests(@"OK", nil);
             NSLog(@"SUCCESS!!");
         }
     }];
}


- (void)checkIfMessageIsWelcomeMail:(MCOIMAPMessage*)message
{
    if(accountSetting.signUpMessageID && [[message.header extraHeaderValueForName:@"X-Mynigma-Signup"] isEqual:accountSetting.signUpMessageID])
    //if([message.header.from.displayName isEqual:@"Mynigma"])
    {
        NSString* token =[message.header extraHeaderValueForName:@"X-Mynigma-Token"];
        
        [MAIN_CONTEXT performBlock:^{

            [SERVER confirmSignUpForAccount:accountSetting andBypassGuard:YES withToken:token andCallback:[^(NSDictionary *dict, NSError *error) {

            NSString* response = [dict objectForKey:@"response"];

            if([response isEqualToString:@"OK"])
            {
                NSLog(@"Spontaneous confirmation: Confirmed sign-up");
            }
            else
            {
                NSLog(@"Spontaneous confirmation: Failed to confirm sign-up with token: response dict is %@", dict);
            }
        } copy]];

        }];
    }
}



@end
