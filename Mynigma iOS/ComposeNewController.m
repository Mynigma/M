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





#import "ComposeNewController.h"
#import "EmailMessage.h"
#import "TITokenField.h"
#import "AppDelegate.h"
#import "Recipient.h"
#import "EmailRecipient.h"
#import "UserSettings.h"
#import "IMAPAccountSetting+Category.h"
#import "IMAPFolderSetting+Category.h"
#import "MessagesController.h"

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import "TextEntryCell.h"
#import "ShowMessageCell.h"
#import "MynigmaMessage+Category.h"
#import "EmailMessage+Category.h"
#import "ABContactDetail.h"
#import "ShowAllRecipientsCell.h"
#import "IMAPAccount.h"
#import "ContactSuggestions.h"
#import "MynigmaPublicKey+Category.h"
#import "EncryptionHelper.h"
#import "EmailMessageData.h"
#import "EmailMessageInstance+Category.h"
#import "IconListAndColourHelper.h"
#import "AddressDataHelper.h"
#import "FormattingHelper.h"
#import "OutlineObject.h"
#import "MynigmaPrivateKey+Category.h"
#import "SendingManager.h"
#import "MynTokenFieldController.h"
#import "MynTokenIBField.h"
#import "Contact+Category.h"
#import "EmailContactDetail+Category.h"
#import "AccountCreationManager.h"
#import "FileAttachment+Category.h"
#import "PublicKeyManager.h"
#import "EmailMessageController.h"
#import "AttachmentsListPopoverController.h"
#import "PictureManager.h"
#import "AttachmentsDetailListController.h"
#import "BodyInputView.h"
#import "AlertHelper.h"
#import "ViewControllersManager.h"
#import "SelectionAndFilterHelper.h"
#import "CoreDataHelper.h"
#import "NSString+EmailAddresses.h"
#import "UserSettings+Category.h"
#import "MynigmaFeedback.h"
#import "SafeDoorsView.h"
#import "SendAnimation.h"




static int kObservingContentSizeChangesContext;


@interface ComposeNewController ()

@end

@implementation ComposeNewController


#pragma mark - INIT

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}



#pragma mark - UI and actions

- (void)dismissMe
{
    if(self.view.frame.origin.x == 0)
    {
    UIImageView* imageView = [[UIImageView alloc] initWithImage:[self snapshot]];
    
    UIWindow* window = self.view.window;
    
    CGRect newFrame = window.bounds;
    
    newFrame.origin.x += newFrame.size.width;
    
    newFrame = CGRectInset(newFrame, 100, 100);
    
    [window addSubview:imageView];

    [self dismissViewControllerAnimated:NO completion:^{
       
        [imageView setFrame:window.bounds];
        
        [UIView animateWithDuration:2. animations:^{
            
            [imageView setFrame:newFrame];
            
            [[ViewControllersManager sharedInstance] setComposeController:nil];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                AudioServicesPlaySystemSound(1001);
            });
            
        } completion:^(BOOL finished) {
            
            [imageView removeFromSuperview];
        }];
    }];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:^{
            
            
        }];
    }
}

