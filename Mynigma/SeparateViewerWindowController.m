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


#import "SeparateViewerWindowController.h"
#import "Recipient.h"
#import "EmailMessage+Category.h"
#import "EmailRecipient.h"
#import "MynigmaMessage+Category.h"
#import "ComposeWindowController.h"
#import "AttachmentAdditionController.h"
#import "AttachmentItem.h"
#import "FileAttachment+Category.h"
#import "AttachmentListController.h"
#import "EmailMessageData.h"
#import "AttachmentsManager.h"
#import "EmailMessageInstance+Category.h"
#import "AddressDataHelper.h"
#import "EmailContactDetail+Category.h"
#import "RecipientTokenField.h"
#import "IconListAndColourHelper.h"
#import "AttachmentsIconView.h"
#import "MynigmaFeedback.h"
#import "FormattingHelper.h"
#import "WindowManager.h"
#import "PrintingHelper.h"
#import "NSString+EmailAddresses.h"





@interface SeparateViewerWindowController ()

@end

@implementation SeparateViewerWindowController


@synthesize fromTrailingEdgeConstraint;
@synthesize replyToTrailingEdgeConstraint;
@synthesize ccHeightConstraint;
@synthesize bccHeightConstraint;
@synthesize ccSpaceConstraint;
@synthesize bccSpaceConstraint;

@synthesize fromField;
@synthesize subjectField;
@synthesize bodyView;
@synthesize toField;
@synthesize dateField;
@synthesize bccField;
@synthesize ccField;
@synthesize ccShown;
@synthesize bccShown;
@synthesize lockImage;
@synthesize replyToField;
@synthesize replyToShown;
@synthesize toShown;
@synthesize bodyBox;
@synthesize ccLabel;
@synthesize bccLabel;
@synthesize replyToLabel;
@synthesize printButton;
@synthesize attachmentButton;
@synthesize attachmentClip;
@synthesize shownMessageInstance;
@synthesize attachmentList;
@synthesize hasAttachments;
@synthesize ccBox;
@synthesize fromBox;
@synthesize toBox;
@synthesize replyToBox;
@synthesize bccBox;
@synthesize topBox;
@synthesize subjectBox;
@synthesize safeLabel;

@synthesize numberOfAttachmentsLabel;


- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // CSS for blockquotes
    WebPreferences *webPrefs = [WebPreferences standardPreferences];
    [webPrefs setUserStyleSheetEnabled:YES];
    //Point to wherever your local/custom css is
    [webPrefs setUserStyleSheetLocation:[[NSBundle mainBundle] URLForResource:@"style" withExtension:@"css"]];
    
    // enable / disable autoload
    // todo: add this to settings
    [webPrefs setLoadsImagesAutomatically:![[NSUserDefaults standardUserDefaults] boolForKey:@"doNotLoadImagesAutomatically"]];

    //Set your webview's preferences
    [bodyView setPreferences:webPrefs];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (NSMenu *)tokenField:(NSTokenField *)tokenField menuForRepresentedObject:(id)representedObject
{
    NSMenu* menu = [[NSMenu alloc] initWithTitle:@"email selection menu"];
    if([representedObject isKindOfClass:[Recipient class]])
    {
        Recipient* rec = (Recipient*)representedObject;
     
        NSArray* emailContacts = [[rec listPossibleEmailContactDetails] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"numberOfTimesContacted" ascending:NO]]];
            for(EmailContactDetail* emailDetail in emailContacts)
            {
                NSMenuItem* menuItem = [[NSMenuItem alloc] initWithTitle:emailDetail.address action:@selector(chooseEmailFromMenu:) keyEquivalent:@""];
                [menu addItem:menuItem];
                [menuItem setTarget:rec];
                if([[[rec displayEmail] lowercaseString] isEqualToString:[emailDetail.address lowercaseString]])
                    [menuItem setState:NSOnState];
                else
                    [menuItem setState:NSOffState];
            }
     }
    return menu;
}

- (BOOL)tokenField:(NSTokenField *)tokenField hasMenuForRepresentedObject:(id)representedObject
{
    return YES;
}

- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject
{
    if([representedObject isKindOfClass:[Recipient class]])
    {
        Recipient* rec = (Recipient*)representedObject;
        return [rec displayName];
    }
    return nil;
}

- (NSRect)splitView:(NSSplitView *)splitView effectiveRect:(NSRect)proposedEffectiveRect forDrawnRect:(NSRect)drawnRect ofDividerAtIndex:(NSInteger)dividerIndex
{
    return NSZeroRect;
}

- (void)arrangeFields
{
    [self.window layoutIfNeeded];
}

/**CALL ON MAIN*/
- (void)showMessageInstance:(EmailMessageInstance*)messageInstance
{
    [ThreadHelper ensureMainThread];

    [self setShownMessageInstance:messageInstance];

    if(messageInstance)
    {
        EmailMessage* message = messageInstance.message;

        [self showMessage:message];


    }
    else
        NSLog(@"No message to display in separate window!!!");
}

