//Copyright © 2012 - 2015 Roman Priebe
//
//This file is part of M - Safe email made simple.
//
//M is free software: you can redistribute it and/or modify
//it under the terms of the GNU General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.
//
//M is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU General Public License
//along with M.  If not, see <http://www.gnu.org/licenses/>.
//



#ifndef Mynigma_AppDelegate_Mac_h
#define Mynigma_AppDelegate_Mac_h

@class MainSplitViewDelegate, ContainerView;

@interface AppDelegate()

//the search field at the top right of the window
@property IBOutlet NSSearchField* searchField;

//various buttons in the window
@property IBOutlet NSButton* showAllButton;
@property IBOutlet NSButton* showFlaggedButton;
@property IBOutlet NSButton* showUnreadButton;
@property IBOutlet NSButton* showSafeButton;
@property IBOutlet NSButton* showAttachmentsButton;

//manages the list of all messages displayed in the message list (type EmailMessageInstance)
@property IBOutlet NSArrayController* messages;

//manages the list of messages in the local archive (type EmailMessage)
@property IBOutlet NSArrayController* localMessages;

//bound to the title of the main window
@property NSMutableString* mainWindowTitle;


//the main window
@property (assign) IBOutlet NSWindow *window;


@property IBOutlet ContainerView* foldersListContainer;


//the message list table view
@property IBOutlet NSTableView* messagesTable;

@property MessageListController* messageListController;

//@property PullToReloadViewController* reloadViewController;

//the array of messages and attachments that are displayed in the content viewer
@property NSMutableArray* viewerArray;

//the list of contacts displayed on the left hand side (after recent contacts)
@property NSArrayController* contacts;

//the list of recent contacts
@property NSArrayController* recentContacts;

//the split view containing contact/folder outline view, message list table view and the content viewer
@property IBOutlet NSSplitView* mainSplitView;
@property(strong) MainSplitViewDelegate* mainSplitViewDelegate;


//if this is true, the content viewer will not be reloaded when the message selection changes - otherwise reloading all messages (which involves saving the selection, reloading the table and then restoring the selection) would cause a flicker
@property BOOL suppressReloadOfContentViewerOnChangeOfMessageSelection;

@property PLCrashReporter* crashReporter;



@property IBOutlet NSArrayController* contactOutlineController;

@property IBOutlet NSScrollView* messageListScrollView;
@property IBOutlet NSScrollView* accountsListScrollView;

@property IBOutlet ReloadButton* refreshInboxButton;

@property IBOutlet DisplayMessageView* displayView;

// toggles autoload user preference
@property IBOutlet NSMenuItem* autoLoadImages;

@end


@interface AppDelegate(Mac)

//- (IBAction)deleteSelectedMessages:(id)sender;

- (IBAction)findKeyShortcut:(id)sender;

//show folders/contacts button has been clicked
//- (IBAction)showButtonClicked:(id)sender;

//show all/unread/important/... button has been clicked
- (IBAction)buttonPressed:(id)sender;

- (IBAction)showSettings:(id)sender;

- (IBAction)feedbackButton:(id)sender;

- (IBAction)showInvitationSheet:(id)sender;

+ (void)openURL:(NSURL*)url;


@end


#endif
