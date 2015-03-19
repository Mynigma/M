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





#import "FormattingHelper.h"
#import "EmailFooter.h"
#import "EmailMessageInstance+Category.h"
#import "AppDelegate.h"
#import "EmailMessage+Category.h"
#import "IMAPAccountSetting+Category.h"
#import "IMAPFolderSetting+Category.h"
#import "UserSettings.h"
#import "EmailMessageData.h"
#import "AddressDataHelper.h"
#import "Recipient.h"
#import "EmailRecipient.h"
#import <MailCore/MailCore.h>
#import "OutlineObject.h"
#import "EncryptionHelper.h"
#import "MynigmaMessage+Category.h"
#import "PublicKeyManager.h"
#import "FileAttachment+Category.h"
#import "FileAttachment.h"
#import "AppleEncryptionWrapper.h"
#import "SelectionAndFilterHelper.h"
#import "UserSettings+Category.h"




#if TARGET_OS_IPHONE

#else

#import <WebKit/WebKit.h>

#endif

@implementation FormattingHelper

+ (NSString*)trimLeadingWhitespaces:(NSString*)originalString
{
    NSInteger i = 0;

    NSMutableCharacterSet* charSet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [charSet addCharactersInString:@":"];

    while ((i < [originalString length])
           && [charSet characterIsMember:[originalString characterAtIndex:i]]) {
        i++;
    }
    return [originalString substringFromIndex:i];
}

+ (NSString*)stripReReRes:(NSString*)subjectString
{
    NSString* string = [self trimLeadingWhitespaces:subjectString];
    NSArray* toBeStripped = @[@"Re:",@"Fw:",@"RE:",@"FW:",@"re:",@"fw:",@"Aw:",@"AW:"];
    while(string.length>=3 && [toBeStripped containsObject:[string substringToIndex:3]])
    {
        if(string.length==3)
            string = @"";
        else
            string = [self trimLeadingWhitespaces:[string substringFromIndex:3]];
    }
    return string;
}

+ (NSString*)addBlockquoteCSSStylesheetToHTML:(NSString*)HTMLString
{
    NSURL* CSSFileURL = [[NSBundle mainBundle] URLForResource:@"style" withExtension:@"css"];

#if TARGET_OS_IPHONE

    CSSFileURL = [[NSBundle mainBundle] URLForResource:@"style_iOS" withExtension:@"css"];

#endif

    NSString* fileURLString = [CSSFileURL absoluteString];
    return [NSString stringWithFormat:@"<link href=\"%@\" rel=\"stylesheet\" type=\"text/css\" />%@", fileURLString, HTMLString];
}


+ (NSString*)addFooter:(EmailFooter*)footer toHTMLEmail:(NSString*)htmlEmail
{
    // See changeHTMLEmail:toFooter:
    return htmlEmail;
}

+ (NSString*)emptyEmailWithFooter:(EmailFooter*)footer
{
    if (footer.htmlContent)
        return [NSString stringWithFormat:@"<br><br><br><div id=\"mynFooter\">%@</div>", footer.htmlContent];
    else
        return @"<div id=\"mynFooter\"></div>";
}

+ (NSString*)invitationEmailToRecipients:(NSArray*)recipients fromSender:(EmailRecipient*)sender withFooter:(EmailFooter*)footer style:(NSString *)styleString
{
    // string format parameters for the invitation template:
    //
    // 1 - p (campaign name)
    //
    // 2 - t (tracking parameter)
    //
    // 3 - from name
    //
    // 4 - to name
    //
    // 5 - from email address
    //
    // 6 - date

    NSString* firstParameter = @"ai";

    if([styleString isEqual:@"conciseStyle"])
        firstParameter = [firstParameter stringByAppendingString:@"1"];

    if([styleString isEqual:@"normalStyle"])
        firstParameter = [firstParameter stringByAppendingString:@"2"];

    if([styleString isEqual:@"emptyStyle"])
        firstParameter = [firstParameter stringByAppendingString:@"3"];

    if([styleString isEqual:@"twitterStyle"])
        firstParameter = [firstParameter stringByAppendingString:@"4"];

    if([styleString isEqual:@"buzzfeedStyle"])
        firstParameter = [firstParameter stringByAppendingString:@"5"];

    if([styleString isEqual:@"tooSecureStyle"])
        firstParameter = [firstParameter stringByAppendingString:@"6"];



    NSString* fourthParameter = recipients.count==1?[(Recipient*)recipients[0] displayName]:NSLocalizedString(@"friends", @"Invitation recipient name");

    NSString* thirdParameter = sender.name;

    NSString* secondParameter = [NSString stringWithFormat:@"%@%ld%ld", [AppleEncryptionWrapper nonUniqueIDForEmailAddress:sender.email], (unsigned long)recipients.count, (long)round([[NSDate date] timeIntervalSince1970])];

    NSString* fifthParameter = sender.email;

    NSString* sixthParameter = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                                             dateStyle:NSDateFormatterShortStyle
                                                                             timeStyle:NSDateFormatterShortStyle];;

    NSURL* invitationEmailURL = [BUNDLE URLForResource:styleString withExtension:@"html"];

    

    NSString* invitationTemplate = [NSString stringWithContentsOfURL:invitationEmailURL encoding:NSUTF8StringEncoding error:nil];

    //fallback
