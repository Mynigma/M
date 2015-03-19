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





#import "AppDelegate.h"
#import "IdleHelper.h"
#import "IMAPAccount.h"
#import "IMAPAccountSetting.h"
#import "IMAPFolderSetting.h"
#import "AccountCheckManager.h"

#import <MailCore/MailCore.h>

//@implementation MCOIMAPSession (Copying)
//
//
//- (MCOIMAPSession*)copy
//{
//    MCOIMAPSession* newSession = [MCOIMAPSession new];
//
//    [newSession setAllowsFolderConcurrentAccessEnabled:self.allowsFolderConcurrentAccessEnabled];
//    [newSession setAuthType:self.authType];
//    [newSession setCheckCertificateEnabled:self.checkCertificateEnabled];
//
//    ...
//
//    return newSession;
//}
//
//@end



@implementation IdleHelper

-(id) initWithIMAPAccount:(IMAPAccount*)imapAcc
{
    self = [super init];

    if(self)
    {
        imapAccount = imapAcc;

        // new idle session - copy the parameters from the imapAcc's session params
        imapSession = [imapAcc freshSession];

        isIdling = false;
        idleTimer = nil;
        idleOperation = nil;
    }
    return self;
}

-(BOOL) isIdling
{
    return isIdling;
}

-(void) ensureMainThread
{
    if(![NSThread isMainThread])
        NSLog(@"Executing on thread other than main!!");
}



//-(void) restartIdle
//{
//    if (idleOperation)
//    {
//        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//
//            [idleOperation interruptIdle];
//        //RESTART IDLE HERE
//
//
//
//        });
//    }
//}

-(void)idle:(IMAPFolderSetting*)folderSetting
{
    [self ensureMainThread];

    //return;

    if(!imapAccount.accountSetting.shouldUse.boolValue)
        return;
    
    if(isIdling)
    {
        //NSLog(@"Already idling...");
        return;
    }
    
    if(!imapAccount.canIdle)
    {
        return;
    }

    if(!imapSession.password && !imapSession.OAuth2Token)
    {
        [imapSession setPassword:imapAccount.quickAccessSession.password];
        [imapSession setOAuth2Token:imapAccount.quickAccessSession.OAuth2Token];
        if(!imapSession.password && !imapSession.OAuth2Token)
        {
            NSLog(@"Cannot idle: missing password");
            return;
        }
    }

    if(!imapSession.username)
    {
        imapSession.username = imapAccount.accountSetting.incomingUserName;

        if(!imapSession.username)
            {
                NSLog(@"Cannot idle: missing username");
                return;
            }
    }

    if(!imapSession.port)
    {
        imapSession.port = imapAccount.accountSetting.incomingPort.unsignedIntValue;

        if(!imapSession.port)
        {
            NSLog(@"Cannot idle: missing port");
            return;
        }
    }

    if(!imapSession.hostname)
    {
        imapSession.hostname = imapAccount.accountSetting.incomingServer;

        if(!imapSession.hostname)
        {
            NSLog(@"Cannot idle: missing hostname");
            return;
        }
   }


    isIdling = YES;

    folderBeingIdled = folderSetting;

    //NSLog(@"Idle operation: %@ %ld",folderSetting.path,folderSetting.uidNext.unsignedIntegerValue-1);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{

        if (!idleOperation){

            //        dispatch_async([AccountCheckManager mailcoreDispatchQueue], ^{

            idleOperation = [imapSession idleOperationWithFolder:folderSetting.path lastKnownUID:folderSetting.uidNext.unsignedIntValue>0?folderSetting.uidNext.unsignedIntValue-1:0];

            //[idleOperation setCallbackDispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)];

            //        });
        }


        [idleOperation start:^(NSError *error) {

                CGFloat delay = 0;

                if(error)
                {
                    //NSLog(@"Idle error: %@",error);

                    if(error.code == MCOErrorConnection) //connection error - wait for three minutes
                        delay = 3*60;
                    else
                        delay = 60; //another kind of error - try again in one minute

                }
                else
                {
                    //NSLog(@"Idle done");
                    delay = .5;
                }

                isIdling = NO;

                [self performSelector:@selector(handleReturnedIdle) withObject:nil afterDelay:delay];
        }];
        
    });
}

- (void)handleReturnedIdle
{
    [ThreadHelper runAsyncOnMain:^{

    [imapAccount checkFolder:folderBeingIdled userInitiated:NO];

    [self idle:folderBeingIdled];

    }];
}

- (IMAPFolderSetting*)idledFolder
{
    return folderBeingIdled;
}

- (void)cancelIdle
{
    if (idleOperation)
    {
        [idleOperation interruptIdle];
    }
}

@end
