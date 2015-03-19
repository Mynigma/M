//
//  OutgoingSettingsController.m
//  Mynigma
//
//  Created by Roman Priebe on 15/04/2013.
//  Copyright (c) 2013 Parakeet. All rights reserved.
//

#import "OutgoingSettingsController.h"
#import "IMAPAccountSetting.h"
#import "Model.h"
#import "AppDelegate.h"
#import "KeychainHelper.h"
#import "IMAPAccount.h"
#import <MailCore/MailCore.h>
#import "EncryptionHelper.h"



@interface OutgoingSettingsController ()

@end

@implementation OutgoingSettingsController

@synthesize account;
@synthesize pwdField;

@synthesize isChecking;
@synthesize feedbackString;
@synthesize encryptionButton;


- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    if(account)
    {
        switch(account.smtpSession.connectionType)
        {
            case MCOConnectionTypeClear:
                [encryptionButton selectItemAtIndex:0];
                break;
            case MCOConnectionTypeStartTLS:
                [encryptionButton selectItemAtIndex:1];
                break;
            case MCOConnectionTypeTLS:
                [encryptionButton selectItemAtIndex:2];
                break;
        }
    }   
}

- (IBAction)encryptionSelector:(id)sender
{
    if(account)
    {
        switch(encryptionButton.indexOfSelectedItem)
        {
            case 0: [account.smtpSession setConnectionType:MCOConnectionTypeClear];
                break;
            case 1: [account.smtpSession setConnectionType:MCOConnectionTypeStartTLS];
                break;
            case 2: [account.smtpSession setConnectionType:MCOConnectionTypeTLS];
                break;
        }
    }
}


- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
   return YES;
}

- (IBAction)checkSettingsButton:(id)sender
{
    if(account)
    {
        [self setFeedbackString:nil];
        [self setIsChecking:YES];
        [account testOutgoingServerWithCallBack:^(NSError* error, MCOSMTPSession* smtpSession)
                              {
                                  NSString* result = [IMAPAccount reasonForError:error];
                                  [self setFeedbackString:result];
                                  [self setIsChecking:NO];
                              } fromAddress:account.emailAddress];
    }

}

- (IBAction)doneButton:(id)sender
{
    if(account)
    {
        [self setFeedbackString:nil];
        [self setIsChecking:YES];
        [account testOutgoingServerWithCallBack:^(NSError* error, MCOSMTPSession* smtpSession)
                              {
                                  NSString* result = [IMAPAccount reasonForError:error];
                                  [self setFeedbackString:result];
                                  [self setIsChecking:NO];
                                  if(!error)
                                  {
                                      //success!!
                                      
                                      //close sheet
                                      [NSApp endSheet:[self window] returnCode:NSOKButton];
                                      [[self window] orderOut:self];
                                      
                                      //make an IMAPAccountSetting
                                      [account createNewAccountSettingForAccount];
                                      
                                      //create a key pair or fetch it from the keychain, if possible
                                      [EncryptionHelper ensureValidCurrentKeyPairForAccount:(IMAPAccountSetting*)[MODEL.mainObjectContext objectWithID:account.settingID] withCallback:^(BOOL success){
                                           //check the account
                                          if(success)
                                              [account startupCheckAccount];
                                       }];
                                      
                                      //congratulate the happy user
                                      NSAlert* alert = [NSAlert alertWithMessageText:@"Your account is being set up for safe messages." defaultButton:@"Continue" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Depending on the size of your inbox, this may take a while... Thank you for your patience."];
                                      [alert runModal];
                                  }
                                  else
                                  {
                                      //oh no, there has been an error
                                      /*NSAlert* alert = [NSAlert alertWithMessageText:@"Connection failed." defaultButton:@"OK" alternateButton:@"Advanced settings" otherButton:nil informativeTextWithFormat:@"Please try re-entering the password or changing the advanced settings, if your account is not with a well-known provider like Yahoo or Gmail."];
                                      switch([alert runModal])
                                      {
                                          case NSAlertAlternateReturn:
                                              [APPDELEGATE showIncomingAccountSettings];
                                      }*/
                                      NSBeep();
                                  }
                                     [APPDELEGATE showOutgoingAccountSettings];
                                  } fromAddress:account.emailAddress];
    }
}


@end
