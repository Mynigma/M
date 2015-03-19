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

#import "ServerHelper.h"
#import "IMAPAccountSetting+Category.h"
#import "EncryptionHelper.h"
#import "UserSettings.h"
#import "EmailContactDetail+Category.h"
#import "Recipient.h"
#import "IMAPAccount.h"
#import "MynigmaPublicKey.h"
#import "EncryptionHelper.h"
#import "PublicKeyManager.h"
#import "KeychainHelper.h"
#import "AppleEncryptionWrapper.h"
#import "NSData+Base64.h"
#import "MynigmaPublicKey+Category.h"
#import "NSString+EmailAddresses.h"
#import "AlertHelper.h"
#import "UserSettings+Category.h"




/*=========================================
 
Ultimate version only: Public key server interaction

Not used in App Store versions

=========================================*/


//prevents the sign-up
static NSNumber* isConfirmingSignupGuard;

static ServerHelper* theServerHelper;

@implementation ServerHelper

@synthesize receivedData;
@synthesize callbackCopy;

+ (ServerHelper*)sharedInstance
{
    if(!theServerHelper)
    {
        theServerHelper = [ServerHelper new];
    }
    return theServerHelper;
}

+ (void)setSharedInstance:(ServerHelper *)instance
{
    theServerHelper = instance;
}

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}


#pragma mark - NSURLConnection Delegate Methods



- (void)connection:(NSURLConnection *)conn willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{

    /* Load remote trust/cert */
    NSURLProtectionSpace *protectionSpace   = [challenge protectionSpace];
    assert(protectionSpace);
    SecTrustRef trust                       = [protectionSpace serverTrust];
    assert(trust);
    CFRetain(trust);  // Make sure this thing stays around until we're done with it
    NSURLCredential *credential             = [NSURLCredential credentialForTrust:trust];


    /* Load lokal cert */
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ca" ofType:@"der"];
    assert(path);
    NSData *data = [NSData dataWithContentsOfFile:path];
    assert(data);

    SecCertificateRef rootcert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(data));
    /* Set up the array of certs we will authenticate against and create cred */
    CFMutableArrayRef certs = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
    CFArrayAppendValue(certs, rootcert);

    // Set anchor cert
    /* Build up the trust anchor using our root cert */
    __block int err;
    err = SecTrustSetAnchorCertificates(trust, certs);
    SecTrustSetAnchorCertificatesOnly(trust, YES); // only use that certificate
    CFRelease(certs);

    if (err == noErr) {
        err = SecTrustEvaluateAsync(trust,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND,0), ^(SecTrustRef trustRef, SecTrustResultType res){

            BOOL trusted = NO;

            switch (res)
            {
                case kSecTrustResultProceed:
                case kSecTrustResultUnspecified: //This will usually occur: the anchor cert is not added as "Always trust" in the keychain, so unspecified is the best we can hope for. It signifies that the user did not specify a trust setting, but the cert provided by the server was otherwise OK.
                    /*deprecated: case kSecTrustResultConfirm:*/
                    trusted = YES;
                    break;
                    
                case kSecTrustResultConfirm:
                case kSecTrustResultDeny:
                case kSecTrustResultFatalTrustFailure:
                case kSecTrustResultInvalid:
                case kSecTrustResultOtherError:
                case kSecTrustResultRecoverableTrustFailure:
                    NSLog(@"SSL trust failure: %ld", (long)res);
                    break;
            }

            CFRelease(rootcert); // for completeness, really does not matter

            BOOL trusted2 = ((err == noErr) && (trusted));

            // Return based on whether we decided to trust or not
            if (trusted2) {
                //NSLog(@"Trust established");
                [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
            } else {
                NSLog(@"Trust evaluation failed for service root certificate, with error code %d",res);
                [[challenge sender] cancelAuthenticationChallenge:challenge];
            }
            CFRelease(trust);// OK, now we're done with it
        });
    }

}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    callbackCopy(nil, error);
    NSLog(@"Connection failed: %@", [error description]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    //Getting your response dict
    NSError* error = nil;

    NSDictionary* result = [NSPropertyListSerialization propertyListWithData:receivedData options:NSPropertyListImmutable format:NULL error:&error];
    if(error || !result)
    {
        NSLog(@"Error serialising server response: %@",[[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding]);
        callbackCopy(nil, error);
    }
    else
    {
        callbackCopy(result, error);
    }
}


#pragma mark - Connection process


- (void)sendArrayToServer:(NSArray*)array withCallback:(void(^)(NSDictionary*, NSError*))callback
{
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString* currentVersion = [infoDict objectForKey:@"CFBundleVersion"];

    //this is the last version that the server reported to be out of date. if the current version is not more recent no contact should be made with the server
    NSString* lastCorruptVersion = [UserSettings currentUserSettings].lastCorruptVersion;

    if(currentVersion && lastCorruptVersion && [lastCorruptVersion compare:currentVersion]!=NSOrderedAscending)
    {
        NSLog(@"No connection made with server - version too old!! Current: %@, last corrupt one: %@", currentVersion, lastCorruptVersion);
        return;
    }

    __block void(^newCallback)(NSDictionary* dict, NSError* error) = callback;

    [MAIN_CONTEXT performBlock:^{
        NSError* error = nil;

        //prefix the current version
        NSMutableArray* dataArray = [NSMutableArray arrayWithObject:currentVersion];
        [dataArray addObjectsFromArray:array];

        //NSLog(@"Request array: %@", dataArray);

        NSData* requestData = [NSPropertyListSerialization dataWithPropertyList:dataArray format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
        if(error)
        {
            NSLog(@"Could not serialise array: %@",array);
            return;
        }

        NSURL* url = [NSURL URLWithString:@"https://mynigma.info/Request_v1_6.php"];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url]; //Add cache policy...

        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:requestData];

        //NSURLConnection *connection = [NSURLConnection new];

        /* Creating a new Delegate Instance declare instance variable Data and Callback */
        ServerHelper* newDelegate = [ServerHelper new];
        [newDelegate setReceivedData:[NSMutableData new]];
        [newDelegate setCallbackCopy:newCallback];

        //connection =
        [NSURLConnection connectionWithRequest:request delegate:newDelegate];
    }];
}



