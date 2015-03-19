
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
#import "ComposeWindowController.h"
#import "IMAPAccount.h"
#import "EmailContactDetail+Category.h"
#import "ABContactDetail.h"
#import "Contact+Category.h"
#import "UserSettings+Category.h"
#import "Recipient.h"
#import "IMAPAccountSetting+Category.h"
#import "EmailMessage+Category.h"
#import "AttachmentAdditionController.h"
#import "Recipient.h"
#import "EmailRecipient.h"
#import "MynigmaMessage+Category.h"
#import "MynigmaAttachment.h"
#import "EncryptionHelper.h"
#import "AttachmentItem.h"
#import "FileAttachment+Category.h"
#import "IMAPFolderSetting+Category.h"
#import "MynigmaPublicKey+Category.h"
#import "PublicKeyManager.h"
#import "EmailMessageData.h"
#import "SendingManager.h"
#import "IconListAndColourHelper.h"
#import "AttachmentsManager.h"
#import "EmailMessageInstance+Category.h"
#import "AddressDataHelper.h"
#import "FormattingHelper.h"
#import "OutlineObject.h"
#import "FileAttachment+Category.h"
#import "MessageTemplate+Category.h"
#import "TemplateNameController.h"
#import "MacTokenField.h"
#import "RecipientTokenField.h"
#import <CrashReporter/CrashReporter.h>
#import "PopoverViewController.h"
#import "ABContactDetail+Category.h"
#import "EmailMessageController.h"
#import "AttachmentsIconView.h"
#import "EmailFooter.h"
#import "NSString+EmailAddresses.h"
#import "HTMLPurifier.h"
#import "WindowManager.h"
#import "SelectionAndFilterHelper.h"
#import "AlertHelper.h"
#import "PrintingHelper.h"
#import "AccountCreationManager.h"
#import "MynigmaFeedback.h"




#import <QuartzCore/QuartzCore.h>


#if ULTIMATE

#import "ServerHelper.h"

#endif




@interface ComposeWindowController ()

@end

@implementation ComposeWindowController



#pragma mark - Window controller

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }

    return self;
}

- (void)awakeFromNib
{
    [self.attachmentsArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"fileName" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"contentid" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"uniqueID" ascending:YES]]];

    [self.attachmentsView registerForDraggedTypes:@[NSURLPboardType, NSFilenamesPboardType, NSFilesPromisePboardType]];

    [self.attachmentsView setIsEditable:YES];

//    [self.topMetalSheetHeight setConstant:0];
//    [self.bottomMetalSheetHeight setConstant:0];
//
//    [self.topMetalSheetBorder setConstant:0];
//    [self.bottomMetalSheetBorder setConstant:0];

//    NSImage* patternImage = [NSImage imageNamed:@"doorGreenFlipped"];
//
//    //[patternImage setScalesWhenResized:YES];
//    [self.topMetalSheetImageView setFillColor:[NSColor colorWithPatternImage:patternImage]];
//
//
//    patternImage = [NSImage imageNamed:@"doorGreen"];
//
//    [self.bottomMetalSheetImageView setFillColor:[NSColor colorWithPatternImage:patternImage]];

    //    [self.topMetalSheetImageView setWantsLayer:YES];
//    [self.topMetalSheetImageView.layer setTransform:CATransform3DMakeRotation(M_PI, 0, 0, 1)];
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    //set up the recipient token fields

    [self.fromField setType:TYPE_FROM];
    [self.fromField setTokenLimit:1];
    [self.fromField setUseSenderAddressesForMenu:YES];

    [self.replyToField setType:TYPE_REPLY_TO];
    [self.replyToField setTokenLimit:1];

    [self.toField setType:TYPE_TO];
    [self.ccField setType:TYPE_CC];
    [self.bccField setType:TYPE_BCC];


    //set up the WebView

    [self.bodyField setEditable:YES];
    [self.bodyField setEditingDelegate:self];
    [[self.bodyField preferences] setStandardFontFamily:@"Helvetica"];
    [[self.bodyField preferences] setDefaultFontSize:12];

    // CSS for blockquotes
    WebPreferences *webPrefs = [WebPreferences standardPreferences];
    [webPrefs setUserStyleSheetEnabled:YES];

    //Point to custom CSS
    [webPrefs setUserStyleSheetLocation:[[NSBundle mainBundle] URLForResource:@"style" withExtension:@"css"]];

    //Set the WebView's preferences
    [self.bodyField setPreferences:webPrefs];

    [self setAutosaveTimer:[NSTimer scheduledTimerWithTimeInterval:3*60 target:self selector:@selector(autosave:) userInfo:nil repeats:YES]];
}


