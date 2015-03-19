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

@class ConnectionItem;

@interface AccountsListController : UITableViewController <UITextFieldDelegate>


@property ConnectionItem* accountBeingSetUp;

@property IBOutlet UITextField* emailField;
@property IBOutlet UITextField* passwordField;


@property IBOutlet UITextField* incomingServerField;
@property IBOutlet UITextField* outgoingServerField;


@property IBOutlet UITextField* incomingUserNameField;
@property IBOutlet UITextField* outgoingUserNameField;


@property IBOutlet UITextField* advIncomingServer;
@property IBOutlet UITextField* advOutoingServer;

@property IBOutlet UITextField* advIncomingPassword;
@property IBOutlet UITextField* advOutgoingPassword;


@property IBOutlet UITextField* advEmailAddress;
@property IBOutlet UITextField* advIncomingUserNameField;
@property IBOutlet UITextField* advOutgoingUserNameField;

@property IBOutlet UITextField* advIncomingPortField;
@property IBOutlet UITextField* advOutgoingPortField;
@property IBOutlet UISegmentedControl* advIncomingEncryptionField;
@property IBOutlet UISegmentedControl* advOutgoingEncryptionField;

@property IBOutlet UISegmentedControl* advIncomingAuthField;
@property IBOutlet UISegmentedControl* advOutgoingAuthField;


@property IBOutlet UIActivityIndicatorView* incomingActivityIndicator;
@property IBOutlet UIActivityIndicatorView* outgoingActivityIndicator;


- (IBAction)cancelButton:(id)sender;

//- (IBAction)setUpTestAccount:(id)sender;

//- (IBAction)connectAsStandard:(id)sender;
//
//- (IBAction)connectWithUsername:(id)sender;
//
//- (IBAction)connectWithHostnames:(id)sender;


@end
