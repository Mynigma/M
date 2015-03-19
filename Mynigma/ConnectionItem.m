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





#import "ConnectionItem.h"
#import <MailCore/MailCore.h>
#import "KeychainHelper.h"
#import "MCODelegate.h"
#import "AccountCreationManager.h"
#import "IMAPAccount.h"
#import "IMAPAccountSetting.h"
#import "ThreadHelper.h"
#import <arpa/inet.h>
#import <resolv.h>
#import "ThreadHelper.h"
#import "IconListAndColourHelper.h"
#import "NSString+EmailAddresses.h"
#import "MCOIMAPSession+Category.h"
#import "MCOSMTPSession+Category.h"
#import "OAuthHelper.h"


#define TIMEOUT 10


NSArray* VTMxRecordForHostname(NSString *hostname)
{
    NSMutableArray *mxRecords = [NSMutableArray array];

    unsigned char response[NS_PACKETSZ];
    ns_msg handle;
    ns_rr rr;
    int len;
    char dispbuf[4096];

    if ((len = res_search([hostname UTF8String], ns_c_in, ns_t_mx, response, sizeof(response))) < 0) {
        /* WARN: res_search failed */
        return nil;
    }

    if (ns_initparse(response, len, &handle) < 0) {
        return nil;
    }


    len = ns_msg_count(handle, ns_s_an);
    if (len < 0)
        return nil;

    for (int ns_index = 0; ns_index < len; ns_index++) {
        if (ns_parserr(&handle, ns_s_an, ns_index, &rr)) {
            /* WARN: ns_parserr failed */
            continue;
        }
        ns_sprintrr (&handle, &rr, NULL, NULL, dispbuf, sizeof (dispbuf));
        if (ns_rr_class(rr) == ns_c_in && ns_rr_type(rr) == ns_t_mx) {
            char mxname[4096];
            dn_expand(ns_msg_base(handle), ns_msg_base(handle) + ns_msg_size(handle), ns_rr_rdata(rr) + NS_INT16SZ, mxname, sizeof(mxname));
            [mxRecords addObject:[NSString stringWithFormat:@"%s", mxname]];
        }
    }
    if (mxRecords.count == 0)
        return nil;

    return mxRecords;
}



@implementation ConnectionItem


#pragma mark - Initialisation

- (id)init
{
    self = [super init];
    if (self) {

        //use for import check box is on by default
        [self setShouldUseForImport:YES];

        //the source of data is undefined, unless otherwise specified
        self.sourceOfData = ConnectionItemSourceOfDataUndefined;

        //source of the
        self.sourceOfPassword = ConnectionItemSourceOfPasswordUndefined;

        //the sets of currently active connections
        [self setActiveIMAPConnections:[NSMutableSet new]];
        [self setActiveSMTPConnections:[NSMutableSet new]];

        self.IMAPError = nil;
        self.SMTPError = nil;
        self.IMAPSuccess = NO;
        self.SMTPSuccess = NO;

        [self showEmptyFeedback];
    }
    return self;
}

- (id)initWithEmail:(NSString*)email
{
    self = [self init];
    if (self) {

        //this is overwritten
        //cancels and resets all connections etc...
        [self setEmailAddress:email];
    }
    return self;
}


- (id)initWithAccountSetting:(IMAPAccountSetting*)accountSetting
{
    self = [self init];
    if (self) {

        //account is already set up - don't overwrite values(!)
        [self setIncomingAuth:accountSetting.incomingAuthType];
        [self setIncomingConnectionType:accountSetting.incomingEncryption];
        [self setIncomingHost:accountSetting.incomingServer];
        [self setIncomingPersistentRef:accountSetting.incomingPasswordRef];
        [self setIncomingPort:accountSetting.incomingPort];
        [self setIncomingUsername:accountSetting.incomingUserName];

        [self setOutgoingAuth:accountSetting.outgoingAuthType];
        [self setOutgoingConnectionType:accountSetting.outgoingEncryption];
        [self setOutgoingHost:accountSetting.outgoingServer];
        [self setOutgoingPersistentRef:accountSetting.outgoingPasswordRef];
        [self setOutgoingPort:accountSetting.outgoingPort];
        [self setOutgoingUsername:accountSetting.outgoingUserName];

        self.emailAddress = accountSetting.emailAddress;

        [self setShouldUseForImport:accountSetting.shouldUse.boolValue];

        self.sourceOfData = ConnectionItemSourceOfDataAlreadySetUp;
    }
    return self;
}





#pragma mark - Connection tests

//cancel all running operations
//don't reset the success feedback
- (void)cancelAllConnectionAttempts
{
    //cancel all running IMAP operations
    for(MCOIMAPSession* imapSession in self.activeIMAPConnections)
    {
        [imapSession cancelAllOperations];
    }

    //SMTP operations cannot be cancelled
}

//cancel all running connections
//then reset the connections and success feedback
- (void)cancelAndResetConnections
{
    [self cancelAllConnectionAttempts];

    self.doneCallback = nil;

    //reset the active connections so that the callbacks won't be executed when the operations to be cancelled return
    self.activeIMAPConnections = [NSMutableSet new];
    self.activeSMTPConnections = [NSMutableSet new];

    self.IMAPError = nil;
    self.SMTPError = nil;

    self.IMAPSuccess = NO;
    self.SMTPSuccess = NO;
}

- (void)userCancelWithFeedback
{
    [self cancelAndResetConnections];

    [self showUserCancel];
}