- (void)sendArrayToLicenceServer:(NSArray*)array withCallback:(void(^)(NSDictionary*, NSError*))callback
{
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString* currentVersion = [infoDict objectForKey:@"CFBundleVersion"];

    __block void(^newCallback)(NSDictionary* dict, NSError* error) = callback;

    [MAIN_CONTEXT performBlock:^{
        NSError* error = nil;

        //prefix the current version
        NSMutableArray* dataArray = [NSMutableArray arrayWithObject:currentVersion];
        [dataArray addObjectsFromArray:array];

        //NSLog(@"Request array: %@", dataArray);

        NSData* requestData = [NSPropertyListSerialization dataWithPropertyList:dataArray format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
        if(error)
        {
            NSLog(@"Could not serialise array: %@",array);
            return;
        }

        NSURL* url = [NSURL URLWithString:@"https://mynigma.info/Licence_v_1_0.php"];

        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url]; //Add cache policy...

        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:requestData];

        //NSURLConnection *connection = [NSURLConnection new];

        /* Creating a new Delegate Instance declare instance variable Data and Callback */
        ServerHelper* newDelegate = [ServerHelper new];
        [newDelegate setReceivedData:[NSMutableData new]];
        [newDelegate setCallbackCopy:newCallback];

        //connection =
        [NSURLConnection connectionWithRequest:request delegate:newDelegate];
    }];
}



