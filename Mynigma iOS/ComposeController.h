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

@class EmailMessage, TITokenField, TIToken, Recipient, EmailMessageInstance;

@interface ComposeController : UITableViewController <UIGestureRecognizerDelegate, UITextFieldDelegate, UITextViewDelegate, UIActionSheetDelegate>
{
    CGPoint startLocation;
    BOOL keyboardVisible;
    
    UITextView* textViewForCalculatingHeight;
    NSAttributedString* composedText;
    float keyboardHeight;
    float shownMessageHeight;
    
    BOOL isDirty;
    
    NSString* composeHtml;
    NSString* composeSubject;
    
    EmailMessageInstance* savedMessageInstance;

    BOOL currentlyEditing;

    BOOL keyboardShown;
}

@property CGFloat toFieldHeight;
@property CGFloat ccFieldHeight;
@property CGFloat bccFieldHeight;

@property TITokenField* toField;
@property TITokenField* ccField;
@property TITokenField* bccField;


@property NSArray* toRecipients;
@property NSArray* ccRecipients;
@property NSArray* bccRecipients;
@property Recipient* replyToRecipient;
@property Recipient* fromRecipient;


@property BOOL isDirty;

@property BOOL recipientsExpanded;

@property IBOutlet UITableView* composeTableView;

@property IBOutlet UIBarButtonItem* cancelButton;

@property(nonatomic,strong) SASlideMenuRootViewController* rootController;

@property NSMutableArray* composeRecipients;

@property IBOutlet UIBarButtonItem* sendButton;

@property BOOL showExtraFields;


- (IBAction)swipeLeft:(id)sender;
- (IBAction)swipeRight:(id)sender;

- (IBAction)tap:(id)sender;

- (IBAction)backButton:(id)sender;
- (void)displayMessage:(EmailMessage*)message;

- (IBAction)replyButton:(id)sender;

- (void)startReplyToMessageInstance:(EmailMessageInstance*)messageInstance;
- (void)startReplyAllToMessageInstance:(EmailMessageInstance*)messageInstance;
- (void)startForwardOfMessageInstance:(EmailMessageInstance*)messageInstance;

- (IBAction)showAllRecipients:(id)sender;
- (IBAction)sendMessage:(id)sender;

- (IBAction)expandRecipients:(id)sender;

@property IBOutlet NSLayoutConstraint* keyBoardDistanceConstraint;


@end
