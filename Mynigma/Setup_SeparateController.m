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





#import "Setup_SeparateController.h"
#import "ConnectionItem.h"
#import <MailCore/MailCore.h>
#import "AccountCreationManager.h"
#import "AppDelegate.h"
#import "IMAPAccount.h"
#import "KeychainHelper.h"
#import "LoadingHelper.h"
#import "ViewControllersManager.h"
#import "MCODelegate.h"
#import "AddressDataHelper.h"
#import "NSString+EmailAddresses.h"
#import "AlertHelper.h"
#import "OAuthHelper.h"
#import "OAuthController.h"





static BOOL usingOAuth;


@interface Setup_SeparateController ()

@end

@implementation Setup_SeparateController

#pragma mark - UIViewController inititialisation

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    
    [self setCurrentSessions:[NSMutableArray new]];
    
    //init with a connection item
    [self clearConnectionItemPreservingSenderName];
    
    // Localize more button by hand
    NSString* moreString = NSLocalizedString(@"more", @"More options button");
    [self.moreSettingsButton setAttributedTitle:[[NSAttributedString alloc] initWithString:moreString?moreString:@"more" attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}] forState:UIControlStateNormal];
    
    [self hideAllLoginOptionsAnimated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    //register for notifications when the keyboard is shown or hidden
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

- (void)loadView
{
    [super loadView];
    
    [self.moreSettingsBoxConstraint setPriority:999];
    
    [self.serverNamesBoxConstraint setPriority:999];
    [self.credentialsBoxConstraint setPriority:999];
    [self.securityBoxConstraint setPriority:999];
    
    [self.view setNeedsLayout];
}


#pragma mark - Keyboard view adjustments

- (void)keyboardWillShow:(NSNotification *)sender
{
    CGRect frame = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect newFrame = [self.view convertRect:frame fromView:[[UIApplication sharedApplication] delegate].window];
    
    self.keyboardConstraint.constant = frame.size.height;
    
    [self.view layoutIfNeeded];
    
    UIScrollView* scrollView = (UIScrollView*)self.view.subviews[1];
    
    
    if([scrollView isKindOfClass:[UIScrollView class]])
    {
        scrollView.contentInset = UIEdgeInsetsMake(0, 0, newFrame.size.height+30, 0);
        scrollView.scrollIndicatorInsets = scrollView.contentInset;
    }
}


- (void)keyboardWillHide:(NSNotification *)sender
{
    self.keyboardConstraint.constant = 0;
    [self.view layoutIfNeeded];
    
    UIScrollView* scrollView = (UIScrollView*)self.view.subviews[1];
    if([scrollView isKindOfClass:[UIScrollView class]])
    {
        scrollView.contentInset = UIEdgeInsetsZero;
        scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
    }
}




#pragma mark - Synchronising fields and connection item

- (void)updateFieldValuesWithConnectionItem:(ConnectionItem*)connectionItem
{
    //first ensure that the provided connection item is actually more recent than the one currently displayed
    //to ensure this, check the source of the data
    if(self.connectionItem.sourceOfData == ConnectionItemSourceOfDataUndefined || [connectionItem isEqual:self.connectionItem] || connectionItem.sourceOfData > self.connectionItem.sourceOfData)
    {
        //yes, it's more recent!
        [self setConnectionItem:connectionItem];
        
        if(connectionItem.emailAddress)
        {
            [self.emailAddressField setText:connectionItem.emailAddress];
        }
        
        if(connectionItem.password)
        {
            [self.passwordField setText:connectionItem.password];
        }
        
        if(connectionItem.incomingAuth)
        {
            [self.incomingAuthCheckButton setOn:!(connectionItem.incomingAuth.intValue & MCOAuthTypeSASLPlain)];
        }
        else
            [self.incomingAuthCheckButton setOn:NO];
        
        if(connectionItem.incomingConnectionType)
            [self.incomingEncryptionField setSelectedSegmentIndex:[self indexOfEncryptionType:connectionItem.incomingConnectionType.intValue]];
        else
            [self.incomingEncryptionField setSelectedSegmentIndex:0];
        
        if(connectionItem.incomingHost)
            [self.incomingServerField setText:connectionItem.incomingHost];
        
        
        if(connectionItem.incomingPassword)
        {
            [self.incomingPasswordField setText:connectionItem.incomingPassword];
        }
        
        if(connectionItem.outgoingPassword)
        {
            [self.outgoingPasswordField setText:connectionItem.outgoingPassword];
        }
        
        if(connectionItem.incomingPort)
        {
            [self.incomingPortField setText:connectionItem.incomingPort.stringValue];
            [self.incomingDefaultPortCheckBox setOn:NO];
        }
        else
        {
            [self.incomingPortField setText:@""];
            [self.incomingDefaultPortCheckBox setOn:YES];
        }
        
        if(connectionItem.incomingUsername.length)
        {
            [self.incomingUserNameField setText:connectionItem.incomingUsername];
        }
        else if(connectionItem.emailAddress)
            [self.incomingUserNameField setText:connectionItem.emailAddress];
        
        
        if(connectionItem.outgoingAuth)
        {
            [self.outgoingAuthCheckButton setOn:!(connectionItem.outgoingAuth.intValue & MCOAuthTypeSASLPlain)];
        }
        else
            [self.outgoingAuthCheckButton setOn:NO];
        
        if(connectionItem.outgoingConnectionType)
            [self.outgoingEncryptionField setSelectedSegmentIndex:[self indexOfEncryptionType:connectionItem.outgoingConnectionType.intValue]];
        else
            [self.outgoingEncryptionField setSelectedSegmentIndex:0];
        
        if(connectionItem.outgoingHost)
            [self.outgoingServerField setText:connectionItem.outgoingHost];
        
        
        if(connectionItem.outgoingPort)
        {
            [self.outgoingPortField setText:connectionItem.outgoingPort.stringValue];
            [self.outgoingDefaultPortCheckBox setOn:NO];
        }
        else
        {
            [self.outgoingPortField setText:@""];
            [self.outgoingDefaultPortCheckBox setOn:YES];
        }
        
        if(connectionItem.outgoingUsername.length)
        {
            [self.outgoingUserNameField setText:connectionItem.outgoingUsername];
        }
        else if(connectionItem.emailAddress)
            [self.outgoingUserNameField setText:connectionItem.emailAddress];
    }
}

- (void)clearFieldValues
{
    
    [self.emailAddressField setText:@""];
    [self.passwordField setText:@""];
    [self.lockImageView setImage:[UIImage imageNamed:@"BirdOpenEyes128.png"]];
    
    [self.incomingAuthCheckButton setOn:NO];
    [self.incomingEncryptionField setSelectedSegmentIndex:0];
    [self.incomingServerField setText:@""];
    [self.incomingUserNameField setText:@""];
    [self.incomingPasswordField setText:@""];
    [self.incomingPortField setText:@""];
    [self.incomingDefaultPortCheckBox setOn:YES];
    
    [self.outgoingUserNameField setText:@""];
    [self.outgoingPasswordField setText:@""];
    [self.outgoingAuthCheckButton setOn:YES];
    [self.outgoingEncryptionField setSelectedSegmentIndex:0];
    [self.outgoingServerField setText:@""];
    [self.outgoingPortField setText:@""];
    [self.outgoingDefaultPortCheckBox setOn:YES];
}

- (void)updateConnectionItemWithFieldValues:(ConnectionItem*)connectionItem
{
    if(!connectionItem)
        connectionItem = self.connectionItem;
    
    [connectionItem setEmailAddress:self.emailAddressField.text];

    //don't need the settings for OAuth
    if(usingOAuth && [self.connectionItem canUseOAuth])
        return;
    
    //if no password has been entered yet look for one in the keychain as the user finishes entering the email address - also look up the server, if possible
    //    [connectionItem setFullName:self.senderNameField.text];
    
    
    [connectionItem setPassword:self.passwordField.text];
    
    
    
    [connectionItem setIncomingAuth:@(self.incomingAuthCheckButton.isOn?(MCOAuthTypeSASLLogin):(MCOAuthTypeSASLLogin|MCOAuthTypeSASLPlain))];
    
    [connectionItem setIncomingConnectionType:@([self encryptionTypeWithIndex:self.incomingEncryptionField.selectedSegmentIndex])];
    
    [connectionItem setIncomingHost:self.incomingServerField.text];
    
    [connectionItem setIncomingPassword:self.incomingPasswordField.text];
    
    if(self.incomingDefaultPortCheckBox.on)
    {
        [connectionItem setIncomingPort:nil];
    }
    else
        [connectionItem setIncomingPort:self.incomingPortField.text.intValue>0?@(self.incomingPortField.text.intValue):nil];
    
    [connectionItem setIncomingUsername:self.incomingUserNameField.text];
    
    
    
    [connectionItem setOutgoingAuth:@(self.outgoingAuthCheckButton.isOn?(MCOAuthTypeSASLLogin):(MCOAuthTypeSASLLogin|MCOAuthTypeSASLPlain))];
    
    [connectionItem setOutgoingConnectionType:@([self encryptionTypeWithIndex:self.outgoingEncryptionField.selectedSegmentIndex])];
    
    [connectionItem setOutgoingHost:self.outgoingServerField.text];
    
    [connectionItem setOutgoingPassword:self.outgoingPasswordField.text];
    
    if(self.outgoingDefaultPortCheckBox.on)
    {
        [connectionItem setOutgoingPort:nil];
    }
    else
        [connectionItem setOutgoingPort:self.outgoingPortField.text.intValue>0?@(self.outgoingPortField.text.intValue):nil];
    
    [connectionItem setOutgoingUsername:self.outgoingUserNameField.text];
}



#pragma mark - IBAction methods

- (IBAction)moreSettingsButtonClicked:(id)sender
{
    if(self.moreSettingsBoxConstraint.priority>900)
    {
        //currently, the more options box is hidden
        //show it!
        
        NSString* lessString = NSLocalizedString(@"less", @"Fewer options button");
        
        if(!lessString)
            lessString = @"less";
        
        [self.moreSettingsButton setAttributedTitle:[[NSAttributedString alloc] initWithString:lessString attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}] forState:UIControlStateNormal];
        [UIView animateWithDuration:.4 animations:^{
            
            [self.moreSettingsBoxConstraint setPriority:1];
            
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
            
            //scroll to security box (lowest box)
            [self scrollToView:self.securityBox];
        }];
    }
    else
    {
        //currently, the more options box is shown
        //hide it!
        //        [self.explanationBox setHidden:YES];
        
        NSString* moreString = NSLocalizedString(@"more", @"More options button");
        
        if(!moreString)
            moreString = @"more";
        
        [self.moreSettingsButton setAttributedTitle:[[NSAttributedString alloc] initWithString:moreString attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}] forState:UIControlStateNormal];
        [UIView animateWithDuration:.4 animations:^{
            
            //        [self.privacyPolicyButton setHidden:YES];
            [self.moreSettingsBoxConstraint setPriority:999];
            
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
            
            [self scrollToView:self.mainCredentialsView];
        }];
    }
}