// Snapshot for dismiss animation
- (UIImage *)snapshot
{
    UIGraphicsBeginImageContextWithOptions(self.view.window.bounds.size, YES, 0);
    [self.view.window drawViewHierarchyInRect:self.view.window.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

// Called after send button is clicked
// animates doors on safe messages and calls dismiss
- (void)playSwishSoundAndMoveOutWindow
{

    [self.view endEditing:YES];
    
    if(self.isSafeMessage)
    {
        [self.doorsView closeDoorsAnimated:YES completion:^(BOOL completed)
        {
            [self performSelector:@selector(dismissMe) withObject:nil afterDelay:.4];
        }];
    }
    else
    {
        [self dismissMe];
    }
}

// removes the send button from right toolbar
// used after send button clicked, to prevent multiple clicks
- (void)removeSendButton
{
    NSMutableArray* toolbarItems = [self.navigationItem.rightBarButtonItems mutableCopy];
    
    if([toolbarItems containsObject:self.sendButton])
    {
        [toolbarItems removeObject:self.sendButton];
        [self.navigationItem setRightBarButtonItems:toolbarItems];
    }
}

// method to adde the send button again.
// maybe for future use
- (void)addSendButton
{
    NSMutableArray* toolbarItems = [self.navigationItem.rightBarButtonItems mutableCopy];
    
    if(self.sendButton && ![toolbarItems containsObject:self.sendButton])
    {
        [toolbarItems addObject:self.sendButton];
        [self.navigationItem setRightBarButtonItems:toolbarItems];
    }
}


#pragma mark Popover handling

// used to show the image picker popover
- (void)showPopoverFromAttachmentsButton:(UIViewController*)displayedViewController
{
    [self.popover dismissPopoverAnimated:NO];
    self.popover = [[UIPopoverController alloc] initWithContentViewController:displayedViewController];
    if(self.attachmentsButton.superview.window)
        [self.popover presentPopoverFromRect:self.attachmentsButton.frame inView:self.attachmentsButton.superview permittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
}

// used to hide the image picker popover
- (void)hidePopover
{
    [self.popover dismissPopoverAnimated:YES];
    self.popover = nil;
}


#pragma mark Quoted text

// uncollapses quoted text
- (IBAction)showQuotedTextButtonTapped:(id)sender
{
    [UIView animateWithDuration:.4 animations:^{
        
        [self.showQuotedTextButton setHidden:YES];
        [self.bodyView setHidden:NO];
        [self adjustWidthAndScrollViewHeight];
        
    }];
}

#pragma mark - Saving & sending

// Save the current message
// options: overwrite previous copy, make safe, rdy for sending (different encryption key)
- (void)saveMessageByOverwritingPreviousCopy:(BOOL)overwrite asSafe:(BOOL)shouldBeSafe forSending:(BOOL)isForSending withCallback:(void(^)(BOOL success))callback
{
    [ThreadHelper ensureMainThread];
    
    Recipient* fromRecipient = nil;
    
    if(self.fromView.recipients.count>0)
    {
        fromRecipient = self.fromView.recipients[0];
    }
    else
        fromRecipient = [AddressDataHelper standardSenderAsRecipient];
    
    IMAPAccountSetting* fromAccountSetting = nil;
    
    for(IMAPAccountSetting* accountSetting in [UserSettings usedAccounts])
    {
        if([accountSetting.senderEmail isEqual:fromRecipient.displayEmail])
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
    
    
    EmailMessage* newMessage = [EmailMessage newDraftMessageInContext:MAIN_CONTEXT];
    
    if(!shouldBeSafe)
        newMessage = [(MynigmaMessage*)newMessage turnIntoOpenMessageInContext:MAIN_CONTEXT];
    
    EmailMessageInstance* newInstance = [EmailMessageInstance findOrMakeNewInstanceForMessage:newMessage inFolder:draftsFolder inContext:MAIN_CONTEXT];
    
    [newMessage setDateSent:[NSDate date]];
    
    [newInstance setFlags:[NSNumber numberWithInt:MCOMessageFlagDraft|MCOMessageFlagSeen]];
    [newInstance setAddedToFolder:newInstance.inFolder];
    
    [newInstance changeUID:nil];
    
    if(overwrite && !self.composedMessageInstance.isDeleted)
        [self.composedMessageInstance moveToBinOrDelete];
    
    [self setComposedMessageInstance:newInstance];
    
    
    NSArray* recipients = [self recipients];
    
    //set the searchString so that the message can be found by search
    NSMutableString* newSearchString = [[NSMutableString alloc] initWithString:@""];
    
    for(Recipient* rec in recipients)
    {
        if([rec isKindOfClass:[Recipient class]])
        {
            if(rec.displayEmail)
                [newSearchString appendFormat:@"%@,",[rec.displayEmail lowercaseString]];
            if(rec.displayName)
                [newSearchString appendFormat:@"%@,",[rec.displayName lowercaseString]];
        }
        
        if(rec.type==TYPE_FROM)
            [newMessage.messageData setFromName:rec.displayName?rec.displayName:@""];
    }
    
    [newMessage setSearchString:newSearchString];
    
    [newMessage.messageData setAddressData:[AddressDataHelper addressDataForRecipients:recipients]];
    
    [newMessage.messageData setLoadRemoteImages:[NSNumber numberWithBool:YES]];
    
    [newMessage.messageData setSubject:self.subjectField.text];
    
    NSString* editViewPlainString = self.editView.text;
    
    if(!editViewPlainString)
        editViewPlainString = @"";
    
    NSString* bodyViewPlainString = [self.bodyView stringByEvaluatingJavaScriptFromString:@"document.body.innerText"];
    
    if(!bodyViewPlainString)
        bodyViewPlainString = @"";
    
    NSString* editViewHTMLString = [FormattingHelper getsavableHTMLFromTextView:self.editView];
    
    if(!editViewHTMLString)
        editViewHTMLString = @"";
    
    NSString* bodyViewHTMLString = [FormattingHelper getSavableHTMLFromWebView:self.bodyView];
    
    if(!bodyViewHTMLString)
        bodyViewHTMLString = @"";
    
    NSString* bodyString = [NSString stringWithFormat:@"%@%@", editViewPlainString, bodyViewPlainString];
    NSString* HTMLString = [NSString stringWithFormat:@"%@%@", editViewHTMLString, bodyViewHTMLString];
    
    [newMessage.messageData setBody:bodyString];
    [newMessage.messageData setHtmlBody:HTMLString];
    
    
    for(FileAttachment* fileAttachment in self.allAttachments)
    {
        FileAttachment* freshAttachment = fileAttachment;
        
        if(fileAttachment.attachedAllToMessage)
        {
            //the attachment is already attached to a message
            //shouldn't be hugely surprising, nor a major problem...
            //NSLog(@"Attachment is already assigned to a different message!! Fixing by creating a copy...");
            
            freshAttachment = [fileAttachment copyInContext:MAIN_CONTEXT];
        }
        
        [newMessage addAllAttachmentsObject:freshAttachment];
        
        if([self.attachments containsObject:freshAttachment])
            [newMessage addAttachmentsObject:freshAttachment];
        
        if(!freshAttachment.contentType)
            [freshAttachment setContentType:@"application/octet-stream"];
    }
    
    [CoreDataHelper save];
    
    //BOOL usesMynigma = [self willBeSentAsSafe];   //TO DO: ensure messages whose recipients include both safe and unsafe recipients are encrypted for safe recipients!
    
    if(shouldBeSafe)
    {
        if(![self.composedMessageInstance.message isKindOfClass:[MynigmaMessage class]])
        {
            self.composedMessageInstance.message = [self.composedMessageInstance.message turnIntoSafeMessageInContext:MAIN_CONTEXT];
        }
        if(isForSending)
        {
            
            [(MynigmaMessage*)self.composedMessageInstance.message encryptForSendingWithCallback:^(MynigmaFeedback* feedback) {
                
                [self setIsDirty:NO];
                
                if(callback)
                    callback(feedback.isSuccess);
            }];
            
        }
        else
        {
            //need to encrypt as draft (may not have all the necessary key labels and/or attachments)
            [(MynigmaMessage*)self.composedMessageInstance.message encryptAsDraftWithCallback:^(MynigmaFeedback* feedback) {
                
                [self setIsDirty:NO];
                
                if(callback)
                    callback(feedback.isSuccess);
            }];
            
        }
    }
    else
    {
        [self setIsDirty:NO];
        if(callback)
            callback(YES);
    }
}


/* CALL ON MAIN */
// This sends the message and handels the result from SendingManager
// also calls to dismiss animation
- (void)sendItNow:(EmailMessageInstance*)messageInstance
{
    [ThreadHelper ensureMainThread];
    
    IMAPAccount* imapAccount = [AddressDataHelper sendingAccountForMessage:messageInstance.message];
    
    if(imapAccount)
    {
        [self playSwishSoundAndMoveOutWindow];
        
        [SendingManager sendDraftMessageInstance:messageInstance fromAccount:imapAccount withCallback:^(NSInteger result, NSError* error){
            
            if(result==-1){
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:error.localizedDescription message:NSLocalizedString(@"The message will kept in your outbox and sent automatically as soon as possible.",@"AlertWindow") delegate:self cancelButtonTitle:NSLocalizedString(@"OK","OK button") otherButtonTitles:nil];
                
                [alert show];
            }
            else if(result==-8)
            {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"There was an error sending your message.",@"AlertWindow") message:[NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"Please check your current SMTP settings.",@"AlertWindow"),NSLocalizedString(@"The message will kept in your outbox and sent automatically as soon as possible.",@"AlertWindow")] delegate:self cancelButtonTitle:NSLocalizedString(@"OK","OK button") otherButtonTitles:nil];
                
                [alert show];
            }
            else if(result<0)
            {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"There was an error sending your message.",@"AlertWindow") message:NSLocalizedString(@"The message will kept in your outbox and sent automatically as soon as possible.",@"AlertWindow") delegate:self cancelButtonTitle:NSLocalizedString(@"OK","OK button") otherButtonTitles:nil];
                
                [alert show];
            }
            if(result==1)
            {
                
                //if the message is a reply, mark the original message as replied to
                if(self.replyToMessageInstance)
                {
                    [self.replyToMessageInstance setFlags:@(self.replyToMessageInstance.flags.intValue | MCOMessageFlagAnswered)];
                    [self.replyToMessageInstance setFlagsChangedInFolder:self.replyToMessageInstance.folderSetting];
                }
                
                //the analogous thing for forwarded messages
                if(self.forwardOfMessageInstance)
                {
                    [self.forwardOfMessageInstance setFlags:@(self.forwardOfMessageInstance.flags.intValue | MCOMessageFlagForwarded)];
                    [self.forwardOfMessageInstance setFlagsChangedInFolder:self.forwardOfMessageInstance.folderSetting];
                }
            }
            
            [self.autosaveTimer invalidate];
            
            [[ViewControllersManager sharedInstance] setComposeController:nil];
        }];
    }
    else
        NSLog(@"No account set for account setting ID!!!! MODEL.accounts: %@, MODEL.currentUserSettings.accounts: %@", [AccountCreationManager sharedInstance].allAccounts, [UserSettings currentUserSettings].accounts);
}

