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





#import "AccountsListController.h"
#import "AppDelegate.h"
#import "UserSettings.h"
#import "IconListAndColourHelper.h"
#import "AccountCreationManager.h"
#import "IMAPAccount.h"
#import <MailCore/MailCore.h>
#import "KeychainHelper.h"
#import "AccountSetupEntryCell.h"
#import "IMAPAccountSetting.h"
#import "ConnectionItem.h"
#import "SplitViewController.h"
#import "IndividualAccountSettingsController.h"
#import "AccountSetupEntryCell.h"
#import "AlertHelper.h"
#import "UserSettings+Category.h"
#import "ViewControllersManager.h"
#import "AlertHelper.h"





@interface AccountsListController ()

@end

@implementation AccountsListController


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

    [self.navigationController.navigationBar.topItem setTitle:@""];
    
    [self setNeedsStatusBarAppearanceUpdate];

    [self.incomingActivityIndicator startAnimating];
    [self.outgoingActivityIndicator startAnimating];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(tableView.tag==133)
        return [super numberOfSectionsInTableView:tableView];

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(tableView.tag==133)
        return [super tableView:tableView numberOfRowsInSection:section];

    // Return the number of rows in the section.
    return [UserSettings usedAccounts].count+4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView.tag==133)
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];

    if(indexPath.row==[UserSettings usedAccounts].count)
    {
        static NSString *CellIdentifier = @"AddAccountCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

        return cell;
    }
    
    if(indexPath.row==[UserSettings usedAccounts].count+1)
    {
        static NSString *CellIdentifier = @"SetupAssistantCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        return cell;
    }

    
    /*

    if(indexPath.row==[UserSettings usedAccounts].count+1)
    {
        static NSString *CellIdentifier = @"DevicesCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

        return cell;
    } */

    if(indexPath.row==[UserSettings usedAccounts].count+2)
    {
        static NSString *CellIdentifier = @"CreditsCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

        return cell;
    }

    if(indexPath.row==[UserSettings usedAccounts].count+3)
    {
        static NSString *CellIdentifier = @"keyListCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

        return cell;
    }


    static NSString *CellIdentifier = @"AccountCell";
    AccountSetupEntryCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    //TO DO: make this more efficient and stable: cache the sorted list of IMAPAccountSettings

    NSSet* IMAPAccountSettings = [UserSettings usedAccounts];

    if(indexPath.row>=0 && indexPath.row<IMAPAccountSettings.count)
    {
        IMAPAccountSetting* accountSetting = [[IMAPAccountSettings sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"emailAddress" ascending:YES]]] objectAtIndex:indexPath.row];

        [cell.textField setText:accountSetting.displayName];
        [cell.detailField setText:accountSetting.emailAddress];
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView.tag==133)
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];

    return 90;
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

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row==[UserSettings usedAccounts].count)
    {
        //setup assistant
        UIViewController* setupController = [[ViewControllersManager setupFlowStoryboard] instantiateViewControllerWithIdentifier:@"setupSeparateController"];
        
        [self presentViewController:setupController animated:YES completion:nil];
    }

    if(indexPath.row==[UserSettings usedAccounts].count+1)
    {
        //setup assistant
        UIViewController* setupController = [[ViewControllersManager setupFlowStoryboard] instantiateViewControllerWithIdentifier:@"WelcomeScreen"];
        
        [self presentViewController:setupController animated:YES completion:nil];
    }
}

- (IBAction)cancelButton:(id)sender
{
    if(![self.view.window.rootViewController isKindOfClass:[SplitViewController class]])
    {
        UIStoryboard* storyboard = [ViewControllersManager mainStoryboard];
        UIViewController* mainScreenController = [storyboard instantiateInitialViewController];

        self.view.window.rootViewController = mainScreenController;

        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    }
    else
    {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}




- (IBAction)connectAsStandard:(id)sender
{
    NSString* email = self.emailField.text;
    NSString* password = self.passwordField.text;

    ConnectionItem* connectionItem = [[ConnectionItem alloc] initWithEmail:email];

    [connectionItem setIncomingPassword:password];
    [connectionItem setOutgoingPassword:password];

    [self setAccountBeingSetUp:connectionItem];

    UIViewController* viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"connectionScreen"];

    [self.navigationController pushViewController:viewController animated:YES];

    [connectionItem attemptImportWithCallback:^{

        if(connectionItem.IMAPSuccess && connectionItem.SMTPSuccess)
        {
            [AccountCreationManager makeNewAccountWithLocalKeychainItem:connectionItem];

            UIViewController* successController = [self.storyboard instantiateViewControllerWithIdentifier:@"successScreen"];
            [self.navigationController pushViewController:successController animated:YES];
        }
        else
        {
            [self.navigationController popViewControllerAnimated:YES];
            [AlertHelper showAlertWithMessage:connectionItem.feedbackString.string informativeText:nil];
        }
    }];
}


- (BOOL)shouldAutorotate
{
    return YES;
}


#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if([textField isEqual:self.emailField])
    {
        NSString* email = textField.text;

        //check if the email address is valid. if not simply return
        NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}";
        NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
        if([emailTest evaluateWithObject:email])
        {
            [self.passwordField becomeFirstResponder];
            return YES;
        }
        [AlertHelper showAlertWithMessage:@"Please enter a valid email address" informativeText:nil];
        return NO;
    }

    if([textField isEqual:self.passwordField])
    {
        [self connectAsStandard:self];
        return YES;
    }

    return YES;
}





- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController* destinationController = segue.destinationViewController;

    if([destinationController isKindOfClass:[IndividualAccountSettingsController class]])
    {
        if([sender isKindOfClass:[AccountSetupEntryCell class]])
        {
            NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];

            NSSet* IMAPAccountSettings = [UserSettings usedAccounts];

            if(indexPath.row>=0 && indexPath.row<IMAPAccountSettings.count)
            {
                IMAPAccountSetting* accountSetting = [[IMAPAccountSettings sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"emailAddress" ascending:YES]]] objectAtIndex:indexPath.row];
                [(IndividualAccountSettingsController*)destinationController setAccountSetting:accountSetting];
            }
        }
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


@end
