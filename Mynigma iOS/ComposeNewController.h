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





#import <UIKit/UIKit.h>
#import "TITokenField.h"




@class EmailMessage, Recipient, TITokenField, TITokenFieldView, IMAPAccountSetting, EmailMessageInstance, MynTokenFieldController, MynTokenIBField, BodyInputView, SafeDoorsView;



@interface ComposeNewController : UIViewController <UITextFieldDelegate, UIGestureRecognizerDelegate, TITokenFieldDelegate, UIActionSheetDelegate, UIPopoverPresentationControllerDelegate, UIViewControllerTransitioningDelegate>
{
    BOOL recipientsExpanded;
}

@property(nonatomic, weak) EmailMessageInstance* composedMessageInstance;
@property(nonatomic, weak) EmailMessageInstance* replyToMessageInstance;
@property(nonatomic, weak) EmailMessageInstance* forwardOfMessageInstance;

@property(nonatomic, weak) IBOutlet BodyInputView* bodyView;

@property(nonatomic, weak) IBOutlet UITextView* editView;

- (IBAction)cancelButton:(id)sender;

@property(nonatomic, weak) IBOutlet NSLayoutConstraint* keyboardMarginConstraint;

@property(nonatomic, weak) IBOutlet NSLayoutConstraint* contentHeightConstraint;

@property(nonatomic, weak) IBOutlet NSLayoutConstraint* hideBodyFieldConstraint;
@property(nonatomic, weak) IBOutlet NSLayoutConstraint* hideEditFieldConstraint;

@property(nonatomic, weak) IBOutlet NSLayoutConstraint* widthConstraint;

@property(nonatomic, weak) IBOutlet NSLayoutConstraint* fromRightMarginConstraint;

@property(nonatomic, weak) IBOutlet NSLayoutConstraint* attachmentsViewHeightConstraint;

@property(nonatomic, weak) IBOutlet UITextField* subjectField;


@property(weak, nonatomic) IBOutlet SafeDoorsView* doorsView;

@property(nonatomic, weak) IBOutlet MynTokenIBField* toView;
@property(nonatomic, weak) IBOutlet MynTokenIBField* fromView;
@property(nonatomic, weak) IBOutlet MynTokenIBField* replyToView;
@property(nonatomic, weak) IBOutlet MynTokenIBField* ccView;
@property(nonatomic, weak) IBOutlet MynTokenIBField* bccView;

@property(nonatomic, weak) IBOutlet UIScrollView* scrollView;

@property(nonatomic, weak) IBOutlet UIBarButtonItem* backButton;
@property(nonatomic, weak) IBOutlet UIBarButtonItem* sendButton;

@property(nonatomic, weak) IBOutlet UIView* extraFieldsView;
@property(nonatomic, weak) IBOutlet NSLayoutConstraint* extraFieldsConstraint;
@property(nonatomic, weak) IBOutlet UIButton* extraFieldsButton;


//- (void)setFieldsForReplyToMessageInstance:(EmailMessageInstance*)messageInstance;
//- (void)setFieldsForReplyAllToMessageInstance:(EmailMessageInstance*)messageInstance;
//- (void)setFieldsForForwardOfMessageInstance:(EmailMessageInstance*)messageInstance;


- (void)startReplyToMessageInstance:(EmailMessageInstance*)messageInstance;
- (void)startReplyAllToMessageInstance:(EmailMessageInstance*)messageInstance;
- (void)startForwardOfMessageInstance:(EmailMessageInstance*)messageInstance;
- (void)showDraftMessageInstance:(EmailMessageInstance*)messageInstance;
- (void)showNewFeedbackMessageInstance;


@property NSMutableArray* allAttachments;
@property NSMutableArray* attachments;

@property BOOL isDirty;

@property NSTimer* autosaveTimer;

@property BOOL isSafeMessage;

@property UIPopoverController* popover;

@property(nonatomic, weak) IBOutlet UIButton* numberOfAttachmentsButton;

@property(nonatomic, weak) IBOutlet UIButton* attachmentsButton;

- (void)addPhotoAttachmentWithData:(NSData*)imageData;

- (void)showPopoverFromAttachmentsButton:(UIViewController*)displayedViewController;

- (void)hidePopover;

- (void)updateAttachmentNumber;

@property(nonatomic, weak) IBOutlet UIButton* showQuotedTextButton;

@property(nonatomic, weak) IBOutlet NSLayoutConstraint* coverViewBottomConstraint;



@end