//    if(!invitationHTML)
//        invitationHTML = [NSString stringWithFormat:NSLocalizedString(@"Hi %@,<br><br>Did you know that emails are as open as postcards? Their content ends up on the internet and who knows what might happen to it?<br><br>Fortunately, there is an easy solution: I am using Mynigma, an email client that makes secure encryption automatic. Because the creators believe that there is no democracy without privacy, they have made it completely free for personal use.<br><br>If you <a href=\"https://mynigma.org/invite.html?p=%1$@_f&t=%2$@\">download it now</a> and we will be able to exchange safe messages straightaway.<br><br>Best wishes,<br><br>%@", nil), emailRecipient.displayString, sender.displayString];
//    else
//    {
//        invitationHTML = [NSString stringWithFormat:[invitationHTML copy], logoBase64String?logoBase64String:@"", emailRecipient.displayString?emailRecipient.displayString:@"", sender.displayString?sender.displayString:@""];
//    }

    if(!invitationTemplate)
        invitationTemplate = @"";

    NSString* invitationHTML = [NSString stringWithFormat:invitationTemplate, firstParameter, secondParameter, thirdParameter, fourthParameter, fifthParameter, sixthParameter];

    //don't use a footer in invitation emails
    return invitationHTML;
}


+ (void)changeHTMLEmail:(DOMDocument*)htmlEmail toFooter:(EmailFooter*)footer
{

#if TARGET_OS_IPHONE


#else

    // get the mynFooter
    DOMHTMLElement* oldFooter = (DOMHTMLElement*)[htmlEmail getElementById:@"mynFooter"];
    
    if (footer.htmlContent)
    {
        if (oldFooter)
        {
            // exchange the HTML content
            NSString* content = [NSString stringWithFormat:@"%@", footer.htmlContent];
            [oldFooter setInnerHTML:content];
        }
        else
        {
            // set a new footer
            DOMHTMLElement* newFooter = (DOMHTMLElement*)[htmlEmail createElement:@"div"];
            // give it an id attribute
            [newFooter setAttribute:@"id" value:@"mynFooter"];
            // set the footer content
            NSString* content = [NSString stringWithFormat:@"%@", footer.htmlContent];
            [newFooter setInnerHTML:content];
            // append the footer eof
            //DOMNode* currentFirstNode = htmlEmail.body.firstChild;
//            if(currentFirstNode)
//                [[htmlEmail body] insertBefore:currentFirstNode refChild:newFooter];
//            else
                [[htmlEmail body] appendChild:newFooter];
        }
    }
    else
    {
        if (oldFooter)
        {
            // set empty HTML content, but leave the footer in place
            NSString* emptyContent = @"";
            [oldFooter setInnerHTML:emptyContent];
        }
        else
        {
            return;
        }
    }
    return;

#endif
    
}

/**CALL ON MAIN*/
+ (EmailMessageInstance*)replyToMessageInstance:(EmailMessageInstance*)messageInstance
{
    [ThreadHelper ensureMainThread];

    return [self replyToMessageInstance:messageInstance inContext:MAIN_CONTEXT];
}

+ (EmailMessageInstance*)replyToMessageInstance:(EmailMessageInstance*)messageInstance inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureMainThread];

    return [self replyToMessage:messageInstance.message withAccountSetting:messageInstance.accountSetting inContext:localContext];
}

