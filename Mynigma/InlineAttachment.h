//
//  InlineAttachment.h
//  BlueBird
//
//  Created by Roman Priebe on 07/08/2013.
//  Copyright (c) 2013 Mynigma. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EmailMessage;

@interface InlineAttachment : NSManagedObject

@property (nonatomic, retain) NSString * contentid;
@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) EmailMessage *inMessage;

@end