//attempt to connect using the specified host, port and connection type
- (MCOIMAPSession*)tryIncomingConnectionOnPort:(NSInteger)port withEncryptionType:(MCOConnectionType)encryptionType
{
    [ThreadHelper ensureMainThread];

    if(!self.emailAddress || (!self.incomingPassword && !self.OAuth2Token) || !self.incomingUsername || !self.incomingHost)
        return nil;

    MCOIMAPSession* newSession = [MCOIMAPSession freshSession];
    [newSession setUsername:self.incomingUsername];
    [newSession setHostname:self.incomingHost];
    [newSession setPort:(unsigned int)port];
    [newSession setConnectionType:encryptionType];
    [newSession setPassword:self.incomingPassword];
    
    [newSession setOAuth2Token:self.OAuth2Token];

    [newSession setTimeout:TIMEOUT];

    [newSession setAuthType:self.incomingAuth?self.incomingAuth.intValue:(MCOAuthTypeSASLPlain|MCOAuthTypeSASLLogin)];

    /* Connection Logger */
    // [newSession setConnectionLogger:^(void * connectionID, MCOConnectionLogType type, NSData * data) { NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);}];
    
    MCOIMAPOperation* checkOperation = [newSession checkAccountOperation];
    [checkOperation start:^(NSError *error)
    {
        //if the operation was cancelled, ignore the result
        if(![self.activeIMAPConnections containsObject:newSession])
            return;

        if(error.code==MCOErrorAuthentication || error.code==MCOErrorAuthenticationRequired)
        {
            //try a different auth type
            if(self.incomingAuth.intValue & MCOAuthTypeSASLPlain)
                [newSession setAuthType:MCOAuthTypeSASLLogin];
            else
                [newSession setAuthType:MCOAuthTypeSASLLogin|MCOAuthTypeSASLPlain];

            MCOIMAPOperation* checkOperation = [newSession checkAccountOperation];
            [checkOperation start:^(NSError* error){
                [self returnFromIncomingConnectionWithError:error andSession:newSession];
            }];
        }
        else
            [self returnFromIncomingConnectionWithError:error andSession:newSession];
    }];

    return newSession;
}


/**
 Attempt to connect using the specified host, port and connection type
 */
- (MCOSMTPSession*)tryOutgoingConnectionOnPort:(NSInteger)port withEncryptionType:(MCOConnectionType)encryptionType
{
    [ThreadHelper ensureMainThread];

    if(!self.emailAddress || (!self.outgoingPassword && !self.OAuth2Token) || !self.outgoingUsername || !port)
    {
        return nil;
    }

    MCOSMTPSession* newSession = [MCOSMTPSession freshSession];
    [newSession setUsername:self.outgoingUsername];
    [newSession setHostname:self.outgoingHost];
    [newSession setPort:(unsigned int)port];
    [newSession setConnectionType:encryptionType];
    [newSession setPassword:self.outgoingPassword];
    
    [newSession setOAuth2Token:self.OAuth2Token];

    [newSession setTimeout:TIMEOUT];

    [newSession setAuthType:self.outgoingAuth?self.outgoingAuth.intValue:(MCOAuthTypeSASLLogin|MCOAuthTypeSASLPlain)];

    MCOAddress* fromAddress = [MCOAddress addressWithDisplayName:newSession.username mailbox:self.emailAddress];

    MCOSMTPOperation* checkOperation = [newSession checkAccountOperationWithFrom:fromAddress];
    [checkOperation start:^(NSError *error)
    {
        //if the operation was cancelled, ignore the result
        if(![self.activeSMTPConnections containsObject:newSession])
            return;

        if(error.code==MCOErrorAuthentication || error.code==MCOErrorAuthenticationRequired)
        {
            //try a different auth type
            if(self.outgoingAuth.intValue & MCOAuthTypeSASLPlain)
                [newSession setAuthType:MCOAuthTypeSASLLogin];
            else
                [newSession setAuthType:MCOAuthTypeSASLLogin|MCOAuthTypeSASLPlain];

            MCOSMTPOperation* checkOperation = [newSession checkAccountOperationWithFrom:fromAddress];
            [checkOperation start:^(NSError* error){
                [self returnFromOutgoingConnectionWithError:error andSession:newSession];
            }];
        }
        else
        {
            [self returnFromOutgoingConnectionWithError:error andSession:newSession];
        }
    }];

    return newSession;
}


/**
 Called when a connection attempt returns
 */
- (void)returnFromIncomingConnectionWithError:(NSError*)error andSession:(MCOIMAPSession*)session
{
    [ThreadHelper runAsyncOnMain:^{

        [self.activeIMAPConnections removeObject:session];

        if(error==nil && !self.IMAPSuccess)
        {
            [self setIMAPSuccess:YES];
            [self setIMAPError:nil];
            [self setIncomingPort:@(session.port)];
            [self setIncomingConnectionType:@(session.connectionType)];
            [self setIncomingAuth:@(session.authType)];
        }
        else
        {
            if(!self.IMAPError || [self errorPriority:self.IMAPError]<[self errorPriority:error])
                [self setIMAPError:error];
        }

        if((self.IMAPSuccess && self.SMTPSuccess) || (self.activeIMAPConnections.count == 0 && self.activeSMTPConnections.count == 0))
            [self doneWithImport];
    }];
}

/**
 Called when a connection attempt returns
 */
