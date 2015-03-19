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

@interface Setup_SeparateController : UIViewController <UITextFieldDelegate, UIPopoverPresentationControllerDelegate>

//the account test operations that are currently in progress
@property NSMutableArray* currentSessions;


//the connection properties currently set up
@property ConnectionItem* connectionItem;

@property IBOutlet NSLayoutConstraint* moreSettingsBoxConstraint;
@property IBOutlet NSLayoutConstraint* serverNamesBoxConstraint;
@property IBOutlet NSLayoutConstraint* credentialsBoxConstraint;
@property IBOutlet NSLayoutConstraint* securityBoxConstraint;

@property IBOutlet UIView* serverNamesBox;
@property IBOutlet UIView* credentialsBox;
@property IBOutlet UIView* securityBox;

@property IBOutlet UIButton* moreSettingsButton;
@property IBOutlet UISwitch* serverNamesCheckBox;
@property IBOutlet UISwitch* credentialsCheckBox;
@property IBOutlet UISwitch* securityCheckBox;


- (IBAction)moreSettingsButtonClicked:(id)sender;
- (IBAction)serverNamesBoxChecked:(id)sender;
- (IBAction)credentialsBoxChecked:(id)sender;
- (IBAction)securityBoxChecked:(id)sender;


@property IBOutlet UITextField* emailAddressField;
@property IBOutlet UITextField* passwordField;
@property (weak, nonatomic) IBOutlet UIView *containerOAuthView;
@property (weak, nonatomic) IBOutlet UIView *containerPasswordView;
@property (weak, nonatomic) IBOutlet UIView *containerHeadingView;

@property IBOutlet UIImageView* lockImageView;

@property IBOutlet UITextField* incomingServerField;
@property IBOutlet UITextField* outgoingServerField;

@property IBOutlet UITextField* incomingUserNameField;
@property IBOutlet UITextField* incomingPasswordField;
@property IBOutlet UISwitch* incomingAuthCheckButton;
@property IBOutlet UITextField* outgoingUserNameField;
@property IBOutlet UITextField* outgoingPasswordField;
@property IBOutlet UISwitch* outgoingAuthCheckButton;


@property IBOutlet UIButton* OAuthButton;

@property IBOutlet UITextField* senderNameField;

@property IBOutletCollection(UIView) NSArray* viewsThatCanBeDisabled;


@property IBOutlet UISegmentedControl* incomingEncryptionField;
@property IBOutlet UITextField* incomingPortField;

@property IBOutlet UISegmentedControl* outgoingEncryptionField;
@property IBOutlet UITextField* outgoingPortField;

@property IBOutlet UIButton* loginButton;
@property IBOutlet UIButton* cancelButton;

@property IBOutlet UIActivityIndicatorView* progressCircle;

@property(nonatomic) BOOL isWorking;

- (void)updateFieldValuesWithConnectionItem:(ConnectionItem*)connectionItem;
- (void)updateConnectionItemWithFieldValues:(ConnectionItem*)connectionItem;


- (IBAction)loginButtonClicked:(id)sender;
- (IBAction)cancelButtonClicked:(id)sender;

- (IBAction)incomingConnectionTypeChanged:(id)sender;
- (IBAction)outgoingConnectionTypeChanged:(id)sender;


@property NSString* feedbackString;
@property IBOutlet UILabel* feedbackLabel;

@property IBOutlet UISwitch* incomingDefaultPortCheckBox;
@property IBOutlet UISwitch* outgoingDefaultPortCheckBox;

- (IBAction)incomingDefaultPortBoxChecked:(id)sender;
- (IBAction)outgoingDefaultPortBoxChecked:(id)sender;

- (void)tryConnectionWithCallback:(void(^)(BOOL success))callback;


@property IBOutlet NSLayoutConstraint* keyboardConstraint;

@property IBOutlet UIBarButtonItem* loginBarButton;

@property(nonatomic, weak) IBOutlet UIScrollView* scrollView;
@property(nonatomic, weak) IBOutlet UIView* mainCredentialsView;
@property(nonatomic, weak) IBOutlet UIView* scrollContentView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *hideContainerOAuth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *hideContainerPassword;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *hideContainersAndButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *hideContainerHeading;

@property(strong) UINavigationController* popoverNavController;


@end
