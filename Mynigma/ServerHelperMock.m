//
//  ServerHelperMock.m
//  Mynigma
//
//  Created by Roman Priebe on 30.01.14.
//  Copyright (c) 2012 - 2014 Roman Priebe. All rights reserved.
//

#import "ServerHelperMock.h"
#import "IMAPAccountSetting.h"
#import "TestHarness.h"
#import "AppDelegate.h"
#import "Model.h"
#import "IMAPSessionMock.h"


static NSMutableDictionary* tokens;
static NSMutableArray* users;

static NSMutableDictionary* keyLabels;

@implementation ServerHelperMock

- (id)init
{
    self = [super init];
    if (self) {
        if(!tokens)
            tokens = [NSMutableDictionary new];
        if(!users)
            users = [NSMutableArray new];

        //overwrite the shared instance to return this mock instead...
        [ServerHelper setSharedInstance:self];
    }
    return self;
}

- (void)requestWelcomeMessageForAccount:(IMAPAccountSetting*)accountSetting withCallBack:(void(^)(NSDictionary*, NSError*))callBack
{
    NSString* email = accountSetting.emailAddress;

    if([users containsObject:email])
    {
        callBack(@{@"response":@"ALREADY_SIGNED_UP"}, nil);
    }

    TestHarness* theHarness = [TestHarness sharedInstance];

    NSString* messageID = [MODEL generateMessageID:@"unit-tests@mynigma.org"];

    [theHarness.imapSesionMock addWelcomeMessageWithToken:messageID];

    //if(!tokens[email])
    //    tokens[email] = [NSMutableArray new];
    //[tokens[email] addObject:messageID];
    tokens[email] = [NSMutableArray arrayWithObject:messageID];
}


- (void)confirmSignUpForAccount:(IMAPAccountSetting*)accountSetting withMessageID:(NSString*)messageID andCallBack:(void (^)(NSDictionary *, NSError *))callBack
{
    NSString* email = accountSetting.emailAddress;
    NSString* keyLabel = accountSetting.currentKeyPairLabel;
    if([users containsObject:email])
        {
            if([[tokens objectForKey:email] containsObject:messageID])
            {
                if([keyLabels[messageID] isEqual:keyLabel])
                    callBack(@{@"response":@"OK"}, nil);
                else
                    callBack(@{@"response":@"WRONG_KEY_ID"}, nil);
            }
            else
            {
                if([(NSArray*)tokens[email] count]==0)
                    callBack(@{@"response":@"NO_TOKEN"}, nil);
                else
                    callBack(@{@"response":@"WRONG_TOKEN"}, nil);
            }
        }
    else
    {
        callBack(@{@"response":@"ALREADY_SIGNED_UP"}, nil);
    }
}

/*
- (void)sendRequestToServer:(NSMutableArray*)requestArray withKeyLabel:(NSString*)keyLabel andCallBack:(void(^)(NSDictionary* result, NSError* error))callBack
{
    if(returnDict)
        callBack(returnDict, returnError);
    else
    {
        return [super sendRequestToServer:requestArray withKeyLabel:keyLabel andCallBack:callBack];
    }
}*/


- (void)setReturnDict:(NSDictionary*)dict withError:(NSError*)error
{
    returnDict = dict;
    returnError = error;
}

@end
