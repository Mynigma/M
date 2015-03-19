//
//  OutgoingSettingsController.h
//  Mynigma
//
//  Created by Roman Priebe on 15/04/2013.
//  Copyright (c) 2013 Parakeet. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class IMAPAccountSetting, IMAPAccount, MCOSMTPOperation;

@interface OutgoingSettingsController : NSWindowController
{
    MCOSMTPOperation* smtpCheckOperation;
}

@property IBOutlet NSPopUpButton* encryptionButton;

- (IBAction)checkSettingsButton:(id)sender;
- (IBAction)doneButton:(id)sender;

@property IMAPAccount* account;
@property IBOutlet NSTextField* pwdField;

@property BOOL isChecking;
@property NSString* feedbackString;

@end
