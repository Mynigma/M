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

#import <Foundation/Foundation.h>
#import "ConnectionItem.h"
#import "GTMOAuth2Authentication.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GTMOAuth2WindowController.h"

typedef void (^OAuthFinishCallback)(NSError* error, GTMOAuth2Authentication* auth);


@class ConnectionItem, GTMOAuth2ViewControllerTouch;

@interface OAuthHelper : NSObject





+ (void)refreshAccessTokenForEmailAddress:(NSString*)emailAddress andProvider:(NSString*)provider userInitiated:(BOOL)userinitiated withCallback:(void(^)(NSString* accessToken))callback;

+ (void)refreshAccessTokenForAccountSetting:(IMAPAccountSetting*) accountSetting userInitiated:(BOOL)userInitiated withCallback:(void(^)(void))callback;


#if TARGET_OS_IPHONE

+ (GTMOAuth2ViewControllerTouch*)getOAuthControllerWithConnectionItem:(ConnectionItem*)connectionItem withCallback:(void(^)(NSError* error, GTMOAuth2Authentication* auth))callback;

#else

+ (GTMOAuth2WindowController*)getOAuthControllerWithConnectionItem:(ConnectionItem*)connectionItem withCallback:(void(^)(NSError* error, GTMOAuth2Authentication* auth))callback;

+ (void)signInSheetModalForWindow:(NSWindow *)parentWindowOrNil controller:(GTMOAuth2WindowController*)controller;

#endif

@property NSDictionary* OAuthProviders;

@property(strong) OAuthFinishCallback finishCallback;

+ (OAuthHelper*) sharedInstance;

@end
