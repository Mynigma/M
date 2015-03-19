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





#import "DisplayMessageView.h"
#import "Recipient.h"
#import "MessageCellView.h"
#import "FileAttachment+Category.h"
#import "MessageCellView.h"
#import "IMAPAccount.h"
#import "EmailRecipient.h"
#import "Recipient.h"
#import "AttachmentCellView.h"
#import "EmailMessage+Category.h"
#import "ComposeWindowController.h"
#import "IMAPAccountSetting+Category.h"
#import "ABContactDetail.h"
#import "ContentView.h"
#import "UserSettings.h"
#import "SeparateViewerWindowController.h"
#import "MynigmaMessage+Category.h"
#import "IMAPFolderSetting+Category.h"
#import <MailCore/MailCore.h>
#import "InlineAttachment.h"
#import "AddressDataHelper.h"
#import "EmailMessageData.h"
#import "AttachmentsManager.h"
#import "IconListAndColourHelper.h"
#import "EmailMessageInstance+Category.h"
#import "Contact+Category.h"
#import "EmailContactDetail+Category.h"
#import "ABContactDetail+Category.h"
#import "AttachmentsIconView.h"
#import "MynigmaFeedback.h"
#import "DeviceMessage+Category.h"
#import "MynigmaDevice+Category.h"
#import "FormattingHelper.h"
#import "WindowManager.h"
#import "DownloadHelper.h"
#import "NSView+LayoutAdditions.h"





#if ULTIMATE

#import "CustomerManager.h"

#endif



@implementation DisplayMessageView


- (void)awakeFromNib
{
    self.boxWidthConstraint.constant = 0;

//    [[WindowManager sharedInstance] setDisplayView:self];
    
//    [self setTranslatesAutoresizingMaskIntoConstraints:NO];

    // CSS for blockquotes, web view preferences
    WebPreferences *webPrefs = [WebPreferences standardPreferences];
    [webPrefs setUserStyleSheetEnabled:YES];
    [webPrefs setStandardFontFamily:@"Helvetica"];
    [webPrefs setUserStyleSheetLocation:[[NSBundle mainBundle] URLForResource:@"style" withExtension:@"css"]];
    
    [webPrefs setLoadsImagesAutomatically:![[NSUserDefaults standardUserDefaults] boolForKey:@"doNotLoadImagesAutomatically"]];
    
    [self.bodyView setPreferences:webPrefs];

    [[[self.bodyView mainFrame] frameView] setAllowsScrolling:YES];

    [self.hideContentConstraint setPriority:999];
    [self.placeHolderView setHidden:NO];
    
//    if(NSClassFromString(@"NSVisualEffectView"))
//    {
//        NSVisualEffectView* effectView = [[NSVisualEffectView alloc] init];
//        
//        [self.placeHolderView addSubview:effectView];
//                
//        [effectView setUpConstraintsToFitIntoSuperview];
//    }
}


#pragma mark - Public methods: show & refresh messages

- (void)showMessageInstance:(EmailMessageInstance*)messageInstance
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0];

    [self configureWithMessage:messageInstance.message andMessageInstance:messageInstance];

    [self layout];

    [NSAnimationContext endGrouping];
}

- (void)showMessage:(EmailMessage*)message
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0];

    [self configureWithMessage:message andMessageInstance:nil];

    [self layout];

    [NSAnimationContext endGrouping];
}

- (void)refresh
{
    [self configureWithMessage:self.message andMessageInstance:self.messageInstance];
}

- (void)refreshMessage:(EmailMessage*)message
{
    if([self.message isEqual:message])
        [self refresh];
}

- (void)refreshMessageInstance:(EmailMessageInstance*)messageInstance
{
    if([self.messageInstance isEqual:messageInstance])
        [self refresh];
}



#pragma mark - UI actions

- (IBAction)tryAgainButtonClicked:(id)sender
{
    if([self.messageInstance isKindOfClass:[EmailMessageInstance class]])
    {
        [DownloadHelper downloadMessageInstance:self.messageInstance urgent:YES alsoDownloadAttachments:NO];

        [self refresh];
    }
    else if([self.message isKindOfClass:[EmailMessage class]])
    {
        [DownloadHelper downloadMessage:self.message urgent:YES];

        [self refresh];
    }

    else
        NSLog(@"Try again button clicked with invalid message!!!");
}

