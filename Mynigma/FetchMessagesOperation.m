
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





#import "FetchMessagesOperation.h"
#import <MailCore/MailCore.h>
#import "AppDelegate.h"
#import "AccountCheckManager.h"
#import "MCOIMAPSession+Category.h"



@implementation FetchMessagesOperation


+ (FetchMessagesOperation*)fetchMessagesByUIDOperationWithRequestKind:(MCOIMAPMessagesRequestKind)requestKind indexSet:(MCOIndexSet*)indexSet folderPath:(NSString*)folderPath session:(MCOIMAPSession*)session withCallback:(void(^)(NSError* error, NSArray* messages, MCOIndexSet* vanishedMessages))callback
{
    FetchMessagesOperation* newOperation = [FetchMessagesOperation new];
    [newOperation setRequestKind:requestKind];
    [newOperation setIndexSet:indexSet];
    [newOperation setFolderPath:folderPath];
    [newOperation setSession:session];
    [newOperation setByNumber:NO];
    [newOperation setCallback:callback];

    [newOperation setName:[NSString stringWithFormat:@"%@|%@|%ld|%@|%@", @"fetchedMessages", session.identifierString, (long)requestKind, indexSet.description, @"byUID"]];

    if(!indexSet || !folderPath || !session.isValid)
    {
        if (callback)
            callback([NSError errorWithDomain:@"SerialisableOperationError" code:1 userInfo:nil], nil, nil);
        
        return nil;
    }

    return newOperation;
}

+ (FetchMessagesOperation*)fetchMessagesByNumberOperationWithRequestKind:(MCOIMAPMessagesRequestKind)requestKind indexSet:(MCOIndexSet*)indexSet folderPath:(NSString*)folderPath session:(MCOIMAPSession*)session withCallback:(void(^)(NSError* error, NSArray* messages, MCOIndexSet* vanishedMessages))callback
{
    FetchMessagesOperation* newOperation = [FetchMessagesOperation new];
    [newOperation setRequestKind:requestKind];
    [newOperation setIndexSet:indexSet];
    [newOperation setFolderPath:folderPath];
    [newOperation setSession:session];
    [newOperation setByNumber:YES];
    [newOperation setCallback:callback];
    
    [newOperation setName:[NSString stringWithFormat:@"%@|%@|%ld|%@|%@", @"fetchedMessages", session.identifierString, (long)requestKind, indexSet.description, @"byNumber"]];

    if(!indexSet || !folderPath || !session.isValid)
    {
        if (callback)
            callback([NSError errorWithDomain:@"SerialisableOperationError" code:1 userInfo:nil], nil, nil);
       
        return nil;
    }
    
    return newOperation;
}


- (void)main
{
    [self nowStarted];

    dispatch_async([AccountCheckManager mailcoreDispatchQueue], ^{

        MCOIMAPFetchMessagesOperation* operation = nil;

        if(self.byNumber)
        {
            operation = [self.session fetchMessagesByNumberOperationWithFolder:self.folderPath requestKind:self.requestKind numbers:self.indexSet];
        }
        else
        {
            operation = [self.session fetchMessagesOperationWithFolder:self.folderPath requestKind:self.requestKind uids:self.indexSet];
        }

        [operation setCallbackDispatchQueue:[AccountCheckManager mailcoreDispatchQueue]];

        if(self.requestKind & MCOIMAPMessagesRequestKindExtraHeaders)
        {
            [operation setExtraHeaders:@[@"X-Mynigma-Safe-Message", @"X-Myn-PK", @"X-Myn-KL", @"X-Mynigma-Token", @"X-Mynigma-Signup", @"X-Mynigma-Device-Message", @"X-Mynigma-Device-Targets", @"X-Mynigma-Device-ThreadID", @"X-Mynigma-Device-Command", @"X-Mynigma-Device-Sender", @"X-Mailer"]];
        }

        [operation start:^(NSError* error, NSArray* messages, MCOIndexSet* vanishedMessages)
         {
             dispatch_async([AccountCheckManager mailcoreDispatchQueue], ^{

                 if(self.callback)
                     self.callback(error, messages, vanishedMessages);
                 
             [self nowDone];

             });
         }];
    });
    


    [self waitUntilDone];
}


@end
