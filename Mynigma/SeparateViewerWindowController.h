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

@class EmailMessage, AttachmentListController, RecipientTokenField, AttachmentsIconView;

@interface SeparateViewerWindowController : NSWindowController <NSWindowDelegate>
{
    EmailMessageInstance* shownMessageInstance;
    AttachmentListController* sheetController;
}

@property BOOL hasAttachments;
@property NSArray* attachmentList;
@property EmailMessageInstance* shownMessageInstance;
@property EmailMessage* shownMessage;

@property IBOutlet WebView* bodyView;
@property IBOutlet NSTextField* subjectField;
@property IBOutlet NSTextField* dateField;
@property IBOutlet NSImageView* lockImage;
@property IBOutlet NSBox* bodyBox;

@property IBOutlet NSTextField* safeLabel;

@property IBOutlet NSLayoutConstraint* fromTrailingEdgeConstraint;
@property IBOutlet NSLayoutConstraint* replyToTrailingEdgeConstraint;
@property IBOutlet NSLayoutConstraint* ccHeightConstraint;
@property IBOutlet NSLayoutConstraint* bccHeightConstraint;
@property IBOutlet NSLayoutConstraint* ccSpaceConstraint;
@property IBOutlet NSLayoutConstraint* bccSpaceConstraint;

@property IBOutlet RecipientTokenField* fromField;
@property IBOutlet RecipientTokenField* toField;
@property IBOutlet RecipientTokenField* ccField;
@property IBOutlet RecipientTokenField* bccField;
@property IBOutlet RecipientTokenField* replyToField;

@property IBOutlet NSTextField* ccLabel;
@property IBOutlet NSTextField* bccLabel;
@property IBOutlet NSTextField* replyToLabel;

@property IBOutlet NSButton* printButton;
@property IBOutlet NSButton* attachmentButton;
@property IBOutlet NSButton* attachmentClip;

@property IBOutlet NSBox* toBox;
@property IBOutlet NSBox* fromBox;
@property IBOutlet NSBox* ccBox;
@property IBOutlet NSBox* bccBox;
@property IBOutlet NSBox* replyToBox;
@property IBOutlet NSBox* topBox;
@property IBOutlet NSBox* subjectBox;

@property IBOutlet NSImageView* envelopeBorderImageView;

@property BOOL toShown;
@property BOOL ccShown;
@property BOOL bccShown;
@property BOOL replyToShown;

@property IBOutlet NSTextField* numberOfAttachmentsLabel;

- (void)showMessageInstance:(EmailMessageInstance*)messageInstance;
- (void)showMessage:(EmailMessage*)message;

- (IBAction)reply:(id)sender;
- (IBAction)replyAll:(id)sender;
- (IBAction)forward:(id)sender;

- (IBAction)printOff:(id)sender;
- (IBAction)openAttachmentList:(id)sender;

@property IBOutlet NSLayoutConstraint* attachmentViewHeightConstraint;
@property IBOutlet AttachmentsIconView* attachmentsView;

@property IBOutlet NSButton* cautionButton;

@end