- (BOOL)windowShouldClose:(NSNotification *)notification
{
    if(self.isDirty)
    {
        NSAlert* alertDialog = [[NSAlert alloc] init];

        [alertDialog setMessageText:NSLocalizedString(@"You have unsaved changes",@"Alert Dialog")];
        [alertDialog setInformativeText:NSLocalizedString(@"Would you like to save this message as a draft?", @"Save message dialog")];

        [alertDialog addButtonWithTitle:NSLocalizedString(@"Save as draft",@"Alert Dialog Button")];

        [alertDialog addButtonWithTitle:NSLocalizedString(@"Cancel",@"Cancel Button")];
        [alertDialog addButtonWithTitle:NSLocalizedString(@"Don't save",@"Don't save Button")];

        switch([alertDialog runModal])
        {
            case NSAlertFirstButtonReturn:
            {
                //save message
                NSAlert* alertDialog = [[NSAlert alloc] init];

                [alertDialog setMessageText:NSLocalizedString(@"Safe or open?", @"Alert Dialog")];
                [alertDialog setInformativeText:NSLocalizedString(@"Choose \"Safe draft\" to prevent your provider from accessing this message. If you would like to edit the draft using another client choose \"Open draft\" instead.", @"Alert dialog")];

                [alertDialog addButtonWithTitle:NSLocalizedString(@"Safe draft",@"Alert Dialog Button")];
                [alertDialog addButtonWithTitle:NSLocalizedString(@"Open draft",@"Alert Dialog Button")];
                [alertDialog addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel Button")];

                NSInteger result = alertDialog.runModal;

                BOOL cancelled = (result==NSAlertThirdButtonReturn);

                if(cancelled)
                    return NO;

                BOOL isSafe = (result==NSAlertFirstButtonReturn);

                [self saveMessageByOverwritingPreviousCopy:YES properDelete:YES asSafe:isSafe forSending:NO withCallback:nil];

                [self.autosaveTimer invalidate];

                //prevent weird WebKit crash (clearUndoRedoOperation etc.)
                [self prepareWebViewForWindowClosing];

                [WindowManager removeWindow:self];

                return YES;
            }
            case NSAlertSecondButtonReturn:
            {
                //cancel
                return NO;
            }
            case NSAlertThirdButtonReturn:
            {
                    //delete the draft
                    if(self.composedMessageInstance)
                    {
#if TARGET_OS_IPHONE

#else

                        [[EmailMessageController sharedInstance] removeMessageObjectFromTable:self.composedMessageInstance animated:YES];

#endif
                        NSLog(@"Delete 2");
                        [MAIN_CONTEXT deleteObject:self.composedMessageInstance];

                    //[MAIN_CONTEXT processPendingChanges];
                }

                    [self setComposedMessageInstance:nil];

                [self.autosaveTimer invalidate];
                
                //prevent weird WebKit crash (clearUndoRedoOperation etc.)
                [self prepareWebViewForWindowClosing];

                [WindowManager removeWindow:self];


                return YES;
            }
        }
    }

    [self.autosaveTimer invalidate];

    //prevent weird WebKit crash (clearUndoRedoOperation etc.)
    [self prepareWebViewForWindowClosing];

    [WindowManager removeWindow:self];

    return YES;
}

//annoying bug in webkit causes crash (clearUndoRedoOperations, forwardInvocation etc.) if this isn't called prior to closing the window
- (void)prepareWebViewForWindowClosing
{
    [self.bodyField stopLoading:nil];

    [self.bodyField setDownloadDelegate:nil];
    [self.bodyField setEditingDelegate:nil];
    [self.bodyField removeFromSuperviewWithoutNeedingDisplay];
}


- (void)dealloc
{
    [self.autosaveTimer invalidate];

    self.autosaveTimer = nil;
}


#pragma mark - UI and actions


//the user selects an email in the "from" menu
- (IBAction)setFromEmailAddress:(id)sender
{
    [self setIsDirty:YES];

    IMAPAccountSetting* fromAccountSetting = [sender representedObject];

    Recipient* newRecipient = [[Recipient alloc] initWithEmail:fromAccountSetting.senderEmail andName:fromAccountSetting.senderName];

    if([sender isEqual:self.toField])
        [newRecipient setType:TYPE_FROM];
    else
        [newRecipient setType:TYPE_REPLY_TO];

    [self.fromField setRecipients:@[newRecipient] filterByType:YES];

    //unnecessary: the callback for a change of recipients will be called anyway...
    //
    //    //[self setCorrectShadow:self.fromField];
    //    [self updateSafeOrOpenStatus];
    //
    //    //move the message to the drafts folder of the new sending account
    //    IMAPFolderSetting* draftsFolder = fromAccountSetting.draftsFolder;
    //
    //    if(draftsFolder && ![draftsFolder isEqual:self.composedMessageInstance.inFolder])
    //    {
    //        self.composedMessageInstance = [self.composedMessageInstance moveToFolder:draftsFolder];
    //    }
    //
    //    [FormattingHelper changeHTMLEmail:[self.bodyField mainFrameDocument] toFooter:fromAccountSetting.footer];
}






#pragma mark - Saving & sending

- (void)saveMessageByOverwritingPreviousCopy:(BOOL)overwrite properDelete:(BOOL)properDelete asSafe:(BOOL)shouldBeSafe forSending:(BOOL)isForSending withCallback:(void(^)(MynigmaFeedback* feedback))callback
{
    [ThreadHelper ensureMainThread];

    //    EmailMessageInstance* messageInstance = self.composedMessageInstance;
    //
    //    if(!messageInstance)
    //    {
    //        Recipient* fromRecipient = nil;
    //        if(self.fromField.recipients.count>0)
    //        {
    //            fromRecipient = self.fromField.recipients[0];
    //        }
    //        else
    //            fromRecipient = [AddressDataHelper standardSenderAsRecipient];
    //
    //        messageInstance = [FormattingHelper freshComposedMessageInstanceWithSenderRecipient:fromRecipient];
    //    }

    Recipient* fromRecipient = nil;

    if(self.fromField.recipients.count>0)
    {
        fromRecipient = self.fromField.recipients[0];
    }
    else
        fromRecipient = [AddressDataHelper standardSenderAsRecipient];

    IMAPAccountSetting* fromAccountSetting = [IMAPAccountSetting accountSettingForSenderEmail:fromRecipient.displayEmail];

    
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

    //[newInstance markUnread];

    [newMessage setDateSent:[NSDate date]];

    [newInstance setFlags:[NSNumber numberWithInt:MCOMessageFlagDraft|MCOMessageFlagSeen]];
    [newInstance setAddedToFolder:newInstance.inFolder];

    [newInstance changeUID:nil];

    EmailMessageInstance* oldInstance = self.composedMessageInstance;

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

    [newMessage.messageData setSubject:self.subjectField.stringValue];

    [newMessage.messageData setBody:[(DOMHTMLElement *)[[[self.bodyField mainFrame] DOMDocument] documentElement] outerText]];

    [newMessage.messageData setHtmlBody:[(DOMHTMLElement *)[[[self.bodyField mainFrame] DOMDocument] documentElement] outerHTML]];

    NSArray* allAttachments = [self.attachmentsView allAttachments];

    //[[NSSet setWithArray:self.attachmentsArrayController.arrangedObjects] valueForKey:@"fileAttachment"];

    for(FileAttachment* fileAttachment in allAttachments)
    {
        FileAttachment* freshAttachment = fileAttachment;

        if(fileAttachment.attachedAllToMessage || fileAttachment.inlineImageForFooter)
        {
            //the attachment is already attached to a message
            //shouldn't be hugely surprising, nor a major problem...
            //NSLog(@"Attachment is already assigned to a different message!! Fixing by creating a copy...");

            freshAttachment = [fileAttachment copyInContext:MAIN_CONTEXT];
        }

        [newMessage addAllAttachmentsObject:freshAttachment];

        //make it explicit just if it's not inline
        if(fileAttachment.inlineImageForFooter)
        {
            //it's inline
            //assume all other attachments are explicit
        }
        else
        {
            [newMessage addAttachmentsObject:freshAttachment];
        }

        if(!freshAttachment.contentType)
            [freshAttachment setContentType:@"application/octet-stream"];
    }

    if(overwrite)
    {
        if(properDelete)
            [oldInstance deleteInstanceInContext:oldInstance.managedObjectContext];
        else
            [oldInstance moveToBinOrDelete];
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

            [(MynigmaMessage*)self.composedMessageInstance.message encryptForSendingWithCallback:^(MynigmaFeedback* feedback)
            {
                [self setIsDirty:NO];

                if(callback)
                    callback(feedback);
            }];

        }
        else
        {
            //need to encrypt as draft (may not have all the necessary key labels and/or attachments)
            [(MynigmaMessage*)self.composedMessageInstance.message encryptAsDraftWithCallback:^(MynigmaFeedback* feedback)
            {
                [self setIsDirty:NO];

                if(callback)
                    callback(feedback);
            }];

        }
    }
    else
    {
        [self setIsDirty:NO];
        if(callback)
            callback([MynigmaFeedback feedback:MynigmaEncryptionSuccess]);
    }
}


- (void)saveMessageByUsingExistingDraft:(EmailMessage*)message andOverwritingPreviousCopy:(BOOL)overwrite properDelete:(BOOL)properDelete asSafe:(BOOL)shouldBeSafe forSending:(BOOL)isForSending withCallback:(void(^)(MynigmaFeedback* feedback))callback
{
    [ThreadHelper ensureMainThread];
    
    Recipient* fromRecipient = nil;

    fromRecipient = [[AddressDataHelper senderAsEmailRecipientForMessage:message] recipient];
    //this was already loaded
    if(self.fromField.recipients.count>0)
    {
        fromRecipient = self.fromField.recipients[0];
    }
    else
        fromRecipient = [AddressDataHelper standardSenderAsRecipient];
    
    IMAPAccountSetting* fromAccountSetting = [IMAPAccountSetting accountSettingForSenderEmail:fromRecipient.displayEmail];
    
    
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
    
    //[newInstance markUnread];
    
    [newMessage setDateSent:[NSDate date]];
    
    [newInstance setFlags:[NSNumber numberWithInt:MCOMessageFlagDraft|MCOMessageFlagSeen]];
    [newInstance setAddedToFolder:newInstance.inFolder];
    
    [newInstance changeUID:nil];
    
    EmailMessageInstance* oldInstance = self.composedMessageInstance;
    
    [self setComposedMessageInstance:newInstance];
    
    [newMessage.messageData setFromName:message.messageData.fromName];
    
    [newMessage setSearchString:message.searchString];
    
    [newMessage.messageData setAddressData:message.messageData.addressData];
    
    [newMessage.messageData setLoadRemoteImages:message.messageData.loadRemoteImages];
    
    [newMessage.messageData setSubject:message.messageData.subject];
    
    [newMessage.messageData setBody:message.messageData.body];
    
    [newMessage.messageData setHtmlBody:message.messageData.htmlBody];
    
    NSArray* allAttachments = [self.attachmentsView allAttachments];
    
    //[[NSSet setWithArray:self.attachmentsArrayController.arrangedObjects] valueForKey:@"fileAttachment"];
    
    for(FileAttachment* fileAttachment in allAttachments)
    {
        FileAttachment* freshAttachment = fileAttachment;
        
        if(fileAttachment.attachedAllToMessage || fileAttachment.inlineImageForFooter)
        {
            //the attachment is already attached to a message
            //shouldn't be hugely surprising, nor a major problem...
            //NSLog(@"Attachment is already assigned to a different message!! Fixing by creating a copy...");
            
            freshAttachment = [fileAttachment copyInContext:MAIN_CONTEXT];
        }
        
        [newMessage addAllAttachmentsObject:freshAttachment];
        
        //make it explicit just if it's not inline
        if(fileAttachment.inlineImageForFooter)
        {
            //it's inline
            //assume all other attachments are explicit
        }
        else
        {
            [newMessage addAttachmentsObject:freshAttachment];
        }
        
        if(!freshAttachment.contentType)
        [freshAttachment setContentType:@"application/octet-stream"];
    }
    
    if(overwrite)
    {
        if(properDelete)
            [oldInstance deleteInstanceInContext:oldInstance.managedObjectContext];
        else
            [oldInstance moveToBinOrDelete];
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
                callback(feedback);
            }];
            
        }
        else
        {
            //need to encrypt as draft (may not have all the necessary key labels and/or attachments)
            [(MynigmaMessage*)self.composedMessageInstance.message encryptAsDraftWithCallback:^(MynigmaFeedback* feedback)
            {
                
                [self setIsDirty:NO];
                
                if(callback)
                    callback(feedback);
            }];
            
        }
    }
    else
    {
        [self setIsDirty:NO];
        if(callback)
            callback([MynigmaFeedback feedback:MynigmaEncryptionSuccess]);
    }
}


