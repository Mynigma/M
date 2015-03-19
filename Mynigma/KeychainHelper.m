
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

#import "OpenSSLWrapper.h"

#else

#import <Security/SecAccess.h>

#endif

#import "AppDelegate.h"
#import "KeychainHelper.h"
#import "IMAPAccountSetting.h"
#import <MailCore/MailCore.h>
#import "UserSettings.h"
#import "MynigmaPublicKey+Category.h"
#import "MynigmaPrivateKey+Category.h"
#import "ConnectionItem.h"
#import "NSData+Base64.h"
#import "NSString+EmailAddresses.h"
#import <Security/Security.h>




static NSArray* publicKeyItemsList;
static NSArray* privateKeyItemsList;

static NSArray* publicKeyItemsPropertiesList;
static NSArray* privateKeyItemsPropertiesList;


@interface MynigmaPrivateKey()

+ (MynigmaPrivateKey*)syncMakeNewPrivateKeyWithLabel:(NSString*)keyLabel forEmail:(NSString*)emailString withDecRef:(NSData*)decRef andSigRef:(NSData*)sigRef andEncRef:(NSData*)encRef andVerRef:(NSData*)verRef dateCreated:(NSDate*)dateCreated isCompromised:(BOOL)isCompromised makeCurrentKey:(BOOL)makeCurrentKey inContext:(NSManagedObjectContext*)keyContext;


@end





@implementation KeychainHelper


#pragma mark - UUID

+ (NSString*)fetchUUIDFromKeychain
{
    NSMutableDictionary *query = [NSMutableDictionary new];

    query[(__bridge id)kSecClass] = (__bridge id)kSecClassInternetPassword;

    [query setObject:@"MynigmaID" forKey:(__bridge id)kSecAttrAccount];
    [query setObject:@"Mynigma Device UUID" forKey:(__bridge id)kSecAttrServer];

    //return the actual password
    [query setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnData];

    //match limit one is needed for actual data to be returned
    [query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];

    CFTypeRef resultsRef = nil;

    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &resultsRef);

    if(status == noErr && resultsRef)
    {
        NSData* pwdData = CFBridgingRelease(resultsRef);
        NSString* password = [[NSString alloc] initWithBytes:pwdData.bytes length:pwdData.length encoding:NSUTF8StringEncoding];
        return password;
    }

    NSString* UUID = [[NSUUID UUID] UUIDString];

    if([KeychainHelper saveUUIDToKeychain:UUID])
        return UUID;

    return nil;
}

+ (BOOL)saveUUIDToKeychain:(NSString*)UUID
{
    if(!UUID)
        return NO;

    NSMutableDictionary *query = [NSMutableDictionary new];

    query[(__bridge id)kSecClass] = (__bridge id)kSecClassInternetPassword;

    [query setObject:@"MynigmaID" forKey:(__bridge id)kSecAttrAccount];
    [query setObject:@"Mynigma Device UUID" forKey:(__bridge id)kSecAttrServer];

    //return the actual password
    [query setObject:[UUID dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];

    CFTypeRef resultsRef = nil;

    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, &resultsRef);

    if(status == noErr)
    {
        return YES;
    }
    else
    {
        NSLog(@"Error saving MynigmaID: %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);
        return NO;
    }

}



#pragma mark - PASSWORDS

+ (NSString*)passwordForPersistentRef:(NSData*)persistentRef
{
    if(!persistentRef)
        return nil;

    NSMutableDictionary *query = [NSMutableDictionary new];

    query[(__bridge id)kSecClass] = (__bridge id)kSecClassInternetPassword;

    query[(__bridge id)kSecValuePersistentRef] = persistentRef;

    //return the actual password
    [query setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnData];

    //match limit one is needed for actual data to be returned
    [query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];

    CFTypeRef resultsRef = nil;

    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &resultsRef);

    if(status == noErr && resultsRef)
    {
        NSData* pwdData = CFBridgingRelease(resultsRef);
        NSString* password = [[NSString alloc] initWithBytes:pwdData.bytes length:pwdData.length encoding:NSUTF8StringEncoding];
        return password;
    }

    //maybe it's a generic password?! try...

    query[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;

    resultsRef = nil;

    status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &resultsRef);

    if(status == noErr && resultsRef)
    {
        NSData* pwdData = CFBridgingRelease(resultsRef);
        NSString* password = [[NSString alloc] initWithBytes:pwdData.bytes length:pwdData.length encoding:NSUTF8StringEncoding];
        return password;
    }

    return nil;
}

+ (NSArray*)listLocalKeychainItems
{
    NSMutableDictionary* query = [NSMutableDictionary new];

    query[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;

    query[(__bridge id)kSecAttrService] = @"iCloud";

    //return both the attributes *and* a persistent ref to the item
    query[(__bridge id)kSecReturnAttributes] = @YES;
    query[(__bridge id)kSecReturnPersistentRef] = @YES;

    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitAll;


    //query[(__bridge id)kSecAttrSynchronizable] = (__bridge id)(kSecAttrSynchronizableAny);

    CFTypeRef resultsRef = nil;

    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &resultsRef);

    NSArray* iCloudResults = nil;

    if(status == noErr && resultsRef)
    {
        iCloudResults = CFBridgingRelease(resultsRef);
    }

    query[(__bridge id)kSecClass] = (__bridge id)kSecClassInternetPassword;

    [query removeObjectForKey:(__bridge id)kSecAttrService];

    query[(__bridge id)kSecAttrProtocol] = (__bridge id)kSecAttrProtocolIMAP;

    status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &resultsRef);

    NSArray* imapResults = nil;

    if(status == noErr && resultsRef)
    {
        imapResults = CFBridgingRelease(resultsRef);
    }

    //sort the results by modified date, last modified first
    imapResults = [imapResults sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2)
                   {
                       if([obj1 isKindOfClass:[NSDictionary class]] && [obj2 isKindOfClass:[NSDictionary class]])
                       {
                           NSDate* mdat1 = obj1[@"mdat"];
                           NSDate* mdat2 = obj2[@"mdat"];

                           if(mdat1 && mdat2)
                           {
                               return [mdat2 compare:mdat1];
                           }

                           if(mdat1)
                               return NSOrderedAscending;

                           if(mdat2)
                               return NSOrderedDescending;

                           return NSOrderedSame;
                       }

                       //invalid objects come last, after all valid items, sorted reverse chronologically

                       if([obj1 isKindOfClass:[NSDictionary class]])
                           return NSOrderedAscending;

                       if([obj2 isKindOfClass:[NSDictionary class]])
                           return NSOrderedDescending;

                       return NSOrderedSame;
                   }];

    query[(__bridge id)kSecAttrProtocol] = (__bridge id)kSecAttrProtocolSMTP;

    status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &resultsRef);

    NSArray* smtpResults = nil;

    if(status == noErr && resultsRef)
    {
        smtpResults = CFBridgingRelease(resultsRef);
    }

    smtpResults = [smtpResults sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2)
                   {
                       if([obj1 isKindOfClass:[NSDictionary class]] && [obj2 isKindOfClass:[NSDictionary class]])
                       {
                           NSDate* mdat1 = obj1[@"mdat"];
                           NSDate* mdat2 = obj2[@"mdat"];

                           if(mdat1 && mdat2)
                           {
                               return [mdat2 compare:mdat1];
                           }

                           if(mdat1)
                               return NSOrderedAscending;

                           if(mdat2)
                               return NSOrderedDescending;

                           return NSOrderedSame;
                       }

                       //invalid objects come last, after all valid items, sorted reverse chronologically

                       if([obj1 isKindOfClass:[NSDictionary class]])
                           return NSOrderedAscending;

                       if([obj2 isKindOfClass:[NSDictionary class]])
                           return NSOrderedDescending;

                       return NSOrderedSame;
                   }];



    //now go through the results
    NSMutableArray* returnValue = [NSMutableArray new];

    NSArray* sortediCloudResults = [iCloudResults sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2)
                                    {
                                        if([obj1 isKindOfClass:[NSDictionary class]] && [obj2 isKindOfClass:[NSDictionary class]])
                                        {
                                            NSDate* mdat1 = obj1[@"mdat"];
                                            NSDate* mdat2 = obj2[@"mdat"];

                                            if(mdat1 && mdat2)
                                            {
                                                return [mdat2 compare:mdat1];
                                            }

                                            if(mdat1)
                                                return NSOrderedAscending;

                                            if(mdat2)
                                                return NSOrderedDescending;

                                            return NSOrderedSame;
                                        }

                                        //invalid objects come last, after all valid items, sorted reverse chronologically

                                        if([obj1 isKindOfClass:[NSDictionary class]])
                                            return NSOrderedAscending;

                                        if([obj2 isKindOfClass:[NSDictionary class]])
                                            return NSOrderedDescending;

                                        return NSOrderedSame;
                                    }];


    //iCloud first
    for(NSDictionary* dict in sortediCloudResults)
    {
        NSString* email = [dict[@"labl"] lowercaseString];
        if(email && ![[returnValue valueForKey:@"emailAddress"] containsObject:email])
        {
            if([email isValidEmailAddress])
            {
                //it's a valid email address

                //IMAP user name for iCloud email is the part before the @
                NSArray* emailComponents = [email componentsSeparatedByString:@"@"];
                if(emailComponents.count!=2 || ![@[@"mac.com", @"me.com", @"icloud.com"] containsObject:[emailComponents[1] lowercaseString]])
                    continue;

                NSString* firstPartOfEmailAddress = emailComponents[0];

                ConnectionItem* newItem = [ConnectionItem new];

                [newItem setEmailAddress:email];

                [newItem setIncomingUsername:firstPartOfEmailAddress];
                [newItem setIncomingHost:@"imap.mail.me.com"];
                [newItem setIncomingPort:@993];
                [newItem setIncomingConnectionType:@(MCOConnectionTypeStartTLS)];
                [newItem setIncomingAuth:@(MCOAuthTypeSASLPlain|MCOAuthTypeSASLLogin)];

                //SMTP user name is full email address
                [newItem setOutgoingUsername:email];
                [newItem setOutgoingHost:@"smtp.mail.me.com"];
                [newItem setOutgoingPort:@587];
                [newItem setOutgoingConnectionType:@(MCOConnectionTypeStartTLS)];
                [newItem setOutgoingAuth:@(MCOAuthTypeSASLPlain|MCOAuthTypeSASLLogin)];

                NSData* persistentRef = dict[@"v_PersistentRef"];

                if([persistentRef length]==0)
                    continue;

                [newItem setIncomingPersistentRef:persistentRef];
                [newItem setOutgoingPersistentRef:persistentRef];


                [newItem setSourceOfData:ConnectionItemSourceOfDataKeychain];
                [newItem setSourceOfPassword:ConnectionItemSourceOfPasswordKeychain];

                [returnValue addObject:newItem];
            }
        }
    }

    //now IMAP and SMTP
    for(NSDictionary* imapDict in imapResults)
    {
        NSString* username = [imapDict[@"acct"] lowercaseString];

        if(!username.length)
            continue;

        if(![[returnValue valueForKey:@"incomingUsername"] containsObject:username])
        {
            //doesn't need to be a valid email address

            //check if there is a matching SMTP entry

            NSDictionary* smtpDict = nil;

            for(NSDictionary* smtpDictItem in smtpResults)
            {
                if([[smtpDictItem[@"acct"] lowercaseString] isEqual:username])
                {
                    smtpDict = smtpDictItem;
                    break;
                }
            }

            if(!smtpDict)
                continue;

            NSData* imapPersistentRef = imapDict[@"v_PersistentRef"];
            NSData* smtpPersistentRef = smtpDict[@"v_PersistentRef"];

            if([imapPersistentRef length]==0 || [smtpPersistentRef length]==0)
                continue;


            NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}";
            NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];

            if(![emailTest evaluateWithObject:username])
                continue;

            ConnectionItem* newItem = [[ConnectionItem alloc] initWithEmail:username];

            [newItem setIncomingUsername:username];

            [newItem setIncomingHost:imapDict[@"srvr"]];

            if(imapDict[@"port"] && ![imapDict[@"port"] isEqual:@0])
            {
                [newItem setIncomingPort:imapDict[@"port"]];
                if([newItem.incomingPort isEqual:@993])
                    [newItem setIncomingConnectionType:@(MCOConnectionTypeTLS)];
            }
            [newItem setIncomingAuth:@(MCOAuthTypeSASLPlain|MCOAuthTypeSASLLogin)];

            //SMTP user name is full email address
            [newItem setOutgoingUsername:username];
            [newItem setOutgoingHost:smtpDict[@"srvr"]];
            if(smtpDict[@"port"] && ![smtpDict[@"port"] isEqual:@0])
            {
                [newItem setOutgoingPort:smtpDict[@"port"]];
                if([newItem.outgoingPort isEqual:@465])
                    [newItem setIncomingConnectionType:@(MCOConnectionTypeTLS)];
                if([newItem.incomingPort isEqual:@587])
                    [newItem setIncomingConnectionType:@(MCOConnectionTypeStartTLS)];
            }

            [newItem setIncomingPersistentRef:imapPersistentRef];
            [newItem setOutgoingPersistentRef:smtpPersistentRef];

            [newItem setOutgoingAuth:@(MCOAuthTypeSASLPlain|MCOAuthTypeSASLLogin)];

            if(newItem.emailAddress)
            {
                MCOMailProvider *accountProvider = [MCOMailProvidersManager.sharedManager providerForEmail:newItem.emailAddress];

                if (!accountProvider) {
                    //NSLog(@"No provider available for email: %@", newItem.emailAddress);
                }
                else
                {
                    NSArray *imapServices = accountProvider.imapServices;
                    if (imapServices.count != 0)
                    {
                        MCONetService *imapService = [imapServices objectAtIndex:0];
                        if(!newItem.incomingHost)
                            [newItem setIncomingHost:imapService.hostname];
                        if(!newItem.incomingPort)
                            [newItem setIncomingPort:@(imapService.port)];
                        if(!newItem.incomingConnectionType)
                        {
                            switch(newItem.incomingConnectionType.integerValue)
                            {
                                case MCOConnectionTypeClear:
                                    [newItem setIncomingConnectionType:@(MCOConnectionTypeClear)];
                                    break;
                                case MCOConnectionTypeStartTLS:
                                    [newItem setIncomingConnectionType:@(MCOConnectionTypeStartTLS)];
                                    break;
                                case MCOConnectionTypeTLS:
                                    [newItem setIncomingConnectionType:@(MCOConnectionTypeTLS)];
                                    break;
                            }
                        }
                    }

                    NSArray* smtpServices = accountProvider.smtpServices;
                    if (smtpServices.count != 0)
                    {
                        MCONetService *smtpService = [smtpServices objectAtIndex:0];
                        if(!newItem.outgoingHost)
                            [newItem setOutgoingHost:smtpService.hostname];
                        if(!newItem.outgoingPort)
                            [newItem setOutgoingPort:@(smtpService.port)];

                        if(!newItem.outgoingConnectionType)
                        {
                            switch(smtpService.connectionType)
                            {
                                case MCOConnectionTypeClear:
                                    [newItem setOutgoingConnectionType:@(MCOConnectionTypeClear)];
                                    break;
                                case MCOConnectionTypeStartTLS:
                                    [newItem setOutgoingConnectionType:@(MCOConnectionTypeStartTLS)];
                                    break;
                                case MCOConnectionTypeTLS:
                                    [newItem setOutgoingConnectionType:@(MCOConnectionTypeTLS)];
                                    break;
                            }
                        }
                    }
                }
            }

            [newItem setSourceOfData:ConnectionItemSourceOfDataKeychain];
            [newItem setSourceOfPassword:ConnectionItemSourceOfPasswordKeychain];

            [returnValue addObject:newItem];
        }
    }

    return returnValue;
}


