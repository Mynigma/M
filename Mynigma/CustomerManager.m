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





#import "CustomerManager.h"
#import "AppDelegate.h"

@implementation CustomerManager

- (void)setup
{
    //try to open the plist
    NSURL* plistURL = [CustomerManager customerPlistURL];

    NSDictionary* plistDict = [NSDictionary dictionaryWithContentsOfURL:plistURL];

    if(plistDict)
    {
        [self setShortString:[plistDict objectForKey:@"name"]];
        [self setIdentifier:[plistDict objectForKey:@"identifier"]];
        [self setFooterHTML:[plistDict objectForKey:@"footerHTML"]];
        [self setFooterLogo:[plistDict objectForKey:@"footerLogo"]];
        [self setPreInstalledAccounts:[plistDict objectForKey:@"preInstalledAccounts"]];
        [self setFooterInlineAttachments:[plistDict objectForKey:@"footerInlineAttachments"]];
    }
    
}

- (instancetype)init
{
    self = [super init];
    if (self) {

        [self setup];

    }
    return self;
}

+ (CustomerManager*)sharedInstance
{
    static dispatch_once_t p = 0;

    __strong static id sharedObject = nil;

    dispatch_once(&p, ^{
        sharedObject = [CustomerManager new];
    });

    return sharedObject;
}


+ (NSURL*)customerPlistURL
{
    NSURL* applicationFilesDirectory = [AppDelegate applicationFilesDirectory];

    if(applicationFilesDirectory)
    {
        NSString* customerPlistDirectory = [applicationFilesDirectory.path stringByAppendingPathComponent:@"Customer"];

        NSError* error = nil;

        BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:customerPlistDirectory withIntermediateDirectories:YES attributes:nil error:&error];

        if(error || !success)
        {
            NSLog(@"Error creating customer directory!! %@", error);
            return nil;
        }

        NSURL* destinationURL = [NSURL fileURLWithPath:[customerPlistDirectory stringByAppendingPathComponent:@"customer.plist"]];

        return destinationURL;
    }
    
    NSLog(@"No Application Support path found!!");
    return nil;
}

//copies a customer.plist file from the bundle to the application support folder, where it will not be touched by future updates
//the customer info is thereby persisted
+ (void)copyPlistIntoApplicationSupportFolder
{
    //first check if there actually is a plist file to copy
    NSString* resourceName = @"customer";

//#if EXCLUSIVE
//
//    resourceName = @"customer_EXCL";
//
//#endif

    NSURL* plistURL = [[NSBundle mainBundle] URLForResource:resourceName withExtension:@"plist"];

    if(!plistURL)
    {
        NSLog(@"No customer plist found.");
        return;
    }

    NSURL* destinationURL = [self customerPlistURL];

    NSError* error = nil;

    [[NSFileManager defaultManager] copyItemAtURL:plistURL toURL:destinationURL error:&error];

    if(error)
    {
        if(error.code==516)
            NSLog(@"Existing customer file found");
        else
            NSLog(@"Error copying customer plist file!! %@", error);
    }
        else
            NSLog(@"Successfully copied plist");
}

+ (NSString*)customerIdentifer
{
    return [[CustomerManager sharedInstance] identifier];
}

+ (NSString*)customerString
{
    return [[CustomerManager sharedInstance] shortString];
}

+ (BOOL)havePlist
{
    return [[CustomerManager sharedInstance] haveCustomerPlist];
}

+ (BOOL)isExclusiveVersion
{
    return [[self customerIdentifer] isEqual:@"EXCL"];
}

+ (NSString*)footerHTML
{
    return [[CustomerManager sharedInstance] footerHTML];
}

+ (NSString*)footerLogo
{
    return [[CustomerManager sharedInstance] footerLogo];
}

+ (NSDictionary*)preInstalledAccountForUsername:(NSString*)username
{
    return [[[CustomerManager sharedInstance] preInstalledAccounts] objectForKey:username];
}

+ (NSArray*)inlineAttachmentsForFooter
{
    return [[CustomerManager sharedInstance] footerInlineAttachments];
}

+ (NSString*)preInstalledFooterForUsername:(NSString*)username
{
    NSDictionary* preInstalledAccount = [self preInstalledAccountForUsername:username];
    
    if (!preInstalledAccount)
        return nil;
    
    NSString* name = [preInstalledAccount objectForKey:@"name"];
    NSString* email = [preInstalledAccount objectForKey:@"displayEmail"];
    NSString* jobDescription = [preInstalledAccount objectForKey:@"jobDescription"];

    //inline attachments are referenced by hardcoded cids to keep the same number of parameters
    return [NSString stringWithFormat:self.footerHTML,name?name:@"",jobDescription?jobDescription:@"",email?email:@""/*,self.footerLogo*/];
}


@end
