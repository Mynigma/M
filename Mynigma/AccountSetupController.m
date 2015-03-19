//
//  AccountSetupController.m
//  Mynigma
//
//  Created by Roman Priebe on 27/02/2013.
//  Copyright (c) 2013 Parakeet. All rights reserved.
//

#import "AccountSetupController.h"
#import "Model.h"
#import "AppDelegate.h"
#import "IMAPAccount.h"
#import "IMAPAccountSetting.h"
#import "KeychainHelper.h"
#import "MynigmaPublicKey.h"
#import "EmailContactDetail.h"
#import "EncryptionHelper.h"
#import "ServerHelper.h"

@interface AccountSetupController ()

@end

@implementation AccountSetupController

@synthesize keyTable;

@synthesize incomingPasswordField;
@synthesize outgoingPasswordField;
@synthesize incomingProgress;
@synthesize outgoingProgress;

@synthesize incomingFeedback;
@synthesize outgoingFeedback;

@synthesize selectedAccount;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        publicKeys = @[];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MynigmaPublicKey"];
    publicKeys = [MAIN_CONTEXT executeFetchRequest:fetchRequest error:nil];    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    NSLog(@"%ld public keys in table", [publicKeys count]);
    if([aTableView tag]==333)
        return [publicKeys count];
    return [MODEL.accounts count];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 32;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView* tableCellView = [tableView makeViewWithIdentifier:@"AccountNameCell" owner:self];
    [tableCellView.textField setStringValue:@"No name"];
    if(row<[MODEL.accounts count])
    {
        IMAPAccount* account = [MODEL.accounts objectAtIndex:row];
        if(account && [account isKindOfClass:[IMAPAccount class]])
        {
            IMAPAccount* imapAccount = (IMAPAccount*)account;
            IMAPAccountSetting* accountSetting = (IMAPAccountSetting*)[MAIN_CONTEXT objectWithID:imapAccount.settingID];
            if(accountSetting)
            {
                [tableCellView.textField setStringValue:accountSetting.displayName];
            }
        }
     }
    return tableCellView;
}

- (IBAction)closeWindow:(id)sender
{
    [NSApp endSheet:[self window] returnCode:NSOKButton];
    [[self window] orderOut:self];
}

- (IBAction)addAccount:(id)sender
{
    [APPDELEGATE showAddAccountSheet];
}

- (NSError*)tryIncomingAccountSetting:(IMAPAccountSetting*)accountSetting
{
    return nil;//[IMAPAccount testIncomingServer:accountSetting.incomingServer withUserName:accountSetting.incomingUserName withPassword:incomingPasswordField.stringValue andPort:accountSetting.incomingPort.intValue connectionType:accountSetting.incomingEncryption.intValue authType:CTImapAuthTypePlain];
}

- (NSError*)tryOutgoingAccountSetting:(IMAPAccountSetting*)accountSetting
{
    return nil;//[IMAPAccount testOutgoingServer:accountSetting.outgoingServer withUserName:accountSetting.outgoingUserName withPassword:outgoingPasswordField.stringValue andPort:accountSetting.outgoingPort.intValue connectionType:accountSetting.outgoingEncryption.intValue useAuth:YES];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if(accountTable.selectedRow>=0 && accountTable.selectedRow<MODEL.accounts.count)
    {
        IMAPAccount* account = [MODEL.accounts objectAtIndex:accountTable.selectedRow];
        if(account && [account isKindOfClass:[IMAPAccount class]])
        {
            IMAPAccount* imapAccount = (IMAPAccount*)account;
            IMAPAccountSetting* accountSetting = (IMAPAccountSetting*)[MAIN_CONTEXT objectWithID:imapAccount.settingID];
            if(accountSetting)
            {
                [self setSelectedAccount:accountSetting];
                NSString* pwd = [KeychainHelper findPasswordForEmail:accountSetting.emailAddress andServer:accountSetting.incomingServer];
                if(pwd)
                {
                    [incomingPasswordField setStringValue:pwd];
                    [outgoingPasswordField setStringValue:pwd];
                }
                [self setIncomingFeedback:@""];
                [self setOutgoingFeedback:@""];
            }
        }
    }
}

- (IBAction)incomingCheck:(id)sender
{
    [self setIncomingFeedback:@""];
    [incomingProgress startAnimation:self];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString* feedback = @"Settings OK";
        NSError* error = [self tryIncomingAccountSetting:selectedAccount];
        if(error)
            feedback = error.localizedDescription;
        dispatch_async(dispatch_get_main_queue(),^{
        [self setIncomingFeedback:feedback];
        [incomingProgress stopAnimation:self];
        });
    });
}

- (IBAction)outgoingCheck:(id)sender
{
    [self setOutgoingFeedback:@""];
    [outgoingProgress startAnimation:self];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString* feedback = @"Settings OK";
        NSError* error = [self tryOutgoingAccountSetting:selectedAccount];
        if(error)
            feedback = error.localizedDescription;
        dispatch_async(dispatch_get_main_queue(),^{
            [self setOutgoingFeedback:feedback];
            [outgoingProgress stopAnimation:self];
        });
    });
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if(rowIndex<publicKeys.count)
    {
        MynigmaPublicKey* publicKey = [publicKeys objectAtIndex:rowIndex];
        if([[[aTableColumn headerCell] title] isEqualToString:@"KeyLabel"])
        {
            return [publicKey keyLabel];
        }
        if([[[aTableColumn headerCell] title] isEqualToString:@"Owner"])
        {
            return [[publicKey keyForEmail] address];
        }
        if([[[aTableColumn headerCell] title] isEqualToString:@"Have declaration"])
        {
            return [publicKey declaration]?@"Yes":@"No";
        }
    }
    return @"Oups";
}

- (IBAction)fetchKeys:(id)sender
{
}

@end
