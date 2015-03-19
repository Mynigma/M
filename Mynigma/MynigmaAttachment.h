//
//  MynigmaAttachment.h
//  Mynigma
//
//  Created by Roman Priebe on 11/08/2013.
//  Copyright (c) 2013 Mynigma UG (haftungsbeschränkt). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MynigmaMessage;

@interface MynigmaAttachment : NSManagedObject

@property (nonatomic, retain) NSData * encryptedData;
@property (nonatomic, retain) NSString * recipient;
@property (nonatomic, retain) MynigmaMessage *attachedToMessage;

@end
