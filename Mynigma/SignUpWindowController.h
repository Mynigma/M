//
//  SignUpWindowController.h
//  BlueBird
//
//  Created by Roman Priebe on 15/07/2013.
//  Copyright (c) 2013 Mynigma. All rights reserved.
//

#import "IMAPAccount.h"


@interface SignUpWindowController : NSWindowController
{
    NSTimer* timer;
    BOOL success;
}

@property IMAPAccount* account;
@property IBOutlet NSButton* okButton;
@property IBOutlet NSTextField* resultLabel;
@property IBOutlet NSProgressIndicator* progressBar;

- (IBAction)closeWindow:(id)sender;
- (void)done;

@end