/**CALL ON MAIN*/
- (void)sendItNow:(EmailMessageInstance*)messageInstance
{
    [ThreadHelper ensureMainThread];

    IMAPAccount* imapAccount = [AddressDataHelper sendingAccountForMessage:messageInstance.message];

    if(imapAccount)
    {
        [SendingManager sendDraftMessageInstance:messageInstance fromAccount:imapAccount withCallback:^(NSInteger result,NSError* error){

            if(result==-1)
            {
                NSBeep();
                NSAlert* alert = [NSAlert alertWithMessageText:error.localizedDescription defaultButton:NSLocalizedString(@"OK","OK button") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"The message will kept in your outbox and sent automatically as soon as possible.",@"AlertWindow")];
                [alert runModal];
            }
            else if(result==-8)
            {
                NSBeep();
                NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"There was an error sending your message.",@"AlertWindow") defaultButton:NSLocalizedString(@"OK","OK button") alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@ %@",NSLocalizedString(@"Please check your current SMTP settings.",@"AlertWindow"),NSLocalizedString(@"The message will kept in your outbox and sent automatically as soon as possible.",@"AlertWindow")];
                [alert runModal];
                
            }
            else if(result<0)
            {
                NSBeep();
                NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"There was an error sending your message.",@"AlertWindow") defaultButton:NSLocalizedString(@"OK","OK button") alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
                [alert runModal];
                // Edit: empty NSLocalized not allowed
            }
            if(result==1)
            {
                [[NSSound soundNamed:@"mail_sent.mp3"] play];

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

            [WindowManager removeWindow:self];
        }];
    }
    else
        NSLog(@"No account set for account setting ID!!!! MODEL.accounts: %@, MODEL.currentUserSettings.accounts: %@", [AccountCreationManager sharedInstance].allAccounts, [UserSettings currentUserSettings].accounts);
}

- (IBAction)sendMessage:(id)sender
{
    [self closeMetalSheetWithDuration:.6 andCallback:^{
        
        [self playSwishSoundAndMoveOutWindow];

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
    [self saveMessageByOverwritingPreviousCopy:YES properDelete:YES asSafe:self.isSafeMessage forSending:YES withCallback:^(MynigmaFeedback* feedback)
        {

        if(!feedback.isSuccess)
        {
//            NSLog(@"Failed to encrypt message before sending!!!");
            [AlertHelper showAlertWithMessage:NSLocalizedString(@"An error occurred.", @"Generic error") informativeText:NSLocalizedString(@"We regret that Mynigma was unable to send your message. Please submit a bug report to help us fix the problem. Thank you!", @"Saving message before sending failed")];
            NSBeep();
        }
        else
        {
            [ThreadHelper runAsyncOnMain:^{
                //the composedMessageInstance is now set to the new, saved message
                [self sendItNow:self.composedMessageInstance];
            }];
        }

    }];

    }];
}

- (IBAction)saveMessage:(id)sender
{
    [self saveMessageByOverwritingPreviousCopy:YES properDelete:YES asSafe:YES forSending:NO withCallback:^(MynigmaFeedback* feedback)
    {
        if(!feedback.isSuccess)
        {
            NSLog(@"Failed to encrypt message while saving!!!");
            
            //TO DO: show more specific error
            //use the MynigmaFeedback object
            
            [AlertHelper showAlertWithMessage:NSLocalizedString(@"An error occurred.", @"Generic error") informativeText:NSLocalizedString(@"We regret that Mynigma was unable to save your message. Please submit a bug report to help us fix the problem. Thank you!", @"Saving message failed")];
            NSBeep();
        }
        else
        {
            //success
            //maybe play a sound or something?
        }

    }];
}

- (void)autosave:(NSTimer*)timer
{
    [self saveMessageByOverwritingPreviousCopy:YES properDelete:YES asSafe:YES forSending:NO withCallback:^(MynigmaFeedback* feedback)
    {
        if(!feedback.isSuccess)
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

//- (void)updateAttachmentNumber
//{
//    NSInteger numberOfAttachments = [(NSArray*)self.attachmentsArrayController.arrangedObjects count];
//    if(numberOfAttachments>0)
//    {
//        NSShadow* shadow = [NSShadow new];
//        NSColor* brightBlue = [NSColor colorWithDeviceRed:1/255. green:104/255. blue:236/255. alpha:1];
//        [shadow setShadowColor:brightBlue];
//        [shadow setShadowBlurRadius:1];
//        [self.attachmentButton setShadow:shadow];
//        [self.numberOfAttachmentsLabel setStringValue:[NSString stringWithFormat:@"%ld", numberOfAttachments]];
//
//        [self.attachmentsListConstraint setConstant:120];
//    }
//    else
//    {
//        [self.attachmentButton setShadow:nil];
//        [self.numberOfAttachmentsLabel setStringValue:@""];
//
//        [self.attachmentsListConstraint setConstant:0];
//    }
//}

//open the attachments sheet
- (IBAction)addAttachment:(id)sender
{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setCanCreateDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:YES];

    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result)
    {
        if(result==NSFileHandlingPanelOKButton)
        {
            NSArray* allURLs = self.attachmentsView.allURLs;

            for(NSURL* url in [openPanel URLs])
            {
                if(url.path && ![allURLs containsObject:url.path])
                {
                    FileAttachment* newAttachment = [FileAttachment makeNewAttachmentFromURL:url];

                    if(newAttachment)
                    {
                        [self.attachmentsView addAttachment:newAttachment];

                        self.isDirty = YES;
                    }
                }
            }
        }}];



//    if(!self.sheetController)
//        self.sheetController = [[AttachmentAdditionController alloc] initWithWindowNibName:@"AttachmentAdditionController"];
//
//    [NSApp beginSheet:[self.sheetController window] modalForWindow:self.window modalDelegate:self didEndSelector: @selector(didEndSheet:returnCode:contextInfo:) contextInfo: nil];
//
//    [self.sheetController setAllAttachments:self.attachmentsArrayController.arrangedObjects];
//
//    [self.sheetController resetCollection];
}

//attachments sheet will call this when it is closed
//- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
//{
//    //[self updateAttachmentNumber];
//
//    self.isDirty = YES;
//}




#pragma mark - Safe/open and colours

- (void)updateSafeOrOpenStatus
{
    NSArray* recArray = [self recipients];

    BOOL result = [Recipient recipientListIsSafe:recArray];

    [self setIsSafeMessage:result];

    [self setCorrectLockImage];
}


- (void)setCorrectLockImage
{
    if(!self.isSafeMessage)
    {
        [self.lockView setImage:[NSImage imageNamed:@"openLockWhite32.png"]];

        NSImage* patternImage = [NSImage imageNamed:@"envelopeMarginRedCombined.png"];
        //[patternImage setScalesWhenResized:YES];
        [self.topBox setFillColor:[NSColor colorWithPatternImage:patternImage]];

        [self.safeLabel setStringValue:NSLocalizedString(@"Open email",@"Open,Unsecure email message")];
        //[sendButton setImage:[NSImage imageNamed:@"SendButtonRedR.png"]];
        [self.window setTitle:NSLocalizedString(@"Open message",@"Compose window title")];
    }
    else
    {
        [self.lockView setImage:[NSImage imageNamed:@"secureLockWhite32.png"]];

        NSImage* patternImage = [NSImage imageNamed:@"envelopeMarginGreenCombined.png"];
        //[patternImage setScalesWhenResized:YES];
        [self.topBox setFillColor:[NSColor colorWithPatternImage:patternImage]];

        [self.safeLabel setStringValue:NSLocalizedString(@"Safe",@"Safe,secure email")];
        //[sendButton setImage:[NSImage imageNamed:@"SendButtonGreenR.png"]];
        [self.window setTitle:NSLocalizedString(@"Safe message",@"Safe, secure email message")];
    }


    //now enable/disable the "Send" button, depending on whether there are any recipients of the to/cc/bcc type
    [self.sendButton setEnabled:[AddressDataHelper sendableAddressContainedInRecipients:[self recipients]]];
}

