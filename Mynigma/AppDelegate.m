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





#import <Security/Security.h>
#import "ThreadHelper.h"

#if TARGET_OS_IPHONE

#import "FolderListController_iOS.h"
#import "SharedSecretTrustController.h"
#import "SplitViewController.h"
#import "ContactSuggestions.h"

#import "DataWrapHelper.h"
#import "DisplayMessageController.h"
#import "WelcomeScreenController.h"
#import "MessagesController.h"
#import "MessageCell.h"
#import "AttachmentsDetailListController.h"
#import "MynigmaURLCache.h"

#else

#import <QuartzCore/QuartzCore.h>
#import "MessagesTable.h"
#import "FolderListController_MacOS.h"

#import <AddressBook/ABPersonView.h>
#import "MessageListController.h"
#import "SettingsController.h"
#import "IncomingSettingsController.h"
#import "OutgoingSettingsController.h"
#import "AttachmentAdditionController.h"
#import "ComposeWindowController.h"
#import "BugReporterController.h"
#import "SeparateViewerWindowController.h"
#import "MessageCellView.h"
#import "AccountView.h"
#import "FolderView.h"
#import "NSAlert+AlertWithBlocks.h"
#import "AdvancedAccountSetupController.h"
#import <CrashReporter/CrashReporter.h>
#import "PullToReloadViewController.h"
#import "DeviceConnectionController.h"
#import "DeviceInfoController.h"
#import "TemplateNameController.h"
#import "InvitationWindowController.h"
#import "SharedSecretConfirmationController.h"
#import "DisplayMessageView.h"
#import "ReloadButton.h"
#import "AttachmentsIconView.h"
#import "WindowManager.h"

#endif

#import "EmailMessageController.h"
#import "AppDelegate.h"
#import "GmailLabelSetting.h"
#import "Contact+Category.h"
#import "EmailContactDetail+Category.h"
#import "IMAPAccountSetting+Category.h"
#import "MynigmaMessage+Category.h"
#import "IMAPAccount.h"
#import "EncryptionHelper.h"
#import "UserSettings.h"
#import "MynigmaPublicKey+Category.h"
#import "KeychainHelper.h"
#import "EmailMessage+Category.h"
#import "FileAttachment+Category.h"
#import "FolderInfoObject.h"
#import "OutlineObject.h"
#import "EmailMessageData.h"
#import "IconListAndColourHelper.h"
#import "EmailMessageInstance+Category.h"
#import "MigrationHelper.h"
#import "OutlineObject.h"
#import "ReloadingDelegate.h"
#import "MessageTemplate+Category.h"
#import "AddressDataHelper.h"
#import "Recipient.h"
#import "AccountCheckManager.h"
#import "ABContactDetail+Category.h"
#import "ThreadHelper.h"
#import "NSString+EmailAddresses.h"
#import "MynigmaDevice+Category.h"
#import "TrustEstablishmentThread.h"
#import "AlertHelper.h"
#import "PrintingHelper.h"
#import "SelectionAndFilterHelper.h"


#if ULTIMATE

#import "CustomerManager.h"
#import <Sparkle/SUUpdater.h>

#endif


#define VERBOSE NO


#pragma mark - COMMON

@implementation AppDelegate




#pragma mark - Directories

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "mynigma.Mynigma" in the user's Application Support directory.
+ (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"Mynigma.Mynigma"];
}

+ (NSString*)applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}



#pragma mark - Redirecting log output

- (void)redirectConsoleLogToDocumentFolder
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

    NSString *logPath = [[documentsDirectory stringByExpandingTildeInPath] stringByAppendingPathComponent:@"console.log"];

#if TARGET_OS_IPHONE

    freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding],"w+",stderr);

#else

    if([self.crashReporter hasPendingCrashReport])
    {
        freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
    }
    else
        freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding],"w+",stderr);
    
#endif
    
}


#pragma mark - Moving selected messages

/**CALL ON MAIN*/
- (IBAction)deleteSelectedMessages:(id)sender
{
    [SelectionAndFilterHelper deleteSelectedMessages];
}

/**CALL ON MAIN*/
- (IBAction)markSelectedMessagesAsSpam:(id)sender
{
    [SelectionAndFilterHelper markSelectedMessagesAsSpam];
}


#pragma mark - "Garbage collection" of deleted messages

//to avoid having to download messages several times when they are moved on the server,
//only instances are deleted and the messages themselves are kept in normal operation
//this method will collect messages without instances and delete them
//run when the program is closed and (optionally) at regular intervals
- (void)removeDeletedMessagesFromStoreInContext:(NSManagedObjectContext*)localContext
{
    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"EmailMessage"];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"instances.@count == 0"];
    
    [fetchRequest setPredicate:predicate];
    
    NSArray* result = [localContext executeFetchRequest:fetchRequest error:nil];
    
    for(EmailMessage* emailMessage in result)
    {
        [emailMessage removeFromStoreInContext:localContext];
    }
}

- (void)removeDeletedMessagesFromStoreWithCallback:(void(^)(void))callback
{
    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {
        
        [self removeDeletedMessagesFromStoreInContext:localContext];
        
        [localContext save:nil];
        
        [CoreDataHelper saveWithCallback:^{
            
            if(callback)
                callback();
        }];
    }];
}


@end