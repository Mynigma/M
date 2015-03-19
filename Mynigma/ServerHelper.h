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

#define SERVER [ServerHelper sharedInstance]

@class IMAPAccountSetting, Recipient;


//communication with the mynigma server is wrapped into this class

@interface ServerHelper : NSObject

@property NSMutableData* receivedData;

@property (nonatomic, strong) void (^callbackCopy)(NSDictionary*, NSError*);

#pragma mark -
#pragma mark SERVER REQUESTS


+ (ServerHelper*)sharedInstance;

+ (void)setSharedInstance:(ServerHelper*)instance;

//signs up a new email address with the server
- (void)requestWelcomeMessageForAccount:(IMAPAccountSetting*)accountSetting withCallback:(void(^)(NSDictionary*, NSError*))callback;

//confirms the sign up using the token provided in the welcome message
- (void)confirmSignUpForAccount:(IMAPAccountSetting*)accountSetting withToken:(NSString*)token andCallback:(void (^)(NSDictionary *, NSError *))callback;

- (void)confirmSignUpForAccount:(IMAPAccountSetting*)accountSetting andBypassGuard:(BOOL)byPassGuard withToken:(NSString*)token andCallback:(void (^)(NSDictionary *, NSError *))callback;


//sends an array of Recipient objects to the server to check if any new connections should be established
- (void)sendRecipientsToServer:(NSArray *)recipients forAccount:(IMAPAccountSetting*)accountSetting withCallback:(void(^)(NSDictionary*, NSError*))callback;

//sends a single Recipient object to the server
- (void)sendRecipientToServer:(Recipient*)recipient forAccount:(IMAPAccountSetting*)accountSetting withCallback:(void(^)(NSDictionary*, NSError*))callback;

//sends all EmailContactDetail addresses that have not previously been sent to the server
- (void)sendNewContactsToServerWithAccount:(IMAPAccountSetting*)accountSetting withCallback:(void(^)(NSDictionary*, NSError*))callback;

//sends all EmailContactDetail addresses to the server
- (void)sendAllContactsToServerWithAccount:(IMAPAccountSetting*)accountSetting withCallback:(void(^)(NSDictionary*, NSError*))callback;

//updates the current key

//removes all records from the server (except sign-up tokens)
- (void)removeAllRecordsForAccount:(IMAPAccountSetting*)accountSetting withCallback:(void(^)(NSDictionary*, NSError*))callback;


//removes any sign-up tokens from the server list
- (void)removeWelcomeMessageIDsForAccount:(IMAPAccountSetting *)accountSetting withCallback:(void (^)(NSDictionary *, NSError *))callback;

- (void)requestKeyWithLabel:(NSString*)keyLabel inAccount:(IMAPAccountSetting*)accountSetting withCallback:(void(^)(NSDictionary*, NSError*))callback;

- (NSArray*) hashContacts:(NSArray*)contacts;


- (void)sendArrayToLicenceServer:(NSArray*)array withCallback:(void(^)(NSDictionary*, NSError*))callback;

@end
