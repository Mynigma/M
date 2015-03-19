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





#import "MigrationHelper.h"
#import "KeychainHelper.h"

#import "AppDelegate.h"
#import "UserSettings+Category.h"
#import "IMAPAccountSetting+Category.h"
#import "EmailContactDetail+Category.h"
#import "PublicKeyManager.h"
#import "MynigmaPrivateKey+Category.h"
#import "EmailFooter.h"
#import "EmailAddress+Category.h"
#import "MynigmaPublicKey+Category.h"





@interface MynigmaPublicKey()

- (void)associateKeyWithEmail:(NSString*)emailString forceMakeCurrent:(BOOL)makeCurrent inContext:(NSManagedObjectContext*)keyContext;

@end

@implementation MigrationHelper


+ (NSMutableDictionary*)publicKeyAdditionDictForLabel:(NSString*)keyLabel forEncryption:(BOOL)forEncryption
{
#if TARGET_OS_IPHONE
    return nil;
#else

    NSMutableDictionary* passDict = [NSMutableDictionary new];
    [passDict setObject:(id)kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
    [passDict setObject:@4096 forKey:(id)kSecAttrKeySizeInBits];
    [passDict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];

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


+ (NSMutableDictionary*)v_2_0_publicKeySearchDictForLabel:(NSString*)keyLabel forEncryption:(BOOL)forEncryption
{
    NSMutableDictionary* passDict = [NSMutableDictionary new];

    NSString* attrLabel = forEncryption?[NSString stringWithFormat:@"Public encryption key: %@", keyLabel]:[NSString stringWithFormat:@"Public verification key: %@", keyLabel];

    [passDict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];

    [passDict setObject:attrLabel forKey:(__bridge id)kSecAttrLabel];
    [passDict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];

    [passDict setObject:(__bridge id)kSecAttrKeyClassPublic forKey:(__bridge id)kSecAttrKeyClass];

    return passDict;
}



+ (NSMutableDictionary*)v_2_0_privateKeySearchDictForLabel:(NSString*)keyLabel forEncryption:(BOOL)forEncryption
{
    NSMutableDictionary* passDict = [NSMutableDictionary new];

    NSString* attrLabel = [NSString stringWithFormat:@"%@%@", forEncryption?@"Mynigma encryption key pair ":@"Mynigma signature key pair ", keyLabel];

    [passDict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];

    //[passDict setObject:[NSData dataWithBytes:[attrLabel UTF8String] length:[attrLabel length]] forKey:(__bridge id)kSecAttrApplicationTag];

    [passDict setObject:attrLabel forKey:(__bridge id)kSecAttrLabel];

    [passDict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];

    [passDict setObject:(__bridge id)kSecAttrKeyClassPrivate forKey:(__bridge id)kSecAttrKeyClass];

    [passDict setObject:@YES forKey:(__bridge id<NSCopying>)(kSecAttrIsPermanent)];
    
    return passDict;
}


+ (void)replaceOccurrencesOfString:(NSString*)oldString withNewString:(NSString*)newString inLabelOfKeychainItemWithPersistentRef:(NSData*)persistentRef andLabel:(NSString*)label
{
    if([label rangeOfString:oldString].location!=NSNotFound)
    {
        NSString* newLabel = [label stringByReplacingOccurrencesOfString:oldString withString:newString];


        NSMutableDictionary* passDict = [NSMutableDictionary new];
        [passDict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
        [passDict setObject:persistentRef forKey:(__bridge id)kSecValuePersistentRef];


        NSDictionary* updateDict = @{(__bridge id)kSecAttrLabel: newLabel};

        OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)(passDict), (__bridge CFDictionaryRef)(updateDict));
        if(status != errSecSuccess)
        {
            NSLog(@"Error updating keychain item with label\n%@\nto new label\n%@\nError code: %@", oldString, newString, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);
        }
    }
}


+ (void)migrateFromVersion:(NSString*)oldVersion
{
    BOOL success = YES;

    if(!oldVersion)
        oldVersion = @"2.0";

    if([oldVersion compare:@"2.01"] == NSOrderedAscending)
    {
        //version 2.0 has old keychain item labels on Mac OS

        NSMutableArray* allKeysInKeychain = [[KeychainHelper listPublicKeychainItems] mutableCopy];

        [allKeysInKeychain addObjectsFromArray:[KeychainHelper listPrivateKeychainItems]];

        for(NSDictionary* attrDict in allKeysInKeychain)
        {
            NSString* label = [attrDict objectForKey:@"labl"];

            if(!label || [label isEqual:[NSNull null]])
                continue;

            NSData* persistentRef = [attrDict objectForKey:@"v_PersistentRef"];

            [self replaceOccurrencesOfString:@"Mynigma encryption key pair " withNewString:@"Mynigma encryption key " inLabelOfKeychainItemWithPersistentRef:persistentRef andLabel:label];

            [self replaceOccurrencesOfString:@"Mynigma signature key pair " withNewString:@"Mynigma signature key " inLabelOfKeychainItemWithPersistentRef:persistentRef andLabel:label];

            [self replaceOccurrencesOfString:@"Public encryption key: " withNewString:@"Mynigma encryption key " inLabelOfKeychainItemWithPersistentRef:persistentRef andLabel:label];

            [self replaceOccurrencesOfString:@"Public verification key: " withNewString:@"Mynigma signature key " inLabelOfKeychainItemWithPersistentRef:persistentRef andLabel:label];
        }

    }

    if([oldVersion compare:@"2.08"] == NSOrderedAscending)
    {
        //from version 2.08 the current MynigmaPublicKey and MynigmaPrivateKey

        //fetch all public keys
        NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MynigmaPublicKey"];
        NSError* error = nil;


        NSArray* allPublicKeys = [MAIN_CONTEXT executeFetchRequest:fetchRequest error:&error];
        for(MynigmaPublicKey* publicKey in allPublicKeys)
        {
            NSString* emailAdress = publicKey.keyForEmail.address;

            if(!publicKey.emailAddress)
                [publicKey setEmailAddress:emailAdress];

            NSNumber* isCurrent = publicKey.isCurrentKey;

            if(!isCurrent || isCurrent.boolValue)
            {
                [publicKey setIsCurrentKey:@YES];
            }
            else
            {
                NSLog(@"Found obsolete public key: %@", publicKey);
            }
        }
        
    }
    

    if([oldVersion compare:@"2.08.17"] == NSOrderedAscending)
    {

        NSEntityDescription* footerEntity = [NSEntityDescription entityForName:@"EmailFooter" inManagedObjectContext:MAIN_CONTEXT];
        EmailFooter* newFooter = [[EmailFooter alloc] initWithEntity:footerEntity insertIntoManagedObjectContext:MAIN_CONTEXT];
        [newFooter setName:NSLocalizedString(@"Sent with Mynigma", @"Standard footer set up by migration helper")];

        NSURL* defaultFooterInRTFFileHTML = [BUNDLE URLForResource:@"StandardFooter" withExtension:@"html"];

        NSString* defaultFooterString = [NSString stringWithContentsOfURL:defaultFooterInRTFFileHTML encoding:NSUTF8StringEncoding error:nil];

        [newFooter setHtmlContent:defaultFooterString];

        for(IMAPAccountSetting* accountSetting in [UserSettings currentUserSettings].accounts)
        {
            if(!accountSetting.footer)
                [accountSetting setFooter:newFooter];
        }
    }

    if([oldVersion compare:@"2.09.03"] == NSOrderedAscending)
    {
        for(IMAPAccountSetting* accountSetting in [UserSettings currentUserSettings].accounts)
        {
            if(!accountSetting.shouldUse)
                [accountSetting setShouldUse:@YES];
        }

        [ThreadHelper runAsyncOnKeyContext:^{

        NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MynigmaPublicKey"];
        NSError* error = nil;

        NSArray* allPublicKeys = [KEY_CONTEXT executeFetchRequest:fetchRequest error:&error];

            NSLog(@"Key labels: %@", [allPublicKeys valueForKey:@"keyLabel"]);

        for(MynigmaPublicKey* publicKey in allPublicKeys)
        {
            //if the key already has EmailAddress objects associated with it, this should be unnecessary...
            if(publicKey.emailAddresses.count > 0)
                continue;

            NSString* emailString = publicKey.keyForEmail.address;

            if(!emailString)
                emailString = publicKey.emailAddress;

            if(!emailString)
            {
                NSLog(@"Public key without email address!!");
                continue;
            }

            BOOL forceMakeCurrent = publicKey.isCurrentKey.boolValue;

            if([MynigmaPrivateKey havePrivateKeyForEmailAddress:emailString] && [publicKey isMemberOfClass:[MynigmaPublicKey class]])
                forceMakeCurrent = NO;

            if([MynigmaPublicKey havePublicKeyForEmailAddress:emailString] && [publicKey isMemberOfClass:[MynigmaPrivateKey class]])
                forceMakeCurrent = YES;

            [publicKey associateKeyWithEmail:emailString forceMakeCurrent:forceMakeCurrent inContext:KEY_CONTEXT];
        }

            //[EmailAddress compileEmailIndex];

        }];
    }

    if(![[NSUserDefaults standardUserDefaults] objectForKey:@"haveSetUpStandardFooter"])
        [self setUpStandardFooter];


    if(success)
        [[UserSettings currentUserSettings] setLastVersionUsed:MYNIGMA_VERSION];

    //[MODEL.currentUserSettings setLastVersionUsed:@"2.0"];
}

+ (void)setUpStandardFooter
{
    //if the app is launched for the first time, set up the standard footer

    //this will also be called once if an existing user updates to 2.08.23 or later from a previous version

    UserSettings* settings = [UserSettings currentUserSettings];

    //if a standard footer has already been set up, don't do it again...
    if(settings.standardFooter)
        return;

    NSEntityDescription* footerEntity = [NSEntityDescription entityForName:@"EmailFooter" inManagedObjectContext:MAIN_CONTEXT];
    EmailFooter* newFooter = [[EmailFooter alloc] initWithEntity:footerEntity insertIntoManagedObjectContext:MAIN_CONTEXT];
    [newFooter setName:NSLocalizedString(@"Sent with Mynigma", @"Standard footer set up by migration helper")];

    NSURL* defaultFooterInRTFFileHTML = [BUNDLE URLForResource:@"StandardFooter" withExtension:@"html"];

    NSString* defaultFooterString = [NSString stringWithContentsOfURL:defaultFooterInRTFFileHTML encoding:NSUTF8StringEncoding error:nil];

    [newFooter setHtmlContent:defaultFooterString];

    [settings setStandardFooter:newFooter];

    for(IMAPAccountSetting* accountSetting in [UserSettings currentUserSettings].accounts)
    {
        if(!accountSetting.footer)
            [accountSetting setFooter:newFooter];
    }

    NSUserDefaults* standardDefaults = [NSUserDefaults standardUserDefaults];
    [standardDefaults setObject:@YES forKey:@"haveSetUpStandardFooter"];
    [standardDefaults synchronize];
}

@end