+ (EmailMessageInstance*)replyToMessage:(EmailMessage*)message
{
    return [self replyToMessage:message withAccountSetting:nil inContext:MAIN_CONTEXT];
}

+ (EmailMessageInstance*)replyToMessage:(EmailMessage*)message withAccountSetting:(IMAPAccountSetting*)accountSetting inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    if(!accountSetting)
        accountSetting = [AddressDataHelper senderAccountSetting];

    IMAPFolderSetting* draftsFolder = accountSetting.draftsFolder;

    if(!draftsFolder)
    {
        draftsFolder = [UserSettings currentUserSettingsInContext:localContext].preferredAccount.draftsFolder;
    }

    if(!draftsFolder)
    {
        NSLog(@"There is no drafts folder!!");
        return nil;
    }
    EmailMessage* newMessage = [EmailMessage newDraftMessageInContext:localContext];

    [newMessage setDateSent:[NSDate date]];

    EmailMessageInstance* newMessageInstance = [EmailMessageInstance findOrMakeNewInstanceForMessage:newMessage inFolder:draftsFolder inContext:localContext];

    [newMessageInstance setFlags:@(MCOMessageFlagSeen|MCOMessageFlagDraft)];
    [newMessageInstance setAddedToFolder:newMessageInstance.inFolder];
    [newMessageInstance changeUID:nil];

    NSString* oldSubject = message.messageData.subject?message.messageData.subject:@"";

    NSString* subject = [NSString stringWithFormat:NSLocalizedString(@"Re: %@", @"Email reply subject"), [FormattingHelper stripReReRes:oldSubject]];


    [newMessage.messageData setSubject:subject];

    NSString* dateString = [NSDateFormatter localizedStringFromDate:message.dateSent dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle];

    NSString* timeString = [NSDateFormatter localizedStringFromDate:message.dateSent dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];

    // don't put attachments in replies - why?
    // inline images should be ok
    
    NSSet* allAttachments = message.allAttachments;
    
    for (FileAttachment* attachment in allAttachments)
    {
        if ([attachment isInline])
        {
            FileAttachment* newAttachment = [attachment copyInContext:localContext];
            [newAttachment setAttachedAllToMessage:newMessage];
            [newAttachment setAttachedToMessage:nil];
            [newMessage addAllAttachmentsObject:newAttachment];
        }
        else
        {
            // leave a information about left out attachements,
            // like <important.pdf> <lameSignature.as7> <trojanHorse.virus> ?
            // should go between blockquotes
        }
    }
    

    NSArray* recipientArray = [AddressDataHelper recipientsForReplyToMessage:message];

//    //add the "from" sender
//
//    EmailRecipient* emailRec = [AddressDataHelper senderAsEmailRecipientForMessage:messageInstance.message];
//
//    if(!emailRec)
//        emailRec = [AddressDataHelper standardSenderAsEmailRecipient];
//
//    Recipient* rec = [[Recipient alloc] initWithEmail:emailRec.email andName:emailRec.name];
//
//    recipientArray = [recipientArray arrayByAddingObject:rec];

    NSData* addressData = [AddressDataHelper addressDataForRecipients:recipientArray];

    [newMessage.messageData setAddressData:addressData];

    NSMutableString* forwardBody = [NSMutableString new];

    if(accountSetting.footer.htmlContent.length>0)
    {
        [forwardBody appendFormat:@"<br><br><br><div id=\"mynFooter\">%@</div>", accountSetting.footer.htmlContent];
    }
    else
    {
        [forwardBody appendFormat:@"<br><br><div id=\"mynFooter\"></div>"];
    }

    [forwardBody appendFormat:NSLocalizedString(@"<br>On %@ at %@ %@ wrote:<br>", @"<Date><fromName> reply"), dateString, timeString, message.messageData.fromName];

    NSString* htmlBody = message.messageData.htmlBody;
    if(htmlBody && htmlBody.length>0)
    {
        NSString* quotedBody = [NSString stringWithFormat:@"<blockquote type=\"cite\">%@</blockquote>",htmlBody];
        [forwardBody appendString:quotedBody];
    }
    else
        [forwardBody appendString:message.messageData.body?message.messageData.body:@""];

    htmlBody = forwardBody;

    [newMessage.messageData setHtmlBody:htmlBody];

    if([newMessage isKindOfClass:[MynigmaMessage class]])
        [(MynigmaMessage*)newMessage encryptAsDraftInContext:localContext withCallback:nil];

    return newMessageInstance;
}

