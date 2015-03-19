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




#import "AppDelegate.h"
#import "KeychainHelper.h"
#import "AccountSettingsController.h"
#import "IMAPAccountSetting.h"
#import "IMAPAccount.h"
#import "GmailAccountSetting.h"
#import "AccountSetupEntryCell.h"
#import "IconListAndColourHelper.h"
#import "UserSettings+Category.h"




@interface AccountSettingsController ()

@end

@implementation AccountSettingsController


@synthesize emailField;
@synthesize passwordField;
@synthesize incomingServerField;
@synthesize outgoingServerField;
@synthesize advancedSettingsShown;
@synthesize incomingEncryptionField;
@synthesize incomingPortField;
@synthesize incomingUserNameField;
@synthesize outgoingEncryptionField;
@synthesize outgoingPortField;
@synthesize outgoingUserNameField;


@synthesize showAdvancedSettings;
@synthesize showIncomingConnectionTypes;
@synthesize showOutgoingConnectionTypes;
@synthesize showServerHostnames;
@synthesize showUserName;

@synthesize activityIndicator;

@synthesize userNameDefaultCell;
@synthesize serverHostnamesDefaultCell;
@synthesize incomingDefaultCell;
@synthesize outgoingDefaultCell;





- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    showAdvancedSettings = NO;
    showServerHostnames = NO;
    showUserName = NO;
    showIncomingConnectionTypes = NO;
    showOutgoingConnectionTypes = NO;

    [self.navigationController.navigationBar.topItem setTitle:@""];


    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2 + (showAdvancedSettings?4:0);
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section)
    {
        case 0:return 2;
        case 1:return 1;
        case 2:
            if(showServerHostnames)
            {
                return 3;
            }
            else
                return 1;
        case 3:
            if(showUserName)
            {
                return 2;
            }
            else
                return 1;
        case 4:
            if(showIncomingConnectionTypes)
            {
                return 4;
            }
            else
                return 1;
        case 5:
            if(showOutgoingConnectionTypes)
            {
                return 4;
            }
            else
                return 1;
    }
    return 0;
}

 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
 {
 static NSString *CellIdentifier = @"EntryCell";

     switch(indexPath.section)
     {
             case 0:
             if(indexPath.row==0)
             {
                 AccountSetupEntryCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
                 [cell.textField setText:@"Email address"];
                 [cell.textEntryField setPlaceholder:@"you@provider.com"];
                 return cell;
             }
             if(indexPath.row==1)
             {
                 AccountSetupEntryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PasswordEntryCell" forIndexPath:indexPath];
                 [cell.textField setText:@"Password"];
                 [cell.textEntryField setPlaceholder:@"password"];
                 return cell;
             }
     }
 UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

 
 return cell;
 }

- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}


- (IBAction)tryOrSetupServers:(id)sender
{
    NSString* email = [emailField.text lowercaseString];
    if([[[UserSettings currentUserSettings].accounts valueForKey:@"emailAddress"] containsObject:email])
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"This account is already in use!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
    else
    {
        NSArray* emailComponents = [email componentsSeparatedByString:@"@"];
        if([emailComponents count]!=2)
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Oups" message:@"Please enter a valid email address" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
        }
        else
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Terms & conditions" message:@"Please confirm that you accept the terms and conditions (available at mynimga.org/terms)" delegate:self cancelButtonTitle:@"Confirm" otherButtonTitles:@"Cancel", nil];
            [alert setTag:1];
            [alert show];
        }
    }
}


- (IBAction)setUpAccount:(id)sender
{
    NSString* email = [emailField.text lowercaseString];
    if([[[UserSettings currentUserSettings].accounts valueForKey:@"emailAddress"] containsObject:email])
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"This email has already been registered!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
    else
    {
        NSArray* emailComponents = [email componentsSeparatedByString:@"@"];
        if([emailComponents count]!=2)
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Oups" message:@"Please enter a valid email address" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
        }
        else
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Terms & conditions" message:@"Please confirm that you accept the terms and conditions (available at mynimga.org/terms)" delegate:self cancelButtonTitle:@"Confirm" otherButtonTitles:@"Cancel", nil];
            [alert setTag:1];
            [alert show];
        }
    }
}



- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch(alertView.tag)
    {
        case 1: //T&C page
            if(buttonIndex==0) //accepted
            {
                //IMAPAccount* newAccount = [IMAPAccount new];

                /*
                    [newAccount temporaryAccountWithEmail:@"wilhelm.schuettelspeer@gmail.com"];
                    [newAccount.imapSession setPassword:@"speerschuettel"];
                    [newAccount.smtpSession setPassword:@"speerschuettel"];

                    [newAccount makeAccountPermanent];

                    [newAccount startupCheckAccount];

                    [self dismissViewControllerAnimated:YES completion:^{}];

                    */
                /*


                     IMAPAccountSetting* newAccountSetting;
                     IMAPAccount* newIMAPAccount;
                     if([@[@"gmail.com",@"googlemail.com",@"gmail.de",@"googlemail.de"] containsObject:emailComponents[1]])
                     {
                     NSEntityDescription* entity = [NSEntityDescription entityForName:@"GmailAccountSetting" inManagedObjectContext:MAIN_CONTEXT];
                     newAccountSetting = [[GmailAccountSetting alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];
                     [MODEL saveContext];
                     newIMAPAccount = [[IMAPAccount alloc] init];
                     }
                     else
                     {
                     NSEntityDescription* entity = [NSEntityDescription entityForName:@"IMAPAccountSetting" inManagedObjectContext:MAIN_CONTEXT];
                     newAccountSetting = [[IMAPAccountSetting alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];
                     [MODEL saveContext];
                     newIMAPAccount = [[IMAPAccount alloc] init];
                     }

                     [newAccountSetting setDisplayName:email];
                     [newAccountSetting setEmailAddress:email];
                     //[newIMAPAccount setDisplayName:email];

                     [newAccountSetting setIncomingServer:incomingServerField.text];
                     [newAccountSetting setOutgoingServer:outgoingServerField.text];

                     [newAccountSetting setIncomingUserName:incomingUserNameField.text];
                     NSInteger incomingEncryption = MCOConnectionTypeTLS;
                     switch(incomingEncryptionField.selectedSegmentIndex)
                     {
                     case 0: incomingEncryption = MCOConnectionTypeTLS;
                     break;
                     case 1: incomingEncryption = MCOConnectionTypeStartTLS;
                     break;
                     case 2: incomingEncryption = MCOConnectionTypeClear;
                     break;
                     }
                     [newAccountSetting setIncomingEncryption:[NSNumber numberWithUnsignedInteger:incomingEncryption]];
                     [newAccountSetting setIncomingPort:[NSNumber numberWithInteger:incomingPortField.text.integerValue]];
                     [newAccountSetting setOutgoingEmail:email];
                     NSInteger outgoingEncryption = MCOConnectionTypeTLS;
                     switch(outgoingEncryptionField.selectedSegmentIndex)
                     {
                     case 0: outgoingEncryption = MCOConnectionTypeTLS;
                     break;
                     case 1: outgoingEncryption = MCOConnectionTypeStartTLS;
                     break;
                     case 2: outgoingEncryption = MCOConnectionTypeClear;
                     break;
                     }
                     [newAccountSetting setOutgoingEncryption:[NSNumber numberWithUnsignedInteger:outgoingEncryption]];
                     [newAccountSetting setOutgoingPort:[NSNumber numberWithInteger:outgoingPortField.text.integerValue]];
                     [newAccountSetting setOutgoingUserName:outgoingUserNameField.text];

                     [KeychainHelper savePassword:passwordField.text forAccount:newAccountSetting.objectID incoming:YES];
                     [KeychainHelper savePassword:passwordField.text forAccount:newAccountSetting.objectID incoming:NO];

                     //[newIMAPAccount setAccountSetting:newAccountSetting];

                     [MODEL.currentUserSettings addAccountsObject:newAccountSetting];
                     NSMutableArray* newAccountArray = [NSMutableArray arrayWithArray:MODEL.accounts];
                     [newAccountArray addObject:newIMAPAccount];
                     [MODEL setAccounts:newAccountArray];
                     [newAccountSetting setLastChecked:[NSDate dateWithTimeIntervalSince1970:0]];

                     [newIMAPAccount startupCheckAccount];
                     */
                    /*[newIMAPAccount testIncomingServerWithCallback:^(NSError* incomingError)
                     {
                     if(!incomingError)
                     {
                     [newIMAPAccount testOutgoingServerWithCallback:^(NSError* outgoingError) {

                     if(incomingError || outgoingError)
                     {
                     dispatch_async(dispatch_get_main_queue(),^{
                     NSMutableString* errorMessage = [NSMutableString stringWithString:@"There was a problem"];
                     if(incomingError)
                     {
                     [errorMessage appendFormat:@" with the incoming settings (%@)",[MODEL reasonForError:incomingError]];
                     if(outgoingError)
                     [errorMessage appendString:@" and"];
                     else
                     [errorMessage appendString:@"."];
                     }
                     if(outgoingError)
                     {
                     [errorMessage appendFormat:@" with the outgoing settings (%@).",[MODEL reasonForError:outgoingError]];

                     }

                     UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                     [alert show];
                     });
                     }
                     else
                     {
                     dispatch_async(dispatch_get_main_queue(),^{
                     UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Congratulations! Logging in." message:@"You will be prompted on your existing devices to allow access to safe messages." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                     [alert show];
                     });
                     [MODEL saveContext];
                     
                     dispatch_async(dispatch_get_main_queue(), ^{
                     
                     [APPDELEGATE refreshFolders];
                     [MODEL saveContext];
                     [newIMAPAccount checkAccount];
                     
                     });
                     }
                     
                     dispatch_async(dispatch_get_main_queue(), ^{
                     [activityIndicator stopAnimating];
                     });
                     
                     } fromAddress:email];
                     }
                     }];
                     }];*/
                //}];


    }
    }
    //if([alertView.title isEqualToString:@"Congratulations! Logging in."])
    //   [self dismissViewControllerAnimated:YES completion:^{}];
}
/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Text field delegate
- (BOOL)tryToFindProviderDetails
{
    NSString* email = emailField.text;
    MCOMailProvider *accountProvider = [MCOMailProvidersManager.sharedManager providerForEmail:email];
    if (!accountProvider) {
        //NSLog(@"No provider available for email: %@", email);
        return NO;
    }
    //Check if the account provides you with IMAP services
    NSArray *imapServices = accountProvider.imapServices;
    if (imapServices.count != 0)
    {
        MCONetService *imapService = [imapServices objectAtIndex:0];
        [incomingServerField setText:imapService.hostname];
        [incomingPortField setText:[NSString stringWithFormat:@"%d",imapService.port]];
        switch(imapService.connectionType)
        {
            case MCOConnectionTypeClear: [incomingEncryptionField setSelectedSegmentIndex:2];
                break;
            case MCOConnectionTypeStartTLS: [incomingEncryptionField setSelectedSegmentIndex:1];
                break;
            case MCOConnectionTypeTLS: [incomingEncryptionField setSelectedSegmentIndex:0];
                break;
        }
    }

    NSArray* smtpServices = accountProvider.smtpServices;
    if (smtpServices.count != 0)
    {
        MCONetService *smtpService = [smtpServices objectAtIndex:0];
        [outgoingServerField setText:smtpService.hostname];
        [outgoingPortField setText:[NSString stringWithFormat:@"%d",smtpService.port]];
        switch(smtpService.connectionType)
        {
            case MCOConnectionTypeClear: [outgoingEncryptionField setSelectedSegmentIndex:2];
                break;
            case MCOConnectionTypeStartTLS: [outgoingEncryptionField setSelectedSegmentIndex:1];
                break;
            case MCOConnectionTypeTLS: [outgoingEncryptionField setSelectedSegmentIndex:0];
                break;
        }
    }

    return YES;
}




