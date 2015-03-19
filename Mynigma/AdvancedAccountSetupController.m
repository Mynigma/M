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





#import "AdvancedAccountSetupController.h"
#import "AppDelegate.h"
#import "IMAPAccountSetting+Category.h"
#import "AccountCreationManager.h"
#import "KeychainHelper.h"
#import "EmailFooter.h"
#import "MCODelegate.h"
#import "AlertHelper.h"





@interface AdvancedAccountSetupController ()

@end

@implementation AdvancedAccountSetupController


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
    
    if(self.accountSetting)
    {
        NSString* incomingPassword = [KeychainHelper findPasswordForAccount:self.accountSetting.objectID incoming:YES];
        if(incomingPassword)
            [self.incomingPasswordField setStringValue:incomingPassword];

        NSString* outgoingPassword = [KeychainHelper findPasswordForAccount:self.accountSetting.objectID incoming:NO];
        if(outgoingPassword)
            [self.outgoingPasswordField setStringValue:outgoingPassword];

        if(!self.account)
        {
            self.account = self.accountSetting.account;
        }
    }

    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"EmailFooter"];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];

    self.footersList = [MAIN_CONTEXT executeFetchRequest:fetchRequest error:nil];

    [self.footerSelectionPopUp removeAllItems];
    [self.footerSelectionPopUp addItemWithTitle:NSLocalizedString(@"none",@"footer selection")];

    for(EmailFooter* footer in self.footersList)
    {
        [self.footerSelectionPopUp addItemWithTitle:footer.name];
        if([self.accountSetting.footer isEqual:footer])
            [self.footerSelectionPopUp selectItemAtIndex:self.footerSelectionPopUp.numberOfItems-1];
    }
}


- (IBAction)doneButtonClicked:(id)sender
{
    IMAPAccount* account = self.accountSetting.account;

    if(account)
    {
        [AccountCreationManager fillIMAPAccount:account withAccountSetting:self.accountSetting];
    }

    [CoreDataHelper save];

    [AlertHelper showSettings];
}


- (IBAction)footerSelectionChanged:(id)sender
{
    if(self.accountSetting)
    {
        NSInteger selectedIndex = [self.footerSelectionPopUp indexOfSelectedItem];
        if(selectedIndex==0)
            [self.accountSetting setFooter:nil];
        else
        {
            selectedIndex--;
            if(selectedIndex>=0 && selectedIndex<self.footersList.count)
            {
                EmailFooter* footer = self.footersList[selectedIndex];
                [self.accountSetting setFooter:footer];
            }
        }
    }
}


- (void)controlTextDidEndEditing:(NSNotification *)obj
{
    if([obj.object isEqual:self.incomingPasswordField])
    {
        NSString* newIncomingPassword = self.incomingPassword;
        [KeychainHelper savePassword:newIncomingPassword forAccount:self.accountSetting.objectID incoming:YES];
        IMAPAccount* account = self.accountSetting.account;

        if(account)
        {
            [AccountCreationManager fillIMAPAccount:account withAccountSetting:self.accountSetting];
        }
    }

    if([obj.object isEqual:self.outgoingPasswordField])
    {
        NSString* newOutgoingPassword = self.outgoingPassword;
        [KeychainHelper savePassword:newOutgoingPassword forAccount:self.accountSetting.objectID incoming:NO];
        IMAPAccount* account = self.accountSetting.account;

        if(account)
        {
            [AccountCreationManager fillIMAPAccount:account withAccountSetting:self.accountSetting];
        }
    }
}


- (IBAction)checkIncoming:(id)sender
{
    if(self.isCheckingIncoming)
    {
        [self setIsCheckingIncoming:NO];
        [self.incomingCheckButton setTitle:NSLocalizedString(@"Check", @"check account button")];
        [self setIncomingFeedbackString:NSLocalizedString(@"Check cancelled", @"check account feedback string")];
    }
    else
    {
        [self setIsCheckingIncoming:YES];
        [self controlTextDidEndEditing:[NSNotification notificationWithName:@"notification" object:self.incomingPasswordField]];
        [self.incomingCheckButton setTitle:NSLocalizedString(@"Cancel", @"Cancel Button")];
        [self setIncomingFeedbackString:NSLocalizedString(@"Checking settings...", @"check account feedback string")];
        [AccountCreationManager fillIMAPAccount:self.account withAccountSetting:self.accountSetting];
        [AccountCreationManager testIncomingServerUsingIMAPAccount:self.account withCallback:^(NSError* error, MCOIMAPSession* session) {
            [self setIncomingFeedbackString:[MCODelegate reasonForError:error]];
            [self.incomingCheckButton setTitle:NSLocalizedString(@"Check", @"check account button")];
            [self setIsCheckingIncoming:NO];
        }];
   }
}


- (IBAction)checkOutgoing:(id)sender
{
    if(self.isCheckingOutgoing)
    {
        [self setIsCheckingOutgoing:NO];
        [self.outgoingCheckButton setTitle:NSLocalizedString(@"Check", @"check account button")];
        [self setOutgoingFeedbackString:NSLocalizedString(@"Check cancelled", @"check account feedback string")];
    }
    else
    {
        [self setIsCheckingOutgoing:YES];
        [self controlTextDidEndEditing:[NSNotification notificationWithName:@"notification" object:self.outgoingPasswordField]];
        [self.outgoingCheckButton setTitle:NSLocalizedString(@"Cancel", @"Cancel Button")];
        [self setOutgoingFeedbackString:NSLocalizedString(@"Checking settings...", @"check account feedback string")];
        [AccountCreationManager fillIMAPAccount:self.account withAccountSetting:self.accountSetting];
        [AccountCreationManager testOutgoingServerUsingAccount:self.account withCallback:^(NSError* error, MCOSMTPSession* session) {
            [self setOutgoingFeedbackString:[MCODelegate reasonForError:error]];
            [self.outgoingCheckButton setTitle:NSLocalizedString(@"Check", @"check account button")];
            [self setIsCheckingOutgoing:NO];
        } fromAddress:self.accountSetting.emailAddress];
    }
}


@end
