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

@class EmailFooter, EmailMessage, MessageTemplate, MynigmaMessage;

@interface FileAttachment : NSManagedObject

@property (nonatomic, retain) NSString * contentid;
@property (nonatomic, retain) NSString * contentType;
@property (nonatomic, retain) NSString * decryptionStatus;
@property (nonatomic, retain) NSNumber * downloadProgress;
@property (nonatomic, retain) NSNumber * encoding;
@property (nonatomic, retain) NSString * fileName;
@property (nonatomic, retain) NSData * hashedValue;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * partID;
@property (nonatomic, retain) NSData * privateBookmark;
@property (nonatomic, retain) NSData * privateEncryptedDataBookmark;
@property (nonatomic, retain) NSString * privateEncryptedDataURLString;
@property (nonatomic, retain) NSString * privateURLString;
@property (nonatomic, retain) NSData * publicBookmark;
@property (nonatomic, retain) NSString * publicURLString;
@property (nonatomic, retain) NSString * remoteURLString;
@property (nonatomic, retain) NSNumber * size;
@property (nonatomic, retain) NSString * uniqueID;
@property (nonatomic, retain) NSData * hmacValue;
@property (nonatomic, retain) EmailMessage *attachedAllToMessage;
@property (nonatomic, retain) MessageTemplate *attachedAllToTemplate;
@property (nonatomic, retain) EmailMessage *attachedToMessage;
@property (nonatomic, retain) MessageTemplate *attachedToTemplate;
@property (nonatomic, retain) EmailFooter *inlineImageForFooter;
@property (nonatomic, retain) MynigmaMessage *rawAttachmentForEncryptedMessage;

@end