// IBAction for send button
// Send button is removed
// Saves new instance and calls "sendItNow"
// also increments contacts number of times contacted
- (IBAction)sendMessage:(id)sender
{
    [self removeSendButton];
    
    NSArray* recipients = [self recipients];
    
    for(Recipient* rec in recipients)
    {
        if(rec.type==TYPE_TO || rec.type==TYPE_CC || rec.type==TYPE_BCC)
        {
            EmailContactDetail* contactDetail = [EmailContactDetail emailContactDetailForAddress:rec.displayEmail];
            
            if(contactDetail)
            {
                if(!contactDetail.numberOfTimesContacted)
                    [contactDetail setNumberOfTimesContacted:@0];
                
                [contactDetail setNumberOfTimesContacted:@(contactDetail.numberOfTimesContacted.integerValue+1)];
            }
        }
    }
    
    //always need to save a new instance, since the current one may be encrypted as a draft, rather than for sending
    [self saveMessageByOverwritingPreviousCopy:YES asSafe:self.isSafeMessage forSending:YES withCallback:^(BOOL success) {
        
        if(!success)
        {
            NSLog(@"Failed to encrypt message before sending!!!");
            [AlertHelper showAlertWithMessage:NSLocalizedString(@"An error occurred.", @"Generic error") informativeText:NSLocalizedString(@"We regret that Mynigma was unable to send your message. Please submit a bug report to help us fix the problem. Thank you!", @"Saving message before sending failed")];
            //NSBeep();
        }
        else
        {
            [MAIN_CONTEXT performBlock:^{
                //the composedMessageInstance is now set to the new, saved message
                [self sendItNow:self.composedMessageInstance];
            }];
        }
        
    }];
    //    else
    //    {
    //        [self sendItNow:self.composedMessageInstance];
    //    }
}

// auto save timer triggered
- (void)autosave:(NSTimer*)timer
{
    [self saveMessageByOverwritingPreviousCopy:YES asSafe:self.isSafeMessage forSending:NO withCallback:^(BOOL success) {
        
        if(!success)
        {
            NSLog(@"Failed to encrypt message while autosaving!!!");
            
            //it's an autosave, so don't keep bothering the user with error messages
            //[APPDELEGATE showAlertWithMessage:NSLocalizedString(@"An error occurred.", @"Generic error") informativeText:NSLocalizedString(@"We regret that Mynigma was unable to save your message. Please submit a bug report to help us fix the problem. Thank you!", @"Saving message failed")];
            //NSBeep();
        }
        else
        {
            
        }
        
    }];
}

#pragma mark - Attachments

// Updates the attachment number
- (void)updateAttachmentNumber
{
    NSInteger attachmentNumber = self.allAttachments.count;
    
    if(attachmentNumber==0)
    {
        [self.numberOfAttachmentsButton setTitle:@"+" forState:UIControlStateNormal];
    }
    else
    {
        NSString* attachmentNumberString = [NSString stringWithFormat:@"%ld", (long)attachmentNumber];
        
        [self.numberOfAttachmentsButton setTitle:attachmentNumberString forState:UIControlStateNormal];
    }
}

// Called by PictureManager
// Do not attach to message yet
- (void)addPhotoAttachmentWithData:(NSData*)imageData
{
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"FileAttachment" inManagedObjectContext:MAIN_CONTEXT];
    
    FileAttachment* newAttachment = [[FileAttachment alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];
    
    [newAttachment setContentType:@"image/png"];
    [newAttachment setDownloadProgress:@1.1];
    [newAttachment setSize:@(imageData.length)];
    
    [self.allAttachments addObject:newAttachment];
    [self.attachments addObject:newAttachment];
    
    NSInteger numberOfAttachments = self.allAttachments.count;
    NSString* newAttachmentName = numberOfAttachments==0?NSLocalizedString(@"Photo.png", @"Added photo name"):[NSString stringWithFormat:NSLocalizedString(@"Photo %ld.png", @"Added photo name with number"), numberOfAttachments+1];
    [newAttachment setFileName:newAttachmentName];
    
    [newAttachment setName:newAttachmentName];
    
    //now save the data to a private bookmark
    [newAttachment saveDataToPrivateURL:imageData];
    
    [self updateAttachmentNumber];
}


#pragma mark - Safe/open

// Updates isSafeMessage
// refreshs coloring and lock image
- (void)updateSafeOrOpenStatus
{
    NSArray* recArray = [self recipients];
    
    BOOL result = [Recipient recipientListIsSafe:recArray];
    
    [self setIsSafeMessage:result];
    
    [self setCorrectColour];
}


#pragma mark - Setup message

- (void)showFreshEmptyMessage
{
    [ThreadHelper ensureMainThread];
    
    Recipient* sender = [AddressDataHelper standardSenderAsRecipient];
    
    [self.fromView removeAllTokens];
    
    [self.fromView addTokenWithTitle:sender.displayName representedObject:sender];
    
    IMAPAccountSetting* fromAccountSetting = [AddressDataHelper senderAccountSetting];
    
    NSString* HTMLEmailWithFooter = [FormattingHelper emptyEmailWithFooter:fromAccountSetting.footer];
    
    HTMLEmailWithFooter = [FormattingHelper prepareHTMLContentForDisplay:HTMLEmailWithFooter makeEditable:YES];
    
    [self.bodyView loadHTMLString:HTMLEmailWithFooter baseURL:nil];
    
    [self updateAttachmentNumber];
}

- (void)showNewFeedbackMessageInstance
{
    //EmailMessage* newDraftMessage = [EmailMessage newDraftMessageInContext:MAIN_CONTEXT];
    
    IMAPAccountSetting* fromAccountSetting = [AddressDataHelper senderAccountSetting];
    
    Recipient* myselfFrom = [[Recipient alloc] initWithEmail:fromAccountSetting.senderEmail andName:fromAccountSetting.senderName];
    
    [myselfFrom setType:TYPE_FROM];
    
    EmailMessageInstance* newMessageInstance = [FormattingHelper freshComposedMessageInstanceWithSenderRecipient:myselfFrom];
    
    [self setComposedMessageInstance:newMessageInstance];
    
    NSString* HTMLEmailWithFooter = [FormattingHelper emptyEmailWithFooter:nil];
    
    HTMLEmailWithFooter = [FormattingHelper prepareHTMLContentForDisplay:HTMLEmailWithFooter makeEditable:YES];
    
    [newMessageInstance.message.messageData setHtmlBody:HTMLEmailWithFooter];
    
    [newMessageInstance.message.messageData setSubject:NSLocalizedString(@"Feedback", @"Feedback message")];
    
    Recipient* recipient = [[Recipient alloc] initWithEmail:@"info@mynigma.org" andName:@"Mynigma info"];
    
    [recipient setType:TYPE_TO];
    
    if(![recipient isSafe])
        [PublicKeyManager addMynigmaInfoPublicKey];
    
    NSArray* recipients = @[myselfFrom, recipient];
    
    NSData* newAddressData = [AddressDataHelper addressDataForRecipients:recipients];
    
    [newMessageInstance.message.messageData setAddressData:newAddressData];
    
    [newMessageInstance.message.messageData setFromName:recipient.displayName];
    
    
    NSMutableString* newSearchString = [NSMutableString new];
    
    for(Recipient* rec in recipients)
    {
        if([rec isKindOfClass:[Recipient class]])
        {
            if(rec.displayEmail)
                [newSearchString appendFormat:@"%@,",[rec.displayEmail lowercaseString]];
            if(rec.displayName)
                [newSearchString appendFormat:@"%@,",[rec.displayName lowercaseString]];
        }
    }
    
    [newMessageInstance.message setSearchString:newSearchString];
    
    [(MynigmaMessage*)newMessageInstance.message encryptAsDraftWithCallback:nil];
    
    [self fillDisplayWithComposedMessageInstance];
}