- (BOOL)handleServerResponse:(NSDictionary*)dict withError:(NSError*)error;
{
    __block BOOL returnValue = NO;

    [ThreadHelper runSyncOnMain:^{

        if(error)
        {
            NSLog(@"Error returned from server: %@",error);
        }
        else
        {
            NSString* response = [dict objectForKey:@"response"];

            //NSLog(@"Server response: %@", response);

            if(response)
            {
                if([response isEqualToString:@"FORCE_UPDATE"])
                {
                    NSString* oldVersion = [dict objectForKey:@"old_version"];
                    if(!oldVersion)
                    {
                        NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
                        oldVersion = [infoDict objectForKey:@"CFBundleVersion"];
                    }
                    [[UserSettings currentUserSettings] setLastCorruptVersion:oldVersion];
                    [CoreDataHelper save];
                }
                else if([response isEqualToString:@"REQUIRE_LICENSE"])
                {

                }
                else if([response isEqualToString:@"SERVER_BUSY"])
                {

                }
                else if([response isEqualToString:@"WRONG_TOKEN"])
                {

                }
                else if([response isEqualToString:@"ALREADY_SIGNED_UP"])
                {
                    returnValue = YES;
                }
                else if([response isEqualToString:@"OK"])
                {
                    returnValue = YES;
                }
                else
                {

                }

                if(returnValue)
                {
                    //now add, update and remove public keys where necessary
                    NSDictionary* addList = [dict objectForKey:@"add"];
                    NSDictionary* updateList = [dict objectForKey:@"update"];
                    NSDictionary* removeList = [dict objectForKey:@"remove"];

                    for(NSString* email in [addList allKeys])
                    {
                        NSArray* record = [addList objectForKey:email];

                        [PublicKeyManager serverSaysAddKey:record forEmailAddress:email];

                    }

                    for(NSString* email in [updateList allKeys])
                    {
                        NSArray* record = [addList objectForKey:email];

                        [PublicKeyManager serverSaysReplaceKey:record forEmailAddress:email];

                    }


                    for(NSString* email in [removeList allKeys])
                    {
                        NSArray* record = [removeList objectForKey:email];

                        [PublicKeyManager serverSaysRevokeKey:record forEmailAddress:email];

                    }

                    [CoreDataHelper save];

                    //TO DO: implement key update and deletion mechanism
                }
            }
        }
    }];
    return returnValue;
}



//sign an array containing details of data requested before it is sent to the server
- (NSString*)signedHashOfRequestArray:(NSArray*)requestArray withKeyLabel:(NSString*)keyLabel
{
    if(!keyLabel)
        return nil;

    NSMutableString* requestString = [NSMutableString new];
    for(NSString* stringComponent in requestArray)
    {
        [requestString appendString:stringComponent];
    }

    NSData* requestStringData = [requestString dataUsingEncoding:NSUTF8StringEncoding];

    NSData* hashedRequestStringData = [AppleEncryptionWrapper SHA512DigestOfData:requestStringData];

    NSData* signedHashedRequestStringData = [EncryptionHelper signHash:hashedRequestStringData withKeyWithLabel:keyLabel withFeedback:nil];

    if(!signedHashedRequestStringData)
        return nil;

    NSString* returnValue = [signedHashedRequestStringData base64];

    return returnValue;
}

- (void)sendRequestToServer:(NSMutableArray*)requestArray withKeyLabel:(NSString*)keyLabel andCallback:(void(^)(NSDictionary* result, NSError* error))callback
{
    if(!keyLabel)
    {
        NSLog(@"No keyLabel to sign request with!!");
        return;
    }

    NSString* signedHashOfRequestString = [SERVER signedHashOfRequestArray:requestArray withKeyLabel:keyLabel];

    if(!signedHashOfRequestString)
    {
        NSLog(@"Hashed and signed request string is nil!");
        return;
    }

    [requestArray addObject:signedHashOfRequestString];

    //NSLog(@"Sending array to server: %@", requestArray);

    [SERVER sendArrayToServer:requestArray withCallback:[^(NSDictionary* result, NSError* error){
        [SERVER handleServerResponse:result withError:error];
        //NSLog(@"Response: %@", result);
        if(callback)
            callback(result, error);
    } copy]];
}

