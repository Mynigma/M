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





#import "AlertHelper.h"
#import "AppDelegate.h"
#import "ThreadHelper.h"
#import "MynigmaDevice+Category.h"
#import "TrustEstablishmentThread.h"




#if TARGET_OS_IPHONE

#import "DisplayMessageController.h"
#import "WelcomeScreenController.h"
#import "SharedSecretTrustController.h"
#import "ViewControllersManager.h"
#import "SetupFlowViewController.h"

#else

#import "SettingsController.h"
#import "AdvancedAccountSetupController.h"
#import "AttachmentAdditionController.h"
#import "SharedSecretConfirmationController.h"
#import "WindowManager.h"
#import "SettingsController.h"
#import "InvitationWindowController.h"

#endif


@implementation AlertHelper


#pragma mark - Shared instance

+ (instancetype)sharedInstance
{
    static dispatch_once_t p = 0;

    __strong static id sharedObject = nil;

    dispatch_once(&p, ^{
        sharedObject = [self new];
    });

    return sharedObject;
}

#if TARGET_OS_IPHONE


#pragma mark - UIAlertViewDelegate methods

+ (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 99)
    {
        if([AlertHelper sharedInstance].alertBoolCallback)
        {
            [AlertHelper sharedInstance].alertBoolCallback(buttonIndex != alertView.cancelButtonIndex);

            [AlertHelper sharedInstance].alertBoolCallback = nil;
        }
    }

    if(alertView.tag == 90)
    {
        if([AlertHelper sharedInstance].alertCallback)
        {
            [AlertHelper sharedInstance].alertCallback();

            [AlertHelper sharedInstance].alertCallback = nil;
        }

        return;
    }

    if(buttonIndex != [alertView cancelButtonIndex])
    {
        NSURL *applicationFilesDirectory = [AppDelegate applicationFilesDirectory];
        NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"Mynigma.storedata"];
        [[NSFileManager defaultManager] removeItemAtPath:url.path error:nil];
    }
}



#pragma mark - Callable methods

#pragma mark -
#pragma mark - iOS

+ (void)showAlertWithMessage:(NSString*)message informativeText:(NSString*)informativeText otherButtonTitle:(NSString*)buttonTitle
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Mynigma" message:[NSString stringWithFormat:@"%@%@%@", message, informativeText?@"\n":@"", informativeText?informativeText:@""] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:buttonTitle, nil];
    [alert show];
}

+ (UIViewController*) topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    if(topController.presentedViewController)
    {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

+ (void)showAlertWithTitle:(NSString*)title message:(NSString*)message callback:(void(^)(void))callback
{
    if(!title || !message)
    {
        callback();
        return;
    }

//    if(NSClassFromString(@"UIAlertController")!=nil)
//    {
//        UIAlertController* alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
//        
//        UIAlertAction* OKAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
//            
//            //            if(suppressionIdentifier)
//            //                [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:suppressionIdentifier];
//            
//            if(callback)
//                callback();
//        }];
//        
//        [alertController addAction:OKAction];
//        
//        UIViewController* viewController = [self topMostController];
//        
//        [viewController showViewController:alertController sender:nil];
//        
////         presentViewController:alertController animated:YES completion:nil];
//    }
//    else
//    {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];

    [alert setTag:90];

    [[AlertHelper sharedInstance] setAlertCallback:callback];

    [alert show];
//    }
    
}

+ (void)showTwoOptionDialogueWithTitle:(NSString*)title message:(NSString*)message OKOption:(NSString*)OKOption cancelOption:(NSString*)cancelOption suppressionIdentifier:(NSString*)suppressionIdentifier callback:(void(^)(BOOL OKOptionSelected))callback
{
    [AlertHelper showTwoOptionDialogueWithTitle:title message:message OKOption:OKOption cancelOption:cancelOption suppressionIdentifier:suppressionIdentifier fromViewController:nil callback:callback];
}

+ (void)showTwoOptionDialogueWithTitle:(NSString*)title message:(NSString*)message OKOption:(NSString*)OKOption cancelOption:(NSString*)cancelOption suppressionIdentifier:(NSString*)suppressionIdentifier fromViewController:(UIViewController*)presentingViewController callback:(void(^)(BOOL OKOptionSelected))callback
{
    NSNumber* suppressed = suppressionIdentifier?[[NSUserDefaults standardUserDefaults] objectForKey:suppressionIdentifier]:nil;

    if(suppressed)
    {
        //the user previously clicked "do not show this again"
        //re-use the previous choice
        callback(suppressed.boolValue);
        return;
    }

    [ThreadHelper runAsyncOnMain:^{

        if(NSClassFromString(@"UIAlertController")!=nil)
        {
            UIAlertController* alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction* OKAction = [UIAlertAction actionWithTitle:OKOption style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {

                //            if(suppressionIdentifier)
                //                [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:suppressionIdentifier];

                if(callback)
                    callback(YES);
            }];

            UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:cancelOption style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                           {

                                               //            if(suppressionIdentifier)
                                               //                [[NSUserDefaults standardUserDefaults] setObject:@NO forKey:suppressionIdentifier];
                                               if(callback)
                                                   callback(NO);
                                           }];

            [alertController addAction:OKAction];

            [alertController addAction:cancelAction];
            
            UIViewController* viewController = presentingViewController;

            if(!viewController)
                viewController = [ViewControllersManager sharedInstance].displayMessageController;
            
            [viewController presentViewController:alertController animated:YES completion:nil];
        }
        else
        {
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelOption otherButtonTitles:OKOption, nil];

            [alertView setTag:99];

            [[AlertHelper sharedInstance] setAlertBoolCallback:[callback copy]];

            [alertView setDelegate:self];

            [alertView show];
        }
    }];
}

