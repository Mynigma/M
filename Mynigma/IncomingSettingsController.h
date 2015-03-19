//
//  IncomingSettingsController.h
//  Mynigma
//
//  Created by Roman Priebe on 15/04/2013.
//  Copyright (c) 2013 Parakeet. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class IMAPAccountSetting, MCOIMAPOperation, IMAPAccount, MCOIMAPSession;

@interface IncomingSettingsController : NSWindowController
{
    MCOIMAPSession* currentIMAPSession;
}


- (IBAction)checkSettingsButton:(id)sender;
- (IBAction)nextButton:(id)sender;
- (IBAction)cancelButton:(id)sender;
- (IBAction)encryptionSelector:(id)sender;

@property IBOutlet NSPopUpButton* encryptionButton;

//@property(strong) IMAPAccount* account;
@property IBOutlet NSTextField* pwdField;

@property BOOL isChecking;
@property NSString* feedbackString;
@property IBOutlet NSButton* nextButton;


@end