- (void)sendRemoveRequestToServerWithAccount:(IMAPAccountSetting*)accountSetting andCallback:(void(^)(NSDictionary* result, NSError* error))callback
{
    NSString* currentKeyLabel = accountSetting.currentPrivateKeyLabel;
    if(accountSetting)
    {
        NSMutableArray* requestArray = [NSMutableArray arrayWithArray:@[@"REMOVE_ALL_RECORDS",accountSetting.emailAddress.canonicalForm]];

        [SERVER sendRequestToServer:requestArray withKeyLabel:currentKeyLabel andCallback:[^(NSDictionary *result, NSError* error) {
            if(callback)
                callback(result, error);
        } copy]];

    }
    else
        NSLog(@"No account setting passed to request!!!");
    return;
}


+ (NSString*)hashOfEmailAddress:(NSString*)address
{
    NSString* prefix = @"Myngima94&83**3)?~0";
    
    NSString* stringToBeHashed = [prefix stringByAppendingString:address];
    NSData* dataToBeHashed = [stringToBeHashed dataUsingEncoding:NSUTF8StringEncoding];
    NSData* hashedData = [AppleEncryptionWrapper SHA512DigestOfData:dataToBeHashed];
    NSString* base64Representation = [hashedData base64];

    return base64Representation;
}


#pragma mark -
#pragma mark Specific server request methods

- (void)sendRecipientsToServer:(NSArray *)recipients forAccount:(IMAPAccountSetting*)accountSett withCallback:(void(^)(NSDictionary*, NSError*))callback
{
    if(!accountSett.shouldUse.boolValue)
        return;

    __block IMAPAccountSetting* accountSetting = accountSett;
    [MAIN_CONTEXT performBlock:^{
        if(accountSetting)
        {
            NSString* currentKeyLabel = accountSetting.currentPrivateKeyLabel;
            if(currentKeyLabel)
            {
                if(accountSetting.hasBeenVerified.boolValue)
                {
                NSMutableArray* requestArray = [NSMutableArray arrayWithArray:@[@"CONTACTS",accountSetting.emailAddress.canonicalForm]];
                
                //hash those contacts
                NSArray* hashedEmailAddressesArray = [self hashContacts:[recipients valueForKey:@"displayEmail"]];

                [requestArray addObjectsFromArray:hashedEmailAddressesArray];

                [SERVER sendRequestToServer:requestArray withKeyLabel:currentKeyLabel andCallback:
                 [^(NSDictionary* dict, NSError* error) {

                    [ThreadHelper runSyncOnMain:^{

                        if(!error)
                        {
                            if([dict objectForKey:@"response"])
                            {
                                for(Recipient* rec in recipients)
                                {
                                    //not necessary: the email contact detail is created before the address is sent to the server:
                                    //[rec makeEmailContactDetailIfNecessary];
                                    EmailContactDetail* detail = [EmailContactDetail emailContactDetailForAddress:rec.displayEmail];
                                    if(!detail)
                                    {
                                        NSLog(@"Error: no email contact detail could be created!!!");
                                    }
                                    else
                                    {
                                        [detail setSentToServer:[NSNumber numberWithBool:YES]];
                                        [detail setLastCheckedWithServer:[NSDate new]];
                                    }
                                }

                                //[self handleServerResponse:dict withError:error];
                                if(callback)
                                    callback(dict, error);
                            }
                        }
                        else
                            NSLog(@"Response from server: %@, error: %@",dict,error);
                    }];
                } copy]];
            }
                else
                {
                    NSLog(@"Cannot check new contacts with server: not verified!!");
                }
            }
            else
            {
                NSLog(@"Cannot check new contacts with server: no current key label!!");
            }
        }
        else
            NSLog(@"Cannot check new contacts with server: invalid account setting!!");
    }];
}

