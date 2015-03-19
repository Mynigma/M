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



#import "SendingManager.h"
#import "EmailMessage+Category.h"
#import "IMAPAccount.h"
#import "IMAPAccountSetting+Category.h"
#import "IMAPFolderSetting+Category.h"
#import "MynigmaMessage+Category.h"
#import "EmailMessageData.h"
#import "EmailRecipient.h"
#import "FileAttachment+Category.h"
#import "IMAPFolderManager.h"
#import "GmailAccountSetting.h"
#import "AttachmentsManager.h"
#import "EmailMessageInstance+Category.h"
#import "UserSettings+Category.h"
#import "PublicKeyManager.h"
#import "EmailAccount.h"
#import "AddressDataHelper.h"
#import "Recipient.h"
#import "DataWrapHelper.h"
#import "DeviceMessage+Category.h"
#import "MynigmaDevice+Category.h"
#import "NSData+Base64.h"
#import "MynigmaPublicKey+Category.h"
#import "SelectionAndFilterHelper.h"
#import "AlertHelper.h"
#import "NSString+EmailAddresses.h"





static NSMutableSet* messagesBeingSent;

@implementation SendingManager


/**CALL ON MAIN*/
+ (void)sendDraftMessageInstance:(EmailMessageInstance*)messageInstance fromAccount:(IMAPAccount*)account withCallback:(void (^)(NSInteger,NSError*))callback
{
    [ThreadHelper ensureMainThread];

    if(!account.accountSetting.outboxFolder)
    {
        NSLog(@"Cannot send message: no outbox folder set for account setting!");
        callback(-5,nil);
        return;
    }
    //moving the instance to the outbox creates a new instance
    //we need to send and then move the instance in the outbox, so re-assign
    messageInstance = [messageInstance moveToOutbox];
    [SelectionAndFilterHelper refreshFolderOrAccount:account.accountSetting.outboxFolder.objectID];
    [SendingManager sendOutboxMessageInstance:messageInstance fromAccount:account withCallback:callback];
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

/**CALL ON MAIN*/
+ (NSData*)MCOMessageForEmailMessage:(EmailMessage*)message
{
    [ThreadHelper ensureMainThread];

    return [self MCOMessageForEmailMessage:message inContext:MAIN_CONTEXT];
}

+ (NSData*)MCOMessageForEmailMessage:(EmailMessage*)message inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    MCOMessageBuilder* messageBuilder = [MCOMessageBuilder new];

    [messageBuilder setBoundaryPrefix:@"Apple-Mail-"];

#if TARGET_OS_IPHONE

    NSString* userAgent = [NSString stringWithFormat:@"Apple Mail / Mynigma iOS %@", MYNIGMA_VERSION];

#else

    NSString* userAgent = [NSString stringWithFormat:@"Apple Mail / Mynigma %@", MYNIGMA_VERSION];

#endif

    [[messageBuilder header] setUserAgent:userAgent];

    // set date
    [[messageBuilder header] setDate:message.dateSent];

    Recipient* senderRecipient = [AddressDataHelper senderAsRecipientForMessage:message addIfNotFound:YES];

    NSString* messageID = message.messageid;

    if(!messageID)
    {
        messageID = [senderRecipient.displayEmail generateMessageID];
        [message setMessageid:messageID];
    }

    [messageBuilder.header setMessageID:messageID];


    NSError* error = [message wrapIntoMessageBuilder:messageBuilder];

    if(error)
    {
        [AlertHelper presentError:error];

        return nil;
    }

    NSData* rfc822Data = [messageBuilder data];

    return rfc822Data;
}

#pragma GCC diagnostic pop


/**CALL ON MAIN*/
+ (void)sendOutboxMessageInstance:(EmailMessageInstance*)messageInstance fromAccount:(IMAPAccount*)account withCallback:(void (^)(NSInteger,NSError*))callback
{
    [ThreadHelper ensureMainThread];

    __block NSManagedObjectID* messageInstanceDraftID = messageInstance.objectID;

    NSData* messageData = [self MCOMessageForEmailMessage:messageInstance.message];

    if(!messageData)
    {
        NSLog(@"Cannot send message: no MCO message set");

        callback(-6,nil);

        [messageInstance moveToDrafts];

        //this causes a crash

        //NSAlert* alert  = [NSAlert alertWithMessageText:NSLocalizedString(@"Error sending message", @"alert window") defaultButton:NSLocalizedString(@"OK", "OK button") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"An error occurred while trying to send your message", @"alert window")];

        //[alert runModal];

#if TARGET_OS_IPHONE

#else

#endif

        return;
    }

    if(!messagesBeingSent)
        messagesBeingSent = [NSMutableSet new];

    NSString* messageIdentifier = messageInstance.message.messageid;

    if([messagesBeingSent containsObject:messageIdentifier])
    {
        callback(-7, nil);
        return;
    }

    if(!messageIdentifier)
    {
        callback(-8, nil);
        return;
    }
    
    [messagesBeingSent addObject:messageIdentifier];

        __block BOOL allSuccessful = YES;
    
    NSLog(@"Sending message! Folder: %@", messageInstance.inFolder.displayName);


    if (![self isValidSMTPSession:account.smtpSession])
    {
        NSLog(@"--Error sending message--\n %@ \n <invalid session>",self);
        callback(-8,nil);
        return;
    }
    MCOSMTPSendOperation* sendOperation = [account.smtpSession sendOperationWithData:messageData];

        [sendOperation start:^(NSError *error) {

            [MAIN_CONTEXT performBlock:^{

                if(error)
                allSuccessful = NO;

            if(allSuccessful)
                {
                    EmailMessageInstance* messageInstance = [EmailMessageInstance messageInstanceWithObjectID:messageInstanceDraftID inContext:MAIN_CONTEXT];

                    NSLog(@"Sent message! Folder: %@", messageInstance.inFolder.displayName);
                    
                    if(messageInstance)
                    {
                        if(account.accountSetting.sentMessagesCopiedIntoSentFolder.boolValue)
                            [messageInstance moveToSent];
                        else
                            [messageInstance moveToBinOrDelete];

                        callback(1,nil);

                        [SelectionAndFilterHelper refreshFolderOrAccount:account.accountSetting.outboxFolder.objectID];
                        [SelectionAndFilterHelper refreshFolderOrAccount:account.accountSetting.sentFolder.objectID];
                        [SelectionAndFilterHelper refreshAllMessages];

                        [CoreDataHelper save];
                    }
                    else
                        callback(1,nil);
                }
                else
                {
                    NSLog(@"--Error sending message--\n %@\nError: %@",self,error);
                    callback(-1,error);
                }

                if([messagesBeingSent containsObject:messageIdentifier])
                    [messagesBeingSent removeObject:messageIdentifier];

            }];
        }];
}

+ (void)sendAnyUnsentMessages
{
    [ThreadHelper ensureMainThread];

    for(IMAPAccountSetting* accountSetting in [UserSettings usedAccounts])
    {
        [accountSetting.account sendAnyUnsentMessages];
    }
}

+(BOOL)isValidSMTPSession:(MCOSMTPSession*)smtpSession
{
    if (!smtpSession.hostname)
        return NO;
    if (!smtpSession.port)
        return NO;
    if (!smtpSession.username)
        return NO;
    if (!smtpSession.password && !smtpSession.OAuth2Token)
        return NO;
    if (!smtpSession.authType)
        return NO;
    if (!smtpSession.connectionType)
        return NO;
        
    return YES;
}



@end