+ (NSArray*)listIMAPPasswordsAndSettingsFoundInKeychain;
{
    NSMutableArray* returnValue = [NSMutableArray new];
    return returnValue;
}


//returns a generic dictionary with the account and server settings set to the sepcified values - this is amended with further object-key pairs and then passed to the keychain functions such as SecItemCopyMatching
+ (NSMutableDictionary*)queryDictionaryForEmail:(NSString*)email withServer:(NSString*)server
{
    NSMutableDictionary *query = [NSMutableDictionary new];
    [query setObject:(__bridge id)kSecClassInternetPassword forKey:(__bridge id)kSecClass];
    [query setObject:[email lowercaseString] forKey:(__bridge id)kSecAttrAccount];
    [query setObject:[server lowercaseString] forKey:(__bridge id)kSecAttrServer];

    return query;
}

//when the user enters an email in the add account dialogue the keychain is searched for a matching password
+ (NSString*)findPasswordForEmail:(NSString*)email andServer:(NSString *)server
{
    @try {

        NSMutableDictionary *query = [self queryDictionaryForEmail:email withServer:server];

        //return the actual password
        [query setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnData];

        //match limit one is needed for actual data to be returned
        [query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];

        CFDataRef pwdDataRef;
        OSStatus osStatus = SecItemCopyMatching((__bridge CFDictionaryRef)(query), (CFTypeRef*)&pwdDataRef);
        if (osStatus == noErr && pwdDataRef)
        {
            NSData* pwdData = (__bridge NSData*)pwdDataRef;
            NSString* password = [[NSString alloc] initWithBytes:pwdData.bytes length:pwdData.length encoding:NSUTF8StringEncoding];
            CFRelease(pwdDataRef);
            return password?password:@"";
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception caught: %@",exception);
    }
    @finally {
    }

    return nil;
}

//this saves the password for the specified account into the Mynigma keychain (if isIncoming is YES, it is the IMAP password, otherwise the SMTP password)
+ (BOOL)savePassword:(NSString*)password forAccount:(NSManagedObjectID *)accountSettingID incoming:(BOOL)isIncoming
{
    if(!password)
        return NO;


    if(!accountSettingID)
    {
        NSLog(@"Cannot save password: no account setting ID!!!");
        return NO;
    }

    __block BOOL result = NO;

    [ThreadHelper runSyncOnMain:^{

        @try {

            IMAPAccountSetting* accountSetting = (IMAPAccountSetting*)[MAIN_CONTEXT objectWithID:accountSettingID];
            if(!accountSetting)
            {
                NSLog(@"Cannot save password: no account setting!!!");
                return;
            }
            NSString* serverName = [isIncoming?accountSetting.incomingServer:accountSetting.outgoingServer lowercaseString];
            NSString* emailAddress = [accountSetting.emailAddress lowercaseString];

            //if a password ref is already assigned - alter the existing item in the keychain
            NSData* keychainItemRef = isIncoming?accountSetting.incomingPasswordRef:accountSetting.outgoingPasswordRef;


            if(keychainItemRef)
            {
                //a password ref has been found - use the corresponding item in the keychain and update its value to the new password

                NSMutableDictionary *query = [self queryDictionaryForEmail:emailAddress withServer:serverName];

                //set the persistent ref
                [query setObject:keychainItemRef forKey:(__bridge id<NSCopying>)(kSecValuePersistentRef)];

                NSMutableDictionary* attributesToUpdate = [NSMutableDictionary new];

                //need to update the password data
                [attributesToUpdate setObject:[password dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];




//                [attributesToUpdate setObject:@"org.mynigma.Mynigma" forKey:(__bridge id<NSCopying>)(kSecAttrAccessGroup)];


                //bug in keychain causes SecItemUpdate to return -25299 (item already exists) if the protocol etc. is updated too

                //                if(isIncoming)
                //                {
                //                    [attributesToUpdate setObject:(__bridge id)kSecAttrProtocolIMAP forKey:(__bridge id)kSecAttrProtocol];
                //                    if(accountSetting.incomingPort)
                //                        [attributesToUpdate setObject:accountSetting.incomingPort forKey:(__bridge id)kSecAttrPort];
                //                }
                //                else
                //                {
                //                    [attributesToUpdate setObject:(__bridge id)kSecAttrProtocolSMTP forKey:(__bridge id)kSecAttrProtocol];
                //                    if(accountSetting.outgoingPort)
                //                        [attributesToUpdate setObject:accountSetting.outgoingPort forKey:(__bridge id)kSecAttrPort];
                //                }

                OSStatus osStatus = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributesToUpdate);
                if(osStatus == noErr)
                {
                    NSLog(@"Password for account %@ updated!",accountSetting.displayName);
                    result = YES;
                }
                else
                    NSLog(@"Password for account %@ could not be updated: %@",accountSetting.displayName,[NSError errorWithDomain:NSOSStatusErrorDomain code:osStatus userInfo:nil]);
            }
            else //so far no ref has been assigned, so add a new keychain item or update an existing one
            {
                //look for any previously stored passwords matching the following criteria:
                //class is internet password
                //account matches the email address
                //the server address matches

                //if such an item is found update it instead of creating a new one

                NSMutableDictionary *query = [KeychainHelper queryDictionaryForEmail:emailAddress withServer:serverName];

                [query setObject:@YES forKey:(__bridge id<NSCopying>)(kSecReturnPersistentRef)];

                CFDataRef persistentRef = NULL;

                OSStatus osStatus = SecItemCopyMatching((__bridge CFDictionaryRef)(query), (CFTypeRef*)&persistentRef);

                if(osStatus == noErr && persistentRef != NULL) //item exists in keychain, so just update it
                {
                    NSMutableDictionary* attributesToUpdate = [NSMutableDictionary new];

                    //need to update the password data
                    [attributesToUpdate setObject:[password dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];







//                    [attributesToUpdate setObject:@"org.mynigma.Mynigma" forKey:(__bridge id<NSCopying>)(kSecAttrAccessGroup)];









                    //bug in keychain causes SecItemUpdate to return -25299 (item already exists) if the protocol etc. is updated too
                    //                    if(isIncoming)
                    //                    {
                    //                        [attributesToUpdate setObject:(__bridge id)kSecAttrProtocolIMAP forKey:(__bridge id)kSecAttrProtocol];
                    //                        if(accountSetting.incomingPort.integerValue>0)
                    //                            [attributesToUpdate setObject:accountSetting.incomingPort forKey:(__bridge id)kSecAttrPort];
                    //                    }
                    //                    else
                    //                    {
                    //                        [attributesToUpdate setObject:(__bridge id)kSecAttrProtocolSMTP forKey:(__bridge id)kSecAttrProtocol];
                    //                        if(accountSetting.outgoingPort.integerValue>0)
                    //                            [attributesToUpdate setObject:accountSetting.outgoingPort forKey:(__bridge id)kSecAttrPort];
                    //                    }

                    [query removeObjectForKey:(__bridge id)kSecReturnPersistentRef];

                    OSStatus osStatus = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributesToUpdate);

                    if(isIncoming)
                        [accountSetting setIncomingPasswordRef:[[NSData alloc] initWithData:(__bridge NSData*)persistentRef]];
                    else
                        [accountSetting setOutgoingPasswordRef:[[NSData alloc] initWithData:(__bridge NSData*)persistentRef]];
                    [CoreDataHelper save];

                    if(osStatus == noErr)
                    {
                        //NSLog(@"Password set! Account: %@",accountSetting.displayName);
                        result = YES;
                    }
                    else
                    {
                        NSLog(@"Password for account %@ could not be updated: %@",accountSetting.displayName,[NSError errorWithDomain:NSOSStatusErrorDomain code:osStatus userInfo:nil]);

                    }
                    CFRelease(persistentRef);

                }
                else
                {
                    //just save the password

                    //set the password data
                    [query setObject:[password dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id<NSCopying>)(kSecValueData)];
                    [query setObject:@YES forKey:(__bridge id<NSCopying>)(kSecReturnPersistentRef)];




                    //                    [query setObject:@"org.mynigma.Mynigma" forKey:(__bridge id<NSCopying>)(kSecAttrAccessGroup)];
                    //
                    //                    [query setObject:@YES forKey:(__bridge id<NSCopying>)(kSecAttrSynchronizable)];





                    if(isIncoming)
                    {
                        [query setObject:(__bridge id)kSecAttrProtocolIMAP forKey:(__bridge id)kSecAttrProtocol];
                        if(accountSetting.incomingPort)
                            [query setObject:accountSetting.incomingPort forKey:(__bridge id)kSecAttrPort];
                    }
                    else
                    {
                        [query setObject:(__bridge id)kSecAttrProtocolSMTP forKey:(__bridge id)kSecAttrProtocol];
                        if(accountSetting.outgoingPort)
                            [query setObject:accountSetting.outgoingPort forKey:(__bridge id)kSecAttrPort];
                    }

                    CFTypeRef persistentRef = NULL;

                    //add it to the keychain
                    osStatus = SecItemAdd((__bridge CFDictionaryRef)query, &persistentRef);


                    //                    [KeychainHelper dumpAccessRefForPersistentRefToLog:(__bridge NSData *)(persistentRef)];

                    //                    SecKeychainItemRef itemRef = (SecKeychainItemRef)[KeychainHelper keyRefForPersistentRef:(__bridge NSData *)(persistentRef)];

                    //[KeychainHelper ensureCorrectAccessRightsForKeychainItem:itemRef isPassword:YES];


                    //                    [KeychainHelper dumpAccessRefForPersistentRefToLog:(__bridge NSData *)(persistentRef)];
                    //#if TEST

                    //[KeychainHelper ensureKeyCanOnlyBeAccessedByMynigma:(__bridge NSData *)(persistentRef)];

                    //#endif



                    if((osStatus != noErr) || !persistentRef)
                        NSLog(@"Error: could not add item to keychain!!! %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:osStatus userInfo:nil]);
                    else
                    {
                        NSLog(@"Password set! Account: %@",accountSetting.displayName);
                        if(isIncoming)
                            [accountSetting setIncomingPasswordRef:[[NSData alloc] initWithData:(__bridge NSData*)persistentRef]];
                        else
                            [accountSetting setOutgoingPasswordRef:[[NSData alloc] initWithData:(__bridge NSData*)persistentRef]];
                        [CoreDataHelper save];
                        result = YES;
                        CFRelease(persistentRef);
                    }
                }
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Exception caught: %@",exception);
            return;
        }
        @finally {
        }

    }];

    return result;
}



//+ (void)ensureKeyCanOnlyBeAccessedByMynigma:(NSData*)persistentKeyRef
//{
//    SecKeychainItemRef keyRef = (SecKeychainItemRef)[KeychainHelper keyRefForPersistentRef:persistentKeyRef];
//
//    SecAccessRef encAccessRef = NULL;
//
//    OSStatus status = SecKeychainItemCopyAccess(keyRef, &encAccessRef);
//
//    CFArrayRef encACLList = NULL;
//
//    status = SecAccessCopyACLList(encAccessRef, &encACLList);
//
//    NSInteger ACLCount = CFArrayGetCount(encACLList);
//
//    for(NSInteger i = 0; i < ACLCount; i++)
//    {
//        SecACLRef ACLRef = (SecACLRef)CFArrayGetValueAtIndex(encACLList, i);
//
//        CFArrayRef applicationListRef = NULL;
//
//        CFStringRef description = NULL;
//
//        SecKeychainPromptSelector promptSelector;
//
//        status = SecACLCopyContents(ACLRef, &applicationListRef, &description, &promptSelector);
//
//        if(applicationListRef)
//        {
//            NSInteger numberOfTrustedApplications = CFArrayGetCount(applicationListRef);
//        }
//    }
//}
//


+ (void)saveAsyncPassword:(NSString*)password forAccountSetting:(IMAPAccountSetting*)accountSetting incoming:(BOOL)isIncoming withCallback:(void(^)(BOOL success))callback
{
    if(!password)
    {
        if(callback)
            callback(NO);
        return;
    }


    if(!accountSetting)
    {
        NSLog(@"Cannot save password: no account setting!!!");
        if(callback)
            callback(NO);
        return;
    }

    NSString* serverName = [isIncoming?accountSetting.incomingServer:accountSetting.outgoingServer lowercaseString];

    NSString* emailAddress = [accountSetting.emailAddress lowercaseString];

    NSNumber* incomingPort = accountSetting.incomingPort;

    NSNumber* outgoingPort = accountSetting.outgoingPort;

    NSString* displayName = accountSetting.displayName;


    //if a password ref is already assigned - alter the existing item in the keychain
    NSData* keychainItemRef = isIncoming?accountSetting.incomingPasswordRef:accountSetting.outgoingPasswordRef;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        if(keychainItemRef)
        {
            //a password ref has been found - use the corresponding item in the keychain and update its value to the new password

            NSMutableDictionary *query = [self queryDictionaryForEmail:emailAddress withServer:serverName];

            //set the persistent ref
            [query setObject:keychainItemRef forKey:(__bridge id<NSCopying>)(kSecValuePersistentRef)];

            NSMutableDictionary* attributesToUpdate = [NSMutableDictionary new];

            //need to update the password data
            [attributesToUpdate setObject:[password dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];

            //bug in keychain causes SecItemUpdate to return -25299 (item already exists) if the protocol etc. is updated too

            //                if(isIncoming)
            //                {
            //                    [attributesToUpdate setObject:(__bridge id)kSecAttrProtocolIMAP forKey:(__bridge id)kSecAttrProtocol];
            //                    if(accountSetting.incomingPort)
            //                        [attributesToUpdate setObject:accountSetting.incomingPort forKey:(__bridge id)kSecAttrPort];
            //                }
            //                else
            //                {
            //                    [attributesToUpdate setObject:(__bridge id)kSecAttrProtocolSMTP forKey:(__bridge id)kSecAttrProtocol];
            //                    if(accountSetting.outgoingPort)
            //                        [attributesToUpdate setObject:accountSetting.outgoingPort forKey:(__bridge id)kSecAttrPort];
            //                }

            @try {
                OSStatus osStatus = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributesToUpdate);
                if(osStatus == noErr)
                {
                    NSLog(@"Password for account %@ updated!", displayName);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(callback)
                            callback(YES);
                    });
                    return;
                }
                else
                {
                    NSLog(@"Password for account %@ could not be updated: %@", displayName,[NSError errorWithDomain:NSOSStatusErrorDomain code:osStatus userInfo:nil]);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(callback)
                            callback(NO);
                    });
                    return;
                }

            }
            @catch (NSException *exception) {
                NSLog(@"Exception caught: %@",exception);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(callback)
                        callback(NO);
                });
                return;
            }
            @finally {
            }

        }
        else //so far no ref has been assigned, so add a new keychain item or update an existing one
        {
            //look for any previously stored passwords matching the following criteria:
            //class is internet password
            //account matches the email address
            //the server address matches

            //if such an item is found update it instead of creating a new one

            NSMutableDictionary *query = [KeychainHelper queryDictionaryForEmail:emailAddress withServer:serverName];

            [query setObject:@YES forKey:(__bridge id<NSCopying>)(kSecReturnPersistentRef)];

            CFDataRef persistentRef = NULL;

            OSStatus osStatus = SecItemCopyMatching((__bridge CFDictionaryRef)(query), (CFTypeRef*)&persistentRef);

            if(osStatus == noErr && persistentRef != NULL) //item exists in keychain, so just update it
            {
                NSMutableDictionary* attributesToUpdate = [NSMutableDictionary new];

                //need to update the password data
                [attributesToUpdate setObject:[password dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];

                //bug in keychain causes SecItemUpdate to return -25299 (item already exists) if the protocol etc. is updated too
                //                    if(isIncoming)
                //                    {
                //                        [attributesToUpdate setObject:(__bridge id)kSecAttrProtocolIMAP forKey:(__bridge id)kSecAttrProtocol];
                //                        if(accountSetting.incomingPort.integerValue>0)
                //                            [attributesToUpdate setObject:accountSetting.incomingPort forKey:(__bridge id)kSecAttrPort];
                //                    }
                //                    else
                //                    {
                //                        [attributesToUpdate setObject:(__bridge id)kSecAttrProtocolSMTP forKey:(__bridge id)kSecAttrProtocol];
                //                        if(accountSetting.outgoingPort.integerValue>0)
                //                            [attributesToUpdate setObject:accountSetting.outgoingPort forKey:(__bridge id)kSecAttrPort];
                //                    }

                [query removeObjectForKey:(__bridge id)kSecReturnPersistentRef];

                OSStatus osStatus = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributesToUpdate);

                dispatch_async(dispatch_get_main_queue(), ^{

                    if(isIncoming)
                        [accountSetting setIncomingPasswordRef:[[NSData alloc] initWithData:(__bridge NSData*)persistentRef]];
                    else
                        [accountSetting setOutgoingPasswordRef:[[NSData alloc] initWithData:(__bridge NSData*)persistentRef]];

                    [CoreDataHelper save];

                    if(osStatus == noErr)
                    {
                        //NSLog(@"Password set! Account: %@",accountSetting.displayName);
                        callback(YES);
                    }
                    else
                    {
                        NSLog(@"Password for account %@ could not be updated: %@", displayName,[NSError errorWithDomain:NSOSStatusErrorDomain code:osStatus userInfo:nil]);

                        if(callback)
                            callback(NO);
                    }
                    CFRelease(persistentRef);

                });

            }
            else
            {
                //just save the password

                //set the password data
                [query setObject:[password dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id<NSCopying>)(kSecValueData)];
                [query setObject:@YES forKey:(__bridge id<NSCopying>)(kSecReturnPersistentRef)];

                if(isIncoming)
                {
                    [query setObject:(__bridge id)kSecAttrProtocolIMAP forKey:(__bridge id)kSecAttrProtocol];
                    if(incomingPort)
                        [query setObject:incomingPort forKey:(__bridge id)kSecAttrPort];
                }
                else
                {
                    [query setObject:(__bridge id)kSecAttrProtocolSMTP forKey:(__bridge id)kSecAttrProtocol];
                    if(outgoingPort)
                        [query setObject:outgoingPort forKey:(__bridge id)kSecAttrPort];
                }

                CFTypeRef persistentRef = NULL;

                //add it to the keychain
                osStatus = SecItemAdd((__bridge CFDictionaryRef)query, &persistentRef);

                if((osStatus != noErr) || !persistentRef)
                    NSLog(@"Error: could not add item to keychain!!! %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:osStatus userInfo:nil]);
                else
                {
                    NSLog(@"Password set! Account: %@", displayName);

                    dispatch_async(dispatch_get_main_queue(), ^{

                        if(isIncoming)
                            [accountSetting setIncomingPasswordRef:[[NSData alloc] initWithData:(__bridge NSData*)persistentRef]];
                        else
                            [accountSetting setOutgoingPasswordRef:[[NSData alloc] initWithData:(__bridge NSData*)persistentRef]];
                        [CoreDataHelper save];

                        if(callback)
                            callback(YES);

                        CFRelease(persistentRef);
                    });
                }
            }
        }
    });
}


