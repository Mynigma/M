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





#import "FileAttachment.h"
#import "EmailFooter.h"
#import "EmailMessage.h"
#import "MessageTemplate.h"
#import "MynigmaMessage.h"


@implementation FileAttachment

@dynamic contentid;
@dynamic contentType;
@dynamic decryptionStatus;
@dynamic downloadProgress;
@dynamic encoding;
@dynamic fileName;
@dynamic hashedValue;
@dynamic name;
@dynamic partID;
@dynamic privateBookmark;
@dynamic privateEncryptedDataBookmark;
@dynamic privateEncryptedDataURLString;
@dynamic privateURLString;
@dynamic publicBookmark;
@dynamic publicURLString;
@dynamic remoteURLString;
@dynamic size;
@dynamic uniqueID;
@dynamic hmacValue;
@dynamic attachedAllToMessage;
@dynamic attachedAllToTemplate;
@dynamic attachedToMessage;
@dynamic attachedToTemplate;
@dynamic inlineImageForFooter;
@dynamic rawAttachmentForEncryptedMessage;

@end