/**CALL ON MAIN*/
- (void)showDraftMessageInstance:(EmailMessageInstance*)messageInstance
{
    [ThreadHelper ensureMainThread];
    
    [self setComposedMessageInstance:messageInstance];
    
    EmailMessage* message = messageInstance.message;
    
    [self.subjectField setText:message.messageData.subject?message.messageData.subject:@""];
    NSData* recData = message.messageData.addressData;
    NSArray* recArray = [AddressDataHelper recipientsForAddressData:recData];
    
    //Recipient* fromRecipient = nil;
    //Recipient* replyToRecipient = nil;
    
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
    
    for(Recipient* rec in sortedRecipients)
    {
        if(rec.type == TYPE_TO)
            [self.toView addTokenWithTitle:rec.displayName representedObject:rec];
        //if(rec.type == TYPE_FROM)
        //    [self.fromView addTokenWithTitle:rec.displayName representedObject:rec];
        if(rec.type == TYPE_CC)
            [self.ccView addTokenWithTitle:rec.displayName representedObject:rec];
        if(rec.type == TYPE_BCC)
            [self.bccView addTokenWithTitle:rec.displayName representedObject:rec];
    }
    
    [self.toView setHidden:NO];
    [self.fromView setHidden:NO];
    [self.ccView setHidden:NO];
    [self.bccView setHidden:NO];
    [self.replyToView setHidden:NO];
    
    
    [self updateSafeOrOpenStatus];
    
    
    [self updateAttachmentNumber];
    
    [self.editView setText:@""];
    
    NSString* htmlBody = [FormattingHelper prepareHTMLContentForDisplay:message.messageData.htmlBody makeEditable:YES];
    
    [self.bodyView loadHTMLString:htmlBody baseURL:nil];
}

- (void)setFieldsForReplyToMessage:(EmailMessage*)message
{
    [self setComposedMessageInstance:[FormattingHelper replyToMessage:message]];
    
    [self fillDisplayWithComposedMessageInstance];
}

- (void)setFieldsForReplyAllToMessage:(EmailMessage*)message
{
    [self setComposedMessageInstance:[FormattingHelper replyAllToMessage:message]];
    
    [self fillDisplayWithComposedMessageInstance];
}

- (void)setFieldsForForwardOfMessage:(EmailMessage*)message
{
    [self setComposedMessageInstance:[FormattingHelper forwardOfMessage:message]];
    
    [self fillDisplayWithComposedMessageInstance];
}




#pragma mark - Recipients and display setup

- (NSArray*)recipients
{
    NSMutableArray* recipients = [NSMutableArray new];

    for(Recipient* rec in self.replyToView.recipients)
    {
        if([rec isKindOfClass:[Recipient class]])
        {
            [rec setType:TYPE_REPLY_TO];
            [recipients addObject:rec];
        }
    }
    for(Recipient* rec in self.toView.recipients)
    {
        if([rec isKindOfClass:[Recipient class]])
        {
            [rec setType:TYPE_TO];
            [recipients addObject:rec];
        }
    }
    for(Recipient* rec in self.ccView.recipients)
    {
        if([rec isKindOfClass:[Recipient class]])
        {
            [rec setType:TYPE_CC];
            [recipients addObject:rec];
        }
    }
    for(Recipient* rec in self.bccView.recipients)
    {
        if([rec isKindOfClass:[Recipient class]])
        {
            [rec setType:TYPE_BCC];
            [recipients addObject:rec];
        }
    }
    for(Recipient* rec in self.fromView.recipients)
    {
        if([rec isKindOfClass:[Recipient class]])
        {
            [rec setType:TYPE_FROM];
            [recipients addObject:rec];
        }
    }

    return recipients;
}

- (void)fillDisplayWithComposedMessageInstance
{
    self.isDirty = NO;
    
    //    if(!self.forwardOfMessageInstance)
    //        [self.window makeFirstResponder:self.bodyField];
    //
    [self setAllAttachments:[[self.composedMessageInstance.message.allAttachments sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"fileName" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"contentid" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"uniqueID" ascending:YES]]] mutableCopy]];
    
    [self setAttachments:[[self.composedMessageInstance.message.attachments sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"fileName" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"contentid" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"uniqueID" ascending:YES]]] mutableCopy]];
    
    [self updateAttachmentNumber];
    
    if(self.composedMessageInstance)
    {
        
        NSData* recData = self.composedMessageInstance.message.messageData.addressData;
        
        //make sure there is a sender recipient
        [AddressDataHelper senderAsEmailRecipientForMessage:self.composedMessageInstance.message addIfNotFound:YES];
        
        NSArray* recArray = [AddressDataHelper recipientsForAddressData:recData];
        
        
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
        
        
        for(Recipient* rec in sortedRecipients)
        {
            if(rec.type == TYPE_TO)
                [self.toView addTokenWithTitle:rec.displayName representedObject:rec];
            //if(rec.type == TYPE_FROM)
            //    [self.fromView addTokenWithTitle:rec.displayName representedObject:rec];
            if(rec.type == TYPE_CC)
                [self.ccView addTokenWithTitle:rec.displayName representedObject:rec];
            if(rec.type == TYPE_BCC)
                [self.bccView addTokenWithTitle:rec.displayName representedObject:rec];
        }
        
        [self.toView setHidden:NO];
        [self.fromView setHidden:NO];
        [self.ccView setHidden:NO];
        [self.bccView setHidden:NO];
        [self.replyToView setHidden:NO];
        
        
        [self updateSafeOrOpenStatus];
        
        NSString* subject = self.composedMessageInstance.message.messageData.subject;
        
        if(!subject)
            subject = @"";
        
        [self.subjectField setText:subject];
        
        [self.editView setText:@""];
        
        NSString* htmlBody = [FormattingHelper prepareHTMLContentForDisplay:self.composedMessageInstance.message.messageData.htmlBody makeEditable:YES];
        
        [self.bodyView loadHTMLString:htmlBody baseURL:nil];
        
        
        //IMAPAccountSetting* fromAccountSetting = [AddressDataHelper sendingAccountSettingForMessage:self.composedMessageInstance.message];
        
        //[FormattingHelper changeHTMLEmail:self.bodyField.mainFrameDocument toFooter:fromAccountSetting.footer];
        
    }
}


#pragma mark - WebView editing delegate

- (void)webViewDidChange:(NSNotification *)notification
{
    self.isDirty = YES;
}



#pragma mark - LOADING