//checks if a password for the specified email address and server is found in the keychain (without querying the password, so that no user permission is required)
+ (BOOL)haveKeychainPasswordForEmail:(NSString*)email andServer:(NSString*)server
{
    NSMutableDictionary *query = [self queryDictionaryForEmail:email withServer:server];

    //just return a ref - no permission ought to be needed
    [query setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];

    //one will be sufficient
    [query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];

    CFDataRef pwdDataRef;
    OSStatus osStatus = SecItemCopyMatching((__bridge CFDictionaryRef)(query), (CFTypeRef*)&pwdDataRef);
    if (osStatus == noErr)
    {
        BOOL valueFound = (pwdDataRef!=NULL);
        if(pwdDataRef)
            CFRelease(pwdDataRef);
        return valueFound;
    }

    return NO;
}


+ (BOOL)removePasswordForAccount:(NSManagedObjectID*)accountSettingID incoming:(BOOL)isIncoming
{
    __block BOOL returnValue = NO;


    [ThreadHelper runSyncOnMain:^{

        @try
        {
            IMAPAccountSetting* accountSetting = (IMAPAccountSetting*)[MAIN_CONTEXT objectWithID:accountSettingID];

            if(accountSetting)
            {
                NSString* emailAddress = [accountSetting.emailAddress lowercaseString];

                NSString* serverName = [isIncoming?accountSetting.incomingServer:accountSetting.outgoingServer lowercaseString];

                NSData* keychainItemRef = isIncoming?accountSetting.incomingPasswordRef:accountSetting.outgoingPasswordRef;

                if(keychainItemRef)
                {
                    NSMutableDictionary *query = [self queryDictionaryForEmail:emailAddress withServer:serverName];

                    //[query setObject:keychainItemRef forKey:(__bridge id<NSCopying>)(kSecValuePersistentRef)];
                    //[query setObject:isIncoming?kSecAttrProtocolIMAP:kSecAttrProtocolSMTP forKey:kSecAttrProtocol];

                    OSStatus osStatus = SecItemDelete((__bridge CFDictionaryRef)query);

                    if(osStatus != noErr)
                    {
                        NSLog(@"Failed to remove keychain password: %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:osStatus userInfo:nil]);
                    }

                    returnValue = (osStatus == noErr);
                }
                else
                    NSLog(@"Could not find password for account %@, no password ref set!",accountSetting.displayName);
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Exception caught: %@",exception);
            return;
        }
        @finally {
        }

    }];

    return returnValue;
}


+ (NSString*)findPasswordForAccount:(NSManagedObjectID*)accountSettingID incoming:(BOOL)isIncoming
{
    if(!accountSettingID)
        return nil;

    __block NSString* result = @"";

    [ThreadHelper runSyncOnMain:^{

        @try
        {
            IMAPAccountSetting* accountSetting = (IMAPAccountSetting*)[MAIN_CONTEXT objectWithID:accountSettingID];
            if(accountSetting)
            {
                NSData* keychainItemRef = isIncoming?accountSetting.incomingPasswordRef:accountSetting.outgoingPasswordRef;

                //NSString* emailAddress = [accountSetting.emailAddress lowercaseString];
                //NSString* serverName = [isIncoming?accountSetting.incomingServer:accountSetting.outgoingServer lowercaseString];

                if(keychainItemRef)
                {
                    NSMutableDictionary *query = [NSMutableDictionary new];
                    [query setObject:(__bridge id)kSecClassInternetPassword forKey:(__bridge id)kSecClass];
                    [query setObject:keychainItemRef forKey:(__bridge id<NSCopying>)(kSecValuePersistentRef)];
                    [query setObject:(__bridge id)(kSecMatchLimitOne) forKey:(__bridge id<NSCopying>)(kSecMatchLimit)];
                    [query setObject:(id)kCFBooleanTrue forKey:(__bridge id<NSCopying>)(kSecReturnData)];

                    CFTypeRef pwdDataRef = NULL;
                    OSStatus osStatus = SecItemCopyMatching((__bridge CFDictionaryRef)query, &pwdDataRef);

                    if((osStatus == noErr) && pwdDataRef)
                    {
                        NSData* pwdData = (__bridge NSData*)pwdDataRef;
                        NSString* pwdString = [[NSString alloc] initWithBytes:pwdData.bytes length:pwdData.length encoding:NSUTF8StringEncoding];
                        result = pwdString;
                    }
                    else
                        NSLog(@"Password for account %@ could not be found: %@",accountSetting.displayName,[NSError errorWithDomain:NSOSStatusErrorDomain code:osStatus userInfo:nil]);
                    if(pwdDataRef)
                        CFRelease(pwdDataRef);
                }
                else
                    NSLog(@"Could not find password for account %@, no password ref set!",accountSetting.displayName);
            }
            else
                NSLog(@"Not a valid account setting while trying to find password!");
        }
        @catch (NSException *exception) {
            NSLog(@"Exception caught: %@",exception);
            return;
        }
        @finally {
        }

    }];

    return result;
}


#pragma mark - KEY ATTRIBUTE DICTIONARIES

//a dictionary of generic values for Mynigma-type RSA keys
+ (NSMutableDictionary*)RSAKeyAttributes
{
    NSMutableDictionary* passDict = [NSMutableDictionary new];
    [passDict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    //[passDict setObject:@4096 forKey:(__bridge id)kSecAttrKeySizeInBits];
    [passDict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];

    return passDict;
}

//a dictionary describing a Mynigma public key corresponding to the specified label - this dictionary is used for adding a key to the keychain and contains more attributes than the search dictionary, just to be on the safe side, since attributes might change in future versions
+ (NSMutableDictionary*)publicKeyAdditionDictForLabel:(NSString*)keyLabel forEncryption:(BOOL)forEncryption
{
#if TARGET_OS_IPHONE

    NSMutableDictionary* passDict = [NSMutableDictionary new];

    NSString* attrLabel = forEncryption?[NSString stringWithFormat:@"Mynigma encryption key %@", keyLabel]:[NSString stringWithFormat:@"Mynigma signature key %@", keyLabel];

    [passDict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [passDict setObject:attrLabel forKey:(__bridge id)kSecAttrApplicationTag];
    [passDict setObject:attrLabel forKey:(__bridge id)kSecAttrLabel];
    [passDict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];

    [passDict setObject:(__bridge id)kSecAttrKeyClassPublic forKey:(__bridge id)kSecAttrKeyClass];

    return passDict;

#else

    NSMutableDictionary* passDict = [NSMutableDictionary new];
    [passDict setObject:(id)kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
    [passDict setObject:@4096 forKey:(id)kSecAttrKeySizeInBits];
    [passDict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];

    //    SecAccessRef accessRef = [KeychainHelper accessRef:NO];
    //    if(accessRef)
    //        [passDict setObject:(__bridge id)accessRef forKey:kSecAttrAccess];

    NSString* attrLabel = forEncryption?[NSString stringWithFormat:@"Mynigma encryption key %@", keyLabel]:[NSString stringWithFormat:@"Mynigma signature key %@", keyLabel];


    if(forEncryption)
    {
        [passDict setObject:@"Mynigma encryption key" forKey:(__bridge id)kSecAttrDescription];
        [passDict setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanVerify];
        [passDict setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanSign];
        [passDict setObject:@YES forKey:(__bridge id)kSecAttrCanEncrypt];
    }
    else
    {
        [passDict setObject:@"Mynigma signature key" forKey:(__bridge id)kSecAttrDescription];
        [passDict setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanDecrypt];
        [passDict setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanEncrypt];
        [passDict setObject:@YES forKey:(__bridge id)kSecAttrCanVerify];
    }

    [passDict setObject:attrLabel forKey:(__bridge id)kSecAttrLabel];

    [passDict setObject:(__bridge id)kSecAttrKeyClassPublic forKey:(__bridge id)kSecAttrKeyClass];

    [passDict setObject:@YES forKey:kSecAttrIsPermanent];

    return passDict;

#endif
}

+ (NSMutableDictionary*)publicKeySearchDictForLabel:(NSString*)keyLabel forEncryption:(BOOL)forEncryption
{
#if TARGET_OS_IPHONE

    NSMutableDictionary* passDict = [NSMutableDictionary new];

    NSString* attrLabel = forEncryption?[NSString stringWithFormat:@"Mynigma encryption key %@", keyLabel]:[NSString stringWithFormat:@"Mynigma signature key %@", keyLabel];

    [passDict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];

    [passDict setObject:attrLabel forKey:(__bridge id)kSecAttrLabel];
    [passDict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];

    [passDict setObject:(__bridge id)kSecAttrKeyClassPublic forKey:(__bridge id)kSecAttrKeyClass];

    return passDict;

#else

    NSMutableDictionary* passDict = [NSMutableDictionary new];

    NSString* attrLabel = forEncryption?[NSString stringWithFormat:@"Mynigma encryption key %@", keyLabel]:[NSString stringWithFormat:@"Mynigma signature key %@", keyLabel];

    [passDict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];

    [passDict setObject:attrLabel forKey:(__bridge id)kSecAttrLabel];
    [passDict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];

    [passDict setObject:(__bridge id)kSecAttrKeyClassPublic forKey:(__bridge id)kSecAttrKeyClass];

    return passDict;

#endif
}


//a dictionary describing a Mynigma private key corresponding to the specified label
+ (NSMutableDictionary*)privateKeyAdditionDictForLabel:(NSString*)keyLabel forEncryption:(BOOL)forEncryption
{

#if TARGET_OS_IPHONE

    NSMutableDictionary* passDict = [NSMutableDictionary new];

    NSString* attrLabel = [NSString stringWithFormat:@"%@%@", forEncryption?@"Mynigma encryption key ":@"Mynigma signature key ", keyLabel];

    [passDict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [passDict setObject:attrLabel forKey:(__bridge id)kSecAttrApplicationTag];
    [passDict setObject:attrLabel forKey:(__bridge id)kSecAttrLabel];
    [passDict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [passDict setObject:(__bridge id)kSecAttrKeyClassPrivate forKey:(__bridge id)kSecAttrKeyClass];

    return passDict;

    //    NSMutableDictionary* passDict = [NSMutableDictionary new];
    //    [passDict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    //    [passDict setObject:@4096 forKey:(__bridge id)kSecAttrKeySizeInBits];
    //
    //    if(forEncryption)
    //    {
    //        [passDict setObject:@"Mynigma encryption key" forKey:(__bridge id)kSecAttrDescription];
    //        [passDict setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanVerify];
    //        [passDict setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanSign];
    //    }
    //    else
    //    {
    //        [passDict setObject:@"Mynigma signature key" forKey:(__bridge id)kSecAttrDescription];
    //        [passDict setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanDecrypt];
    //        [passDict setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanEncrypt];
    //    }
    //
    //    NSString* attrLabel = [NSString stringWithFormat:@"%@%@", forEncryption?@"Mynigma encryption key ":@"Mynigma signature key ", keyLabel];
    //
    //    [passDict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    //
    //    [passDict setObject:attrLabel forKey:(__bridge id)kSecAttrApplicationTag];
    //    [passDict setObject:attrLabel forKey:(__bridge id)kSecAttrLabel];
    //
    //    [passDict setObject:(__bridge id)kSecAttrKeyClassPrivate forKey:(__bridge id)kSecAttrKeyClass];
    //
    //    [passDict setObject:@YES forKey:(__bridge id<NSCopying>)(kSecAttrIsPermanent)];
    //
    //    return passDict;

#else

    NSMutableDictionary* passDict = [NSMutableDictionary new];
    [passDict setObject:(id)kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
    [passDict setObject:@4096 forKey:(id)kSecAttrKeySizeInBits];
    [passDict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];

    NSString* attrLabel = [NSString stringWithFormat:@"%@%@", forEncryption?@"Mynigma encryption key ":@"Mynigma signature key ", keyLabel];

    if(forEncryption)
    {
        [passDict setObject:@"Mynigma encryption key" forKey:(__bridge id)kSecAttrDescription];
        [passDict setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanVerify];
        [passDict setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanSign];
    }
    else
    {
        [passDict setObject:@"Mynigma signature key" forKey:(__bridge id)kSecAttrDescription];
        [passDict setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanDecrypt];
        [passDict setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanEncrypt];
    }

    [passDict setObject:attrLabel forKey:(__bridge id)kSecAttrLabel];

    [passDict setObject:(__bridge id)kSecAttrKeyClassPrivate forKey:(__bridge id)kSecAttrKeyClass];

    [passDict setObject:@YES forKey:kSecAttrIsPermanent];

    //    SecAccessRef accessRef = [KeychainHelper accessRef:NO];
    //    if(accessRef)
    //        [passDict setObject:(__bridge id)accessRef forKey:kSecAttrAccess];

    return passDict;

#endif
}

+ (NSMutableDictionary*)privateKeySearchDictForLabel:(NSString*)keyLabel forEncryption:(BOOL)forEncryption
{
#if TARGET_OS_IPHONE

    NSMutableDictionary* passDict = [NSMutableDictionary new];

    NSString* attrLabel = [NSString stringWithFormat:@"%@%@", forEncryption?@"Mynigma encryption key ":@"Mynigma signature key ", keyLabel];

    [passDict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];

    //[passDict setObject:[NSData dataWithBytes:[attrLabel UTF8String] length:[attrLabel length]] forKey:(__bridge id)kSecAttrApplicationTag];

    [passDict setObject:attrLabel forKey:(__bridge id)kSecAttrLabel];

    [passDict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];

    [passDict setObject:(__bridge id)kSecAttrKeyClassPrivate forKey:(__bridge id)kSecAttrKeyClass];

    //[passDict setObject:@YES forKey:(__bridge id<NSCopying>)(kSecAttrIsPermanent)];

    return passDict;

#else

    NSMutableDictionary* passDict = [NSMutableDictionary new];

    NSString* attrLabel = [NSString stringWithFormat:@"%@%@", forEncryption?@"Mynigma encryption key ":@"Mynigma signature key ", keyLabel];

    [passDict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];

    //[passDict setObject:[NSData dataWithBytes:[attrLabel UTF8String] length:[attrLabel length]] forKey:(__bridge id)kSecAttrApplicationTag];

    [passDict setObject:attrLabel forKey:(__bridge id)kSecAttrLabel];

    [passDict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];

    [passDict setObject:(__bridge id)kSecAttrKeyClassPrivate forKey:(__bridge id)kSecAttrKeyClass];

    /*
     SecKeychainRef loginKeychain = NULL;

     SecKeychainCopyDefault(&loginKeychain);

     if(loginKeychain != NULL)
     {
     [passDict setObject:[NSArray arrayWithObject:CFBridgingRelease(loginKeychain)] forKey:kSecMatchSearchList];
     }*/

    [passDict setObject:@YES forKey:kSecAttrIsPermanent];

    return passDict;

#endif
}

#if TARGET_OS_IPHONE
#else
+ (SecItemImportExportKeyParameters)importExportParams:(BOOL)forEncryption
{
    SecItemImportExportKeyParameters params;

    params.version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
    params.flags = 0;

    params.passphrase = NULL;
    params.alertTitle = NULL;
    params.alertPrompt = NULL;

    //    SecAccessRef accessRef = [KeychainHelper accessRef:NO];
    //    if(accessRef)
    //        params.accessRef = accessRef;

    //    [KeychainHelper dumpAccessRefToLog:accessRef];

    params.keyAttributes = NULL;

    if(forEncryption)
        params.keyUsage = (__bridge CFArrayRef)@[(__bridge id)kSecAttrCanEncrypt];
    else
        params.keyUsage = (__bridge CFArrayRef)@[(__bridge id)kSecAttrCanVerify];

    return params;
}

+ (void)dumpAccessRefForPersistentRefToLog:(NSData*)persistentRef
{
    SecKeychainItemRef keyRef = (SecKeychainItemRef)[KeychainHelper keyRefForPersistentRef:persistentRef];

    [KeychainHelper dumpAccessRefForKeyRefToLog:keyRef];
}

+ (void)dumpAccessRefForKeyRefToLog:(SecKeychainItemRef)itemRef
{
    SecAccessRef encAccessRef = NULL;

    /*OSStatus status = */SecKeychainItemCopyAccess(itemRef, &encAccessRef);

    [KeychainHelper dumpAccessRefToLog:encAccessRef];
}


+ (void)dumpAccessRefToLog:(SecAccessRef)accessRef
{
    CFArrayRef encACLList = NULL;

    OSStatus status = SecAccessCopyACLList(accessRef, &encACLList);

    if (encACLList) {

        NSInteger ACLCount = CFArrayGetCount(encACLList);

        NSLog(@"\n\n%ld ACL entries:\n", ACLCount);

        for(NSInteger i = 0; i < ACLCount; i++)
        {
            SecACLRef ACLRef = (SecACLRef)CFArrayGetValueAtIndex(encACLList, i);

            CFArrayRef applicationListRef = NULL;

            CFStringRef description = NULL;

            SecKeychainPromptSelector promptSelector = 0;

            status = SecACLCopyContents(ACLRef, &applicationListRef, &description, &promptSelector);

            NSArray* authorisations = (__bridge NSArray*)SecACLCopyAuthorizations(ACLRef);

            NSLog(@"Application list: %@\nDescription: %@\nPrompt selector: %x\nAuthorizations: %@", applicationListRef, description, promptSelector, authorisations);
        }
    }
}



+ (void)setAccessRightsForKey:(SecKeychainItemRef)keyRef withDescription:(NSString*)descriptionString
{
    //    [self dumpAccessRefForKeyRefToLog:keyRef];



    SecTrustedApplicationRef thisApplication = NULL;

    OSStatus status = SecTrustedApplicationCreateFromPath(NULL, &thisApplication);

    if(status != noErr || thisApplication == NULL)
    {
        NSLog(@"Error setting access rights for freshly added keychain item! %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);

        return;
    }

    SecAccessRef itemAccess = NULL; //SecAccessCreateWithOwnerAndACL(getuid(), 0, kSecUseOnlyUID, (__bridge CFArrayRef)@[], NULL);

    status = SecKeychainItemCopyAccess(keyRef, &itemAccess);

    CFArrayRef encACLList = NULL;

    status = SecAccessCopyACLList(itemAccess, &encACLList);

    NSArray* ACLListCopy = [(__bridge NSArray*)encACLList copy];

    //    BOOL haveExportAuth = NO;

    for(NSInteger i = 0; i < ACLListCopy.count; i++)
    {
        SecACLRef ACLRef = (__bridge SecACLRef)ACLListCopy[i];

        //NSArray* auths = (__bridge NSArray*)SecACLCopyAuthorizations(ACLRef);

        //if(![auths containsObject:(__bridge id)kSecACLAuthorizationAny])
        {
            CFArrayRef applicationListRef = NULL;
            //
            CFStringRef description = NULL;
            //
            SecKeychainPromptSelector promptSelector = 0;
            //
            status = SecACLCopyContents(ACLRef, &applicationListRef, &description, &promptSelector);

            promptSelector = kSecKeychainPromptRequirePassphase;

            NSArray* newTrustedAppArray = applicationListRef?[(__bridge NSArray*)applicationListRef arrayByAddingObject:(__bridge id)(thisApplication)]:@[(__bridge id)thisApplication];

            SecACLSetContents(ACLRef, (__bridge CFArrayRef)newTrustedAppArray, (__bridge CFStringRef)descriptionString, promptSelector);
        }
    }

    SecKeychainItemSetAccess(keyRef, itemAccess);

    //    [self dumpAccessRefForKeyRefToLog:keyRef];
}

+ (void)temporarilyGrantPermissiveAccessRightsForPublicKeyKeychainItem:(SecKeychainItemRef)keyRef
{
    SecAccessRef itemAccess = NULL; //SecAccessCreateWithOwnerAndACL(getuid(), 0, kSecUseOnlyUID, (__bridge CFArrayRef)@[], NULL);

    OSStatus status = SecKeychainItemCopyAccess(keyRef, &itemAccess);

    CFArrayRef encACLList = NULL;

    status = SecAccessCopyACLList(itemAccess, &encACLList);

    NSArray* ACLListCopy = [(__bridge NSArray*)encACLList copy];

    //    BOOL haveExportAuth = NO;

    for(NSInteger i = 0; i < ACLListCopy.count; i++)
    {
        SecACLRef ACLRef = (__bridge SecACLRef)ACLListCopy[i];

        NSArray* auths = (__bridge NSArray*)SecACLCopyAuthorizations(ACLRef);

        if([auths containsObject:(__bridge id)kSecACLAuthorizationAny])
        {
            //            CFArrayRef applicationListRef = NULL;
            //
            //            CFStringRef description = NULL;
            //
            SecKeychainPromptSelector promptSelector = 0;
            //
            //            status = SecACLCopyContents(ACLRef, &applicationListRef, &description, &promptSelector);
            //
            promptSelector = 0;

            SecACLSetContents(ACLRef, NULL, NULL, promptSelector);
        }
    }

    SecKeychainItemSetAccess(keyRef, itemAccess);

    //    [self dumpAccessRefForKeyRefToLog:keyRef];
}

+ (void)setAccessRightsForPassword:(SecKeychainItemRef)keyRef isPassword:(BOOL)isPassword
{
    [self dumpAccessRefForKeyRefToLog:keyRef];

    SecTrustedApplicationRef thisApplication = NULL;

    OSStatus status = SecTrustedApplicationCreateFromPath(NULL, &thisApplication);

    if(status != noErr || thisApplication == NULL)
    {
        NSLog(@"Error setting access rights for freshly added keychain item! %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);

        return;
    }

    NSArray* newTrustedAppArray = @[(__bridge id)thisApplication];

    //CFStringRef description = (CFStringRef)@"Mynigma Key";

    SecKeychainPromptSelector promptSelector = /*kSecKeychainPromptInvalid | kSecKeychainPromptInvalidAct | kSecKeychainPromptUnsigned | kSecKeychainPromptUnsignedAct |*/ kSecKeychainPromptRequirePassphase;

    //SecACLRef newACL = NULL;

    //NSError* error = nil;

    SecAccessRef itemAccess = NULL; //SecAccessCreateWithOwnerAndACL(getuid(), 0, kSecUseOnlyUID, (__bridge CFArrayRef)@[], NULL);

    status = SecKeychainItemCopyAccess(keyRef, &itemAccess);

    CFArrayRef encACLList = NULL;

    status = SecAccessCopyACLList(itemAccess, &encACLList);

    NSArray* ACLListCopy = [(__bridge NSArray*)encACLList copy];

    //    BOOL haveExportAuth = NO;

    for(NSInteger i = 0; i < ACLListCopy.count; i++)
    {
        SecACLRef ACLRef = (__bridge SecACLRef)ACLListCopy[i];

        CFArrayRef applicationListRef = NULL;

        CFStringRef description = NULL;

        status = SecACLCopyContents(ACLRef, &applicationListRef, &description, &promptSelector);

        SecACLSetContents(ACLRef, (__bridge CFArrayRef)newTrustedAppArray, (__bridge CFStringRef)(@"Mynigma account password"), promptSelector);
    }

    SecKeychainItemSetAccess(keyRef, itemAccess);

    //    [self dumpAccessRefForKeyRefToLog:keyRef];
}

#endif

//the SecAccessRef to be set for new keychain items
//isPassword is YES for passwords and NO for keys
//+ (SecAccessRef)accessRef:(BOOL)isPassword
//{
//    //    SecAccessControlCreateWithFlags(<#CFAllocatorRef allocator#>, <#CFTypeRef protection#>, <#SecAccessControlCreateFlags flags#>, <#CFErrorRef *error#>)
//
////    CFArrayRef authorizations = SecACLCopyAuthorizations
//
//    SecTrustedApplicationRef thisApplication = NULL;
//
//    OSStatus status = SecTrustedApplicationCreateFromPath(NULL, &thisApplication);
//
//    if(status != noErr || thisApplication == NULL)
//    {
//        NSLog(@"Error setting access rights for freshly added keychain item! %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);
//
//        return NULL;
//    }
//
//    NSArray* newTrustedAppArray = @[(__bridge id)thisApplication];
//
//    CFStringRef description = (CFStringRef)@"Mynigma Key";
//
//    SecKeychainPromptSelector promptSelector = /*kSecKeychainPromptInvalid | kSecKeychainPromptInvalidAct | kSecKeychainPromptUnsigned | kSecKeychainPromptUnsignedAct |*/ kSecKeychainPromptRequirePassphase;
//
//    //SecACLRef newACL = NULL;
//
//    //NSError* error = nil;
//
//    SecAccessRef itemAccess = NULL; //SecAccessCreateWithOwnerAndACL(getuid(), 0, kSecUseOnlyUID, (__bridge CFArrayRef)@[], NULL);
//
//    status = SecAccessCreate(description, (__bridge CFArrayRef)newTrustedAppArray, &itemAccess);
//
//    //    status = SecACLCreateWithSimpleContents(itemAccess, (__bridge CFArrayRef)(newTrustedAppArray), description, promptSelector, &newACL);
//
//    //   status = SecACLUpdateAuthorizations(newACL, (__bridge CFArrayRef)@[@(CSSM_ACL_AUTHORIZATION_ANY)]);
//
////    SecACLRef ACLEntryChangeACL = SecACLC
//
//
//    //itemAccess = SecAccessCreateWithOwnerAndACL(<#uid_t userId#>, <#gid_t groupId#>, <#SecAccessOwnerType ownerType#>, <#CFArrayRef acls#>, <#CFErrorRef *error#>)
//
//    CFArrayRef encACLList = NULL;
//
//    status = SecAccessCopyACLList(itemAccess, &encACLList);
//
////    BOOL haveACLChangeAuth = NO;
//
////    BOOL haveNonACLChangeAuth = NO;
//
//    NSArray* ACLListCopy = [(__bridge NSArray*)encACLList copy];
//
////    NSMutableArray* newACLList = [NSMutableArray new];
//
//    for(NSInteger i = 0; i < ACLListCopy.count; i++)
//    {
//        SecACLRef ACLRef = (__bridge SecACLRef)ACLListCopy[i];
//
//        CFArrayRef applicationListRef = NULL;
//
//        CFStringRef description = NULL;
//
//        status = SecACLCopyContents(ACLRef, &applicationListRef, &description, &promptSelector);
//
//        //        NSArray* auths = (__bridge NSArray*)SecACLCopyAuthorizations(ACLRef);
//
//        //if(![auths containsObject:@"ACLAuthorizationChangeACL"])
//                {
//                    //                    status = status ?: SecACLRemove (ACLRef);
//
//                    //            status = status ?: SecACLCreateWithSimpleContents (itemAccess, (__bridge CFArrayRef)newTrustedAppArray, description, promptSelector, &ACLRef);
////
////                    if([auths containsObject:(__bridge id)kSecACLAuthorizationDecrypt])
////                    {
////                        auths = @[(__bridge id)kSecACLAuthorizationAny];
////                    }
////
////                    status = status ?: SecACLUpdateAuthorizations(ACLRef, (__bridge CFArrayRef)auths);
//                }
//
//        SecACLSetContents(ACLRef, (__bridge CFArrayRef)newTrustedAppArray, (__bridge CFStringRef)(isPassword?@"Mynigma account password":@"Mynigma key"), promptSelector);
////
////        status = SecACLCopyContents(ACLRef, &applicationListRef, &description, &promptSelector);
////
////        auths = (__bridge NSArray*)SecACLCopyAuthorizations(ACLRef);
////
////        //SecACLRef newACLRef = NULL;
////
////        //status = SecACLCreateWithSimpleContents(NULL, (__bridge CFArrayRef)newTrustedAppArray, (__bridge CFStringRef)(isPassword?@"Mynigma account password":@"Mynigma key"), promptSelector, &newACLRef);
////
////        [newACLList addObject:(__bridge id)ACLRef];
//
//        //SecACL
//
////        if([auths containsObject:@"ACLAuthorizationChangeACL"])
////        {
////            haveACLChangeAuth = YES;
////            [newACLList addObject:(__bridge id)ACLRef];
////        }
////        else if(haveNonACLChangeAuth)
////        {
////            SecACLRemove(ACLRef);
////        }
////        else
////        {
////            haveNonACLChangeAuth = YES;
////            NSArray* newAuths = @[(__bridge id)kSecACLAuthorizationAny];
////            //NSArray* newAuths = @[(__bridge id)kSecACLAuthorizationDecrypt, (__bridge id)kSecACLAuthorizationDelete, (__bridge id)kSecACLAuthorizationDerive, (__bridge id)kSecACLAuthorizationEncrypt, (__bridge id)kSecACLAuthorizationExportClear, (__bridge id)kSecACLAuthorizationExportWrapped, (__bridge id)kSecACLAuthorizationGenKey, (__bridge id)kSecACLAuthorizationImportClear, (__bridge id)kSecACLAuthorizationImportWrapped, (__bridge id)kSecACLAuthorizationMAC, (__bridge id)kSecACLAuthorizationSign];
////            SecACLUpdateAuthorizations(ACLRef, (__bridge CFArrayRef)newAuths);
//////            SecACLUpdateAuthorizations(ACLRef, (__bridge CFArrayRef)@[(__bridge id)kSecACLAuthorizationDecrypt, (__bridge id)kSecACLAuthorizationDelete, (__bridge id)kSecACLAuthorizationDerive, (__bridge id)kSecACLAuthorizationEncrypt, (__bridge id)kSecACLAuthorizationExportClear, (__bridge id)kSecACLAuthorizationExportWrapped, (__bridge id)kSecACLAuthorizationGenKey, (__bridge id)kSecACLAuthorizationImportClear, (__bridge id)kSecACLAuthorizationImportWrapped, (__bridge id)kSecACLAuthorizationMAC, (__bridge id)kSecACLAuthorizationSign]);
////
////            [newACLList addObject:(__bridge id)ACLRef];
////        }
//
//        //NSArray* authArray = (__bridge NSArray*)SecACLCopyAuthorizations(ACLRef);
//
//        //NSLog(@"%@ %@ %@ %@", applicationListRef, description, @(promptSelector), authArray);
//    }
//
////    SecACLRef ACLRef = NULL;
////
////    SecACLCreateWithSimpleContents (itemAccess, NULL, description, 0, &ACLRef);
////
////    SecACLUpdateAuthorizations(ACLRef, (__bridge CFArrayRef)@[(__bridge id)kSecACLAuthorizationAny]);
//
//    //NSError* error = nil;
//
//    //itemAccess = SecAccessCreateWithOwnerAndACL(getuid(), 0, kSecUseOnlyUID, (__bridge CFArrayRef)newACLList, NULL);
//
//
//
//
//                                                //SecAccessCreateWithOwnerAndACL(getuid(), 0, kSecUseOnlyUID, (__bridge CFArrayRef)@[], NULL);
//    [KeychainHelper dumpAccessRefToLog:itemAccess];
//
//    return itemAccess;
//}

#pragma mark - KEYCHAIN ITEMS LISTS

//lists all Mynigma public keys found in the keychain (as dictionaries of attributes)
//including a persistent reference
+ (NSArray*)listPublicKeychainItems
{
    __block NSArray* returnValue = [NSMutableArray new];

    //don't hit the keychain more than once - it will block and cause a beach ball if too many threads try at once
    [ThreadHelper synchronizeIfNotOnMain:@"LIST_PUBLIC_KEYCHAIN_ITEMS" block:
     ^{
        if(publicKeyItemsList)
        {
            returnValue = publicKeyItemsList;
            return;
        }

        NSMutableArray* workingArray = [NSMutableArray new];

        __block NSMutableDictionary* passDict = [self RSAKeyAttributes];

        [passDict setObject:(__bridge id)kSecAttrKeyClassPublic forKey:(__bridge id)kSecAttrKeyClass];
        [passDict setObject:(__bridge id)kSecMatchLimitAll forKey:(__bridge id)kSecMatchLimit];
        [passDict setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnPersistentRef];
        [passDict setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];

        CFArrayRef resultsArray = nil;
        OSStatus oserr = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, (CFTypeRef*)&resultsArray);
        NSArray* array = CFBridgingRelease(resultsArray);
        if(oserr == noErr && array.count>0)
        {
            [workingArray addObjectsFromArray:array];
        }

        returnValue = workingArray;

        publicKeyItemsList = workingArray;
    }];

    return returnValue;
}

//lists all Mynigma public keys found in the keychain (as dictionaries of attributes)
//excluding a persistent reference
+ (NSArray*)listPublicKeychainProperties
{
    __block NSArray* returnValue = [NSMutableArray new];

    //don't hit the keychain more than once - it will block and cause a beach ball if too many threads try at once
    [ThreadHelper synchronizeIfNotOnMain:@"LIST_PUBLIC_KEYCHAIN_ITEMS_PROPERTIES" block:
     ^{
        if(publicKeyItemsPropertiesList)
        {
            returnValue = publicKeyItemsPropertiesList;
            return;
        }

        NSMutableArray* workingArray = [NSMutableArray new];

        __block NSMutableDictionary* passDict = [self RSAKeyAttributes];

        [passDict setObject:(__bridge id)kSecAttrKeyClassPublic forKey:(__bridge id)kSecAttrKeyClass];
        [passDict setObject:(__bridge id)kSecMatchLimitAll forKey:(__bridge id)kSecMatchLimit];
        [passDict setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];

        CFArrayRef resultsArray = nil;
        OSStatus oserr = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, (CFTypeRef*)&resultsArray);
        NSArray* array = CFBridgingRelease(resultsArray);
        if(oserr == noErr && array.count>0)
        {
            [workingArray addObjectsFromArray:array];
        }

         returnValue = workingArray;

         publicKeyItemsPropertiesList = workingArray;
     }];

    return returnValue;
}

//lists all Mynigma private keys found in the keychain (as dictionaries of attributes)
//including a persistent reference
+ (NSArray*)listPrivateKeychainItems
{
    __block NSArray* returnValue = [NSMutableArray new];

    //don't hit the keychain more than once - it will block and cause a beach ball if too many threads try at once
    [ThreadHelper synchronizeIfNotOnMain:@"LIST_PRIVATE_KEYCHAIN_ITEMS" block:
     ^{
        if(privateKeyItemsList)
        {
            returnValue = privateKeyItemsList;
            return;
        }
        
    NSMutableArray* workingArray = [NSMutableArray new];

    __block NSMutableDictionary* passDict = [self RSAKeyAttributes];

    [passDict setObject:(__bridge id)kSecAttrKeyClassPrivate forKey:(__bridge id)kSecAttrKeyClass];
    [passDict setObject:(__bridge id)kSecMatchLimitAll forKey:(__bridge id)kSecMatchLimit];
    [passDict setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnPersistentRef];
    [passDict setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];

    CFArrayRef resultsArray = nil;
    OSStatus oserr = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, (CFTypeRef*)&resultsArray);
    NSArray* array = CFBridgingRelease(resultsArray);
    if(oserr == noErr && array.count>0)
    {
        [workingArray addObjectsFromArray:array];
    }
        returnValue = workingArray;

        privateKeyItemsList = workingArray;
    }];

    return returnValue;
}

//lists all Mynigma private keys found in the keychain (as dictionaries of attributes)
//excluding a persistent reference
+ (NSArray*)listPrivateKeychainProperties
{
    __block NSArray* returnValue = [NSMutableArray new];

    //don't hit the keychain more than once - it will block and cause a beach ball if too many threads try at once
    [ThreadHelper synchronizeIfNotOnMain:@"LIST_PRIVATE_KEYCHAIN_ITEMS_PROPERTIES" block:
     ^{
        if(privateKeyItemsPropertiesList)
        {
            returnValue = privateKeyItemsPropertiesList;
            return;
        }

   NSMutableArray* workingArray = [NSMutableArray new];

    __block NSMutableDictionary* passDict = [self RSAKeyAttributes];

    [passDict setObject:(__bridge id)kSecAttrKeyClassPrivate forKey:(__bridge id)kSecAttrKeyClass];
    [passDict setObject:(__bridge id)kSecMatchLimitAll forKey:(__bridge id)kSecMatchLimit];
    [passDict setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];

    CFArrayRef resultsArray = nil;
    OSStatus oserr = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, (CFTypeRef*)&resultsArray);
    NSArray* array = CFBridgingRelease(resultsArray);
    if(oserr == noErr && array.count>0)
    {
        [workingArray addObjectsFromArray:array];
    }

        returnValue = workingArray;

        privateKeyItemsPropertiesList = workingArray;
    }];

    return returnValue;
}

+ (void)dumpEntireKeychainToConsole
{
    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  (__bridge id)kCFBooleanTrue, (__bridge id)kSecReturnAttributes,
                                  (__bridge id)kSecMatchLimitAll, (__bridge id)kSecMatchLimit,
                                  nil];

    NSArray *secItemClasses = [NSArray arrayWithObjects:
                               (__bridge id)kSecClassGenericPassword,
                               (__bridge id)kSecClassInternetPassword,
                               (__bridge id)kSecClassCertificate,
                               (__bridge id)kSecClassKey,
                               (__bridge id)kSecClassIdentity,
                               nil];

    NSArray* descriptions = @[@"Generic passwords: ", @"Internet passwords: ", @"Certificates: ", @"Keys: ", @"Identities: "];

    NSLog(@"=== KEYCHAIN ===\n");

    NSInteger counter = 0;
    for (id secItemClass in secItemClasses)
    {
        [query setObject:secItemClass forKey:(__bridge id)kSecClass];

        CFTypeRef result = NULL;
        SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
        NSLog(@"%@%@\n", descriptions[counter], (__bridge id)result);
        counter++;
        if (result != NULL) CFRelease(result);
    }

    NSLog(@"================");
}



//fetch all keys that might be lingering in the keychain and add them to the store
+ (void)fetchAllKeysFromKeychainWithCallback:(void(^)(void))callback
{
    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

        NSArray* publicKeyDicts = [KeychainHelper listPublicKeychainItems];
        NSArray* privateKeyDicts = [KeychainHelper listPrivateKeychainItems];


        NSMutableArray* privateKeyLabels = [NSMutableArray new];

        for(NSDictionary* privateKeyDict in privateKeyDicts)
        {
            NSString* label = [privateKeyDict objectForKey:@"labl"];

            if(!label || [label isEqual:[NSNull null]])
                continue;

            NSData* persistentRef = [privateKeyDict objectForKey:@"v_PersistentRef"];

            if(!persistentRef)
                continue;

            NSRange range = [label rangeOfString:@"Mynigma signature key "];

            if(range.location!=NSNotFound && label.length>range.location+range.length) //signature key pair
            {
                NSString* keyLabel = [label substringFromIndex:range.location+range.length];

                [privateKeyLabels addObject:keyLabel];
            }
        }


        NSMutableArray* publicKeyLabels = [NSMutableArray new];

        for(NSDictionary* privateKeyDict in publicKeyDicts)
        {
            NSString* label = [privateKeyDict objectForKey:@"labl"];

            if(!label || [label isEqual:[NSNull null]])
                continue;

            NSData* persistentRef = [privateKeyDict objectForKey:@"v_PersistentRef"];

            if(!persistentRef)
                continue;

            NSRange range = [label rangeOfString:@"Mynigma signature key "];

            if(range.location!=NSNotFound && label.length>range.location+range.length) //signature key pair
            {
                NSString* keyLabel = [label substringFromIndex:range.location+range.length];

                [publicKeyLabels addObject:keyLabel];
            }
        }

        for(NSString* privateKeyLabel in privateKeyLabels)
        {
            if([MynigmaPrivateKey havePrivateKeyWithLabel:privateKeyLabel])
                continue;

            //no problem if there is an existing public key - it will be replaced...

            NSArray* keychainData = [KeychainHelper dataForPrivateKeychainItemWithLabel:privateKeyLabel];

            if(keychainData.count == 4)
            {
                NSData* decrKeyData = keychainData[0];

                NSData* signKeyData = keychainData[1];

                NSData* encrKeyData = keychainData[2];

                NSData* verKeyData = keychainData[3];

                [MynigmaPrivateKey syncMakeNewPrivateKeyWithEncData:encrKeyData andVerKeyData:verKeyData decKeyData:decrKeyData sigKeyData:signKeyData forEmail:nil keyLabel:privateKeyLabel];
            }
        }

        for(NSString* publicKeyLabel in publicKeyLabels)
        {
            if([MynigmaPublicKey havePublicKeyWithLabel:publicKeyLabel])
                continue;

            NSArray* keychainData = [KeychainHelper dataForPrivateKeychainItemWithLabel:publicKeyLabel];

            if(keychainData.count == 4)
            {
                NSData* encrKeyData = keychainData[0];

                NSData* verKeyData = keychainData[1];

                [MynigmaPublicKey syncMakeNewPublicKeyWithEncKeyData:encrKeyData andVerKeyData:verKeyData forEmail:nil keyLabel:publicKeyLabel];
            }
        }

        if(callback)
        {
            [ThreadHelper runAsyncOnMain:^{

                callback();
            }];
        }
    }];
}


#pragma mark - PUBLIC KEYS

//adds a single public key to the keychain
+ (NSData*)addPublicKeyWithData:(NSData*)data toKeychainWithLabel:(NSString*)keyLabel forEncryption:(BOOL)forEncryption
{
    if(!data)
    {
        NSLog(@"No data to add to keychain!!");
        return nil;
    }

#if TARGET_OS_IPHONE

    NSString* dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    //    NSLog(@"Data string: %@", dataString);

    NSData* DERData = [OpenSSLWrapper DERFileFromPEMKey:data withPassphrase:nil];

    dataString = [[NSString alloc] initWithData:DERData encoding:NSUTF8StringEncoding];

    //     NSLog(@"DER data string: %@", dataString);

    if(!DERData)
    {
        NSLog(@"Cannot add public key: DERData is nil!!");

        return nil;
    }

    SecCertificateRef cert = SecCertificateCreateWithData (kCFAllocatorDefault, (__bridge CFDataRef)(DERData));
    CFArrayRef certs = CFArrayCreate(kCFAllocatorDefault, (const void **) &cert, 1, NULL);

    SecTrustRef trustRef;
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustCreateWithCertificates(certs, policy, &trustRef);
    SecTrustResultType trustResult;
    SecTrustEvaluate(trustRef, &trustResult);
    SecKeyRef publicKeyRef = SecTrustCopyPublicKey(trustRef);

    __block NSMutableDictionary* passDict = [self publicKeyAdditionDictForLabel:keyLabel forEncryption:forEncryption];

    [passDict setObject:(__bridge id)(publicKeyRef) forKey:(__bridge id)kSecValueRef];
    [passDict setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnPersistentRef];

    CFTypeRef result = NULL;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)passDict, &result);

    if (status != noErr)
    {
        if(result)
            CFRelease(result);
        NSLog(@"Error adding keychain item! %@",[NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);
        return nil;
    }

    return CFBridgingRelease(result);

#else

    if([self havePublicKeychainItemWithLabel:keyLabel])
    {
        NSArray* dataArray = [KeychainHelper persistentRefsForPublicKeychainItemWithLabel:keyLabel];
        if(dataArray.count<2)
            return nil;

        return forEncryption?dataArray[0]:dataArray[1];
    }


    //first import the key: turn the PEM file into a SecKeyRef
    SecItemImportExportKeyParameters params = [self importExportParams:forEncryption];

    SecExternalItemType itemType = kSecItemTypePublicKey;
    SecExternalFormat externalFormat = kSecFormatPEMSequence;
    int flags = 0;

    CFArrayRef temparray;
    OSStatus oserr = SecItemImport((__bridge CFDataRef)data, NULL, &externalFormat, &itemType, flags, &params, NULL /*don't add to a keychain*/, &temparray);
    if (oserr != noErr || CFArrayGetCount(temparray)<1)
    {
        NSLog(@"Error importing key! %@",[NSError errorWithDomain:NSOSStatusErrorDomain code:oserr userInfo:nil]);
        return nil;
    }

    SecKeyRef encrKeyRef = (SecKeyRef)CFArrayGetValueAtIndex(temparray, 0);

    //now add it to the keychain - without a label at first (using a label doesn't work on add, so need to update the item later...)
    __block NSMutableDictionary* passDict = [self publicKeyAdditionDictForLabel:keyLabel forEncryption:forEncryption];

    [passDict setObject:(__bridge id)(encrKeyRef) forKey:kSecValueRef];

    [passDict setObject:@YES forKey:(__bridge id)kSecReturnPersistentRef];

    [passDict removeObjectForKey:(__bridge id)kSecAttrLabel];

    CFTypeRef result;

    oserr = SecItemAdd((__bridge CFDictionaryRef)passDict, &result);

    if(oserr != noErr)
    {
        NSLog(@"Error adding public keychain item: %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:oserr userInfo:nil]);
    }

    NSData* persistentRef = CFArrayGetValueAtIndex(result, 0);

    //almost done - just need to add the missing label
    NSMutableDictionary* query = [NSMutableDictionary dictionaryWithDictionary:@{(__bridge id)kSecValuePersistentRef:persistentRef}];

    query[(__bridge id)kSecClass] = (__bridge id)kSecClassKey;

    NSMutableDictionary* newAttributes = [NSMutableDictionary new];

    NSString* attrLabel = forEncryption?[NSString stringWithFormat:@"Mynigma encryption key %@", keyLabel]:[NSString stringWithFormat:@"Mynigma signature key %@", keyLabel];

    newAttributes[(__bridge id)kSecAttrLabel] = attrLabel;

    SecKeychainItemRef itemRef = (SecKeychainItemRef)[KeychainHelper keyRefForPersistentRef:persistentRef];

    oserr = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)newAttributes);
    if (oserr != noErr)
    {
        NSLog(@"Error updating keychain item! %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:oserr userInfo:nil]);
    }

    [self setAccessRightsForKey:itemRef withDescription:@"Mynigma public key"];

    return persistentRef;

#endif
}


+ (NSArray*)addPublicKeyWithLabel:(NSString*)keyLabel toKeychainWithEncData:(NSData*)encData verData:(NSData*)verData
{
    if(!keyLabel)
        return nil;


    if([self havePublicKeychainItemWithLabel:keyLabel])
    {
        if([self doesPublicKeychainItemWithLabel:keyLabel matchEncData:encData andVerData:verData])
        {
            //already have the same item in the keychain
            //nonetheless, need to point the persistent refs of the MynigmaPublicKey object to the correct location in the keychain

            return [self persistentRefsForPublicKeychainItemWithLabel:keyLabel];
        }
        else
            return nil;
    }


    NSData* persistentEncrKey = [self addPublicKeyWithData:encData toKeychainWithLabel:keyLabel forEncryption:YES];

    NSData* persistentVerKey = [self addPublicKeyWithData:verData toKeychainWithLabel:keyLabel forEncryption:NO];

    if(persistentEncrKey && persistentVerKey)
    {
        return @[persistentEncrKey, persistentVerKey];
    }

    return nil;
}

+ (BOOL)havePublicKeychainItemWithLabel:(NSString*)keyLabel
{
    BOOL allOK = YES;

    NSMutableDictionary* passDict = [self publicKeySearchDictForLabel:keyLabel forEncryption:YES];

    CFTypeRef result;

    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, &result);

    if(status != noErr)
    {
        allOK = NO;
    }

    passDict = [self publicKeySearchDictForLabel:keyLabel forEncryption:NO];

    status = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, &result);

    if(status != noErr)
    {
        allOK = NO;
    }

    return allOK;
}

