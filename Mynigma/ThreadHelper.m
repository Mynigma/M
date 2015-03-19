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



#import "ThreadHelper.h"
#import "AppDelegate.h"

#import <objc/runtime.h>



#define BEACH_BALL_DEBUGGING 0


#define MAXIMUM_QUEUE_TIME -1
#define MAXIMUM_RUN_TIME 1.


static NSString* dictKey = @"MynManagedObjectContext";

@implementation ThreadHelper

+ (BOOL)ensureMainThread
{
    if(![NSThread isMainThread])
    {
        NSLog(@"Ensuring main thread failed!!");
        NSLog(@"Stack trace: %@", [NSThread callStackSymbols]);
        return NO;
    }

    return YES;
}

+ (BOOL)ensureNotMainThread
{
    if([NSThread isMainThread])
    {
        NSLog(@"Ensuring not main thread failed!!");
        NSLog(@"Stack trace: %@", [NSThread callStackSymbols]);
        return NO;
    }

    return YES;
}

+ (BOOL)ensureLocalThread:(NSManagedObjectContext*)localContext
{
    NSThread* currentThread = [NSThread currentThread];

    if([currentThread isMainThread])
    {
        if([localContext isEqual:MAIN_CONTEXT])
        {
            return YES;
        }
        else
        {
            NSLog(@"Using local context %@ on main thread!!", localContext);
            NSLog(@"Stack trace: %@", [NSThread callStackSymbols]);
            return NO;
        }
    }

    NSManagedObjectContext* associatedObjectContext = currentThread.threadDictionary[dictKey];
    //NSManagedObjectContext* associatedObjectContext = (NSManagedObjectContext*)objc_getAssociatedObject(localContext, &key);
    //NSThread* associatedThread = (NSThread*)objc_getAssociatedObject(localContext, &key);

    if([associatedObjectContext isEqual:localContext])
        return YES;
    else
    {
        if([localContext isEqual:MAIN_CONTEXT])
            NSLog(@"Using main context %@ on wrong local thread!!", localContext);
        else
            NSLog(@"Using local context %@ on wrong local thread!!", localContext);
        NSLog(@"Stack trace: %@", [NSThread callStackSymbols]);
        return NO;
    }
}

+ (void)runAsyncFreshLocalChildContext:(void(^)(NSManagedObjectContext* localContext))executionBlock
{
    NSManagedObjectContext* localContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [localContext setParentContext:MAIN_CONTEXT];
    [localContext setMergePolicy:NSErrorMergePolicy];
    [localContext setUndoManager:nil];

    [localContext performBlock:^{

        NSThread* currentThread = [NSThread currentThread];

        currentThread.threadDictionary[dictKey] = localContext;

        executionBlock(localContext);

        NSError* error = nil;

        //NSDate* startDate = [NSDate date];

        [localContext save:&error];

        //[ThreadHelper printElapsedTimeSince:startDate withIdentifier:@"local context save"];

        if(error)
        {
            NSLog(@"Error saving local context at end of run async block");
        }

        [currentThread.threadDictionary removeObjectForKey:dictKey];
    }];
}

+ (void)runSyncFreshLocalChildContext:(void(^)(NSManagedObjectContext* localContext))executionBlock
{
    if([NSThread isMainThread])
    {
        NSLog(@"Attempting to start sync local child context on main context - will cause deadlock(!!)");
    }

    NSManagedObjectContext* localContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [localContext setParentContext:MAIN_CONTEXT];
    [localContext setMergePolicy:NSErrorMergePolicy];
    [localContext setUndoManager:nil];

    [localContext performBlockAndWait:^{

        NSThread* currentThread = [NSThread currentThread];

        currentThread.threadDictionary[dictKey] = localContext;

        executionBlock(localContext);

        NSError* error = nil;

        [localContext save:&error];

        if(error)
        {
            NSLog(@"Error saving local context at end of run async block");
        }
        
        [currentThread.threadDictionary removeObjectForKey:dictKey];
    }];

}