//the view loaded. set up the token fields, body etc...
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.doorsView openDoorsAnimated:NO];
    
    self.allAttachments = [NSMutableArray new];
    self.attachments = [NSMutableArray new];
    
    [[ViewControllersManager sharedInstance] setComposeController:self];
    
    [self.attachmentsViewHeightConstraint setConstant:0];
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    if(UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
        [self.widthConstraint setConstant:screenBounds.size.width];
    else
        [self.widthConstraint setConstant:screenBounds.size.height];
    
    [self.toView setPrompt:NSLocalizedString(@"To:",@"To lable (recipient)")];
    [self.fromView setPrompt:NSLocalizedString(@"From:",@"From lable (sender)")];
    [self.ccView setPrompt:NSLocalizedString(@"Cc:",@"Cc lable (recipient)")];
    [self.bccView setPrompt:NSLocalizedString(@"Bcc:",@"Bcc lable (recipient)")];
    [self.replyToView setPrompt:NSLocalizedString(@"Reply To:",@"Reply To lable (sender)")];
    
    if([self.bodyView isKindOfClass:[BodyInputView class]])
        [(BodyInputView*)self.bodyView removeInputAccessoryView];
    
    [self.fromView.tokenFieldController.tokenField setUsePreparedResults:YES];
    
    //the address data of the current composed message instance will be changed when tokens are added, to save it for later use
    NSData* addressData = self.composedMessageInstance.message.messageData.addressData;
    
    //find the sender information and add it as a token
    Recipient* senderRecipient = [AddressDataHelper senderAsRecipientForMessage:self.composedMessageInstance.message addIfNotFound:YES];
    
    [self.fromView addTokenWithTitle:senderRecipient.displayName representedObject:senderRecipient];
    
    //set up the 'From:' token field with all possible sender addresses
    NSMutableArray* senderAddresses = [NSMutableArray new];
    
    for(IMAPAccountSetting* accountSetting in [UserSettings currentUserSettings].accounts)
    {
        NSString* email = accountSetting.senderEmail;
        NSString* name = accountSetting.senderName;
        
        Recipient* recipient = [[Recipient alloc] initWithEmail:email andName:name];
        
        // Set correct type
        [recipient setType:TYPE_FROM];
        
        [senderAddresses addObject:recipient];
    }
    
    [self.fromView.tokenFieldController.tokenFieldView setSourceArray:senderAddresses];
    [self.fromView.tokenFieldController.tokenFieldView setForcePickSearchResult:YES];
    
    //if the message is a reply/forward, then a new composedMessageInstance with the correct address information and body has already been set up
    if(self.composedMessageInstance)
    {
        //go through the recipients and fill the token fields
        NSArray* recipientArray = [AddressDataHelper recipientsForAddressData:addressData];
        
        for(Recipient* rec in recipientArray)
        {
            if(rec.type == TYPE_TO)
                [self.toView addTokenWithTitle:rec.displayName representedObject:rec];
            //if(rec.type == TYPE_FROM)
            //    [self.fromView addTokenWithTitle:rec.displayName representedObject:rec];
            if(rec.type == TYPE_CC)
                [self.ccView addTokenWithTitle:rec.displayName representedObject:rec];
            if(rec.type == TYPE_BCC)
                [self.bccView addTokenWithTitle:rec.displayName representedObject:rec];
        }
        
        [self.toView setHidden:NO];
        [self.fromView setHidden:NO];
        [self.ccView setHidden:YES];
        [self.bccView setHidden:YES];
        [self.replyToView setHidden:YES];
        
        //set the subject
        [self.subjectField setText:self.composedMessageInstance.message.messageData.subject];
        
        if(self.forwardOfMessageInstance || self.replyToMessageInstance)
        {
            NSString* htmlBody = [FormattingHelper prepareHTMLContentForDisplay:self.composedMessageInstance.message.messageData.htmlBody makeEditable:YES];
            
            [self.editView setText:@""];
            [self.hideEditFieldConstraint setPriority:1];
            
            
            [self.bodyView loadHTMLString:htmlBody baseURL:nil];
            
            [self.showQuotedTextButton setHidden:NO];
            
            if([self.bodyView respondsToSelector:@selector(makeInvisible)])
                [self.bodyView makeInvisible];
            else
            {
                NSLog(@"Body view of type UIWebView!");
                [self.bodyView setHidden:YES];
            }
        }
        else
        {
            [self.showQuotedTextButton setHidden:YES];
            
            [self.editView setText:@""];
            [self.hideEditFieldConstraint setPriority:999];
            
            //load the HTML part into the bodyView
            NSString* htmlBody = [FormattingHelper prepareHTMLContentForDisplay:self.composedMessageInstance.message.messageData.htmlBody makeEditable:YES];
            if(htmlBody.length)
                [self.bodyView loadHTMLString:htmlBody baseURL:nil];
            else
            {
                if([self.bodyView respondsToSelector:@selector(makeInvisible)])
                    [self.bodyView makeInvisible];
                else
                {
                    NSLog(@"Body view of type UIWebView!");
                    [self.bodyView setHidden:YES];
                }
            }
        }
        
    }
    else
    {
        // compose message will be created while saving
        
        [self.editView setAttributedText:nil];
        [self.hideEditFieldConstraint setPriority:1];
        
        
        [self.toView setHidden:NO];
        [self.fromView setHidden:NO];
        [self.ccView setHidden:YES];
        [self.bccView setHidden:YES];
        [self.replyToView setHidden:YES];
        
        //not a reply or anything - no need to quote
        [self.showQuotedTextButton setHidden:YES];
        
        if([self.bodyView respondsToSelector:@selector(makeInvisible)])
            [self.bodyView makeInvisible];
        else
        {
            NSLog(@"Body view of type UIWebView!");
            [self.bodyView setHidden:YES];
        }
    }
    
    [self updateAttachmentNumber];
    
    [self.bodyView.scrollView setBounces:NO];
    [self.bodyView.scrollView setScrollEnabled:NO];
    
    [self.bodyView setNeedsLayout];
    [self.bodyView layoutIfNeeded];
    
    [self.editView setNeedsLayout];
    [self.editView layoutIfNeeded];
    
    [self setCorrectColour];
    
    self.autosaveTimer = [NSTimer timerWithTimeInterval:5*60 target:self selector:@selector(autosave:) userInfo:nil repeats:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector (keyboardWillShow:)
                                                 name: UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector (keyboardWillHide:)
                                                 name: UIKeyboardWillHideNotification object:nil];
    
    //    [self startObservingContentSizeChangesInWebView:self.bodyView];
    
    [self adjustWidthAndScrollViewHeight];
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
    // if there is already a recipient, one wants to write the message
    if ([[self.toView.tokenFieldController.tokenField tokens] count])
        [self.editView becomeFirstResponder];
    else
        [self.toView.tokenFieldController.tokenField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if([ViewControllersManager sharedInstance].messagesController)
    {
        [[ViewControllersManager sharedInstance].messagesController addComposeNewButton];
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - KEYBOARD

- (void)keyboardWillShow: (NSNotification *)aNotification
{
    NSDictionary* userInfo = [aNotification userInfo];
    
    CGRect keyboardEndFrame;
    
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    
    CGRect newKbRect = [self.view.window convertRect:keyboardEndFrame toView:self.view];
    
    
    self.keyboardMarginConstraint.constant = newKbRect.size.height;
    self.coverViewBottomConstraint.constant = newKbRect.size.height;
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    //make sure the body view is scrolled to the right position
    //this method is the next best thing to a didLosFocus callback
    [self.bodyView.scrollView setContentOffset:CGPointMake(0, 0) animated:NO];
}

- (void)keyboardWillHide: (NSNotification *)aNotification
{
    self.keyboardMarginConstraint.constant = 0;
    self.coverViewBottomConstraint.constant = 0;
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    //make sure the body view is scrolled to the right position
    //this method is the next best thing to a didLosFocus callback
    [self.bodyView.scrollView setContentOffset:CGPointMake(0, 0) animated:NO];
}


#pragma mark - ROTATION

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         CGFloat newWidth = size.width;
         
         [self adjustToWidth:newWidth];
         
     } completion:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         
     }];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self adjustWidthAndScrollViewHeight];
    
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (BOOL)shouldAutorotate
{
    return YES;
}