- (IBAction)saveImageByRightClick:(id)sender
{

}

- (IBAction)unreadButton:(id)sender
{
    if([self.messageInstance isUnread])
        [self.messageInstance markRead];
    else
        [self.messageInstance markUnread];

    NSInteger row = [APPDELEGATE.messagesTable selectedRow];
    if(row>=0 && row<APPDELEGATE.messagesTable.numberOfRows)
    {
        [APPDELEGATE.messagesTable beginUpdates];
        [APPDELEGATE.messagesTable reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
        [APPDELEGATE.messagesTable endUpdates];
    }
}

- (IBAction)spamButton:(id)sender
{
        if([self.messageInstance isKindOfClass:[EmailMessageInstance class]])
        {
            if([self.messageInstance isInSpamFolder])
                [self.messageInstance moveToInbox];
            else
                [self.messageInstance moveToSpam];
        }
}

- (IBAction)deleteButton:(id)sender
{
    if([self.messageInstance isKindOfClass:[EmailMessageInstance class]])
        {
            [self.messageInstance moveToBinOrDelete];
        }
}


- (IBAction)flagButton:(id)sender
{
        if([self.messageInstance isKindOfClass:[EmailMessageInstance class]])
        {
            if([self.messageInstance isFlagged])
                [self.messageInstance markUnflagged];
            else
                [self.messageInstance markFlagged];
            NSInteger row = [APPDELEGATE.messagesTable selectedRow];
            if(row>=0 && row<APPDELEGATE.messagesTable.numberOfRows)
            {
                [APPDELEGATE.messagesTable beginUpdates];
                [APPDELEGATE.messagesTable reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
                [APPDELEGATE.messagesTable endUpdates];
            }
        }
}

- (IBAction)replyButton:(id)sender
{
        if([self.message isKindOfClass:[EmailMessage class]])
        {
            ComposeWindowController* composeController = [WindowManager showFreshMessageWindow];
            if (self.messageInstance)
                [composeController setFieldsForReplyToMessageInstance:self.messageInstance];
            else
                [composeController setFieldsForReplyToMessage:self.message];
        }
}

- (IBAction)replyAllButton:(id)sender
{
        if([self.message isKindOfClass:[EmailMessage class]])
        {
            ComposeWindowController* composeController = [WindowManager showFreshMessageWindow];
            if (self.messageInstance)
                [composeController setFieldsForReplyAllToMessageInstance:self.messageInstance];
            else
                [composeController setFieldsForReplyAllToMessage:self.message];
        }
}

- (IBAction)forwardButton:(id)sender
{
        if([self.message isKindOfClass:[EmailMessage class]])
        {
            ComposeWindowController* composeController = [WindowManager showFreshMessageWindow];
            if (self.messageInstance)
                [composeController setFieldsForForwardOfMessageInstance:self.messageInstance];
            else
                [composeController setFieldsForForwardOfMessage:self.message];
        }
}


- (IBAction)cautionButtonClicked:(id)sender
{
    MynigmaMessage* message = (MynigmaMessage*)self.message;

    if([message isKindOfClass:[MynigmaMessage class]])
    {
        MynigmaFeedback* error = [MynigmaFeedback feedbackWithArchivedString:[(MynigmaMessage*)message decryptionStatus] message:message];

        [NSApp presentError:error modalForWindow:self.window delegate:message didPresentSelector:@selector(didPresentErrorWithRecovery:contextInfo:) contextInfo:nil];
    }
}


#pragma mark - Private methods: configure UI elements




- (void)configureWithMessage:(EmailMessage*)message andMessageInstance:(EmailMessageInstance*)messageInstance
{
    [self setMessage:message];
    [self setMessageInstance:messageInstance];

    WebPreferences *webPrefs = [WebPreferences standardPreferences];
    [webPrefs setLoadsImagesAutomatically:![[NSUserDefaults standardUserDefaults] boolForKey:@"doNotLoadImagesAutomatically"]];
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0];

    if(message)
    {
        [self.hideContentConstraint setPriority:1];
        [self.placeHolderView setHidden:YES];
    }
    else
    {
        [self.hideContentConstraint setPriority:999];
        [self.placeHolderView setHidden:NO];
    }

    if([messageInstance isUnread])
    {
        [messageInstance markRead];
    }



    if(messageInstance)
    {
        [self.unreadButton setState:messageInstance.isUnread?NSOnState:NSOffState];
        [self.flagButton setState:messageInstance.isFlagged?NSOnState:NSOffState];
        [self.unreadButton setEnabled:YES];
        [self.flagButton setEnabled:YES];
    }
    else
    {
        [self.unreadButton setState:NSOffState];
        [self.flagButton setState:NSOffState];
        [self.unreadButton setEnabled:NO];
        [self.flagButton setEnabled:NO];
    }

    [self.addressLabelView setEmailRecipientsForMessage:message];

    [self.addressLabelView setNeedsLayout:YES];

    [self.bodyView setMessage:message];

    //this is the green strip indicating a safe message
    [self.boxWidthConstraint setConstant:[message isSafe]?LEFT_BORDER_OFFSET:0];

    if([message profilePic])
    {
        NSImage* senderProfilePic = [message profilePic];

        [self.profilePicView setImage:senderProfilePic];
        [self.profilePicView setHidden:NO];
        [self.hideProfilePicConstraint setPriority:1];
    }
    else
    {
        [self.profilePicView setHidden:YES];
        [self.hideProfilePicConstraint setPriority:999];
    }

    NSString* existingSubject = message.messageData.subject;

    if(!existingSubject)
    {
        if([message isSafe])
            existingSubject = NSLocalizedString(@"Safe message",@"Safe, secure email message");
        else
            existingSubject = @"";
    }

    [self.subjectField setStringValue:existingSubject];

    //now load the body and set the feedback

    //the message is a draft
    //ignore the downloaded/downloading status etc...
//    if(messageInstance.flags.intValue & MCOMessageFlagDraft)
//    {
//        [self.bodyView.mainFrame loadHTMLString:message.messageData.htmlBody?message.messageData.htmlBody:@"" baseURL:nil];
//        [self.feedbackView hideFeedback];
//    }
//    else

    NSString* htmlBody = [self.message htmlBody];

    [[self.bodyView mainFrame] loadHTMLString:htmlBody baseURL:nil];


    [NSAnimationContext endGrouping];

    if([self.message isDeviceMessage])
    {
        [self.feedbackView hideFeedback];

        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:0.2];

        [self.attachmentListHeight.animator setConstant:0];
        
        [NSAnimationContext endGrouping];

#if ULTIMATE

        if([CustomerManager isExclusiveVersion])
        {
            NSString* messageCommand = [(DeviceMessage*)self.message messageCommand];
            [self.subjectField setStringValue:messageCommand?messageCommand:@""];
        }

#endif

        return;
    }

    [self.feedbackView showFeedbackForMessage:self.message];

    [self setNeedsLayout:YES];
    [self layoutSubtreeIfNeeded];

    MynigmaFeedback* feedback = [self.message feedback];

    
    if([feedback isWarning])
    {
        [self.addressLabelLeftAlignment setConstant:-36];
        [self.cautionButton setHidden:NO];
    }
    else
    {
        [self.addressLabelLeftAlignment setConstant:6];
        [self.cautionButton setHidden:YES];
    }

    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.2];
    [[NSAnimationContext currentContext] setAllowsImplicitAnimation:YES];




    if(![message isSafe] || [message isDecrypted])
    {
        [self.attachmentsView showAttachments:message.attachments];

//        NSArray* attachmentItems = [AttachmentsManager attachmentItemsForMessage:message];
//
        [self.attachmentListHeight.animator setConstant:message.attachments.count?120:0];
//
//        [self.attachmentsArrayController addObjects:attachmentItems];

//        [self.topMetalSheetHideConstraint.animator setPriority:999];
//        [self.topMetalSheetShowConstraint.animator setPriority:1];
//
//        [self.bottomMetalSheetHideConstraint.animator setPriority:999];
//        [self.bottomMetalSheetShowConstraint.animator setPriority:1];
//
//        NSImage* bigImage = [[NSImage alloc] initWithSize:self.topMetalSheetRibbon.bounds.size];
//
//        [bigImage lockFocus];
//
//        NSImage* patternImage = [NSImage imageNamed:@"doorGreenFlipped"];
//
//        NSColor* backgroundColor = [NSColor colorWithPatternImage:patternImage];
//
//        [backgroundColor set];
//
//        NSRectFill(self.topMetalSheetRibbon.bounds);
//
//        [bigImage unlockFocus];
//
//        //[patternImage setScalesWhenResized:YES];
//        [self.topMetalSheetRibbon setImage:bigImage];
//
//        bigImage = [[NSImage alloc] initWithSize:self.bottomMetalSheetRibbon.bounds.size];
//
//        patternImage = [NSImage imageNamed:@"doorGreen"];
//
//        [bigImage lockFocus];
//
//        backgroundColor = [NSColor colorWithPatternImage:patternImage];
//
//        [backgroundColor set];
//
//        NSRectFill(self.bottomMetalSheetRibbon.bounds);
//        
//        [bigImage unlockFocus];
//        
//        [self.bottomMetalSheetRibbon setImage:bigImage];
    }
    else
    {
        [self.attachmentsView showAttachments:[NSSet set]];

        [self.attachmentListHeight.animator setConstant:0];

        //        [self.topMetalSheetHideConstraint.animator setPriority:1];
//        [self.topMetalSheetShowConstraint.animator setPriority:999];
//
//        [self.bottomMetalSheetHideConstraint.animator setPriority:1];
//        [self.bottomMetalSheetShowConstraint.animator setPriority:999];
//
//        NSImage* bigImage = [[NSImage alloc] initWithSize:self.topMetalSheetRibbon.bounds.size];
//
//        [bigImage lockFocus];
//
//        NSImage* patternImage = [NSImage imageNamed:@"doorSheetNew"];
//
//        NSColor* backgroundColor = [NSColor colorWithPatternImage:patternImage];
//
//        [backgroundColor set];
//
//        NSRectFill(self.topMetalSheetRibbon.bounds);
//
//        [bigImage unlockFocus];
//
//        //[patternImage setScalesWhenResized:YES];
//        [self.topMetalSheetRibbon setImage:bigImage];
//
//        bigImage = [[NSImage alloc] initWithSize:self.bottomMetalSheetRibbon.bounds.size];
//
////        patternImage = [NSImage imageNamed:@"doorSheet"];
//
//        [bigImage lockFocus];
//
//        backgroundColor = [NSColor colorWithPatternImage:patternImage];
//
//        [backgroundColor set];
//
//        NSRectFill(self.bottomMetalSheetRibbon.bounds);
//
//        [bigImage unlockFocus];
//
//        [self.bottomMetalSheetRibbon setImage:bigImage];
    }


    [NSAnimationContext endGrouping];
}