+ (BOOL)removePublicKeychainItemWithLabel:(NSString*)keyLabel
{
    BOOL allOK = YES;

    __block NSMutableDictionary* passDict = [self publicKeySearchDictForLabel:keyLabel forEncryption:YES];

    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)passDict);

    if(status != noErr)
    {
        allOK = NO;
    }

    passDict = [self publicKeySearchDictForLabel:keyLabel forEncryption:NO];

    status = SecItemDelete((__bridge CFDictionaryRef)passDict);

    if(status != noErr)
    {
        allOK = NO;
    }

    return allOK;
}

+ (BOOL)doesPublicKeychainItemWithLabel:(NSString*)keyLabel matchEncData:(NSData*)encData andVerData:(NSData*)verData
{
    NSArray* existingKeyData = [self dataForPublicKeychainItemWithLabel:keyLabel];

    if(!existingKeyData || existingKeyData.count<2)
        return NO;

    NSData* existingEncKeyData = existingKeyData[0];

    NSData* existingVerKeyData = existingKeyData[1];

    if([existingEncKeyData isEqual:encData] && [existingVerKeyData isEqual:verData])
        return YES;

    return NO;
}

+ (NSArray*)dataForPublicKeychainItemWithLabel:(NSString*)keyLabel
{
    NSMutableDictionary* passDict = [self publicKeySearchDictForLabel:keyLabel forEncryption:YES];
    [passDict setObject:@YES forKey:(__bridge id)kSecReturnPersistentRef];

    CFTypeRef result = nil;

    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, &result);

    if(status != noErr)
    {
        NSError* error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"Error exporting key: %@", error);
        return nil;
    }

    NSData* persistentRefData = CFBridgingRelease(result);

    NSData* encKeyData = [self dataForPersistentRef:persistentRefData];

    passDict = [self publicKeySearchDictForLabel:keyLabel forEncryption:NO];
    [passDict setObject:@YES forKey:(__bridge id)kSecReturnPersistentRef];

    status = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, &result);

    if(status != noErr)
    {
        NSError* error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"Error exporting key: %@", error);
        return nil;
    }

    persistentRefData = CFBridgingRelease(result);

    NSData* verKeyData = [self dataForPersistentRef:persistentRefData];

    if(encKeyData && verKeyData)
        return @[encKeyData, verKeyData];

    return nil;
}