- (void)textFieldDidEndEditing:(UITextField *)textField //an email was entered, so try to set correct values for provider, if possible, and generic values otherwise
{
    if([textField isEqual:emailField])
    {
    NSString* email = emailField.text;

    [incomingUserNameField setText:email];
    [outgoingUserNameField setText:email];

    NSArray* emailComponents = [email componentsSeparatedByString:@"@"];
    if([emailComponents count]!=2)
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Oups" message:@"Please enter a valid email address" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
    else
    {
        [incomingServerField setText:[NSString stringWithFormat:@"imap.%@",[emailComponents objectAtIndex:1]]];
        [outgoingServerField setText:[NSString stringWithFormat:@"smtp.%@",[emailComponents objectAtIndex:1]]];
        [incomingPortField setText:@"993"];
        [outgoingPortField setText:@"587"];
        [incomingEncryptionField setSelectedSegmentIndex:0];
        [outgoingEncryptionField setSelectedSegmentIndex:0];
        [self tryToFindProviderDetails];
    }
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

- (IBAction)showAdvancedSettings:(id)sender
{
    [self.tableView beginUpdates];
    showAdvancedSettings = YES;
    [self.tableView insertSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(2,4)] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch(indexPath.section)
    {
        case 1:
            if(showAdvancedSettings)
                return 0;
            else
                return 60;
            break;
    }
    return 44;
}





- (IBAction)toggleIncomingDefault:(id)sender
{
    if(showIncomingConnectionTypes)
    {
        showIncomingConnectionTypes = NO;
        [incomingDefaultCell setAccessoryType:showIncomingConnectionTypes?UITableViewCellAccessoryNone:UITableViewCellAccessoryCheckmark];
        [self.tableView reloadData];
    }
    else
    {
    [self.tableView beginUpdates];
    showIncomingConnectionTypes = YES;

    NSArray* indexPaths = @[[NSIndexPath indexPathForRow:1 inSection:4], [NSIndexPath indexPathForRow:2 inSection:4], [NSIndexPath indexPathForRow:3 inSection:4]];
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];

    [incomingDefaultCell setAccessoryType:showIncomingConnectionTypes?UITableViewCellAccessoryNone:UITableViewCellAccessoryCheckmark];

    [self.tableView reloadData];
    }
}

- (IBAction)toggleOutgoingDefault:(id)sender
{
    if(showOutgoingConnectionTypes)
    {
        showOutgoingConnectionTypes = NO;
        [outgoingDefaultCell setAccessoryType:showOutgoingConnectionTypes?UITableViewCellAccessoryNone:UITableViewCellAccessoryCheckmark];
        [self.tableView reloadData];
    }
    else
    {
        [self.tableView beginUpdates];
        showOutgoingConnectionTypes = YES;

        NSArray* indexPaths = @[[NSIndexPath indexPathForRow:1 inSection:5], [NSIndexPath indexPathForRow:2 inSection:5], [NSIndexPath indexPathForRow:3 inSection:5]];
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];

        [outgoingDefaultCell setAccessoryType:showOutgoingConnectionTypes?UITableViewCellAccessoryNone:UITableViewCellAccessoryCheckmark];
        
        [self.tableView reloadData];
    }
}