//- (void)configureWithMessageInstance:(EmailMessageInstance*)messageInstance
//{
//    [self.addressLabelView setEmailRecipientsForMessage:messageInstance.message];
//
//    [self.bodyView setMessage:messageInstance.message];
//    [self setMessage:messageInstance.message];
//    [[self.bodyView preferences] setStandardFontFamily:@"Helvetica"];
//    [[self.bodyView preferences] setDefaultFontSize:12];
//    [[[self.bodyView mainFrame] frameView] setAllowsScrolling:YES];
//
//    //[self.outerBox setHidden:YES];
//
//    [self.boxWidthConstraint setConstant:0];
//
//    if([MODEL haveProfilePicForMessage:messageInstance.message])
//    {
//        NSImage* senderProfilePic = [MODEL profilePicForMessage:messageInstance.message];
//
//        [self.profilePicView setImage:senderProfilePic];
//        [self.profilePicView setHidden:NO];
//        [self.picHiderConstraint setPriority:999];
//    }
//    else
//    {
//        [self.profilePicView setHidden:YES];
//        [self.picHiderConstraint setPriority:1];
//    }
//
//    [self.unreadButton setState:[messageInstance isUnread]?NSOnState:NSOffState];
//    [self.flagButton setState:[messageInstance isFlagged]?NSOnState:NSOffState];
//
//    [self.subjectField setStringValue:messageInstance.message.messageData.subject?messageInstance.message.messageData.subject:@"(no subject)"];
//    [self.tryAgainButton setHidden:YES];
//    [self.tryAgainLabel setStringValue:NSLocalizedString(@"Click to try again", @"Try again button")];
//    [self.tryAgainLabel setHidden:YES];
//    [self.progressBar setHidden:YES];
//
//    NSString* bodyString = messageInstance.message.messageData.htmlBody;
//    if(bodyString)
//    {
//        [[self.bodyView mainFrame] loadHTMLString:bodyString baseURL:nil];
//        [self setFeedBackString:nil];
//    }
//    else
//    {
//        [[self.bodyView mainFrame] loadHTMLString:@"" baseURL:nil];
//        if([messageInstance.message isDownloading])
//        {
//            [[self.bodyView mainFrame] loadHTMLString:@"" baseURL:nil];
//            [self setFeedBackString:NSLocalizedString(@"Downloading message body",@"Placeholder label")];
//            [self.tryAgainLabel setHidden:YES];
//            [self.progressBar setHidden:NO];
//        }
//        else if([messageInstance.message isCleaning])
//        {
//            [[self.bodyView mainFrame] loadHTMLString:@"" baseURL:nil];
//            [self setFeedBackString:NSLocalizedString(@"Cleaning message body",@"Placeholder label")];
//            [self.tryAgainLabel setHidden:YES];
//            [self.progressBar setHidden:NO];
//        }
//        else
//        {
//            [[self.bodyView mainFrame] loadHTMLString:@"" baseURL:nil];
//            [self setFeedBackString:NSLocalizedString(@"Error downloading message body",@"Placeholder label")];
//            [self.tryAgainButton setHidden:NO];
//            [self.tryAgainLabel setHidden:NO];
//        }
//    }
//}

