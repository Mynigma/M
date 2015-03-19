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





#import "FetchAllFoldersOperation.h"
#import "AccountCheckManager.h"
#import <MailCore/MailCore.h>
#import "MCOIMAPSession+Category.h"


@implementation FetchAllFoldersOperation

+ (FetchAllFoldersOperation*)fetchAllFoldersWithSession:(MCOIMAPSession*)session withCallback:(void(^)(NSError *error, NSArray *fetchedFolders))callback
{
    FetchAllFoldersOperation* newOperation = [FetchAllFoldersOperation new];

    [newOperation setSession:session];
    [newOperation setCallback:callback];
    
    if(!session.isValid)
    {
        if (callback)
            callback([NSError errorWithDomain:@"SerialisableOperationError" code:14 userInfo:nil],nil);
        
        return nil;
    }

    return newOperation;

}


- (void)main
{
    [self nowStarted];

    dispatch_async([AccountCheckManager mailcoreDispatchQueue], ^{

        MCOIMAPFetchFoldersOperation* operation = [self.session fetchAllFoldersOperation];

        //[operation setCallbackDispatchQueue:[AccountCheckManager mailcoreDispatchQueue]];

        [operation start:^(NSError *error, NSArray *fetchedFolders)
         {
             dispatch_async([AccountCheckManager mailcoreDispatchQueue], ^{
             if(self.callback)
                 self.callback(error, fetchedFolders);

             [self nowDone];
             });
         }];
    });

    [self waitUntilDone];
}

@end
