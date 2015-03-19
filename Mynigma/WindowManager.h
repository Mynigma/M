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

@class ComposeWindowController, SeparateViewerWindowController, EmailRecipient, EmailMessageInstance, DisplayMessageView, FolderListController, ConnectionItem;

@interface WindowManager : NSObject

+ (instancetype)sharedInstance;

+ (NSMutableSet*)shownWindows;

+ (void)showNewMessageWindowWithRecipient:(EmailRecipient*)emailRecipient;
+ (void)showMessageWindowWithRecipients:(NSArray*)emailRecipients subject:(NSString*)subject body:(NSString*)bodyString;
+ (void)showNewMessageWindow;

+ (ComposeWindowController*)showFreshMessageWindow;
+ (ComposeWindowController*)showInvitationMessageForRecipients:(NSArray*)emailRecipients style:(NSString*)styleString;
+ (ComposeWindowController*)showInvitationMessageForEmailRecipient:(EmailRecipient*)emailRecipient;
+ (SeparateViewerWindowController*)openMessageInstanceInWindow:(EmailMessageInstance*)messageInstance;
+ (ComposeWindowController*)openDraftMessageInstanceInWindow:(EmailMessageInstance*)messageInstance;

+ (void)startSetupAssistant;
+ (void)showComposeFeedbackWindow;
+ (void)showBugReporterWindow;

+ (void)removeWindow:(NSWindowController*)windowToBeReleased;

- (DisplayMessageView*)displayView;

@property FolderListController* foldersController;

@property NSViewController* setupViewController;

+ (void)showOAuthLoginForConnectionItem:(ConnectionItem*)connectionItem withCallback:(void(^)(void))callback;

@end