//- (void)configureWithMessage:(EmailMessage*)message
//{
//    [self.addressLabelView setEmailRecipientsForMessage:message];
//
//    [self.bodyView setMessage:message];
//    [self setMessage:message];
//
//    [[self.bodyView preferences] setStandardFontFamily:@"Helvetica"];
//    [[self.bodyView preferences] setDefaultFontSize:12];
//    [[[self.bodyView mainFrame] frameView] setAllowsScrolling:YES];
//
//    if([message isSafe])
//    {
//        [self.outerBox setHidden:NO];
//        [self.boxWidthConstraint setConstant:32];
//    }
//    else
//    {
//        [self.outerBox setHidden:YES];
//        [self.boxWidthConstraint setConstant:0];
//    }
//
//    if([MODEL haveProfilePicForMessage:message])
//    {
//        NSImage* senderProfilePic = [MODEL profilePicForMessage:message];
//
//        [self.profilePicView setImage:senderProfilePic];
//        [self.profilePicView setHidden:NO];
//        [self.picHiderConstraint setPriority:999];
//    }
//    else
//    {
//        [self.profilePicView setHidden:YES];
//        [self.picHiderConstraint setPriority:1];
//    }
//
//    [self.unreadButton setState:NSOffState];
//    [self.flagButton setState:NSOffState];
//
//    [self.subjectField setStringValue:message.messageData.subject?message.messageData.subject:@"(no subject)"];
//    [self.tryAgainButton setHidden:YES];
//    [self.tryAgainLabel setStringValue:NSLocalizedString(@"Click to try again", @"Try again button")];
//    [self.tryAgainLabel setHidden:YES];
//    [self.progressBar setHidden:YES];
//
//    NSString* bodyString = message.messageData.htmlBody;
//    if(bodyString)
//    {
//        [[self.bodyView mainFrame] loadHTMLString:bodyString baseURL:nil];
//        [self setFeedBackString:nil];
//    }
//    else
//    {
//        [[self.bodyView mainFrame] loadHTMLString:@"" baseURL:nil];
//        if([message isDownloading])
//        {
//            [[self.bodyView mainFrame] loadHTMLString:@"" baseURL:nil];
//            [self setFeedBackString:NSLocalizedString(@"Downloading message body",@"Placeholder label")];
//            [self.tryAgainLabel setHidden:YES];
//            [self.progressBar setHidden:NO];
//        }
//        else if([message isCleaning])
//        {
//            [[self.bodyView mainFrame] loadHTMLString:@"" baseURL:nil];
//            [self setFeedBackString:NSLocalizedString(@"Cleaning message body",@"Placeholder label")];
//            [self.tryAgainLabel setHidden:YES];
//            [self.progressBar setHidden:NO];
//        }
//        else
//        {
//            [[self.bodyView mainFrame] loadHTMLString:@"" baseURL:nil];
//            [self setFeedBackString:NSLocalizedString(@"Error downloading message body",@"Placeholder label")];
//            [self.tryAgainButton setHidden:NO];
//            [self.tryAgainLabel setHidden:NO];
//        }
//    }
//}




