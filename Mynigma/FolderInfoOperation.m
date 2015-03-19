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





#import "FolderInfoOperation.h"
#import <MailCore/MailCore.h>
//#import "IMAPSessionHelper.h"
#import "AppDelegate.h"
#import "AccountCheckManager.h"
#import "MCOIMAPSession+Category.h"


@implementation FolderInfoOperation

+ (FolderInfoOperation*)operationWithFolderPath:(NSString*)path usingSession:(MCOIMAPSession*)session withCallback:(void(^)(NSError *error, MCOIMAPFolderInfo* folderInfo))callback
{
    FolderInfoOperation* newOperation = [FolderInfoOperation new];
    [newOperation setFolderPath:path];
    [newOperation setSession:session];
    [newOperation setCallback:callback];

    if(!path || !session.isValid)
    {
        if (callback)
            callback([NSError errorWithDomain:@"SerialisableOperationError" code:7 userInfo:nil],nil);
       
        return nil;
    }
    
    return newOperation;
}


- (void)main
{
    [self nowStarted];

    dispatch_async([AccountCheckManager mailcoreDispatchQueue], ^{

        MCOIMAPFolderInfoOperation* folderInfoOperation = [self.session folderInfoOperation:self.folderPath];

        [folderInfoOperation setCallbackDispatchQueue:[AccountCheckManager mailcoreDispatchQueue]];

        [folderInfoOperation start:^(NSError *error, MCOIMAPFolderInfo* folderInfo){

            if(self.callback)
                self.callback(error, folderInfo);

            [self nowDone];
        }];
    });

    [self waitUntilDone];
}

@end
