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





#import "FolderInfoObject.h"

@implementation FolderInfoObject

@synthesize completelyLoaded;
@synthesize isBusy;
@synthesize lastError;
@synthesize lowestUID;
@synthesize nextUID;
@synthesize successfulBackLoads;
@synthesize unsuccessfulBackLoads;
@synthesize successfulForwardLoads;
@synthesize unsuccessfulForwardLoads;
@synthesize numberOfMessages;


- (id)init
{
    self = [super init];
    if (self) {
        completelyLoaded = NO;
        isBusy = NO;
        lastError = nil;
        lowestUID = -1;
        nextUID = -1;
        successfulBackLoads = 0;
        unsuccessfulBackLoads = 0;
        successfulForwardLoads = 0;
        unsuccessfulForwardLoads = 0;
        numberOfMessages = 0;
        self.isBackwardLoading = NO;
    }
    return self;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"Back: %ld ✅, %ld ❌ - forward: %ld ✅, %ld ❌ %@\n", (long)successfulBackLoads, (long)(successfulBackLoads + unsuccessfulBackLoads), (long)successfulForwardLoads, (long)(successfulForwardLoads + unsuccessfulForwardLoads), completelyLoaded?@"more...":@"done."];
}


@end
