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






@class IMAPAccountSetting, IMAPFolderSetting, EmailMessageInstance;

@interface FolderListController : NSViewController <NSTableViewDelegate, NSTableViewDataSource, NSPasteboardItemDataProvider>

//re-populates the list of account & folders/contacts
//then reloads the data
- (void)refreshListOfShownAccountsAndFolders;

//updates the contents of all visible rows (unread count etc.)
- (void)refreshTable;

//loads the entire table afresh without re-populating the objects
- (void)reloadTable;

//the folder selected by the user that contains the message instance
//it's going to be *either* the folder the message is actually in, a label it has (Gmail) or the "All Mail" folder (non-Gmail)
+ (IMAPFolderSetting*)selectedFolderForMessageInstance:(EmailMessageInstance*)messageInstance;

@property BOOL isChangingSelection;

@property IBOutlet NSButton* showFoldersButton;
@property IBOutlet NSButton* showContactsButton;

@property IBOutlet NSBox* foldersBox;
@property IBOutlet NSBox* contactsBox;

@property IBOutlet NSTableView* tableView;


@end

