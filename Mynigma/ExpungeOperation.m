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





#import "ExpungeOperation.h"
#import <MailCore/MailCore.h>
#import "AccountCheckManager.h"
#import "MCOIMAPSession+Category.h"

@implementation ExpungeOperation

+ (ExpungeOperation*)expungeOperationWithFolder:(NSString*)folderPath session:(MCOIMAPSession*)session withCallback:(void(^)(NSError *error))callback
{
    ExpungeOperation* newOperation = [ExpungeOperation new];
    [newOperation setFolderPath:folderPath];
    [newOperation setSession:session];
    [newOperation setCallback:callback];

    if(!folderPath || !session.isValid)
    {
        if (callback)
            callback([NSError errorWithDomain:@"SerialisableOperationError" code:10 userInfo:nil]);
        
        return nil;
    }
    
    return newOperation;
}

- (void)main
{
    [self nowStarted];

    dispatch_async([AccountCheckManager mailcoreDispatchQueue], ^{

        MCOIMAPOperation* expungeOperation = [self.session expungeOperation:self.folderPath];

        [expungeOperation setCallbackDispatchQueue:[AccountCheckManager mailcoreDispatchQueue]];

        [expungeOperation start:^(NSError *error){

            if(self.callback)
                self.callback(error);

            [self nowDone];
        }];
    });

    [self waitUntilDone];
}


@end
