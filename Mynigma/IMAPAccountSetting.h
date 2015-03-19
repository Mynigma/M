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
#import <CoreData/CoreData.h>

@class EmailContactDetail, EmailFooter, IMAPFolderSetting, MynigmaDevice, UserSettings;

@interface IMAPAccountSetting : NSManagedObject

@property (nonatomic, retain) NSString * accountID;
@property (nonatomic, retain) NSString * currentKeyPairLabel;
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSString * emailAddress;
@property (nonatomic, retain) NSNumber * footerUsage;
@property (nonatomic, retain) NSNumber * hasBeenVerified;
@property (nonatomic, retain) NSNumber * hasRequestedWelcomeMessage;
@property (nonatomic, retain) NSNumber * incomingAuthType;
@property (nonatomic, retain) NSNumber * incomingEncryption;
@property (nonatomic, retain) NSData * incomingPasswordRef;
@property (nonatomic, retain) NSNumber * incomingPort;
@property (nonatomic, retain) NSString * incomingServer;
@property (nonatomic, retain) NSString * incomingUserName;
@property (nonatomic, retain) NSDate * lastChecked;
@property (nonatomic, retain) NSDate * lastUpdatedFolders;
@property (nonatomic, retain) NSNumber * outgoingAuthType;
@property (nonatomic, retain) NSString * outgoingEmail;
@property (nonatomic, retain) NSNumber * outgoingEncryption;
@property (nonatomic, retain) NSData * outgoingPasswordRef;
@property (nonatomic, retain) NSNumber * outgoingPort;
@property (nonatomic, retain) NSString * outgoingServer;
@property (nonatomic, retain) NSString * outgoingUserName;
@property (nonatomic, retain) NSString * senderEmail;
@property (nonatomic, retain) NSString * senderName;
@property (nonatomic, retain) NSNumber * sentMessagesCopiedIntoSentFolder;
@property (nonatomic, retain) NSString * signUpMessageID;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSNumber * supportsIDLE;
@property (nonatomic, retain) NSNumber * supportsMODSEQ;
@property (nonatomic, retain) NSNumber * supportsQRESYNC;
@property (nonatomic, retain) NSNumber * unreadCount;
@property (nonatomic, retain) NSNumber * shouldUse;
@property (nonatomic, retain) IMAPFolderSetting *binFolder;
@property (nonatomic, retain) IMAPFolderSetting *draftsFolder;
@property (nonatomic, retain) NSSet *folders;
@property (nonatomic, retain) EmailFooter *footer;
@property (nonatomic, retain) IMAPFolderSetting *inboxFolder;
@property (nonatomic, retain) IMAPFolderSetting *mynigmaFolder;
@property (nonatomic, retain) IMAPFolderSetting *outboxFolder;
@property (nonatomic, retain) UserSettings *preferredAccountForUser;
@property (nonatomic, retain) NSSet *senderAddresses;
@property (nonatomic, retain) IMAPFolderSetting *sentFolder;
@property (nonatomic, retain) UserSettings *settingsAccountForUser;
@property (nonatomic, retain) IMAPFolderSetting *spamFolder;
@property (nonatomic, retain) NSSet *usedByDevices;
@property (nonatomic, retain) UserSettings *user;
@end

@interface IMAPAccountSetting (CoreDataGeneratedAccessors)

- (void)addFoldersObject:(IMAPFolderSetting *)value;
- (void)removeFoldersObject:(IMAPFolderSetting *)value;
- (void)addFolders:(NSSet *)values;
- (void)removeFolders:(NSSet *)values;

- (void)addSenderAddressesObject:(EmailContactDetail *)value;
- (void)removeSenderAddressesObject:(EmailContactDetail *)value;
- (void)addSenderAddresses:(NSSet *)values;
- (void)removeSenderAddresses:(NSSet *)values;

- (void)addUsedByDevicesObject:(MynigmaDevice *)value;
- (void)removeUsedByDevicesObject:(MynigmaDevice *)value;
- (void)addUsedByDevices:(NSSet *)values;
- (void)removeUsedByDevices:(NSSet *)values;

@end
