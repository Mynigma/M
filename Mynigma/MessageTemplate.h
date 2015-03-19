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

@class FileAttachment;

@interface MessageTemplate : NSManagedObject

@property (nonatomic, retain) NSDate * dateSaved;
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSString * htmlBody;
@property (nonatomic, retain) NSDate * lastUsed;
@property (nonatomic, retain) NSString * subject;
@property (nonatomic, retain) NSData * recipients;
@property (nonatomic, retain) NSSet *attachments;
@property (nonatomic, retain) NSSet *allAttachments;
@end

@interface MessageTemplate (CoreDataGeneratedAccessors)

- (void)addAttachmentsObject:(FileAttachment *)value;
- (void)removeAttachmentsObject:(FileAttachment *)value;
- (void)addAttachments:(NSSet *)values;
- (void)removeAttachments:(NSSet *)values;

- (void)addAllAttachmentsObject:(FileAttachment *)value;
- (void)removeAllAttachmentsObject:(FileAttachment *)value;
- (void)addAllAttachments:(NSSet *)values;
- (void)removeAllAttachments:(NSSet *)values;

@end