- (void)returnFromOutgoingConnectionWithError:(NSError*)error andSession:(MCOSMTPSession*)session
{
    [ThreadHelper runAsyncOnMain:^{

        [self.activeSMTPConnections removeObject:session];

        if(error==nil && !self.SMTPSuccess)
        {
            [self setSMTPSuccess:YES];
            [self setSMTPError:nil];
            [self setOutgoingPort:@(session.port)];
            [self setOutgoingConnectionType:@(session.connectionType)];
            [self setOutgoingAuth:@(session.authType)];
        }
        else
        {
            if(!self.SMTPError || [self errorPriority:self.SMTPError]<[self errorPriority:error])
                [self setSMTPError:error];
        }

        if((self.IMAPSuccess && self.SMTPSuccess) || (self.activeIMAPConnections.count == 0 && self.activeSMTPConnections.count == 0))
            [self doneWithImport];
    }];
}


/**
 Called when both incoming and outgoing connection attempts have returned success
 */
- (void)doneWithImport
{
    if(self.IMAPSuccess && self.SMTPSuccess)
    {
        [self setSourceOfData:ConnectionItemSourceOfDataTestedAndOK];

        [self showSuccess];

        [self cancelAllConnectionAttempts];
    }
    else if(self.IMAPError.code == self.SMTPError.code)
    {
        //imap and smtp error are identical, so just display the error
        [self showError:[MCODelegate reasonForError:self.IMAPError]];
    }
    else if([self errorPriority:self.IMAPError] >= [self errorPriority:self.SMTPError])
    {
        [self showError:[NSString stringWithFormat:NSLocalizedString(@"IMAP: %@", @"Connection item"), [MCODelegate reasonForError:self.IMAPError]]];
    }
    else
    {
        [self showError:[NSString stringWithFormat:NSLocalizedString(@"SMTP: %@", @"Connection item"), [MCODelegate reasonForError:self.SMTPError]]];
    }

    if(self.doneCallback)
        self.doneCallback();

    self.doneCallback = nil;
}


/**
 Higher priority errors take precendence over lower ones (if different settings are tried, the most specific/informative error should be returned to the user)
 E.g. if one connection cannot find the server and another one reports a wrong user name/password combination, then only the latter should be displayed to the user
 */
- (NSInteger)errorPriority:(NSError*)error
{
    switch (error.code)
    {
        case MCOErrorGmailExceededBandwidthLimit:
        case MCOErrorGmailIMAPNotEnabled:
        case MCOErrorGmailTooManySimultaneousConnections:
        case MCOErrorMobileMeMoved:
        case MCOErrorNeedsConnectToWebmail:
        case MCOErrorYahooUnavailable:
            return 4;

        case MCOErrorAuthentication:
        case MCOErrorAuthenticationRequired:
        case MCOErrorStartTLSNotAvailable:
        case MCOErrorTLSNotAvailable:
            return 3;

        case MCOErrorInvalidAccount:
            return 2;

        case MCOErrorCertificate:
        case MCOErrorCompression:
        case MCOErrorConnection:
        case MCOErrorIdentity:
        case MCOErrorParse:
            return 1;

        default:
            return 0;
            break;
    }
}


/**
 Try to connect using the specified settings only
 */
