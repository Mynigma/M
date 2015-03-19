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





#import "FetchAttachmentOperation.h"
#import "AccountCheckManager.h"
#import "MCOIMAPSession+Category.h"


@implementation FetchAttachmentOperation

+ (FetchAttachmentOperation*)fetchMessageAttachmentByUIDWithFolder:(NSString*)folderPath uid:(NSUInteger)UID partID:(NSString*)partID encoding:(MCOEncoding)encoding urgent:(BOOL)urgent session:(MCOIMAPSession*)session withProgressBlock:(MCOIMAPBaseOperationProgressBlock)progressBlock withCallback:(void(^)(NSError* error, NSData* partData))callback
{
    FetchAttachmentOperation* newOperation = [FetchAttachmentOperation new];

    [newOperation setFolderPath:folderPath];
    [newOperation setUID:UID];
    [newOperation setPartID:partID];
    [newOperation setEncoding:encoding];
    [newOperation setUrgent:urgent];
    [newOperation setSession:session];
    [newOperation setProgressCallback:progressBlock];
    [newOperation setCallback:callback];
    
    if(!folderPath || !UID || !partID || !(-1 <= encoding <= 5) || !session.isValid)
    {
        if (callback)
            callback([NSError errorWithDomain:@"SerialisableOperationError" code:13 userInfo:nil],nil);
        
        return nil;
    }
    

    return newOperation;
}


- (void)main
{
    [self nowStarted];

    dispatch_async([AccountCheckManager mailcoreDispatchQueue], ^{

        MCOIMAPFetchContentOperation* operation = [self.session fetchMessageAttachmentOperationWithFolder:self.folderPath uid:(uint32_t)self.UID partID:self.partID encoding:self.encoding urgent:self.urgent];

        if(self.progressCallback)
        {
            [operation setProgress:self.progressCallback];
        }

        [operation setCallbackDispatchQueue:[AccountCheckManager mailcoreDispatchQueue]];
        
        [operation start:^(NSError *error, NSData* partData)
        {
            if(self.callback)
                self.callback(error, partData);
            
            [self nowDone];
        }];
    });

    [self waitUntilDone];
}
                                                                                                                                                                                                           
@end
