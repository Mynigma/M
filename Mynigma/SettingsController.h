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





#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class AppDelegate, MynigmaPublicKey;


@interface SettingsController : NSWindowController <NSCollectionViewDelegate, NSDraggingSource, NSTableViewDataSource, NSTableViewDelegate, NSTextViewDelegate>
{
    NSArray* publicKeys;
}

@property AppDelegate* appDelegate;

- (IBAction)addButton:(id)sender;
- (IBAction)editButton:(id)sender;
- (IBAction)deleteButton:(id)sender;
- (IBAction)privacySettingsButton:(id)sender;
- (IBAction)closeWindow:(id)sender;

- (IBAction)fetchKeys:(id)sender;

- (IBAction)showAccountSettings:(id)sender;

@property IBOutlet NSTableView* accountsTable;
@property IBOutlet NSTableView* emailAddressesTable;

@property MynigmaPublicKey* selectedKey;

- (IBAction)createAccountDataFile:(id)sender;
- (IBAction)deleteAccountDataFile:(id)sender;

- (IBAction)saveKey:(id)sender;
- (IBAction)restoreKey:(id)sender;

- (IBAction)launchSetupAssistant:(id)sender;

@property IBOutlet NSCollectionView* accountFileView;

@property IBOutlet NSTableView* accountsList;
@property IBOutlet NSTableView* footersList;

@property IBOutlet NSTableView* connectionsTableView;

@property IBOutlet WebView* footerEditView;

- (IBAction)addToFootersList:(id)sender;
- (IBAction)removeFromFootersList:(id)sender;

@property IBOutlet NSButton* removeFromFooterListButton;

@property NSMutableArray* footers;

@property IBOutlet NSButton* editAccountButton;
@property IBOutlet NSButton* addAccountButton;
@property IBOutlet NSButton* deleteAccountButton;

- (IBAction)showDeviceList:(id)sender;

- (IBAction)makeNewDeviceDiscoveryMessage:(id)sender;

@end
