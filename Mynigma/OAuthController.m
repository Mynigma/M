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

#import "OAuthController.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "ConnectionItem.h"
#import "AlertHelper.h"
#import "ViewControllersManager.h"
#import "AccountCreationManager.h"
#import "IMAPAccount.h"
#import "NSString+EmailAddresses.h"
#import "OAuthHelper.h"





@implementation OAuthController



- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
}

- (void)startOAuthWithConnectionItem:(ConnectionItem*)connectionItem fromRect:(CGRect)sourceRect
{
    GTMOAuth2ViewControllerTouch *OAuthController = [OAuthHelper getOAuthControllerWithConnectionItem:connectionItem withCallback:^(NSError* error, GTMOAuth2Authentication* auth){
        
        if (error != nil)
        {
            [AlertHelper presentError:error];
            
            [self dismissViewControllerAnimated:YES completion:nil];
            
            // Authentication failed
            // Error handling here
            return;
        }
        
        NSString * email = [auth userEmail];
        NSString * accessToken = [auth accessToken];
        
        if ((error != nil) || ![email isValidEmailAddress] || !accessToken)
        {
            [AlertHelper showAlertWithMessage:NSLocalizedString(@"Error", nil) informativeText:NSLocalizedString(@"Provider failed to return email address", nil)];
            
            [AlertHelper showTwoOptionDialogueWithTitle:NSLocalizedString(@"Error!", nil) message:NSLocalizedString(@"An error occured while authenticating your account.", nil) OKOption:NSLocalizedString(@"Try again", nil) cancelOption:NSLocalizedString(@"Use basic login", nil) suppressionIdentifier:nil callback:^(BOOL OKOptionSelected){
                
                if(OKOptionSelected)
                {
//#warning GOTO OAUTH CONTROLLER AGAIN
                    // try OAuth again
                    [self dismissViewControllerAnimated:YES completion:^{
                        
                        [[[ViewControllersManager sharedInstance] splitViewController] dismissViewControllerAnimated:YES completion:nil];
                    }];
                }
                else
                {
//#warning GOTO STANDARD LOGIN
                    // navigate to standard login
                    [self dismissViewControllerAnimated:YES completion:^{
                        
                        [[[ViewControllersManager sharedInstance] splitViewController] dismissViewControllerAnimated:YES completion:nil];
                    }];
                }
                
            }];
            
            // we depend on the email !!!
            // do something useful here !!
            return;
        }
        
        if([AccountCreationManager haveAccountForEmail:email])
        {
            [AlertHelper showAlertWithMessage:NSLocalizedString(@"Account exists", nil) informativeText:NSLocalizedString(@"This account has already been set up!", nil)];
            return;
        }
        
        [AccountCreationManager makeNewAccountWithLocalKeychainItem:connectionItem];
        
        [AlertHelper showTwoOptionDialogueWithTitle:NSLocalizedString(@"Success!", nil) message:NSLocalizedString(@"We will be setting up the encryption in the background, which is hard work, so please be patient if the app becomes a little slow. Would you like to set up another account?", nil) OKOption:NSLocalizedString(@"Yes", nil) cancelOption:NSLocalizedString(@"No", nil) suppressionIdentifier:nil callback:^(BOOL OKOptionSelected){
            
            if(OKOptionSelected)
            {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            else
            {
                [self dismissViewControllerAnimated:YES completion:^{
                    
                    [[[ViewControllersManager sharedInstance] splitViewController] dismissViewControllerAnimated:YES completion:nil];
                }];
            }
        }];
    }];
    
    if(OAuthController)
    {
        self.popoverNavController = [[UINavigationController alloc] initWithRootViewController:OAuthController];
        
        [self.popoverNavController setNavigationBarHidden:YES];
        
        [self.popoverNavController setModalPresentationStyle:UIModalPresentationPopover];
        
        UIPopoverPresentationController* popover = self.popoverNavController.popoverPresentationController;
        
        self.popoverNavController.preferredContentSize = CGSizeMake(400, 600);
       
        popover.delegate = self;
        popover.sourceView = self.view;
        popover.sourceRect = sourceRect;
        popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
        
        [self presentViewController:self.popoverNavController animated:YES completion:nil];
    }
}


#pragma mark - UIAdaptivePresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    //force popover on iPhone
    return UIModalPresentationNone;
}

@end