- (void)sendRecipientToServer:(Recipient*)recipient forAccount:(IMAPAccountSetting*)accountSett withCallback:(void(^)(NSDictionary*, NSError*))callback;
{
    if(!accountSett.shouldUse.boolValue)
        return;

    __block Recipient* rec = recipient;
    __block IMAPAccountSetting* accountSetting = accountSett;
    [ThreadHelper runAsyncOnMain:[^{
        if(accountSetting)
        {
            NSString* currentKeyLabel = accountSetting.currentPrivateKeyLabel;
            if(currentKeyLabel)
            {
                if(accountSetting.hasBeenVerified.boolValue)
                {
                    NSMutableArray* requestArray = [NSMutableArray arrayWithArray:@[@"CONTACTS",accountSetting.emailAddress.canonicalForm]];
                    
                    //hash those contacts
                    NSArray* hashedEmailAddressesArray = [self hashContacts:@[recipient.displayEmail]];

                    [requestArray addObjectsFromArray:hashedEmailAddressesArray];

                    [SERVER sendRequestToServer:requestArray withKeyLabel:currentKeyLabel andCallback:[^(NSDictionary* dict, NSError* error) {

                        [ThreadHelper runSyncOnMain:^{

                            if(!error)
                            {
                                if([dict objectForKey:@"response"])
                                {
                                    //[rec makeEmailContactDetailIfNecessary];
                                    EmailContactDetail* detail = [EmailContactDetail emailContactDetailForAddress:rec.displayEmail];
                                    if(!detail)
                                    {
                                        NSLog(@"Error: no email contact detail could be created!!!");
                                    }
                                    else
                                    {
                                        [detail setSentToServer:[NSNumber numberWithBool:YES]];
                                        [detail setLastCheckedWithServer:[NSDate new]];
                                    }
                                }

                                [self handleServerResponse:dict withError:error];
                                if(callback)
                                    callback(dict, error);
                            }
                            else
                            {
                                if(callback)
                                    callback(dict, error);
                                NSLog(@"Response from server: %@, error: %@",dict,error);
                            }
                        }];
                    } copy]];
                }
                else
                    NSLog(@"Cannot check new contacts with server - hasBeenVerified is NO!!");
            }
            else
            {
                NSLog(@"Cannot check new contacts with server: no current key pair!!! (2)");

            }
        }
        else
        {
            NSLog(@"Cannot check new contacts with server: invalid account setting!!");
        }
    } copy]];

}



- (void)confirmSignUpForAccount:(IMAPAccountSetting*)accountSetting withToken:(NSString*)token andCallback:(void (^)(NSDictionary *, NSError *))callback
{
    [self confirmSignUpForAccount:accountSetting andBypassGuard:NO withToken:token andCallback:callback];
}

