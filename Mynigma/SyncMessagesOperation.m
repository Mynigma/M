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





#import "SyncMessagesOperation.h"
#import "AccountCheckManager.h"
#import <MailCore/MailCore.h>
#import "MCOIMAPSession+Category.h"


@implementation SyncMessagesOperation

+ (SyncMessagesOperation*)syncWithMODSEQValue:(uint64_t)MODSEQValue toFolder:(NSString*)folderPath uids:(MCOIndexSet*)indexSet session:(MCOIMAPSession*)session withCallback:(void(^)(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages))callback
{
    SyncMessagesOperation* newOperation = [SyncMessagesOperation new];
    [newOperation setRequestKind:MCOIMAPMessagesRequestKindFlags|MCOIMAPMessagesRequestKindGmailLabels|MCOIMAPMessagesRequestKindHeaders];
    [newOperation setIndexSet:indexSet];
    [newOperation setFolderPath:folderPath];
    [newOperation setSession:session];
    [newOperation setByNumber:NO];
    [newOperation setCallback:callback];
    [newOperation setMODSEQValue:@(MODSEQValue)];

    if(!indexSet || !folderPath || !@(MODSEQValue) || !session.isValid)
    {
        if (callback)
            callback([NSError errorWithDomain:@"SerialisableOperationError" code:9 userInfo:nil],nil,nil);
        
        return nil;
    }
    
    return newOperation;
}


- (void)main
{
    [self nowStarted];

    dispatch_async([AccountCheckManager mailcoreDispatchQueue], ^{

        MCOIMAPFetchMessagesOperation* syncOperation = [self.session syncMessagesWithFolder:self.folderPath requestKind:MCOIMAPMessagesRequestKindFlags|MCOIMAPMessagesRequestKindGmailLabels|MCOIMAPMessagesRequestKindHeaders uids:self.indexSet modSeq:self.MODSEQValue.integerValue];

        [syncOperation setCallbackDispatchQueue:[AccountCheckManager mailcoreDispatchQueue]];

        [syncOperation start:^(NSError *error, NSArray* messages, MCOIndexSet* vanishedMessages){

            if(self.callback)
                self.callback(error, messages, vanishedMessages);

            [self nowDone];
        }];
    });

    [self waitUntilDone];
}


@end