+ (EmailMessageInstance*)replyAllToMessageInstance:(EmailMessageInstance*)messageInstance
{
    [ThreadHelper ensureMainThread];

    return [self replyAllToMessageInstance:messageInstance inContext:MAIN_CONTEXT];
}

+ (EmailMessageInstance*)replyAllToMessageInstance:(EmailMessageInstance*)messageInstance inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    return [self replyAllToMessage:messageInstance.message withAccountSetting:messageInstance.accountSetting inContext:localContext];
}

+ (EmailMessageInstance*)replyAllToMessage:(EmailMessage*)message
{
    return [self replyAllToMessage:message withAccountSetting:nil inContext:MAIN_CONTEXT];
}

+ (EmailMessageInstance*)replyAllToMessage:(EmailMessage*)message withAccountSetting:(IMAPAccountSetting*)accountSetting inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    if(!accountSetting)
        accountSetting = [AddressDataHelper senderAccountSetting];

    IMAPFolderSetting* draftsFolder = accountSetting.draftsFolder;

    if(!draftsFolder)
    {
        draftsFolder = [UserSettings currentUserSettingsInContext:localContext].preferredAccount.draftsFolder;
    }

    if(!draftsFolder)
    {
        NSLog(@"There is no drafts folder!!");
        return nil;
    }

    EmailMessage* newMessage = [EmailMessage newDraftMessageInContext:localContext];

    //don't do this - we may not be on main (!!)
    //draftsFolder = MODEL.currentUserSettings.preferredAccount.draftsFolder;

    [newMessage setDateSent:[NSDate date]];

    EmailMessageInstance* newMessageInstance = [EmailMessageInstance findOrMakeNewInstanceForMessage:newMessage inFolder:draftsFolder inContext:localContext];

    [newMessageInstance setFlags:@(MCOMessageFlagSeen|MCOMessageFlagDraft)];
    [newMessageInstance setAddedToFolder:newMessageInstance.inFolder];
    [newMessageInstance changeUID:nil];

    NSString* oldSubject = message.messageData.subject?message.messageData.subject:@"";

    NSString* subject = [NSString stringWithFormat:NSLocalizedString(@"Re: %@", @"Email reply subject"), [FormattingHelper stripReReRes:oldSubject]];


    [newMessage.messageData setSubject:subject];

    NSString* dateString = [NSDateFormatter localizedStringFromDate:message.dateSent dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle];

    NSString* timeString = [NSDateFormatter localizedStringFromDate:message.dateSent dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];

    NSMutableString* forwardBody = [NSMutableString new];

    if(accountSetting.footer.htmlContent.length>0)
    {
        [forwardBody appendFormat:@"<br><br><br><div id=\"mynFooter\">%@</div>", accountSetting.footer.htmlContent];
    }
    else
    {
        [forwardBody appendFormat:@"<br><br><div id=\"mynFooter\"></div>"];
    }

    [forwardBody appendFormat:NSLocalizedString(@"<br>On %@ at %@ %@ wrote:<br>", @"<Date><fromName> reply"), dateString, timeString, message.messageData.fromName];

    // don't put attachments in replies - why?
    // inline images should be ok
    
    NSSet* allAttachments = message.allAttachments;
    
    for (FileAttachment* attachment in allAttachments)
    {
        if ([attachment isInline])
        {
            FileAttachment* newAttachment = [attachment copyInContext:localContext];
            [newAttachment setAttachedAllToMessage:newMessage];
            [newAttachment setAttachedToMessage:nil];
            [newMessage addAllAttachmentsObject:newAttachment];
        }
        else
        {
            // leave a information about left out attachements,
            // like <important.pdf> <lameSignature.as7> <trojanHorse.virus>
            // should go between blockquotes
        }
    }
    
    
    NSArray* recipientArray = [AddressDataHelper recipientsForReplyAllToMessage:message];

