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





#import "MynigmaMessage+Category.h"
#import "AppDelegate.h"
#import "FileAttachment+Category.h"
#import "MynigmaDeclaration.h"
#import "EncryptionHelper.h"
#import "IMAPAccount.h"
#import "EmailMessage+Category.h"
#import "IMAPAccountSetting+Category.h"
#import "AddressDataHelper.h"
#import "PublicKeyManager.h"
#import "EmailMessageData.h"
#import "EmailRecipient.h"
#import "EmailContactDetail+Category.h"
#import "MynigmaPrivateKey+Category.h"
#import "AddressDataHelper.h"
#import "PublicKeyManager.h"
#import "EncryptionHelper.h"
#import "MynigmaPublicKey+Category.h"
#import "EmailMessageController.h"
#import "EmailMessageInstance+Category.h"
#import "MynigmaFeedback.h"
#import "SelectionAndFilterHelper.h"
#import "IMAPFolderSetting+Category.h"
#import "FetchAttachmentOperation.h"
#import "NSString+EmailAddresses.h"
#import "EncryptedMessage.h"
#import "Recipient.h"







@implementation MynigmaMessage (Category)


#pragma mark - Status

- (BOOL)isDownloaded
{
    //need the second condition for drafts
    return ([self mynData].length>0) || [self.messageData htmlBody];
}

- (BOOL)isDecrypted
{
    return [[self messageData] htmlBody]!=nil;
}

- (BOOL)isSafe
{
    return YES;
}

- (BOOL)canBeDecrypted
{
    BOOL result = [self isDownloaded] && ![self isDecrypted] && ![self isDecrypting];

    //sanity check
    if(result && [[self mynData] length]==0)
        NSLog(@"Downloaded Mynigma attachment has no data to be decrypted!!");

    return result;
}







- (void)attemptDecryptionInContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    __block NSManagedObjectID* messageObjectID = self.objectID;

    if([self isDecrypting])
        return;

    if([self canBeDecrypted] && ![self isDecrypted])
    {
        [self setIsDecrypting:YES];

        [EncryptionHelper asyncDecryptMessage:messageObjectID fromData:self.mynData withCallback:^(MynigmaFeedback* decryptionError){

            [ThreadHelper runAsyncOnMain:^{

                //decryptionStatus is either the string @"OK", indicating no error
                //or the code of the error, in the form of a string
                NSString* decryptionStatus = decryptionError.archivableString;

                [self setDecryptionStatus:decryptionStatus];

                [self setIsDecrypting:NO];

                [SelectionAndFilterHelper refreshMessage:messageObjectID];

                MynigmaMessage* thisMessageOnMain = (MynigmaMessage*)[MAIN_CONTEXT existingObjectWithID:messageObjectID error:nil];

                if(![thisMessageOnMain isKindOfClass:[MynigmaMessage class]])
                {
                    NSLog(@"Error: decrypted message cannot be reconstructed!!!");
                    return;
                }

                [SelectionAndFilterHelper refreshViewerShowingMessage:thisMessageOnMain];

                for(FileAttachment* attachment in thisMessageOnMain.allAttachments)
                {
                    [attachment urgentlyDownloadWithCallback:^(NSData *data) {

                        [ThreadHelper runAsyncOnMain:^{

                            [SelectionAndFilterHelper refreshViewerShowingMessage:attachment.attachedAllToMessage];
                        }];

                    }];
                }
            }];
        }];
    }
    else
    {
        for(FileAttachment* attachment in self.allAttachments)
        {
            if([attachment canBeDecrypted])
            {
                [attachment setIsDecrypting:YES];

                NSManagedObjectID* attachmentObjectID = attachment.objectID;

                [EncryptionHelper asyncDecryptFileAttachment:attachmentObjectID withCallback:[^(NSData *data, NSString *result) {

                    [ThreadHelper runAsyncOnMain:^{

                        FileAttachment* attachmentOnMain = (FileAttachment*)[MAIN_CONTEXT existingObjectWithID:attachmentObjectID error:nil];

                        [attachmentOnMain setIsDecrypting:NO];

                        [SelectionAndFilterHelper refreshAttachment:attachmentOnMain];

                    }];

                } copy]];
            }
        }
    }
}


