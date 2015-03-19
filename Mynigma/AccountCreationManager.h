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
#import <MailCore/MailCore.h>

@class IMAPAccount, IMAPAccountSetting, ConnectionItem;

@interface AccountCreationManager : NSObject

+ (instancetype)sharedInstance;


+ (BOOL)haveAccountForEmail:(NSString*)emailAddress;


//looks up known providers and attempts to find hostname details for the given email address
+ (BOOL)tryToFindProviderDetailsWithEmail:(NSString*)email forAccount:(IMAPAccount*)account;


//fills the IMAPAccount object with the settings from the IMAPAccountSetting object
+ (void)fillIMAPAccount:(IMAPAccount*)newAccount withAccountSetting:(IMAPAccountSetting*)accountSetting;


//creates an IMAPAccount for an IMAPAccountSetting that was loaded from the store
+ (IMAPAccount*)createFromLoadedAccountSetting:(IMAPAccountSetting*)accountSetting;

//sets up an IMAPAccount without an associated IMAPAccountSetting - this is useful for account setup
//after a successful connection attempt call makeAccountPermanent to create a matching IMAPAccountSetting and persist the settings to the store
+ (IMAPAccount*)temporaryAccountWithEmail:(NSString*)email;

//takes an IMAPAccountSetting and creates a suitable IMAPAccountSetting for it - the account becomes permanent (i.e. stored)
+ (void)makeAccountPermanent:(IMAPAccount*)account;


//takes an email address an turns it into a pretty string to be displayed as the account name (e.g. Yahoo, Gmail 2, etc.)
+ (NSString*)displayNameForEmail:(NSString*)email;

+ (BOOL)makeNewAccountWithLocalKeychainItem:(ConnectionItem*)localItem;

+ (void)makeOrUpdateAccountWithConnectionItem:(ConnectionItem*)connectionItem;

+ (void)useConnectionItem:(ConnectionItem*)connectionItem;

+ (void)disuseAllAccounts;

+ (void)resetIMAPAccountsFromAccountSettings;

+ (NSArray*)registeredEmailAddresses;

//CONNECTION TEST
/**CALL ON MAIN*/
+ (MCOIMAPSession*)testIncomingServerUsingIMAPAccount:(IMAPAccount*)account withCallback:(void (^)(NSError*, MCOIMAPSession*))callback;
/**CALL ON MAIN*/
+ (MCOSMTPSession*)testOutgoingServerUsingAccount:(IMAPAccount*)account withCallback:(void (^)(NSError*, MCOSMTPSession*))callback fromAddress:(NSString*)fromAddress;


//an array of IMAPAccount objects (each associated with an IMAPAccountSetting in the store)
@property(strong) NSArray* allAccounts;



@end
