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
#import <CoreData/CoreData.h>
#import "EmailMessage.h"

@class MynigmaDevice;

@interface DeviceMessage : EmailMessage

@property (nonatomic, retain) NSNumber * burnAfterReading;
@property (nonatomic, retain) NSDate * expiryDate;
@property (nonatomic, retain) NSString * messageCommand;
@property (nonatomic, retain) NSData * payloadData;
@property (nonatomic, retain) NSString * threadID;
@property (nonatomic, retain) MynigmaDevice *discoveryMessageForDevice;
@property (nonatomic, retain) MynigmaDevice *sender;
@property (nonatomic, retain) NSSet *targets;
@property (nonatomic, retain) MynigmaDevice *dataSyncMessageForDevice;
@end

@interface DeviceMessage (CoreDataGeneratedAccessors)

- (void)addTargetsObject:(MynigmaDevice *)value;
- (void)removeTargetsObject:(MynigmaDevice *)value;
- (void)addTargets:(NSSet *)values;
- (void)removeTargets:(NSSet *)values;

@end
