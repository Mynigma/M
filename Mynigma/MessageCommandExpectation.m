//
//  MessageCommandExpectation.m
//  Mynigma
//
//  Created by Roman Priebe on 21.05.14.
//  Copyright (c) 2014 Mynigma UG (haftungsbeschränkt). All rights reserved.
//

#import "MessageCommandExpectation.h"

@implementation MessageCommandExpectation

- (MessageCommandExpectation*)initWithCommandString:(NSString*)messageCommandString andNumberOfPayloads:(NSNumber*)numberOfPayloads
{
    self = [super init];
    if (self) {

        _messageCommand = messageCommandString;

        _expectedNumberOfPayloads = numberOfPayloads;

    }
    return self;
}

- (BOOL)validateCommand:(NSString*)messageCommandString withNumberOfPayloads:(NSInteger)numberOfPayloads
{
    BOOL result = [messageCommandString isEqualToString:self.messageCommand] && ((!self.expectedNumberOfPayloads) || (numberOfPayloads == self.expectedNumberOfPayloads.integerValue));

    return result;
}

@end
