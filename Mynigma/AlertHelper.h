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





#import <Foundation/Foundation.h>

@class MynigmaDevice, IMAPAccountSetting;

@interface AlertHelper : NSObject


#pragma mark - Callbacks

typedef void (^AlertCallbackBlock)(void);
typedef void (^AlertBoolCallbackBlock)(BOOL OKButtonClicked);

@property(nonatomic, strong) AlertCallbackBlock alertCallback;
@property(nonatomic, strong) AlertBoolCallbackBlock alertBoolCallback;

@property(nonatomic, strong) void (^sheetCallback)(NSInteger result);



#pragma mark - SHARED INSTANCE

+ (instancetype)sharedInstance;



#pragma mark - SHOW ALERTS

#if TARGET_OS_IPHONE

+ (void)showAlertWithMessage:(NSString*)message informativeText:(NSString*)informativeText otherButtonTitle:(NSString*)buttonTitle;

+ (void)showAlertWithTitle:(NSString*)title message:(NSString*)message callback:(void(^)(void))callback;

+ (void)showTwoOptionDialogueWithTitle:(NSString*)title message:(NSString*)message OKOption:(NSString*)OKOption cancelOption:(NSString*)cancelOption suppressionIdentifier:(NSString*)suppressionIdentifier fromViewController:(UIViewController*)presentingViewController callback:(void(^)(BOOL OKOptionSelected))callback;


#else

+ (NSInteger)showAlertWithMessage:(NSString*)message informativeText:(NSString*)informativeText otherButtonTitle:(NSString*)buttonTitle;

+ (void)showDialogueWithTitle:(NSString*)title message:(NSString*)message options:(NSArray*)options suppressionIdenitifer:(NSString*)suppressionIdentifier callback:(void(^)(NSInteger indexOfSelectedOption))callback;

#endif

+ (void)showAlertWithMessage:(NSString*)message informativeText:(NSString*)informativeText;

+ (void)showTwoOptionDialogueWithTitle:(NSString*)title message:(NSString*)message OKOption:(NSString*)OKOption cancelOption:(NSString*)cancelOption suppressionIdentifier:(NSString*)suppressionIdentifier callback:(void(^)(BOOL OKOptionSelected))callback;

+ (void)presentError:(NSError*)error;


#pragma mark - SHOW SHEETS

#if TARGET_OS_IPHONE

+ (void)showWelcomeSheet;

#else

//controls the currently visible sheet, if any...
@property NSWindowController* sheetController;

#pragma mark - Show particular sheets (Mac OS)

+ (void)showSettings;
+ (void)showIndividualSettingsWithIMAPAccountSetting:(IMAPAccountSetting*)accountSetting;
+ (void)showAttachmentSheet;
+ (void)showWelcomeSheet;
//+ (void)showMynigmaAccountSettings:(IMAPAccountSetting*)accountSetting;
+ (void)showInvitationSheet;
+ (void)showConnectionMode;
+ (void)showDeviceInfo:(MynigmaDevice*)device;
+ (void)showOAuthSheet:(NSWindowController*)sheetController;


#pragma mark - Sheet callback

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;


#pragma Standard client dialogue

+ (void)askIfMynigmaShouldBecomeStandardClient;

#endif


#pragma mark - Device Connection

+ (void)showDigestChunks:(NSArray*)chunks withTargetDevice:(MynigmaDevice*)device;
+ (void)showTrustEstablishmentWithDevice:(MynigmaDevice*)device;
+ (void)showTrustEstablishmentProgress:(NSInteger)progressIndex;
+ (void)showProgress:(NSInteger)progress;
+ (void)informUserAboutNewlyDiscoveredDevice:(MynigmaDevice*)device inAccountSetting:(IMAPAccountSetting*)accountSetting;





@end