- (void)setCorrectShadow:(RecipientTokenField*)tokenField
{
    NSBox* superBox = (NSBox*)[tokenField superview].superview;
    if(superBox && [superBox isKindOfClass:[NSBox class]] && ![superBox isEqual:self.replyToBox])
    {
        if([(NSArray*)[tokenField recipients] count]>0)
        {
            BOOL isSafe = [Recipient recipientListIsSafe:tokenField.recipients];
            NSShadow* shadow = [NSShadow new];
            [shadow setShadowColor:isSafe?SAFE_SHADOW_COLOUR:OPEN_SHADOW_COLOUR];
            [shadow setShadowBlurRadius:1];
            [superBox setShadow:shadow];
            [superBox setFillColor:isSafe?SAFE_TOKENFIELD_BACKGROUND_COLOUR:OPEN_TOKENFIELD_BACKGROUND_COLOUR];
            //[superBox setBorderColor:isSafe?SAFE_TOKENFIELD_BORDER_COLOUR:OPEN_TOKENFIELD_BORDER_COLOUR];
            [tokenField setBackgroundColor:isSafe?SAFE_TOKENFIELD_BACKGROUND_COLOUR:OPEN_TOKENFIELD_BACKGROUND_COLOUR];
        }
        else
        {
            [superBox setShadow:nil];
            [superBox setFillColor:[NSColor whiteColor]];
            //[superBox setBorderColor:TOKENFIELD_BORDER_COLOUR];
            [tokenField setBackgroundColor:[NSColor whiteColor]];
        }
    }
}


#pragma mark - Setup message

- (void)showInvitationMessageForRecipients:(NSArray*)recipients style:(NSString*)styleString
{
    [ThreadHelper ensureMainThread];

    CGFloat screenHeight = NSHeight([[self.window screen] frame]);
    CGFloat screenWidth = NSWidth([[self.window screen] frame]);

    CGFloat height = screenHeight - 300;
    CGFloat width = 800;

    CGFloat xPos = screenWidth/2 - width/2;
    CGFloat yPos = screenHeight/2 - height/2;
    [self.window setFrame:NSMakeRect(xPos, yPos, width, height) display:YES];

    BOOL singleRecipient = (recipients.count==1);

    Recipient* sender = [AddressDataHelper standardSenderAsRecipient];

    [self.fromField setRecipients:@[sender] filterByType:YES];

    NSMutableArray* newRecipients = [NSMutableArray new];

    for(Recipient* recipient in recipients)
    {
        if([recipient isKindOfClass:[Recipient class]])
        {
            [recipient setType:TYPE_BCC];
            [newRecipients addObject:recipient];
        }
    }

    if(singleRecipient)
    {
        Recipient* recipient = recipients[0];

        [recipient setType:TYPE_TO];

        [self.toField setRecipients:@[recipient] filterByType:YES];
    }
    else
    {
        [self.bccField setRecipients:newRecipients filterByType:YES];
    }


    IMAPAccountSetting* fromAccountSetting = [AddressDataHelper senderAccountSetting];

    NSString* HTMLEmailWithFooter = [FormattingHelper invitationEmailToRecipients:newRecipients fromSender:sender.emailRecipient withFooter:fromAccountSetting.footer style:styleString];

    [self.subjectField setStringValue:NSLocalizedString(@"Invitation to Mynigma",@"Invitation email subject")];

    [self.bodyField.mainFrame loadHTMLString:HTMLEmailWithFooter baseURL:nil];

    //[self updateAttachmentNumber];

    if(!singleRecipient)
        [self showPopoverInfoWithText:NSLocalizedString(@"We have put the recipients in the BCC field so they won't see each other. You may want to edit the body to make it a little more personal before sending the message.", @"Invitation compose window popover") atRect:[self.bccField bounds] inView:self.bccField withUserDefaultsString:@"invitationInfoDismissal"];
}

- (void)showFreshEmptyMessage
{
    [ThreadHelper ensureMainThread];

    Recipient* sender = [AddressDataHelper standardSenderAsRecipient];

    if(sender)
        [self.fromField setRecipients:@[sender] filterByType:YES];

    IMAPAccountSetting* fromAccountSetting = [AddressDataHelper senderAccountSetting];

    NSString* HTMLEmailWithFooter = [FormattingHelper emptyEmailWithFooter:fromAccountSetting.footer];

    [self.bodyField.mainFrame loadHTMLString:HTMLEmailWithFooter baseURL:nil];

    [self updateSafeOrOpenStatus];

    //[self updateAttachmentNumber];
}

- (void)showFreshMessageToEmailRecipient:(EmailRecipient*)mailRecipient
{
    NSString* emptyEmail = [FormattingHelper emptyEmailWithFooter:nil];
    
    [self.bodyField.mainFrame loadHTMLString:emptyEmail baseURL:nil];
    
//    [self.subjectField setStringValue:NSLocalizedString(@"Feedback", @"Feedback message")];
    
    Recipient* recipient = mailRecipient.recipient;
    
    [recipient setType:TYPE_TO];
    
//    if(![recipient isSafe])
//        [PublicKeyManager addMynigmaInfoPublicKey];
//    
    [self.toField setRecipients:@[recipient] filterByType:YES];
    
    IMAPAccountSetting* fromAccountSetting = [AddressDataHelper senderAccountSetting];
    
    Recipient* myselfFrom = [[Recipient alloc] initWithEmail:fromAccountSetting.senderEmail andName:fromAccountSetting.senderName];
    [myselfFrom setType:TYPE_FROM];
    [self.fromField setRecipients:@[myselfFrom] filterByType:YES];
}


- (void)showFreshMessageToRecipients:(NSArray*)emailRecipients withSubject:(NSString*)subject body:(NSString*)htmlString
{
    if(!htmlString)
    {
    NSString* emptyEmail = [FormattingHelper emptyEmailWithFooter:nil];

        [self.bodyField.mainFrame loadHTMLString:emptyEmail baseURL:nil];
    }
    else
    {
        [HTMLPurifier cleanHTML:htmlString withCallBack:^(NSString *cleanedHTML, NSError *error) {

            [MAIN_CONTEXT performBlock:^{

                [self.bodyField.mainFrame loadHTMLString:cleanedHTML baseURL:nil];
            }];
        }];
    }

//    EmailRecipient* sender = [AddressDataHelper senderAmongRecipients:emailRecipients];
//
//    if(!sender)
//    {
//        sender = [AddressDataHelper standardSenderAsEmailRecipient];
//        emailRecipients = [emailRecipients arrayByAddingObject:sender];
//    }

    //show the user's own address first(!)
    NSArray* sortedRecipients = [emailRecipients sortedArrayUsingComparator:^NSComparisonResult(Recipient* rec1, Recipient* rec2) {
        BOOL rec1IsMine = [rec1.displayEmail isUsersAddress];
        BOOL rec2IsMine = [rec2.displayEmail isUsersAddress];

        if(rec1IsMine && !rec2IsMine)
            return NSOrderedAscending;

        if(!rec1IsMine && rec2IsMine)
            return NSOrderedDescending;

        return [rec1.displayEmail compare:rec2.displayEmail];
    }];

    [self.fromField setRecipients:sortedRecipients filterByType:YES];

    [self.toField setRecipients:sortedRecipients filterByType:YES];
    [self.ccField setRecipients:sortedRecipients filterByType:YES];
    [self.bccField setRecipients:sortedRecipients filterByType:YES];


    if([AddressDataHelper shouldShowReplyToForMessageInstance:self.composedMessageInstance])
        [self.replyToField setRecipients:sortedRecipients filterByType:YES];

    [self updateSafeOrOpenStatus];

    [self.toField setRecipients:emailRecipients filterByType:YES];

    IMAPAccountSetting* fromAccountSetting = [AddressDataHelper senderAccountSetting];

    Recipient* myselfFrom = [[Recipient alloc] initWithEmail:fromAccountSetting.senderEmail andName:fromAccountSetting.senderName];
    [myselfFrom setType:TYPE_FROM];

    [self.fromField setRecipients:@[myselfFrom] filterByType:YES];

    if(subject)
        [self.subjectField setStringValue:subject];
}


