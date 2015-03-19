//
//  ServerHelperMock.h
//  Mynigma
//
//  Created by Roman Priebe on 30.01.14.
//  Copyright (c) 2012 - 2014 Roman Priebe. All rights reserved.
//

#import "ServerHelper.h"

@interface ServerHelperMock : ServerHelper
{
    NSDictionary* returnDict;
    NSError* returnError;
}



//causes ServerhelperMock to respond to all subsequent requests by executing the callback with the given parameters
- (void)setReturnDict:(NSDictionary*)dict withError:(NSError*)error;


@end
