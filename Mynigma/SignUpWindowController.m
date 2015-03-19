//
//  SignUpWindowController.m
//  BlueBird
//
//  Created by Roman Priebe on 15/07/2013.
//  Copyright (c) 2013 Mynigma. All rights reserved.
//

#import "SignUpWindowController.h"

@interface SignUpWindowController ()

@end

@implementation SignUpWindowController

@synthesize progressBar;
@synthesize okButton;
@synthesize resultLabel;
@synthesize account;

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
    [progressBar setDoubleValue:0];
    [resultLabel setHidden:YES];
    [okButton setEnabled:NO];
    success = NO;
    
    NSMethodSignature* methodSignature = [self methodSignatureForSelector:@selector(stepTimer)];
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:methodSignature];

    [invocation setSelector:@selector(stepTimer)];
    [invocation setTarget:self];
    timer = [NSTimer scheduledTimerWithTimeInterval:0.05 invocation:invocation repeats:YES];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)stepTimer
{
    double currentValue = progressBar.doubleValue;
    if(currentValue<100)
    {
        double newValue = currentValue+1;
        [progressBar setDoubleValue:newValue];
    }
    else
    {
        [okButton setEnabled:YES];
        [timer invalidate];
        timer = nil;
        [resultLabel setStringValue:@"Thank you for your patience, the account is being secured."];
        [resultLabel setHidden:NO];
    }
}

/*
- (void)done
{
    [timer invalidate];
    timer = nil;
    [progressBar setDoubleValue:100];
    [resultLabel setHidden:NO];
    [okButton setEnabled:YES];
    success = YES;
    if(account)
        [account signUpReturn:YES];
}

- (IBAction)closeWindow:(id)sender
{
    [NSApp endSheet:[self window] returnCode:NSOKButton];
    [[self window] orderOut:self];
    if(account && !success)
        [account signUpReturn:NO];
}*/


@end