+ (void)runAsyncOnKeyContext:(void(^)(void))blockToRun
{
    [KEY_CONTEXT performBlock:^{

        blockToRun();

        NSError* error = nil;

        [KEY_CONTEXT save:&error];

        if(error)
        {
            NSLog(@"Error saving key context at end of ThreadHelper async block");
        }

        [CoreDataHelper save];
    }];
}

+ (void)runSyncOnKeyContext:(void(^)(NSManagedObjectContext* keyContext))blockToRun
{
    //don't call [KEY_CONTEXT performBlockAndWait:] from the main thread
    //it would cause a deadlock if the key context needs to fetch objects from its parent, the main context
    if([NSThread isMainThread])
    {
        [MAIN_CONTEXT performBlockAndWait:^{

            blockToRun(MAIN_CONTEXT);

            [CoreDataHelper save];
        }];
    }
    else
    {
    [KEY_CONTEXT performBlockAndWait:^{

        blockToRun(KEY_CONTEXT);

        NSError* error = nil;

        [KEY_CONTEXT save:&error];

        if(error)
        {
            NSLog(@"Error saving key context at end of ThreadHelper sync block");
        }

        [CoreDataHelper save];
}];
    }
}

+ (void)runAsyncOnMain:(void(^)(void))blockToRun
{

#if BEACH_BALL_DEBUGGING

    NSDate* queueDate = [NSDate date];

    NSArray* stackTrace = [NSThread callStackSymbols];

#endif

    [MAIN_CONTEXT performBlock:^{

#if BEACH_BALL_DEBUGGING

        NSDate* runDate = [NSDate date];

#endif

        blockToRun();

#if BEACH_BALL_DEBUGGING

        NSDate* endDate = [NSDate date];

        NSTimeInterval queueTime = [runDate timeIntervalSinceDate:queueDate];

        NSTimeInterval runTime = [endDate timeIntervalSinceDate:runDate];

        if((queueTime > MAXIMUM_QUEUE_TIME && MAXIMUM_QUEUE_TIME > 0) || (runTime > MAXIMUM_RUN_TIME && MAXIMUM_RUN_TIME > 0))
        {
            NSLog(@"Block queued for %.f ms, ran in %.f ms\nStack trace: %@", 1000*queueTime, 1000*runTime, stackTrace);
        }

#endif

    }];
}

+ (void)runSyncOnMain:(void(^)(void))blockToRun
{
#if BEACH_BALL_DEBUGGING

    NSDate* queueDate = [NSDate date];

#endif

    [MAIN_CONTEXT performBlockAndWait:^{

#if BEACH_BALL_DEBUGGING

        NSDate* runDate = [NSDate date];

#endif

        blockToRun();

#if BEACH_BALL_DEBUGGING

        NSDate* endDate = [NSDate date];

        NSTimeInterval queueTime = [runDate timeIntervalSinceDate:queueDate];

        NSTimeInterval runTime = [endDate timeIntervalSinceDate:runDate];
        
        if((queueTime > MAXIMUM_QUEUE_TIME && MAXIMUM_QUEUE_TIME > 0) || (runTime > MAXIMUM_RUN_TIME && MAXIMUM_RUN_TIME > 0))
        {
            NSLog(@"Block queued for %.f ms, ran in %.f ms\nStack trace: %@", 1000*queueTime, 1000*runTime, [NSThread callStackSymbols]);
        }
        
#endif
        
    }];
}

+ (void)printElapsedTimeSince:(NSDate*)startDate withIdentifier:(NSString*)identifier
{
    NSDate* currentDate = [NSDate date];

    NSLog(@"%ld ms elapsed. %@", (long)([currentDate timeIntervalSinceDate:startDate]*1000), identifier);
}


/**
Calls block within an @synchronized(syncObject) statement, unless it is called on the main thread. In this case no synchronisation is enforced. This prevents beach balls for code that should not, but may be executed concurrently on the main and at most one other thread.
*/
+ (void)synchronizeIfNotOnMain:(NSObject*)syncObject block:(void(^)(void))blockToExecute
{
    if([NSThread isMainThread])
    {
        if(blockToExecute)
            blockToExecute();
    }
    else
    {
        @synchronized(syncObject)
        {
            if(blockToExecute)
                blockToExecute();
        }
    }
}

@end