- (void)showMessage:(EmailMessage*)message
{
    [self setShownMessage:message];

    [self.fromField setType:TYPE_FROM];
    [self.fromField setTokenLimit:1];

    [self.replyToField setType:TYPE_REPLY_TO];
    [self.replyToField setTokenLimit:1];

    [self.toField setType:TYPE_TO];
    [self.ccField setType:TYPE_CC];
    [self.bccField setType:TYPE_BCC];

    [self.cautionButton setHidden:YES];

    if(message.messageData.subject)
        [subjectField setStringValue:message.messageData.subject];

    if(message.messageData.htmlBody)
        [bodyView.mainFrame loadHTMLString:message.messageData.htmlBody baseURL:nil];
    else
        [bodyView.mainFrame loadHTMLString:NSLocalizedString(@"Downloading message body...",nil) baseURL:nil];

    NSDate* date = message.dateSent;

    [dateField setStringValue:date?[NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]:@""];


    if([message isSafe])
    {
        [self.window setTitle:[NSString stringWithFormat:NSLocalizedString(@"Safe message from %@",@"Safe msg subject <sender name>"), message.messageData.fromName]];
    }
    else
        [self.window setTitle:[NSString stringWithFormat:NSLocalizedString(@"Open message from %@",@"name"), message.messageData.fromName]];


    //        [self setAttachmentList:[messageInstance.message.allAttachments sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"contentid" ascending:YES]]]];
    //        [self setHasAttachments:messageInstance.message.allAttachments.count>0];

    [self.attachmentsView showAttachments:message.allAttachments];

    //        [self.attachmentViewHeightConstraint setConstant:message.allAttachments.count?120:0];

    NSArray* recArray = nil;

    NSData* recData = message.messageData.addressData;

    recArray = [AddressDataHelper recipientsForAddressData:recData];

    //show the user's own address first(!)
    NSArray* sortedRecipients = [recArray sortedArrayUsingComparator:^NSComparisonResult(Recipient* rec1, Recipient* rec2) {
        BOOL rec1IsMine = [rec1.displayEmail isUsersAddress];
        BOOL rec2IsMine = [rec2.displayEmail isUsersAddress];

        if(rec1IsMine && !rec2IsMine)
            return NSOrderedAscending;

        if(!rec1IsMine && rec2IsMine)
            return NSOrderedDescending;

        return [rec1.displayEmail compare:rec2.displayEmail];
    }];

    [self.fromField setRecipients:sortedRecipients filterByType:YES];

    if([AddressDataHelper shouldShowReplyToForMessage:message])
    {
        replyToTrailingEdgeConstraint.priority = 999;
        fromTrailingEdgeConstraint.priority = 1;
        [self.replyToField addRecipients:sortedRecipients filterByType:YES];
    }
    else
    {
        replyToTrailingEdgeConstraint.priority = 1;
        fromTrailingEdgeConstraint.priority = 999;
    }

    [self.toField setRecipients:sortedRecipients filterByType:YES];
    [self.ccField setRecipients:sortedRecipients filterByType:YES];
    [self.bccField setRecipients:sortedRecipients filterByType:YES];

    if(self.ccField.attributedString.length==0)
    {
        ccHeightConstraint.priority = 999;
        ccSpaceConstraint.constant = 0;
    }
    else
    {
        ccHeightConstraint.priority = 1;
        ccSpaceConstraint.constant = 1;
    }

    if(self.bccField.attributedString.length==0)
    {
        bccHeightConstraint.priority = 999;
        bccSpaceConstraint.constant = 0;
    }
    else
    {
        bccHeightConstraint.priority = 1;
        bccSpaceConstraint.constant = 1;
    }


    [numberOfAttachmentsLabel setStringValue:message.allAttachments.count>0?[NSString stringWithFormat:@"%ld",message.allAttachments.count]:@""];

    [self.window layoutIfNeeded];

    if([message isSafe])
    {
        [lockImage setImage:[NSImage imageNamed:@"secureLockWhite32.png"]];

        [safeLabel setStringValue:NSLocalizedString(@"Safe", @"Safe,secure email")];

        MynigmaFeedback* feedback = [message feedback];

        if([feedback isWarning])
        {
            //the decryption status indicates an error
            [self.topBox setFillColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"envelopeMarginYellow"]]];
            [self.cautionButton setHidden:NO];

            //TO DO:
            //deal with special cases
            //display appropriate warning

            //MynigmaDecryptionError* error = [MynigmaDecryptionError decryptionErrorWithCode:[(MynigmaMessage*)message decryptionStatus].integerValue];
        }
        else
        {
            [self.topBox setFillColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"envelopeMarginGreenCombined.png"]]];

            [self.cautionButton setHidden:YES];
        }
    }
    else
    {
        [lockImage setImage:[NSImage imageNamed:@"openLockWhite32.png"]];

        [safeLabel setStringValue:NSLocalizedString(@"Open email", @"Open,Unsecure email message")];

        //[self.topBox setFillColor:OPEN_DARK_COLOUR];

        NSImage* patternImage = [NSImage imageNamed:@"envelopeMarginRedCombined.png"];

        //[patternImage setScalesWhenResized:YES];

        [self.topBox setFillColor:[NSColor colorWithPatternImage:patternImage]];
    }

    [self arrangeFields];
}

