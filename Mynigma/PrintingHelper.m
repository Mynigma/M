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





#import "PrintingHelper.h"
#import "AppDelegate.h"
#import "AlertHelper.h"
#import "EmailMessageController.h"
#import "EmailMessageInstance+Category.h"
#import "EmailMessage+Category.h"
#import <WebKit/WebKit.h>
#import "EmailMessageData.h"
#import "AddressDataHelper.h"
#import "FileAttachment+Category.h"
#import "Recipient.h"



@implementation PrintingHelper


+ (instancetype)sharedInstance
{
    static dispatch_once_t p = 0;

    __strong static id sharedObject = nil;

    dispatch_once(&p, ^{
        sharedObject = [self new];
    });

    return sharedObject;
}


#pragma mark -
#pragma mark PRINTING


+ (void)printDocument
{
    [ThreadHelper ensureMainThread];

    NSArray* selectedMessages = [EmailMessageController selectedMessages];
    if(selectedMessages.count>=5)
    {
        //alert, more than 5 print windows
        NSModalResponse alertResponse = [AlertHelper showAlertWithMessage:NSLocalizedString(@"Printing more than 5 emails",@"Alert Window Title") informativeText:[NSString stringWithFormat:NSLocalizedString(@"Do you really want to open %lu print windows at a time?",@"Alert Window Text <number of messages>"),(unsigned long)selectedMessages.count] otherButtonTitle:NSLocalizedString(@"Cancel",@"Cancel Button")];
        if (alertResponse == NSOKButton)
            [self printMessageObjects:selectedMessages];
    }
    else
    {
        [self printMessageObjects:selectedMessages];
    }
}

//TODO page numbering
+ (void)printMessageObjects:(NSArray*)messagesToPrint
{
    [ThreadHelper ensureMainThread];

    for(NSManagedObject* messageObject in messagesToPrint)
    {
        EmailMessage* message = nil;

        if([messageObject isKindOfClass:[EmailMessageInstance class]])
            message = [(EmailMessageInstance*)messageObject message];
        else if([messageObject isKindOfClass:[EmailMessage class]])
            message = (EmailMessage*)messageObject;
        else
        {
            NSLog(@"Trying to print invalid object %@", messageObject);
            return;
        }

        WebView* printView = [WebView new];

        //set email header
        NSString* header = [self generateHeaderForMessage:message];

        //grab htmlbody from email
        NSString* body = [[message messageData] htmlBody];

        NSString* print = [header stringByAppendingString:body];

        //insert body in webView
        [printView.mainFrame loadHTMLString:print baseURL:nil];

        // set delegate
        [printView setFrameLoadDelegate:[self sharedInstance]];
    }
}


