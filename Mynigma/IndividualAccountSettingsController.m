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





#import "IndividualAccountSettingsController.h"
#import "IMAPAccountSetting+Category.h"
#import <MailCore/MailCore.h>
#import "KeychainHelper.h"


@implementation IndividualAccountSettingsController

@synthesize accountSetting;

- (void)viewDidLoad
{
    [self setup];
}

- (void)setup
{
    [self.accountNameField setText:accountSetting.displayName?accountSetting.displayName:@""];
    [self.senderNameField setText:accountSetting.senderName?accountSetting.senderName:@""];
    [self.emailAddressField setText:accountSetting.emailAddress?accountSetting.emailAddress:@""];
    [self.intoSentFolderSwitch setOn:accountSetting.sentMessagesCopiedIntoSentFolder.boolValue];

    [self.incomingUserNameField setText:accountSetting.incomingUserName?accountSetting.incomingUserName:@""];
    [self.incomingServerField setText:accountSetting.incomingServer?accountSetting.incomingServer:@""];

    NSString* incomingPassword = [KeychainHelper findPasswordForAccount:accountSetting.objectID incoming:YES];

    [self.incomingPasswordField setText:incomingPassword];

    [self.incomingEncryptionField setSelectedSegmentIndex:[self indexOfEncryptionType:accountSetting.incomingEncryption.integerValue]];

    [self.incomingPortField setText:self.accountSetting.incomingPort.stringValue];

    [self.outgoingUserNameField setText:accountSetting.outgoingUserName?accountSetting.outgoingUserName:@""];
    [self.outgoingServerField setText:accountSetting.outgoingServer?accountSetting.outgoingServer:@""];

    NSString* outgoingPassword = [KeychainHelper findPasswordForAccount:accountSetting.objectID incoming:NO];

    [self.outgoingPasswordField setText:outgoingPassword];

    [self.outgoingEncryptionField setSelectedSegmentIndex:[self indexOfEncryptionType:accountSetting.outgoingEncryption.integerValue]];

    [self.outgoingPortField setText:self.accountSetting.outgoingPort.stringValue];
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

- (IBAction)OKButton:(id)sender
{
    //save it

    [accountSetting setDisplayName:self.accountNameField.text];
    [accountSetting setSenderName:self.senderNameField.text];
//    [accountSetting setEmailAddress:self.emailAddressField.text];
    [accountSetting setSentMessagesCopiedIntoSentFolder:@(self.intoSentFolderSwitch.isOn)];

    [accountSetting setIncomingUserName:self.incomingUserNameField.text];
    [accountSetting setIncomingServer:self.incomingServerField.text];

    NSString* incomingPassword = self.incomingPasswordField.text;

    [KeychainHelper saveAsyncPassword:incomingPassword forAccountSetting:accountSetting incoming:YES withCallback:nil];

    [accountSetting setIncomingEncryption:@([self encryptionTypeWithIndex:self.incomingEncryptionField.selectedSegmentIndex])];

    [accountSetting setIncomingPort:@(self.incomingPortField.text.integerValue)];


    [accountSetting setOutgoingUserName:self.outgoingUserNameField.text];
    [accountSetting setOutgoingServer:self.outgoingServerField.text];

    NSString* outgoingPassword = self.outgoingPasswordField.text;

    [KeychainHelper saveAsyncPassword:outgoingPassword forAccountSetting:accountSetting incoming:NO withCallback:nil];

    [accountSetting setOutgoingEncryption:@([self encryptionTypeWithIndex:self.outgoingEncryptionField.selectedSegmentIndex])];

    [accountSetting setOutgoingPort:@(self.outgoingPortField.text.integerValue)];

    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)cancelButton:(id)sender
{

}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];

    //TO DO: reset connection item and attempt a fresh connection

    return NO;
}



- (void)textFieldDidEndEditing:(UITextField *)textField
{

}


@end
