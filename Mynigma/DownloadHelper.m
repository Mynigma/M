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





#import "DownloadHelper.h"
#import "EmailMessage+Category.h"
#import "EmailMessageInstance+Category.h"


//extend the class EmailMessage to make the (private) download method available
@interface EmailMessage()

- (void)downloadUsingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation urgent:(BOOL)urgent alsoDownloadAttachments:(BOOL)withAttachments;

@end



//slight refactoring, mainly to make unit tests work without having to mock managed objects
//wrap calls to download methods in static methods
@implementation DownloadHelper

#pragma mark - Downloading messages

+ (void)downloadMessage:(EmailMessage*)message
{
    [message downloadUsingSession:nil disconnectOperation:nil urgent:NO alsoDownloadAttachments:NO];
}

+ (void)downloadMessage:(EmailMessage*)message urgent:(BOOL)urgent
{
    [message downloadUsingSession:nil disconnectOperation:nil urgent:urgent alsoDownloadAttachments:NO];
}

+ (void)downloadMessage:(EmailMessage*)message urgent:(BOOL)urgent alsoDownloadAttachments:(BOOL)alsoDownloadAttachments
{
    [message downloadUsingSession:nil disconnectOperation:nil urgent:urgent alsoDownloadAttachments:alsoDownloadAttachments];
}

+ (void)downloadMessage:(EmailMessage*)message usingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation
{
    [message downloadUsingSession:session disconnectOperation:disconnectOperation urgent:NO alsoDownloadAttachments:NO];
}

+ (void)downloadMessage:(EmailMessage*)message usingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation urgent:(BOOL)urgent alsoDownloadAttachments:(BOOL)alsoDownloadAttachments
{
    [message downloadUsingSession:session disconnectOperation:disconnectOperation urgent:urgent alsoDownloadAttachments:alsoDownloadAttachments];
}



#pragma mark - Downloading instances

+ (void)downloadMessageInstance:(EmailMessageInstance*)messageInstance
{
    [DownloadHelper downloadMessage:messageInstance.message];
}

+ (void)downloadMessageInstance:(EmailMessageInstance*)messageInstance urgent:(BOOL)urgent
{
    [DownloadHelper downloadMessage:messageInstance.message];
}

+ (void)downloadMessageInstance:(EmailMessageInstance*)messageInstance urgent:(BOOL)urgent alsoDownloadAttachments:(BOOL)alsoDownloadAttachments
{
    [DownloadHelper downloadMessage:messageInstance.message urgent:urgent alsoDownloadAttachments:alsoDownloadAttachments];
}

+ (void)downloadMessageInstance:(EmailMessageInstance*)messageInstance usingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation
{
    [DownloadHelper downloadMessage:messageInstance.message usingSession:session disconnectOperation:disconnectOperation];
}

+ (void)downloadMessageInstance:(EmailMessageInstance*)messageInstance usingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation urgent:(BOOL)urgent alsoDownloadAttachments:(BOOL)alsoDownloadAttachments
{
    [messageInstance.message downloadUsingSession:session disconnectOperation:disconnectOperation urgent:urgent alsoDownloadAttachments:alsoDownloadAttachments];
}



@end