#pragma mark - STATUS BAR

- (BOOL)prefersStatusBarHidden
{
    return [ViewControllersManager sharedInstance].hideTheStatusBar;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}



#pragma mark - COLOURS

- (void)setCorrectColour
{
    if(self.isSafeMessage)
    {
        //[backButton setTintColor:SAFE_COLOUR];
        [self.navigationController.navigationBar setBarTintColor:SAFE_DARK_COLOUR];
        //[self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:SAFE_COLOUR}];
        //[self.navigationController.navigationBar.topItem setTitle:NSLocalizedString(@"🔐",@"Safe, secure email message")];
        UIImageView* imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"lockClosed22"]];
        [imageView setContentMode:UIViewContentModeScaleAspectFit];
        self.navigationItem.titleView = imageView;
    }
    else
    {
        //[backButton setTintColor:OPEN_COLOUR];
        [self.navigationController.navigationBar setBarTintColor:OPEN_DARK_COLOUR];
        //[self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:OPEN_COLOUR}];
        //        [self.navigationController.navigationBar.topItem setTitle:NSLocalizedString(@"🔓",@"Compose window title")];
        UIImageView* imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"lockOpen22"]];
        [imageView setContentMode:UIViewContentModeScaleAspectFit];
        self.navigationItem.titleView = imageView;
    }
    
}


- (void)setCorrectShadow:(TITokenField*)tokenField
{
    return;
    
    UIView* superBox = (UIView*)[tokenField superview];
    if([superBox isKindOfClass:[UIView class]] && ![superBox isEqual:self.replyToView])
    {
        if([(NSArray*)[tokenField tokens] count]>0)
        {
            BOOL isSafe = [Recipient recipientListIsSafe:tokenField.tokenObjects];
            
            [tokenField setBackgroundColor:isSafe?SAFE_TOKENFIELD_BACKGROUND_COLOUR_UNFOCUSSED:OPEN_TOKENFIELD_BACKGROUND_COLOUR_UNFOCUSSED];
        }
        else
        {
            [superBox.layer setShadowRadius:0];
            [superBox.layer setShadowOpacity:0];
            [tokenField setBackgroundColor:[UIColor whiteColor]];
        }
    }
}



#pragma mark - SIZE

- (void)adjustWidthAndScrollViewHeight
{
    CGFloat newWidth = self.view.frame.size.width;
    [self adjustToWidth:newWidth];
}

- (void)adjustToWidth:(CGFloat)newWidth
{
    if(fabs(self.widthConstraint.constant-newWidth)>0)
    {
        [self.widthConstraint setConstant:newWidth];
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }
    
    [self.fromView invalidateIntrinsicContentSize];
    [self.replyToView invalidateIntrinsicContentSize];
    [self.toView invalidateIntrinsicContentSize];
    [self.ccView invalidateIntrinsicContentSize];
    [self.bccView invalidateIntrinsicContentSize];
    
    [self.toView setNeedsLayout];
    [self.replyToView setNeedsLayout];
    [self.fromView setNeedsLayout];
    [self.ccView setNeedsLayout];
    [self.bccView setNeedsLayout];
    
    
    if(self.bodyView.hidden)
    {
        //        CGSize appropriateSize = [self.editView sizeThatFits:CGSizeMake(self.editView.frame.size.width, MAXFLOAT)];
        //
        //        [self.editFieldContentHeightConstraint setConstant:appropriateSize.height + 60];
        //[self.contentHeightConstraint setConstant:appropriateSize.height + 60];
        //
        //        [self.editView setNeedsLayout];
        //        [self.editView layoutIfNeeded];
    }
    else
    {
        CGRect frame = self.bodyView.frame;
        frame.size.height = 1;
        self.bodyView.frame = frame;
        CGSize fittingSize = [self.bodyView sizeThatFits:CGSizeZero];
        frame.size = fittingSize;
        self.bodyView.frame = frame;
        
        if([self.bodyView respondsToSelector:@selector(setHeightTo:)])
            [self.bodyView setHeightTo:fittingSize.height];
        else
            NSLog(@"Body view has wrong class, cannot set height(!!)");
        
        [self.contentHeightConstraint setConstant:fittingSize.height];
        
        self.bodyView.scrollView.contentSize = self.bodyView.bounds.size;
        
        [self.bodyView.scrollView setScrollEnabled:NO];
        [self.bodyView.scrollView setContentOffset:CGPointMake(0, 0)];
        
        [self.bodyView.scrollView setNeedsLayout];
        [self.bodyView.scrollView layoutIfNeeded];
        
        [self.bodyView setNeedsLayout];
        [self.bodyView layoutIfNeeded];
    }
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    [self.view layoutSubviews];
}


- (void)startObservingContentSizeChangesInWebView:(UIWebView *)webView
{
    [webView.scrollView addObserver:self forKeyPath:@"contentSize" options:0 context:&kObservingContentSizeChangesContext];
}