- (void)confirmSignUpForAccount:(IMAPAccountSetting*)accountSetting andBypassGuard:(BOOL)byPassGuard withToken:(NSString*)token andCallback:(void (^)(NSDictionary *, NSError *))callback
{
    NSString* emailAddress = [accountSetting.emailAddress canonicalForm];

    NSString* currentKeyLabel = accountSetting.currentPrivateKeyLabel;

    if(!currentKeyLabel)
    {
        callback(nil, nil);
        NSLog(@"No current keyLabel!!!");
        return;
    }

    NSArray* pemDataPair = [MynigmaPublicKey dataForExistingMynigmaPublicKeyWithLabel:currentKeyLabel];

    if(pemDataPair.count<2)
    {
        callback(nil, [NSError errorWithDomain:@"ConfirmSignUp" code:11 userInfo:nil]);
        NSLog(@"No PEM data for key pair");
        return;
    }
    NSData* encryptionPEM = pemDataPair[0];

    NSData* signingPEM = pemDataPair[1];

    NSString* encryptionPEMString = [[NSString alloc] initWithData:encryptionPEM encoding:NSUTF8StringEncoding];

    NSString* signingPEMString = [[NSString alloc] initWithData:signingPEM encoding:NSUTF8StringEncoding];

    if(!byPassGuard)
    {
    @synchronized(@"CONFIRM_SIGNUP")
    {
        if([isConfirmingSignupGuard isEqualTo:@YES])
        {
            callback(nil, nil);
            return;
        }
        isConfirmingSignupGuard = @YES;
    }
    }

    if(!emailAddress || !token || !encryptionPEMString || !signingPEMString)
    {
        callback(nil, nil);
        return;
    }

    // get current language code
    NSString* languageCode = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];

    [SERVER sendArrayToServer:@[@"CONFIRM_SIGNUP", emailAddress, token, encryptionPEMString, signingPEMString, currentKeyLabel, languageCode] withCallback:
     [^(NSDictionary* dict, NSError* error) {

        if(!byPassGuard)
        @synchronized(@"CONFIRM_SIGNUP")
        {
            isConfirmingSignupGuard = @NO;
        }
            NSString* response = [dict objectForKey:@"response"];

            if([response isEqualToString:@"OK"])
            {
                NSString* keyLabel = [dict objectForKey:@"keyLabel"];
                if(!keyLabel)
                    NSLog(@"Signed up, but no key label sent!!! %@",dict);
                else
                {
                    //NSLog(@"Signed up");
                    [accountSetting setHasBeenVerified:[NSNumber numberWithBool:YES]];
                    [CoreDataHelper save];

                    [self sendNewContactsToServerWithAccount:accountSetting withCallback:^(NSDictionary *dict, NSError *error) { }];

                    [AlertHelper showAlertWithMessage:NSLocalizedString(@"Congratulations! Your account setup has been completed.",nil) informativeText:NSLocalizedString(@"You can now send save messages to other Mynigma users",nil)];
                }
            }
            else if([response isEqualToString:@"ALREADY_SIGNED_UP"])
            {
                //NSLog(@"Already signed up");
                //NSString* keyLabel = [dict objectForKey:@"keyLabel"];
                [accountSetting setHasBeenVerified:[NSNumber numberWithBool:YES]];
                [CoreDataHelper save];

                [self sendNewContactsToServerWithAccount:accountSetting withCallback:^(NSDictionary *dict, NSError *error) { }];

            }
            else //if([response isEqualToString:@"WRONG_TOKEN"])
            {
                //NSLog(@"Server response: %@", response);
            }
            callback(dict, error);
    } copy]];
}

- (void)sendNewContactsToServerWithAccount:(IMAPAccountSetting*)accountSetting withCallback:(void(^)(NSDictionary*, NSError*))callback
{
    if(!accountSetting.shouldUse.boolValue)
        return;

    if(accountSetting)
    {
        NSString* currentKeyLabel = accountSetting.currentPrivateKeyLabel;
        if(currentKeyLabel)
        {
            NSMutableArray* requestArray = [NSMutableArray arrayWithArray:@[@"CONTACTS",accountSetting.emailAddress.canonicalForm]];
            NSFetchRequest* unsentContactsFetch = [NSFetchRequest fetchRequestWithEntityName:@"EmailContactDetail"];
            [unsentContactsFetch setPredicate:[NSPredicate predicateWithFormat:@"(sentToServer == NO) AND (dateLastContacted != nil)"]];
            [unsentContactsFetch setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"address" ascending:YES]]];
            NSError* error = nil;
            NSArray* contactsArray = [MAIN_CONTEXT executeFetchRequest:unsentContactsFetch error:&error];
            if(error)
                NSLog(@"Error fetching unsent contacts!");
            
            //hash those contacts
            NSArray* hashedEmailAddressesArray = [self hashContacts:[contactsArray valueForKey:@"address"]];

            [requestArray addObjectsFromArray:hashedEmailAddressesArray];

            for(EmailContactDetail* contactDetail in contactsArray)
            {
                [contactDetail setSentToServer:[NSNumber numberWithBool:YES]];
            }

            [SERVER sendRequestToServer:requestArray withKeyLabel:currentKeyLabel andCallback:[^(NSDictionary *dict, NSError *error) {

                [ThreadHelper runSyncOnMain:^{

                    if(![SERVER handleServerResponse:dict withError:error])
                        for(EmailContactDetail* contactDetail in contactsArray)
                        {
                            [contactDetail setSentToServer:[NSNumber numberWithBool:NO]];
                        }
                    else
                        for(EmailContactDetail* contactDetail in contactsArray)
                        {
                            [contactDetail setLastCheckedWithServer:[NSDate date]];
                        }
                    if(callback)
                        callback(dict, error);
                }];

            } copy]];

        }
        else
            NSLog(@"Cannot check new contacts with server: no current key pair!!! (3)");
    }
    else
        NSLog(@"Cannot check new contacts with server: invalid account setting!!");
}

