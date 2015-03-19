//Copyright © 2012 - 2015 Roman Priebe
//
//This file is part of M - Safe email made simple.
//
//M is free software: you can redistribute it and/or modify
//it under the terms of the GNU General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.
//
//M is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU General Public License
//along with M.  If not, see <http://www.gnu.org/licenses/>.
//



#import "FileAttachment.h"
#import "AppDelegate.h"

@class MCOIMAPSession, DisconnectOperation;

@interface FileAttachment (Category)


- (BOOL)havePublicData;
- (BOOL)havePrivateData;

- (BOOL)isAnImage;

-(BOOL) isInline;


- (BOOL)isDownloaded;
- (BOOL)isDecrypted;
- (BOOL)isDecrypting;
- (BOOL)isDownloading;
- (void)setIsDownloading:(BOOL)isDownloading;
- (void)setIsDecrypting:(BOOL)isDecrypting;
- (BOOL)canBeDecrypted;
- (BOOL)canBeDownloaded;
- (BOOL)canBeSavedByUser;
- (BOOL)isMissing;




- (NSURL*)publicURL;
- (NSURL*)privateEncryptedURL;
- (NSURL*)privateURL;


- (void)saveDataToPrivateURL:(NSData*)data;
- (void)saveDataToPrivateEncryptedURL:(NSData*)data;

/**CALL ON MAIN THREAD*/
- (void)saveAndDecryptData:(NSData*)data;

- (NSData*)data;
- (NSData*)encryptedData;

- (FileAttachment*)copyInContext:(NSManagedObjectContext*)localContext;

+ (FileAttachment*)makeNewAttachmentFromURL:(NSURL*)URL;

- (NSString*)sizeString;


- (NSURL*)URL;


- (IMAGE*)thumbnail;

- (NSString*)overlayString;

+ (FileAttachment*)makeAttachmentWithInlineImageData:(NSData*)imageData fileName:(NSString*)fileName contentType:(NSString*)contentType contentID:(NSString*)contentID inContext:(NSManagedObjectContext*)localContext;


#pragma mark - Downloading

- (void)downloadUsingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation withCallback:(void(^)(NSData* data))callback;

- (void)downloadUsingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation *)disconnectOperation urgent:(BOOL)urgent withCallback:(void(^)(NSData* data))callback;

- (void)urgentlyDownloadWithCallback:(void(^)(NSData* data))callback;


@end