- (void)attemptSpecificImportWithCallback:(void(^)(void))callback
{
    if(self.IMAPSuccess && self.SMTPSuccess)
    {
        if(callback)
            callback();
        return;
    }

    if(self.emailAddress.length == 0)
    {
        [self showError:NSLocalizedString(@"Missing email address", @"Connection item")];

        if(callback)
            callback();
        return;
    }

    if(![self.emailAddress isValidEmailAddress])
    {
        [self showError:NSLocalizedString(@"Invalid email address", @"Connection item")];

        if(callback)
            callback();
        return;
    }

    if(!self.incomingHost.length || !self.outgoingHost.length)
    {
        [self showError:NSLocalizedString(@"Missing hostname", @"Connection item")];

        if(callback)
            callback();
        return;
    }

    if(!self.password && !self.OAuth2Token)
    {
        [self showError:NSLocalizedString(@"Please provide password", @"Connection item")];

        if(callback)
            callback();
        return;
    }

    [self cancelAndResetConnections];

    self.doneCallback = callback;

    [self showActive];

    if(!self.incomingUsername.length)
        [self setIncomingUsername:self.emailAddress];

    if(!self.outgoingUsername.length)
        [self setOutgoingUsername:self.emailAddress];

    //prevent premature abort due to race condition
    [self.activeIMAPConnections addObject:[NSNull null]];
    [self.activeSMTPConnections addObject:[NSNull null]];


    if(!self.incomingConnectionType.integerValue)
    {
        if(!self.incomingPort.integerValue)
        {
            MCOIMAPSession* newIMAPSession = [self tryIncomingConnectionOnPort:993 withEncryptionType:MCOConnectionTypeTLS];
            if(newIMAPSession)
                [self.activeIMAPConnections addObject:newIMAPSession];

            newIMAPSession = [self tryIncomingConnectionOnPort:143 withEncryptionType:MCOConnectionTypeTLS];
            if(newIMAPSession)
                [self.activeIMAPConnections addObject:newIMAPSession];



            newIMAPSession = [self tryIncomingConnectionOnPort:993 withEncryptionType:MCOConnectionTypeStartTLS];
            if(newIMAPSession)
                [self.activeIMAPConnections addObject:newIMAPSession];

            newIMAPSession = [self tryIncomingConnectionOnPort:143 withEncryptionType:MCOConnectionTypeStartTLS];
            if(newIMAPSession)
                [self.activeIMAPConnections addObject:newIMAPSession];
        }
        else
        {
            MCOIMAPSession* newIMAPSession = [self tryIncomingConnectionOnPort:self.incomingPort.integerValue withEncryptionType:MCOConnectionTypeTLS];
            if(newIMAPSession)
                [self.activeIMAPConnections addObject:newIMAPSession];

            newIMAPSession = [self tryIncomingConnectionOnPort:self.incomingPort.integerValue withEncryptionType:MCOConnectionTypeStartTLS];
            if(newIMAPSession)
                [self.activeIMAPConnections addObject:newIMAPSession];
        }
    }
    else
    {
        if(!self.incomingPort.integerValue)
        {
            MCOIMAPSession* newIMAPSession = [self tryIncomingConnectionOnPort:993 withEncryptionType:(MCOConnectionType)self.incomingConnectionType.integerValue];
            if(newIMAPSession)
                [self.activeIMAPConnections addObject:newIMAPSession];

            newIMAPSession = [self tryIncomingConnectionOnPort:143 withEncryptionType:(MCOConnectionType)self.incomingConnectionType.integerValue];
            if(newIMAPSession)
                [self.activeIMAPConnections addObject:newIMAPSession];
        }
        else
        {
            MCOIMAPSession* newIMAPSession = [self tryIncomingConnectionOnPort:self.incomingPort.integerValue withEncryptionType:(MCOConnectionType)self.incomingConnectionType.integerValue];
            if(newIMAPSession)
                [self.activeIMAPConnections addObject:newIMAPSession];
        }
    }

    if(!self.outgoingConnectionType.integerValue)
    {
        if(!self.outgoingPort.integerValue)
        {
            MCOSMTPSession* newSMTPSession = [self tryOutgoingConnectionOnPort:465 withEncryptionType:MCOConnectionTypeTLS];
            if(newSMTPSession)
                [self.activeSMTPConnections addObject:newSMTPSession];

            newSMTPSession = [self tryOutgoingConnectionOnPort:587 withEncryptionType:MCOConnectionTypeTLS];
            if(newSMTPSession)
                [self.activeSMTPConnections addObject:newSMTPSession];

            newSMTPSession = [self tryOutgoingConnectionOnPort:25 withEncryptionType:MCOConnectionTypeTLS];
            if(newSMTPSession)
                [self.activeSMTPConnections addObject:newSMTPSession];



            newSMTPSession = [self tryOutgoingConnectionOnPort:465 withEncryptionType:MCOConnectionTypeStartTLS];
            if(newSMTPSession)
                [self.activeSMTPConnections addObject:newSMTPSession];

            newSMTPSession = [self tryOutgoingConnectionOnPort:587 withEncryptionType:MCOConnectionTypeStartTLS];
            if(newSMTPSession)
                [self.activeSMTPConnections addObject:newSMTPSession];

            newSMTPSession = [self tryOutgoingConnectionOnPort:25 withEncryptionType:MCOConnectionTypeStartTLS];
            if(newSMTPSession)
                [self.activeSMTPConnections addObject:newSMTPSession];
        }
        else
        {
            MCOSMTPSession* newSMTPSession = [self tryOutgoingConnectionOnPort:self.outgoingPort.integerValue withEncryptionType:MCOConnectionTypeTLS];
            if(newSMTPSession)
                [self.activeSMTPConnections addObject:newSMTPSession];

            newSMTPSession = [self tryOutgoingConnectionOnPort:self.outgoingPort.integerValue withEncryptionType:MCOConnectionTypeStartTLS];
            if(newSMTPSession)
                [self.activeSMTPConnections addObject:newSMTPSession];
        }
    }
    else
    {
        if(!self.outgoingPort.integerValue)
        {
            MCOSMTPSession* newSMTPSession = [self tryOutgoingConnectionOnPort:465 withEncryptionType:(MCOConnectionType)self.outgoingConnectionType.integerValue];
            if(newSMTPSession)
                [self.activeSMTPConnections addObject:newSMTPSession];

            newSMTPSession = [self tryOutgoingConnectionOnPort:587 withEncryptionType:(MCOConnectionType)self.outgoingConnectionType.integerValue];
            if(newSMTPSession)
                [self.activeSMTPConnections addObject:newSMTPSession];

            newSMTPSession = [self tryOutgoingConnectionOnPort:25 withEncryptionType:(MCOConnectionType)self.outgoingConnectionType.integerValue];
            if(newSMTPSession)
                [self.activeSMTPConnections addObject:newSMTPSession];
        }
        else
        {
            MCOSMTPSession* newSMTPSession = [self tryOutgoingConnectionOnPort:self.outgoingPort.integerValue withEncryptionType:(MCOConnectionType)self.outgoingConnectionType.integerValue];
            if(newSMTPSession)
                [self.activeSMTPConnections addObject:newSMTPSession];
        }
    }


    [self.activeIMAPConnections removeObject:[NSNull null]];
    [self.activeSMTPConnections removeObject:[NSNull null]];


    if(self.activeIMAPConnections.count == 0 && self.activeSMTPConnections.count == 0)
        if(callback)
            callback();
}



/**
 Attempt to connect using the specified host and the most common combinations of ports & connection types
 */