- (EmailMessage*)turnIntoOpenMessageInContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    NSEntityDescription* entity = [NSEntityDescription entityForName:@"EmailMessage" inManagedObjectContext:localContext];
    EmailMessage* openMessage = [[EmailMessage alloc] initWithEntity:entity insertIntoManagedObjectContext:localContext];

    [openMessage setMessageData:self.messageData];
    [openMessage setInstances:self.instances];

    [self setMessageData:nil];
    [self setInstances:nil];

    [openMessage setAllAttachments:self.allAttachments];
    [openMessage setAttachments:self.attachments];

    [self setAllAttachments:nil];
    [self setAttachments:nil];

    [openMessage setDateSent:self.dateSent];
    [openMessage setEmails:self.emails];

    [self setEmails:nil];

    [openMessage setIsCleaning:NO];
    [openMessage setIsDecrypting:NO];
    [openMessage setIsDownloading:NO];

    [openMessage setSearchString:self.searchString];

    //create a fresh messageID
    [openMessage setMessageid:[@"safeToOpen@mynigma.org" generateMessageID]];

    //now need to update the allMessages dictionary in MODEL to point to the new, open message(!)
    [localContext obtainPermanentIDsForObjects:@[openMessage] error:nil];

    [self removeMessageFromAllMessagesDict];

    [localContext deleteObject:self];

    [openMessage includeInAllMessagesDictInContext:localContext];

    return openMessage;
}

- (void)encryptAsDraftWithCallback:(void(^)(MynigmaFeedback* feedback))callback
{
    [ThreadHelper ensureMainThread];

    [self encryptAsDraftInContext:MAIN_CONTEXT withCallback:callback];
}

- (void)encryptAsDraftInContext:(NSManagedObjectContext*)localContext withCallback:(void(^)(MynigmaFeedback* feedback))callback
{
    [ThreadHelper ensureLocalThread:localContext];

    NSString* privateKeyLabel = [MynigmaPrivateKey senderKeyLabelForMessage:self];

    if(!privateKeyLabel)
    {
        NSLog(@"No current key pair - cannot save message!!");
        if(callback)
            callback([MynigmaFeedback feedback:MynigmaEncryptionErrorNoCurrentPrivateKeyLabel]);
        return;
    }

    //create the encrypted data and put it into mynMessage.mynData - also encrypt each attachment with the same session key and put the latter into mynMessage.sessionKey
    NSError* error = nil;

    [localContext save:&error];
    if(error)
    {
        NSLog(@"Error saving local object context before encrypting message!! %@", error);
        if(callback)
            callback([MynigmaFeedback feedback:MynigmaEncryptionErrorSavingContext]);
        return;
    }

    [CoreDataHelper save];

    [localContext obtainPermanentIDsForObjects:@[self] error:&error];

    if(error)
    {
        NSLog(@"Error obtaining permanent ID for message object prior to encryption!!! %@", self);
        if(callback)
            callback([MynigmaFeedback feedback:MynigmaEncryptionErrorObtainingPermanentObjectID]);
        return;
    }

    [EncryptionHelper asyncEncryptMessage:self.objectID withSignatureKeyLabel:privateKeyLabel expectedSignatureKeyLabels:@[] encryptionKeyLabels:@[] andCallback:^(MynigmaFeedback* feedback)
    {
        [localContext performBlock:^{

            if(callback)
                callback(feedback);
        }];
    }];
}




- (void)encryptForSendingWithCallback:(void(^)(MynigmaFeedback* feedback))callback
{
    [ThreadHelper ensureMainThread];
    [self encryptForSendingInContext:MAIN_CONTEXT withCallback:callback];
}