#pragma mark -
#pragma mark WEB VIEW POLICY DELEGATE

- (void)webView:(WebView *)webView
decidePolicyForNavigationAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request frame:(WebFrame *)frame
decisionListener:(id < WebPolicyDecisionListener >)listener
{
    //always open mailto: links with Mynigma

    if([request.URL.scheme.lowercaseString isEqual:@"mailto"])
    {
        [AppDelegate openURL:request.URL];
        return;
    }
    
    if([request.URL.scheme.lowercaseString isEqual:@"uncollapsequote"])
    {
        [FormattingHelper uncollapseQuote:webView];
        return;
    }

    if([[actionInformation objectForKey:WebActionNavigationTypeKey] integerValue] == WebNavigationTypeLinkClicked)
    {
        if(!self.message.messageData.loadRemoteImages.boolValue && self.message.messageData.hasImages.boolValue)
        {
            [self.message.messageData setLoadRemoteImages:[NSNumber numberWithBool:YES]];
            [self refresh];
        }
        else
        {
            //if(request.URL.scheme isEqualToString:@")
            [[NSWorkspace sharedWorkspace] openURL:[request URL]];
        }

    }
    else
        [listener use];
}

//- (void)webView:(WebView *)webView decidePolicyForNewWindowAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request newFrameName:(NSString *)frameName decisionListener:(id < WebPolicyDecisionListener >)listener
//{
//    ContentViewerCellView* contentView = (ContentViewerCellView*)[webView superview];
//    NSInteger row = [APPDELEGATE.viewerTable rowForView:contentView];
//    if(row!=NSNotFound)
//    {
//        if(row<APPDELEGATE.viewerArray.count)
//        {
//            EmailMessageInstance* messageInstance = [APPDELEGATE.viewerArray objectAtIndex:row];
//            if(!messageInstance.message.messageData.loadRemoteImages.boolValue)
//            {
//                [messageInstance.message.messageData setLoadRemoteImages:[NSNumber numberWithBool:YES]];
//                [APPDELEGATE.viewerTable reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
//            }
//            else
//                [[NSWorkspace sharedWorkspace] openURL:[request URL]];
//        }
//    }
//}


