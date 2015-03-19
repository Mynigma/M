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

@class IMAPFolderSetting, MCOIMAPMessage, EmailMessageInstance, MCOIMAPSession, DisconnectOperation;

@interface MessageSyncHelper : NSObject

+ (NSArray*)arrayOfLabelStringsForStoreMessageInstance:(EmailMessageInstance*)storeMessageInstance;

+ (NSSet*)labelStringsForStoreMessageInstance:(EmailMessageInstance*)storeMessageInstance;


//+ (void)deleteServerMessage:(MCOIMAPMessage*)serverMessage withLocalFolderSetting:(IMAPFolderSetting*)localFolderSetting inLocalContext:(NSManagedObjectContext*)localContext;

//+ (void)copyStoreMessageInstanceToServer:(EmailMessageInstance*)storeMessageInstance;

//+ (void)moveServerMessage:(MCOIMAPMessage*)serverMessage fromFolderPath:(NSString*)sourceFolderPath withStoreMessage:(EmailMessageInstance*)storeMessageInstance usingSession:(IMAPSessionHelper*)session localContext:(NSManagedObjectContext*)localContext;

+ (void)syncFlagsOnStoreMessageInstance:(EmailMessageInstance*)storeMessageInstance withServerMessage:(MCOIMAPMessage*)serverMessage inFolder:(IMAPFolderSetting*)localFolderSetting usingSession:(MCOIMAPSession*)passedSession disconnectOperation:(DisconnectOperation*)disconnectOperation withLocalContext:(NSManagedObjectContext*)localContext;

//+ (void)updateFlagsAndMoveMessageInstanceIfNecessary:(EmailMessageInstance*)storeMessageInstance withServerMessage:(MCOIMAPMessage*)serverMessage inFolder:(IMAPFolderSetting*)localFolderSetting withContext:(NSManagedObjectContext*)localContext usingSession:(IMAPSessionHelper*)session;

//+ (BOOL)processDownloadedServerMessage:(MCOIMAPMessage*)serverMessage inFolder:(IMAPFolderSetting*)localFolderSetting withContext:(NSManagedObjectContext*)localContext usingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation newMessageInstancesArray:(NSMutableArray*)newMessages UIDCollection:(NSIndexSet*)UIDCollection;

+ (void)processUpdatedFlagsForMessage:(MCOIMAPMessage*)serverMessage inFolder:(IMAPFolderSetting*)localFolderSetting withContext:(NSManagedObjectContext*)localContext usingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation newMessageInstancesArray:(NSMutableArray*)newMessages;

+ (void)populateMessageInstance:(EmailMessageInstance*)messageInstance withCoreMessage:(MCOIMAPMessage*)imapMessage inFolder:(IMAPFolderSetting*)folderSetting andContext:(NSManagedObjectContext*)localContext;

+ (void)populateMessage:(EmailMessage*)message withCoreMessage:(MCOIMAPMessage*)imapMessage inFolder:(IMAPFolderSetting*)folderSetting andContext:(NSManagedObjectContext*)localContext;


@end
