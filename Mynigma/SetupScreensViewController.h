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


@class DetailedSetupController, ConnectionItem, LinkButton, ErrorLinkButton, TintedImageView;


@interface SetupScreensViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate>


@property DetailedSetupController* detailedSetupController;

@property IBOutlet NSView* accountsListPage;

@property (weak) IBOutlet NSLayoutConstraint *totalWidthConstraint;

@property (weak) IBOutlet NSView* pageView;

@property NSInteger currentPage;

@property (weak) IBOutlet NSLayoutConstraint *showScreenConstraint1;
@property (weak) IBOutlet NSLayoutConstraint *showScreenConstraint2;
@property (weak) IBOutlet NSLayoutConstraint *showScreenConstraint3;
@property (weak) IBOutlet NSLayoutConstraint *showScreenConstraint4;
@property (weak) IBOutlet NSLayoutConstraint *showScreenConstraint5;
@property (weak) IBOutlet NSLayoutConstraint *showScreenConstraint6;
@property (weak) IBOutlet NSLayoutConstraint *showScreenConstraint7;
@property (weak) IBOutlet NSLayoutConstraint *showScreenConstraint8;

@property (weak) IBOutlet NSTextField* privacyInformationText;
@property (weak) IBOutlet NSButton* privacyPolicyLink;

@property (weak) IBOutlet TintedImageView* birdImage;

@property (weak) IBOutlet NSTextField* passwordField;


@property ConnectionItem* itemBeingEdited;

@property (weak) IBOutlet NSBox *feedbackBox;
@property (weak) IBOutlet ErrorLinkButton *feedbackTextField;


- (void)popDetailedSettingsOutOfView;


@property IBOutlet NSView* accountsTableRoundedBox;

- (void)nextScreen;
- (void)previousScreen;


- (BOOL)canGoBack;
- (BOOL)canGoForward;

@property BOOL canGoUp;

@property NSMutableArray* connectionItemList;

@property (weak) IBOutlet NSTableView* accountsListTableView;



@property(weak, nonatomic) IBOutlet NSButton* accountsPlusButton;
@property(weak, nonatomic) IBOutlet NSButton* accountsEditButton;
@property(weak, nonatomic) IBOutlet NSButton* accountsMinusButton;



+ (NSArray*)parsePlistAtURL:(NSURL*)plistURL;


#pragma mark - New style accounts setup

@property (weak) IBOutlet NSButton *OAuthLoginButton;
@property (weak) IBOutlet LinkButton *normalLoginOptionButton;

@property (weak) IBOutlet NSLayoutConstraint *showPasswordLoginConstraint;

@property (weak) IBOutlet NSBox *invalidEmailNoticeBox;
@property (weak) IBOutlet NSView *passwordEntryFrameView;

@property (weak) IBOutlet NSTabView* tabView;

@property (weak) IBOutlet NSProgressIndicator* connectionProgressIndicator;

@end
