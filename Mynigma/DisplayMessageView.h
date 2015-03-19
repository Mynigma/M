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





#import <Foundation/Foundation.h>
#import "AppDelegate.h"
#import "SendCellView.h"
#import "ContentViewerCellView.h"
#import "FeedbackView.h"


@class AttachmentsIconView;


@interface DisplayMessageView : NSView <NSTextFieldDelegate>


- (void)showMessage:(EmailMessage*)message;
- (void)showMessageInstance:(EmailMessageInstance*)messageInstance;

- (void)refresh;
- (void)refreshMessage:(EmailMessage*)message;
- (void)refreshMessageInstance:(EmailMessageInstance*)messageInstance;

//sets the height of the content to 0, showing the placeholder view instead (provided) its priority is high enough
@property(weak) IBOutlet NSLayoutConstraint* hideContentConstraint;

//sets the subject inset to move into the space of the (hidden) profile pic view
@property(weak) IBOutlet NSLayoutConstraint* hideProfilePicConstraint;

@property IBOutlet NSImageView* profilePicView;

@property IBOutlet FeedbackView* feedbackView;

@property IBOutlet ContentView* bodyView;
@property IBOutlet NSTextField* subjectField;

@property EmailMessage* message;
@property EmailMessageInstance* messageInstance;


@property IBOutlet NSLayoutConstraint* boxWidthConstraint;


@property IBOutlet NSView* placeHolderView;
@property IBOutlet NSView* contentFrameView;


@property IBOutlet NSButton* unreadButton;
@property IBOutlet NSButton* flagButton;
@property IBOutlet NSButton* replyAllButton;


@property IBOutlet AddressLabelView* addressLabelView;


//- (IBAction)cellClicked:(id)sender;

- (IBAction)unreadButton:(id)sender;
- (IBAction)flagButton:(id)sender;
- (IBAction)spamButton:(id)sender;

- (IBAction)replyButton:(id)sender;
- (IBAction)replyAllButton:(id)sender;
- (IBAction)forwardButton:(id)sender;

@property IBOutlet NSLayoutConstraint* attachmentListHeight;

@property IBOutlet NSLayoutConstraint* headerHeight;

@property IBOutlet AttachmentsIconView* attachmentsView;

@property IBOutlet NSArrayController* attachmentsArrayController;

@property IBOutlet NSButton* cautionButton;

- (IBAction)cautionButtonClicked:(id)sender;

@property IBOutlet NSLayoutConstraint* addressLabelLeftAlignment;


@property IBOutlet NSLayoutConstraint* topMetalSheetHideConstraint;
@property IBOutlet NSLayoutConstraint* topMetalSheetShowConstraint;

@property IBOutlet NSLayoutConstraint* bottomMetalSheetHideConstraint;
@property IBOutlet NSLayoutConstraint* bottomMetalSheetShowConstraint;

@property IBOutlet NSImageView* topMetalSheetRibbon;
@property IBOutlet NSImageView* bottomMetalSheetRibbon;


@end
