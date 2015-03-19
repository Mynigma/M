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

#import "OAuthHelper.h"
#import "ConnectionItem.h"
#import "IMAPAccountSetting+Category.h"
#import "IMAPAccount.h"
#import "MCOIMAPSession+Category.h"
#import "AlertHelper.h"
#import "NSString+EmailAddresses.h"


#if TARGET_OS_IPHONE

#import "GTMOAuth2ViewControllerTouch.h"

#else 

#import "GTMOAuth2WindowController.h"

#endif


#define GOOGLE_SECRET @"";
#define OUTLOOK_SECRET @"";
#define YAHOO_SECRET @"";

static dispatch_queue_t accessTokenRequestQueue;
static NSMutableDictionary* accessTokenRequests;

@implementation OAuthHelper

- (id)init
{
    self = [super init];
    if (self) {
        self.OAuthProviders = [[NSDictionary alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"OAuthProviders" ofType:@"plist"]]];
    }
    return self;
}

+ (OAuthHelper*)sharedInstance
{
    static dispatch_once_t p = 0;
    
    __strong static id sharedObject = nil;
    
    dispatch_once(&p, ^{
        sharedObject = [self new];
    });
    
    return sharedObject;
}




#pragma mark - OAuth2

#if TARGET_OS_IPHONE

+ (GTMOAuth2ViewControllerTouch*)getOAuthControllerWithConnectionItem:(ConnectionItem*)connectionItem withCallback:(void(^)(NSError* error, GTMOAuth2Authentication* auth))callback
{
    NSString* provider = connectionItem.OAuthProvider;
    
    GTMOAuth2Authentication* auth = [self getFirstAuthForProvider:provider];
    
    [auth setConnectionItem:connectionItem];
    
    [self sharedInstance].finishCallback = [callback copy];

    return [self getOAuthControllerTouchWithAuth:auth forProvider:provider withEmailAddress:connectionItem.emailAddress delegate:[self sharedInstance] finishedSelector:@selector(viewOrWindowController:closedWithAuth:error:)];
}

#else

+ (GTMOAuth2WindowController*)getOAuthControllerWithConnectionItem:(ConnectionItem*)connectionItem withCallback:(void(^)(NSError* error, GTMOAuth2Authentication* auth))callback
{
    NSString* provider = connectionItem.OAuthProvider;
    
    GTMOAuth2Authentication* auth = [self getFirstAuthForProvider:provider];
    
    [auth setConnectionItem:connectionItem];
    
    [self sharedInstance].finishCallback = [callback copy];
    
    return [self getOAuthWindowControllerWithAuth:auth forProvider:provider withEmailAddress:connectionItem.emailAddress];
}

#endif


+ (void)refreshAccessTokenForAccountSetting:(IMAPAccountSetting*)accountSetting userInitiated:(BOOL)userInitiated withCallback:(void(^)(void))callback
{
    
    GTMOAuth2Authentication *auth = [self getAuthForAccount:accountSetting];
    
    if (!accessTokenRequests)
        accessTokenRequests = [NSMutableDictionary new];
    
    if ([auth canAuthorize])
    {
        if ([auth shouldRefreshAccessToken])
        {
            dispatch_sync([OAuthHelper accessTokenRequestQueue], ^{
                [accessTokenRequests setValue:@[accountSetting,callback,@(userInitiated)] forKey:accountSetting.emailAddress];
            });
            [auth beginTokenFetchWithDelegate:[self sharedInstance] didFinishSelector:@selector(auth:finishedRefreshWithFetcher:error:)];
        }
        else
        {
            NSString* accessToken = [auth accessToken];
            if (![accessToken isEqual:accountSetting.account.quickAccessSession.OAuth2Token])
                [self setAccessToken:accessToken forAccountSetting:accountSetting];
            
            if (callback)
                callback();
        }
    }
    else
    {
        // need to restart oauth process
        // this should only happen if
        //      a) we change client credentials
        //      b) user changes password
        //      c) user revokes app connection
        
        if (userInitiated)
            [AlertHelper showAlertWithMessage:NSLocalizedString(@"OAuth error",nil) informativeText:NSLocalizedString(@"You need to renew your provider's access control in M's account settings.",nil)];
    }
    
}