//    //add the "from" sender
//
//    EmailRecipient* emailRec = [AddressDataHelper senderAsEmailRecipientForMessage:messageInstance.message];
//
//    if(!emailRec)
//        emailRec = [AddressDataHelper standardSenderAsEmailRecipient];
//
//    Recipient* rec = [[Recipient alloc] initWithEmail:emailRec.email andName:emailRec.name];
//
//    recipientArray = [recipientArray arrayByAddingObject:rec];

    NSData* addressData = [AddressDataHelper addressDataForRecipients:recipientArray];

    [newMessage.messageData setAddressData:addressData];


    NSString* htmlBody = message.messageData.htmlBody;
    if(htmlBody && htmlBody.length>0)
    {
        NSString* quotedBody = [NSString stringWithFormat:@"<blockquote type=\"cite\">%@</blockquote>",htmlBody];
        [forwardBody appendString:quotedBody];
    }
    else
        [forwardBody appendString:message.messageData.body?message.messageData.body:@""];

    htmlBody = forwardBody;
    
    [newMessage.messageData setHtmlBody:htmlBody];

    if([newMessage isKindOfClass:[MynigmaMessage class]])
        [(MynigmaMessage*)newMessage encryptAsDraftInContext:localContext withCallback:nil];

    return newMessageInstance;
}

+ (EmailMessageInstance*)forwardOfMessageInstance:(EmailMessageInstance*)messageInstance
{
    [ThreadHelper ensureMainThread];

    return [self forwardOfMessageInstance:messageInstance inContext:MAIN_CONTEXT];
}

+ (EmailMessageInstance*)forwardOfMessageInstance:(EmailMessageInstance*)messageInstance inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    return [self forwardOfMessage:messageInstance.message withAccountSetting:messageInstance.accountSetting inContext:localContext];
}

+ (EmailMessageInstance*)forwardOfMessage:(EmailMessage*)message
{
    return [self forwardOfMessage:message withAccountSetting:nil inContext:MAIN_CONTEXT];
}