- (IBAction)toggleUserNameDefault:(id)sender
{
    if(showUserName)
    {
        showUserName = NO;
        [userNameDefaultCell setAccessoryType:showUserName?UITableViewCellAccessoryNone:UITableViewCellAccessoryCheckmark];
        [self.tableView reloadData];
    }
    else
    {
        [self.tableView beginUpdates];
        showUserName = YES;

        NSArray* indexPaths = @[[NSIndexPath indexPathForRow:1 inSection:3]];
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];

        [userNameDefaultCell setAccessoryType:showUserName?UITableViewCellAccessoryNone:UITableViewCellAccessoryCheckmark];
        
        [self.tableView reloadData];
    }
}

- (IBAction)toggleServerHostnamesDefault:(id)sender
{
    if(showServerHostnames)
    {
        showServerHostnames = NO;
        [serverHostnamesDefaultCell setAccessoryType:showServerHostnames?UITableViewCellAccessoryNone:UITableViewCellAccessoryCheckmark];
        [self.tableView reloadData];
    }
    else
    {
        [self.tableView beginUpdates];
        showServerHostnames = YES;

        NSArray* indexPaths = @[[NSIndexPath indexPathForRow:1 inSection:2], [NSIndexPath indexPathForRow:2 inSection:2]];
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];

        [serverHostnamesDefaultCell setAccessoryType:showServerHostnames?UITableViewCellAccessoryNone:UITableViewCellAccessoryCheckmark];
        
        [self.tableView reloadData];
    }
}


#pragma mark - Status Bar Style

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


@end
