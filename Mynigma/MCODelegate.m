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
#import "MCODelegate.h"
#import "EmailMessage+Category.h"
#import "FileAttachment.h"
#import "AttachmentsManager.h"
#import "NSString+EmailAddresses.h"




static MCODelegate* theInstance;

@implementation MCODelegate


+ (MCODelegate*)sharedInstance
{
    if(!theInstance)
        theInstance = [MCODelegate new];

    return theInstance;
}


/**
 The delegate method returns NULL if the delegate have not fetch the part yet. The opportunity can also be used to
 start fetching the attachment.
 It will return the data synchronously if it has already fetched it.
 */

/**CALL ON MAIN*/
- (NSData *) MCOAbstractMessage:(MCOAbstractMessage *)msg dataForIMAPPart:(MCOIMAPPart *)part folder:(NSString *)folder
{
    [ThreadHelper ensureMainThread];

    NSString* messageID = msg.header.messageID;

    EmailMessage* emailMessage = [EmailMessage findMessageWithMessageID:messageID inContext:MAIN_CONTEXT];

    if([emailMessage isKindOfClass:[EmailMessage class]])
    {
        for(FileAttachment* attachment in emailMessage.allAttachments)
        {
            if([attachment.partID isEqualToString:part.partID])
            {
                NSData* data = [attachment data];

                //disabled for now

                //don't have a session at this point
                //probably shouldn't create a new one every time...

                //anyway, it shouldn't be necessary to fetch the data at this point

//                if(!data)
//                    [attachment fetchAndDecryptWithCallback:nil];
//
                return data;
            }
        }
    }

    return nil;
}

/**
 The delegate method will notify the delegate to start fetching the given part.
 It will be used to render an attachment that cannot be previewed.
 */
- (void) MCOAbstractMessage:(MCOAbstractMessage *)msg prefetchAttachmentIMAPPart:(MCOIMAPPart *)part folder:(NSString *)folder
{

}

/**
 The delegate method will notify the delegate to start fetching the given part.
 It will be used to render an attachment that can be previewed.
 */
- (void) MCOAbstractMessage:(MCOAbstractMessage *)msg prefetchImageIMAPPart:(MCOIMAPPart *)part folder:(NSString *)folder
{

}

- (BOOL)MCOAbstractMessage:(MCOAbstractMessage *)msg shouldShowPart:(MCOAbstractPart *)part
{
    return YES;
}

- (NSString *)MCOAbstractMessage:(MCOAbstractMessage *)msg filterHTMLForPart:(NSString *)html
{

    return html;
}

- (NSString *)MCOAbstractMessage:(MCOAbstractMessage *)msg filterHTMLForMessage:(NSString *)html
{


    return html;
}

- (NSString *)MCOAbstractMessage:(MCOAbstractMessage *)msg templateForMainHeader:(MCOMessageHeader *)header {
    return @"";
}

- (NSDictionary *)MCOAbstractMessage:(MCOAbstractMessage *)msg templateValuesForHeader:(MCOMessageHeader *)header {

    return @{};
}

- (NSString *) MCOAbstractMessage:(MCOAbstractMessage *)msg templateForImage:(MCOAbstractPart *)header
{

    NSString* templateString;
    /*
     if ([[self delegate] respondsToSelector:@selector(MCOMessageView_templateForImage:)]) {
     templateString = [[self delegate] MCOMessageView_templateForImage:self];
     }
     else {
     templateString = @"<img src=\"{{URL}}\"/>";
     }
     templateString = [NSString stringWithFormat:@"<div id=\"{{CONTENTID}}\">%@</div>", templateString];*/
    return templateString;
}

- (NSString *) MCOAbstractMessage_templateForMessage:(MCOAbstractMessage *)msg;
{
    //return @"{{HEADER}}{{BODY}}";
    return @"{{BODY}}";
}



- (NSString *)MCOAbstractMessage:(MCOAbstractMessage *)msg templateForAttachment:(MCOAbstractPart *)part
{
    if([@[@"image/png", @"image/gif", @"image/jpg", @"image/jpeg"] containsObject:[[part mimeType] lowercaseString]])
    {
        NSString* messageID = msg.header.messageID;


        EmailMessage* emailMessage = [EmailMessage findMessageWithMessageID:messageID inContext:MAIN_CONTEXT];

        if([emailMessage isKindOfClass:[EmailMessage class]])
        {
            for(FileAttachment* attachment in emailMessage.allAttachments)
            {
                if([attachment.uniqueID isEqual:part.uniqueID])
                {
                    NSString* contentID = attachment.contentid;

                    if(!contentID)
                    {
                        contentID = [@"generic@mynigma.org" generateMessageID];
                        [attachment setContentid:contentID];
                    }

                    return [NSString stringWithFormat:@"<img src='cid:%@'>", contentID];
                }
            }
        }
        return [NSString stringWithFormat:@"<img src=\"\">"];
    }
    return @"";
}

