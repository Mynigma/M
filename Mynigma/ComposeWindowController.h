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





#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "RecipientTokenField.h"

@class AttachmentAdditionController, IMAPAccountSetting, EmailMessageInstance, EmailMessage, MessageTemplate, TemplateNameController, RecipientTokenField, PopoverViewController, EmailRecipient, AttachmentsIconView, MynigmaFeedback;

@interface ComposeWindowController : NSWindowController <RecipientDelegate>

@property NSUndoManager* undoManager;

@property EmailMessageInstance* composedMessageInstance;

@property EmailMessageInstance* replyToMessageInstance;
@property EmailMessageInstance* forwardOfMessageInstance;

@property IBOutlet NSTextField* subjectField;
@property IBOutlet WebView* bodyField;

@property IBOutlet NSButton* sendButton;
@property IBOutlet NSButton* attachmentButton;

@property IBOutlet NSBox* toFieldBox;
@property IBOutlet NSBox* replyToFieldBox;
@property IBOutlet NSBox* ccFieldBox;
@property IBOutlet NSBox* bccFieldBox;

@property IBOutlet NSTextField* safeLabel;

@property IBOutlet NSTextField* numberOfAttachmentsLabel;

@property IBOutlet NSButton* ccBccButton;

@property IBOutlet NSBox* bodyFieldBox;

@property IBOutlet NSImageView* lockView;

@property IBOutlet NSProgressIndicator* progressIndicator;

@property AttachmentAdditionController* sheetController;

@property BOOL isDirty;
@property BOOL showCCAndBcc;


@property BOOL isSafeMessage;

- (void)updateSafeOrOpenStatus;

@property IBOutlet RecipientTokenField* fromField;
@property IBOutlet RecipientTokenField* toField;
@property IBOutlet RecipientTokenField* ccField;
@property IBOutlet RecipientTokenField* bccField;
@property IBOutlet RecipientTokenField* replyToField;

@property IBOutlet NSBox* toBox;
@property IBOutlet NSBox* fromBox;
@property IBOutlet NSBox* ccBox;
@property IBOutlet NSBox* bccBox;
@property IBOutlet NSBox* replyToBox;
@property IBOutlet NSBox* topBox;
@property IBOutlet NSBox* subjectBox;
@property IBOutlet NSBox* bodyBox;


- (void)saveMessageByOverwritingPreviousCopy:(BOOL)overwrite properDelete:(BOOL)properDelete asSafe:(BOOL)shouldBeSafe forSending:(BOOL)isForSending withCallback:(void(^)(MynigmaFeedback* feedback))callback;


- (IBAction)sendMessage:(id)sender;
- (IBAction)saveMessage:(id)sender;

- (void)autosave:(NSTimer*)timer;

- (IBAction)addAttachment:(id)sender;

- (void)showFreshEmptyMessage;

- (void)showFreshMessageToEmailRecipient:(EmailRecipient*)mailRecipient;

- (void)showFreshMessageToRecipients:(NSArray*)emailRecipients withSubject:(NSString*)subject body:(NSString*)htmlString;

- (void)showNewFeedbackMessageInstance;

- (void)showNewBugReporterMessageInstance;

- (void)showDraftMessageInstance:(EmailMessageInstance*)messageInstance;

- (void)setFieldsForReplyToMessageInstance:(EmailMessageInstance*)messageInstance;

- (void)setFieldsForReplyAllToMessageInstance:(EmailMessageInstance*)messageInstance;

- (void)setFieldsForForwardOfMessageInstance:(EmailMessageInstance*)messageInstance;

- (void)setFieldsForReplyToMessage:(EmailMessage*)message;

- (void)setFieldsForReplyAllToMessage:(EmailMessage*)message;

- (void)setFieldsForForwardOfMessage:(EmailMessage*)message;

///fires at regular intervals to autosave the composed message
@property NSTimer* autosaveTimer;

- (void)fillWithTemplate:(MessageTemplate*)messageTemplate;

- (void)showInvitationMessageForRecipients:(NSArray*)emailRecipients style:(NSString*)styleString;

- (NSArray*)recipients;

@property TemplateNameController* templateNameController;

@property IBOutlet PopoverViewController* popoverController;

@property IBOutlet NSToolbar* toolBar;

@property IBOutlet NSLayoutConstraint* bodyShrinkConstraint;

@property IBOutlet NSLayoutConstraint* attachmentsListConstraint;

@property IBOutlet AttachmentsIconView* attachmentsView;

@property IBOutlet NSArrayController* attachmentsArrayController;

@property IBOutlet NSLayoutConstraint* topMetalSheetHideConstraint;

@property IBOutlet NSLayoutConstraint* topMetalSheetShowConstraint;

@property IBOutlet NSLayoutConstraint* bottomMetalSheetHideConstraint;

@property IBOutlet NSLayoutConstraint* bottomMetalSheetShowConstraint;

@property IBOutlet NSBox* topMetalSheetImageView;

@property IBOutlet NSBox* bottomMetalSheetImageView;

@property IBOutlet NSView* metalSheetView;

//@property NSUndoManager* webViewUndoManager;

@end