+ (NSArray*)persistentRefsForPublicKeychainItemWithLabel:(NSString*)keyLabel
{
    NSMutableDictionary* passDict = [self publicKeySearchDictForLabel:keyLabel forEncryption:YES];
    [passDict setObject:@YES forKey:(__bridge id)kSecReturnPersistentRef];

    CFTypeRef result = nil;

    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, &result);

    if(status != noErr)
    {
        NSError* error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"Error exporting key: %@", error);
        return nil;
    }

    NSData* persistentEncRef = CFBridgingRelease(result);

    passDict = [self publicKeySearchDictForLabel:keyLabel forEncryption:NO];
    [passDict setObject:@YES forKey:(__bridge id)kSecReturnPersistentRef];

    status = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, &result);

    if(status != noErr)
    {
        NSError* error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"Error exporting key: %@", error);
        return nil;
    }

    NSData* persistentVerRef = CFBridgingRelease(result);

    if(persistentEncRef && persistentVerRef)
        return @[persistentEncRef, persistentVerRef];

    return nil;
}







#pragma mark - PRIVATE KEYS


//adds a single private key to the keychain (low level, private method)
+ (NSData*)addPrivateKeyWithData:(NSData*)keyData toKeychainWithLabel:(NSString*)keyLabel forEncryption:(BOOL)forEncryption withPassphrase:(NSString*)passphrase
{
#if TARGET_OS_IPHONE

    if(passphrase)
    {
        NSData* PKCS12KeyData = [OpenSSLWrapper PKCS12FileFromPKCS8Key:keyData withPassphrase:passphrase];

        if(!PKCS12KeyData)
            return nil;

        NSDictionary* optionsDict = @{(__bridge id)kSecImportExportPassphrase:passphrase};

        CFArrayRef results = NULL;

        OSStatus status = SecPKCS12Import((__bridge CFDataRef)PKCS12KeyData, (__bridge CFDictionaryRef)optionsDict, &results);

        if (status != errSecSuccess || !results)
        {
            if(results)
                CFRelease(results);

            NSLog(@"Failed to import private key!! %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);

            return nil;
        }

        NSArray* items = CFBridgingRelease(results);

        if(items.count>0)
        {
            NSDictionary* identityAndTrust = items[0];
            SecIdentityRef identityRef = (__bridge SecIdentityRef)(identityAndTrust[(__bridge id)kSecImportItemIdentity]);

            SecKeyRef privateKey = NULL;
            status = SecIdentityCopyPrivateKey(identityRef, &privateKey);

            if (status) {
                NSLog(@"SecIdentityCopyPrivateKey failed. %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);

                if(privateKey)
                    CFRelease(privateKey);

                return nil;
            }

            NSMutableDictionary* passDict = [self privateKeyAdditionDictForLabel:keyLabel forEncryption:forEncryption];

            [passDict setObject:(__bridge id)(privateKey) forKey:(__bridge id)kSecValueRef];
            [passDict setObject:@YES forKey:(__bridge id)kSecReturnPersistentRef];


            CFTypeRef result = NULL;
            OSStatus status = SecItemAdd((__bridge CFDictionaryRef)passDict, &result);

            if(privateKey)
                CFRelease(privateKey);

            if (status != errSecSuccess || !result)
            {
                if(result)
                    CFRelease(result);
                NSLog(@"Error adding keychain item!!! %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);
                return nil;
            }

            return CFBridgingRelease(result);
        }

        return nil;
    }
    else
    {
        NSMutableDictionary* passDict = [self privateKeyAdditionDictForLabel:keyLabel forEncryption:forEncryption];

        [passDict setObject:keyData forKey:(__bridge id)kSecValueData];
        [passDict setObject:@YES forKey:(__bridge id)kSecReturnPersistentRef];


        CFTypeRef result = NULL;
        OSStatus status = SecItemAdd((__bridge CFDictionaryRef)passDict, &result);

        if (status != errSecSuccess || !result)
        {
            if(result)
                CFRelease(result);
            NSLog(@"Error adding keychain item! %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);
            return nil;
        }

        return CFBridgingRelease(result);
    }

    return nil;

#else

    if([self havePrivateKeychainItemWithLabel:keyLabel])
    {
        NSArray* dataArray = [KeychainHelper persistentRefsForPrivateKeychainItemWithLabel:keyLabel];
        if(dataArray.count<2)
            return nil;

        return forEncryption?dataArray[0]:dataArray[1];
    }

    SecItemImportExportKeyParameters params = [self importExportParams:forEncryption];

    SecExternalItemType itemType = kSecItemTypePrivateKey;
    SecExternalFormat externalFormat = kSecFormatPEMSequence;
    int flags = 0;

    if(passphrase)
    {
        passphrase = @"";
        params.passphrase = (__bridge_retained CFStringRef)passphrase;
        externalFormat = kSecFormatPKCS12;
    }

    params.keyUsage = forEncryption?(__bridge CFArrayRef)@[(__bridge id)kSecAttrCanDecrypt]:(__bridge CFArrayRef)@[(__bridge id)kSecAttrCanSign];


    CFArrayRef temparray;
    OSStatus oserr = SecItemImport((__bridge CFDataRef)keyData, NULL, &externalFormat /*NULL*/, &itemType, flags, &params, NULL, &temparray);

    if(params.passphrase)
        CFRelease(params.passphrase);

    if (oserr != noErr || CFArrayGetCount(temparray)<1) {
        NSLog(@"Error importing key! %@",[NSError errorWithDomain:NSOSStatusErrorDomain code:oserr userInfo:nil]);
        return nil;
    }

    SecKeyRef encrKeyRef = (SecKeyRef)CFArrayGetValueAtIndex(temparray, 0);

    //now add it to the keychain - without a label at first (using a label doesn't work on add, so need to update the item later...)
    __block NSMutableDictionary* passDict = [self privateKeyAdditionDictForLabel:keyLabel forEncryption:forEncryption];

    [passDict setObject:(__bridge id)(encrKeyRef) forKey:kSecValueRef];

    [passDict setObject:@YES forKey:(__bridge id)kSecReturnPersistentRef];

    [passDict removeObjectForKey:(__bridge id)kSecAttrLabel];

    CFTypeRef result;

    oserr = SecItemAdd((__bridge CFDictionaryRef)passDict, &result);

    if(oserr != noErr)
    {
        NSLog(@"Error adding private key to keychain: %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:oserr userInfo:nil]);
    }

    NSData* persistentRef = CFArrayGetValueAtIndex(result, 0);

    //almost done - just need to add the missing label
    NSMutableDictionary* query = [NSMutableDictionary dictionaryWithDictionary:@{(__bridge id)kSecValuePersistentRef:persistentRef}];

    query[(__bridge id)kSecClass] = (__bridge id)kSecClassKey;

    NSMutableDictionary* newAttributes = [NSMutableDictionary new];

    NSString* attrLabel = forEncryption?[NSString stringWithFormat:@"Mynigma encryption key %@", keyLabel]:[NSString stringWithFormat:@"Mynigma signature key %@", keyLabel];

    newAttributes[(__bridge id)kSecAttrLabel] = attrLabel;

    //    SecAccessRef accessRef = [self accessRef:NO];
    //    if(accessRef)
    //        newAttributes[(__bridge id)kSecAttrAccess] = (__bridge id)accessRef;


    oserr = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)newAttributes);
    if (oserr != noErr)
    {
        NSLog(@"Error updating keychain item! %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:oserr userInfo:nil]);
    }

    SecKeychainItemRef keyRef = (SecKeychainItemRef)[KeychainHelper keyRefForPersistentRef:persistentRef];

    [self setAccessRightsForKey:keyRef withDescription:@"Mynigma private key"];

    //    [self dumpAccessRefForKeyRefToLog:keyRef];

    return persistentRef;

#endif
}

//public method
+ (NSArray*)addPrivateKeyWithLabel:(NSString *)keyLabel toKeychainWithEncData:(NSData*)encData verData:(NSData*)verData decData:(NSData*)decData sigData:(NSData*)sigData
{
    return [self addPrivateKeyWithLabel:keyLabel toKeychainWithEncData:encData verData:verData decData:decData sigData:sigData passphrase:@""];
}

+ (NSArray*)addPrivateKeyWithLabel:(NSString *)keyLabel toKeychainWithEncData:(NSData*)encData verData:(NSData*)verData decData:(NSData*)decData sigData:(NSData*)sigData passphrase:(NSString*)passphrase
{
    if(!keyLabel)
        return nil;


    if([self havePrivateKeychainItemWithLabel:keyLabel])
    {
        if([self doesPrivateKeychainItemWithLabel:keyLabel matchDecData:decData sigData:sigData encData:encData verData:verData])
        {
            //already have the same item in the keychain
            //nonetheless, need to point the persistent refs of the MynigmaPublicKey object to the correct location in the keychain
            return [self persistentRefsForPrivateKeychainItemWithLabel:keyLabel];
        }
        else
            return nil;
    }

    if([self havePublicKeychainItemWithLabel:keyLabel])
    {
        if(![self doesPublicKeychainItemWithLabel:keyLabel matchEncData:encData andVerData:verData])
            NSLog(@"Adding private key that doesn't match the existing public key data(!!!)");

        //[]
    }


    NSData* persistentDecrRef = [self addPrivateKeyWithData:decData toKeychainWithLabel:keyLabel forEncryption:YES withPassphrase:passphrase];

    NSData* persistentSignRef = [self addPrivateKeyWithData:sigData toKeychainWithLabel:keyLabel forEncryption:NO withPassphrase:passphrase];

    //#endif

    NSData* persistentEncrRef = [self addPublicKeyWithData:encData toKeychainWithLabel:keyLabel forEncryption:YES];

    NSData* persistentVerRef = [self addPublicKeyWithData:verData toKeychainWithLabel:keyLabel forEncryption:NO];

    if(persistentDecrRef && persistentSignRef && persistentEncrRef && persistentVerRef)
    {
        return @[persistentDecrRef, persistentSignRef, persistentEncrRef, persistentVerRef];
    }

    return nil;
}


+ (BOOL)havePrivateKeychainItemWithLabel:(NSString*)keyLabel
{
    BOOL allOK = YES;

    NSMutableDictionary* passDict = [self privateKeySearchDictForLabel:keyLabel forEncryption:YES];

    CFTypeRef result;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, &result);

    if(status != noErr)
    {
        allOK = NO;
    }

    passDict = [self privateKeySearchDictForLabel:keyLabel forEncryption:NO];

    status = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, &result);

    if(status != noErr)
    {
        allOK = NO;
    }

    passDict = [self publicKeySearchDictForLabel:keyLabel forEncryption:YES];

    status = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, &result);

    if(status != noErr)
    {
        allOK = NO;
    }

    passDict = [self publicKeySearchDictForLabel:keyLabel forEncryption:NO];

    status = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, &result);

    if(status != noErr)
    {
        allOK = NO;
    }

    return allOK;
}


