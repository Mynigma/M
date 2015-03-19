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





#import <MailCore/MailCore.h>
#import "EmailAccount.h"


@class MCOIMAPSession, MCOSMTPSession, MCOIMAPMessage, IMAPFolderSetting, SignUpWindowController, IdleHelper, MynigmaMessage, IMAPAccountSetting, EmailMessage, IMAPFolderSetting,  EmailMessageInstance, AccountCheckManager, DisconnectOperation;

#if ULTIMATE
@class RegistrationHelper;
#endif

@interface IMAPAccount : EmailAccount
{
    NSMutableArray* newMessageObjectIDs;

    // IDLE OPERATIONS
    MCOIMAPIdleOperation* idleOperationInbox; //IDLE operation on the inbox
    
    MCOIMAPIdleOperation* idleOperationSpam; //IDLE operation on the spam folder
    
    BOOL isIdlingInbox; //indicating whether the inbox is currently idling
    
    BOOL isIdlingSpam; //indication whether the spam folder is currently idling
    
    BOOL fetchingSignUpMessage;
    
    BOOL stopLookingForSignUpMessage;
    
    IdleHelper* idleHelperSpam;
    IdleHelper* idleHelperInbox;
    
    NSInteger idleLoopCountSpam;
    NSInteger idleLoopCountInbox;

    NSMutableSet* messagesBeingDownloaded;
    NSMutableSet* messagesBeingDecrypted;

    NSMutableDictionary* operationQueues;

    AccountCheckManager* accountCheckManager;
}

@property IdleHelper* idleHelperSpam;
@property IdleHelper* idleHelperInbox;

@property(strong) MCOIMAPSession* quickAccessSession;
@property(strong) MCOIMAPSession* idleSession;

- (MCOIMAPSession*)freshSession;

- (void)freshSessionWithScope:(void(^)(MCOIMAPSession* session, DisconnectOperation* disconnectOperation))scope;

//@property IMAPSessionHelper* mainSession;

@property NSString* emailAddress;


- (BOOL)canIdle;
- (BOOL)canModSeq;
- (BOOL)canQResync;

@property NSDate* lastTriedAccountCheck;
@property NSDate* lastSuccessfulAccountCheck;

#if ULTIMATE
@property RegistrationHelper* registrationHelper;
#endif


//+ (IMAPAccount*)accountForMessageInstance:(EmailMessageInstance*)messageInstance;

//- (NSOperationQueue*)mergeLocalChangesQueueForFolderWithObjectID:(NSManagedObjectID*)folderObjectID;


- (void)checkFolder:(IMAPFolderSetting*)folderSetting userInitiated:(BOOL)userInitiated;


- (NSString*)description;


#pragma mark - iOS

//+ (void)backwardLoadWithCallback:(void(^)(BOOL success, NSInteger totalNum, NSInteger numDone))callback;


//+ (void)registerSessionHelper:(IMAPSessionHelper*)helper;
//
//+ (void)unregisterSessionHelper:(IMAPSessionHelper*)helper;


@end
