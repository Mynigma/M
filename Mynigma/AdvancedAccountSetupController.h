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

@class IMAPAccountSetting, IMAPAccount;

@interface AdvancedAccountSetupController : NSWindowController <NSTextFieldDelegate>

@property IMAPAccountSetting* accountSetting;

@property IMAPAccount* account;

@property IBOutlet NSTextField* incomingPasswordField;
@property IBOutlet NSTextField* outgoingPasswordField;

@property IBOutlet NSPopUpButton* footerSelectionPopUp;

- (IBAction)doneButtonClicked:(id)sender;
- (IBAction)footerSelectionChanged:(id)sender;

@property NSArray* footersList;


@property BOOL isCheckingIncoming;
@property BOOL isCheckingOutgoing;

@property NSString* incomingFeedbackString;
@property NSString* outgoingFeedbackString;

- (IBAction)checkIncoming:(id)sender;
- (IBAction)checkOutgoing:(id)sender;

@property IBOutlet NSButton* incomingCheckButton;
@property IBOutlet NSButton* outgoingCheckButton;

@property NSString* incomingPassword;
@property NSString* outgoingPassword;


@end