- (void)attemptImportWithCallback:(void(^)(void))callback
{
    if(self.IMAPSuccess && self.SMTPSuccess)
    {
        if(callback)
            callback();
        return;
    }

    if(self.emailAddress.length == 0)
    {
        [self showError:NSLocalizedString(@"Missing email address", @"Connection item")];

        if(callback)
            callback();
        return;
    }

    if(![self.emailAddress isValidEmailAddress])
    {
        [self showError:NSLocalizedString(@"Invalid email address", @"Connection item")];

        if(callback)
            callback();
        return;
    }

    if(!self.incomingHost || !self.outgoingHost)
    {
        [self showError:NSLocalizedString(@"Missing hostname", @"Connection item")];

        if(callback)
            callback();
        return;
    }

    if(!self.password.length)
    {
        [self showError:NSLocalizedString(@"Please provide password", @"Connection item")];

        if(callback)
            callback();
        return;
    }

    //don't run this while there are still active connections
    if(self.activeIMAPConnections.count > 0 || self.activeSMTPConnections.count > 0)
    {
        return;
    }

    self.doneCallback = callback;

    [self showActive];

    if(!self.incomingUsername.length)
        [self setIncomingUsername:self.emailAddress];

    if(!self.outgoingUsername.length)
        [self setOutgoingUsername:self.emailAddress];

    //prevent premature abort due to race condition
    [self.activeIMAPConnections addObject:[NSNull null]];
    [self.activeSMTPConnections addObject:[NSNull null]];
    
    //if auth type is OAuth, we need an authenitcation token(!)
    NSInteger OAuthTypes = MCOAuthTypeXOAuth2 | MCOAuthTypeXOAuth2Outlook;
    if(((self.incomingAuth.integerValue & OAuthTypes) || (self.outgoingAuth.integerValue & OAuthTypes)) && !self.OAuth2Token)
    {
        //missing token
        if(callback)
            callback();
        return;
    }


    MCOIMAPSession* newIMAPSession = [self tryIncomingConnectionOnPort:993 withEncryptionType:MCOConnectionTypeTLS];
    if(newIMAPSession)
        [self.activeIMAPConnections addObject:newIMAPSession];

    newIMAPSession = [self tryIncomingConnectionOnPort:143 withEncryptionType:MCOConnectionTypeTLS];
    if(newIMAPSession)
        [self.activeIMAPConnections addObject:newIMAPSession];



    newIMAPSession = [self tryIncomingConnectionOnPort:993 withEncryptionType:MCOConnectionTypeStartTLS];
    if(newIMAPSession)
        [self.activeIMAPConnections addObject:newIMAPSession];

    newIMAPSession = [self tryIncomingConnectionOnPort:143 withEncryptionType:MCOConnectionTypeStartTLS];
    if(newIMAPSession)
        [self.activeIMAPConnections addObject:newIMAPSession];



    MCOSMTPSession* newSMTPSession = [self tryOutgoingConnectionOnPort:465 withEncryptionType:MCOConnectionTypeTLS];
    if(newSMTPSession)
        [self.activeSMTPConnections addObject:newSMTPSession];

    newSMTPSession = [self tryOutgoingConnectionOnPort:587 withEncryptionType:MCOConnectionTypeTLS];
    if(newSMTPSession)
        [self.activeSMTPConnections addObject:newSMTPSession];

    newSMTPSession = [self tryOutgoingConnectionOnPort:25 withEncryptionType:MCOConnectionTypeTLS];
    if(newSMTPSession)
        [self.activeSMTPConnections addObject:newSMTPSession];



    newSMTPSession = [self tryOutgoingConnectionOnPort:465 withEncryptionType:MCOConnectionTypeStartTLS];
    if(newSMTPSession)
        [self.activeSMTPConnections addObject:newSMTPSession];

    newSMTPSession = [self tryOutgoingConnectionOnPort:587 withEncryptionType:MCOConnectionTypeStartTLS];
    if(newSMTPSession)
        [self.activeSMTPConnections addObject:newSMTPSession];

    newSMTPSession = [self tryOutgoingConnectionOnPort:25 withEncryptionType:MCOConnectionTypeStartTLS];
    if(newSMTPSession)
        [self.activeSMTPConnections addObject:newSMTPSession];


    [self.activeIMAPConnections removeObject:[NSNull null]];
    [self.activeSMTPConnections removeObject:[NSNull null]];


    if(self.activeIMAPConnections.count == 0 && self.activeSMTPConnections.count == 0)
        if(callback)
            callback();
}



#pragma mark - UPDATE THE DATA


/**
 Checks the persistent refs and pulls the respective passwords from the keychain, if necessary
 */
- (void)pullPasswordFromKeychainWithCallback:(void(^)(void))callback
{
    //don't overwrite a user-provided password
    if(self.sourceOfPassword < ConnectionItemSourceOfPasswordUserProvided)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),

                       ^{
                           BOOL foundSomething = NO;

                           if(!self.incomingPassword)
                           {
                               NSString* result = [KeychainHelper passwordForPersistentRef:self.incomingPersistentRef];
                               if(result)
                               {
                                   [self setIncomingPassword:result];
                                   foundSomething = YES;
                               }
                           }

                           if(!self.outgoingPassword)
                           {
                               NSString* result = [KeychainHelper passwordForPersistentRef:self.outgoingPersistentRef];
                               if(result)
                                   [self setOutgoingPassword:result];
                           }

                           if(!foundSomething && self.emailAddress.length && self.incomingHost.length)
                           {
                               NSString* newPassword = [KeychainHelper findPasswordForEmail:self.emailAddress andServer:self.incomingHost];

                               if(newPassword)
                               {
                                   [self setIncomingPassword:newPassword];
                                   [self setOutgoingPassword:newPassword];

                                   foundSomething = YES;
                               }
                           }

                           dispatch_async(dispatch_get_main_queue(), ^{

                               if(foundSomething)
                                   if(self.sourceOfPassword < ConnectionItemSourceOfPasswordUserProvided && self.incomingPassword.length > 0)
                                   {
                                       [self setPassword:self.incomingPassword];
                                       [self setSourceOfPassword:ConnectionItemSourceOfPasswordKeychain];
                                   }

                               if(callback)
                                   callback();
                           });
                       });
    }
    else if(callback)
        callback();
}