- (void)encryptForSendingInContext:(NSManagedObjectContext*)localContext withCallback:(void(^)(MynigmaFeedback* feedback))callback
{
    [ThreadHelper ensureLocalThread:localContext];

    NSString* privateKeyLabel = [MynigmaPrivateKey senderKeyLabelForMessage:self];

    if(!privateKeyLabel)
    {
        NSLog(@"No current key pair - cannot save message!!");
        if(callback)
            callback([MynigmaFeedback feedback:MynigmaEncryptionErrorNoCurrentPrivateKeyLabel]);
        return;
    }

    NSArray* emailRecipients = [AddressDataHelper emailRecipientsForAddressData:self.messageData.addressData];

    NSArray* encryptionKeyLabels = [MynigmaPublicKey encryptionKeyLabelsForRecipients:emailRecipients allowErrors:NO];

    if(!encryptionKeyLabels)
    {
        NSLog(@"Failed to find public keys for recipients!!!");
        if(callback)
            callback([MynigmaFeedback feedback:MynigmaEncryptionErrorNoPublicKeyLabels]);
        return;
    }

    NSArray* expectedSignatureKeyLabels = [MynigmaPublicKey introductionOriginKeyLabelsForRecipients:emailRecipients allowErrors:NO];

    if(!expectedSignatureKeyLabels)
    {
        NSLog(@"Failed to find public keys for recipients!!!");
        if(callback)
            callback([MynigmaFeedback feedback:MynigmaEncryptionErrorNoExpectedPublicKeyLabels]);
        return;
    }


    //create the encrypted data and put it into mynMessage.mynData - also encrypt each attachment with the same session key and put the latter into mynMessage.sessionKey
    NSError* error = nil;

    [localContext save:&error];
    if(error)
    {
        NSLog(@"Error saving local object context before encrypting message!! %@", error);
        if(callback)
            callback([MynigmaFeedback feedback:MynigmaEncryptionErrorSavingContext]);
        return;
    }

    [CoreDataHelper save];

    [localContext obtainPermanentIDsForObjects:@[self] error:&error];

    if(error)
    {
        NSLog(@"Error obtaining permanent ID for message object prior to encryption!!! %@", self);
        if(callback)
            callback([MynigmaFeedback feedback:MynigmaEncryptionErrorObtainingPermanentObjectID]);
        return;
    }

    [EncryptionHelper asyncEncryptMessage:self.objectID withSignatureKeyLabel:privateKeyLabel expectedSignatureKeyLabels:expectedSignatureKeyLabels encryptionKeyLabels:encryptionKeyLabels andCallback:^(MynigmaFeedback* mynigmaFeedback)
    {
        if(callback)
            callback(mynigmaFeedback);
    }];
}


- (MynigmaFeedback*)decryptionError
{
    NSString* decryptionStatus = [self decryptionStatus];

    if(!decryptionStatus || [decryptionStatus isEqualToString:@"OK"])
    {
        return nil;
    }

    NSInteger errorCode = decryptionStatus.integerValue;

    MynigmaFeedback* error = [MynigmaFeedback feedback:errorCode message:self];

    return error;
}





- (void)downloadUsingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation*)disconnectOperation urgent:(BOOL)urgent alsoDownloadAttachments:(BOOL)withAttachments
{
    [ThreadHelper ensureMainThread];

    //don't need to download a message that has already been downloaded
    if([self isDownloaded])
    {
        //the message is downloaded, but it's a MynigmaMessage, so we might need to decrypt it...
        [(MynigmaMessage*)self attemptDecryptionInContext:MAIN_CONTEXT];
        return;
    }

    //if it's already downloading, don't bother doing anything...
    if([self isDownloading])
        return;


    //first find an instance of the message that can be downloaded from the IMAP server
    EmailMessageInstance* messageInstance = [self downloadableInstance];

    if(!messageInstance)
    {
        NSLog(@"Cannot download message without a suitable instance! %@", self);
        return;
    }

    IMAPAccount* account = messageInstance.account;

    //for a MynigmaMessage don't bother fetching the body - it's always the same and won't be displayed anyway. fetch the mynData instead...
    if(![self mynDataPartID])
    {
        NSLog(@"No myn data part ID!!! Message: %@", self);
        return;
    }

    if(urgent)
    {
        session = account.quickAccessSession;
        disconnectOperation = nil;
    }

    if (!session)
    {
        NSLog(@"Uh Ah no session");
        return;
    }

    [self setIsDownloading:YES];

    NSString* path = messageInstance.folderSetting.path;

    FetchAttachmentOperation* operation = [FetchAttachmentOperation fetchMessageAttachmentByUIDWithFolder:path uid:messageInstance.uid.unsignedIntValue partID:[self mynDataPartID] encoding:MCOEncodingBase64 urgent:YES session:session withProgressBlock:nil withCallback:^(NSError *error, NSData *partData){

        [self setIsDownloading:NO];

        if(partData.length>0 && !error)
        {
            [self setMynData:partData];
            [SelectionAndFilterHelper refreshMessage:self.objectID];

            [self attemptDecryptionInContext:MAIN_CONTEXT];
        }
        else
        {
            NSLog(@"Error downloading myn data! %@", error);
            [SelectionAndFilterHelper refreshMessage:self.objectID];
        }
    }];

    if(urgent)
        [operation setHighPriority];
    else
        [operation setLowPriority];

    if(urgent)
        [operation addToUserActionQueue];
    else
    {
        if(![operation addToMailCoreQueueWithDisconnectOperation:disconnectOperation])
        {
            //if the session is invalid, adding the operation to the queue will fail
            //ensure the message isn't caught in an infinite donwloading oepration
            [self setIsDownloading:NO];
        }
    }

    if(withAttachments)
    {
        for(FileAttachment* attachment in self.allAttachments)
        {
            [attachment downloadUsingSession:session disconnectOperation:disconnectOperation urgent:urgent withCallback:nil];
        }
    }
}



