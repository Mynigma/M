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

@class KeyExpectation, MynigmaPublicKey;

@interface EmailAddress : NSManagedObject

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSDate * dateAdded;
@property (nonatomic, retain) NSDate * dateCurrentKeyAnchored;
@property (nonatomic, retain) MynigmaPublicKey *currentKey;
@property (nonatomic, retain) KeyExpectation *expectationsFrom;
@property (nonatomic, retain) KeyExpectation *expectationsTo;
@property (nonatomic, retain) NSSet *allKeys;
@end

@interface EmailAddress (CoreDataGeneratedAccessors)

- (void)addAllKeysObject:(MynigmaPublicKey *)value;
- (void)removeAllKeysObject:(MynigmaPublicKey *)value;
- (void)addAllKeys:(NSSet *)values;
- (void)removeAllKeys:(NSSet *)values;

@end