+ (void)refreshAccessTokenForEmailAddress:(NSString*)emailAddress andProvider:(NSString*)provider userInitiated:(BOOL)userInitiated withCallback:(void(^)(NSString* accessToken))callback
{

    GTMOAuth2Authentication *auth = [self getAuthForEmailAddress:emailAddress withProvider:provider];
    
    if ([auth canAuthorize])
    {
        if ([auth shouldRefreshAccessToken])
        {
            dispatch_sync([OAuthHelper accessTokenRequestQueue], ^{
                [accessTokenRequests setValue:@[callback,@(userInitiated)] forKey:emailAddress];
            });
            [auth beginTokenFetchWithDelegate:[self sharedInstance] didFinishSelector:@selector(auth:finishedRefreshWithFetcher:error:)];
        }
        else
        {
            NSString* accessToken = [auth accessToken];
            
            if (callback && accessToken.length)
                callback(accessToken);
        }
    }
    else
    {
        // need to restart oauth process
        // this should only happen if
        //      a) we change client credentials
        //      b) user changes password
        //      c) user revokes app connection
        
        if (userInitiated)
            [AlertHelper showAlertWithMessage:NSLocalizedString(@"OAuth error",nil) informativeText:NSLocalizedString(@"You need to renew your provider's access control in M's account settings.",nil)];
    }

}

+ (GTMOAuth2Authentication*)getFirstAuthForProvider:(NSString*)provider
{
    GTMOAuth2Authentication *auth = nil;
    
    NSDictionary* oauthData = [[self sharedInstance] getOAuthDataForProvider:provider];
    
    if(oauthData)
    {
        NSURL* tokenURL = [NSURL URLWithString:[oauthData objectForKey:@"tokenURL"]];
        
        auth = [GTMOAuth2Authentication authenticationWithServiceProvider:provider tokenURL:tokenURL redirectURI:oauthData[@"redirectURL"] clientID:[oauthData objectForKey:@"clientID"] clientSecret:[OAuthHelper secretForProvider:provider]];
    
        auth.scope = [oauthData objectForKey:@"scope"];
    }
    
    return auth;
}

#if TARGET_OS_IPHONE

+ (GTMOAuth2ViewControllerTouch*)getOAuthControllerTouchWithAuth:(GTMOAuth2Authentication*)auth forProvider:(NSString*)provider withEmailAddress:(NSString*)emailAddress delegate:(id)delegate finishedSelector:(SEL)selector
{
    NSDictionary* oauthData = [[self sharedInstance] getOAuthDataForProvider:provider];
            
    NSURL* authURL = [NSURL URLWithString:[oauthData objectForKey:@"authURL"]];

    GTMOAuth2ViewControllerTouch* newController = [[GTMOAuth2ViewControllerTouch alloc] initWithAuthentication:auth authorizationURL:authURL keychainItemName:@"override" delegate:delegate finishedSelector:selector];

    // prefill email address
    [newController setEmailAddress:emailAddress];
    
    return newController;
}

#else

+ (GTMOAuth2WindowController*)getOAuthWindowControllerWithAuth:(GTMOAuth2Authentication*)auth forProvider:(NSString*)provider withEmailAddress:(NSString*)emailAddress
{
    GTMOAuth2WindowController* newController;
    
    NSDictionary* oauthData = [[self sharedInstance] getOAuthDataForProvider:provider];
    
    NSURL* authURL = [NSURL URLWithString:[oauthData objectForKey:@"authURL"]];
        
    newController = [[GTMOAuth2WindowController alloc] initWithAuthentication:auth authorizationURL:authURL keychainItemName:nil resourceBundle:nil];
        
    // prefill email address
    [newController setEmailAddress:emailAddress];
    
    return newController;
}


