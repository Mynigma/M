//
//  MessageCommandExpectation.h
//  Mynigma
//
//  Created by Roman Priebe on 21.05.14.
//  Copyright (c) 2014 Mynigma UG (haftungsbeschränkt). All rights reserved.
//

#import <Foundation/Foundation.h>

#define EXPECT_COMMAND(messageCommand,numberOfPayloads) ([[MessageCommandExpectation alloc] initWithCommandString:messageCommand andNumberOfPayloads:numberOfPayloads])

@interface MessageCommandExpectation : NSObject

@property NSString* messageCommand;

@property NSArray* messageCommands;

@property NSNumber* expectedNumberOfPayloads;

- (MessageCommandExpectation*)initWithCommandString:(NSString*)messageCommandString andNumberOfPayloads:(NSNumber*)numberOfPayloads;

- (BOOL)validateCommand:(NSString*)messageCommand withNumberOfPayloads:(NSInteger)numberOfPayloads;

@end
