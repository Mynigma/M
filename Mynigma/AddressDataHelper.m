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
#import "AddressDataHelper.h"
#import "EmailRecipient.h"
#import "Recipient.h"
#import "EmailMessage+Category.h"
#import "EmailMessageData.h"
#import "UserSettings+Category.h"
#import "IMAPAccountSetting+Category.h"
#import "OutlineObject.h"
#import "IMAPAccount.h"
#import "EmailMessageInstance+Category.h"
#import "SelectionAndFilterHelper.h"
#import "NSString+EmailAddresses.h"




@implementation AddressDataHelper

#pragma mark - Address data vs. recipient list conversions

+ (NSArray*)emailRecipientsForAddressData:(NSData*)addressData
{
    if(addressData.length==0)
        return nil;

    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:addressData];
    NSArray* recArray = [unarchiver decodeObjectForKey:@"recipients"];
    [unarchiver finishDecoding];
    return [recArray sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"email" ascending:YES]]];
}

+ (NSArray*)recipientsForAddressData:(NSData*)addressData
{
    if(addressData.length==0)
        return nil;

    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:addressData];
    NSArray* recArray = [unarchiver decodeObjectForKey:@"recipients"];
    [unarchiver finishDecoding];
    NSMutableArray* recipientsArray = [NSMutableArray new];
    if(recArray)
    {
        for(EmailRecipient* emailRecipient in recArray)
        {
            Recipient* recipient = [emailRecipient recipient];
            [recipientsArray addObject:recipient];
        }
    }
    [recipientsArray sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"email" ascending:YES]]];

    return recipientsArray;
}

+ (NSData*)addressDataForRecipients:(NSArray*)recipients
{
    NSMutableArray* emailRecArray = [NSMutableArray new];

    for(Recipient* rec in recipients)
    {
        EmailRecipient* emailRec = [rec emailRecipient];

        [emailRecArray addObject:emailRec];
    }

    return [self addressDataForEmailRecipients:emailRecArray];
}

+ (NSData*)addressDataForEmailRecipients:(NSArray*)emailRecipients
{
    NSMutableData* addressData = [NSMutableData new];
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:addressData];
    [archiver encodeObject:emailRecipients forKey:@"recipients"];
    [archiver finishEncoding];
    
    return addressData;
}


#pragma mark - Sender addresses


+ (EmailRecipient*)senderAmongRecipients:(NSArray*)recipients
{
    for(EmailRecipient* rec in recipients)
    {
        if([rec isKindOfClass:[EmailRecipient class]])
            if(rec.type==TYPE_FROM)
                return rec;

        if([rec isKindOfClass:[Recipient class]])
            if([(Recipient*)rec type]==TYPE_FROM)
                return [(Recipient*)rec emailRecipient];
    }

    return nil;
}

+ (EmailRecipient*)senderAsEmailRecipientForMessage:(EmailMessage*)message
{
    return [self senderAsEmailRecipientForMessage:message addIfNotFound:NO];
}

+ (Recipient*)senderAsRecipientForMessage:(EmailMessage*)message
{
    return [self senderAsRecipientForMessage:message addIfNotFound:NO];
}


//DO NOT CHANGE - IMPORTANT FOR VERIFYING SIGNATURES
+ (EmailRecipient*)senderAsEmailRecipientForMessage:(EmailMessage*)message addIfNotFound:(BOOL)addIfNotFound

{
    NSArray* emailRecArray = [self emailRecipientsForAddressData:message.messageData.addressData];

    for(EmailRecipient* rec in emailRecArray)
    {
        if(rec.type==TYPE_FROM)
            return rec;
    }

    if(addIfNotFound)
    {
        if(!message.messageData.addressData)
            [message.messageData setAddressData:[NSData new]];

        NSArray* recipients = [self recipientsForAddressData:message.messageData.addressData];

        EmailRecipient* newRec = [self standardSenderAsEmailRecipient];

        if(!newRec)
            return nil;

        recipients = [recipients arrayByAddingObject:newRec];

        NSData* newAddressData = [self addressDataForEmailRecipients:recipients];

        [message.messageData setAddressData:newAddressData];

        return newRec;
    }

    return nil;
}