- (NSString *)MCOAbstractMessage_templateForAttachmentSeparator:(MCOAbstractMessage *)msg
{
    return @"";
}

- (NSDictionary *)MCOAbstractMessage:(MCOAbstractMessage *)msg templateValuesForPart:(MCOAbstractPart *)part
{
    return @{};
}


#pragma mark - Localized error reporting

+ (NSString*)reasonForError:(NSError*)error
{
    if(!error)
        return NSLocalizedString(@"No error information",@"MailCore Error");
    switch(error.code)
    {
        case MCOErrorNone:
            return NSLocalizedString(@"No error information",@"MailCore Error");
        case MCOErrorConnection:
            return NSLocalizedString(@"Connection error",@"MailCore Error");
        case MCOErrorTLSNotAvailable:
            return NSLocalizedString(@"TLS not available",@"MailCore Error");
        case MCOErrorParse:
            return NSLocalizedString(@"Parse error",@"MailCore Error");
        case MCOErrorCertificate:
            return NSLocalizedString(@"Certificate error",@"MailCore Error");
        case MCOErrorAuthentication:
            return NSLocalizedString(@"Authentication error",@"MailCore Error");
        case MCOErrorGmailIMAPNotEnabled:
            return NSLocalizedString(@"IMAP not enabled",@"MailCore Error");
        case MCOErrorGmailExceededBandwidthLimit:
            return NSLocalizedString(@"Bandwidth limit exceeded",@"MailCore Error");
        case MCOErrorGmailTooManySimultaneousConnections:
            return NSLocalizedString(@"Too many connections",@"MailCore Error");
        case MCOErrorMobileMeMoved:
            return NSLocalizedString(@"Mobile me moved",@"MailCore Error");
        case MCOErrorYahooUnavailable:
            return NSLocalizedString(@"Yahoo unavailable",@"MailCore Error");
        case MCOErrorNonExistantFolder:
            return NSLocalizedString(@"Folder does not exist",@"MailCore Error");
        case MCOErrorRename:
            return NSLocalizedString(@"Rename error",@"MailCore Error");
        case MCOErrorDelete:
            return NSLocalizedString(@"Delete error",@"MailCore Error");
        case MCOErrorCreate:
            return NSLocalizedString(@"Create error",@"MailCore Error");
        case MCOErrorSubscribe:
            return NSLocalizedString(@"Subscribe error",@"MailCore Error");
        case MCOErrorAppend:
            return NSLocalizedString(@"Append error",@"MailCore Error");
        case MCOErrorCopy:
            return NSLocalizedString(@"Copy error",@"MailCore Error");
        case MCOErrorExpunge:
            return NSLocalizedString(@"Expunge error",@"MailCore Error");
        case MCOErrorFetch:
            return NSLocalizedString(@"Fetch error",@"MailCore Error");
        case MCOErrorIdle:
            return NSLocalizedString(@"Idle error",@"MailCore Error");
        case MCOErrorIdentity:
            return NSLocalizedString(@"Identity error",@"MailCore Error");
        case MCOErrorNamespace:
            return NSLocalizedString(@"Namespace error",@"MailCore Error");
        case MCOErrorStore:
            return NSLocalizedString(@"Store error",@"MailCore Error");
        case MCOErrorCapability:
            return NSLocalizedString(@"Capability error",@"MailCore Error");
        case MCOErrorStartTLSNotAvailable:
            return NSLocalizedString(@"StartTLS not available",@"MailCore Error");
        case MCOErrorSendMessageIllegalAttachment:
            return NSLocalizedString(@"Illegal attachment",@"MailCore Error");
        case MCOErrorStorageLimit:
            return NSLocalizedString(@"Storage limit",@"MailCore Error");
        case MCOErrorSendMessageNotAllowed:
            return NSLocalizedString(@"Send message not allowed",@"MailCore Error");
        case MCOErrorAuthenticationRequired:
            return NSLocalizedString(@"Authentication required",@"MailCore Error");
        case MCOErrorFetchMessageList:
            return NSLocalizedString(@"Fetch message list error",@"MailCore Error");
        case MCOErrorDeleteMessage:
            return NSLocalizedString(@"Delete message error",@"MailCore Error");
        case MCOErrorInvalidAccount:
            return NSLocalizedString(@"Invalid account",@"MailCore Error");
        default: return NSLocalizedString(@"Unkown error",@"MailCore Error");
    }
}



@end