- (void)sendAllContactsToServerWithAccount:(IMAPAccountSetting*)accountSetting withCallback:(void(^)(NSDictionary*, NSError*))callback
{
    if(!accountSetting.shouldUse.boolValue)
        return;

    if(accountSetting)
    {
        NSString* currentKeyLabel = accountSetting.currentPrivateKeyLabel;
        if(currentKeyLabel)
        {
            NSMutableArray* requestArray = [NSMutableArray arrayWithArray:@[@"CONTACTS",accountSetting.emailAddress.canonicalForm]];
            NSFetchRequest* allContacts = [NSFetchRequest fetchRequestWithEntityName:@"EmailContactDetail"];
            [allContacts setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"address" ascending:YES]]];
            NSError* error = nil;

            [allContacts setPredicate:[NSPredicate predicateWithFormat:@"dateLastContacted != nil"]];

            __block NSArray* contactsArray = [MAIN_CONTEXT executeFetchRequest:allContacts error:&error];
            if(error)
                NSLog(@"Error fetching contacts!");


            NSMutableArray *batches = [NSMutableArray array];

            NSInteger itemsRemaining = [contactsArray count];
            NSInteger i = 0;

            while(i < [contactsArray count]) {
                NSRange range = NSMakeRange(i, MIN(100, itemsRemaining));
                NSArray *subarray = [contactsArray subarrayWithRange:range];
                [batches addObject:subarray];
                itemsRemaining -= range.length;
                i += range.length;
            }

            for(NSArray* batch in batches)
            {
            
            //hash those contacts
            NSArray* hashedEmailAddressesArray = [self hashContacts:[batch valueForKey:@"address"]];

            [requestArray addObjectsFromArray:hashedEmailAddressesArray];

            for(EmailContactDetail* contactDetail in batch)
            {
                [contactDetail setSentToServer:[NSNumber numberWithBool:YES]];
            }

            [SERVER sendRequestToServer:requestArray withKeyLabel:currentKeyLabel andCallback:^(NSDictionary* dict, NSError* error) {

                [ThreadHelper runSyncOnMain:^{

                    if(!error)
                    {
                        if(![SERVER handleServerResponse:dict withError:error])
                        {
                            for(EmailContactDetail* contactDetail in batch)
                            {
                                [contactDetail setSentToServer:[NSNumber numberWithBool:NO]];
                            }
                            [CoreDataHelper save];
                        }
                        else
                            for(EmailContactDetail* contactDetail in batch)
                            {
                                [contactDetail setLastCheckedWithServer:[NSDate date]];
                            }
                    }
                    else
                        NSLog(@"Response from server: %@, error: %@",dict,error);
                    if(callback)
                        callback(dict, error);
                }];

            }];
            }
        }
        else
            NSLog(@"Cannot check all contacts with server: no current key pair!!!");
    }
    else
        NSLog(@"Cannot check all contacts with server: invalid account setting!!");
}

