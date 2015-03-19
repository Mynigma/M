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

@class ConnectionItem;

@interface DetailedSetupController : NSViewController

@property ConnectionItem* connectionItem;

@property BOOL isClosing;

@property IBOutlet NSLayoutConstraint* serverNamesBoxConstraint;
@property IBOutlet NSLayoutConstraint* credentialsBoxConstraint;
@property IBOutlet NSLayoutConstraint* securityBoxConstraint;
@property IBOutlet NSLayoutConstraint* standardPortsBoxConstraint;

@property IBOutlet NSBox* serverNamesBox;
@property IBOutlet NSBox* credentialsBox;
@property IBOutlet NSBox* securityBox;
@property IBOutlet NSBox* standardPortsBox;

@property IBOutlet NSButton* serverNamesCheckBox;
@property IBOutlet NSButton* credentialsCheckBox;
@property IBOutlet NSButton* securityCheckBox;
@property IBOutlet NSButton* standardPortsCheckBox;


- (IBAction)serverNamesBoxChecked:(id)sender;
- (IBAction)credentialsBoxChecked:(id)sender;
- (IBAction)securityBoxChecked:(id)sender;
//- (IBAction)standardPortsBoxChecked:(id)sender;


@property IBOutlet NSTextField* emailAddressField;
@property IBOutlet NSTextField* passwordField;

@property IBOutlet NSTextField* incomingServerField;
@property IBOutlet NSTextField* outgoingServerField;

@property IBOutlet NSTextField* incomingUserNameField;
@property IBOutlet NSTextField* incomingPasswordField;
@property IBOutlet NSButton* incomingAuthCheckButton;

@property IBOutlet NSTextField* outgoingUserNameField;
@property IBOutlet NSTextField* outgoingPasswordField;
@property IBOutlet NSButton* outgoingAuthCheckButton;


@property IBOutlet NSSegmentedControl* incomingEncryptionField;
@property IBOutlet NSComboBox* incomingPortField;

@property IBOutlet NSSegmentedControl* outgoingEncryptionField;
@property IBOutlet NSComboBox* outgoingPortField;

@property IBOutlet NSButton* loginButton;
@property IBOutlet NSButton* cancelButton;


@property IBOutlet NSButton* errorLinkButton;

@property IBOutlet NSProgressIndicator* progressCircle;

@property(nonatomic) BOOL isWorking;

- (void)setupWithConnectionItem:(ConnectionItem*)connectionItem;

//- (IBAction)loginButtonClicked:(id)sender;
//- (IBAction)cancelButtonClicked:(id)sender;

- (IBAction)incomingConnectionTypeChanged:(id)sender;
- (IBAction)outgoingConnectionTypeChanged:(id)sender;


//- (IBAction)showPrivacyPolicy:(id)sender;

@property NSString* feedbackString;

@property IBOutlet NSButton* incomingDefaultPortCheckBox;
@property IBOutlet NSButton* outgoingDefaultPortCheckBox;

- (IBAction)incomingDefaultPortBoxChecked:(id)sender;
- (IBAction)outgoingDefaultPortBoxChecked:(id)sender;

//- (void)tryConnectionWithCallback:(void(^)(BOOL success))callback;

//- (IBAction)additionalInfoRequested:(id)sender;

//@property BOOL additionalInfoRequested;

//@property IBOutlet NSButton* additionalInfoButton;


@property IBOutlet NSPopUpButton* incomingAuthButton;
@property IBOutlet NSPopUpButton* outgoingAuthButton;


@end