#pragma mark - Sending

- (NSError*)wrapIntoMessageBuilder:(MCOMessageBuilder*)messageBuilder
{
    // Mynigma icon as inline attachment
    NSString* logoPath = [[NSBundle mainBundle] pathForResource:@"MynigmaIconForLetter" ofType:@"jpg"];
    NSData* logoData = [NSData dataWithContentsOfFile:logoPath];

    MCOAttachment* logoAttachment = [MCOAttachment attachmentWithData:logoData filename:@"MynigmaIconForLetter.jpg"];
    [logoAttachment setInlineAttachment:YES];
    [logoAttachment setContentID:@"TXluaWdtYUljb25Gb3JMZXR0ZXI@mynigma.org"];
    if(logoAttachment)
        [messageBuilder addRelatedAttachment:logoAttachment];

    Recipient* senderRecipient = [AddressDataHelper senderAsRecipientForMessage:self addIfNotFound:YES];

    //Subject
    NSString* subjectString = [NSString stringWithFormat:NSLocalizedString(@"Safe message from %@",@"Safe msg subject <sender name>"),senderRecipient.displayName];

    NSURL* mynigmaMessageURL = [BUNDLE URLForResource:@"MynigmaMessage" withExtension:@"html"];

    NSString* formatString = [NSString stringWithContentsOfURL:mynigmaMessageURL encoding:NSUTF8StringEncoding error:nil];

    if(!formatString)
        formatString = @"<html><head><meta http-equiv='Content-Type' content='text/html;charset=utf-8'><title>Mynigma Message</title></head><body><div style='background:#EDEDED;background-color:#EDEDED;padding:0px;width:100%%;' align='center' width='100%%'><table border='0' cellpadding='5px' cellspacing='0px' style='font-family: Segoe UI,Arial,Helvetica,sans-serif,Calibri;' width='550px'><tbody><tr><td align='center' style='background:#EDEDED;background-color:#EDEDED;text-align:center;font-size:12px;color:#808080;width:550px;'><br/><br/></td></tr><tr><td style='background: #FFFFFF; background-color: #FFFFFF; padding: 60px; padding-top:30px; padding-bottom:30px;font-size:16px;color:#155891;' width='550px'><div style='text-align:center;'><img src='cid:TXluaWdtYUljb25Gb3JMZXR0ZXI@mynigma.org' width='100px' height='100px' alt='Mynigma'></div><p style='font-size: 30px; text-align:center'>This is a safe message from</p><hr style='border:0; color:#155891;background-color:#155891; height:1px; width:60%%;' /><p style='font-size:20px; text-align:center'>%@ (%@)</p><hr style='border:0; color:#155891;background-color:#155891; height:1px; width:60%%;' /><br /><p style='text-align:center;'>To read simply launch Mynigma or open 'Secure&nbsp;message.myn'</p></td><tr><td colspan='4'style='background:#EDEDED;font-size:12px;color:#808080;' width='500px' align='center'><p>Not yet installed Mynigma on this device? <a href='https://mynigma.org/download.html?p=safeEmail' style='color:#808080;text-decoration:underline;'>Get it at mynigma.org</a></p><br/></td></tr></tbody></table><div></body></html>";

    NSString* emailString = [senderRecipient.displayEmail.lowercaseString isEqual:senderRecipient.displayName.lowercaseString]?@"":senderRecipient.displayEmail;

    if(!emailString)
        emailString = @"";

    NSString* bodyString = [NSString stringWithFormat:formatString,senderRecipient.displayName?senderRecipient.displayName:@"", emailString, self.messageid, self.messageid];

    [[messageBuilder header] setExtraHeaderValue:@"Mynigma Safe Email" forName:@"X-Mynigma-Safe-Message"];

    [[messageBuilder header] setSubject:subjectString];
    [messageBuilder setHTMLBody:bodyString];

    MCOAddress* fromAddress = nil;

    NSData* recData = self.messageData.addressData;

    NSArray* recArray = [AddressDataHelper emailRecipientsForAddressData:recData];

    MCOAddress* replyToAddress = nil;
    NSMutableArray* toAddresses = [NSMutableArray new];
    NSMutableArray* ccAddresses = [NSMutableArray new];
    NSMutableArray* bccAddresses = [NSMutableArray new];

    for(EmailRecipient* rec in recArray)
    {
        MCOAddress* newAddress = [MCOAddress addressWithDisplayName:rec.name mailbox:rec.email];
        switch(rec.type)
        {
            case TYPE_FROM:
                fromAddress = newAddress;
                break;
            case TYPE_REPLY_TO:
                replyToAddress = newAddress;
                break;
            case TYPE_TO:
                [toAddresses addObject:newAddress];
                break;
            case TYPE_CC:
                [ccAddresses addObject:newAddress];
                break;
            case TYPE_BCC:
                [bccAddresses addObject:newAddress];
                break;
            default:{}
        }
    }

    if(!fromAddress)
    {
        NSLog(@"No from address set!!!");
        return nil;
    }

    [[messageBuilder header] setFrom:fromAddress];
    [[messageBuilder header] setTo:toAddresses];
    if(replyToAddress)
        [[messageBuilder header] setReplyTo:@[replyToAddress]];
    else
        [[messageBuilder header] setReplyTo:@[fromAddress]];
    [[messageBuilder header] setCc:ccAddresses];
    [[messageBuilder header] setBcc:bccAddresses];

    MCOAttachment* attachment = [MCOAttachment attachmentWithData:self.mynData filename:@"Secure message.myn"];

    [attachment setMimeType:@"application/mynigma"];
    [attachment setInlineAttachment:NO];

    [messageBuilder addAttachment:attachment];

    if(!self.mynData.length)
    {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"Failed to wrap encrypted message", nil), NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"No myn data set(!!)", nil), NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"Please submit a bug report so we can fix the problem for you.", nil)};

        NSError* error = [NSError errorWithDomain:@"EmailMessage wrap for sending" code:2 userInfo:userInfo];

        return error;
    }

    NSInteger index = 0;
    for(FileAttachment* fileAttachment in self.allAttachments)
    {
        index++;
        
        NSData* encryptedData = [fileAttachment encryptedData];
        
        if(encryptedData)
        {
            MCOAttachment* att = [MCOAttachment attachmentWithData:encryptedData filename:[NSString stringWithFormat:@"%ld.myn",(long)index]];
            [att setMimeType:@"application/mynigma"];
            
            //whether or not the attachment is inline is decided after decryption - the encrypted attachments are never inline(!)
            [att setInlineAttachment:NO];
            if(fileAttachment.contentid)
                [att setContentID:fileAttachment.contentid];
            else
            {
                //this should never happen: a content id is generated during encryption, if necessary...
                NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"Failed to wrap encrypted message", nil), NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"Attachment lacks contentID(!)", nil), NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"Please submit a bug report so we can fix the problem for you.", nil)};

                NSError* error = [NSError errorWithDomain:@"EmailMessage wrap for sending" code:3 userInfo:userInfo];
                
                return error;
            }
            
            if(att)
            {
                [messageBuilder addAttachment:att];
            }
        }
        else
        {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"Failed to wrap encrypted message", nil), NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"Attachment lacks data(!)", nil), NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"Please submit a bug report so we can fix the problem for you.", nil)};

            NSError* error = [NSError errorWithDomain:@"EmailMessage wrap for sending" code:3 userInfo:userInfo];

            return error;
        }
    }

    //no error
    return nil;
}





@end