/**
 Checks keychain and generates a refreshed accessToken, if possible
 */
- (void)pullOAuthTokenFromKeychainWithCallback:(void(^)(void))callback
{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
                       
                       ^{
                           
                           if(!self.OAuth2Token && self.emailAddress.length && self.OAuthProvider.length)
                           {
                               [OAuthHelper refreshAccessTokenForEmailAddress:self.emailAddress andProvider:self.OAuthProvider userInitiated:NO withCallback:^(NSString* accessToken){
                                   if (accessToken)
                                   {
                                       [self setOAuth2Token:accessToken];
                                   }
                                   
                                   
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       
                                       if(callback)
                                           callback();
                                   });
                                   
                               }];

                           }
                           else
                           {
                               dispatch_async(dispatch_get_main_queue(), ^{
                               
                                   if(callback)
                                       callback();
                               });
                           }

                       });
}



/**
 Update the connection settings using the specified MCOMailProvider
 */
- (BOOL)updateSettingsUsingMailProvider:(MCOMailProvider*)accountProvider source:(ConnectionItemSourceOfData)source
{
    BOOL returnValue = NO;

    if(accountProvider)
    {
        //don't overwrite the data if it's already been set by a more trustworthy source
        if(self.sourceOfData > source)
            return NO;

        self.sourceOfData = source;

        NSArray *imapServices = accountProvider.imapServices;
        if (imapServices.count != 0)
        {
            MCONetService *imapService = [imapServices objectAtIndex:0];
            [self setIncomingHost:imapService.hostname.lowercaseString];
            [self setIncomingPort:@(imapService.port)];
            switch(imapService.connectionType)
            {
                case MCOConnectionTypeClear: [self setIncomingConnectionType:@(MCOConnectionTypeClear)];
                    break;
                case MCOConnectionTypeStartTLS: [self setIncomingConnectionType:@(MCOConnectionTypeStartTLS)];
                    break;
                case MCOConnectionTypeTLS: [self setIncomingConnectionType:@(MCOConnectionTypeTLS)];
                    break;
            }

            returnValue = YES;
        }

        NSArray* smtpServices = accountProvider.smtpServices;
        if (smtpServices.count != 0)
        {
            MCONetService *smtpService = [smtpServices objectAtIndex:0];
            if(![self.outgoingHost.lowercaseString isEqual:smtpService.hostname.lowercaseString])
            {
                [self setOutgoingHost:smtpService.hostname.lowercaseString];

                //if the hostname is changed, the user name must also be reset
                //after all, the Apple Mail settings file may have set an SMTP connection that actually corresponds to a different account
                [self setOutgoingUsername:self.emailAddress];
            }
            [self setOutgoingPort:@(smtpService.port)];
            switch(smtpService.connectionType)
            {
                case MCOConnectionTypeClear: [self setOutgoingConnectionType:@(MCOConnectionTypeClear)];
                    break;
                case MCOConnectionTypeStartTLS: [self setOutgoingConnectionType:@(MCOConnectionTypeStartTLS)];
                    break;
                case MCOConnectionTypeTLS: [self setOutgoingConnectionType:@(MCOConnectionTypeTLS)];
                    break;
            }

            returnValue = YES;
        }
    }

    return returnValue;
}

- (void)lookForSettingsWithCallback:(void(^)(void))callback
{
    NSString* email = [self emailAddress];

    if(email.length)
    {
        [self performProvidersPlistLookupWithCallback:^(BOOL foundSomething)
         {
             if(foundSomething)
             {
                 if(callback)
                     callback();
             }
             else
             {
                 [self performMXLookupWithCallback:^(BOOL foundSomething)
                  {

                      if(callback)
                          callback();
                  }];
             }
         }];
    }
    else if(callback)
        callback();
}


#pragma mark - UPDATE (PROVIDERS PLIST)

- (void)performProvidersPlistLookupWithCallback:(void(^)(BOOL foundSomething))callback
{
    NSString* email = [self emailAddress];

    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

        BOOL foundSomething = NO;

        if(self.sourceOfData < ConnectionItemSourceOfDataProvidersJSON)
        {
            MCOMailProvider *accountProvider = [MCOMailProvidersManager.sharedManager providerForEmail:email];

            if (!accountProvider)
            {

                //NSLog(@"No provider available for email: %@", email);

                NSArray* emailComponents = [email componentsSeparatedByString:@"@"];

                NSString* incomingServer = [NSString stringWithFormat:@"imap.%@", emailComponents.lastObject];
                NSString* outgoingServer = [NSString stringWithFormat:@"smtp.%@", emailComponents.lastObject];

                //only change if no values are provided, irrespective of the source of the data...
                if(!self.incomingHost.length)
                    [self setIncomingHost:incomingServer];

                if(!self.outgoingHost.length)
                    [self setOutgoingHost:outgoingServer];

                if(self.sourceOfData < ConnectionItemSourceOfDataGuessed)
                    self.sourceOfData = ConnectionItemSourceOfDataGuessed;
            }
            else
            {
                if([self updateSettingsUsingMailProvider:accountProvider source:ConnectionItemSourceOfDataProvidersJSON])
                    foundSomething = YES;
            }
        }

        if(callback)
            [ThreadHelper runAsyncOnMain:^{
                callback(foundSomething);
            }];
    }];
}


#pragma mark - UPDATE (MX LOOKUP)

+ (NSArray*)MXRecordsForHostname:(NSString*)hostString
{
    return VTMxRecordForHostname(hostString);
}