+ (EmailMessageInstance*)forwardOfMessage:(EmailMessage*)message withAccountSetting:(IMAPAccountSetting*)accountSetting inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    if(!accountSetting)
        accountSetting = [AddressDataHelper senderAccountSetting];

    IMAPFolderSetting* draftsFolder = accountSetting.draftsFolder;

    if(!draftsFolder)
    {
        draftsFolder = [UserSettings currentUserSettingsInContext:localContext].preferredAccount.draftsFolder;
    }

    if(!draftsFolder)
    {
        NSLog(@"There is no drafts folder!!");
        return nil;
    }

    EmailMessage* newMessage = [EmailMessage newDraftMessageInContext:localContext];
 
    [newMessage setDateSent:[NSDate date]];

    //don't do this - we may not be on main (!!)
    //draftsFolder = MODEL.currentUserSettings.preferredAccount.draftsFolder;

    EmailMessageInstance* newMessageInstance = [EmailMessageInstance findOrMakeNewInstanceForMessage:newMessage inFolder:draftsFolder inContext:localContext];

    [newMessageInstance setFlags:@(MCOMessageFlagSeen|MCOMessageFlagDraft)];
    [newMessageInstance setAddedToFolder:newMessageInstance.inFolder];
    [newMessageInstance changeUID:nil];

    NSString* oldSubject = message.messageData.subject?message.messageData.subject:@"";

    NSString* subject = [NSString stringWithFormat:NSLocalizedString(@"Fw: %@", @"Email forward subject"), [FormattingHelper stripReReRes:oldSubject]];

    [newMessage.messageData setSubject:subject];

    NSString* dateString = [NSDateFormatter localizedStringFromDate:message.dateSent dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle];

    NSString* timeString = [NSDateFormatter localizedStringFromDate:message.dateSent dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];

    //don't put attachments in replies
    //nono - here we definitifly want attachments to prevail!

    NSSet* allAttachments = message.allAttachments;

    for (FileAttachment* attachment in allAttachments)
    {
        FileAttachment* newAttachment = [attachment copyInContext:localContext];
        [newAttachment setAttachedAllToMessage:newMessage];
        if (![attachment isInline])
            [newAttachment setAttachedToMessage:newMessage];
        [newMessage addAllAttachmentsObject:newAttachment];
    }


    NSArray* recipientArray = [AddressDataHelper recipientsForForwardOfMessage:message];

    //    //add the "from" sender
    //
    //    EmailRecipient* emailRec = [AddressDataHelper senderAsEmailRecipientForMessage:messageInstance.message];
    //
    //    if(!emailRec)
    //        emailRec = [AddressDataHelper standardSenderAsEmailRecipient];
    //
    //    Recipient* rec = [[Recipient alloc] initWithEmail:emailRec.email andName:emailRec.name];
    //
    //    recipientArray = [recipientArray arrayByAddingObject:rec];

    NSData* addressData = [AddressDataHelper addressDataForRecipients:recipientArray];

    [newMessage.messageData setAddressData:addressData];


    NSMutableString* forwardBody = [NSMutableString new];

    if(accountSetting.footer.htmlContent.length>0)
    {
        [forwardBody appendFormat:@"<br><br><br><div id=\"mynFooter\">%@</div>", accountSetting.footer.htmlContent];
    }
    else
    {
        [forwardBody appendFormat:@"<br><br><div id=\"mynFooter\"></div>"];
    }

    [forwardBody appendFormat:NSLocalizedString(@"<br>On %@ at %@ %@ wrote:<br>", @"<Date><fromName> reply"), dateString, timeString, message.messageData.fromName];

    NSString* htmlBody = message.messageData.htmlBody;

    if(htmlBody && htmlBody.length>0)
    {
        NSString* quotedBody = [NSString stringWithFormat:@"<blockquote type=\"cite\">%@</blockquote>",htmlBody];
        [forwardBody appendString:quotedBody];
    }
    else
        [forwardBody appendString:message.messageData.body?message.messageData.body:@""];

    htmlBody = forwardBody;

    [newMessage.messageData setHtmlBody:htmlBody];

    if([newMessage isKindOfClass:[MynigmaMessage class]])
    {
        [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {

            if(newMessage.objectID.isTemporaryID)
            {
                [localContext obtainPermanentIDsForObjects:@[newMessage] error:nil];
            }

            NSManagedObjectID* newMessageObjectID = newMessage.objectID;

            if(newMessageObjectID)
            {
                MynigmaMessage* localMessage = (MynigmaMessage*)[localContext existingObjectWithID:newMessageObjectID error:nil];

                [localMessage encryptAsDraftInContext:localContext withCallback:nil];
            }
        }];
    }

    return newMessageInstance;
}



+ (EmailMessageInstance*)freshComposedMessageInstanceWithSenderRecipient:(Recipient*)recipient
{
    [ThreadHelper ensureMainThread];

    //find the appropriate drafts folder
    IMAPAccountSetting* fromAccountSetting = nil;

    for(IMAPAccountSetting* accountSetting in [UserSettings currentUserSettings].accounts)
    {
        if([accountSetting.senderEmail isEqual:recipient.displayEmail])
        {
            fromAccountSetting = accountSetting;
        }
    }

    IMAPFolderSetting* draftsFolder = nil;
    if(fromAccountSetting)
    {
        draftsFolder = fromAccountSetting.draftsFolder;
    }

    if(!draftsFolder)
    {
        if([SelectionAndFilterHelper sharedInstance].topSelection)
            draftsFolder = [SelectionAndFilterHelper sharedInstance].topSelection.accountSetting.draftsFolder;
    }

    if(!draftsFolder)
        draftsFolder = [UserSettings currentUserSettings].preferredAccount.draftsFolder;

    if(!draftsFolder)
    {
        NSLog(@"Cannot compose message: no drafts folder!!");
        //return;
    }

    //create a new draft message
    EmailMessage* newMessage = [EmailMessage newDraftMessageInContext:MAIN_CONTEXT];

    //create a new message instance
    EmailMessageInstance* newMessageInstance = [EmailMessageInstance findOrMakeNewInstanceForMessage:newMessage inFolder:draftsFolder inContext:MAIN_CONTEXT];
    [newMessageInstance setAddedToFolder:newMessageInstance.inFolder];
    [newMessageInstance setFlags:@(MCOMessageFlagSeen|MCOMessageFlagDraft)];
    [newMessageInstance changeUID:nil];

    [newMessage setDateSent:[NSDate date]];


    NSString* HTMLString = [FormattingHelper emptyEmailWithFooter:fromAccountSetting.footer];

    [newMessage.messageData setHtmlBody:HTMLString];

    //address data will be provided by the caller

    return newMessageInstance;
}