#endif


#pragma mark - Internal auth methods


+ (GTMOAuth2Authentication*)getAuthForEmailAddress:(NSString*)emailAddress withProvider:(NSString*)provider
{
    GTMOAuth2Authentication *auth;
    
    NSDictionary* oauthData = [[self sharedInstance] getOAuthDataForProvider:provider];
    
    NSURL* tokenURL = [NSURL URLWithString:[oauthData objectForKey:@"tokenURL"]];
    
    auth = [GTMOAuth2Authentication authenticationWithServiceProvider:provider tokenURL:tokenURL redirectURI:oauthData[@"redirectURL"] clientID:[oauthData objectForKey:@"clientID"] clientSecret:[OAuthHelper secretForProvider:provider]];
    
    if (auth) {

#if TARGET_OS_IPHONE

        [GTMOAuth2ViewControllerTouch authorizeFromKeychainForName:[self keychainNameForEmail:emailAddress] authentication:auth error:nil];

#else
        [GTMOAuth2WindowController authorizeFromKeychainForName:[self keychainNameForEmail:emailAddress] authentication:auth];
        
#endif

    }
    
    return auth;
}


+ (GTMOAuth2Authentication*)getAuthForAccount:(IMAPAccountSetting*) accountSetting
{
    GTMOAuth2Authentication *auth;
    
    NSString* incomingServer = [accountSetting incomingServer];
    NSString* emailAddress = [accountSetting emailAddress];
    
    if ([incomingServer isEqual:@"imap.gmail.com"])
    {
        auth = [self getAuthForEmailAddress:emailAddress withProvider:@"Google"];
    }
    else if ([incomingServer isEqual:@"imap.mail.yahoo.com"] || [incomingServer isEqual:@"imap.mail.yahoo.co.jp"])
    {
        auth = [self getAuthForEmailAddress:emailAddress withProvider:@"Yahoo"];
    }
    else if ([incomingServer isEqual:@"imap-mail.outlook.com"])
    {
        auth = [self getAuthForEmailAddress:emailAddress withProvider:@"Outlook"];
    }

    return auth;
}

-(NSDictionary*)getOAuthDataForProvider:(NSString*)provider
{
    if(provider)
        return [self.OAuthProviders objectForKey:provider];
    else
        return nil;
}

- (void)updateConnectionItemWithAuth:(GTMOAuth2Authentication*)auth andError:(NSError*)error
{
    ConnectionItem* connectionItem = auth.connectionItem;
    
    NSString * email = [auth userEmail];
    NSString * accessToken = [auth accessToken];

    if ((error != nil) || ![email isValidEmailAddress] || !accessToken)
    {
        //error or invalid email
        return;
    }
    
    [connectionItem setEmailAddress:email];
    
    [connectionItem setIncomingUsername:email];
    [connectionItem setOutgoingUsername:email];
    
    // if outlook...
    if ([connectionItem.incomingHost isEqual:@"imap-mail.outlook.com"])
    {
        [connectionItem setIncomingAuth:@(MCOAuthTypeXOAuth2Outlook)];
        [connectionItem setOutgoingAuth:@(MCOAuthTypeXOAuth2Outlook)];
    }
    else
    {
        [connectionItem setIncomingAuth:@(MCOAuthTypeXOAuth2)];
        [connectionItem setOutgoingAuth:@(MCOAuthTypeXOAuth2)];
    }
    
    [connectionItem setOAuth2Token:accessToken];
    
    if(accessToken)
        [connectionItem setSourceOfData:ConnectionItemSourceOfDataTestedAndOK];
}

#pragma mark - Mac Window Wrapper

#if TARGET_OS_IPHONE
#else

