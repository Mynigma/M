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

@class EmailMessage;

@interface EmailMessageData : NSManagedObject

@property (nonatomic, retain) NSData * addressData;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSString * fromName;
@property (nonatomic, retain) NSNumber * hasImages;
@property (nonatomic, retain) NSString * htmlBody;
@property (nonatomic, retain) NSNumber * loadRemoteImages;
@property (nonatomic, retain) NSNumber * mainPartEncoding;
@property (nonatomic, retain) NSString * mainPartID;
@property (nonatomic, retain) NSNumber * size;
@property (nonatomic, retain) NSString * subject;
@property (nonatomic, retain) NSString * mainPartType;
@property (nonatomic, retain) EmailMessage *message;

@end
