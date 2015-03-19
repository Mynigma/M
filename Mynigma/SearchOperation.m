//Copyright © 2012 - 2015 Roman Priebe
//
//This file is part of M - Safe email made simple.
//
//M is free software: you can redistribute it and/or modify
//it under the terms of the GNU General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.
//
//M is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU General Public License
//along with M.  If not, see <http://www.gnu.org/licenses/>.
//



#import "SearchOperation.h"
#import "AccountCheckManager.h"
#import "MCOIMAPSession+Category.h"

@implementation SearchOperation

+ (SearchOperation*)searchInFolder:(NSString*)folderPath withSearchKind:(MCOIMAPSearchKind)searchKind searchString:(NSString*)searchString session:(MCOIMAPSession*)session withCallback:(void(^)(NSError* error, MCOIndexSet* indexSet))callback
{
    SearchOperation* newOperation = [SearchOperation new];
    [newOperation setFolderPath:folderPath];
    [newOperation setSearchKind:searchKind];
    [newOperation setSearchString:searchString];
    [newOperation setSession:session];
    [newOperation setCallback:callback];
    
    if(!folderPath || !searchKind || !searchString || !session.isValid)
    {
        if (callback)
            callback([NSError errorWithDomain:@"SerialisableOperationError" code:11 userInfo:nil],nil);
        
        return nil;
    }

    return newOperation;
}

+ (SearchOperation*)searchByExpression:(MCOIMAPSearchExpression*)expression inFolder:(NSString*)folderPath session:(MCOIMAPSession*)session withCallback:(void(^)(NSError* error, MCOIndexSet* resultSet))callback
{
    SearchOperation* newOperation = [SearchOperation new];
    [newOperation setFolderPath:folderPath];
    [newOperation setSearchExpression:expression];
    [newOperation setSession:session];
    [newOperation setCallback:callback];

    if(!folderPath || !expression || !session.isValid)
    {
        if (callback)
            callback([NSError errorWithDomain:@"SerialisableOperationError" code:11 userInfo:nil],nil);
        
        return nil;
    }
    
    return newOperation;
}

- (void)main
{
    [self nowStarted];

    dispatch_async([AccountCheckManager mailcoreDispatchQueue], ^{

        MCOIMAPSearchOperation* searchOperation = nil;

        if(self.searchExpression)
        {
            searchOperation = [self.session searchExpressionOperationWithFolder:self.folderPath expression:self.searchExpression];
        }
        else
        {
            searchOperation = [self.session searchOperationWithFolder:self.folderPath kind:self.searchKind searchString:self.searchString];
        }

        [searchOperation setCallbackDispatchQueue:[AccountCheckManager mailcoreDispatchQueue]];

        [searchOperation start:^(NSError *error, MCOIndexSet* indexSet){

            if(self.callback)
                self.callback(error, indexSet);

            [self nowDone];
        }];
    });

    [self waitUntilDone];
}


@end