//DO NOT CHANGE - IMPORTANT FOR VERIFYING SIGNATURES
+ (NSArray*)nonSenderEmailRecipientsForMessage:(EmailMessage*)message
{
    NSMutableArray* returnArray = [NSMutableArray new];

    NSArray* emailRecArray = [self emailRecipientsForAddressData:message.messageData.addressData];

    for(EmailRecipient* rec in emailRecArray)
    {
        if(rec.type!=TYPE_FROM && rec.type!=TYPE_REPLY_TO)
            [returnArray addObject:rec];;
    }

    return returnArray;
}


+ (Recipient*)senderAsRecipientForMessage:(EmailMessage*)message addIfNotFound:(BOOL)addIfNotFound
{
    return [[self senderAsEmailRecipientForMessage:message addIfNotFound:addIfNotFound] recipient];
}


+ (IMAPAccountSetting*)senderAccountSettingForReplyToOrForwardOfMessage:(EmailMessage*)message
{
    NSData* recData = message.messageData.addressData;

    if(recData.length==0)
        return nil;

    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:recData];
    NSArray* recArray = [unarchiver decodeObjectForKey:@"recipients"];
    [unarchiver finishDecoding];

        NSArray* ownEmails = [[UserSettings usedAccounts] valueForKey:@"senderEmail"];

    for(EmailRecipient* rec in recArray)
    {
        if([ownEmails containsObject:rec.email])
        {
            for(IMAPAccountSetting* accountSetting in [UserSettings usedAccounts])
            {
                if([accountSetting.senderEmail isEqual:rec.email])
                {
                    return accountSetting;
                }
            }
        }
    }

    return [AddressDataHelper senderAccountSetting];
}

+ (IMAPAccountSetting*)senderAccountSetting
{
    if([SelectionAndFilterHelper sharedInstance].topSelection)
    {
        if([[SelectionAndFilterHelper sharedInstance].topSelection isAccount])
        {
            IMAPAccountSetting* returnValue = [[SelectionAndFilterHelper sharedInstance].topSelection accountSetting];
            if(returnValue)
                return returnValue;
        }
    }

    return [UserSettings currentUserSettings].preferredAccount;
}

+ (Recipient*)senderAsRecipientForReplyToOrForwardOfMessage:(EmailMessage*)message
{
    IMAPAccountSetting* senderSetting = [self senderAccountSettingForReplyToOrForwardOfMessage:message];

    if(senderSetting)
    {
        NSString* senderName = senderSetting.senderName;
        NSString* senderEmail = senderSetting.senderEmail;

        if(!senderEmail)
            senderEmail = senderSetting.emailAddress;

        if(!senderName)
            senderName = senderEmail;

        Recipient* rec = [[Recipient alloc] initWithEmail:senderEmail andName:senderName];

        [rec setType:TYPE_FROM];

        return rec;
    }
    
    return nil;
}


+ (EmailRecipient*)standardSenderAsEmailRecipient
{
    IMAPAccountSetting* senderSetting = [self senderAccountSetting];

    if(senderSetting)
    {
        NSString* senderName = senderSetting.senderName;
        NSString* senderEmail = senderSetting.senderEmail;

        if(!senderEmail)
            senderEmail = senderSetting.emailAddress;

        if(!senderName)
            senderName = senderEmail;

        EmailRecipient* emailRec = [EmailRecipient new];

        [emailRec setName:senderName];
        [emailRec setEmail:senderEmail];
        [emailRec setType:TYPE_FROM];

        return emailRec;
    }
    
    return nil;
}

+ (Recipient*)standardSenderAsRecipient
{
    IMAPAccountSetting* senderSetting = [self senderAccountSetting];

    if(senderSetting)
    {
        NSString* senderName = senderSetting.senderName;
        NSString* senderEmail = senderSetting.senderEmail;

        if(!senderEmail)
            senderEmail = senderSetting.emailAddress;

        if(!senderName)
            senderName = senderEmail;

        Recipient* rec = [[Recipient alloc] initWithEmail:senderEmail andName:senderName];

        [rec setType:TYPE_FROM];

        return rec;
    }
    
    return nil;
}



#pragma mark - recipients for reply, reply all and forward

