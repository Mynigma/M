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

@class FileAttachment, IMAPAccountSetting, UserSettings;

@interface EmailFooter : NSManagedObject

@property (nonatomic, retain) NSString * htmlContent;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *senderAddresses;
@property (nonatomic, retain) NSSet *standardForUser;
@property (nonatomic, retain) NSSet *inlineImages;
@end

@interface EmailFooter (CoreDataGeneratedAccessors)

- (void)addSenderAddressesObject:(IMAPAccountSetting *)value;
- (void)removeSenderAddressesObject:(IMAPAccountSetting *)value;
- (void)addSenderAddresses:(NSSet *)values;
- (void)removeSenderAddresses:(NSSet *)values;

- (void)addStandardForUserObject:(UserSettings *)value;
- (void)removeStandardForUserObject:(UserSettings *)value;
- (void)addStandardForUser:(NSSet *)values;
- (void)removeStandardForUser:(NSSet *)values;

- (void)addInlineImagesObject:(FileAttachment *)value;
- (void)removeInlineImagesObject:(FileAttachment *)value;
- (void)addInlineImages:(NSSet *)values;
- (void)removeInlineImages:(NSSet *)values;

@end