//sends request for a sign up mail
- (void)requestWelcomeMessageForAccount:(IMAPAccountSetting*)accountSetting withCallback:(void(^)(NSDictionary*, NSError*))callback;
{
    __block NSString* emailAddress = accountSetting.emailAddress.canonicalForm;

    //cannot request a sign-up message without a valid account
    if(!accountSetting)
    {
        NSLog(@"Trying to sign up an invalid account!");
        return;
    }

    if(!accountSetting.shouldUse.boolValue)
        return;

    //probably don't need this any more, but it amounts to a lock that ensures that no more than one request is sent off concurrently - its former function was to ensure that not too many requests were made one after the other, but now the sign-up procedure in IMAPAccount has been cleaned up, so no unnecessary requests ought to be made anyway...
    @synchronized(@"REQUEST_TOKEN")
    {
        if(!accountSetting.hasRequestedWelcomeMessage.boolValue)
        {
            [accountSetting setHasRequestedWelcomeMessage:[NSNumber numberWithBool:YES]];
        }
        //else
        //  return;
    }

    NSString* keyLabel = accountSetting.currentPrivateKeyLabel;
    if(!keyLabel)
        return;
    
    // get current language code
    NSString* languageCode = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];

    [SERVER sendArrayToServer:@[@"SIGNUP", emailAddress, keyLabel, languageCode] withCallback:
         [^(NSDictionary* dict, NSError* error) {

            NSString* response = [dict objectForKey:@"response"]; //TODO RESPONSE FIT

            NSLog(@"Requested token. Response: %@", response);

            //if(error || !([response isEqualToString:@"OK"] || [response isEqualToString:@"ALREADY_SIGNED_UP"] || [response isEqualToString:@"Token has already been sent"]))
            @synchronized(@"REQUEST_TOKEN")
            {
                [accountSetting setHasRequestedWelcomeMessage:[NSNumber numberWithBool:NO]];
                [CoreDataHelper save];
            }

            if([response isEqualToString:@"ALREADY_SIGNED_UP"])
            {
                [accountSetting setHasBeenVerified:[NSNumber numberWithBool:YES]];
                [CoreDataHelper save];

                [self sendNewContactsToServerWithAccount:accountSetting withCallback:^(NSDictionary *dict, NSError *error) { }];
            }
            callback(dict, error);
            } copy]];
}

//removes all records from the server
- (void)removeAllRecordsForAccount:(IMAPAccountSetting*)accountSetting withCallback:(void(^)(NSDictionary*, NSError*))callback
{
    if(!accountSetting)
    {
        NSLog(@"No account setting set!!");
        return;
    }
    __block NSString* emailAddress = accountSetting.emailAddress.canonicalForm;
    [SERVER sendRequestToServer:[@[@"REMOVE_ALL_RECORDS", emailAddress] mutableCopy] withKeyLabel:accountSetting.currentPrivateKeyLabel andCallback:[^(NSDictionary *dict, NSError *error) {
        callback(dict, error);
    } copy]];
}

//removes all sign-up tokens from server
- (void)removeWelcomeMessageIDsForAccount:(IMAPAccountSetting *)accountSetting withCallback:(void (^)(NSDictionary *, NSError *))callback
{
    if(!accountSetting)
    {
        NSLog(@"No account setting set!!");
        return;
    }
    __block NSString* emailAddress = accountSetting.emailAddress.canonicalForm;
    [SERVER sendRequestToServer:[@[@"REMOVE_ALL_TOKENS", emailAddress] mutableCopy] withKeyLabel:accountSetting.currentPrivateKeyLabel andCallback:[^(NSDictionary *dict, NSError *error) {
        callback(dict, error);
    } copy]];
}


- (void)requestKeyWithLabel:(NSString*)keyLabel inAccount:(IMAPAccountSetting*)accountSetting withCallback:(void(^)(NSDictionary*, NSError*))callback
{
    //TO DO: implement
}

- (NSArray*) hashContacts:(NSArray*)contacts
{
    NSMutableArray* hashedContacts = [NSMutableArray new];
    for (int i = 0; i<contacts.count; i++)
    {
        NSString* contactWithSecret  = [NSString stringWithFormat:@"Mynigma%@App",[contacts[i] canonicalForm]];
        NSData* unhashedData = [contactWithSecret dataUsingEncoding:NSUTF8StringEncoding];
        NSData* hashedData = [AppleEncryptionWrapper SHA512DigestOfData:unhashedData];
        NSString* base64Data = [hashedData base64];
        [hashedContacts addObject:base64Data];
        //NSLog(@"\n%@:\n%@\n%@", contacts[i], base64Data, hashedData);
    }
        return hashedContacts;
}

@end
