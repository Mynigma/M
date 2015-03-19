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

@class IMAPAccountSetting;

@interface IndividualAccountSettingsController : UIViewController <UITextFieldDelegate>

@property IBOutlet UITextField* accountNameField;
@property IBOutlet UITextField* senderNameField;
@property IBOutlet UITextField* emailAddressField;

@property IBOutlet UISwitch* intoSentFolderSwitch;

@property IBOutlet UITextField* incomingServerField;
@property IBOutlet UITextField* incomingUserNameField;
@property IBOutlet UITextField* incomingPortField;

@property IBOutlet UITextField* incomingPasswordField;
@property IBOutlet UITextField* outgoingPasswordField;

@property IBOutlet UITextField* outgoingServerField;
@property IBOutlet UITextField* outgoingUserNameField;
@property IBOutlet UITextField* outgoingPortField;
@property IBOutlet UISegmentedControl* incomingEncryptionField;
@property IBOutlet UISegmentedControl* outgoingEncryptionField;

@property IMAPAccountSetting* accountSetting;

- (void)setup;


@end
