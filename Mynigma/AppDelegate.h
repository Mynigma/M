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






#import "CommonHeader.h"


@class Model, MessagesController,  ComposeNewController, FolderListController, EmailMessage, OutlineObject, IMAPFolderSetting, EmailMessageController, EmailMessageInstance, FolderInfoObject, IMAPAccount, FileAttachment, MessageListController, MynigmaDevice, EmailRecipient;


#if TARGET_OS_IPHONE

@class RootController, ContactSuggestions, SASlideMenuRootViewController, EmailMessageController, DisplayMessageController, Contact, AttachmentsDetailListController, SplitViewDelegate;


@interface AppDelegate : UIResponder <UIApplicationDelegate, NSFetchedResultsControllerDelegate, UIAlertViewDelegate>

#else


@class Message, WelcomeController, IMAPAccountSetting, ComposeWindowController, SeparateViewerWindowController, PLCrashReporter, PullToReloadViewController, DisplayMessageView, ReloadButton;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTextFieldDelegate>

#endif


//the unique Model object - usually accessed through the MODEL macro (which uses this pointer)
@property Model* model;


#if TARGET_OS_IPHONE

@property (strong, nonatomic) UIWindow *window;

#endif



+ (NSString*)applicationDocumentsDirectory;


+ (NSURL *)applicationFilesDirectory;


- (void)redirectConsoleLogToDocumentFolder;




- (IBAction)deleteSelectedMessages:(id)sender;
- (IBAction)markSelectedMessagesAsSpam:(id)sender;

- (void)removeDeletedMessagesFromStoreInContext:(NSManagedObjectContext*)localContext;
- (void)removeDeletedMessagesFromStoreWithCallback:(void(^)(void))callback;


@end

#if TARGET_OS_IPHONE

#import "Appdelegate-iOS.h"

#else

#import "AppDelegate-Mac.h"

#endif