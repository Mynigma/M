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
#import "AlertHelper.h"
#import "AppDelegate.h"
#import "AppDelegate-Mac.h"
#import "WindowManager.h"
#import "SelectionAndFilterHelper.h"
#import <CrashReporter/CrashReporter.h>
#import "DisplayMessageView.h"
#import "IconListAndColourHelper.h"
#import "MigrationHelper.h"
#import "CustomerManager.h"
#import <CrashReporter/CrashReporter.h>
#import "UserSettings+Category.h"
#import <Sparkle/Sparkle.h>
#import "AccountCheckManager.h"
#import "ReloadingDelegate.h"
#import "ABContactDetail+Category.h"
#import "OutlineObject.h"
#import "EmailMessageController.h"
#import "EmailMessageInstance+Category.h"
#import "MessageTemplate+Category.h"
#import "ComposeWindowController.h"
#import "TrustEstablishmentThread.h"
#import "DeviceMessage+Category.h"
#import "IMAPFolderSetting+Category.h"
#import "IMAPAccountSetting+Category.h"
#import "TrustEstablishmentThread.h"
#import "MynigmaDevice+Category.h"
#import "TemplateNameController.h"
#import "EmailMessage+Category.h"
#import "EmailMessageData.h"
#import "MynigmaMessage+Category.h"
#import "AttachmentsIconView.h"
#import "MainSplitViewDelegate.h"
#import "Recipient.h"
#import "NSString+EmailAddresses.h"
#import "PrintingHelper.h"
#import "NSImage+CustomAdditions.h"
#import "UserNotificationHelper.h"
#import "StartUpHelper.h"
#import <objc/runtime.h>
#import "ReloadButton.h"
#import "ContainerView.h"
#import "FolderListController_MacOS.h"




@implementation AppDelegate(Mac)


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if(NSClassFromString(@"NSVisualEffectView"))
    {
        [WindowManager sharedInstance].foldersController = (FolderListController*)[self.foldersListContainer loadViewControllerOfClass:[FolderListController class] fromXIB:@"FoldersList_VisualEffect"];
        
    }
    else if([NSScrollView instancesRespondToSelector:@selector(addFloatingSubview:forAxis:)])
    {
        //we're on 10.9 (Mavericks)
        [WindowManager sharedInstance].foldersController = (FolderListController*)[self.foldersListContainer loadViewControllerOfClass:[FolderListController class] fromXIB:@"FoldersList"];

    }
    else
    {
        //we're on 10.8 (Mountain Lion)
        [WindowManager sharedInstance].foldersController = (FolderListController*)[self.foldersListContainer loadViewControllerOfClass:[FolderListController class] fromXIB:@"FoldersList_MountainLion"];
    }

    
