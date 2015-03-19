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

#import "SetupFlowPageControllerServerSettings.h"
#import <MailCore/MailCore.h>
#import "MovingPlaceholderTextField.h"
#import "IconListAndColourHelper.h"




@interface SetupFlowPageControllerServerSettings ()

@end

@implementation SetupFlowPageControllerServerSettings

#pragma mark - Setup

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.settingsTopMarginConstraint setConstant:500];
}








- (NSNumber*)standardPortForIncoming:(MCOConnectionType)encryptionType
{
    switch(encryptionType)
    {
        case MCOConnectionTypeTLS:
            return @993;
        case MCOConnectionTypeStartTLS:
            return @143;
        case MCOConnectionTypeClear:
        default:
            return @143;
    }
}

- (NSNumber*)standardIncomingPort
{
    return [self standardPortForIncoming:self.connectionItem.incomingConnectionType.integerValue];
}


- (NSNumber*)standardPortForOutgoing:(MCOConnectionType)encryptionType
{
    switch(encryptionType)
    {
        case MCOConnectionTypeTLS:
            return @465;
        case MCOConnectionTypeStartTLS:
            return @587;
        case MCOConnectionTypeClear:
        default:
            return @25;
    }
}

- (NSNumber*)standardOutgoingPort
{
    return [self standardPortForOutgoing:self.connectionItem.outgoingConnectionType.integerValue];
}



- (NSInteger)indexOfEncryptionType:(MCOConnectionType)encryptionType
{
    switch(encryptionType)
    {
        case MCOConnectionTypeTLS: return 0;
        case MCOConnectionTypeStartTLS: return 1;
        case MCOConnectionTypeClear: return 2;
        default: return 0;
    }
}


- (NSNumber*)connectionTypeForSelectedIndex:(NSInteger)selectedIndex
{
    switch(selectedIndex)
    {
        case 0:
            return @(MCOConnectionTypeTLS);
        case 1:
            return @(MCOConnectionTypeStartTLS);
        case 2:
            return @(MCOConnectionTypeClear);
            
        default:
            return @(MCOConnectionTypeTLS);
    }
}



#pragma mark - IBActions


- (IBAction)showSettings:(id)sender
{
    [self.showSettingsButton setHidden:YES];
    [self.buttonSeparator setHidden:YES];
    
    [self.autoDetectCoverLabel setHidden:YES];
    
    [UIView animateWithDuration:1. delay:0 usingSpringWithDamping:.6 initialSpringVelocity:.5 options:0 animations:^{
        
        [self.settingsTopMarginConstraint setConstant:30];
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        
    } completion:nil];
}

- (void)hideSettings
{
    [self.showSettingsButton setHidden:NO];
    [self.buttonSeparator setHidden:NO];
    
    [self.autoDetectCoverLabel setHidden:NO];
    
    [self.settingsTopMarginConstraint setConstant:500];
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}



- (void)updateIncomingOutletValuesForPort
{
    if(self.incomingDetectPortSwitch.isOn)
    {
        [self.incomingPortTextField setText:nil];
        [self.incomingPortTextField setEnabled:NO];
        [self.incomingPortTextField setTintColor:[UIColor lightGrayColor]];
    }
    else
    {
        [self.incomingPortTextField setText:self.connectionItem.incomingPort.stringValue];
        [self.incomingPortTextField setEnabled:YES];
        [self.incomingPortTextField setTintColor:NAVBAR_COLOUR];
    }
}

- (void)updateOutgoingOutletValuesForPort
{
    if(self.outgoingDetectPortSwitch.isOn)
    {
        [self.outgoingPortTextField setText:nil];
        [self.outgoingPortTextField setEnabled:NO];
        [self.outgoingPortTextField setTintColor:[UIColor lightGrayColor]];
    }
    else
    {
        [self.outgoingPortTextField setText:self.connectionItem.outgoingPort.stringValue];
        [self.outgoingPortTextField setEnabled:YES];
        [self.outgoingPortTextField setTintColor:NAVBAR_COLOUR];
    }
}

- (IBAction)valueChanged:(id)sender
{
    if(sender == self.incomingConnectionTypeSegmentedControl)
    {
        [self.connectionItem setIncomingConnectionType:[self connectionTypeForSelectedIndex:[(UISegmentedControl*)sender selectedSegmentIndex]]];
    }
    
    if(sender == self.incomingDetectPortSwitch)
    {
        if([(UISwitch*)sender isOn])
        {
            //nil to detect the port
            [self.connectionItem setIncomingPort:nil];
        }
        else
        {
            [self.connectionItem setIncomingPort:[self standardIncomingPort]];
        }
        
        [self updateIncomingOutletValuesForPort];
    }
    
    
    if(sender == self.outgoingConnectionTypeSegmentedControl)
    {
        [self.connectionItem setIncomingConnectionType:[self connectionTypeForSelectedIndex:[(UISegmentedControl*)sender selectedSegmentIndex]]];
    }
    
    if(sender == self.outgoingDetectPortSwitch)
    {
        if([(UISwitch*)sender isOn])
        {
            //nil to detect the port
            [self.connectionItem setOutgoingPort:nil];
        }
        else
        {
            [self.connectionItem setOutgoingPort:[self standardOutgoingPort]];
        }
        
        [self updateOutgoingOutletValuesForPort];
    }
}




#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if(textField == self.incomingServerNameField)
    {
        [self.connectionItem setIncomingHost:textField.text];
        
        [self.outgoingServerNameField becomeFirstResponder];
    }
    
    if(textField == self.incomingPortTextField)
    {
        [self.connectionItem setIncomingPort:@(textField.text.integerValue)];
    }
    
    if(textField == self.outgoingServerNameField)
    {
        [self.connectionItem setOutgoingHost:textField.text];
    }
    
    if(textField == self.outgoingPortTextField)
    {
        [self.connectionItem setOutgoingPort:@(textField.text.integerValue)];
    }
}

@end
