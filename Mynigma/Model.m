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





#import "AppDelegate.h"
#import "KeychainHelper.h"

#if TARGET_OS_IPHONE

#import "EmailMessageController.h"
#import "ContactSuggestions.h"

#else

#endif



#import <AddressBook/AddressBook.h>
#import "UserSettings.h"
#import "GmailAccountSetting.h"
#import "ABContactDetail+Category.h"
#import "EmailContactDetail+Category.h"
#import "EmailMessage+Category.h"
#import "Contact+Category.h"
#import "GmailLabelSetting.h"
#import "EncryptionHelper.h"
#import "MynigmaDevice.h"
#import "EmailRecipient.h"
#import "MynigmaMessage+Category.h"
#import "Recipient.h"
#import "MessageSieve.h"
#import "IMAPAccount.h"
#import <MailCore/MailCore.h>
#import "FileAttachment+Category.h"
#import "AddressDataHelper.h"
#import "EmailMessageData.h"
#import "AccountCreationManager.h"
#import "IMAPFolderManager.h"
#import "EmailMessageController.h"
#import "EmailMessageInstance+Category.h"
#import "MynigmaPublicKey+Category.h"
#import "AccountCheckManager.h"
#import "IMAPAccountSetting+Category.h"
#import "NSString+EmailAddresses.h"
#import "UIDHelper.h"
#import "AlertHelper.h"
#import "SelectionAndFilterHelper.h"



#if ULTIMATE
#import "ServerHelper.h"
#endif

@implementation Model

@synthesize mainObjectContext;
@synthesize storeObjectContext;
@synthesize usersOwnEmailAddresses;
@synthesize accounts;
//@synthesize allContacts;
//@synthesize allEmailAddresses;
@synthesize currentUserSettings;
@synthesize currentDevice;
//@synthesize allMessages;
@synthesize objectsBeingCleaned;
@synthesize objectsBeingDecrypted;
@synthesize objectsBeingDownloaded;


- (id)init
{
    self = [super init];
    if(self)
    {
        self.mainObjectContext = MAIN_CONTEXT;
        self.storeObjectContext = APPDELEGATE.storeObjectContext;

        //allContacts = [NSMutableDictionary new];
        //allEmailAddresses = [NSMutableDictionary new];
        //allMessages = [NSMutableDictionary new];

        objectsBeingDecrypted = [NSMutableSet new];
        objectsBeingDownloaded = [NSMutableSet new];
        objectsBeingCleaned = [NSMutableSet new];
    }
    return self;
}


























@end