- (IBAction)cautionButtonClicked:(id)sender
{
    MynigmaMessage* message = (MynigmaMessage*)self.shownMessage;

    if([message isKindOfClass:[MynigmaMessage class]])
    {
        MynigmaFeedback* feedback = [message feedback];

        [NSApp presentError:feedback modalForWindow:self.window delegate:message didPresentSelector:@selector(didPresentErrorWithRecovery:contextInfo:) contextInfo:nil];
    }
}


- (void)adjustTokenFieldHeight:(NSTokenField*)tokenField
{
    /*
     NSBox* box = (NSBox*)tokenField.superview.superview;
     CGFloat boxInset = 10;//box.frame.size.height-tokenField.frame.size.height;
     
     NSRect oldFrame = [tokenField frame];
     NSRect newFrame = oldFrame;
     newFrame.size.height = CGFLOAT_MAX;
     CGFloat height = [tokenField.cell cellSizeForBounds:newFrame].height+boxInset;
     CGFloat boxHeight = height>26?height:26;
     oldFrame = box.frame;
     [box setFrame:NSMakeRect(oldFrame.origin.x,
     oldFrame.origin.y,
     oldFrame.size.width,
     boxHeight)];*/
}



- (void)windowDidResize:(NSNotification *)notification
{
    [self arrangeFields];
    // if(shownMessage && shownMessage.htmlBody)
    //    [bodyView.mainFrame loadHTMLString:shownMessage.htmlBody baseURL:nil];
}

- (IBAction)reply:(id)sender
{
    ComposeWindowController* composeController = [WindowManager showFreshMessageWindow];

    if(self.shownMessageInstance)
        [composeController setFieldsForReplyToMessageInstance:shownMessageInstance];
    else
        [composeController setFieldsForReplyToMessage:self.shownMessage];

    [composeController.window makeFirstResponder:composeController.bodyField];
    [composeController.bodyField selectSentence:self];
}

- (IBAction)replyAll:(id)sender
{
    ComposeWindowController* composeController = [WindowManager showFreshMessageWindow];

    if(self.shownMessageInstance)
        [composeController setFieldsForReplyAllToMessageInstance:shownMessageInstance];
    else
        [composeController setFieldsForReplyAllToMessage:self.shownMessage];

    [composeController.window makeFirstResponder:composeController.bodyField];
    [composeController.bodyField selectSentence:self];
}

- (IBAction)forward:(id)sender
{
    ComposeWindowController* composeController = [WindowManager showFreshMessageWindow];

    if(self.shownMessageInstance)
        [composeController setFieldsForForwardOfMessageInstance:shownMessageInstance];
    else
        [composeController setFieldsForForwardOfMessage:self.shownMessage];
}

- (IBAction)printOff:(id)sender
{
    [bodyView print:self];
}

- (IBAction)openAttachmentList:(id)sender
{
    if(!sheetController)
        sheetController = [[AttachmentListController alloc] initWithWindowNibName:@"AttachmentListController"];
    [NSApp beginSheet:[sheetController window] modalForWindow:self.window modalDelegate:self didEndSelector: @selector(didEndSheet:returnCode:contextInfo:) contextInfo: nil];
    if([sheetController.collectionController.arrangedObjects count])
        [sheetController.collectionController removeObjects:sheetController.collectionController.arrangedObjects];
    for(FileAttachment* attachment in shownMessageInstance.message.allAttachments)
    {
//        AttachmentItem* item = [AttachmentItem new];
//        [item setFileAttachment:attachment];
//
//        NSURL* url = [attachment publicURL];
//        if(!url)
//            url = [attachment privateURL];
//        [item setUrl:url];
//
//        NSString* fileName = attachment.fileName;
//        if(!fileName)
//            fileName = [[url path] lastPathComponent];
//        if(!fileName)
//            fileName = @"";
//
//        [item setName:fileName];
//
//        [item setImage:attachment.thumbnail];

        [sheetController.collectionController addObject:attachment];
    }
    
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{

}

- (void)windowWillClose:(NSNotification*)notification
{
    [WindowManager removeWindow:self];
}



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
    
    if([[actionInformation objectForKey:WebActionNavigationTypeKey] integerValue] == WebNavigationTypeLinkClicked)
    {
        [[NSWorkspace sharedWorkspace] openURL:[request URL]];
    }
    else
        [listener use];
}

- (NSArray*)webView:(WebView*)sender contextMenuItemsForElement:(NSDictionary*)element defaultMenuItems:(NSArray*)defaultMenuItems
{
    return @[];
}

- (IBAction)printDocument:(id)sender
{
    [ThreadHelper ensureMainThread];

    if(self.shownMessageInstance)
        [PrintingHelper printMessageObjects:@[self.shownMessageInstance]];
    else
    {
        NSLog(@"Cannot print: shownMessageInstance is nil!!");
        NSBeep();
    }
}

-(void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    [FormattingHelper addTitleAttributeToAllLinksInWebView:sender];
}


@end
