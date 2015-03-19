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
#import "FileAttachment+Category.h"


@interface AttachmentsManager : NSObject
{
}


+ (void)promptUserToSaveAttachment:(FileAttachment*)fileAttachment;

+ (void)promptUserToSaveAttachments:(NSArray*)attachments;

#if TARGET_OS_IPHONE

#else

+ (void)promptUserToSaveAttachment:(FileAttachment*)fileAttachment withWindow:(NSWindow*)window;

+ (void)promptUserToSaveAttachments:(NSArray *)attachments withWindow:(NSWindow*)window;

#endif

+ (void)openAttachment:(FileAttachment*)attachment;

+ (FileAttachment*)makeFreshCopyOfAttachment:(FileAttachment*)fileAttachment inContext:(NSManagedObjectContext*)localContext;

+ (NSArray*)attachmentItemsForMessage:(EmailMessage*)message;


@end