+ (NSArray*)recipientsForReplyToMessage:(EmailMessage*)message
{
    NSData* recData = message.messageData.addressData;

    if(recData.length==0)
        return nil;

    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:recData];
    NSArray* recArray = [unarchiver decodeObjectForKey:@"recipients"];
    [unarchiver finishDecoding];

    NSMutableArray* recipientArray = [NSMutableArray new];
    if([message isSentByMe])
    {
        for(EmailRecipient* rec in recArray)
            if(rec.type==TYPE_TO)
            {
                Recipient* newRecipient = [rec recipient];
                [recipientArray addObject:newRecipient];
            }
    }
    else
    {
        for(EmailRecipient* rec in recArray)
            if(rec.type==TYPE_REPLY_TO)
            {
                Recipient* newRecipient = [rec recipient];
                [newRecipient setType:TYPE_TO];
                [recipientArray addObject:newRecipient];
            }

        if(recipientArray.count==0)
            for(EmailRecipient* rec in recArray)
                if(rec.type==TYPE_FROM)
                {
                    Recipient* newRecipient = [rec recipient];
                    [newRecipient setType:TYPE_TO];
                    [recipientArray addObject:newRecipient];
                }
    }

    Recipient* fromRecipient = [AddressDataHelper senderAsRecipientForReplyToOrForwardOfMessage:message];

    [recipientArray addObject:fromRecipient];

    return recipientArray;
}


+ (NSArray*)recipientsForReplyAllToMessage:(EmailMessage*)message
{
    NSData* recData = message.messageData.addressData;

    if(!recData)
        return nil;

    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:recData];
    NSArray* recArray = [unarchiver decodeObjectForKey:@"recipients"];
    [unarchiver finishDecoding];

    NSMutableArray* recipientArray = [NSMutableArray new];

    for(EmailRecipient* rec in recArray)
    {
        switch(rec.type)
        {
            case TYPE_FROM:
            {
                if([rec.email isUsersAddress])
                {
                    //[newRecipient setType:TYPE_FROM];
                }
                else
                {
                    Recipient* newRecipient = [rec recipient];
                    [newRecipient setType:TYPE_TO];
                    if(![[recipientArray valueForKey:@"email"] containsObject:rec.email])
                        [recipientArray addObject:newRecipient];
                }
                break;
            }
            case TYPE_TO:
            {
                if([rec.email isUsersAddress])
                {
                    //[newRecipient setType:TYPE_FROM];
                }
                else
                {
                    Recipient* newRecipient = [rec recipient];
                    [newRecipient setType:TYPE_TO];
                    if(![[recipientArray valueForKey:@"email"] containsObject:rec.email])
                        [recipientArray addObject:newRecipient];

                }
                break;
            }
            case TYPE_REPLY_TO:
            {
                Recipient* newRecipient = [rec recipient];
                [newRecipient setType:TYPE_TO];
                if(![[recipientArray valueForKey:@"email"] containsObject:rec.email])
                    [recipientArray addObject:newRecipient];
                break;
            }

            case TYPE_CC:
            {
                if([rec.email isUsersAddress])
                {
                    //[newRecipient setType:TYPE_FROM];
                }
                else
                {
                    Recipient* newRecipient = [rec recipient];
                    [newRecipient setType:TYPE_CC];
                    if(![[recipientArray valueForKey:@"email"] containsObject:rec.email])
                        [recipientArray addObject:newRecipient];
                }
                break;
            }
            case TYPE_BCC:
            {
                if([rec.email isUsersAddress])
                {
                    //[newRecipient setType:TYPE_FROM];
                }
                else
                {
                    Recipient* newRecipient = [rec recipient];
                    [newRecipient setType:TYPE_BCC];
                    if(![[recipientArray valueForKey:@"email"] containsObject:rec.email])
                        [recipientArray addObject:newRecipient];
                }
                break;
            }
        }
    }

    Recipient* fromRecipient = [AddressDataHelper senderAsRecipientForReplyToOrForwardOfMessage:message];

    [recipientArray addObject:fromRecipient];

    return recipientArray;
}


+ (NSArray*)recipientsForForwardOfMessage:(EmailMessage*)message
{
    NSMutableArray* recipientArray = [NSMutableArray new];

    Recipient* fromRecipient = [AddressDataHelper senderAsRecipientForReplyToOrForwardOfMessage:message];

    [recipientArray addObject:fromRecipient];

    return recipientArray;
}