+ (void)showAlertWithMessage:(NSString*)message informativeText:(NSString*)informativeText
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Mynigma" message:[NSString stringWithFormat:@"%@%@%@", message, informativeText?@"\n":@"", informativeText?informativeText:@""] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

+ (void)presentError:(NSError*)error
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@: %@", [error localizedDescription], [error localizedFailureReason]] message:[error localizedRecoverySuggestion] delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
    
    [alert show];
}


#else

#pragma mark -
#pragma mark - Mac OS

+ (NSInteger)showAlertWithMessage:(NSString*)message informativeText:(NSString*)informativeText otherButtonTitle:(NSString*)buttonTitle
{
    __block NSInteger returnValue = 0;

    [MAIN_CONTEXT performBlockAndWait:^{

        NSAlert* alert = [NSAlert alertWithMessageText:message defaultButton:@"OK" alternateButton:buttonTitle otherButton:nil informativeTextWithFormat:@"%@", informativeText];
        returnValue = [alert runModal];

    }];

    return returnValue;

}


+ (void)showTwoOptionDialogueWithTitle:(NSString*)title message:(NSString*)message OKOption:(NSString*)OKOption cancelOption:(NSString*)cancelOption suppressionIdentifier:(NSString*)suppressionIdentifier callback:(void(^)(BOOL OKOptionSelected))callback
{
    NSNumber* suppressed = suppressionIdentifier?[[NSUserDefaults standardUserDefaults] objectForKey:suppressionIdentifier]:nil;

    if(suppressed)
    {
        //the user previously clicked "do not show this again"
        //re-use the previous choice
        callback(suppressed.boolValue);
        return;
    }

    [ThreadHelper runAsyncOnMain:^{

        __block NSInteger result = 0;

        NSAlert* alert = [NSAlert alertWithMessageText:title defaultButton:OKOption alternateButton:cancelOption otherButton:nil informativeTextWithFormat:@"%@", message];

        [alert setShowsSuppressionButton:suppressionIdentifier!=nil];

        result = [alert runModal];

        if(alert.suppressionButton.state == NSOnState)
        {
            if(suppressionIdentifier)
                [[NSUserDefaults standardUserDefaults] setObject:@(result == NSAlertDefaultReturn) forKey:suppressionIdentifier];
        }
        
        if(callback)
            callback(result == NSAlertDefaultReturn);
    }];
}