#if TARGET_OS_IPHONE

#else

// Mac (webkit) only 
+(void) addTitleAttributeToAllLinksInWebView:(WebView*)webview
{
    DOMDocument* domdoc = webview.mainFrameDocument;
    DOMNodeList* domlist = (DOMNodeList*)[domdoc getElementsByTagName:@"a"];
    
    for (int i = 0; i<domlist.length; i++)
    {
        DOMHTMLElement* elem = (DOMHTMLElement*)[domlist item:i];
        [elem setAttribute:@"title" value:[elem getAttribute:@"href"]];
    }
}

+(void) collapseLatestQuote:(WebView*)webview
{
    DOMDocument* domdoc = webview.mainFrameDocument;
    
    //blockquote
    DOMNodeList* domlist = (DOMNodeList*)[domdoc getElementsByTagName:@"blockquote"];
    for (int i = 0; i<domlist.length; i++)
    {
        DOMHTMLElement* elem = (DOMHTMLElement*)[domlist item:i];
   //   if ([[elem getAttribute:@"type"] isEqual:@"cite"])
        {
            NSString* before = [NSString stringWithFormat:@"<div id='quoteLink'><br><a href='uncollapseQuote:'>%@</a><br></div><div id='hiddenQuote' style='display:none;'>",NSLocalizedString(@"Show more",@"Uncollapse quote link")];
        
            [elem setInnerHTML:[[before stringByAppendingString:elem.innerHTML] stringByAppendingString:@"</div>"]];
            [webview setNeedsDisplay:YES];
            //fibr
            break;
        }
    }
}

+(void) uncollapseQuote:(WebView*)webview
{
    DOMDocument* domdoc = webview.mainFrameDocument;
    
    //remove link
    DOMHTMLElement* link = (DOMHTMLElement*)[domdoc getElementById:@"quoteLink"];
    [link.parentElement removeChild:link];
    
    //unwrap quote
    DOMHTMLElement* quote = (DOMHTMLElement*)[domdoc getElementById:@"hiddenQuote"];
    [quote removeAttribute:@"style"];
    
    [webview setNeedsDisplay:YES];
}

#endif

#if TARGET_OS_IPHONE

//iOS only

//assuming that the htmlBodyContent has no body, html or head tags
+ (NSString*)prepareHTMLContentForDisplay:(NSString*)htmlBodyContent makeEditable:(BOOL)editable
{
    if(!htmlBodyContent)
        return nil;
    
    // need to do the following:
    //
    // 1. add html, head and body tags if necessary
    //
    // 2. make the body editable
    //
    // 3. add the CSS link to the head
    //
    // 4. replace "cid:" with "https://cid/?p=" in inline image src attributes

    NSURL* CSSFileURL = [[NSBundle mainBundle] URLForResource:@"style_iOS" withExtension:@"css"];

    NSString* fileURLString = [CSSFileURL absoluteString];

    NSString* htmlBody = [NSString stringWithFormat:@"<html><head><meta name=\"viewport\" content=\"width=device-width\"><link href=\"%@\" rel=\"stylesheet\" type=\"text/css\" /></head><body><div id=\"content\"%@>%@</div></body></html>", fileURLString, editable?@" contenteditable=\"true\"":@"", [htmlBodyContent copy]];

    htmlBody = [htmlBody stringByReplacingOccurrencesOfString:@"src=\"cid:" withString:@"src=\"https://cid/?p="];

    return htmlBody;
}

+ (NSString*)getsavableHTMLFromTextView:(UITextView *)textView
{
    NSString* htmlString = [textView text];
    
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];
    
    return htmlString;
}

+ (NSString*)getSavableHTMLFromWebView:(UIWebView*)webView
{
    // need to do the following:
    //
    // 1. get the message content (from the div with id "content")
    //
    // 2. replace "https://cid/?p=" with "cid:" in inline image src attributes

    NSString* htmlBody = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('content').innerHTML"];

    htmlBody = [htmlBody stringByReplacingOccurrencesOfString:@"src=\"https://cid/?p=" withString:@"src=\"cid:"];

    return htmlBody;
}

#endif

@end
