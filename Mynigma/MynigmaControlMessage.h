//
//  MynigmaControlMessage.h
//  BlueBird
//
//  Created by Roman Priebe on 04/07/2013.
//  Copyright (c) 2013 Mynigma. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "EmailMessage.h"

@class EmailContactDetail, MynigmaControlMessage, MynigmaDeclaration;

@interface MynigmaControlMessage : EmailMessage

@property (nonatomic, retain) NSString * command;
@property (nonatomic, retain) NSData * declarationData;
@property (nonatomic, retain) NSString * keyLabel;
@property (nonatomic, retain) NSNumber * responseToken;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * version;
@property (nonatomic, retain) MynigmaDeclaration *declaration;
@property (nonatomic, retain) EmailContactDetail *from;
@property (nonatomic, retain) MynigmaControlMessage *inReplyTo;
@property (nonatomic, retain) MynigmaControlMessage *reply;
@property (nonatomic, retain) EmailContactDetail *to;

@end
