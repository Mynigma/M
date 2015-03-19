//
//  IncomingSettingsController.m
//  Mynigma
//
//  Created by Roman Priebe on 15/04/2013.
//  Copyright (c) 2013 Parakeet. All rights reserved.
//

#import "IncomingSettingsController.h"
#import "IMAPAccountSetting.h"
#import "AppDelegate.h"
#import "Model.h"
#import "KeychainHelper.h"
#import "IMAPAccount.h"
#import <MailCore/MailCore.h>


@interface IncomingSettingsController ()

@end

@implementation IncomingSettingsController

//@synthesize account;
@synthesize pwdField;

@synthesize isChecking;
@synthesize feedbackString;
@synthesize encryptionButton;
@synthesize nextButton;


- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        [self setIsChecking:NO];
        [self setFeedbackString:nil];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    if(APPDELEGATE.accountBeingSetup)
    {
        switch(APPDELEGATE.accountBeingSetup.imapSession.connectionType)
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
    if(APPDELEGATE.accountBeingSetup)
    {
        switch(encryptionButton.indexOfSelectedItem)
        {
            case 0: [APPDELEGATE.accountBeingSetup.imapSession setConnectionType:MCOConnectionTypeClear];
                break;
            case 1: [APPDELEGATE.accountBeingSetup.imapSession setConnectionType:MCOConnectionTypeStartTLS];
                 break;
            case 2: [APPDELEGATE.accountBeingSetup.imapSession setConnectionType:MCOConnectionTypeTLS];
                break;
        }
    }
    
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    if([control isEqual:encryptionButton])
    {
        
    }
    return YES;
}

- (IBAction)checkSettingsButton:(id)sender
{
    if(APPDELEGATE.accountBeingSetup)
    {
        //[self setFeedbackString:nil];
        //[self setIsChecking:YES];
        [APPDELEGATE.accountBeingSetup testIncomingServerWithCallBack:[^(NSError* error)
        {
            currentIMAPSession = [APPDELEGATE.accountBeingSetup testIncomingServerWithCallBack:[^(NSError* error)
                                                                           {
                                                                               //NSString* result = [IMAPAccount reasonForError:error];
            NSLog(@"%@",error);
                                                                           } copy]];
            //[self setFeedbackString:result];
            //[self setIsChecking:NO];
        } copy]];
    }
}

- (IBAction)nextButton:(id)sender
{
    if(APPDELEGATE.accountBeingSetup)
    {
        //[self setFeedbackString:nil];
        //[self setIsChecking:YES];
        [APPDELEGATE.accountBeingSetup testIncomingServerWithCallBack:[^(NSError* error)
                                                                       {
                                                                           [APPDELEGATE.accountBeingSetup testIncomingServerWithCallBack:[^(NSError* error)
                                                                                                                                          {
                                                                                                                                              //NSString* result = [IMAPAccount reasonForError:error];
                                                                                                                                              NSLog(@"%@",error);
                                                                                                                                          } copy]];
                                                                           //[self setFeedbackString:result];
                                                                           //[self setIsChecking:NO];
                                                                       } copy]];
    }
/*    if(APPDELEGATE.accountBeingSetup)
    {
        [self setFeedbackString:nil];
        [self setIsChecking:YES];
        [APPDELEGATE.accountBeingSetup testIncomingServerWithCallBack:^(NSError* error)
                              {
                                  NSString* result = [IMAPAccount reasonForError:error];
                                  [self setFeedbackString:result];
                                  [self setIsChecking:NO];
                                  if(!error)
                                      [APPDELEGATE showOutgoingAccountSettings:APPDELEGATE.accountBeingSetup];                                  
                              }];
    }*/
}

- (IBAction)cancelButton:(id)sender
{
    if(isChecking)
    {
        //[imapCheckOperation cancel];
       // imapCheckOperation = nil;
        if(currentIMAPSession)
            [APPDELEGATE.cancelledSessions addObject:currentIMAPSession];
        [self setIsChecking:NO];
    }
    else
    {
        [APPDELEGATE showAddAccountSheet];
        //[NSApp endSheet:[self window] returnCode:NSCancelButton];
        //[[self window] orderOut:self];
    }
}


@end