- (IBAction)serverNamesBoxChecked:(id)sender
{
    if([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch* switchButton = (UISwitch*)sender;
        if(!switchButton.on)
        {
            [UIView animateWithDuration:.3 animations:^{
                [self.serverNamesBoxConstraint setPriority:999];
                [self.serverNamesBox layoutIfNeeded];
                [self.view setNeedsLayout];
                [self.view layoutIfNeeded];
            }];
        }
        else
        {
            [UIView animateWithDuration:.3 animations:^{
                [self.serverNamesBoxConstraint setPriority:1];
                [self.serverNamesBox layoutIfNeeded];
                [self.view setNeedsLayout];
                [self.view layoutIfNeeded];
                
                //ensure the entire box is visible
                [self scrollToView:self.serverNamesBox];
            }];
        }
    }
}

- (IBAction)credentialsBoxChecked:(id)sender
{
    if([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch* switchButton = (UISwitch*)sender;
        if(!switchButton.on)
        {
            [UIView animateWithDuration:.4 animations:^{
                [self.credentialsBoxConstraint setPriority:999];
                [self.credentialsBox layoutIfNeeded];
                [self.view setNeedsLayout];
                [self.view layoutIfNeeded];
            }];
        }
        else
        {
            [UIView animateWithDuration:.4 animations:^{
                [self.credentialsBoxConstraint setPriority:1];
                [self.credentialsBox layoutIfNeeded];
                [self.view setNeedsLayout];
                [self.view layoutIfNeeded];
                
                //ensure the entire box is visible
                [self scrollToView:self.credentialsBox];
            }];
        }
    }
}

- (IBAction)securityBoxChecked:(id)sender
{
    if([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch* switchButton = (UISwitch*)sender;
        if(!switchButton.on)
        {
            [UIView animateWithDuration:.4 animations:^{
                [self.securityBoxConstraint setPriority:999];
                [self.securityBox layoutIfNeeded];
                [self.view setNeedsLayout];
                [self.view layoutIfNeeded];
            }];
        }
        else
        {
            [UIView animateWithDuration:.4 animations:^{
                [self.securityBoxConstraint setPriority:1];
                [self.securityBox layoutIfNeeded];
                [self.view setNeedsLayout];
                [self.view layoutIfNeeded];
                
                //ensure the entire box is visible
                [self scrollToView:self.securityBox];
            }];
        }
    }
}

- (IBAction)standardPortsBoxChecked:(id)sender
{
    [UIView commitAnimations];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:.2];
    //    [self.standardPortsCheckBox setHidden:YES];
    //    [self.standardPortsBox setHidden:NO];
    //    [self.standardPortsBoxConstraint setConstant:23];
    [UIView commitAnimations];
}


- (IBAction)loginButtonClicked:(id)sender
{
    if(self.senderNameField.isFirstResponder)
        [self.senderNameField resignFirstResponder];
    
    if(self.emailAddressField.isFirstResponder)
        [self.emailAddressField resignFirstResponder];
    
    if(self.passwordField)
        [self.passwordField resignFirstResponder];
    
    [self.view endEditing:YES];
    
    if(![self isWorking])
    {
        
        __block NSString* email = self.emailAddressField.text;
        
        NSArray* emailComponents = [email componentsSeparatedByString:@"@"];
        
        if(![email isValidEmailAddress] || [emailComponents count] != 2)
        {
            [AlertHelper showAlertWithMessage:NSLocalizedString(@"Please enter a valid email address",@"Alert Title") informativeText:@""];
            [self.emailAddressField becomeFirstResponder];
            return;
        }
        
        //if an account with the same email address already exists simply adjust its settings:
        //        if([AccountCreationManager haveAccountForEmail:email])
        //        {
        //            [AlertHelper showAlertWithMessage:NSLocalizedString(@"This address has already been set up", @"Alert Title") informativeText:@""];
        //            [self.emailAddressField becomeFirstResponder];
        //            return;
        //        }
        
        //update the connection item
        [self updateConnectionItemWithFieldValues:nil];
        
        [self tryConnectionWithCallback:^(BOOL success) {
            if(success)
            {
//                [self performSegueWithIdentifier:@"individualSetup" sender:self];
                [AlertHelper showTwoOptionDialogueWithTitle:NSLocalizedString(@"Success!", nil) message:NSLocalizedString(@"Would you like to set up another account?", nil) OKOption:NSLocalizedString(@"Yes", nil) cancelOption:NSLocalizedString(@"No", nil) suppressionIdentifier:nil fromViewController:self callback:^(BOOL OKOptionSelected){
                    
                    if(OKOptionSelected)
                    {
                        [self clearConnectionItemPreservingSenderName];
                        //[self updateFieldValuesWithConnectionItem:self.connectionItem];
                        [self clearFieldValues];
                        [self hideAllLoginOptionsAnimated:YES];
                    }
                    else
                    {
                        [self performSegueWithIdentifier:@"unwindToSplitView" sender:self];
                    }
                    
                }];
            }
            else
            {
                //No need to show an alert - this is already done by tryConnectionWithCallback
                //[APPDELEGATE showAlertWithMessage:NSLocalizedString(@"Connection error", @"MailCore Error") informativeText:NSLocalizedString(@"Unable to connect", @"Individual setup")];
            }
        }];
    }
    else
    {
        [self cancelButtonClicked:nil];
    }
}

- (IBAction)doneButtonClicked:(id)sender
{
    if(self.senderNameField.isFirstResponder)
        [self.senderNameField endEditing:YES];
    
    if(self.emailAddressField.isFirstResponder)
        [self.emailAddressField endEditing:YES];
    
    if(self.passwordField)
        [self.passwordField endEditing:YES];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    //    UIStoryboard* storyboard = self.storyboard;
    //    UIViewController* mainScreenController = [storyboard instantiateViewControllerWithIdentifier:@"MainSplitView"];
    //
    //    //don't want to animate this - it looks weird to have the frames fly in...
    //    [UIView animateWithDuration:0 animations:^{
    //
    //        self.view.window.rootViewController = mainScreenController;
    //
    //        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    //
    //    }];
}


- (IBAction)cancelButtonClicked:(id)sender
{
    if([self isWorking])
    {
        [self setIsWorking:NO];
        [self setCurrentSessions:[@[] mutableCopy]];
    }
    else
    {
        //[NSApp endSheet:self.window returnCode:NSCancelButton];
        //[self.window orderOut:self];
    }
}

- (IBAction)incomingConnectionTypeChanged:(id)sender
{
    if(self.incomingPortField.isEnabled)
        [self.incomingPortField setText:[NSString stringWithFormat:@"%ld", (long)[self standardPortForIncoming:[self encryptionTypeWithIndex:[self.incomingEncryptionField selectedSegmentIndex]]]]];
}

- (IBAction)outgoingConnectionTypeChanged:(id)sender
{
    if(self.outgoingPortField.isEnabled)
        [self.outgoingPortField setText:[NSString stringWithFormat:@"%ld", (long)[self standardPortForOutgoing:[self encryptionTypeWithIndex:[self.outgoingEncryptionField selectedSegmentIndex]]]]];
}


- (IBAction)incomingDefaultPortBoxChecked:(id)sender
{
    if(self.incomingDefaultPortCheckBox.on)
    {
        //[self.incomingPortField setEnabled:NO];
        [self.incomingPortField setText:@""];
    }
    else
    {
        //[self.incomingPortField setEnabled:YES];
        [self.incomingPortField setText:[NSString stringWithFormat:@"%ld", (long)[self standardPortForIncoming:[self encryptionTypeWithIndex:[self.incomingEncryptionField selectedSegmentIndex]]]]];
    }
}


- (IBAction)outgoingDefaultPortBoxChecked:(id)sender
{
    if(self.outgoingDefaultPortCheckBox.on)
    {
        //[self.outgoingPortField setEnabled:NO];
        [self.outgoingPortField setText:@""];
    }
    else
    {
        //[self.outgoingPortField setEnabled:YES];
        [self.outgoingPortField setText:[NSString stringWithFormat:@"%ld", (long)[self standardPortForOutgoing:[self encryptionTypeWithIndex:[self.outgoingEncryptionField selectedSegmentIndex]]]]];
    }
}

- (IBAction)incomingAuthRequiredTapped:(id)sender
{
    [self.incomingAuthCheckButton setOn:!self.incomingAuthCheckButton.on animated:YES];
}

- (IBAction)outgoingAuthRequiredTapped:(id)sender
{
    [self.outgoingAuthCheckButton setOn:!self.outgoingAuthCheckButton.on animated:YES];
}


- (IBAction)incomingPortDetectTapped:(id)sender
{
    [self.incomingDefaultPortCheckBox setOn:!self.incomingDefaultPortCheckBox.on animated:YES];
    
    [self incomingDefaultPortBoxChecked:self.incomingDefaultPortCheckBox];
}

- (IBAction)outgoingPortDetectTapped:(id)sender
{
    [self.outgoingDefaultPortCheckBox setOn:!self.outgoingDefaultPortCheckBox.on animated:YES];
    
    [self outgoingDefaultPortBoxChecked:self.outgoingDefaultPortCheckBox];
}


- (IBAction)showPasswordLoginInstead:(id)sender
{
    [self showPasswordLoginAnimated:YES];
}

- (IBAction)moreInfoOnOAuth:(id)sender
{
    [AlertHelper showTwoOptionDialogueWithTitle:NSLocalizedString(@"OAuth", nil) message:NSLocalizedString(@"OAuth allows you to log into your account and grant Mynigma access to your inbox without telling us your password.", nil) OKOption:@"OK" cancelOption:@"Use normal login instead" suppressionIdentifier:nil fromViewController:self callback:^(BOOL OKOptionSelected) {
        
        if(!OKOptionSelected)
        {
            [self showPasswordLoginInstead:nil];
        }
    }];
}

#pragma mark - Scrolling offset adjustment

- (void)scrollToView:(UIView*)viewToScrollTo
{
    //express the view's frame relative to the scroll content view
    CGRect newFrame = [viewToScrollTo.superview convertRect:viewToScrollTo.frame toView:self.scrollContentView];
    
    //give it 30 more pixels on each side
    newFrame = CGRectInset(newFrame, -30, -30);
    
    [self.scrollView scrollRectToVisible:newFrame animated:NO];
    
}



#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField*)textField
{
    if([textField isEqual:self.emailAddressField])
    {
        //the email address is being changed, so let's assume we're not using OAuth
        usingOAuth = NO;
        [self hideAllLoginOptionsAnimated:YES];
        
        //the source of the data needs to be reset, so that the providers lookup doesn't think more accurate data is available
        [self.connectionItem setSourceOfData:ConnectionItemSourceOfDataUndefined];
        
    }
    
    if(![textField isEqual:self.senderNameField] && ![textField isEqual:self.emailAddressField] && ![textField isEqual:self.passwordField])
    {
        //the parameters were changed by the user, so don't overwrite them with subsequent callbacks
        [self.connectionItem setSourceOfData:ConnectionItemSourceOfDataEnteredManually];
    }
    
    if(textField == self.incomingPortField)
    {
        //the port is going to be changed manually - no longer the default value
        [self.incomingDefaultPortCheckBox setOn:NO];
    }
    
    if(textField == self.outgoingPortField)
    {
        //the port is going to be changed manually - no longer the default value
        [self.outgoingDefaultPortCheckBox setOn:NO];
    }
}


//- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
//{
//    if([textField isEqual:self.emailAddressField])
//    {
//        NSString* email = self.emailAddressField.text;
//
//        //check if the email address is valid. if not simply return
//        NSArray* emailComponents = [email componentsSeparatedByString:@"@"];
//
//        if([emailComponents count] == 2 && [email isValidEmailAddress])
//        {
//            if(self.incomingUserNameField.text.length == 0)
//                [self.incomingUserNameField setText:email];
//
//            if(self.outgoingUserNameField.text.length == 0)
//                [self.outgoingUserNameField setText:email];
//        }
//    }
//
//    if([textField isEqual:self.passwordField])
//    {
//        [self.incomingPasswordField setText:self.passwordField.text];
//        [self.outgoingPasswordField setText:self.passwordField.text];
//    }
//
//    return YES;
//}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self updateConnectionItemWithFieldValues:self.connectionItem];
    
    if([textField isEqual:self.emailAddressField])
    {
        if([self.connectionItem.emailAddress isValidEmailAddress])
        {
            [[LoadingHelper sharedInstance] startLoading];
            
            [self.connectionItem lookForSettingsWithCallback:^{
                
                [self updateFieldValuesWithConnectionItem:self.connectionItem];
                
                [[LoadingHelper sharedInstance] stopLoading];
                
                if([[LoadingHelper sharedInstance] hasBeenCancelled])
                    return;
                
                
                BOOL canUseOAuth = [self.connectionItem canUseOAuth];

                //no need to disable, we will push if popovers aren't available
//                // Disable OAuth on iOS 7 ...
//                canUseOAuth &= [self.navigationController respondsToSelector:@selector(popoverPresentationController)];
                
                // todo switch provider cases...
                if(canUseOAuth)
                {
                    [self showOAuthLoginAnimated:YES];
                    
                    //adjust the OAuth button in the nav bar
                    if([self.connectionItem.OAuthProvider isEqual:@"Google"])
                    {
                        //it's google
                        [self.OAuthButton setImage:[UIImage imageNamed:@"GMail22"] forState:UIControlStateNormal];
                    }
                    else
                    {
                        //TO DO: add images for other OAuth providers as applicable
                        [self.OAuthButton setImage:[UIImage imageNamed:@"Outlook22"] forState:UIControlStateNormal];
                    }
                }
                else
                {
                    
                    [self showPasswordLoginAnimated:YES];
                }
            }];
        }
    }
}


- (BOOL)textFieldShouldReturn:(UITextField *)theTextField
{
    if(theTextField == self.senderNameField)
    {
        [self.emailAddressField becomeFirstResponder];
    }
    else if(theTextField == self.emailAddressField)
    {
        if([AddressDataHelper isValidEmailAddress:self.emailAddressField.text])
            [self.passwordField becomeFirstResponder];
        else
            return NO;
    }
    else if(theTextField == self.passwordField)
    {
        [self loginButtonClicked:nil];
    }
    else if(theTextField == self.incomingServerField)
    {
        [self.outgoingServerField becomeFirstResponder];
    }
    else if(theTextField == self.outgoingServerField)
    {
        [self loginButtonClicked:nil];
    }
    else if(theTextField == self.incomingUserNameField)
    {
        [self.outgoingUserNameField becomeFirstResponder];
    }
    else if(theTextField == self.outgoingUserNameField)
    {
        [self loginButtonClicked:nil];
    }
    else if(theTextField == self.incomingPasswordField)
    {
        [self.outgoingPasswordField becomeFirstResponder];
    }
    else if(theTextField == self.outgoingPasswordField)
    {
        [self loginButtonClicked:nil];
    }
    else if(theTextField == self.incomingPortField)
    {
        [self.outgoingPortField becomeFirstResponder];
    }
    else if(theTextField == self.outgoingPortField)
    {
        [self loginButtonClicked:nil];
    }
    return YES;
}

- (IBAction)textDidChange:(UITextField*)textField
{
    if([textField isEqual:self.passwordField])
    {
        [self.incomingPasswordField setText:self.passwordField.text];
        [self.outgoingPasswordField setText:self.passwordField.text];
        
        if([textField text].length)
        {
            [self.lockImageView setImage:[UIImage imageNamed:@"BirdClosedEyes128.png"]];
        }
        else
        {
            [self.lockImageView setImage:[UIImage imageNamed:@"BirdOpenEyes128.png"]];
        }
    }
}


#pragma mark - Ports calculations

- (NSInteger)standardPortForIncoming:(NSInteger)encryptionType
{
    switch(encryptionType)
    {
        case MCOConnectionTypeTLS:
            return 993;
        case MCOConnectionTypeStartTLS:
            return 143;
        case MCOConnectionTypeClear:
        default:
            return 143;
    }
}

- (NSInteger)standardPortForOutgoing:(NSInteger)encryptionType
{
    switch(encryptionType)
    {
        case MCOConnectionTypeTLS:
            return 465;
        case MCOConnectionTypeStartTLS:
            return 587;
        case MCOConnectionTypeClear:
        default:
            return 25;
    }
}


- (NSInteger)indexOfEncryptionType:(NSInteger)encryptionType
{
    switch(encryptionType)
    {
        case MCOConnectionTypeTLS: return 0;
        case MCOConnectionTypeStartTLS: return 1;
        case MCOConnectionTypeClear: return 2;
        default: return 0;
    }
}

- (NSInteger)encryptionTypeWithIndex:(NSInteger)index
{
    switch(index)
    {
        case 0: return MCOConnectionTypeTLS;
        case 1: return MCOConnectionTypeStartTLS;
        case 2: return MCOConnectionTypeClear;
        default: return MCOConnectionTypeTLS;
    }
}



#pragma mark - Activity indicator

- (void)setIsWorking:(BOOL)isWorking
{
    if(isWorking)
    {
        [[LoadingHelper sharedInstance] startLoading];
    }
    else
    {
        [[LoadingHelper sharedInstance] stopLoading];
    }
    
    _isWorking = isWorking;
}


#pragma mark - Connection attempt

- (void)tryConnectionWithCallback:(void(^)(BOOL success))callback
{
    BOOL canUseOAuth = [self.connectionItem canUseOAuth];
    
    if(canUseOAuth && usingOAuth)
    {
        [self launchOAuthWithConnectionItem:self.connectionItem];
    }
    else
    {
        ConnectionItem* newConnectionItem = self.connectionItem;
        
        [self setIsWorking:YES];
        
        [self.currentSessions addObject:newConnectionItem];
        
        [newConnectionItem attemptSpecificImportWithCallback:^()
         {
             [self setIsWorking:NO];
             
             if([[LoadingHelper sharedInstance] hasBeenCancelled])
             {
                 if(callback)
                     callback(NO);
                 return;
             }
             
             if([self.currentSessions containsObject:newConnectionItem])
             {
                 [self.currentSessions removeObject:newConnectionItem];
                 if(newConnectionItem.IMAPSuccess && newConnectionItem.SMTPSuccess)
                 {
                     [AccountCreationManager makeOrUpdateAccountWithConnectionItem:newConnectionItem];
//                     if(![AccountCreationManager haveAccountForEmail:newConnectionItem.emailAddress])
//                     {
//                         [AccountCreationManager makeNewAccountWithLocalKeychainItem:newConnectionItem];
                         callback(YES);
//                     }
//                     else
//                     {
//                         //TO DO: update the account
//                         
//                         NSString* errorMessage = newConnectionItem.feedbackString.string;
//                         
//                         [AlertHelper showAlertWithMessage:NSLocalizedString(@"Account already set up!", @"Duplicate account during local keychain item import") informativeText:[NSString stringWithFormat:@"%@", errorMessage?errorMessage:NSLocalizedString(@"This account has already been set up.", @"Account setup duplicate message")]];
//                         callback(NO);
//                     }
                 }
                 else
                 {
                     NSString* errorMessage = newConnectionItem.feedbackString.string;
                     
                     [AlertHelper showAlertWithMessage:NSLocalizedString(@"Login error", @"Error during local login") informativeText:[NSString stringWithFormat:@"%@", errorMessage?errorMessage:NSLocalizedString(@"An error occurred.", @"Generic error")]];
                     callback(NO);
                     
                     [self moreSettingsButtonClicked:nil];
                 }
             }
         }];
    }
}


#pragma mark - OAuth vs. password

- (void)hideAllLoginOptionsAnimated:(BOOL)animated
{
    [UIView animateWithDuration:animated?.3:0 animations:^{
        
        [self.hideContainerOAuth setPriority:999];
        [self.hideContainerPassword setPriority:999];
        [self.hideContainersAndButton setPriority:999];
        [self.hideContainerHeading setPriority:1];
        
        //hide the more settings box
        [self.moreSettingsBoxConstraint setPriority:999];
        
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        
        [self.navigationController setNavigationBarHidden:YES animated:NO];
    }];
}

- (void)showPasswordLoginAnimated:(BOOL)animated
{
    usingOAuth = NO;
    
    [UIView animateWithDuration:animated?.3:0 animations:^{
        
        [self.hideContainerOAuth setPriority:999];
        [self.hideContainerPassword setPriority:1];
        [self.hideContainersAndButton setPriority:1];
        [self.hideContainerHeading setPriority:999];
        
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        
        [self.navigationController setNavigationBarHidden:YES animated:NO];
    }];
}

- (void)showOAuthLoginAnimated:(BOOL)animated
{
    usingOAuth = YES;
    
    [UIView animateWithDuration:animated?.3:0 animations:^{
        
        [self.hideContainerOAuth setPriority:1];
        [self.hideContainerPassword setPriority:999];
        [self.hideContainersAndButton setPriority:1];
        [self.hideContainerHeading setPriority:999];
        
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        
        [self.view.window endEditing:YES];
    }];
}



#pragma mark - UIAdaptivePresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    //force popover on iPhone
    return UIModalPresentationNone;
}



