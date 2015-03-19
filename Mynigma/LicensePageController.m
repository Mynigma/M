//
//  LincensePageController.m
//  BlueBird
//
//  Created by Roman Priebe on 26/07/2013.
//  Copyright (c) 2013 Mynigma. All rights reserved.
//

#import "LicensePageController.h"
#import "AppDelegate.h"
#import "Model.h"
#import "IMAPAccountSetting.h"
#import "EncryptionHelper.h"
#import "IMAPAccount.h"

@interface LicensePageController ()

@end

@implementation LicensePageController

@synthesize segmentSelector;
@synthesize tosField;
@synthesize acceptCheckbox;
@synthesize termsAccepted;


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
    [self setTermsAccepted:NO];
    NSString* tosPath = [[NSBundle mainBundle] pathForResource:@"Beta Use TOS" ofType:@"rtf"];
    if(!tosPath)
        return;
    NSData* tosData = [NSData dataWithContentsOfFile:tosPath];
    if(!tosData)
        return;
    NSAttributedString* tosString = [[NSAttributedString alloc] initWithRTF:tosData documentAttributes:nil];
    if(!tosString)
        return;
    [tosField setEditable:YES];
    [tosField setString:@""];
    [tosField insertText:tosString];
    [tosField setEditable:NO];
    [tosField scrollToBeginningOfDocument:self];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)segmentSelected:(id)sender
{
    /*
    if(sender && [sender isKindOfClass:[NSSegmentedControl class]])
    {
        if([sender selectedSegment]==0)
        { //personal use TOS
            NSString* tosPath = [[NSBundle mainBundle] pathForResource:@"Personal Use TOS" ofType:@"rtf"];
            if(!tosPath)
                return;
            NSData* tosData = [NSData dataWithContentsOfFile:tosPath];
            if(!tosData)
                return;
            NSAttributedString* tosString = [[NSAttributedString alloc] initWithRTF:tosData documentAttributes:nil];
            if(!tosString)
                return;
            [tosField setEditable:YES];
            [tosField setString:@""];
            [tosField insertText:tosString];
            [tosField setEditable:NO];
            [tosField scrollToBeginningOfDocument:self];
        }
        else
        { //commercial use TOS
            NSString* tosPath = [[NSBundle mainBundle] pathForResource:@"Commercial Use TOS" ofType:@"rtf"];
            if(!tosPath)
                return;
            NSData* tosData = [NSData dataWithContentsOfFile:tosPath];
            if(!tosData)
                return;
            NSAttributedString* tosString = [[NSAttributedString alloc] initWithRTF:tosData documentAttributes:nil];
            if(!tosString)
                return;
            [tosField setEditable:YES];
            [tosField setString:@""];
            [tosField insertText:tosString];
            [tosField setEditable:NO];
            [tosField scrollToBeginningOfDocument:self];
        }
    }
     */
}

- (IBAction)OKButtonClicked:(id)sender
{
    [NSApp endSheet:self.window returnCode:NSOKButton];
    [self.window orderOut:self];

    //close sheet and show the register controller
    [APPDELEGATE showExplanationSheet];
}

- (IBAction)cancelButtonClicked:(id)sender
{
    [NSApp endSheet:[self window] returnCode:NSCancelButton];
    [[self window] orderOut:self];

    //[APPDELEGATE showAddAccountSheet];
}

@end
