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





#import "DetailedSetupController.h"

#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "KeychainHelper.h"
#import "IMAPAccount.h"
#import "UserSettings.h"
#import "IMAPAccountSetting.h"
#import "GmailAccountSetting.h"
#import "EmailContactDetail.h"
#import "EncryptionHelper.h"
#import <MailCore/MailCore.h>
#import "LicensePageController.h"
#import "AccountCreationManager.h"
#import "MCODelegate.h"
#import "ConnectionItem.h"
#import "AuthenticationChoiceTransformer.h"




@interface DetailedSetupController ()

@end

@implementation DetailedSetupController


@synthesize serverNamesBoxConstraint;
@synthesize credentialsBoxConstraint;
@synthesize securityBoxConstraint;
@synthesize standardPortsBoxConstraint;

@synthesize serverNamesBox;
@synthesize credentialsBox;
@synthesize securityBox;
@synthesize standardPortsBox;

@synthesize serverNamesCheckBox;
@synthesize credentialsCheckBox;
@synthesize securityCheckBox;
@synthesize standardPortsCheckBox;

@synthesize passwordField;
@synthesize emailAddressField;
@synthesize progressCircle;

@synthesize incomingPasswordField;
@synthesize incomingPortField;
@synthesize incomingUserNameField;
@synthesize incomingServerField;
@synthesize incomingAuthCheckButton;
@synthesize feedbackString;

@synthesize outgoingPasswordField;
@synthesize outgoingPortField;
@synthesize outgoingUserNameField;
@synthesize outgoingServerField;
@synthesize outgoingAuthCheckButton;

@synthesize incomingEncryptionField;
@synthesize outgoingEncryptionField;


@synthesize loginButton;
@synthesize cancelButton;

@synthesize incomingDefaultPortCheckBox;
@synthesize outgoingDefaultPortCheckBox;



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)retryConnection
{
    [self.connectionItem setSourceOfData:ConnectionItemSourceOfDataEnteredManually];

    ConnectionItem* __weak weakConnectionItem = self.connectionItem;

    NSView* __weak setupView = self.view.superview.superview;

    DetailedSetupController* __weak weakSelf = self;

    [self.connectionItem cancelAndResetConnections];

    [self.connectionItem attemptSpecificImportWithCallback:^{

        if(weakSelf.isClosing)
            return;

        if(weakConnectionItem.IMAPSuccess && weakConnectionItem.SMTPSuccess)
        {
            [weakSelf setIsClosing:YES];

            if([setupView respondsToSelector:@selector(popDetailedSettingsOutOfView)])
                [setupView performSelector:@selector(popDetailedSettingsOutOfView) withObject:nil afterDelay:1];

            [[NSSound soundNamed:@"Glass"] play];
        }
    }];
}

- (IBAction)errorLinkClicked:(id)sender
{
    if(self.connectionItem.isSuccessfullyImported)
        return;

    if(self.connectionItem.isImporting)
    {
        [self.connectionItem userCancelWithFeedback];
    }
    else
    {
        [self retryConnection];
    }
}

- (void)setupWithConnectionItem:(ConnectionItem*)connectionItem
{
    [self setConnectionItem:connectionItem];

    self.isClosing = NO;

    [serverNamesBox setHidden:YES];
    [serverNamesBoxConstraint setPriority:999];
    [credentialsBox setHidden:YES];
    [credentialsBoxConstraint setPriority:999];
    [securityBox setHidden:YES];
    [securityBoxConstraint setPriority:999];

    [serverNamesCheckBox setImage:[NSImage imageNamed:@"chevronUp"]];
    [credentialsCheckBox setImage:[NSImage imageNamed:@"chevronUp"]];
    [securityCheckBox setImage:[NSImage imageNamed:@"chevronUp"]];

    [serverNamesCheckBox setState:NSOnState];
    [credentialsCheckBox setState:NSOnState];
    [securityCheckBox setState:NSOnState];

    [self.incomingDefaultPortCheckBox setState:connectionItem.incomingPort?NSOffState:NSOnState];
    [self.outgoingDefaultPortCheckBox setState:connectionItem.outgoingPort?NSOffState:NSOnState];

    switch(connectionItem.IMAPError.code)
    {
            case MCOErrorAuthentication:
            case MCOErrorAuthenticationRequired:
            case MCOErrorCertificate:
        case MCOErrorCompression:
            [self showCredentials:YES];
            break;
            
            case MCOErrorCapability:
        case MCOErrorMobileMeMoved:
           [self showServerNames:YES];
            break;

        case MCOErrorConnection:
        case MCOErrorInvalidAccount:
            [self showSecurity:YES];
            [self showServerNames:YES];
            break;

        case MCOErrorStartTLSNotAvailable:
        case MCOErrorTLSNotAvailable:
            [self showSecurity:YES];
            break;
    }

    return;
}

