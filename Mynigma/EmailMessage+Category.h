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






#define PERFORM_MESSAGE_INTEGRITY_CHECKS YES

#import "EmailMessage.h"
#import "CommonHeader.h"


@class MynigmaMessage, IMAPAccountSetting, IMAPSessionHelper, MynigmaFeedback, DisconnectOperation, MCOIMAPSession, MCOMessageBuilder;

@interface EmailMessage (Category)


- (BOOL)isDownloaded;
- (BOOL)isDecrypted;


- (BOOL)isCleaning;
- (BOOL)isDecrypting;
- (BOOL)isDownloading;


- (void)setIsDownloading:(BOOL)isDownloading;
- (void)setIsDecrypting:(BOOL)isDecrypting;
- (void)setIsCleaning:(BOOL)isCleaning;




- (BOOL)canBeDecrypted;
- (BOOL)canBeDownloaded;


- (BOOL)isSafe;

- (BOOL)isDeviceMessage;



- (BOOL)isSentByMe;

- (BOOL)willBeSafeWhenSent;


+ (void)collectAllMessagesWithCallback:(void(^)(void))callback;

+ (instancetype)findOrMakeMessageWithMessageID:(NSString*)messageID inContext:(NSManagedObjectContext*)localContext messageFound:(BOOL*)found;
+ (instancetype)findOrMakeMessageWithMessageID:(NSString*)messageID inContext:(NSManagedObjectContext*)localContext;
+ (instancetype)findOrMakeMessageWithMessageID:(NSString*)messageID messageFound:(BOOL*)found;
+ (instancetype)findOrMakeMessageWithMessageID:(NSString*)messageID;

+ (EmailMessage*)findMessageWithMessageID:(NSString*)messageID inContext:(NSManagedObjectContext*)localContext;

+ (EmailMessage*)findMessageWithMessageID:(NSString*)messageID inContext:(NSManagedObjectContext*)localContext found:(BOOL*)foundMessage;

+ (BOOL)haveMessageWithMessageID:(NSString*)messageID;

+ (EmailMessage*)newDraftMessageInContext:(NSManagedObjectContext*)localContext;




- (MynigmaMessage*)turnIntoSafeMessageInContext:(NSManagedObjectContext*)localContext;

- (void)outputInstancesInfoToConsole;

+ (instancetype)messageWithObjectID:(NSManagedObjectID*)messageObjectID inContext:(NSManagedObjectContext*)localContext;

- (BOOL)includeInAllMessagesDictInContext:(NSManagedObjectContext*)localContext;

- (void)asyncIncludeInAllMessagesDictInContext:(NSManagedObjectContext*)localContext;

- (BOOL)removeMessageFromAllMessagesDict;

//- (BOOL)showWarning;

- (MynigmaFeedback*)feedback;

- (void)checkIntegrity;

- (NSString*)htmlBody;


#pragma mark - Downloading

- (EmailMessageInstance*)downloadableInstance;

//- (void)download;
//- (void)downloadUrgently;
- (void)downloadUsingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation urgent:(BOOL)urgent alsoDownloadAttachments:(BOOL)withAttachments;


#pragma mark - Profile picture

- (IMAGE*)profilePic;
- (BOOL)haveProfilePic;


#pragma mark - Sending

- (NSError*)wrapIntoMessageBuilder:(MCOMessageBuilder*)messageBuilder;


#pragma mark - Deletion

- (void)removeFromStoreInContext:(NSManagedObjectContext*)localContext;


@end