+ (void)signInSheetModalForWindow:(NSWindow *)parentWindowOrNil controller:(GTMOAuth2WindowController*)controller
{
    if([controller respondsToSelector:@selector(signInSheetModalForWindow:completionHandler:)])
    {
        [controller signInSheetModalForWindow:parentWindowOrNil completionHandler:^(GTMOAuth2Authentication* auth, NSError* error){
            
            [[self sharedInstance] updateConnectionItemWithAuth:auth andError:error];
            
            if([self sharedInstance].finishCallback)
                [self sharedInstance].finishCallback(error, auth);
        }];
    }
    else
    {
        [controller signInSheetModalForWindow:parentWindowOrNil delegate:[self sharedInstance] finishedSelector:@selector(viewOrWindowController:closedWithAuth:error:)];
    }
}

#endif

#pragma mark - Helper

+ (NSString*)keychainNameForEmail:(NSString*)emailAddress
{
    return [NSString stringWithFormat:@"Mynigma OAuth: %@",emailAddress];
}

+ (NSString*)secretForProvider:(NSString*)provider
{
    if ([provider isEqual:@"Google"])
        return GOOGLE_SECRET;
    if ([provider isEqual:@"Outlook"])
        return OUTLOOK_SECRET;
    if ([provider isEqual:@"Yahoo"])
        return OUTLOOK_SECRET;
    
    return @"";
}

+(void)setAccessToken:(NSString*)accessToken forAccountSetting:(IMAPAccountSetting *)accountSetting
{
    IMAPAccount* account = accountSetting.account;
    
    [account.quickAccessSession setOAuth2Token:accessToken];
    [account.smtpSession setOAuth2Token:accessToken];
    
}

#pragma mark - OAuth delegates
- (void)auth:(GTMOAuth2Authentication *)auth finishedRefreshWithFetcher:(GTMHTTPFetcher *)fetcher error:(NSError *)error
{
    NSString * email = [auth userEmail];
    NSString * accessToken = [auth accessToken];
    
    if (error != nil || ![email isValidEmailAddress] || !accessToken)
    {
        // Access Token refresh failed.
        // If this happens to often, we should start OAuth afresh
#warning TODO error inspection
        // if internet connection fails?
        // [AlertHelper showAlertWithMessage:NSLocalizedString(@"OAuth error",nil) informativeText:NSLocalizedString(@"If this error occurs more than once, you should renew your provider's access control in M's account settings.",nil)];
        
        return;
    }
    
    // arr[3] = userInitiated
    dispatch_sync([OAuthHelper accessTokenRequestQueue], ^{
        
        NSArray* arr = [accessTokenRequests objectForKey:email];
        
        if (arr.count == 2)
        {
            // run callback
            __unsafe_unretained void (^callback)(NSString*) = nil;
            callback = arr[0];
            if (callback)
                callback(accessToken);
        }
        else if (arr.count == 3)
        {
            [OAuthHelper setAccessToken:accessToken forAccountSetting:arr[0]];
            
            // run callback
            __unsafe_unretained void (^callback)(void) = nil;
            callback = arr[1];
            if (callback)
                callback();
        }
        
        // remove this entry again
        [accessTokenRequests removeObjectForKey:email];
    });
}


- (void)viewOrWindowController:(NSObject*)viewOrWindowController closedWithAuth:(GTMOAuth2Authentication*)auth error:(NSError*)error
{
    [self updateConnectionItemWithAuth:auth andError:error];
    
    if(self.finishCallback)
    {
        self.finishCallback(error, auth);
     
        self.finishCallback = nil;
    }
}


#pragma mark - Private methods

+ (dispatch_queue_t)accessTokenRequestQueue
{
    if(!accessTokenRequestQueue)
        accessTokenRequestQueue = dispatch_queue_create("org.mynigma.accessTokenRequestQueue", NULL);
    
    return accessTokenRequestQueue;
}

@end
