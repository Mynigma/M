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





#import "POP3Account.h"
//#import "RegistrationHelper.h"
#import <MailCore/MailCore.h>
#import "IMAPAccountSetting.h"



@implementation POP3Account

@synthesize popSession;


- (instancetype)init
{
    self = [super init];
    if (self) {
        newMessageObjectIDs = [NSMutableArray new];

        fetchingSignUpMessage = NO;

        //registrationHelper = [[RegistrationHelper alloc] initWithAccount:self];

        messagesBeingDownloaded = [NSMutableSet new];
        messagesBeingDecrypted = [NSMutableSet new];

        operationQueues = [NSMutableDictionary new];
    }
    return self;
}


//checks the account (first new, then existing messages)
- (void)checkAccount
{
//    if(lastTriedAccountCheck && [lastTriedAccountCheck timeIntervalSinceNow]>-10*60)
//    {
//        lastTriedAccountCheck = [NSDate date];
//        if(self.accountSetting)
//        {
//            for(IMAPFolderSetting* folderSetting in self.accountSetting.folders)
//            [self checkFolder:folderSetting];
//        }
//    }
}


//used for inbox and spam folders: checks for new messages and then starts idling
- (void)checkFolder:(IMAPFolderSetting*)folderSetting
{
    //MCOPOPOperation* fetchMessagesOperation = [self.popSession fetchMessagesOperation];



    //self.popSession fetchMessagesOperation
}




//invoked when the user clicks on the account in the sidebar
- (void)clickedOnAccount
{
    
}


@end
