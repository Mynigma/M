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





#import "EmailMessageInstance.h"

@class IMAPFolderSetting, DisconnectOperation, MCOIMAPSession;

@interface EmailMessageInstance (Category)



- (BOOL)isInSpamFolder;
- (BOOL)isInBinFolder;
- (BOOL)isInDraftsFolder;
- (BOOL)isInSentFolder;
- (BOOL)isInOutboxFolder;
- (BOOL)isInAllMailFolder;
- (BOOL)isInInboxFolder;

- (BOOL)isSourceOfMove;


- (void)markUnread;

//marks a message as read
- (void)markRead;
//marks a message as unread
- (BOOL)isUnread;

//returns whether a message is important - currently unused
- (BOOL)isImportant;

//marks a message as important
//- (void)markImportant;
//marks a message as unimportant
//- (void)markUnimportant;
//marks a message as unflagged
- (void)markUnflagged;
- (void)markFlagged;

//returns whether a message is flagged
- (BOOL)isFlagged;

- (BOOL)isOnServer;

- (BOOL)recipientListIsSafe;
- (BOOL)isSafe;

- (void)moveToSpam;
- (void)moveToInbox;
//- (void)moveToAllMailOrInbox;
- (void)moveToDrafts;
- (void)moveToSent;

- (EmailMessageInstance*)moveToOutbox;

- (void)moveToBinOrDelete;

- (EmailMessageInstance*)moveDestination;

- (void)moveOnIMAPDoneWithNewUID:(NSNumber*)newUID withContext:(NSManagedObjectContext*)localContext toInstance:(EmailMessageInstance*)newInstance;


- (void)deleteInstanceInContext:(NSManagedObjectContext*)localContext;

- (void)deleteCompletelyWithContext:(NSManagedObjectContext*)localContext;


- (EmailMessageInstance*)moveToFolder:(IMAPFolderSetting*)folderSetting;
//- (EmailMessageInstance*)moveToFolder:(IMAPFolderSetting*)folderSetting inContext:(NSManagedObjectContext*)localContext;

/** Use for drag and drop: a message is dragged to toFolder, fromFolder is the folder *currently selected*, not the folder the message is in...*/
- (void)moveToFolderOrAddLabel:(IMAPFolderSetting*)toFolder fromFolder:(IMAPFolderSetting*)fromFolder;
- (BOOL)canMoveToFolderOrAddLabel:(IMAPFolderSetting*)toFolder fromFolder:(IMAPFolderSetting*)fromFolder;

- (void)addDraggedLabel:(GmailLabelSetting*)label;
- (BOOL)canAddLabel:(GmailLabelSetting*)label;


//don't download instances directly
//call the methods in EmailMessage to avoid downloading the body of safe/device messages
//- (void)downloadAndOrDecryptUsingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation urgent:(BOOL)urgent alsoDownloadAttachments:(BOOL)withAttachments;
//
//- (void)downloadAndOrDecryptUsingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation urgent:(BOOL)urgent;

- (IMAPAccountSetting*)accountSetting;

- (NSManagedObjectID*)accountSettingObjectID;

- (void)UIDNotFoundOnServerWithContext:(NSManagedObjectContext*)localContext;

/**Looks for an existing instance with either the given messageID or, failing that, the given UID in this folder (even if the messageID is incorrect)*/
+ (EmailMessageInstance*)findExistingInstanceWithMessageID:(NSString*)messageID andUid:(NSNumber*)uid inFolder:(IMAPFolderSetting*)folderSetting inContext:(NSManagedObjectContext*)localContext;

/**Looks for an existing instance of the EmailMessage in this folder. If none is found a new one is created*/
+ (EmailMessageInstance*)findOrMakeNewInstanceForMessage:(EmailMessage*)message inFolder:(IMAPFolderSetting*)localFolderSetting inContext:(NSManagedObjectContext*)localContext;

+ (EmailMessageInstance*)findOrMakeNewInstanceForMessage:(EmailMessage*)message inFolder:(IMAPFolderSetting*)localFolderSetting inContext:(NSManagedObjectContext*)localContext alreadyFoundOne:(BOOL*)foundOne;

/**Looks for an existing instance with the given UID in this folder. If none is found a new one will be created. The addedToFolder connection will *not* be set*/
+ (EmailMessageInstance*)findOrMakeNewInstanceForMessage:(EmailMessage*)message inFolder:(IMAPFolderSetting*)localFolderSetting withUID:(NSNumber*)UID inContext:(NSManagedObjectContext*)localContext;

+ (EmailMessageInstance*)findOrMakeNewInstanceForMessage:(EmailMessage*)message inFolder:(IMAPFolderSetting*)localFolderSetting withUID:(NSNumber*)UID inContext:(NSManagedObjectContext*)localContext alreadyFoundOne:(BOOL*)foundOne;

/**Looks for an existing instance with the given messageID in the account provided. If none is found returns nil*/
+ (EmailMessageInstance*)findExistingInstanceWithMessageID:(NSString *)messageID inAccount:(IMAPAccountSetting*)accountSetting inContext:(NSManagedObjectContext *)localContext;

/**Checks if an instance with this UID exists in the specified folder*/
+ (BOOL)haveInstanceWithUid:(NSNumber*)UID inFolder:(IMAPFolderSetting*)localFolderSetting UIDCollection:(NSIndexSet*)UIDCollection;


/**Looks for a former instance that has been deleted or moved away by the user - an instance must match both messageID *and* UID, if both are provided*/
+ (BOOL)haveRemovedInstanceWithMessageID:(NSString*)messageID andUid:(NSNumber*)uid inFolder:(IMAPFolderSetting*)folderSetting inContext:(NSManagedObjectContext*)localContext;

- (IMAPAccount*)account;
- (IMAPFolderSetting*)folderSetting;

+ (EmailMessageInstance*)messageInstanceWithObjectID:(NSManagedObjectID*)objectID inContext:(NSManagedObjectContext*)localContext;

- (void)changeUID:(NSNumber*)newUID;


#pragma mark - Deletion

- (void)removeFromStoreInContext:(NSManagedObjectContext*)localContext;


@end
