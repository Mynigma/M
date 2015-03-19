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





#import "IMAPSessionMock.h"
#import <MailCore/MailCore.h>
#import "MCOIMAPFetchMessagesOperationMock.h"
#import "MCOIMAPSearchOperationMock.h"
#import "IMAPFolderSettingMock.h"

@implementation IMAPSessionMock


- (id)init
{
    self = [super init];
    if (self) {
        uidCounter = 1;
        fetchOperationMock = [MCOIMAPFetchMessagesOperationMock new];
        searchOperationMock = [MCOIMAPSearchOperationMock new];
    }
    return self;
}

- (MCOIMAPFetchMessagesOperationMock*)fetchMessagesByUIDOperationWithFolder:(NSString*)folder requestKind:(MCOIMAPMessagesRequestKind)requestKind uids:MCOIndexSet
{
    return fetchOperationMock;
}

- (MCOIMAPSearchOperationMock*) searchOperationWithFolder:(NSString *)folder kind:(MCOIMAPSearchKind)kind searchString:(NSString *)searchString
{
    return searchOperationMock;
}

- (void)addWelcomeMessageWithToken:(NSString*)messageID
{
    MCOIMAPMessage* newMessage = [MCOIMAPMessage new];

    newMessage.header.subject = @"Welcome to M - Safe email made simple";

    newMessage.header.messageID = messageID;

    newMessage.uid = (uint32_t)uidCounter;

    uidCounter++;

    [fetchOperationMock.messagesToBeFetched addObject:newMessage];

    [searchOperationMock.indexSetToBeReturned addIndex:newMessage.uid];
}

- (void)removeAllWelcomeMessages
{
    [fetchOperationMock setMessagesToBeFetched:[NSMutableArray new]];
    [searchOperationMock setIndexSetToBeReturned:[MCOIndexSet new]];
}

- (IMAPFolderSettingMock*)inboxFolder
{
    return [[IMAPFolderSettingMock alloc] initWithPath:@"INBOX"];
}

- (IMAPFolderSettingMock*)spamFolder
{
    return [[IMAPFolderSettingMock alloc] initWithPath:@"Spam"];
}

@end