- (void)stopObservingContentSizeChangesInWebView:(UIWebView *)webView
{
    [webView.scrollView removeObserver:self forKeyPath:@"contentSize" context:&kObservingContentSizeChangesContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


#pragma mark - BUTTONS AND ACTIONS




- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch(alertView.tag)
    {
        case 456:
            //cancel alert
            switch(buttonIndex)
        {
            case 0:
                //save message
            {
                UIAlertView* alertDialog = [[UIAlertView alloc] init];
                
                [alertDialog setTitle:NSLocalizedString(@"Safe or open?",@"Alert Dialog")];
                [alertDialog setMessage:NSLocalizedString(@"Choose \"Safe draft\" to prevent your provider from accessing this message. If you would like to edit the draft using another client choose \"Open draft\" instead.", @"Alert dialog")];
                
                [alertDialog addButtonWithTitle:NSLocalizedString(@"Safe draft",@"Alert Dialog Button")];
                [alertDialog addButtonWithTitle:NSLocalizedString(@"Open draft",@"Alert Dialog Button")];
                [alertDialog addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel Button")];
                
                [alertDialog setDelegate:self];
                
                [alertDialog setTag:457];
                
                [alertDialog show];
            }
                break;
            case 1:
                //cancel
                return;
            case 2:
                //delete the draft
                if(self.composedMessageInstance)
                {
#if TARGET_OS_IPHONE
                    
#else
                    
                    [[EmailMessageController sharedInstance] removeMessageObjectFromTable:self.composedMessageInstance animated:YES]];
                    
#endif
                    //NSLog(@"Delete 1");
                    
                    [MAIN_CONTEXT deleteObject:self.composedMessageInstance];
                    
                    //[MAIN_CONTEXT processPendingChanges];
                }
                
                [self setComposedMessageInstance:nil];
                
                [self.autosaveTimer invalidate];
                
                [[ViewControllersManager sharedInstance] setComposeController:nil];
                [self dismissViewControllerAnimated:YES completion:nil];
                
                return;
            default:
                break;
        }
            break;
            
        case 457:
        {
            BOOL isSafe = YES;
            switch(buttonIndex)
            {
                case 1:
                    isSafe = NO;
                case 0:
                {
                    [self saveMessageByOverwritingPreviousCopy:YES asSafe:isSafe forSending:NO withCallback:nil];
                    
                    [self.autosaveTimer invalidate];
                    
                    [[ViewControllersManager sharedInstance] setComposeController:nil];
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
            }
        }
            
    }
}


- (IBAction)cancelButton:(id)sender
{
    if(self.isDirty)
    {
        UIAlertView* alertDialog = [[UIAlertView alloc] init];
        
        [alertDialog setTitle:NSLocalizedString(@"You have unsaved changes",@"Alert Dialog")];
        [alertDialog setMessage:NSLocalizedString(@"Would you like to save this message as a draft?", @"Save message dialog")];
        
        [alertDialog addButtonWithTitle:NSLocalizedString(@"Save as draft",@"Alert Dialog Button")];
        
        [alertDialog addButtonWithTitle:NSLocalizedString(@"Cancel",@"Cancel Button")];
        [alertDialog addButtonWithTitle:NSLocalizedString(@"Don't save",@"Don't save Button")];
        
        [alertDialog setTag:456];
        
        [alertDialog setDelegate:self];
        
        [alertDialog show];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:^{
            
            [self setComposedMessageInstance:nil];
            
            [self.autosaveTimer invalidate];
            
            [[ViewControllersManager sharedInstance] setComposeController:nil];
            
        }];
    }
}


- (IBAction)expandRecipients:(id)sender
{
    [self.extraFieldsButton setHidden:YES];
    
    [UIView animateWithDuration:.3 animations:^{
     
        [self.fromRightMarginConstraint setConstant:0];

        [self.ccView setHidden:NO];
        [self.bccView setHidden:NO];
        
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        
        [self.fromView invalidateIntrinsicContentSize];
    }];
    
}

- (IBAction)attachmentButtonHit:(id)sender
{
    if([ViewControllersManager canDoPopovers])
    {
        [self performSegueWithIdentifier:@"attachmentSegue" sender:self];
        
    }
    else
    {
        //iOS 7 (iPhone)
        [self performSegueWithIdentifier:@"attachmentSegue_iOS7" sender:self];
    }
}


#pragma mark - REPLY/FORWARD SETUP

- (void)startReplyToMessageInstance:(EmailMessageInstance*)messageInstance
{
    self.replyToMessageInstance = messageInstance;
    
    self.composedMessageInstance = [FormattingHelper replyToMessageInstance:messageInstance];
}


- (void)startReplyAllToMessageInstance:(EmailMessageInstance *)messageInstance
{
    self.replyToMessageInstance = messageInstance;
    
    self.composedMessageInstance = [FormattingHelper replyAllToMessageInstance:messageInstance];
}


- (void)startForwardOfMessageInstance:(EmailMessageInstance *)messageInstance
{
    self.forwardOfMessageInstance = messageInstance;
    
    self.composedMessageInstance = [FormattingHelper forwardOfMessageInstance:messageInstance];
}



#pragma mark - RECIPIENTS

- (NSArray*)emailRecipients
{
    NSMutableArray* emailRecipients = [NSMutableArray new];
    
    for(TIToken* token in self.replyToView.recipients)
    {
        Recipient* rec = token.representedObject;
        if([rec isKindOfClass:[Recipient class]])
        {
            [rec setType:TYPE_REPLY_TO];
            [emailRecipients addObject:rec];
        }
    }
    for(TIToken* token in self.toView.recipients)
    {
        Recipient* rec = token.representedObject;
        if([rec isKindOfClass:[Recipient class]])
        {
            [rec setType:TYPE_TO];
            [emailRecipients addObject:rec];
        }
    }
    for(TIToken* token in self.ccView.recipients)
    {
        Recipient* rec = token.representedObject;
        if([rec isKindOfClass:[Recipient class]])
        {
            [rec setType:TYPE_CC];
            [emailRecipients addObject:rec];
        }
    }
    for(TIToken* token in self.bccView.recipients)
    {
        Recipient* rec = token.representedObject;
        if([rec isKindOfClass:[Recipient class]])
        {
            [rec setType:TYPE_BCC];
            [emailRecipients addObject:rec];
        }
    }
    for(TIToken* token in self.fromView.recipients)
    {
        Recipient* rec = token.representedObject;
        if([rec isKindOfClass:[Recipient class]])
        {
            [rec setType:TYPE_FROM];
            [emailRecipients addObject:rec];
        }
    }
    
    return emailRecipients;
}

- (BOOL)isSafe
{
    return [Recipient recipientListIsSafe:[self emailRecipients]];
}




#pragma mark - UITextFieldDelegate methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if([textField isKindOfClass:[TITokenField class]])
    {
        CGPoint point = [self.scrollView convertPoint:textField.frame.origin fromView:textField];
        
        point.x = 0;
        
        CGFloat scrollViewHeight = self.scrollView.frame.size.height;
        
        CGFloat contentHeight = self.scrollView.contentSize.height;
        
        if(contentHeight < scrollViewHeight)
            point.y = 0;
        else
        {
            if(point.y > contentHeight - scrollViewHeight)
                point.y = contentHeight - scrollViewHeight;
        }
        
        [self.scrollView setContentOffset:point animated:YES];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if([textField isEqual:self.toView.tokenFieldController.tokenField])
    {
        TITokenField* tokenField = self.toView.tokenFieldController.tokenField;
        
        NSString* tokenFieldText = tokenField.text;
        
        if(tokenFieldText.length<=1)
        {
            if([self.ccView isHidden])
            {
                [self.subjectField becomeFirstResponder];
            }
            else
            {
                [self.ccView.tokenFieldController.tokenField becomeFirstResponder];
            }
        }
    }
    
    if([textField isEqual:self.subjectField])
    {
        if(self.bodyView.hidden)
            [self.editView becomeFirstResponder];
        else
            [self.bodyView becomeFirstResponder];
        return NO;
    }
    return YES;
}



#pragma mark - TEXT VIEW DELEGATE

- (void)textViewDidChange:(UITextView *)textView
{
    self.isDirty = YES;

    CGRect caretRect = [textView caretRectForPosition:textView.selectedTextRange.start];
    CGRect absoluteCaretRect = [self.scrollView convertRect:caretRect fromView:textView];
    CGRect offsetRect = CGRectOffset(absoluteCaretRect, 0, 20);
    [self.scrollView scrollRectToVisible:offsetRect animated:YES];

}


- (void)textViewDidBeginEditing:(UITextView*)textView
{

}





#pragma mark - WEB VIEW DELEGATE

- (BOOL)webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType
{
    if ( inType == UIWebViewNavigationTypeLinkClicked )
    {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }
    
    if ([inRequest.URL.scheme isEqualToString:@"textDidChange"])
    {
        [self adjustWidthAndScrollViewHeight];
        return NO;
    }
    
    
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString* innerHTML = [webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"];
    
    //get notified about text changes to the body view
    [self.bodyView stringByEvaluatingJavaScriptFromString:@"document.getElementById('content').addEventListener('change', function () {"
     @"var frame = document.createElement('iframe');"
     @"frame.src = 'textDidChange://something';"
     @"document.body.appendChild(frame);"
     @"setTimeout(function () { document.body.removeChild(frame); }, 0);"
     @"}, false);"];
    
    innerHTML = [webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"];
    
    [self adjustWidthAndScrollViewHeight];
}




#pragma mark - TOKEN FIELD DELEGATE


- (BOOL)tokenField:(TITokenField *)tokenField willRemoveToken:(TIToken *)token
{
    return YES;
}

- (BOOL)tokenField:(TITokenField *)field shouldUseCustomSearchForSearchString:(NSString *)searchString
{
    if(field.usePreparedResults)
        return NO;
    
    return YES;
}

- (BOOL)tokenField:(TITokenField*)tokenField willAddToken:(TIToken *)token
{
    if(![token.representedObject isKindOfClass:[Recipient class]])
    {
        NSString* title = token.title;
        
        Recipient* rec = [APPDELEGATE.contactSuggestions recipientForString:title];
        
        if(!rec)
            return NO;
        
        [token setRepresentedObject:rec];
    }
    
    return YES;
}


- (void)tokenField:(TITokenField *)tokenField didAddToken:(TIToken *)token
{
    [self setIsDirty:YES];
    
    [self updateSafeOrOpenStatus];
    [self setCorrectShadow:tokenField];
    
    Recipient* rec = token.representedObject;
    
    if(rec.type==TYPE_FROM)
    {
        IMAPAccountSetting* fromAccountSetting = [IMAPAccountSetting accountSettingForSenderEmail:rec.displayEmail];
        
        //move the message to the drafts folder of the new sending account
        IMAPFolderSetting* draftsFolder = fromAccountSetting.draftsFolder;
        
        if(draftsFolder && ![self.composedMessageInstance isInDraftsFolder])
        {
            self.composedMessageInstance = [self.composedMessageInstance moveToFolder:draftsFolder];
        }
        
        //[FormattingHelper changeHTMLEmail:[self.bodyField mainFrameDocument] toFooter:fromAccountSetting.footer];
    }
    
    //show the popover if the recipient is open, the "don't show this again" button was never pressed and the token field is not one used to select sender addresses, as opposed to proper recipients
    //    if(![recipient isSafe] && MODEL.currentUserSettings.showNewbieExplanations.boolValue && !tokenField.useSenderAddressesForMenu)
    //    {
    //        [self showPopoverInfoWithText:nil atRect:[tokenField boundsOfTokenWithRecipient:recipient] inView:tokenField];
    //    }
    
    if([rec isKindOfClass:[Recipient class]])
    {
        //NSArray* newEmailRecipients = [self emailRecipients];
        
        //add an EmailContactDetail so that the address will be included in the list of suggestions
        [EmailContactDetail addEmailContactDetailForEmail:rec.displayEmail alreadyFoundOne:nil inContext:MAIN_CONTEXT];
        
        //NSData* newAddressData = [AddressDataHelper addressDataForRecipients:newEmailRecipients];
        
        //[self.composedMessageInstance.message.messageData setAddressData:newAddressData];
        
        [token setTintColor:[rec isSafe]?SAFE_DARK_COLOUR:OPEN_DARK_COLOUR];
        
        [self setCorrectColour];
        //[self.view bringSubviewToFront:tokenField];
        [self setCorrectShadow:tokenField];
        
        [self.view layoutSubviews];
    }
    
    return;
}

- (void)tokenField:(TITokenField *)tokenField didRemoveToken:(TIToken *)token
{
    [self setIsDirty:YES];
    
    [self setCorrectColour];
    [self setCorrectShadow:tokenField];
    [self updateSafeOrOpenStatus];
}

- (void)tokenField:(TITokenField *)tokenField didFinishSearch:(NSArray *)matches
{
    
}

- (NSString *)tokenField:(TITokenField *)tokenField displayStringForRepresentedObject:(id)object
{
    if([object isKindOfClass:[Recipient class]])
    {
        NSString* name = [(Recipient*)object displayName];
        
        if(!name)
            name = [(Recipient*)object displayEmail];
        
        return name;
    }
    
    return @"Name";
}

- (NSString *)tokenField:(TITokenField *)tokenField searchResultStringForRepresentedObject:(id)object
{
    if([object isKindOfClass:[NSManagedObjectID class]])
    {
        NSManagedObject* managedObject = [MAIN_CONTEXT existingObjectWithID:object error:nil];
        if([managedObject isKindOfClass:[Contact class]])
        {
            return [(Contact*)managedObject displayName];
        }
        if([managedObject isKindOfClass:[EmailContactDetail class]])
        {
            NSString* name = [(EmailContactDetail*)managedObject fullName];
            if(!name)
                name = [(EmailContactDetail*)managedObject address];
            return name;
        }
    }
    
    if([object isKindOfClass:[Recipient class]])
    {
        return [(Recipient*)object displayName];
    }
    
    return @"Name";
}

- (NSString *)tokenField:(TITokenField *)tokenField searchResultSubtitleForRepresentedObject:(id)object
{
    if([object isKindOfClass:[NSManagedObjectID class]])
    {
        NSManagedObject* managedObject = [MAIN_CONTEXT existingObjectWithID:object error:nil];
        if([managedObject isKindOfClass:[Contact class]])
        {
            return nil;//[[MODEL mostFrequentEmailOfContact:(Contact*)managedObject] address];
        }
        if([managedObject isKindOfClass:[EmailContactDetail class]])
        {
            return [(EmailContactDetail*)managedObject address];
        }
    }
    
    if([object isKindOfClass:[Recipient class]])
    {
        return [(Recipient*)object displayEmail];
    }
    
    return @"email address";
}


- (CGFloat)tokenField:(TITokenField *)tokenField resultsTableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}


- (void)tokenField:(TITokenField *)field performCustomSearchForSearchString:(NSString *)searchString withCompletionHandler:(void (^)(NSArray *results))completionHandler
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        NSArray* result = [APPDELEGATE.contactSuggestions contactObjectIDsForPartialString:searchString maxNumber:4];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            completionHandler(result);
            
        });
    });
}

