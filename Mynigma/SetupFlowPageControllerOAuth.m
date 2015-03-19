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

#import "SetupFlowPageControllerOAuth.h"
#import "OAuthHelper.h"
#import "GTMOAuth2ViewControllerTouch.h"


@interface SetupFlowPageControllerOAuth ()

@end

@implementation SetupFlowPageControllerOAuth

- (IBAction)showPrivacyPolicy:(id)sender
{
    NSString* privacyPolicyLocation = NSLocalizedString(@"https://mynigma.org/en/PPApp.html", @"Privacy policy link");
    
    NSURL* privacyPolicyURL = [NSURL URLWithString:privacyPolicyLocation];
    
    [[UIApplication sharedApplication] openURL:privacyPolicyURL];
}


- (IBAction)usePasswordInstead:(id)sender
{
    [self.dataProvisionDelegate setSkipOAuth:YES];
}

//- (IBAction)launchOAuthScreen:(id)sender
//{
//    //[OAuthHelper startOAuth2FromController:self];
//    
//    NSString* host = [[self.dataProvisionDelegate getConnectionItem] incomingHost];
//    
//    /* Google */
//    if ([host isEqual:@"imap.gmail.com"])
//    {
//        [self startOAuthForProvider:@"Google"];
//    }
//    else if ([host isEqual:@"imap.mail.yahoo.com"] || [host isEqual:@"imap.mail.yahoo.co.jp"])
//    {
//        [self startOAuthForProvider:@"Yahoo"];
//    }
//    else if ([host isEqual:@"imap-mail.outlook.com"])
//    {
//        [self startOAuthForProvider:@"Outlook"];
//    }
//    else
//    {
//        // handle non (tested) oauth provider
//    }
//    
//}

//-(void) startOAuthForProvider:(NSString*)provider
//{
//    NSString* kClientID;
//    NSString* kClientSecret;
//    NSString* kScope;
//    NSString* kTokenURLString;
//    
//    GTMOAuth2Authentication *auth;
//    
//    if ([provider isEqual:@"Google"])
//    {
//        kClientID = @"663129018939-97dflc5jlb98d8l9c6960f7b4vk45uik.apps.googleusercontent.com";
//        kClientSecret = @"6PL_K3Hbs9O8cdx2nVY5Une4";
//        kScope = @"https://mail.google.com/";
//        
//        auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:[self keychainName] clientID:kClientID clientSecret:kClientSecret];
//        
//    }
//    else
//    {
//        
//        if ([provider isEqual:@"Yahoo"])
//        {
//            kClientID = @"";
//            kClientSecret = @"";
//            kScope = @"";
//            kTokenURLString = @"";
//        }
//        else if ([provider isEqual:@"Outlook"])
//        {
//            kClientID = @"";
//            kClientSecret = @"";
//            kScope = @"";
//            kTokenURLString = @"";
//        }
//        
//        NSURL *tokenURL = [NSURL URLWithString:kTokenURLString];
//        // We'll make up an arbitrary redirectURI.  The controller will watch for
//        // the server to redirect the web view to this URI, but this URI will not be
//        // loaded, so it need not be for any actual web page.
//        NSString *redirectURI = @"http://www.google.com/OAuthCallback";
//    
//        auth = [GTMOAuth2Authentication authenticationWithServiceProvider:provider tokenURL:tokenURL redirectURI:redirectURI clientID:kClientID clientSecret:kClientSecret];
//        
//    }
//    
//    if ([auth refreshToken] == nil)
//    {
//        // need a new token
//        GTMOAuth2ViewControllerTouch *oauthController = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:kScope clientID:kClientID clientSecret:kClientSecret keychainItemName:[self keychainName] delegate:self finishedSelector:@selector(windowController:finishedWithAuth:error:)];
//        
//        // prefill email address
//        [oauthController setEmailAddress:[self.dataProvisionDelegate getConnectionItem].emailAddress];
//        
//        // need push here... [[self navigationController] pushViewController:controller animated:YES];
//        
//        [self presentViewController:oauthController animated:YES completion:nil];
//    }
//    else
//    {
//        [auth beginTokenFetchWithDelegate:self
//                        didFinishSelector:@selector(auth:finishedRefreshWithFetcher:error:)];
//    }
//
//}


@end