#pragma mark - OAuth

- (void)startOAuthWithConnectionItem:(ConnectionItem*)connectionItem fromRect:(CGRect)sourceRect
{
    if([ViewControllersManager isHorizontallyCompact])
    {
        //do a push segue on small displays
        GTMOAuth2ViewControllerTouch* OAuthController = [OAuthHelper getOAuthControllerWithConnectionItem:connectionItem withCallback:^(NSError* error, GTMOAuth2Authentication* auth){
            
            [self.navigationController popViewControllerAnimated:YES];
            
                if (error != nil)
                {
                    //this error code comes up when the user dismisses a popover through a tap outside
                    //in this case we are pushing, but it can do no harm to have it in here
                    //presumable it will be used when the cancel button is tapped
                    if(error.code != -1000)
                        [AlertHelper presentError:error];
                    
                    //[self dismissViewControllerAnimated:YES completion:nil];
                    
                    // Authentication failed
                    // Error handling here
                    return;
                }
                
                NSString * email = [auth userEmail];
                NSString * accessToken = [auth accessToken];
                
                if (!email)
                {
                    [AlertHelper showAlertWithMessage:NSLocalizedString(@"Error", nil) informativeText:NSLocalizedString(@"Provider failed to return email address", nil)];
                    
                    // we depend on the email !!!
                    // do something useful here !!
                    return;
                }
                
                [self.connectionItem setEmailAddress:email];
                
                [self.connectionItem setIncomingUsername:email];
                [self.connectionItem setOutgoingUsername:email];
                
                // if outlook...
                if ([self.connectionItem.incomingHost isEqual:@"imap-mail.outlook.com"])
                {
                    [self.connectionItem setIncomingAuth:@(MCOAuthTypeXOAuth2Outlook)];
                    [self.connectionItem setOutgoingAuth:@(MCOAuthTypeXOAuth2Outlook)];
                }
                else
                {
                    [self.connectionItem setIncomingAuth:@(MCOAuthTypeXOAuth2)];
                    [self.connectionItem setOutgoingAuth:@(MCOAuthTypeXOAuth2)];
                }
                
                [self.connectionItem setOAuth2Token:accessToken];
                
                // no need to test the connection settings - they have been looked up, so they really ought to be OK
                
                [AccountCreationManager makeOrUpdateAccountWithConnectionItem:self.connectionItem];
                
                //    if([AccountCreationManager haveAccountForEmail:email])
                //    {
                //        [AccountCreationManager updateAccountWith]
                //        [AlertHelper showAlertWithMessage:NSLocalizedString(@"Account exists", nil) informativeText:NSLocalizedString(@"This account has already been set up!", nil)];
                //        return;
                //    }
                //
                //    [AccountCreationManager makeNewAccountWithLocalKeychainItem:self.connectionItem];
                
                [AlertHelper showTwoOptionDialogueWithTitle:NSLocalizedString(@"Success!", nil) message:NSLocalizedString(@"Would you like to set up another account?", nil) OKOption:NSLocalizedString(@"Yes", nil) cancelOption:NSLocalizedString(@"No", nil) suppressionIdentifier:nil fromViewController:self callback:^(BOOL OKOptionSelected){
                    
                    if(OKOptionSelected)
                    {
                        self.connectionItem = [[ConnectionItem alloc] initWithEmail:@""];
                        [self updateFieldValuesWithConnectionItem:self.connectionItem];
                        [self hideAllLoginOptionsAnimated:YES];
                    }
                    else
                    {
                        [self performSegueWithIdentifier:@"unwindToSplitView" sender:self];
                    }
                    
            }];
        }];
        
        if(OAuthController)
        {
            [self.navigationController pushViewController:OAuthController animated:YES];
        }
    }
    else
    {
        //a popover on larger displays
    GTMOAuth2ViewControllerTouch* OAuthController = [OAuthHelper getOAuthControllerWithConnectionItem:connectionItem withCallback:^(NSError* error, GTMOAuth2Authentication* auth){
        
        [self.popoverNavController dismissViewControllerAnimated:YES completion:^{
        
        if (error != nil)
        {
            //this error code comes up when the user dismisses the popover through a tap outside
            if(error.code != -1000)
                [AlertHelper presentError:error];
            
            //[self dismissViewControllerAnimated:YES completion:nil];
            
            // Authentication failed
            // Error handling here
            return;
        }
        
        NSString * email = [auth userEmail];
        NSString * accessToken = [auth accessToken];
        
        if (!email)
        {
            [AlertHelper showAlertWithMessage:NSLocalizedString(@"Error", nil) informativeText:NSLocalizedString(@"Provider failed to return email address", nil)];
            
            // we depend on the email !!!
            // do something useful here !!
            return;
        }
        
        [self.connectionItem setEmailAddress:email];
        
        [self.connectionItem setIncomingUsername:email];
        [self.connectionItem setOutgoingUsername:email];
        
        // if outlook...
        if ([self.connectionItem.incomingHost isEqual:@"imap-mail.outlook.com"])
        {
            [self.connectionItem setIncomingAuth:@(MCOAuthTypeXOAuth2Outlook)];
            [self.connectionItem setOutgoingAuth:@(MCOAuthTypeXOAuth2Outlook)];
        }
        else
        {
            [self.connectionItem setIncomingAuth:@(MCOAuthTypeXOAuth2)];
            [self.connectionItem setOutgoingAuth:@(MCOAuthTypeXOAuth2)];
        }
        
        [self.connectionItem setOAuth2Token:accessToken];
        
        // no need to test the connection settings - they have been looked up, so they really ought to be OK
        
        [AccountCreationManager makeOrUpdateAccountWithConnectionItem:self.connectionItem];
        
        //    if([AccountCreationManager haveAccountForEmail:email])
        //    {
        //        [AccountCreationManager updateAccountWith]
        //        [AlertHelper showAlertWithMessage:NSLocalizedString(@"Account exists", nil) informativeText:NSLocalizedString(@"This account has already been set up!", nil)];
        //        return;
        //    }
        //
        //    [AccountCreationManager makeNewAccountWithLocalKeychainItem:self.connectionItem];
        
            [AlertHelper showTwoOptionDialogueWithTitle:NSLocalizedString(@"Success!", nil) message:NSLocalizedString(@"Would you like to set up another account?", nil) OKOption:NSLocalizedString(@"Yes", nil) cancelOption:NSLocalizedString(@"No", nil) suppressionIdentifier:nil fromViewController:self callback:^(BOOL OKOptionSelected){
                
                if(OKOptionSelected)
                {
                    self.connectionItem = [[ConnectionItem alloc] initWithEmail:@""];
                    [self updateFieldValuesWithConnectionItem:self.connectionItem];
                    [self hideAllLoginOptionsAnimated:YES];
                }
                else
                {
                    [self performSegueWithIdentifier:@"unwindToSplitView" sender:self];
                }
                
            }];
            
        }];
        
    }];
    
    if(OAuthController)
    {
        self.popoverNavController = [[UINavigationController alloc] initWithRootViewController:OAuthController];
        
        [self.popoverNavController setNavigationBarHidden:YES];
        
        [self.popoverNavController setModalPresentationStyle:UIModalPresentationPopover];
        
        UIPopoverPresentationController* popover = self.popoverNavController.popoverPresentationController;
        
        self.popoverNavController.preferredContentSize = CGSizeMake(400, 600);
        
        popover.delegate = self;
        popover.sourceView = self.view;
        popover.sourceRect = sourceRect;
        popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
        
        [self presentViewController:self.popoverNavController animated:YES completion:nil];
    }
    }
}



- (void)launchOAuthWithConnectionItem:(ConnectionItem*)connectionItem
{
    CGRect buttonRect = self.OAuthButton.frame;
    
    CGRect buttonRectInWindow = [self.view convertRect:buttonRect fromView:self.OAuthButton.superview];
    
    [self startOAuthWithConnectionItem:connectionItem fromRect:buttonRectInWindow];
}


#pragma mark - ConnectionItem

- (void)clearConnectionItemPreservingSenderName
{
    NSString* senderName = self.connectionItem.fullName;
    
    //use an empty email string so that any existing value will be overwritten
    self.connectionItem = [[ConnectionItem alloc] initWithEmail:@""];
    
    [self.connectionItem setFullName:senderName];

    //there is no actual data yet...
    [self.connectionItem setSourceOfData:ConnectionItemSourceOfDataUndefined];
}


@end