- (void)loadView
{
    [super loadView];

    [progressCircle startAnimation:self];
    [serverNamesBox setHidden:YES];
    [serverNamesBoxConstraint setPriority:999];
    [credentialsBox setHidden:YES];
    [credentialsBoxConstraint setPriority:999];
    [securityBox setHidden:YES];
    [securityBoxConstraint setPriority:999];

    [serverNamesCheckBox setImage:[NSImage imageNamed:@"chevronUp"]];
    [credentialsCheckBox setImage:[NSImage imageNamed:@"chevronUp"]];
    [securityCheckBox setImage:[NSImage imageNamed:@"chevronUp"]];

    [serverNamesCheckBox setState:NSOnState];
    [credentialsCheckBox setState:NSOnState];
    [securityCheckBox setState:NSOnState];

    [self.incomingAuthButton removeAllItems];
    [self.incomingAuthButton addItemsWithTitles:[AuthenticationChoiceTransformer items]];

    [self.outgoingAuthButton removeAllItems];
    [self.outgoingAuthButton addItemsWithTitles:[AuthenticationChoiceTransformer items]];
    
    [self.view layout];
}

- (void)showServerNames:(BOOL)show
{
    [serverNamesBox setHidden:!show];
    [serverNamesCheckBox setImage:[NSImage imageNamed:show?@"chevronDown":@"chevronUp"]];
    [serverNamesCheckBox setState:show?NSOffState:NSOnState];

    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:.3];
    [[NSAnimationContext currentContext] setAllowsImplicitAnimation:YES];
    [serverNamesBoxConstraint.animator setPriority:show?1:999];
    [self.view layoutSubtreeIfNeeded];
    [NSAnimationContext endGrouping];
}


- (IBAction)serverNamesBoxChecked:(id)sender
{
    [self showServerNames:self.serverNamesCheckBox.state != NSOnState];
}

- (void)showCredentials:(BOOL)show
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:.3];
    [credentialsCheckBox setImage:[NSImage imageNamed:show?@"chevronDown":@"chevronUp"]];
    [credentialsBox setHidden:!show];
    [credentialsBoxConstraint.animator setPriority:show?1:999];
    [credentialsCheckBox setState:show?NSOffState:NSOnState];
    [[NSAnimationContext currentContext] setAllowsImplicitAnimation:YES];
    [self.view layoutSubtreeIfNeeded];
    [NSAnimationContext endGrouping];
}

- (IBAction)credentialsBoxChecked:(id)sender
{
    [self showCredentials:self.credentialsCheckBox.state != NSOnState];
}

- (void)showSecurity:(BOOL)show
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:.3];
    [securityCheckBox setImage:[NSImage imageNamed:show?@"chevronDown":@"chevronUp"]];
    [securityBox setHidden:!show];
    [securityBoxConstraint.animator setPriority:show?1:999];
    [securityCheckBox setState:show?NSOffState:NSOnState];
    [[NSAnimationContext currentContext] setAllowsImplicitAnimation:YES];
    [self.view layoutSubtreeIfNeeded];
    [NSAnimationContext endGrouping];
}

- (IBAction)securityBoxChecked:(id)sender
{
    [self showSecurity:self.securityCheckBox.state != NSOnState];
}

- (void)controlTextDidEndEditing:(NSNotification *)obj
{
    if ([obj.userInfo[@"NSTextMovement"] unsignedIntegerValue])
    {
        [self retryConnection];
    }
}


- (void)controlTextDidChange:(NSNotification *)obj
{
//    if([obj.object isEqualTo:passwordField])
//    {
//        [incomingPasswordField setStringValue:passwordField.stringValue];
//        [outgoingPasswordField setStringValue:passwordField.stringValue];
//    }

    [self.view layoutSubtreeIfNeeded];
}


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

- (IBAction)incomingConnectionTypeChanged:(id)sender
{
    [self retryConnection];
}

- (IBAction)outgoingConnectionTypeChanged:(id)sender
{
    [self retryConnection];
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


- (IBAction)incomingDefaultPortBoxChecked:(id)sender
{
    if(incomingDefaultPortCheckBox.state==NSOnState)
    {
        [incomingPortField setEnabled:NO];
        [self.connectionItem setIncomingPort:nil];
    }
    else
    {
        [incomingPortField setEnabled:YES];
        [self.connectionItem setIncomingPort:@([self standardPortForIncoming:[self encryptionTypeWithIndex:[incomingEncryptionField selectedSegment]]])];
    }

    [self retryConnection];
}


- (IBAction)outgoingDefaultPortBoxChecked:(id)sender
{
    if(outgoingDefaultPortCheckBox.state==NSOnState)
    {
        [outgoingPortField setEnabled:NO];
        [self.connectionItem setOutgoingPort:nil];
    }
    else
    {
        [outgoingPortField setEnabled:YES];
        [self.connectionItem setOutgoingPort:@([self standardPortForOutgoing:[self encryptionTypeWithIndex:[outgoingEncryptionField selectedSegment]]])];
    }

    [self retryConnection];
}

@end
