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


@class IMAPAccount, IMAPAccountSetting;


typedef enum : NSInteger {

    ConnectionItemSourceOfDataUndefined = -1,
    ConnectionItemSourceOfDataGuessed = 0,
    ConnectionItemSourceOfDataKeychain = 1,
    ConnectionItemSourceOfDataAppleMail = 2,
    ConnectionItemSourceOfDataMXRecord = 3,
    ConnectionItemSourceOfDataProvidersJSON = 4,
    ConnectionItemSourceOfDataEnteredManually = 5,
    ConnectionItemSourceOfDataTestedAndOK = 6,
    ConnectionItemSourceOfDataAlreadySetUp = 7

} ConnectionItemSourceOfData;




typedef enum : NSInteger {

    ConnectionItemSourceOfPasswordUndefined = -1,
    ConnectionItemSourceOfPasswordKeychain = 0,
    ConnectionItemSourceOfPasswordUserProvided = 1

} ConnectionItemSourceOfPassword;

typedef enum : NSInteger {

    ConnectionItemStatusUndefined = -1,
    ConnectionItemStatusActive = 0,
    ConnectionItemStatusDoneSuccess = 1,
    ConnectionItemStatusDoneError = 2,
    ConnectionItemStatusUserCancelled = 3
    
} ConnectionItemStatus;


//#if TARGET_OS_IPHONE
//
//@interface ConnectionItem : NSObject
//
////---------------
////currently not used on iOS
////added only to avoid compiler errors
//
//@property ConnectionItemSourceOfData sourceOfData;
//
//@property ConnectionItemSourceOfPassword sourceOfPassword;
//
//@property BOOL shouldUseForImport;
//
////---------------
//
//
//@property BOOL isImporting;
//@property BOOL importingCancelled;
//
//
//@property NSString* emailAddress;
//
//@property NSArray* emailAddresses;
//@property NSString* fullName;
//
//@property NSArray* sendingAliases;
//
//@property NSString* accountName;
//
//
//@property NSData* incomingPersistentRef;
//@property NSString* incomingHost;
//@property NSNumber* incomingPort;
//@property NSString* incomingUsername;
//@property NSNumber* incomingConnectionType;
//@property NSNumber* incomingAuth;
//
//@property NSString* incomingPassword;
//
//
//@property NSData* outgoingPersistentRef;
//@property NSString* outgoingHost;
//@property NSNumber* outgoingPort;
//@property NSString* outgoingUsername;
//@property NSNumber* outgoingConnectionType;
//@property NSNumber* outgoingAuth;
//
//@property NSString* outgoingPassword;
//
//- (instancetype)initWithAccount:(IMAPAccount*)account;
//
//- (instancetype)initWithEmail:(NSString*)email;
//
//- (instancetype)initWithAccountSetting:(IMAPAccountSetting*)accountSetting;
//
//- (BOOL)alreadyInUse;
//
//- (void)attemptImportWithCallback:(void(^)(BOOL success, NSString* errorMessage))callBack;
//
//- (BOOL)isImported;
//
//- (void)cancelImport;
//
//- (BOOL)canBeImported;
//
//- (BOOL)fetchPasswordsFromKeychainIfNecessary;
//
//- (BOOL)havePasswords;
//
//- (void)updateUsingProvidersList;
//
//- (void)clear;
//
//
//@property BOOL errorImporting;
//
//
//@end
//
//
//#else

@interface ConnectionItem : NSObject


@property ConnectionItemSourceOfData sourceOfData;
@property ConnectionItemSourceOfPassword sourceOfPassword;


@property (strong, nonatomic) NSString* emailAddress;
@property (strong, nonatomic) NSString* password;
@property (strong, nonatomic) NSString* OAuth2Token;

@property (strong) NSArray* emailAddresses;
@property (strong) NSString* fullName;
@property (strong) NSArray* sendingAliases;
@property (strong) NSString* accountName;


@property (strong) NSData* incomingPersistentRef;
@property (strong) NSString* incomingHost;
@property (strong) NSNumber* incomingPort;
@property (strong) NSString* incomingUsername;
@property (strong) NSNumber* incomingConnectionType;
@property (strong) NSNumber* incomingAuth;
@property (strong) NSString* incomingPassword;


@property (strong) NSData* outgoingPersistentRef;
@property (strong) NSString* outgoingHost;
@property (strong) NSNumber* outgoingPort;
@property (strong) NSString* outgoingUsername;
@property (strong) NSNumber* outgoingConnectionType;
@property (strong) NSNumber* outgoingAuth;
@property (strong) NSString* outgoingPassword;

@property BOOL isCancelled;

@property BOOL shouldUseForImport;

@property (strong) NSAttributedString* feedbackString;
@property NSInteger feedbackIconIndex;

@property (strong) NSError* IMAPError;
@property (strong) NSError* SMTPError;

@property BOOL IMAPSuccess;
@property BOOL SMTPSuccess;

@property (strong) NSMutableSet* activeIMAPConnections;
@property (strong) NSMutableSet* activeSMTPConnections;

//called when a connection attempt has finished
@property (strong) void (^doneCallback)(void);

//called whenever either the email address or the password is changed
@property (strong) void (^changeCallback)(void);


#pragma mark - Initialisation

- (id)initWithEmail:(NSString*)email;
- (id)initWithAccountSetting:(IMAPAccountSetting*)accountSetting;


#pragma mark - Connection attempts

- (void)cancelAllConnectionAttempts;
- (void)cancelAndResetConnections;
- (void)userCancelWithFeedback;

- (void)attemptImportWithCallback:(void(^)(void))callback;
- (void)attemptSpecificImportWithCallback:(void(^)(void))callback;


#pragma mark - Update item

- (void)lookForSettingsWithCallback:(void(^)(void))callback;

- (void)pullPasswordFromKeychainWithCallback:(void(^)(void))callback;
- (void)pullOAuthTokenFromKeychainWithCallback:(void(^)(void))callback;


+ (NSArray*)MXRecordsForHostname:(NSString*)hostString;
- (void)performMXLookupWithCallback:(void(^)(BOOL foundSomething))callback;
- (void) performMXLookupForHost:(NSString*) hostString withCallback:(void(^)(NSString* mxHost))callback;

- (void)performProvidersPlistLookupWithCallback:(void(^)(BOOL foundSomething))callback;

- (void)clear;

#pragma mark - Status queries

- (BOOL)isImporting;
- (BOOL)showsError;
- (BOOL)isSuccessfullyImported;
- (BOOL)canUseOAuth;


- (NSString*)OAuthProvider;

@end

//#endif