+ (BOOL)removePrivateKeychainItemWithLabel:(NSString*)keyLabel
{
#if TARGET_OS_IPHONE

    BOOL allOK = YES;

    NSMutableDictionary* passDict = [self privateKeySearchDictForLabel:keyLabel forEncryption:YES];

    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)passDict);

    if(status != noErr)
    {
        allOK = NO;
    }

    passDict = [self privateKeySearchDictForLabel:keyLabel forEncryption:NO];

    status = SecItemDelete((__bridge CFDictionaryRef)passDict);

    if(status != noErr)
    {
        allOK = NO;
    }

    passDict = [self publicKeySearchDictForLabel:keyLabel forEncryption:YES];

    status = SecItemDelete((__bridge CFDictionaryRef)passDict);

    if(status != noErr)
    {
        allOK = NO;
    }

    passDict = [self publicKeySearchDictForLabel:keyLabel forEncryption:NO];

    status = SecItemDelete((__bridge CFDictionaryRef)passDict);

    if(status != noErr)
    {
        allOK = NO;
    }

    return allOK;

#else

    BOOL allOK = YES;

    NSMutableDictionary* passDict = [self privateKeySearchDictForLabel:keyLabel forEncryption:YES];

    [passDict setObject:kSecMatchLimitAll forKey:kSecMatchLimit];

    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)passDict);

    if(status != noErr)
    {
        allOK = NO;
    }

    passDict = [self privateKeySearchDictForLabel:keyLabel forEncryption:NO];

    status = SecItemDelete((__bridge CFDictionaryRef)passDict);

    if(status != noErr)
    {
        allOK = NO;
    }

    passDict = [self publicKeySearchDictForLabel:keyLabel forEncryption:YES];

    status = SecItemDelete((__bridge CFDictionaryRef)passDict);

    if(status != noErr)
    {
        allOK = NO;
    }

    passDict = [self publicKeySearchDictForLabel:keyLabel forEncryption:NO];

    status = SecItemDelete((__bridge CFDictionaryRef)passDict);

    if(status != noErr)
    {
        allOK = NO;
    }

    return allOK;