+ (NSString*)generateHeaderForMessage:(EmailMessage*)message
{

    //set recipients
    NSArray* recipients = [AddressDataHelper recipientsForAddressData:message.messageData.addressData];

    NSString* from = @"";
    NSString* to = @"";
    NSString* cc = @"";
    NSString* bcc = @"";
    NSString* replyTo = @"";

    //open or safe
    NSString* safe = message.isSafe?NSLocalizedString(@"Safe message",@"Safe, secure email message"):NSLocalizedString(@"Open message",@"Compose window title");
    safe = [NSString stringWithFormat:@"<nobr>Mynigma %@</nobr>",safe];

    //subject
    NSString* subject = message.messageData.subject?message.messageData.subject:NSLocalizedString(@"(no subject)",@"Placeholder");

    //date
    NSString* date = [NSDateFormatter localizedStringFromDate:message.dateSent dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle];
    if (!date)
        date = NSLocalizedString(@"(no date)",@"Placeholder");

    //attachments
    NSString* attachments = @"";
    for (FileAttachment* attachment in message.allAttachments)
    {
        attachments = [attachments stringByAppendingString:[NSString stringWithFormat:@"<nobr>%@</nobr>, ",[attachment fileName]]];
    }

    //Sort recipients
    for (Recipient* recipient in recipients)
    {
        switch (recipient.type) {
            case TYPE_FROM:
                from = [NSString  stringWithFormat:@"%@ &lt;%@&gt;",recipient.displayName,recipient.displayEmail];
                break;
            case TYPE_TO:
                to = [to stringByAppendingString:[NSString stringWithFormat:@"<nobr>%@</nobr> <nobr>&lt;%@&gt;</nobr>, ",recipient.displayName,recipient.displayEmail]];
                break;
            case TYPE_CC:
                cc = [cc stringByAppendingString:[NSString stringWithFormat:@"<nobr>%@</nobr> <nobr>&lt;%@&gt;</nobr>, ",recipient.displayName,recipient.displayEmail]];
                break;
            case TYPE_BCC:
                bcc = [bcc stringByAppendingString:[NSString stringWithFormat:@"<nobr>%@</nobr> <nobr>&lt;%@&gt;</nobr>, ",recipient.displayName,recipient.displayEmail]];
                break;
            case TYPE_REPLY_TO:
                replyTo = [NSString  stringWithFormat:@"%@ &lt;%@&gt;",recipient.displayName,recipient.displayEmail];
                break;
            default:
                break;
        }
    }


    NSString* header;

    //begin table
    header = @"<table style='font-size:10px;'>";

    //safe/open
    header = [header stringByAppendingString:[NSString stringWithFormat:@"<tr><td>%@</td></tr>",safe]];

    //From
    header = [header stringByAppendingString:[NSString stringWithFormat:@"<tr><td style='color:#ccc;font-weight:bold;vertical-align:top;'>%@</td><td>%@</td></tr>",NSLocalizedString(@"From:",@"From lable (sender)"),from]];

    //reply to
    if([AddressDataHelper shouldShowReplyToForMessage:message])
        header = [header stringByAppendingString:[NSString stringWithFormat:@"<tr><td style='color:#ccc;font-weight:bold;vertical-align:top;'>%@</td><td>%@</td></tr>",NSLocalizedString(@"Reply To:",@"Reply To lable (sender)"),replyTo]];

    //subject
    header = [header stringByAppendingString:[NSString stringWithFormat:@"<tr><td style='color:#ccc;font-weight:bold;vertical-align:top;'>%@</td><td>%@</td></tr>",NSLocalizedString(@"Subject:",@"Subject lable (email)"),subject]];

    //Date
    header = [header stringByAppendingString:[NSString stringWithFormat:@"<tr><td style='color:#ccc;font-weight:bold;vertical-align:top;'>%@</td><td>%@</td></tr>",NSLocalizedString(@"Date:",@"Date lable (email)"),date]];

    //to
    if (![to isEqual:@""])
        to = [to substringToIndex:to.length-3];
    else
        to = @"(no sender)";
    header = [header stringByAppendingString:[NSString stringWithFormat:@"<tr><td style='color:#ccc;font-weight:bold;vertical-align:top;'>%@</td><td>%@</td></tr>",NSLocalizedString(@"To:",@"To lable (recipient)"),to]];


    //cc
    if (![cc isEqual:@""])
    {
        cc = [cc substringToIndex:cc.length-3];
        header = [header stringByAppendingString:[NSString stringWithFormat:@"<tr><td style='color:#ccc;font-weight:bold;vertical-align:top;'>%@</td><td>%@</td></tr>",NSLocalizedString(@"Cc:",@"Cc lable (recipient)"),cc]];
    }

    //bcc
    if (![bcc isEqual:@""])
    {
        bcc = [bcc substringToIndex:bcc.length-3];
        header = [header stringByAppendingString:[NSString stringWithFormat:@"<tr><td style='color:#ccc;font-weight:bold;vertical-align:top;'>%@</td><td>%@</td></tr>",NSLocalizedString(@"Bcc:",@"Bcc lable (recipient)"),bcc]];
    }

    //attachments
    if (![attachments isEqual:@""])
    {
        attachments = [attachments substringToIndex:attachments.length-3];
        header = [header stringByAppendingString:[NSString stringWithFormat:@"<tr><td style='color:#ccc;font-weight:bold;vertical-align:top;'>%@</td><td>%@</td></tr>",NSLocalizedString(@"Attachments:",@"Attachments lable (email)"),attachments]];
    }

    //end table
    header = [header stringByAppendingString:@"</table><hr noshade style='size:1px;color:#ccc;'><br>"];

    return header;
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    NSView* view = [[[sender mainFrame] frameView] documentView];
    NSPrintOperation *op = [NSPrintOperation printOperationWithView:view];
    [op setCanSpawnSeparateThread:YES];
    [op runOperation];
}


@end
