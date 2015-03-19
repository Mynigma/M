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

@interface ThreadHelper : NSObject

+ (BOOL)ensureMainThread;

+ (BOOL)ensureNotMainThread;

+ (BOOL)ensureLocalThread:(NSManagedObjectContext*)localContext;

+ (void)runAsyncFreshLocalChildContext:(void(^)(NSManagedObjectContext* localContext))executionBlock;

+ (void)runSyncFreshLocalChildContext:(void(^)(NSManagedObjectContext* localContext))executionBlock;


+ (void)runAsyncOnMain:(void(^)(void))blockToRun;

+ (void)runSyncOnMain:(void(^)(void))blockToRun;


+ (void)runAsyncOnKeyContext:(void(^)(void))blockToRun;

+ (void)runSyncOnKeyContext:(void(^)(NSManagedObjectContext* keyContext))blockToRun;


+ (void)printElapsedTimeSince:(NSDate*)startDate withIdentifier:(NSString*)identifier;

+ (void)synchronizeIfNotOnMain:(NSObject*)syncObject block:(void(^)(void))blockToExecute;

@end