#endif
}


+ (BOOL)doesPrivateKeychainItemWithLabel:(NSString*)keyLabel matchDecData:(NSData*)decData sigData:(NSData*)sigData encData:(NSData*)encData verData:(NSData*)verData
{
    NSArray* existingKeyData = [self dataForPrivateKeychainItemWithLabel:keyLabel];

    if(!existingKeyData || existingKeyData.count<4)
        return NO;

    NSData* existingDecrKeyData = existingKeyData[0];

    NSData* existingSigKeyData = existingKeyData[1];

    NSData* existingEncrKeyData = existingKeyData[2];

    NSData* existingVerKeyData = existingKeyData[3];

    if([existingDecrKeyData isEqual:decData] && [existingSigKeyData isEqual:sigData] && [existingEncrKeyData isEqual:encData] && [existingVerKeyData isEqual:verData])
        return YES;

    return NO;
}

/*returns the exported private key as an array [dec, sig, enc, ver]*/
+ (NSArray*)dataForPrivateKeychainItemWithLabel:(NSString*)keyLabel
{
    return [self dataForPrivateKeychainItemWithLabel:keyLabel passphrase:@""];
}

+ (NSArray*)dataForPrivateKeychainItemWithLabel:(NSString*)keyLabel passphrase:(NSString*)passphrase
{
#if TARGET_OS_IPHONE

    NSMutableDictionary* passDict = [self privateKeySearchDictForLabel:keyLabel forEncryption:YES];

    [passDict setObject:(__bridge id)kSecAttrKeyClassPublic forKey:(__bridge id)kSecAttrKeyClass];
    [passDict setObject:@YES forKey:(__bridge id)kSecReturnData];

    CFTypeRef result = nil;

    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, &result);

    if(status != noErr)
    {
        NSError* error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"Error exporting key: %@", error);
        return nil;
    }

    NSData* encKeyData = CFBridgingRelease(result);

    [passDict setObject:(__bridge id)kSecAttrKeyClassPrivate forKey:(__bridge id)kSecAttrKeyClass];

    status = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, &result);

    if(status != noErr)
    {
        NSError* error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"Error exporting key: %@", error);
        return nil;
    }

    NSData* decKeyData = CFBridgingRelease(result);

    passDict = [self privateKeySearchDictForLabel:keyLabel forEncryption:NO];
    [passDict setObject:(__bridge id)kSecAttrKeyClassPublic forKey:(__bridge id)kSecAttrKeyClass];
    [passDict setObject:@YES forKey:(__bridge id)kSecReturnData];

    status = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, &result);

    if(status != noErr)
    {
        NSError* error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"Error exporting key: %@", error);
        return nil;
    }

    NSData* verKeyData = CFBridgingRelease(result);

    [passDict setObject:(__bridge id)kSecAttrKeyClassPrivate forKey:(__bridge id)kSecAttrKeyClass];

    status = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, &result);

    if(status != noErr)
    {
        NSError* error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"Error exporting key: %@", error);
        return nil;
    }

    NSData* sigKeyData = CFBridgingRelease(result);


    if(decKeyData && sigKeyData && encKeyData && verKeyData)
        return @[decKeyData, sigKeyData, encKeyData, verKeyData];

    return nil;

#else

    NSMutableDictionary* passDict = [self privateKeySearchDictForLabel:keyLabel forEncryption:YES];
    [passDict setObject:@YES forKey:(__bridge id)kSecReturnPersistentRef];

    CFTypeRef result = nil;

    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, &result);

    if(status != noErr)
    {
        NSError* error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"Error exporting key: %@", error);
        return nil;
    }

    NSData* persistentRefData = CFBridgingRelease(result);

    NSData* decKeyData = [self dataForPersistentRef:persistentRefData withPassphrase:passphrase];

    passDict = [self privateKeySearchDictForLabel:keyLabel forEncryption:NO];
    [passDict setObject:@YES forKey:(__bridge id)kSecReturnPersistentRef];

    status = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, &result);

    if(status != noErr)
    {
        NSError* error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"Error exporting key: %@", error);
        return nil;
    }

    persistentRefData = CFBridgingRelease(result);

    NSData* sigKeyData = [self dataForPersistentRef:persistentRefData withPassphrase:passphrase];

    passDict = [self publicKeySearchDictForLabel:keyLabel forEncryption:YES];
    [passDict setObject:@YES forKey:(__bridge id)kSecReturnPersistentRef];

    status = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, &result);

    if(status != noErr)
    {
        NSError* error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"Error exporting key: %@", error);
        return nil;
    }

    persistentRefData = CFBridgingRelease(result);

    NSData* encKeyData = [self dataForPersistentRef:persistentRefData withPassphrase:passphrase];

    passDict = [self publicKeySearchDictForLabel:keyLabel forEncryption:NO];
    [passDict setObject:@YES forKey:(__bridge id)kSecReturnPersistentRef];

    status = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, &result);

    if(status != noErr)
    {
        NSError* error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"Error exporting key: %@", error);
        return nil;
    }

    persistentRefData = CFBridgingRelease(result);

    NSData* verKeyData = [self dataForPersistentRef:persistentRefData withPassphrase:passphrase];


    if(decKeyData && sigKeyData && encKeyData && verKeyData)
        return @[decKeyData, sigKeyData, encKeyData, verKeyData];

    return nil;

#endif
}


+ (NSArray*)persistentRefsForPrivateKeychainItemWithLabel:(NSString*)keyLabel
{
    NSMutableDictionary* passDict = [self privateKeySearchDictForLabel:keyLabel forEncryption:YES];
    [passDict setObject:@YES forKey:(__bridge id)kSecReturnPersistentRef];

    CFTypeRef result = nil;

    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, &result);

    if(status != noErr)
    {
        NSError* error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"Error exporting key: %@", error);
        return nil;
    }

    NSData* persistentDecKeyRef = CFBridgingRelease(result);

    passDict = [self privateKeySearchDictForLabel:keyLabel forEncryption:NO];
    [passDict setObject:@YES forKey:(__bridge id)kSecReturnPersistentRef];

    status = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, &result);

    if(status != noErr)
    {
        NSError* error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"Error exporting key: %@", error);
        return nil;
    }

    NSData* persistentSigKeyRef = CFBridgingRelease(result);

    passDict = [self publicKeySearchDictForLabel:keyLabel forEncryption:YES];
    [passDict setObject:@YES forKey:(__bridge id)kSecReturnPersistentRef];

    status = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, &result);

    if(status != noErr)
    {
        NSError* error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"Error exporting key: %@", error);
        return nil;
    }

    NSData* persistentEncKeyRef = CFBridgingRelease(result);

    passDict = [self publicKeySearchDictForLabel:keyLabel forEncryption:NO];
    [passDict setObject:@YES forKey:(__bridge id)kSecReturnPersistentRef];

    status = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, &result);

    if(status != noErr)
    {
        NSError* error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"Error exporting key: %@", error);
        return nil;
    }

    NSData* persistentVerKeyRef = CFBridgingRelease(result);


    if(persistentDecKeyRef && persistentSigKeyRef && persistentEncKeyRef && persistentVerKeyRef)
        return @[persistentDecKeyRef, persistentSigKeyRef, persistentEncKeyRef, persistentVerKeyRef];

    return nil;
}




#pragma mark - GENERIC


//+ (SecAccessRef)accessRef:(BOOL)isPassword
//{
//    //    SecAccessControlCreateWithFlags(<#CFAllocatorRef allocator#>, <#CFTypeRef protection#>, <#SecAccessControlCreateFlags flags#>, <#CFErrorRef *error#>)
//
////    CFArrayRef authorizations = SecACLCopyAuthorizations
//
//    SecTrustedApplicationRef thisApplication = NULL;
//
//    OSStatus status = SecTrustedApplicationCreateFromPath(NULL, &thisApplication);
//
//    if(status != noErr || thisApplication == NULL)
//    {
//        NSLog(@"Error setting access rights for freshly added keychain item! %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);
//
//        return NULL;
//    }
//
//    NSArray* newTrustedAppArray = @[(__bridge id)thisApplication];
//
//    CFStringRef description = (CFStringRef)@"Mynigma Key";
//
//    SecKeychainPromptSelector promptSelector = /*kSecKeychainPromptInvalid | kSecKeychainPromptInvalidAct | kSecKeychainPromptUnsigned | kSecKeychainPromptUnsignedAct |*/ kSecKeychainPromptRequirePassphase;
//
//    //SecACLRef newACL = NULL;
//
//    //NSError* error = nil;
//
//    SecAccessRef itemAccess = NULL; //SecAccessCreateWithOwnerAndACL(getuid(), 0, kSecUseOnlyUID, (__bridge CFArrayRef)@[], NULL);
//
//    return itemAccess;
//}
//
//    status = SecAccessCreate(description, (__bridge CFArrayRef)newTrustedAppArray, &itemAccess);
//
//    //    status = SecACLCreateWithSimpleContents(itemAccess, (__bridge CFArrayRef)(newTrustedAppArray), description, promptSelector, &newACL);
//
//    //   status = SecACLUpdateAuthorizations(newACL, (__bridge CFArrayRef)@[@(CSSM_ACL_AUTHORIZATION_ANY)]);
//
////    SecACLRef ACLEntryChangeACL = SecACLC
//
//
//    //itemAccess = SecAccessCreateWithOwnerAndACL(<#uid_t userId#>, <#gid_t groupId#>, <#SecAccessOwnerType ownerType#>, <#CFArrayRef acls#>, <#CFErrorRef *error#>)
//
//    CFArrayRef encACLList = NULL;
//
//    status = SecAccessCopyACLList(itemAccess, &encACLList);
//
////    BOOL haveACLChangeAuth = NO;
//
////    BOOL haveNonACLChangeAuth = NO;
//
//    NSArray* ACLListCopy = [(__bridge NSArray*)encACLList copy];
//
////    NSMutableArray* newACLList = [NSMutableArray new];
//
//    for(NSInteger i = 0; i < ACLListCopy.count; i++)
//    {
//        SecACLRef ACLRef = (__bridge SecACLRef)ACLListCopy[i];
//
//        CFArrayRef applicationListRef = NULL;
//
//        CFStringRef description = NULL;
//
//        status = SecACLCopyContents(ACLRef, &applicationListRef, &description, &promptSelector);
//
//        //        NSArray* auths = (__bridge NSArray*)SecACLCopyAuthorizations(ACLRef);
//
//        //if(![auths containsObject:@"ACLAuthorizationChangeACL"])
//                {
//                    //                    status = status ?: SecACLRemove (ACLRef);
//
//                    //            status = status ?: SecACLCreateWithSimpleContents (itemAccess, (__bridge CFArrayRef)newTrustedAppArray, description, promptSelector, &ACLRef);
////
////                    if([auths containsObject:(__bridge id)kSecACLAuthorizationDecrypt])
////                    {
////                        auths = @[(__bridge id)kSecACLAuthorizationAny];
////                    }
////
////                    status = status ?: SecACLUpdateAuthorizations(ACLRef, (__bridge CFArrayRef)auths);
//                }
//
//        SecACLSetContents(ACLRef, (__bridge CFArrayRef)newTrustedAppArray, (__bridge CFStringRef)(isPassword?@"Mynigma account password":@"Mynigma key"), promptSelector);
////
////        status = SecACLCopyContents(ACLRef, &applicationListRef, &description, &promptSelector);
////
////        auths = (__bridge NSArray*)SecACLCopyAuthorizations(ACLRef);
////
////        //SecACLRef newACLRef = NULL;
////
////        //status = SecACLCreateWithSimpleContents(NULL, (__bridge CFArrayRef)newTrustedAppArray, (__bridge CFStringRef)(isPassword?@"Mynigma account password":@"Mynigma key"), promptSelector, &newACLRef);
////
////        [newACLList addObject:(__bridge id)ACLRef];
//
//        //SecACL
//
////        if([auths containsObject:@"ACLAuthorizationChangeACL"])
////        {
////            haveACLChangeAuth = YES;
////            [newACLList addObject:(__bridge id)ACLRef];
////        }
////        else if(haveNonACLChangeAuth)
////        {
////            SecACLRemove(ACLRef);
////        }
////        else
////        {
////            haveNonACLChangeAuth = YES;
////            NSArray* newAuths = @[(__bridge id)kSecACLAuthorizationAny];
////            //NSArray* newAuths = @[(__bridge id)kSecACLAuthorizationDecrypt, (__bridge id)kSecACLAuthorizationDelete, (__bridge id)kSecACLAuthorizationDerive, (__bridge id)kSecACLAuthorizationEncrypt, (__bridge id)kSecACLAuthorizationExportClear, (__bridge id)kSecACLAuthorizationExportWrapped, (__bridge id)kSecACLAuthorizationGenKey, (__bridge id)kSecACLAuthorizationImportClear, (__bridge id)kSecACLAuthorizationImportWrapped, (__bridge id)kSecACLAuthorizationMAC, (__bridge id)kSecACLAuthorizationSign];
////            SecACLUpdateAuthorizations(ACLRef, (__bridge CFArrayRef)newAuths);
//////            SecACLUpdateAuthorizations(ACLRef, (__bridge CFArrayRef)@[(__bridge id)kSecACLAuthorizationDecrypt, (__bridge id)kSecACLAuthorizationDelete, (__bridge id)kSecACLAuthorizationDerive, (__bridge id)kSecACLAuthorizationEncrypt, (__bridge id)kSecACLAuthorizationExportClear, (__bridge id)kSecACLAuthorizationExportWrapped, (__bridge id)kSecACLAuthorizationGenKey, (__bridge id)kSecACLAuthorizationImportClear, (__bridge id)kSecACLAuthorizationImportWrapped, (__bridge id)kSecACLAuthorizationMAC, (__bridge id)kSecACLAuthorizationSign]);
////
////            [newACLList addObject:(__bridge id)ACLRef];
////        }
//
//        //NSArray* authArray = (__bridge NSArray*)SecACLCopyAuthorizations(ACLRef);
//
//        //NSLog(@"%@ %@ %@ %@", applicationListRef, description, @(promptSelector), authArray);
//    }
//
////    SecACLRef ACLRef = NULL;
////
////    SecACLCreateWithSimpleContents (itemAccess, NULL, description, 0, &ACLRef);
////
////    SecACLUpdateAuthorizations(ACLRef, (__bridge CFArrayRef)@[(__bridge id)kSecACLAuthorizationAny]);
//
//    //NSError* error = nil;
//
//    //itemAccess = SecAccessCreateWithOwnerAndACL(getuid(), 0, kSecUseOnlyUID, (__bridge CFArrayRef)newACLList, NULL);
//
//
//
//
//                                                //SecAccessCreateWithOwnerAndACL(getuid(), 0, kSecUseOnlyUID, (__bridge CFArrayRef)@[], NULL);
//    [KeychainHelper dumpAccessRefToLog:itemAccess];
//
//    return itemAccess;
//}