- (void)showNewFeedbackMessageInstance
{
    //EmailMessage* newDraftMessage = [EmailMessage newDraftMessageInContext:MAIN_CONTEXT];

    NSString* emptyEmail = [FormattingHelper emptyEmailWithFooter:nil];

    [self.bodyField.mainFrame loadHTMLString:emptyEmail baseURL:nil];

    [self.subjectField setStringValue:NSLocalizedString(@"Feedback", @"Feedback message")];

    Recipient* recipient = [[Recipient alloc] initWithEmail:@"info@mynigma.org" andName:@"Mynigma info"];
    [recipient setType:TYPE_TO];

    if(![recipient isSafe])
        [PublicKeyManager addMynigmaInfoPublicKey];

    [self.toField setRecipients:@[recipient] filterByType:YES];

    IMAPAccountSetting* fromAccountSetting = [AddressDataHelper senderAccountSetting];

    Recipient* myselfFrom = [[Recipient alloc] initWithEmail:fromAccountSetting.senderEmail andName:fromAccountSetting.senderName];
    [myselfFrom setType:TYPE_FROM];
    [self.fromField setRecipients:@[myselfFrom] filterByType:YES];

    //    EmailRecipient* myselfReplyTo = [EmailRecipient new];
    //    [myselfReplyTo setEmail:fromAccountSetting.senderEmail];
    //    [myselfReplyTo setName:fromAccountSetting.senderName];
    //    [myselfReplyTo setType:TYPE_REPLY_TO];
    //    [emailRecipients addObject:myselfReplyTo];

    //[self updateAttachmentNumber];
}