+ (void)showAlertWithMessage:(NSString*)message informativeText:(NSString*)informativeText
{
    [MAIN_CONTEXT performBlockAndWait:^{
        NSAlert* alert = [NSAlert alertWithMessageText:message defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", informativeText];
        [alert runModal];
    }];
}






+ (void)showDialogueWithTitle:(NSString*)title message:(NSString*)message options:(NSArray*)options suppressionIdenitifer:(NSString*)suppressionIdentifier callback:(void(^)(NSInteger indexOfSelectedOption))callback
{
    NSNumber* suppressed = suppressionIdentifier?[[NSUserDefaults standardUserDefaults] objectForKey:suppressionIdentifier]:nil;

    if(suppressed)
    {
        //the user previously clicked "do not show this again"
        //re-use the previous choice
        callback(suppressed.integerValue);
        return;
    }

    [ThreadHelper runAsyncOnMain:^{

        __block NSInteger result = 0;

        NSAlert* alert = [NSAlert new];

        [alert setMessageText:title];
        [alert setInformativeText:message];

        for(NSString* buttonTitle in options)
            [alert addButtonWithTitle:buttonTitle];

        [alert setShowsSuppressionButton:suppressionIdentifier!=nil];

        if([alert respondsToSelector:@selector(beginSheetModalForWindow:completionHandler:)])
        {
            //10.9 and above
            [alert performSelector:@selector(beginSheetModalForWindow:completionHandler:) withObject:APPDELEGATE.window withObject:^(NSModalResponse returnCode){

                if(alert.suppressionButton.state == NSOnState)
                {
                    if(suppressionIdentifier)
                        [[NSUserDefaults standardUserDefaults] setObject:@(result) forKey:suppressionIdentifier];
                }

                if(callback)
                    callback(result);
            }];
        }
        else
        {
            //10.8 and below

            //pass the callback and the suppression identifier in the context info
            NSMutableArray* newContextInfo = [NSMutableArray new];

            [newContextInfo addObject:callback];

            if(suppressionIdentifier)
                [newContextInfo addObject:suppressionIdentifier];

            [alert beginSheetModalForWindow:APPDELEGATE.window modalDelegate:[self sharedInstance] didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:(void*)CFBridgingRetain(newContextInfo)];
        }


    }];
}


- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    NSArray* contextInfoArray = CFBridgingRelease(contextInfo);

    NSString* suppressionIdentifier = nil;

    if(contextInfoArray.count > 1)
        suppressionIdentifier = contextInfoArray[1];

    if(alert.suppressionButton.state == NSOnState)
    {
        if(suppressionIdentifier)
            [[NSUserDefaults standardUserDefaults] setObject:@(returnCode) forKey:suppressionIdentifier];
    }

    void(^callback)(NSInteger result) = contextInfoArray.firstObject;

    if(callback)
        callback(returnCode);
}


+ (void)presentError:(NSError*)error
{
    [ThreadHelper runAsyncOnMain:^{
        [APPDELEGATE.window presentError:error];
    }];
}

#endif


#pragma mark - Sheets

#if TARGET_OS_IPHONE


+ (void)showWelcomeSheet
{
//    UIViewController* containerController = [[ContainerViewController alloc] initWithViewControllers:[self _configuredChildViewControllers]];
//
//    [[[ViewControllersManager sharedInstance] splitViewController] presentViewController:containerController animated:YES completion:nil];
//
//    return;


//    UIViewController* setupController = [[ViewControllersManager setupFlowStoryboard] instantiateInitialViewController];

    UIViewController* setupController = [[ViewControllersManager setupFlowStoryboard] instantiateViewControllerWithIdentifier:@"WelcomeScreen"];


    [[[ViewControllersManager sharedInstance] splitViewController] presentViewController:setupController animated:YES completion:nil];

//    UIWindow* window = APPDELEGATE.window;
//    UIStoryboard* storyboard = window.rootViewController.storyboard;
//
//    WelcomeScreenController* welcomeScreenController = [storyboard instantiateViewControllerWithIdentifier:@"WelcomeScreen"];
//
//    [UIView transitionWithView:window
//                      duration:1.
//                       options:UIViewAnimationOptionTransitionCrossDissolve
//                    animations:^{
//
//                        window.rootViewController = welcomeScreenController;
//                        [window makeKeyAndVisible];
//
//                    }
//                    completion:nil];

}

#else

/**
 Dismisses the currently displayed sheet, if any
 */
+ (void)dismissCurrentlyShownSheet
{
    NSWindowController* sheetController = [AlertHelper sharedInstance].sheetController;

    if(sheetController && [sheetController.window isVisible])
    {
        [NSApp endSheet:sheetController.window returnCode:NSOKButton];
        [sheetController.window orderOut:[AlertHelper sharedInstance]];
    }
}

/**
Loads the sheet from the respective xib
 */
+ (void)loadSheetOfClass:(Class)windowControllerClass withNibName:(NSString*)nibName
{
    //first remove any currently shown sheets
    [self dismissCurrentlyShownSheet];

    [[self sharedInstance] setSheetController:[[windowControllerClass alloc] initWithWindowNibName:nibName]];
}

/**
 Presents the sheet loaded by the previous method
 */
