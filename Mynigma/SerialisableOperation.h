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





#import <Foundation/Foundation.h>

//return the object, if it's not nil, or the [NSNull null] object otherwise
//safe to add to collections
#define GUARD_NULL(x) x?x:[NSNull null]

//the reverse: take a value and convert it to nil iff it's [NSNull null]
#define UNGUARD_NULL(x) [x isEqual:[NSNull null]]?nil:x

@class MCOIMAPSession, DisconnectOperation;

@interface SerialisableOperation : NSOperation
{
    BOOL alreadyStarted;
    BOOL _has_Finished;
    BOOL _is_Executing;

    dispatch_group_t dispatchGroup;
}

@property NSString* folderPath;
@property MCOIMAPSession* session;


#pragma mark - BASIC OPERATION

- (void)nowDone;

- (void)nowStarted;

- (void)waitUntilDone;


#pragma mark - PRIORITIES

//user initiated new message checks
//device message checks and merges in device connection mode
- (void)setHighPriority;

//new message checks (not user initiated)
//disconnect operations
- (void)setMediumPriority;

//merge local changes
- (void)setLowPriority;

//old message checks
- (void)setVeryLowPriority;



#pragma mark - ENQUEUEING

- (BOOL)addToMailCoreQueueWithDisconnectOperation:(DisconnectOperation*)disconnectOperation;

- (void)addToUserActionQueue;


@end