#pragma mark -
#pragma mark WEB VIEW RESOURCE LOAD DELEGATE

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource
{
        NSMutableString* requestString = [[[request URL] absoluteString] mutableCopy];
            if([[[request URL] absoluteString] hasPrefix:@"cid:"])
            {

                [requestString deleteCharactersInRange:NSMakeRange(0,4)];

                for(FileAttachment* attachment in self.message.allAttachments)
                    if([attachment.contentid isEqualToString:requestString])
                    {
                        NSURL* privateURL = [attachment privateURL];

                        if(privateURL)
                            return [[NSMutableURLRequest alloc] initWithURL:privateURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];

                        NSURL* publicURL = [attachment publicURL];

                        if(publicURL)
                            return [[NSMutableURLRequest alloc] initWithURL:publicURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];

                        return [[NSMutableURLRequest alloc] initWithURL:request.URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
                    }
            }
            else
            {
                //NSLog(@"Not a cid request: %@",request);
                [self.message.messageData setHasImages:[NSNumber numberWithBool:YES]];
                if(self.message.messageData.loadRemoteImages.boolValue)
                    return [[NSMutableURLRequest alloc] initWithURL:[request URL] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:30.0];
                //return request;
                else
                {
                    //[self.contentView.showImagesLabel setHidden:NO];
                }
            }
    return [[NSMutableURLRequest alloc] initWithURL:[[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"placeholder.png"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
}


#pragma mark -
#pragma mark WEB VIEW FRAME LOAD DELEGATE

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{

}


- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    [FormattingHelper addTitleAttributeToAllLinksInWebView:sender];
    // Only needed for message threads
    // [FormattingHelper collapseLatestQuote:sender];
}


#pragma mark -
#pragma mark WEB VIEW UI DELEGATE


- (NSArray*)webView:(WebView*)sender contextMenuItemsForElement:(NSDictionary*)element defaultMenuItems:(NSArray*)defaultMenuItems
{
    if(!element)
        return @[];
    
    NSString* imageURL = [element objectForKey:WebElementImageURLKey];
    if(imageURL)
    {
        //TO DO: allow save by right-click
        
    }
    return @[];
}


@end