#if TARGET_OS_IPHONE

#else

+ (BOOL)setProperAccessRightsForKeychainItem:(SecKeychainItemRef)keychainItemRef
{
    if(!keychainItemRef)
    {
        NSLog(@"Tried to set proper access for nil keychain item!!!");
        return NO;
    }

    SecAccessRef accessRef = NULL;

    OSStatus status = SecKeychainItemCopyAccess(keychainItemRef, &accessRef);

    if(status != noErr)
    {
        NSLog(@"Error getting access ref!!!");

        return NO;
    }

    SecTrustedApplicationRef thisApplication = NULL;

    status = SecTrustedApplicationCreateFromPath(NULL, &thisApplication);

    if(status != noErr || thisApplication == NULL)
    {
        NSLog(@"Error setting access rights for freshly added keychain item! %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);

        return NO;
    }

    CFStringRef description = (CFStringRef)@"Mynigma Key";

    CFArrayRef encACLList = NULL;

    status = SecAccessCopyACLList(accessRef, &encACLList);

    NSInteger ACLCount = CFArrayGetCount(encACLList);

    for(NSInteger i = 0; i < ACLCount; i++)
    {
        SecACLRef ACLRef = (SecACLRef)CFArrayGetValueAtIndex(encACLList, i);

        SecKeychainPromptSelector promptSelector = 0;

        status = SecACLSetContents(ACLRef, (__bridge CFArrayRef)@[(__bridge id)thisApplication], description, promptSelector);

        if(status != noErr)
        {
            NSLog(@"Error setting ACL contents!!!");

            return NO;
        }
    }

    return YES;
}

#endif


+ (NSData*)dataForPersistentRef:(NSData*)persistentRef
{
#if TARGET_OS_IPHONE

    if(!persistentRef)
        return nil;

    NSMutableDictionary* passDict = [NSMutableDictionary new];

    passDict[(__bridge id)kSecValuePersistentRef] = persistentRef;//setObject:(__bridge id)keyRef forKey:(__bridge id)kSecValueRef];

    passDict[(__bridge id)kSecReturnData] = @YES;

    CFTypeRef result = nil;

    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, &result);

    if(status != noErr)
    {
        NSError* error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"Error exporting key: %@", error);
        return nil;
    }

    NSData* encKeyData = CFBridgingRelease(result);

    NSString* base64edEncKeyData = [encKeyData base64];

    NSString* completeString = [NSString stringWithFormat:@"MIICIjANBgkqhkiG9w0BAQEFAAOCAg8A%@", base64edEncKeyData];

    //split into 64 character lines
    NSMutableArray* chunks = [NSMutableArray new];

    NSInteger index = 0;

    while(index<completeString.length)
    {
        NSInteger lengthOfChunk = (index+64<completeString.length)?64:completeString.length-index;

        NSString* substring = [completeString substringWithRange:NSMakeRange(index, lengthOfChunk)];

        [chunks addObject:substring];

        index+= 64;
    }

    NSString* joinedString = [chunks componentsJoinedByString:@"\n"];

    NSString* armouredDataString = [NSString stringWithFormat:@"-----BEGIN RSA PUBLIC KEY-----\n%@\n-----END RSA PUBLIC KEY-----\n", joinedString];

    NSData* returnValue = [armouredDataString dataUsingEncoding:NSUTF8StringEncoding];

    return returnValue;

#else

    return [self dataForPersistentRef:persistentRef withPassphrase:nil];

#endif

}

+ (NSData*)dataForPersistentRef:(NSData*)persistentRef withPassphrase:(NSString*)passphrase
{

#if TARGET_OS_IPHONE

    if(!persistentRef)
        return nil;

    //TO DO: implement

    return [self dataForPersistentRef:persistentRef];

    //first get a SecKeyRef from the persistent reference
    //SecKeyRef keyRef = [self keyRefForPersistentRef:persistentRef];

#else

    if(!persistentRef)
        return nil;

    //first get a SecKeyRef from the persistent reference
    SecKeyRef keyRef = [self keyRefForPersistentRef:persistentRef];

    if(!keyRef)
        return nil;

    SecItemImportExportKeyParameters params = {0};
    params.version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;

    SecExternalFormat externalFormat = kSecFormatPEMSequence;

    if(passphrase)
    {
        params.passphrase = (__bridge_retained CFStringRef)passphrase;
        externalFormat = kSecFormatWrappedPKCS8;
    }

    int armour = kSecItemPemArmour;

    CFDataRef keyData = NULL;

    [self temporarilyGrantPermissiveAccessRightsForPublicKeyKeychainItem:(SecKeychainItemRef)keyRef];

    OSStatus oserr = SecItemExport(keyRef, externalFormat, armour , &params, &keyData);

    [self setAccessRightsForKey:(SecKeychainItemRef)keyRef withDescription:@"Mynigma public key"];

    if(passphrase)
        CFRelease(params.passphrase);

    if(oserr == noErr) {
        return CFBridgingRelease(keyData);
    }
    else
    {
        if(keyData)
            CFRelease(keyData);

        //try exporting it as a PEM sequence without a passphrase

        params.passphrase = NULL;

        externalFormat = kSecFormatPEMSequence;

        [self temporarilyGrantPermissiveAccessRightsForPublicKeyKeychainItem:(SecKeychainItemRef)keyRef];

        OSStatus newOserr = SecItemExport(keyRef, externalFormat, /*kSecItemPemArmour*/  0, &params, &keyData);

        [self setAccessRightsForKey:(SecKeychainItemRef)keyRef withDescription:@"Mynigma public key"];

        if(newOserr == noErr)
            return CFBridgingRelease(keyData);

        NSLog(@"Error exporting key: %@, %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:oserr userInfo:nil], [NSError errorWithDomain:NSOSStatusErrorDomain code:newOserr userInfo:nil]);

        [KeychainHelper dumpAccessRefForKeyRefToLog:(SecKeychainItemRef)keyRef];
    }

    return nil;

#endif

}

+ (SecKeyRef)keyRefForPersistentRef:(NSData*)persistentRef
{
    if(!persistentRef)
        return nil;

    NSMutableDictionary* passDict = [NSMutableDictionary new];

    passDict[(__bridge id)kSecValuePersistentRef] = persistentRef;
    passDict[(__bridge id)kSecClass] = (__bridge id)kSecClassKey;
    [passDict setObject:@YES forKey:(__bridge id)kSecReturnRef];

    SecKeyRef keyRef = NULL;
    OSStatus oserr = SecItemCopyMatching((__bridge CFDictionaryRef)(passDict), (CFTypeRef*)&keyRef);

    if(oserr != noErr)
    {
        if(keyRef)
            CFRelease(keyRef);
        NSLog(@"Error turning persistent ref into key ref: %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:oserr userInfo:nil]);
    }
    
    if(keyRef)
        return keyRef;
    
    passDict[(__bridge id)kSecClass] = (__bridge id)kSecClassCertificate;
    
    oserr = SecItemCopyMatching((__bridge CFDictionaryRef)(passDict), (CFTypeRef*)&keyRef);
    
    if(oserr != noErr)
    {
        if(keyRef)
            CFRelease(keyRef);
        NSLog(@"Error turning persistent ref into key ref! %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:oserr userInfo:nil]);
        return nil;
    }
    
    return keyRef;
}



#if TARGET_OS_IPHONE
+ (void)deleteAllKeys
{
    NSLog(@"Deleting private keys!!!!");
    
    NSMutableDictionary* keyAttributesDict = [NSMutableDictionary new];
    
    keyAttributesDict[(__bridge id)kSecClass] = (__bridge id)kSecClassKey;
    
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)(keyAttributesDict));
    
    if(status != noErr)
    {
        
        NSLog(@"Failed to delete private keys!! %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);
    }
}
#endif



+ (NSData*)rawDataExportPrivateKeyWithLabel:(NSString*)keyLabel
{
    NSMutableDictionary* passDict = [self privateKeySearchDictForLabel:keyLabel forEncryption:YES];
    
    passDict[(__bridge id)kSecReturnData] = @YES;
    
    CFTypeRef result = nil;
    
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)passDict, &result);
    
    if(status != noErr)
    {
        NSError* error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"Error exporting key: %@", error);
        return nil;
    }
    
    NSData* encKeyData = CFBridgingRelease(result);
    
    return encKeyData;
}

+ (BOOL)importPrivateKeyRawData:(NSData*)data withLabel:(NSString*)keyLabel
{
    BOOL forEncryption = YES;
    
    NSMutableDictionary* passDict = [NSMutableDictionary new];
    //[passDict setObject:(id)kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
    //[passDict setObject:@4096 forKey:(id)kSecAttrKeySizeInBits];
    [passDict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    
    //NSString* attrLabel = [NSString stringWithFormat:@"%@%@", forEncryption?@"Mynigma encryption key ":@"Mynigma signature key ", keyLabel];
    
    if(forEncryption)
    {
        //[passDict setObject:@"Mynigma encryption key" forKey:(__bridge id)kSecAttrDescription];
        //[passDict setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanVerify];
        //[passDict setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanSign];
    }
    else
    {
        [passDict setObject:@"Mynigma signature key" forKey:(__bridge id)kSecAttrDescription];
        [passDict setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanDecrypt];
        [passDict setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanEncrypt];
    }
    
    //[passDict setObject:attrLabel forKey:(__bridge id)kSecAttrLabel];
    
    [passDict setObject:(__bridge id)kSecAttrKeyClassPrivate forKey:(__bridge id)kSecAttrKeyClass];
    
    //[passDict setObject:@YES forKey:kSecAttrIsPermanent];
    
    
    passDict[(__bridge id)kSecValueData] = data;
    
    CFTypeRef result = nil;
    
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)passDict, &result);
    
    if(status != noErr)
    {
        if(result)
            CFRelease(result);
        
        NSError* error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"Error exporting key: %@", error);
        return NO;
    }
    
    if(result)
        CFRelease(result);
    
    return YES;
}


//- (BOOL)iOS_import:(NSString*)keyAsBase64
//{
//
//        /* First decode the Base64 string */
//        NSData * rawFormattedKey = [[NSData alloc] initWithBase64EncodedString:keyAsBase64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
//
//        /* Now strip the uncessary ASN encoding guff at the start */
//        unsigned char * bytes = (unsigned char *)[rawFormattedKey bytes];
//        size_t bytesLen = [rawFormattedKey length];
//
//        /* Strip the initial stuff */
//        size_t i = 0;
//        if (bytes[i++] != 0x30)
//            return FALSE;
//
//        /* Skip size bytes */
//        if (bytes[i] > 0x80)
//            i += bytes[i] - 0x80 + 1;
//        else
//            i++;
//
//        if (i >= bytesLen)
//            return FALSE;
//
//        if (bytes[i] != 0x30)
//            return FALSE;
//
//        /* Skip OID */
//        i += 15;
//
//        if (i >= bytesLen - 2)
//            return FALSE;
//
//        if (bytes[i++] != 0x03)
//            return FALSE;
//
//        /* Skip length and null */
//        if (bytes[i] > 0x80)
//            i += bytes[i] - 0x80 + 1;
//        else
//            i++;
//
//        if (i >= bytesLen)
//            return FALSE;
//
//        if (bytes[i++] != 0x00)
//            return FALSE;
//
//        if (i >= bytesLen)
//            return FALSE;
//
//        /* Here we go! */
//        NSData * extractedKey = [NSData dataWithBytes:&bytes[i] length:bytesLen - i];
//
//        /* Load as a key ref */
//        OSStatus error = noErr;
//        CFTypeRef persistPeer = NULL;
//
//        NSData * refTag = [[NSData alloc] initWithBytes:refString length:strlen(refString)];
//        NSMutableDictionary * keyAttr = [[NSMutableDictionary alloc] init];
//
//        [keyAttr setObject:(id)kSecClassKey forKey:(id)kSecClass];
//        [keyAttr setObject:(id)kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
//        [keyAttr setObject:refTag forKey:(id)kSecAttrApplicationTag];
//
//        /* First we delete any current keys */
//        error = SecItemDelete((CFDictionaryRef) keyAttr);
//
//        [keyAttr setObject:extractedKey forKey:(id)kSecValueData];
//        [keyAttr setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnPersistentRef];
//
//        error = SecItemAdd((CFDictionaryRef) keyAttr, (CFTypeRef *)&persistPeer);
//
//        if (persistPeer == nil || ( error != noErr && error != errSecDuplicateItem)) {
//            NSLog(@"Problem adding public key to keychain");
//            return FALSE;
//        }
//
//        CFRelease(persistPeer);
//
//        publicKeyRef = nil;
//
//        /* Now we extract the real ref */
//        [keyAttr removeAllObjects];
//        /*
//         [keyAttr setObject:(id)persistPeer forKey:(id)kSecValuePersistentRef];
//         [keyAttr setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnRef];
//         */
//        [keyAttr setObject:(id)kSecClassKey forKey:(id)kSecClass];
//        [keyAttr setObject:refTag forKey:(id)kSecAttrApplicationTag];
//        [keyAttr setObject:(id)kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
//        [keyAttr setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnRef];
//        
//        // Get the persistent key reference.
//        error = SecItemCopyMatching((CFDictionaryRef)keyAttr, (CFTypeRef *)&publicKeyRef);    
//        
//        if (publicKeyRef == nil || ( error != noErr && error != errSecDuplicateItem)) {
//            NSLog(@"Error retrieving public key reference from chain");
//            return FALSE;
//        }
//        
//        
//        return TRUE;
//}

@end