+ (void)presentSheet
{
    AlertHelper* alertHelper = [AlertHelper sharedInstance];
    NSWindowController* sheetController = [AlertHelper sharedInstance].sheetController;

    if([APPDELEGATE.window respondsToSelector:@selector(beginSheet:completionHandler:)])
    {
        //10.9 and above
        [APPDELEGATE.window beginSheet:sheetController.window completionHandler:sheetController?^(NSModalResponse returnCode){
        if(alertHelper.sheetCallback)
         {
             alertHelper.sheetCallback(returnCode);
             alertHelper.sheetCallback = nil;
         }
        }:nil];
    }
    else
    {
        //10.8 and below
        [NSApp beginSheet:[sheetController window] modalForWindow:APPDELEGATE.window modalDelegate:alertHelper didEndSelector: @selector(didEndSheet:returnCode:contextInfo:) contextInfo: nil];
    }
}

/**
 Load and present a sheet all in one go
 */
+ (void)loadAndPresentSheetOfClass:(Class)windowControllerClass withNibName:(NSString*)nibName
{
    [self loadSheetOfClass:windowControllerClass withNibName:nibName];
    [self presentSheet];
}



#pragma mark - Show particular sheets

+ (void)showSettings
{
    [self loadAndPresentSheetOfClass:[SettingsController class] withNibName:@"SettingsController"];
}

+ (void)showIndividualSettingsWithIMAPAccountSetting:(IMAPAccountSetting*)accountSetting
{
    [self loadSheetOfClass:[AdvancedAccountSetupController class] withNibName:@"AdvancedAccountSetupController"];
    
    NSWindowController* sheetController = [AlertHelper sharedInstance].sheetController;
    
    [(AdvancedAccountSetupController*)sheetController setAccountSetting:accountSetting];
    [self presentSheet];
}


+ (void)showAttachmentSheet
{
    [self loadAndPresentSheetOfClass:[AttachmentAdditionController class] withNibName:@"AttachmentAdditionController"];
}

+ (void)showWelcomeSheet
{
    [AlertHelper dismissCurrentlyShownSheet];

    [WindowManager startSetupAssistant];
}

//+ (void)showMynigmaAccountSettings:(IMAPAccountSetting*)accountSetting
//{
//    [AlertHelper loadAndPresentSheetOfClass:[MynigmaSet] WithNibName:@"MynigmaSettingsController"];
//}

#pragma mark - Sheet callback

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if(self.sheetCallback)
    {
        self.sheetCallback(returnCode);
        self.sheetCallback = nil;
    }
}

+ (void)showInvitationSheet
{
    [self loadAndPresentSheetOfClass:[InvitationWindowController class] withNibName:@"InvitationWindowController"];
}

+ (void)showOAuthSheet:(NSWindowController*)sheetController
{
    [[AlertHelper sharedInstance] setSheetController:sheetController];
    
    [self presentSheet];
}



#endif


#pragma mark - Device Connection

#if TARGET_OS_IPHONE


+ (void)showDigestChunks:(NSArray*)chunks withTargetDevice:(MynigmaDevice*)device
{
    UIStoryboard* storyboard = [ViewControllersManager mainStoryboard];

    UIViewController* sharedSecretController = [storyboard instantiateViewControllerWithIdentifier:@"sharedSecretController"];

    [(SharedSecretTrustController*)sharedSecretController setupWithDevice:device];
    [(SharedSecretTrustController*)sharedSecretController showShortDigests:chunks];

    [UIView transitionWithView:APPDELEGATE.window
                      duration:1.
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{

                        APPDELEGATE.window.rootViewController = sharedSecretController;
                        [APPDELEGATE.window makeKeyAndVisible];

                    }
                    completion:nil];
}


+ (void)showTrustEstablishmentProgress:(NSInteger)progressIndex
{
    //no longer showing user feedback for each individual step of the protocol

//    UIViewController* naviController = [UIApplication sharedApplication].keyWindow.rootViewController;
//
//    if(![naviController isKindOfClass:[UINavigationController class]])
//        if([naviController respondsToSelector:@selector(navigationController)])
//            naviController = naviController.navigationController;
//
//    if([naviController isKindOfClass:[UINavigationController class]])
//    {
//        UIViewController* topMostViewController = [(UINavigationController*)naviController topViewController];
//
//        if([topMostViewController isKindOfClass:[SharedSecretTrustController class]])
//        {
//            [(SharedSecretTrustController*)topMostViewController showProgress:progressIndex];
//        }
//    }
}