- (void)showNewBugReporterMessageInstance
{
    EmailMessage* newDraftMessage = [EmailMessage newDraftMessageInContext:MAIN_CONTEXT];

    if ([APPDELEGATE.crashReporter hasPendingCrashReport])
    {
        NSError* error = nil;

        PLCrashReportTextFormat textFormat = PLCrashReportTextFormatiOS;

        PLCrashReport* crashReport = [[PLCrashReport alloc] initWithData:[APPDELEGATE.crashReporter loadPendingCrashReportData] error:&error];
        NSString* crashReportString = [PLCrashReportTextFormatter stringValueForCrashReport:crashReport withTextFormat:textFormat];

        if (crashReportString)
        {
            NSEntityDescription* entity = [NSEntityDescription entityForName:@"FileAttachment" inManagedObjectContext:MAIN_CONTEXT];
            FileAttachment* newAttachment = [[FileAttachment alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];
            [newAttachment setAttachedToMessage:newDraftMessage];
            [newAttachment setAttachedAllToMessage:newDraftMessage];
            [newAttachment setContentType:@"application/octet-stream"];
            [newAttachment setFileName:@"report.crash"];
            [newAttachment setDownloadProgress:@1];

            NSData* attData = [crashReportString dataUsingEncoding:NSUTF8StringEncoding];
            [newAttachment saveDataToPrivateURL:attData];

            [newAttachment setSize:[NSNumber numberWithInteger:attData.length]];
        }

        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *logPath = [[documentsDirectory stringByExpandingTildeInPath] stringByAppendingPathComponent:@"console.log"];
        error = nil;
        NSString* consoleLog = [NSString stringWithContentsOfFile:logPath encoding:NSUTF8StringEncoding error:&error];
        if(error)
            NSLog(@"Error writing console.log file to string: %@",error);

        NSInteger consoleLogLength = 8*4096;

        NSString* briefConsoleLog = consoleLog.length>consoleLogLength?[consoleLog substringWithRange:NSMakeRange(consoleLog.length-consoleLogLength, consoleLogLength)]:consoleLog;
        if(briefConsoleLog.length>0)
        {
            NSEntityDescription* entity = [NSEntityDescription entityForName:@"FileAttachment" inManagedObjectContext:MAIN_CONTEXT];
            FileAttachment* newAttachment = [[FileAttachment alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];
            [newAttachment setAttachedToMessage:newDraftMessage];
            [newAttachment setAttachedAllToMessage:newDraftMessage];
            [newAttachment setContentType:@"application/octet-stream"];
            NSData* attData = [briefConsoleLog dataUsingEncoding:NSUTF8StringEncoding];
            [newAttachment setFileName:@"ConsoleLog.txt"];
            [newAttachment setSize:[NSNumber numberWithInteger:attData.length]];
            [newAttachment setDownloadProgress:@1];

            [newAttachment saveDataToPrivateURL:attData];
        }
    }

    NSString* htmlBody = [NSLocalizedString(@"Dear Mynigma team,\n\nmy app crashed the last time I used it.\n\nPlease look into the problem and fix it as soon as possible.\n\nSincerely,\n\nUnhappy user", @"Standard crash report text") stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];

    if(!htmlBody)
        htmlBody = @"";

    [newDraftMessage.messageData setHtmlBody:htmlBody];
    [newDraftMessage.messageData setSubject:@"Bug report"];

    [APPDELEGATE.crashReporter purgePendingCrashReport];

    [newDraftMessage setDateSent:[NSDate date]];




    IMAPAccountSetting* fromAccountSetting = [AddressDataHelper senderAccountSetting];

    [newDraftMessage.messageData setFromName:fromAccountSetting.senderName];

    EmailMessageInstance* messageInstance = [EmailMessageInstance findOrMakeNewInstanceForMessage:newDraftMessage inFolder:fromAccountSetting.draftsFolder inContext:MAIN_CONTEXT];


    [messageInstance setFlags:[NSNumber numberWithInt:MCOMessageFlagSeen]];
    [messageInstance setAddedToFolder:messageInstance.inFolder];

    [messageInstance changeUID:nil];

    [newDraftMessage.messageData setLoadRemoteImages:@YES];


    NSMutableArray* emailRecipients = [NSMutableArray new];

    EmailRecipient* recipient = [EmailRecipient new];
    [recipient setName:@"Mynigma info"];
    [recipient setEmail:@"info@mynigma.org"];
    [recipient setType:TYPE_TO];
    [emailRecipients addObject:recipient];

    if(![recipient isSafe])
        [PublicKeyManager addMynigmaInfoPublicKey];

    EmailRecipient* myselfFrom = [EmailRecipient new];
    [myselfFrom setEmail:fromAccountSetting.senderEmail];
    [myselfFrom setName:fromAccountSetting.senderName];
    [myselfFrom setType:TYPE_FROM];
    [emailRecipients addObject:myselfFrom];

    EmailRecipient* myselfReplyTo = [EmailRecipient new];
    [myselfReplyTo setEmail:fromAccountSetting.senderEmail];
    [myselfReplyTo setName:fromAccountSetting.senderName];
    [myselfReplyTo setType:TYPE_REPLY_TO];
    [emailRecipients addObject:myselfReplyTo];

    NSMutableData* addressData = [NSMutableData new];
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:addressData];
    [archiver encodeObject:emailRecipients forKey:@"recipients"];
    [archiver finishEncoding];

    [newDraftMessage.messageData setAddressData:addressData];

    [self setComposedMessageInstance:messageInstance];

    [self fillDisplayWithComposedMessageInstance];
}

/**CALL ON MAIN*/
- (void)showDraftMessageInstance:(EmailMessageInstance*)messageInstance
{
    [ThreadHelper ensureMainThread];

    [self setComposedMessageInstance:messageInstance];

    EmailMessage* message = messageInstance.message;

    [self.subjectField setStringValue:message.messageData.subject?message.messageData.subject:@""];
    NSData* recData = message.messageData.addressData;
    NSArray* recArray = [AddressDataHelper recipientsForAddressData:recData];

    Recipient* fromRecipient = nil;
    Recipient* replyToRecipient = nil;

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

    [self.replyToField setRecipients:sortedRecipients filterByType:YES];

    [self.toField setRecipients:sortedRecipients filterByType:YES];
    [self.ccField setRecipients:sortedRecipients filterByType:YES];
    [self.bccField setRecipients:sortedRecipients filterByType:YES];


    if(replyToRecipient && !([replyToRecipient.displayEmail isEqualToString:fromRecipient.displayEmail]))
        [self.replyToField setRecipients:@[replyToRecipient] filterByType:YES];

    [self updateSafeOrOpenStatus];

    //need to set attachments to controller
    for(FileAttachment* attachment in messageInstance.message.allAttachments)
    {
        FileAttachment* freshCopy = [attachment copyInContext:MAIN_CONTEXT];
        
        [self.attachmentsView addAttachment:freshCopy];
    }
    
    //[self updateAttachmentNumber];
    NSString* htmlBody = message.messageData.htmlBody;
    [self.bodyField.mainFrame loadHTMLString:htmlBody baseURL:nil];
    
    //save a copy of the draft into the bin folder
    //just in case the user wants to revert to the old copy
    //as opposed to the current one (default for saves is to overwrite irretrievably)
    [self saveMessageByUsingExistingDraft:message andOverwritingPreviousCopy:YES properDelete:NO asSafe:YES forSending:NO withCallback:nil];

}

- (void)setFieldsForReplyToMessageInstance:(EmailMessageInstance*)messageInstance
{
    [self setComposedMessageInstance:[FormattingHelper replyToMessageInstance:messageInstance]];

    [self setReplyToMessageInstance:messageInstance];

    [self fillDisplayWithComposedMessageInstance];
}

- (void)setFieldsForReplyAllToMessageInstance:(EmailMessageInstance*)messageInstance
{
    [self setComposedMessageInstance:[FormattingHelper replyAllToMessageInstance:messageInstance]];

    [self setReplyToMessageInstance:messageInstance];

    [self fillDisplayWithComposedMessageInstance];
}

- (void)setFieldsForForwardOfMessageInstance:(EmailMessageInstance*)messageInstance
{
    [self setComposedMessageInstance:[FormattingHelper forwardOfMessageInstance:messageInstance]];

    [self setForwardOfMessageInstance:messageInstance];

    [self fillDisplayWithComposedMessageInstance];
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

- (void)fillWithTemplate:(MessageTemplate*)messageTemplate
{
    [self showFreshEmptyMessage];

    [self.bodyField.mainFrame loadHTMLString:messageTemplate.htmlBody baseURL:nil];

    if(messageTemplate.subject.length>0)
    {
        [self.subjectField setStringValue:messageTemplate.subject];
    }

    NSArray* emailRecipients = [AddressDataHelper recipientsForAddressData:messageTemplate.recipients];

    Recipient* fromRecipient = nil;
    Recipient* replyToRecipient = nil;

    //show the user's own address first(!)
    NSArray* sortedRecipients = [emailRecipients sortedArrayUsingComparator:^NSComparisonResult(Recipient* rec1, Recipient* rec2) {
        BOOL rec1IsMine = [rec1.displayEmail isUsersAddress];
        BOOL rec2IsMine = [rec2.displayEmail isUsersAddress];

        if(rec1IsMine && !rec2IsMine)
            return NSOrderedAscending;

        if(!rec1IsMine && rec2IsMine)
            return NSOrderedDescending;

        return [rec1.displayEmail compare:rec2.displayEmail];
    }];

    [self.fromField setRecipients:sortedRecipients filterByType:YES];

    [self.replyToField setRecipients:sortedRecipients filterByType:YES];

    [self.toField setRecipients:sortedRecipients filterByType:YES];
    [self.ccField setRecipients:sortedRecipients filterByType:YES];
    [self.bccField setRecipients:sortedRecipients filterByType:YES];


    if(replyToRecipient && !([replyToRecipient.displayEmail isEqualToString:fromRecipient.displayEmail]))
        [self.replyToField setRecipients:@[replyToRecipient] filterByType:YES];

    [self updateSafeOrOpenStatus];

    for(FileAttachment* attachment in messageTemplate.allAttachments)
    {
        FileAttachment* freshCopy = [attachment copyInContext:MAIN_CONTEXT];

        [self.attachmentsView addAttachment:freshCopy];

        //        if([messageTemplate.attachments containsObject:attachment])
        //            [self.attachments addObject:freshCopy];
    }

    //[self updateAttachmentNumber];
}



#pragma mark - Recipients and display setup

- (NSArray*)recipients
{
    NSMutableArray* returnValue = [NSMutableArray new];

    [returnValue addObjectsFromArray:self.fromField.recipients];
    [returnValue addObjectsFromArray:self.replyToField.recipients];
    [returnValue addObjectsFromArray:self.toField.recipients];
    [returnValue addObjectsFromArray:self.ccField.recipients];
    [returnValue addObjectsFromArray:self.bccField.recipients];

    return returnValue;
}


- (void)fillDisplayWithComposedMessageInstance
{
    self.isDirty = NO;

    //    if(!self.forwardOfMessageInstance)
    //        [self.window makeFirstResponder:self.bodyField];
    //

    [self.attachmentsView showAttachments:self.composedMessageInstance.message.allAttachments];

    //[self setAllAttachments:[[self.composedMessageInstance.message.allAttachments sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"fileName" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"contentid" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"uniqueID" ascending:YES]]] mutableCopy]];

    //[self setAttachments:[[self.composedMessageInstance.message.attachments sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"fileName" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"contentid" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"uniqueID" ascending:YES]]] mutableCopy]];

    //[self updateAttachmentNumber];

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

        [self.fromField setRecipients:sortedRecipients filterByType:YES];

        [self.toField setRecipients:sortedRecipients filterByType:YES];
        [self.ccField setRecipients:sortedRecipients filterByType:YES];
        [self.bccField setRecipients:sortedRecipients filterByType:YES];


        if([AddressDataHelper shouldShowReplyToForMessageInstance:self.composedMessageInstance])
            [self.replyToField setRecipients:sortedRecipients filterByType:YES];

        [self updateSafeOrOpenStatus];

        NSString* subject = self.composedMessageInstance.message.messageData.subject;

        if(!subject)
            subject = @"";

        [self.subjectField setStringValue:subject];

        [self.bodyField.mainFrame loadHTMLString:self.composedMessageInstance.message.messageData.htmlBody baseURL:nil];


        //IMAPAccountSetting* fromAccountSetting = [AddressDataHelper sendingAccountSettingForMessage:self.composedMessageInstance.message];

        //[FormattingHelper changeHTMLEmail:self.bodyField.mainFrameDocument toFooter:fromAccountSetting.footer];

    }
}





#pragma mark - Drag & drop

- (void)webView:(WebView *)sender willPerformDragDestinationAction:(WebDragDestinationAction)action forDraggingInfo:(id < NSDraggingInfo >)draggingInfo
{
    if ([draggingInfo draggingSource] == nil)
    {
        NSPasteboard *pboard = [draggingInfo draggingPasteboard];

        if ([[pboard types] containsObject:NSFilenamesPboardType])
        {
            NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];

            //if it's a single image, display it inline(!)
            if(files.count==1)
            {
                NSString* fileName = files[0];

                NSString* extension = [[fileName pathExtension] lowercaseString];

                if(extension)
                    if([@[@"png", @"jpeg", @"jpg", @"gif", @"tiff"] containsObject:extension])
                    {
                        //OK, it's an image that can be displayed inline

                        NSURL* url = [NSURL fileURLWithPath:fileName];

                        NSEntityDescription* entity = [NSEntityDescription entityForName:@"FileAttachment" inManagedObjectContext:MAIN_CONTEXT];
                        FileAttachment* newAttachment = [[FileAttachment alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];

                        [newAttachment setFileName:[url.path lastPathComponent]];

                        [url startAccessingSecurityScopedResource];

                        NSError* error = nil;

                        NSData* imageData = [NSData dataWithContentsOfURL:url options:0 error:&error];

                        if(error)
                        {
                            NSLog(@"Error getting image data from URL: %@ - %@", url, error);

                        }

                        NSData* publicURLBookmark = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:&error];

                        if(error)
                        {
                            NSLog(@"Error creating bookmark for dragged & dropped URL: %@", error);

                            NSAlert* alert = [NSAlert alertWithMessageText:@"Error creating bookmark" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"No bookmark could be created for the selected file"];

                            [alert runModal];
                        }

                        [newAttachment setPublicBookmark:publicURLBookmark];

                        [newAttachment saveDataToPrivateURL:imageData];

                        [newAttachment setName:newAttachment.fileName];

                        [url stopAccessingSecurityScopedResource];

                        NSString* contentID = [@"inline@mynigma.org" generateMessageID];

                        [newAttachment setContentid:contentID];

                        [newAttachment setSize:@(imageData.length)];

                        [newAttachment setDownloadProgress:@1.1];

//                        AttachmentItem* newItem = [AttachmentItem new];
//                        [newItem setName:newAttachment.fileName];
//
//                        [newItem setImage:newAttachment.thumbnail];
//
//                        [newItem setFileAttachment:newAttachment];

                        NSSize maximumSize = NSMakeSize(500, 500);

                        NSImage* image = [[NSImage alloc] initWithData:newAttachment.data];

                        NSSize imageSize = image.size;

                        CGFloat scaleFactor = 1;

                        if(imageSize.height > maximumSize.height)
                            scaleFactor = maximumSize.height/imageSize.height;

                        if(imageSize.width > maximumSize.width)
                        {
                            CGFloat newScaleFactor = maximumSize.width/imageSize.width;
                            if(newScaleFactor < scaleFactor)
                                scaleFactor = newScaleFactor;
                        }

                        NSString* sizeString = @"";

                        if(scaleFactor < .99)
                            sizeString = [NSString stringWithFormat:@" height='%ld' width='%ld'", (long)(imageSize.height*scaleFactor), (long)(imageSize.width*scaleFactor)];

                        NSString* htmlInsertion = [NSString stringWithFormat:@"<img src='cid:%@'%@>", contentID, sizeString];

                        [pboard clearContents];

                        [pboard declareTypes: [NSArray arrayWithObject: NSHTMLPboardType] owner: nil];

                        [pboard setString:htmlInsertion forType:NSHTMLPboardType];

                        [self.attachmentsView addAttachment:newAttachment];

                        [self setIsDirty:YES];
                        //[self updateAttachmentNumber];

                        return;
                    }

                //not an image, so use default behaviour (attach expicitly)
            }


            //otherwise go through the list and add each as an explicit attachment
            for(NSString* fileName in files)
            {
                NSURL* url = [NSURL fileURLWithPath:fileName];

                NSSet* allAttachments = [[NSSet setWithArray:self.attachmentsArrayController.arrangedObjects] valueForKey:@"fileAttachment"];

                if(![[allAttachments valueForKey:@"publicURLString"] containsObject:url.path])
                {
                    FileAttachment* newAttachment = [FileAttachment makeNewAttachmentFromURL:url];

                    if(newAttachment)
                    {
//                        AttachmentItem* newItem = [AttachmentItem new];
//                        [newItem setName:newAttachment.fileName];
//                        [newItem setImage:newAttachment.thumbnail];
//                        [newItem setFileAttachment:newAttachment];
                        [self.attachmentsView addAttachment:newAttachment];

                        [self setIsDirty:YES];
                    }
                }
            }
            //[self updateAttachmentNumber];
        }

        [pboard setPropertyList:@[] forType:NSFilenamesPboardType];

        [pboard declareTypes: [NSArray arrayWithObject:NSStringPboardType] owner: pboard];
        [pboard setString:@"" forType:NSStringPboardType];

    }
}