//    [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"];
//    [self.refreshInboxButton setImage:[NSImage imageNamed:@"nBirdTemplate.gif"]];
    
    // set correct button state
    [self.autoLoadImages setState:[[NSUserDefaults standardUserDefaults] boolForKey:@"doNotLoadImagesAutomatically"]?NSOnState:NSOffState];
    
    //need to respond to wake from sleep by initiating a message check
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(wakeFromSleep:) name:NSWorkspaceDidWakeNotification object:nil];

    //prompt the user to make Mynigma the default client
    [AlertHelper askIfMynigmaShouldBecomeStandardClient];

    //this is used when programmatically changing selection
    //it prevents the message on the right from being reloaded
    self.suppressReloadOfContentViewerOnChangeOfMessageSelection = NO;

    //set the split view delegate
    self.mainSplitViewDelegate = [MainSplitViewDelegate sharedInstance];
    self.mainSplitView.delegate = self.mainSplitViewDelegate;

    //[self.mainSplitView adjustSubviews];

    for(NSButton* button in @[self.showUnreadButton, self.showFlaggedButton, self.showSafeButton, self.showAttachmentsButton])
    {
        [button setState:NSOffState];

        NSImage* image = button.image;

        NSImage* tintedImage = [image imageWithTintColour:[NSColor lightGrayColor]];

        [button setImage:tintedImage];
        [button setAlternateImage:image];

        [button.cell setShowsStateBy:NSPushInCellMask | NSContentsCellMask | 12];
    }


    // Setup Crash Reporter
    self.crashReporter = [PLCrashReporter new];

    //this will send all console output to a file
    //useful for crash reports
    if(REDIRECT_LOG_TO_FILE)
        [self redirectConsoleLogToDocumentFolder];

    //register for user notifications
    //creating the helper is sufficient
    [UserNotificationHelper sharedInstance];

    //sort the contacts list
    [self.contactOutlineController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"sortSection" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"sortDate" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"sortName" ascending:YES]]];

    //let the array controller do the sorting when the content is updated
    [self.contactOutlineController setAutomaticallyRearrangesObjects:YES];

    //display the placeholder in the message viewer section
    [[WindowManager sharedInstance].displayView showMessage:nil];


    [SelectionAndFilterHelper sharedInstance].draggedObjects = [NSSet new];

    [SelectionAndFilterHelper sharedInstance].messageDateFormatter = [[NSDateFormatter alloc] init];
    NSString *longFormatWithoutYear = [NSDateFormatter dateFormatFromTemplate:@"MMM d" options:0 locale:[NSLocale currentLocale]];
    [[SelectionAndFilterHelper sharedInstance].messageDateFormatter setDateFormat:longFormatWithoutYear];
    //[messageDateFormatter setDateStyle:NSDateFormatterShortStyle];
    //[messageDateFormatter setTimeStyle:NSDateFormatterNoStyle];

    [SelectionAndFilterHelper sharedInstance].messageOldDateFormatter = [NSDateFormatter new];
    NSString* longFormatWithYear = [NSDateFormatter dateFormatFromTemplate:@"MMM d yy" options:0 locale:[NSLocale currentLocale]];
    [[SelectionAndFilterHelper sharedInstance].messageOldDateFormatter setDateFormat:longFormatWithYear];


    [[SelectionAndFilterHelper sharedInstance] setShowContacts:NO];

    //progressIndicators = [NSMutableDictionary new];

    [ThreadHelper runAsyncOnMain:^{

        [StartUpHelper performStartupTasks];

        [SelectionAndFilterHelper performSelector:@selector(updateFilters) withObject:nil afterDelay:.5];

        [SelectionAndFilterHelper reloadOutlinePreservingSelection];


        //compares the current version to the version previously run
        //if an update is detected, the migration assistant will perform any necessary changes in data structures, keychain items, etc...
        NSString* lastVersionString = [UserSettings currentUserSettings].lastVersionUsed;
        [MigrationHelper migrateFromVersion:lastVersionString];
    }];

    [APPDELEGATE.messagesTable registerForDraggedTypes: [NSArray arrayWithObjects:DRAGANDDROPLABEL, nil]];

#if ULTIMATE

    [CustomerManager copyPlistIntoApplicationSupportFolder];

    if(!IS_IN_TESTING_MODE)
    {
        //SPARKLE AUTOUPDATE
        SUUpdater* updater = [SUUpdater sharedUpdater];
        [updater setAutomaticallyChecksForUpdates:YES];
        [updater setAutomaticallyDownloadsUpdates:NO];
        [updater setSendsSystemProfile:NO];

        //[updater setDelegate:self];

        if([CustomerManager isExclusiveVersion])
        {
            NSLog(@"Exclusive version!!");

            [updater setFeedURL:[NSURL URLWithString:@"https://mynigma.org/files/updateFeedCandidates.xml"]];
        }

        [updater checkForUpdatesInBackground];
    }

#endif


    //NSURLCACHE
    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:10 * 1024 * 1024
                                                         diskCapacity:50 * 1024 * 1024
                                                             diskPath:nil];
    [NSURLCache setSharedURLCache:URLCache];

    [self.crashReporter enableCrashReporter];


    if ([self.crashReporter hasPendingCrashReport])
    {
        /* Do this in bug reporter controler
         NSError* error = nil;

         PLCrashReport* crashReport = [[PLCrashReport alloc] initWithData:[crashReporter loadPendingCrashReportData] error:&error];
         NSString* crashReportString = [PLCrashReportTextFormatter stringValueForCrashReport:crashReport withTextFormat:PLCrashReporterSymbolicationStrategyAll];

         if (crashReportString)  */
        {

            NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Crash report", @"Crash report title") defaultButton:NSLocalizedString(@"OK", @"OK button") alternateButton:NSLocalizedString(@"No, thanks", @"No thanks button") otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Mynigma crashed when it was opened last time. Please consider sending us a bug report, so that we can fix the issue immediately. Thank you!",@"please send bug report")];

            if([alert respondsToSelector:@selector(beginSheetModalForWindow:completionHandler:)])
            {
                //on 10.9 show a modal sheet
                [alert setAlertStyle:NSWarningAlertStyle];

                [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
                    if(returnCode == NSOKButton)
                        [WindowManager showBugReporterWindow];
                    else
                        [self.crashReporter purgePendingCrashReport];
                }];
            }
            else
            {
                //on 10.8 there is a problem with the bug reporter sheet: it's not attached to anything if the nsalert is shown previously
                //just show the alert in a separate window
                if(alert.runModal == NSOKButton)
                    [WindowManager showBugReporterWindow];
                else
                    [self.crashReporter purgePendingCrashReport];
            }
        }
    }
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    NSLog(@"Opening file: %@",filename);
    return YES;
}


- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
//    if (![NSVisualEffectView class]) {
//        Class NSVisualEffectViewClass = objc_allocateClassPair([NSView class], "NSVisualEffectView", 0);
//        objc_registerClassPair(NSVisualEffectViewClass);
//    }
    
    [self.accountsListScrollView setBackgroundColor:ACCOUNT_SELECTION_COLOUR];
    
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self
                           andSelector:@selector(handleGetURLEvent:withReplyEvent:)
                         forEventClass:kInternetEventClass andEventID:kAEGetURL];

}

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSURL *url = [NSURL URLWithString:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];

    [AppDelegate openURL:url];
}

- (void)wakeFromSleep:(NSNotification*)notification
{
    [AccountCheckManager awakeFromSleep];
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return NO;
}


- (void)applicationWillTerminate:(NSNotification *)notification
{
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.

    if (![[CoreDataHelper sharedInstance] haveInitialisedManagedObjectContext])
    {
        return NSTerminateNow;
    }

    if (![MAIN_CONTEXT commitEditing])
    {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    [self removeDeletedMessagesFromStoreInContext:MAIN_CONTEXT];

    [CoreDataHelper saveAndWait];

    if (![[[CoreDataHelper sharedInstance] storeObjectContext] hasChanges])
    {
        return NSTerminateNow;
    }

    NSError *error = nil;
    if (![[[CoreDataHelper sharedInstance] storeObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel Button");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];

        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

//when the application loses focus, store the main object context to disk, so that no data is lost in case of a crash etc...
- (void)applicationWillResignActive:(NSNotification *)notification
{
    //    [MODEL saveAndWait];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    //    [APPDELEGATE refreshAllMessages];
    //    for(IMAPAccount* account in MODEL.accounts)
    //    {
    //        [account checkAccount];
    //    }
}

- (BOOL)applicationShouldHandleReopen:(NSApplication*)theApplication
hasVisibleWindows:(BOOL)flag
{
    [self.window orderFront:nil];
    [SelectionAndFilterHelper refreshAllMessages];
    [AccountCheckManager appReactivated];
    return TRUE;
}

- (void)application:(NSApplication *)app didDecodeRestorableState:(NSCoder *)coder
{
    [AccountCheckManager appReactivated];
}


// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [MAIN_CONTEXT undoManager];
}

//- (void)applicationDidChangeOcclusionState:(NSNotification *)notification
//{
//    BOOL isVisible = ([NSApp occlusionState] & NSApplicationOcclusionStateVisible) != 0;
//}



//make sure sheets start from bottom of menu bar, not the title bar...
- (NSRect)window:(NSWindow *)window willPositionSheet:(NSWindow *)sheet
usingRect:(NSRect)rect {
    rect.origin.y-=66;
    rect.size.height-=66;
    return rect;
}





+ (void)openURL:(NSURL*)url
{
    NSString* query = [url query];

    //accommodating for apparent bug in NSURL parsing
    if (!query)
    {
        if ([url.absoluteString rangeOfString:@"?"].location != NSNotFound)
        {
            //there seems to be a query....
            query = (NSString*)[[url.absoluteString componentsSeparatedByString:@"?"] lastObject];
        }
    }

    if([[url.scheme lowercaseString] isEqualToString:@"mynigma"])
    {
        NSArray *queryPairs = [query componentsSeparatedByString:@"&"];
        NSMutableDictionary *pairs = [NSMutableDictionary dictionary];
        for (NSString *queryPair in queryPairs) {
            NSArray *bits = [queryPair componentsSeparatedByString:@"="];
            if ([bits count] != 2) { continue; }

            NSString *key = [[bits objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString *value = [[bits objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

            [pairs setObject:value forKey:key];
        }

        NSString* messageID = [pairs objectForKey:@"messageID"];

        if(messageID)
        {
            [SelectionAndFilterHelper highlightMessageWithID:messageID];
        }
    }

    if([[url.scheme lowercaseString] isEqualToString:@"mailto"])
    {
        NSArray *queryPairs = [query componentsSeparatedByString:@"&"];
        NSMutableDictionary *pairs = [NSMutableDictionary dictionary];
        for (NSString *queryPair in queryPairs) {
            NSArray *bits = [queryPair componentsSeparatedByString:@"="];
            if ([bits count] != 2) { continue; }

            NSString *key = [[[bits objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] lowercaseString];
            NSString *value = [[bits objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

            [pairs setObject:value forKey:key];
        }

        NSString* recipients = [url resourceSpecifier];

        NSArray* individualRecipients = [recipients componentsSeparatedByString:@","];

        NSMutableArray* newRecipients = [NSMutableArray new];

        for(NSString* recipientString in individualRecipients)
        {
            Recipient* emailRecipient = [recipientString parseAsRecipient];

            if(emailRecipient)
            {
                [emailRecipient setType:TYPE_TO];

                [newRecipients addObject:emailRecipient];
            }
        }

        NSString* ccString = pairs[@"cc"];

        NSArray* ccRecipients = [ccString componentsSeparatedByString:@","];

        for(NSString* recipientString in ccRecipients)
        {
            Recipient* emailRecipient = [recipientString parseAsRecipient];

            if(emailRecipient)
            {
                [emailRecipient setType:TYPE_CC];

                [newRecipients addObject:emailRecipient];
            }
        }

        NSString* bccString = pairs[@"bcc"];

        NSArray* bccRecipients = [bccString componentsSeparatedByString:@","];

        for(NSString* recipientString in bccRecipients)
        {
            Recipient* emailRecipient = [recipientString parseAsRecipient];

            if(emailRecipient)
            {
                [emailRecipient setType:TYPE_BCC];

                [newRecipients addObject:emailRecipient];
            }
        }

        NSString* subjectString = [pairs[@"subject"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSString* bodyString = [pairs[@"body"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [WindowManager showMessageWindowWithRecipients:newRecipients subject:subjectString body:bodyString];
    }
}





#pragma mark - IBAction methods


- (IBAction)refreshInbox:(id)sender
{
    [ReloadingDelegate startNewLoad];
}

- (IBAction)importFromAddressBook:(id)sender
{
    [ABContactDetail loadAdditionalContactsFromAddressbook];
}

- (IBAction)showAboutPanel:(id)sender
{
    NSString* shortVersionString = @"";

#if ULTIMATE

    shortVersionString = [CustomerManager customerString];

#endif

    if(!shortVersionString)
        shortVersionString = @"";

        [[NSApplication sharedApplication] orderFrontStandardAboutPanelWithOptions:@{@"Version":shortVersionString}];
}


- (IBAction)reopenTheMainWindow:(id)sender
{
    [self.window makeKeyAndOrderFront:self];
    //[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}


//one of the "show type" switch buttons has been pressed ("All", "Important", etc.)
- (IBAction)buttonPressed:(id)sender
{
    //filter the message list with this show type switch
    [SelectionAndFilterHelper updateFilters];

    //selected messages should be deselected, since indexes will change through the update of filters
    if([self.messagesTable selectedRowIndexes].count>0)
        [self.messagesTable deselectAll:self];
    //[messagesTable reloadData];
}

- (IBAction)showSettings:(id)sender
{
    [AlertHelper showSettings];
}

- (IBAction)feedbackButton:(id)sender
{
    [WindowManager showComposeFeedbackWindow];
}

- (IBAction)showInvitationSheet:(id)sender
{
    [AlertHelper showInvitationSheet];
}

- (IBAction)newMessage:(id)sender
{
    [WindowManager showNewMessageWindow];
}

- (IBAction)printDocument:(id)sender
{
    [PrintingHelper printDocument];
}

#pragma mark - BUTTONS & MENU ITEMS


/**CALL ON MAIN*/
- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    [ThreadHelper ensureMainThread];

    NSArray* selectedMessages = [EmailMessageController selectedMessages];
    if ([item action] == @selector(markSelectedMessagesAsFlagged:))
    {
        if(selectedMessages.count==0)
            return NO;

        BOOL allOn = YES;
        for(NSManagedObject* messageObject in selectedMessages)
        {
            if([messageObject isKindOfClass:[EmailMessageInstance class]])
                if(![(EmailMessageInstance*)messageObject isFlagged])
                    allOn = NO;
        }
        if(allOn)
            [item setTitle:NSLocalizedString(@"Unflagged",@"MenuItem Unflagged")];
        else
            [item setTitle:NSLocalizedString(@"Flagged",@"MenuItem Flagged")];
        return YES;
    }
    if ([item action] == @selector(markSelectedMessagesAsRead:))
    {
        if(selectedMessages.count==0)
            return NO;
        BOOL allOn = YES;
        for(NSManagedObject* messageObject in selectedMessages)
        {
            if([messageObject isKindOfClass:[EmailMessageInstance class]])
                if([(EmailMessageInstance*)messageObject isUnread])
                    allOn = NO;
        }
        if(allOn)
            [item setTitle:NSLocalizedString(@"Unread",@"MenuItem Unread")];
        else
            [item setTitle:NSLocalizedString(@"Read",@"MenuItem Read")];
        return YES;
    }
    if ([item action] == @selector(markSelectedMessagesAsImportant:))
    {
        if(selectedMessages.count==0)
            return NO;
        BOOL allOn = YES;
        for(NSManagedObject* messageObject in selectedMessages)
        {
            if([messageObject isKindOfClass:[EmailMessageInstance class]])
                if(![(EmailMessageInstance*)messageObject isImportant])
                    allOn = NO;
        }
        if(allOn)
            [item setTitle:NSLocalizedString(@"Not Important",@"MenuItem Not Important")];
        else
            [item setTitle:NSLocalizedString(@"Important",@"MenuItem Important")];
        return YES;
    }
    if ([item action] == @selector(markSelectedMessagesAsSpam:))
    {
        if(selectedMessages.count==0)
            return NO;
        BOOL allOn = YES;
        for(NSManagedObject* messageObject in selectedMessages)
        {
            if([messageObject isKindOfClass:[EmailMessageInstance class]])
                if(![(EmailMessageInstance*)messageObject isInSpamFolder])
                    allOn = NO;
        }
        if(allOn)
            [item setTitle:NSLocalizedString(@"Not Spam",@"MenuItem Not Spam")];
        else
            [item setTitle:NSLocalizedString(@"Spam",@"MenuItem Spam")];
        return YES;
    }
    if ([item action] == @selector(deleteSelectedMessages:))
    {
        if(selectedMessages.count==0)
            return NO;
        BOOL allOn = YES;
        for(NSManagedObject* messageObject in selectedMessages)
        {
            if([messageObject isKindOfClass:[EmailMessageInstance class]])
                if(![(EmailMessageInstance*)messageObject isInBinFolder])
                    allOn = NO;
        }
        if(allOn)
            [item setTitle:NSLocalizedString(@"Undelete",@"MenuItem Undelete")];
        else
            [item setTitle:NSLocalizedString(@"Delete",@"Delete Button")];
        return YES;
    }
    if ([item action] == @selector(replyMenuItem:))
    {
        return selectedMessages.count==1;
    }
    if ([item action] == @selector(replyAllMenuItem:))
    {
        return selectedMessages.count==1;
    }
    if ([item action] == @selector(forwardMenuItem:))
    {
        return selectedMessages.count==1;
    }
    if([item action] == @selector(reopenTheMainWindow:))
    {
        return ![self.window isMainWindow];
    }
    if([item action] == @selector(refetchSelectedMessage:))
    {
        return [SelectionAndFilterHelper canRefetchSelectedMessage];
    }



    if([item action] == @selector(saveDraftAsTemplate:))
    {
        return [[NSApp mainWindow].delegate isKindOfClass:[ComposeWindowController class]];
    }
    if([item action] == @selector(newMessageFromTemplate:))
    {
        return [MessageTemplate haveTemplates];
    }
    if([item action] == @selector(replaceWithTemplate:))
    {
        return [MessageTemplate haveTemplates] && [[NSApp mainWindow].delegate isKindOfClass:[ComposeWindowController class]];
    }
    if([item action] == @selector(removeTemplate:))
    {
        return [MessageTemplate haveTemplates];
    }
    if([item action] == @selector(replyWithTemplate:))
    {
        return [MessageTemplate haveTemplates] && selectedMessages.count==1;
    }
    if([item action] == @selector(replyAllWithTemplate:))
    {
        return [MessageTemplate haveTemplates] && selectedMessages.count==1;
    }
    if([item action] == @selector(forwardWithTemplate:))
    {
        return [MessageTemplate haveTemplates] && selectedMessages.count==1;
    }

    return YES;
}

- (IBAction)pairWithThisDevice:(NSMenuItem*)sender
{
    MynigmaDevice* device = (MynigmaDevice*)[sender representedObject];
    
    NSString* deviceUUID = device.deviceId;

    [TrustEstablishmentThread startNewThreadWithTargetDeviceUUID:deviceUUID withCallback:^(NSString* newThreadID)
     {
         [sender setTitle:NSLocalizedString(@"Connecting...", @"Menu item feedback")];
         [sender setEnabled:NO];
     }];
}

- (void)menuNeedsUpdate:(NSMenu*)menu
{
    if([menu.supermenu isEqual:[[NSApplication sharedApplication] mainMenu]])
    {
        //it's the "Devices" menu item
        NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MynigmaDevice"];

        NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES];

        [fetchRequest setSortDescriptors:@[sortDescriptor]];

        NSError* error = nil;

        NSArray* allDevices = [MAIN_CONTEXT executeFetchRequest:fetchRequest error:&error];

        if(error)
            return;

        //remove all items except the first two
        while(menu.numberOfItems > 2)
            [menu removeItemAtIndex:2];

        for(MynigmaDevice* device in allDevices)
        {
            NSMenuItem* newMenuItem = [[NSMenuItem alloc] initWithTitle:device.displayName?device.displayName:@"" action:nil keyEquivalent:@""];
            [menu addItem:newMenuItem];

            NSMenu* newMenu = [[NSMenu alloc] initWithTitle:@"Device details"];

            [newMenuItem setSubmenu:newMenu];

            NSMenuItem* pairMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Pair with this device", "Devices menu item") action:@selector(pairWithThisDevice:) keyEquivalent:@""];

            [pairMenuItem setRepresentedObject:device];

            [newMenu addItem:pairMenuItem];
        }

        return;
    }


    NSArray* items = menu.itemArray;
    SEL menuItemAction = nil;

    if(items.count>0)
    {
        menuItemAction = [(NSMenuItem*)items[0] action];
    }

    if(!menuItemAction)
    {
        NSLog(@"No menu item selector!! Menu: %@", menu);
    }

    [menu removeAllItems];

    NSArray* allTemplates = [MessageTemplate listAllTemplates];

    if(allTemplates.count==0)
    {
        NSString* title = NSLocalizedString(@"No templates saved", @"Menu item");
        NSMenuItem* emptyMenuPlaceholder = [[NSMenuItem alloc] initWithTitle:title action:menuItemAction keyEquivalent:@""];
        [menu addItem:emptyMenuPlaceholder];
        return;
    }

    for(MessageTemplate* messageTemplate in allTemplates)
    {
        NSMenuItem* menuItem = [[NSMenuItem alloc] initWithTitle:messageTemplate.displayName action:menuItemAction keyEquivalent:@""];
        [menuItem setRepresentedObject:messageTemplate];
        [menu addItem:menuItem];
    }
}

/**CALL ON MAIN*/
- (IBAction)markSelectedMessagesAsRead:(id)sender
{
    [SelectionAndFilterHelper markSelectedMessagesAsRead];
}

/**CALL ON MAIN*/
- (IBAction)markSelectedMessagesAsFlagged:(id)sender
{
    [SelectionAndFilterHelper markSelectedMessagesAsFlagged];
}


- (IBAction)emptyTrash:(id)sender
{
    [ThreadHelper ensureMainThread];

    NSAlert* alertView = [NSAlert alertWithMessageText:NSLocalizedString(@"Please confirm", @"Seeking confirmation alert message") defaultButton:NSLocalizedString(@"OK", @"OK button") alternateButton:NSLocalizedString(@"Cancel", @"Cancel Button") otherButton:nil informativeTextWithFormat:NSLocalizedString(@"All messages in the trash folder of each selected account will be deleted. This action cannot be undone.", @"Message batch deletion confirmation")];

    if(alertView.runModal != NSAlertDefaultReturn)
    {
        //don't do anything unless the user confirms
        return;
    }

    NSSet* selectedAccounts = [[SelectionAndFilterHelper sharedInstance].topSelection accountSettings];

    for(IMAPAccountSetting* accountSetting in selectedAccounts)
    {
        [accountSetting emptyTrash];
    }
}



/**CALL ON MAIN*/
- (IBAction)replyMenuItem:(id)sender
{
    [ThreadHelper ensureMainThread];

    NSArray* selectedMessages = [EmailMessageController selectedMessages];
    if(selectedMessages.count==1)
    {
        NSManagedObject* messageObject = [selectedMessages objectAtIndex:0];
        if([messageObject isKindOfClass:[EmailMessageInstance class]])
        {
            ComposeWindowController* composeController = [WindowManager showFreshMessageWindow];
            [composeController setFieldsForReplyToMessageInstance:(EmailMessageInstance*)messageObject];
            [composeController.window makeFirstResponder:composeController.bodyField];
            [composeController.bodyField selectSentence:self];
        }
        else if([messageObject isKindOfClass:[EmailMessage class]])
        {
            ComposeWindowController* composeController = [WindowManager showFreshMessageWindow];
            [composeController setFieldsForReplyToMessage:(EmailMessage*)messageObject];
            [composeController.window makeFirstResponder:composeController.bodyField];
            [composeController.bodyField selectSentence:self];
        }
    }
}

/**CALL ON MAIN*/
- (IBAction)replyAllMenuItem:(id)sender
{
    [ThreadHelper ensureMainThread];

    NSArray* selectedMessages = [EmailMessageController selectedMessages];
    if(selectedMessages.count==1)
    {
        NSManagedObject* messageObject = [selectedMessages objectAtIndex:0];
        if([messageObject isKindOfClass:[EmailMessageInstance class]])
        {
            ComposeWindowController* composeController = [WindowManager showFreshMessageWindow];
            [composeController setFieldsForReplyAllToMessageInstance:(EmailMessageInstance*)messageObject];
            [composeController.window makeFirstResponder:composeController.bodyField];
            [composeController.bodyField selectSentence:self];
        }
        else if([messageObject isKindOfClass:[EmailMessage class]])
        {
            ComposeWindowController* composeController = [WindowManager showFreshMessageWindow];
            [composeController setFieldsForReplyAllToMessage:(EmailMessage*)messageObject];
            [composeController.window makeFirstResponder:composeController.bodyField];
            [composeController.bodyField selectSentence:self];
        }
    }
}

/**CALL ON MAIN*/
- (IBAction)forwardMenuItem:(id)sender
{
    [ThreadHelper ensureMainThread];

    NSArray* selectedMessages = [EmailMessageController selectedMessages];
    if(selectedMessages.count==1)
    {
        NSManagedObject* messageObject = [selectedMessages objectAtIndex:0];
        if([messageObject isKindOfClass:[EmailMessageInstance class]])
        {
            ComposeWindowController* composeController = [WindowManager showFreshMessageWindow];
            [composeController setFieldsForForwardOfMessageInstance:(EmailMessageInstance*)messageObject];
        }
        else if([messageObject isKindOfClass:[EmailMessage class]])
        {
            ComposeWindowController* composeController = [WindowManager showFreshMessageWindow];
            [composeController setFieldsForForwardOfMessage:(EmailMessage*)messageObject];
        }
    }
}


- (IBAction)findKeyShortcut:(id)sender
{
    [self.searchField becomeFirstResponder];
}

- (IBAction)refetchSelectedMessage:(id)sender
{
    [SelectionAndFilterHelper refetchSelectedMessage];
}

- (IBAction)toggleLoadImagesAutomatically:(id)sender
{
    BOOL doNOTautoload = [[NSUserDefaults standardUserDefaults] boolForKey:@"doNotLoadImagesAutomatically"];
    NSMenuItem* item = (NSMenuItem*) sender;

    if (doNOTautoload)
    {
        // enable autoload
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"doNotLoadImagesAutomatically"];
        [item setState:NSOffState];
    }
    else
    {
        // disable autoload
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"doNotLoadImagesAutomatically"];
        [item setState:NSOnState];
    }
}


#pragma mark - Search bar

//search field text changed
- (void)controlTextDidChange:(NSNotification *)obj
{
    //reload the list of messages, filtering by the new search string
    [SelectionAndFilterHelper updateFilters];

    //the contact outline needs to be reloaded, because it is also filtered by the search string
    [SelectionAndFilterHelper reloadOutlinePreservingSelection];

    //remove selection from message list, if any (otherwise selected messages would have to be filtered out, which would be confusing...)
    if([APPDELEGATE.messagesTable selectedRowIndexes].count>0)
        [APPDELEGATE.messagesTable deselectAll:self];
}


#pragma mark - TEMPLATES

- (IBAction)saveDraftAsTemplate:(id)sender
{
    ComposeWindowController* composeController = (ComposeWindowController*)[NSApp mainWindow].delegate;

    if([composeController isKindOfClass:[ComposeWindowController class]])
        if(!composeController.templateNameController.window.isVisible)
        {
            TemplateNameController* newTemplateNameController = [[TemplateNameController alloc] initWithWindowNibName:@"TemplateNameController"];

            [newTemplateNameController setSubject:composeController.subjectField.stringValue];

            [newTemplateNameController setHTMLBody:[(DOMHTMLElement *)[[[composeController.bodyField mainFrame] DOMDocument] documentElement] outerHTML]];

            [newTemplateNameController setRecipients:[composeController recipients]];

            [newTemplateNameController setAllAttachments:composeController.attachmentsView.allAttachments];


            [NSApp beginSheet:[newTemplateNameController window] modalForWindow:composeController.window modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];

            [composeController setTemplateNameController:newTemplateNameController];
        }
}

- (IBAction)removeTemplate:(id)sender
{
    MessageTemplate* messageTemplate = [(NSMenuItem*)sender representedObject];

    [MessageTemplate removeTemplate:messageTemplate];
}

- (IBAction)newMessageFromTemplate:(id)sender
{
    MessageTemplate* messageTemplate = [(NSMenuItem*)sender representedObject];

    ComposeWindowController* composeController = [WindowManager showFreshMessageWindow];

    [composeController fillWithTemplate:messageTemplate];
}

- (IBAction)replaceWithTemplate:(id)sender
{
    MessageTemplate* messageTemplate = [(NSMenuItem*)sender representedObject];

    ComposeWindowController* composeController = (ComposeWindowController*)[NSApp mainWindow].delegate;

    if([composeController isKindOfClass:[ComposeWindowController class]])
    {
        [composeController fillWithTemplate:messageTemplate];
    }
}

- (IBAction)replyWithTemplate:(id)sender
{
    MessageTemplate* messageTemplate = [(NSMenuItem*)sender representedObject];

    NSArray* selectedMessages = [EmailMessageController selectedMessages];
    if(selectedMessages.count==1)
    {
        EmailMessageInstance* messageInstance = [selectedMessages objectAtIndex:0];

        if([messageInstance isKindOfClass:[EmailMessageInstance class]])
        {
            ComposeWindowController* composeController = [WindowManager showFreshMessageWindow];
            [composeController setFieldsForReplyToMessageInstance:messageInstance];

            [composeController fillWithTemplate:messageTemplate];

            [composeController.window makeFirstResponder:composeController.bodyField];
            [composeController.bodyField selectSentence:self];
        }
        else if([messageInstance isKindOfClass:[EmailMessage class]])
        {
            ComposeWindowController* composeController = [WindowManager showFreshMessageWindow];
            [composeController setFieldsForReplyToMessage:(EmailMessage*)messageInstance];

            [composeController fillWithTemplate:messageTemplate];

            [composeController.window makeFirstResponder:composeController.bodyField];
            [composeController.bodyField selectSentence:self];
        }
    }
}

- (IBAction)replyAllWithTemplate:(id)sender
{
    MessageTemplate* messageTemplate = [(NSMenuItem*)sender representedObject];

    NSArray* selectedMessages = [EmailMessageController selectedMessages];
    if(selectedMessages.count==1)
    {
        EmailMessageInstance* messageInstance = [selectedMessages objectAtIndex:0];
        if([messageInstance isKindOfClass:[EmailMessageInstance class]])
        {
            ComposeWindowController* composeController = [WindowManager showFreshMessageWindow];

            [composeController setFieldsForReplyAllToMessageInstance:messageInstance];
            [composeController fillWithTemplate:messageTemplate];

            [composeController.window makeFirstResponder:composeController.bodyField];
            [composeController.bodyField selectSentence:self];
        }
        else if([messageInstance isKindOfClass:[EmailMessage class]])
        {
            ComposeWindowController* composeController = [WindowManager showFreshMessageWindow];
            [composeController setFieldsForReplyAllToMessage:(EmailMessage*)messageInstance];

            [composeController fillWithTemplate:messageTemplate];

            [composeController.window makeFirstResponder:composeController.bodyField];
            [composeController.bodyField selectSentence:self];
        }
    }
}

- (IBAction)forwardWithTemplate:(id)sender
{
    MessageTemplate* messageTemplate = [(NSMenuItem*)sender representedObject];

    NSArray* selectedMessages = [EmailMessageController selectedMessages];
    if(selectedMessages.count==1)
    {
        EmailMessageInstance* messageInstance = [selectedMessages objectAtIndex:0];
        if([messageInstance isKindOfClass:[EmailMessageInstance class]])
        {
            ComposeWindowController* composeController = [WindowManager showFreshMessageWindow];

            [composeController setFieldsForForwardOfMessageInstance:messageInstance];

            [composeController fillWithTemplate:messageTemplate];
            [composeController.window makeFirstResponder:composeController.toField];
        }
        else if([messageInstance isKindOfClass:[EmailMessage class]])
        {
            ComposeWindowController* composeController = [WindowManager showFreshMessageWindow];
            [composeController setFieldsForForwardOfMessage:(EmailMessage*)messageInstance];

            [composeController fillWithTemplate:messageTemplate];

            [composeController.window makeFirstResponder:composeController.bodyField];
            [composeController.bodyField selectSentence:self];
        }
    }
}




@end