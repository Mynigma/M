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





#import "DeleteMessagesOperation.h"
#import "AppDelegate.h"
#import "AccountCheckManager.h"
#import <MailCore/MailCore.h>
#import "MCOIMAPSession+Category.h"




@implementation DeleteMessagesOperation

+ (DeleteMessagesOperation*)deleteWithFolderPath:(NSString*)path uids:(MCOIndexSet*)indexSet usingSession:(MCOIMAPSession*)session withCallback:(void(^)(NSError*))callback
{
    DeleteMessagesOperation* newOperation = [DeleteMessagesOperation new];
    [newOperation setIndexSet:indexSet];
    [newOperation setFolderPath:path];
    [newOperation setSession:session];
    [newOperation setCallback:callback];
    
    [newOperation setName:[NSString stringWithFormat:@"%@|%@|%@|%@", @"deleteMessages", session.identifierString, path, indexSet.description]];
    
    if(!indexSet || !path || !session.isValid)
    {
        if (callback)
            callback([NSError errorWithDomain:@"SerialisableOperationError" code:5 userInfo:nil]);
        
        return nil;
    }

    return newOperation;
}

- (void)main
{
    [self nowStarted];

    dispatch_async([AccountCheckManager mailcoreDispatchQueue], ^{

    MCOIMAPOperation* deleteOperation = [self.session storeFlagsOperationWithFolder:self.folderPath uids:self.indexSet kind:MCOIMAPStoreFlagsRequestKindAdd flags:MCOMessageFlagDeleted];

    [deleteOperation setCallbackDispatchQueue:[AccountCheckManager mailcoreDispatchQueue]];

    [deleteOperation start:^(NSError *error){

        dispatch_async([AccountCheckManager mailcoreDispatchQueue], ^{
            
        if(error)
        {
            if(self.callback)
                self.callback(error);

            [self nowDone];
        }
        else
        {
            MCOIMAPOperation* expungeOperation = [self.session expungeOperation:self.folderPath];

            [expungeOperation start:^(NSError *error){

                if(self.callback)
                    self.callback(error);

                [self nowDone];
            }];
        }

        });
    }];

    });

    [self waitUntilDone];
}


@end