- (void)performMXLookupWithCallback:(void(^)(BOOL foundSomething))callback
{
    NSArray* emailComponents = [self.emailAddress componentsSeparatedByString:@"@"];
    NSString* hostname = emailComponents.lastObject;

    if(!hostname)
    {
        if(callback)
            callback(NO);

        return;
    }

    __block BOOL foundSomething = NO;

    if (self.sourceOfData < ConnectionItemSourceOfDataMXRecord)
    {
        [self performMXLookupForHost:hostname withCallback:^(NSString* mxRecord) {

            if(mxRecord)
            {
                MCOMailProvider* accountProvider = [[MCOMailProvidersManager sharedManager] providerForMX:mxRecord];

                if([self updateSettingsUsingMailProvider:accountProvider source:ConnectionItemSourceOfDataMXRecord])
                    foundSomething = YES;
            }

            if(callback)
            {
                [ThreadHelper runAsyncOnMain:^{
                    callback(foundSomething);
                }];
            }
        }];
    }
    else [ThreadHelper runAsyncOnMain:^{
        callback(NO);
    }];

    
}

//for better testing refactored
- (void) performMXLookupForHost:(NSString*)hostString withCallback:(void(^)(NSString* mxHost))callback{

    if(!hostString)
    {
        if(callback)
            callback(nil);
        return;
    }

    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

        NSString * mxRecord = [[ConnectionItem MXRecordsForHostname:hostString] firstObject];

//        if(mxRecord)
            if(callback)
            {
                [ThreadHelper runAsyncOnMain:^{
                    callback(mxRecord);
                }];
            }
    }];
}


#pragma mark - UPDATE PASSWORDS

/**
 Called whenever the password is changed - either by bindings or explicitly
 */
- (void)setPassword:(NSString *)password
{
    //make sure the connection feedback no longer reports connection success
    if(self.sourceOfData == ConnectionItemSourceOfDataTestedAndOK)
        [self setSourceOfData:ConnectionItemSourceOfDataAlreadySetUp];

    //don't bother changing the password if it's nil & empty, respectively
    if(_password.length == 0 && password.length == 0)
        return;

    if(![_password isEqual:password])
    {
        _password = password;

        //the password value was changed
        //probably by the user
        self.sourceOfPassword = ConnectionItemSourceOfPasswordUserProvided;

        //update the values for incoming and outgoing connections
        [self setIncomingPassword:password];
        [self setOutgoingPassword:password];

        [self cancelAndResetConnections];

        if(self.changeCallback)
            self.changeCallback();
    }
}

/**
 Called whenever the email address is changed - either by bindings or explicitly
 */
- (void)setEmailAddress:(NSString *)emailAddress
{
    //the email address value was changed
    if(![_emailAddress isEqual:emailAddress])
    {
        _emailAddress = emailAddress;

        //the source of data is undefined, unless otherwise specified
        //of course the email address is probably user provided, but the data we are interested in are the connection settings (hostname etc...)
        self.sourceOfData = ConnectionItemSourceOfDataUndefined;

        [self showInactive];

        if(![self isSuccessfullyImported])
            [self cancelAndResetConnections];

        if(self.changeCallback)
            self.changeCallback();

        //don't start any connection attempts
        //the connection item doesn't know if it should attempt a specific or a general import
    }
}

/**
 Called whenever the OAuth token is changed - either by bindings or explicitly
 */
- (void)setOAuth2Token:(NSString *)OAuth2Token
{
    //the email address value was changed
    if(![_OAuth2Token isEqual:OAuth2Token])
    {
        _OAuth2Token = OAuth2Token;
        
        //the OAuth token was changed
        //probably by the user
        self.sourceOfPassword = ConnectionItemSourceOfPasswordUserProvided;
        
        [self cancelAndResetConnections];
        
        if(self.changeCallback)
            self.changeCallback();
    }
}


- (void)clear
{
    [self setIncomingUsername:nil];
    [self setOutgoingUsername:nil];

    [self setIncomingHost:nil];
    [self setOutgoingHost:nil];
}


#pragma mark - ERROR BUTTON

- (NSAttributedString*)errorButtonTitleWithText:(NSString*)text enableLink:(BOOL)linkEnabled
{
    if(linkEnabled)
    {
        NSMutableAttributedString* attributedTitle = [[NSMutableAttributedString alloc] initWithString:text attributes:@{}];

        NSRange range = NSMakeRange(0, attributedTitle.length);

        [attributedTitle addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:range];
        [attributedTitle addAttribute:NSForegroundColorAttributeName value:DARKISH_BLUE_COLOUR range:range];

#if TARGET_OS_IPHONE

        [attributedTitle addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:[UIFont systemFontSize]] range:range];

#else

        [attributedTitle addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:[NSFont systemFontSize]] range:range];
        [attributedTitle addAttribute:NSCursorAttributeName value:[NSCursor pointingHandCursor] range:range];

#endif



        //        NSMutableParagraphStyle *paragrapStyle = [NSMutableParagraphStyle new];
        //        paragrapStyle.alignment = NSRightTextAlignment;
        //
        //        [attributedTitle addAttribute:NSParagraphStyleAttributeName value:paragrapStyle range:range];

        return attributedTitle;
    }
    else
    {
        NSMutableAttributedString* attributedTitle = [[NSMutableAttributedString alloc] initWithString:text attributes:@{}];

        NSRange range = NSMakeRange(0, attributedTitle.length);

        [attributedTitle addAttribute:NSForegroundColorAttributeName value:[COLOUR lightGrayColor] range:range];

#if TARGET_OS_IPHONE

        [attributedTitle addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:[UIFont systemFontSize]] range:range];