#pragma mark - Sending

+ (IMAPAccount*)sendingAccountForMessage:(EmailMessage*)message
{
    NSArray* emailRecipients = [self emailRecipientsForAddressData:message.messageData.addressData];

    for(EmailRecipient* rec in emailRecipients)
    {
        if(rec.type==TYPE_FROM)
        {
            NSString* email = rec.email;

            IMAPAccountSetting* accountSetting = [IMAPAccountSetting accountSettingForSenderEmail:email];

            IMAPAccount* account = accountSetting.account;

            return account;
        }
    }

    return nil;
}

+ (IMAPAccountSetting*)sendingAccountSettingForMessage:(EmailMessage*)message
{
    NSArray* emailRecipients = [self emailRecipientsForAddressData:message.messageData.addressData];

    for(EmailRecipient* rec in emailRecipients)
    {
        if(rec.type==TYPE_FROM)
        {
            NSString* email = rec.email;

            IMAPAccountSetting* accountSetting = [IMAPAccountSetting accountSettingForSenderEmail:email];

            return accountSetting;
        }
    }
    
    return nil;
}


+ (BOOL)isValidEmailAddress:(NSString*)email
{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];

    return [emailTest evaluateWithObject:email];
}


+ (BOOL)sendableAddressContainedInEmailRecipients:(NSArray*)emailRecipients
{
    for(EmailRecipient* emailRec in emailRecipients)
    {
        if(emailRec.type==TYPE_CC || emailRec.type==TYPE_TO || emailRec.type==TYPE_BCC)
            return YES;
    }

    return NO;
}

+ (BOOL)sendableAddressContainedInRecipients:(NSArray*)recipients
{
    for(Recipient* recipient in recipients)
    {
        if(recipient.type==TYPE_CC || recipient.type==TYPE_TO || recipient.type==TYPE_BCC)
            return YES;
    }

    return NO;
}

+ (NSArray*)recipientsWithoutSenderForMessageInstance:(EmailMessageInstance*)messageInstance
{
    return [self recipientsWithoutSenderForMessage:messageInstance.message];
}

+ (NSArray*)recipientsWithoutSenderForMessage:(EmailMessage*)message
{
    NSArray* emailRecipients = [self emailRecipientsForAddressData:message.messageData.addressData];

    NSMutableArray* returnValue = [NSMutableArray new];

    for(EmailRecipient* emailRecipient in emailRecipients)
        if([emailRecipient isKindOfClass:[EmailRecipient class]])
        {
            if(emailRecipient.type==TYPE_TO || emailRecipient.type==TYPE_CC || emailRecipient.type==TYPE_BCC)
                [returnValue addObject:emailRecipient];
        }

    return returnValue;
}

+ (BOOL)shouldShowReplyToForMessage:(EmailMessage*)message
{
    NSArray* emailRecipients = [self emailRecipientsForAddressData:message.messageData.addressData];

    EmailRecipient* senderEmailRecipient;
    EmailRecipient* replyToEmailRecipient;

    for(EmailRecipient* emailRecipient in emailRecipients)
        if([emailRecipient isKindOfClass:[EmailRecipient class]])
        {
            if(emailRecipient.type==TYPE_FROM)
                senderEmailRecipient = emailRecipient;

            if(emailRecipient.type==TYPE_REPLY_TO)
                replyToEmailRecipient = emailRecipient;
        }

    if(senderEmailRecipient && replyToEmailRecipient)
        if([senderEmailRecipient.email isEqual:replyToEmailRecipient.email])
            return NO;

    return replyToEmailRecipient!=nil;
}

+ (BOOL)shouldShowReplyToForMessageInstance:(EmailMessageInstance*)messageInstance
{
    return [self shouldShowReplyToForMessage:messageInstance.message];
}



#pragma mark - User's own addresses

//checks if a given message is sent by one of the user's own email addresses
- (BOOL)messageIsSentByMe:(EmailMessage*)message
{
    if(!message)
        return NO;

    EmailRecipient* senderEmailRecipient = [AddressDataHelper senderAsEmailRecipientForMessage:message];

    return [senderEmailRecipient.email isUsersAddress];
}





@end