#pragma mark - WebResourceLoadDelegate

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource
{
    NSMutableString* requestString = [[[request URL] absoluteString] mutableCopy];
    if([[[request URL] absoluteString] hasPrefix:@"cid:"])
    {
        [requestString deleteCharactersInRange:NSMakeRange(0,4)];

        NSArray* allAttachments = [self.attachmentsView allAttachments];

        for(FileAttachment* attachment in allAttachments)
            if([attachment.contentid isEqualToString:requestString])
            {
                NSURL* privateURL = [attachment privateURL];

                if(privateURL)
                    return [[NSMutableURLRequest alloc] initWithURL:privateURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];

                NSURL* publicURL = [attachment publicURL];

                //this will fail in a sandboxed app
                if(publicURL)
                    return [[NSMutableURLRequest alloc] initWithURL:publicURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];

                return [[NSMutableURLRequest alloc] initWithURL:request.URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
            }
    }
    else
    {
        //NSLog(@"Not a cid request: %@",request);
        //[messageInstance.message.messageData setHasImages:[NSNumber numberWithBool:YES]];
        //if(messageInstance.message.messageData.loadRemoteImages.boolValue)
        return [[NSMutableURLRequest alloc] initWithURL:[request URL] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:30.0];
        //return request;
        //        else
        //                {
        //                    [contentView.showImagesLabel setHidden:NO];
        //                }
        //            }
        //        }
    }
    return [[NSMutableURLRequest alloc] initWithURL:[[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"placeholder.png"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
}

//- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource
//{
//    NSMutableString* requestString = [[[request URL] absoluteString] mutableCopy];
//    if([[[request URL] absoluteString] hasPrefix:@"cid:"])
//    {
//        [requestString deleteCharactersInRange:NSMakeRange(0,4)];
//        //requestString = [NSMutableString stringWithFormat:@"<%@>",[requestString copy]];
//        for(FileAttachment* attachment in message.allAttachments)
//            if([attachment.contentid isEqualToString:requestString])
//            {
//                if(attachment.bookmark)
//                {
//                    NSError* error = nil;
//                    NSURL *fileURL = [NSURL URLByResolvingBookmarkData:attachment.bookmark options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:NO error:&error];
//                    if(!error)
//                    {
//                        return [[NSMutableURLRequest alloc] initWithURL:fileURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
//                    }
//                    else
//                        NSLog(@"Could not create attachment URL from bookmark");
//                }
//                //else
//                //  NSLog(@"Could not find attachment bookmark. request string: %@",requestString); <- this is quite normal: message is usually loaded before attachments have been fetched
//            }
//                /* for(InlineAttachment* inlineAttachment in message.inlineAttachments)
//                 {
//                 if([inlineAttachment.contentid isEqualToString:requestString])
//                 {
//                 [[NSMutableURLRequest alloc] initWI]
//                 }
//                 }*/
//
//        }
//        else
//        {
//            //NSLog(@"Not a cid request: %@",request);
//            [self.replyToMessage setHasImages:[NSNumber numberWithBool:YES]];
//            if(message.loadRemoteImages.boolValue)
//                return [[NSMutableURLRequest alloc] initWithURL:[request URL] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:30.0];
//            //return request;
//            else
//            {
//                [contentView.showImagesLabel setHidden:NO];
//            }
//        }
//        /*
//            FileAttachment* fileAttachment = (FileAttachment*)[APPDELEGATE.viewerArray objectAtIndex:row];
//             if(fileAttachment && [fileAttachment isKindOfClass:[FileAttachment class]])*/
//    }
//}
//    return [[NSMutableURLRequest alloc] initWithURL:[[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"placeholder.png"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
//}


#pragma mark - WebView editing delegate

- (void)webViewDidChange:(NSNotification *)notification
{
    self.isDirty = YES;
}

- (BOOL)webView:(WebView *)webView shouldInsertNode:(DOMNode *)node replacingDOMRange:(DOMRange *)range givenAction:(WebViewInsertAction)action
{
    return YES;
}

- (BOOL)webView:(WebView *)webView shouldInsertText:(NSString *)text replacingDOMRange:(DOMRange *)range givenAction:(WebViewInsertAction)action
{
    if([text isEqualTo:@"\n"])
    {
        //TO DO: be a litle more specific
        //TO DO: allow multiple layers of blockquotes
        //TO DO: tweak the style of the blockquotes to make this behave in the most intuitive & practically useful way possible
        if([range.startContainer.nodeName isEqualTo:@"BLOCKQUOTE"])
        {
            [webView replaceSelectionWithMarkupString:@"</blockquote><br><br><blockquote type=\"cite\">"];

            //TO DO: change selection - currently the entire insertion is selected
            //
            //

            //already inserted the text, so return NO
            return NO;
        }
    }
    return YES;
}



#pragma mark - WebView loading delegate

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    //the body web view has loaded some html - probably the message being replied to, etc.
    //make it the first responder
    if(self.toField.tokens.count > 0)
        [self.window makeFirstResponder:sender];
    else
        [self.window makeFirstResponder:self.toField];
}

#pragma mark - WebView policy delegate

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id < WebPolicyDecisionListener >)listener
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


- (void)recipientTokenField:(RecipientTokenField*)tokenField addedRecipient:(Recipient*)recipient
{
    [self setIsDirty:YES];

    [self updateSafeOrOpenStatus];
    [self setCorrectShadow:tokenField];

    if(recipient.type==TYPE_FROM)
    {
        //remove attachments from previous footer
        NSArray* allPreviousAttachments = [self.attachmentsView.allAttachments copy];
        for(FileAttachment* attachment in allPreviousAttachments)
        {
            if(attachment.inlineImageForFooter)
                [self.attachmentsView removeAttachments:@[attachment]];
        }


        IMAPAccountSetting* fromAccountSetting = [IMAPAccountSetting accountSettingForSenderEmail:recipient.displayEmail];

        //move the message to the drafts folder of the new sending account
        if(![self.composedMessageInstance isInDraftsFolder])
        {
            [self.composedMessageInstance moveToDrafts];
        }

        EmailFooter* newFooter = fromAccountSetting.footer;

        [self.attachmentsView addAttachmentsFromSet:newFooter.inlineImages];

        [FormattingHelper changeHTMLEmail:[self.bodyField mainFrameDocument] toFooter:fromAccountSetting.footer];
    }

    //show the popover if the recipient is open, the "don't show this again" button was never pressed and the token field is not one used to select sender addresses, as opposed to proper recipients
    if(![recipient isSafe] && [UserSettings currentUserSettings].showNewbieExplanations.boolValue && !tokenField.useSenderAddressesForMenu)
    {
        [self showPopoverInfoWithText:nil atRect:[tokenField boundsOfTokenWithRecipient:recipient] inView:tokenField withUserDefaultsString:@"newbieOpenExplanationDismissal"];
    }


#if ULTIMATE

    //check unsafe recipients with the server (if necessary)
    if(![recipient isSafe])
    {
        //this will use the last date this recipient was checked to determine if another check is necessary
        [PublicKeyManager typedRecipient:recipient quickCheckWithCallback:^(BOOL found){
            
            if(found)
            {
                [tokenField updateTintColours];

                [self setCorrectShadow:tokenField];
                [self updateSafeOrOpenStatus];
                
                if(self.popoverController)
                {
                    [self.popoverController.popover close];
                }
            }
        }];
    }
    
#endif
    
}



- (void)recipientTokenField:(RecipientTokenField*)tokenField removedRecipient:(Recipient*)recipient
{
    [self setIsDirty:YES];
    
    [self setCorrectShadow:tokenField];
    [self updateSafeOrOpenStatus];
}

- (void)showPopoverInfoWithText:(NSString*)text atRect:(NSRect)rect inView:(NSView*)view withUserDefaultsString:(NSString*)userDefaultsString
{
    if(self.popoverController && userDefaultsString)
    {
        //don't show it if it has previously been dismissed using the "don't show again" button
        if(![[NSUserDefaults standardUserDefaults] objectForKey:userDefaultsString])
        {
            [self.popoverController setUserDefaultsString:userDefaultsString];
            
            if(text)
                [self.popoverController.popoverLabel setStringValue:text];
            [self.popoverController.popover showRelativeToRect:rect ofView:view preferredEdge:NSMaxYEdge];
        }
    }
}



- (IBAction)printDocument:(id)sender
{
    [ThreadHelper ensureMainThread];
    
    [self saveMessageByOverwritingPreviousCopy:YES properDelete:YES asSafe:YES forSending:NO withCallback:^(MynigmaFeedback* feedback)
    {
        if(!feedback.isSuccess)
        {
            NSLog(@"Failed to encrypt message while saving!!!");
            [AlertHelper showAlertWithMessage:NSLocalizedString(@"An error occurred.", @"Generic error") informativeText:NSLocalizedString(@"We regret that Mynigma was unable to save your message. Please submit a bug report to help us fix the problem. Thank you!", @"Saving message failed")];
            NSBeep();
        }
        else
        {
            [PrintingHelper printMessageObjects:@[self.composedMessageInstance]];
        }
    }];
}

//-(BOOL)collectionView:(NSCollectionView *)collectionView writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard
//{
//    NSInteger index = indexes.firstIndex;
//
//    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
//    [pboard clearContents];
//
//    //[pboard declareTypes:<#(NSArray *)#> owner:<#(id)#>]
//
//    while(index!=NSNotFound)
//    {
//        FileAttachment* attachment = [self.attachmentsArrayController.arrangedObjects objectAtIndex:index];
//
//        NSURL* URL = attachment.URL;
//        
//        //[pboard writeObjects:<#(NSArray *)#>]
//
//        index = [indexes indexGreaterThanIndex:index];
//    }
//
//
//    [pboard declareTypes:@[NSURLPboardType, NSFilenamesPboardType] owner:nil];
//
//
//
//    //[URL writeToPasteboard:pboard];
//
//     return YES;
//}
//
//- (BOOL)collectionView:(NSCollectionView *)collectionView acceptDrop:(id<NSDraggingInfo>)draggingInfo index:(NSInteger)index dropOperation:(NSCollectionViewDropOperation)dropOperation {
//    NSPasteboard *pBoard = [draggingInfo draggingPasteboard];
//    NSData *indexData = [pBoard dataForType:@"my_drag_type_id"];
//    NSIndexSet *indexes = [NSKeyedUnarchiver unarchiveObjectWithData:indexData];
//    NSInteger draggedCell = [indexes firstIndex];
//
//
//    return YES;
//}
//
//- (BOOL)collectionView:(NSCollectionView *)collectionView canDragItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event
//{
//    return YES;
//}

- (void)playLockSound:(id)sender
{
    NSSound* sound = [NSSound soundNamed:@"locked.mp3"];
    [sound play];
}

- (void)closeMetalSheetWithDuration:(CGFloat)duration andCallback:(void(^)(void))callback
{
    //disabled for the moment (awaiting better graphics)

    if(callback)
        callback();

    return;

    if(self.isSafeMessage)
    {
        NSSound* sound = [NSSound soundNamed:@"locked.mp3"];

        //[self performSelector:@selector(playLockSound:) withObject:nil afterDelay:duration/3.];

    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:duration];
    [[NSAnimationContext currentContext] setAllowsImplicitAnimation:YES];
    [[NSAnimationContext currentContext] setCompletionHandler:^{
        [sound play];

//        NSImage* patternImage = [NSImage imageNamed:@"doorSheetFlipped"];
//
//        //[patternImage setScalesWhenResized:YES];
//        [self.topMetalSheetImageView setFillColor:[NSColor colorWithPatternImage:patternImage]];
//
//        patternImage = [NSImage imageNamed:@"doorSheet"];
//
//        [self.bottomMetalSheetImageView setFillColor:[NSColor colorWithPatternImage:patternImage]];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

            if(callback)
                callback();
        });
    }];

//        [self.topMetalSheetHideConstraint.animator setPriority:1];
//        [self.bottomMetalSheetHideConstraint.animator setPriority:1];
//
//        [self.topMetalSheetShowConstraint.animator setPriority:999];
//        [self.bottomMetalSheetShowConstraint.animator setPriority:999];

//        [self.metalSheetView layoutSubtreeIfNeeded];

        [NSAnimationContext endGrouping];
    }
    else if(callback)
        callback();
}