#else

        [attributedTitle addAttribute:NSCursorAttributeName value:[NSCursor arrowCursor] range:range];
        [attributedTitle addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:[NSFont systemFontSize]] range:range];

#endif


        //        NSMutableParagraphStyle *paragrapStyle = [NSMutableParagraphStyle new];
        //        paragrapStyle.alignment = NSRightTextAlignment;
        //
        //        [attributedTitle addAttribute:NSParagraphStyleAttributeName value:paragrapStyle range:range];

        return attributedTitle;
    }
}


#pragma mark - DESCRIPTION

- (NSString*)description
{
    return [NSString stringWithFormat:@"\n=== CONNECTION ITEM ===\n\nEmail address: %@\n\nINCOMING\nServer:%@\nUser name:%@\nPassword:%ld chars\nPort:%@\nType:%@\nAuth:%@\n\nOUTGOING:\nServer:%@\nUser name:%@\nPassword:%ld chars\nPort:%@\nType:%@\nAuth:%@\n=======================", self.emailAddress, self.incomingHost, self.incomingUsername, (unsigned long)self.incomingPassword.length, self.incomingPort, self.incomingConnectionType, self.incomingAuth, self.outgoingHost, self.outgoingUsername, (unsigned long)self.outgoingPassword.length, self.outgoingPort, self.outgoingConnectionType, self.outgoingAuth];
}

//needed for isEqual
- (NSUInteger)hash
{
    //doesn't use the passwords, but that's ok...
    return [self.description hash];
}

//compare the settings of two connection items
//used mainly by unit tests
- (BOOL)isEqual:(ConnectionItem*)object
{
    if(![object isKindOfClass:[ConnectionItem class]])
        return NO;

    if(![self.description isEqualToString:object.description])
        return NO;

    if(self.password)
    {
        if(![self.password isEqualToString:object.password])
            return NO;
    }
    else
    {
        if(object.password)
            return NO;
    }

    if(self.incomingPassword)
    {
        if(![self.incomingPassword isEqualToString:object.incomingPassword])
            return NO;
    }
    else
    {
        if(object.incomingPassword)
            return NO;
    }

    if(self.outgoingPassword)
    {
        if(![self.outgoingPassword isEqualToString:object.outgoingPassword])
            return NO;
    }
    else
    {
        if(object.outgoingPassword)
            return NO;
    }

    return YES;
}


#pragma mark - STATUS QUERIES

- (BOOL)isImporting
{
    return self.activeIMAPConnections.count + self.activeSMTPConnections.count > 0;
}

- (BOOL)showsError
{
    return ![self isImporting] && ![self isSuccessfullyImported];
}

- (BOOL)isSuccessfullyImported
{
    return self.sourceOfData == ConnectionItemSourceOfDataTestedAndOK;
}

- (BOOL)canUseOAuth
{
    NSString* host = self.incomingHost;

//TO DO: change we have when yahoo api key
// no yahoo api key yet...
//    return ([host isEqual:@"imap.gmail.com"] ||
//            [host isEqual:@"imap.mail.yahoo.com"] ||
//            [host isEqual:@"imap.mail.yahoo.co.jp"] ||
//            [host isEqual:@"imap-mail.outlook.com"]);
    
    return ([host isEqual:@"imap.gmail.com"] ||
            [host isEqual:@"imap-mail.outlook.com"]);
}


#pragma mark - CHANGE STATUS

- (void)showError:(NSString*)error
{
    [self setIsCancelled:NO];
    
    [self setFeedbackString:[self errorButtonTitleWithText:error enableLink:YES]];
    [self setFeedbackIconIndex:1];
    
    if(self.changeCallback)
        self.changeCallback();
}

- (void)showSuccess
{
    [self setIsCancelled:NO];
    
    [self setFeedbackString:[self errorButtonTitleWithText:NSLocalizedString(@"Settings correct", @"Connection item") enableLink:NO]];
    [self setFeedbackIconIndex:3];
    
    if(self.changeCallback)
        self.changeCallback();
}

- (void)showUserCancel
{
    [self setIsCancelled:YES];
    
    [self setFeedbackString:[self errorButtonTitleWithText:NSLocalizedString(@"Cancelled", @"Connection item") enableLink:YES]];
    [self setFeedbackIconIndex:1];
    
    if(self.changeCallback)
        self.changeCallback();
}

- (void)showInactive
{
    [self setIsCancelled:NO];
    
    [self setFeedbackIconIndex:0];
    [self setFeedbackString:[self errorButtonTitleWithText:NSLocalizedString(@"Check connection", nil) enableLink:YES]];
    if(self.changeCallback)
        self.changeCallback();
}

- (void)showActive
{
    [self setIsCancelled:NO];
    
    [self setFeedbackIconIndex:2];
    [self setFeedbackString:[self errorButtonTitleWithText:NSLocalizedString(@"Testing connection...", nil) enableLink:YES]];
    
    if(self.changeCallback)
        self.changeCallback();
}

- (void)showEmptyFeedback
{
    [self setIsCancelled:NO];

    [self setFeedbackIconIndex:0];
    [self setFeedbackString:[self errorButtonTitleWithText:@"" enableLink:NO]];
    if(self.changeCallback)
        self.changeCallback();
}


- (NSString*)OAuthProvider
{
    NSString* host = self.incomingHost;
    
    if([host isEqual:@"imap.gmail.com"])
        return @"Google";
    
    if([host isEqual:@"imap-mail.outlook.com"])
        return @"Outlook";
    
    return nil;
}

@end