- (IMAGE*)tokenField:(TITokenField *)tokenField searchResultImageForRepresentedObject:(id)object
{
    if([object isKindOfClass:[Recipient class]])
    {
        //return [(Recipient*)object ];
    }
    
    return nil;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.destinationViewController isKindOfClass:[AttachmentsDetailListController class]])
    {
        AttachmentsDetailListController* destinationController = (AttachmentsDetailListController*)segue.destinationViewController;
        
        [destinationController setCanAddAndRemove:YES];
        
        [destinationController setupWithAttachments:self.allAttachments];

        
        NSInteger numberOfAttachments = self.composedMessageInstance.message.attachments.count;
        
        destinationController.preferredContentSize = CGSizeMake(300, 73*(numberOfAttachments+2));
        
        destinationController.callingViewController = self;
        
        //        if([segue isKindOfClass:[UIStoryboardPopoverSegue class]])
        //        {
        //            [(UIStoryboardPopoverSegue*)segue popoverController].popoverContentSize = CGSizeMake(300, (self.composedMessageInstance.message.allAttachments.count+1)*73);
        //            self.popover = [(UIStoryboardPopoverSegue *)segue popoverController];
        //        }
        
        //only iOS 8.0 and above
        if([destinationController respondsToSelector:@selector(popoverPresentationController)])
        {
            UIPopoverPresentationController *popPC = destinationController.popoverPresentationController;
            popPC.delegate = self;
        }
    }
    
    [super prepareForSegue:segue sender:sender];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}


@end