- (void)playSwishSoundAndMoveOutWindow
{
    //play the swish sound
    if(![self isSafeMessage])
        [[NSSound soundNamed:@"swish.mp3"] play];
    NSRect frame = self.window.frame;
    NSRect mainScreenFrame = [NSScreen mainScreen].frame;

    //    if(self.isSafeMessage)
    //    {
    //        [NSAnimationContext beginGrouping];
    //        [[NSAnimationContext currentContext] setDuration:.6];
    //        [self.bodyShrinkConstraint setPriority:999];
    //        [self.window layoutIfNeeded];
    //        [NSAnimationContext endGrouping];
    //
    //        [NSAnimationContext beginGrouping];
    //        [[NSAnimationContext currentContext] setDuration:.4];
    //        [self.window setFrame:NSMakeRect(mainScreenFrame.origin.x+mainScreenFrame.size.width,mainScreenFrame.origin.y,frame.size.width,mainScreenFrame.size.height) display:YES animate:YES];
    //        [NSAnimationContext endGrouping];
    //
    //
    //    }
    //    else
//    {
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:.4];
        [self.window setFrame:NSMakeRect(mainScreenFrame.origin.x+mainScreenFrame.size.width,mainScreenFrame.origin.y,frame.size.width,mainScreenFrame.size.height) display:YES animate:YES];

[[NSAnimationContext currentContext] setCompletionHandler:^{

    [self prepareWebViewForWindowClosing];

    [self.window setIsVisible:NO];

    [self.window setFrame:frame display:NO];

    [self.window close];
}];

        [NSAnimationContext endGrouping];
//    }

}


//- (NSUndoManager *)undoManagerForWebView:(WebView *)webView
//{
//    if(!self.webViewUndoManager)
//        self.webViewUndoManager = [NSUndoManager new];
//
//    return self.webViewUndoManager;
//}

@end
