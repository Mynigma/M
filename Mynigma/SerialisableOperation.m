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





#import "SerialisableOperation.h"
#import "DisconnectOperation.h"
#import "AccountCheckManager.h"



@implementation SerialisableOperation

- (id)init
{
    self = [super init];
    if (self) {
//        [self willChangeValueForKey:@"isFinished"];
//        _hasAlreadyFinished = NO;
//        [self didChangeValueForKey:@"isFinished"];
//        
//        [self willChangeValueForKey:@"isExecuting"];
//        _isCurrentlyExecuting = NO;
//        [self didChangeValueForKey:@"isExecuting"];

        dispatchGroup = dispatch_group_create();
    }
    return self;
}

- (BOOL)isConcurrent
{
    return YES;
}


- (void)nowDone
{
    dispatch_group_leave(dispatchGroup);
}

- (void)nowStarted
{
    dispatch_group_enter(dispatchGroup);
}

- (void)waitUntilDone
{
    dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER);
}

- (void)setName:(NSString *)name
{
    if ([NSOperation instancesRespondToSelector:@selector(setName:)])
        [super setName:name];
}


#pragma mark - PRIORITIES

//        [self main];
//    }
//}


- (void)setHighPriority
{
    if([self respondsToSelector:@selector(setQualityOfService:)])
    {
#if MAC_OS_X_VERSION_MIN_REQUIRED == MAC_OS_X_VERSION_10_9
        [self setQualityOfService:NSQualityOfServiceUserInitiated];
#endif
    }
    else
    {
        [self setQueuePriority:NSOperationQueuePriorityHigh];
    }
}

- (void)setMediumPriority
{
    if([self respondsToSelector:@selector(setQualityOfService:)])
    {
#if MAC_OS_X_VERSION_MIN_REQUIRED == MAC_OS_X_VERSION_10_9
        [self setQualityOfService:NSQualityOfServiceUserInteractive];
#endif
    }
    else
    {
        [self setQueuePriority:NSOperationQueuePriorityNormal];
    }
}

- (void)setLowPriority
{
    if([self respondsToSelector:@selector(setQualityOfService:)])
    {
#if MAC_OS_X_VERSION_MIN_REQUIRED == MAC_OS_X_VERSION_10_9
        [self setQualityOfService:NSQualityOfServiceUtility];
#endif
    }
    else
    {
        [self setQueuePriority:NSOperationQueuePriorityLow];
    }
}

- (void)setVeryLowPriority
{
    if([self respondsToSelector:@selector(setQualityOfService:)])
    {
#if MAC_OS_X_VERSION_MIN_REQUIRED == MAC_OS_X_VERSION_10_9
        [self setQualityOfService:NSQualityOfServiceBackground];
#endif
    }
    else
    {
        [self setQueuePriority:NSOperationQueuePriorityVeryLow];
    }
}



#pragma mark - ENQUEUEING

- (BOOL)addToMailCoreQueueWithDisconnectOperation:(DisconnectOperation*)disconnectOperation
{
    if(!self.session.hostname || !self.session.username || (!self.session.password && !self.session.OAuth2Token) || !self.session.port)
    {
        NSLog(@"Invalid session info for operation %@ (%@, %@, %ld, %ld)", self, self.session.hostname, self.session.username, (unsigned long)self.session.password.length, (long)self.session.port);

        return NO;
    }

    NSOperationQueue* queue = [AccountCheckManager mailcoreOperationQueue];

    if(disconnectOperation)
        [disconnectOperation addDependency:self];

    [queue addOperation:self];

    return YES;
}

- (void)addToUserActionQueue
{
    NSOperationQueue* queue = [AccountCheckManager userActionOperationQueue];

    [queue addOperation:self];
}

@end
