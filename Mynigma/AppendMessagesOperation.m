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





#import "AppendMessagesOperation.h"
//#import "IMAPSessionHelper.h"
#import "AppDelegate.h"
#import "AccountCheckManager.h"
#import <MailCore/MailCore.h>
#import "MCOIMAPSession+Category.h"



@implementation AppendMessagesOperation


+ (AppendMessagesOperation*)appendMessagesWithData:(NSData*)data toFolderWithPath:(NSString*)path withFlags:(MCOMessageFlag)flags session:(MCOIMAPSession*)session withCallback:(void(^)(NSError*, uint32_t))callback
{
    AppendMessagesOperation* newOperation = [AppendMessagesOperation new];
    [newOperation setData:data];
    [newOperation setFlags:flags];
    [newOperation setFolderPath:path];
    [newOperation setSession:session];
    [newOperation setCallback:callback];
    
    [newOperation setName:[NSString stringWithFormat:@"%@|%@|%ld|%@|%ld", @"appendMessages", session.identifierString, (long)flags, path, (long)data.length]];
    
    if(!data || !path || !session.isValid)
    {
        if (callback)
            callback([NSError errorWithDomain:@"SerialisableOperationError" code:2 userInfo:nil], -1);
        
        return nil;
    }

    return newOperation;
}

- (void)main
{
    [self nowStarted];

    dispatch_async([AccountCheckManager mailcoreDispatchQueue], ^{

        MCOIMAPAppendMessageOperation* appendOperation = [self.session appendMessageOperationWithFolder:self.folderPath messageData:self.data flags:self.flags];

        [appendOperation setCallbackDispatchQueue:[AccountCheckManager mailcoreDispatchQueue]];

        [appendOperation start:^(NSError *error, uint32_t UID) {
            
            dispatch_async([AccountCheckManager mailcoreDispatchQueue], ^{

                if(self.callback)
                    self.callback(error, UID);

                [self nowDone];
            });
        }];
    });

    [self waitUntilDone];
}



@end
