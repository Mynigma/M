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





#import "StoreLabelsOperation.h"
//#import "IMAPSessionHelper.h"
#import "AppDelegate.h"
#import <MailCore/MailCore.h>
#import "AccountCheckManager.h"
#import "MCOIMAPSession+Category.h"



@implementation StoreLabelsOperation


+ (StoreLabelsOperation*)storeLabelsWithFolderPath:(NSString*)path uids:(MCOIndexSet*)indexSet labels:(NSArray*)labels kind:(MCOIMAPStoreFlagsRequestKind)requestKind usingSession:(MCOIMAPSession*)session withCallback:(void(^)(NSError*))callback
{
    StoreLabelsOperation* newOperation = [StoreLabelsOperation new];
    [newOperation setIndexSet:indexSet];
    [newOperation setLabels:labels];
    [newOperation setFolderPath:path];
    [newOperation setRequestKind:requestKind];
    [newOperation setSession:session];
    [newOperation setCallback:callback];
    
    [newOperation setName:[NSString stringWithFormat:@"%@|%@|%@|%ld|%@|%@", @"storeLabels", session.identifierString, labels, (long)requestKind, path, indexSet.description]];

    if(!indexSet || !path || !session.isValid)
    {
        if (callback)
            callback([NSError errorWithDomain:@"SerialisableOperationError" code:4 userInfo:nil]);
        
        return nil;
    }

    
    return newOperation;
}

- (void)main
{
    [self nowStarted];

    dispatch_async([AccountCheckManager mailcoreDispatchQueue], ^{

    MCOIMAPOperation* operation = [self.session storeLabelsOperationWithFolder:self.folderPath uids:self.indexSet kind:self.requestKind labels:self.labels];

    [operation setCallbackDispatchQueue:[AccountCheckManager mailcoreDispatchQueue]];

    [operation start:^(NSError* error){

        dispatch_async([AccountCheckManager mailcoreDispatchQueue], ^{

            if(self.callback)
                self.callback(error);

            [self nowDone];

        });
        
     }];

    });

    [self waitUntilDone];
}

@end
