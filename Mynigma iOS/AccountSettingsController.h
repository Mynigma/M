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

@interface AccountSettingsController : UITableViewController <UIAlertViewDelegate>
{
    UIButton* buttonDown;
}

@property IBOutlet UITextField* emailField;
@property IBOutlet UITextField* passwordField;
@property IBOutlet UITextField* incomingServerField;
@property IBOutlet UITextField* incomingUserNameField;
@property IBOutlet UITextField* incomingPortField;
@property IBOutlet UITextField* outgoingServerField;
@property IBOutlet UITextField* outgoingUserNameField;
@property IBOutlet UITextField* outgoingPortField;
@property IBOutlet UISegmentedControl* incomingEncryptionField;
@property IBOutlet UISegmentedControl* outgoingEncryptionField;

@property BOOL advancedSettingsShown;

@property IBOutlet UIActivityIndicatorView* activityIndicator;

- (IBAction)cancel:(id)sender;
- (IBAction)setUpAccount:(id)sender;

- (IBAction)showAdvancedSettings:(id)sender;


@property BOOL showAdvancedSettings;
@property BOOL showServerHostnames;
@property BOOL showUserName;
@property BOOL showIncomingConnectionTypes;
@property BOOL showOutgoingConnectionTypes;


@property IBOutlet UITableViewCell* userNameCell;

@property (weak, nonatomic) IBOutlet UITableViewCell *IMAPServerCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *SMTPServerCell;

@property (weak, nonatomic) IBOutlet UITableViewCell *incomingEncryptionCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *incomingLoginTypeCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *incomingPortCell;

@property (weak, nonatomic) IBOutlet UITableViewCell *outgoingEncryptionCell;


@property (weak, nonatomic) IBOutlet UITableViewCell *serverHostnamesDefaultCell;

@property (weak, nonatomic) IBOutlet UITableViewCell *userNameDefaultCell;

@property (weak, nonatomic) IBOutlet UITableViewCell *incomingDefaultCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *outgoingDefaultCell;


- (IBAction)toggleServerHostnamesDefault:(id)sender;
- (IBAction)toggleUserNameDefault:(id)sender;
- (IBAction)toggleIncomingDefault:(id)sender;
- (IBAction)toggleOutgoingDefault:(id)sender;


@end