#else

+ (void)showTrustEstablishmentProgress:(NSInteger)progressIndex
{

}

+ (void)showDigestChunks:(NSArray*)chunks withTargetDevice:(MynigmaDevice*)device
{
    if([AlertHelper sharedInstance].sheetController && [[AlertHelper sharedInstance].sheetController.window isVisible])
    {
        [[AlertHelper sharedInstance].sheetController.window orderOut:self];
    }
    [AlertHelper sharedInstance].sheetController = [[SharedSecretConfirmationController alloc] initWithWindowNibName:@"SharedSecretConfirmationController"];

    NSWindowController* sheetController = [AlertHelper sharedInstance].sheetController;
    
    [(SharedSecretConfirmationController*)sheetController setTargetDevice:device];
    
    [NSApp beginSheet:[sheetController window] modalForWindow:APPDELEGATE.window modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo: nil];

    [(SharedSecretConfirmationController*)sheetController showChunks:chunks];
}


+ (void)askIfMynigmaShouldBecomeStandardClient
{
    NSString* thisHandler = [BUNDLE bundleIdentifier];

    NSString* URLScheme = @"mailto";
    NSString* defaultHandler = (__bridge NSString *)(LSCopyDefaultHandlerForURLScheme((__bridge CFStringRef)(URLScheme)));

    if(![defaultHandler.lowercaseString isEqualToString:thisHandler.lowercaseString])
    {
        [AlertHelper showTwoOptionDialogueWithTitle:NSLocalizedString(@"Thank you for choosing Mynigma!", nil) message:NSLocalizedString(@"Would you like to use Mynigma as your standard email client?", nil) OKOption:NSLocalizedString(@"Yes, please", nil) cancelOption:NSLocalizedString(@"No, thank you", nil) suppressionIdentifier:@"mynigmaDefaultsStandardClient" callback:^(BOOL OKOptionSelected){

            if(OKOptionSelected)
            {
                LSSetDefaultHandlerForURLScheme((__bridge CFStringRef)(URLScheme), (__bridge CFStringRef)(thisHandler));
            }
        }];
    }
}


#endif


+ (void)showConnectionMode
{
    //    [self loadAndPresentSheetWithNibName:@"DeviceConnectionController"];
}

+ (void)showTrustEstablishmentWithDevice:(MynigmaDevice *)device
{
    //    [self loadSheetWithNibName:@"SharedSecretConfirmationController"];
    //    [(SharedSecretConfirmationController*)self.sheetController setTargetDevice:device];
    //    [self presentSheet];
}


+ (void)showDeviceInfo:(MynigmaDevice*)device
{
    //    if(self.sheetController && [self.sheetController.window isVisible])
    //    {
    //        [self.sheetController.window orderOut:self];
    //    }
    //    self.sheetController = [[DeviceInfoController alloc] initWithWindowNibName:@"DeviceInfoController"];
    //    [NSApp beginSheet:[self.sheetController window] modalForWindow:APPDELEGATE.window modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo: nil];
    //
    //    [(DeviceInfoController*)self.sheetController loadDevice:device];
}



+ (void)showProgress:(NSInteger)progress
{
    [AlertHelper showTrustEstablishmentProgress:progress];
}


+ (void)informUserAboutNewlyDiscoveredDevice:(MynigmaDevice*)device inAccountSetting:(IMAPAccountSetting*)accountSetting
{
    if(!PROCESS_DEVICE_MESSAGES)
        return;
    
    NSString* targetDeviceUUID = device.deviceId;
    
    NSString* titleString = NSLocalizedString(@"New device found", nil);

    NSString* messageString = [NSString stringWithFormat:NSLocalizedString(@"Device %@ is also connected to this account. Would you like to pair with this device? Pairing will allow both devices to access your safe messages.", nil), device.displayName];

    [AlertHelper showTwoOptionDialogueWithTitle:titleString message:messageString OKOption:NSLocalizedString(@"OK", nil) cancelOption:NSLocalizedString(@"Cancel", nil) suppressionIdentifier:@"mynigmaSuppressionDeviceDiscoveryMessage" callback:^(BOOL OKOptionSelected) {

        if(OKOptionSelected)
        {
            [ThreadHelper runAsyncOnMain:^{

                [TrustEstablishmentThread startNewThreadWithTargetDeviceUUID:targetDeviceUUID withCallback:nil];
            }];
        }
    }];
}



@end
