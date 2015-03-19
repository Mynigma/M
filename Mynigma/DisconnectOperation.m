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





#import "DisconnectOperation.h"
#import <MailCore/MailCore.h>
#import "AccountCheckManager.h"
#import "MCOIMAPSession+Category.h"


@implementation DisconnectOperation

+ (DisconnectOperation*)operationWithIMAPSession:(MCOIMAPSession*)IMAPSession withCallback:(void(^)(NSError* error))callback
{
    DisconnectOperation* newOperation = [DisconnectOperation new];

    [newOperation setSession:IMAPSession];

    [newOperation setCallback:callback];

    //high priority to free up sessions and ensure user feedback given asap
    [newOperation setHighPriority];
    
    if(!IMAPSession.isValid)
    {
        if (callback)
            callback([NSError errorWithDomain:@"SerialisableOperationError" code:8 userInfo:nil]);
        
        return nil;
    }

    return newOperation;
}

- (void)main
{
    [self nowStarted];

    if(!self.session)
    {
        //no session was created
        //just return
        [self nowDone];

        if(self.callback)
            self.callback(nil);
    }
    else
    {
        //disconnect the session
        dispatch_async([AccountCheckManager mailcoreDispatchQueue], ^{

        MCOIMAPOperation* disconnectOperation = [self.session disconnectOperation];

        [disconnectOperation setCallbackDispatchQueue:[AccountCheckManager mailcoreDispatchQueue]];

        [disconnectOperation start:^(NSError *error) {

            dispatch_async([AccountCheckManager mailcoreDispatchQueue], ^{

                if(self.callback)
                    self.callback(error);

                [self nowDone];
            });
        }];
    });
    }

    [self waitUntilDone];
}


@end
