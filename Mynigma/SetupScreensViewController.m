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

#import "SetupScreensViewController.h"

#import "AppDelegate.h"
#import "ConnectionItem.h"
#import "IMAPAccountSetting+Category.h"
#import "KeychainHelper.h"
#import <MailCore/MailCore.h>
#import <QuartzCore/QuartzCore.h>
#import "DetailedSetupController.h"
#import "AccountCreationManager.h"
#import "NSString+EmailAddresses.h"
#import "ConnectionItemCellView.h"
#import "AlertHelper.h"
#import "LinkButton.h"
#import "SetupScreensView.h"
#import "TintedImageView_Mac.h"
#import "IconListAndColourHelper.h"
#import "WindowManager.h"
#import "ErrorLinkButton.h"
#import "GTMOAuth2Authentication.h"
#import "GTMOAuth2WindowController.h"





@interface SetupScreensViewController ()

@end

@implementation SetupScreensViewController

#pragma mark - Initialisation and initial loading

- (void)awakeFromNib
{
#if ULTIMATE
    // Set "we collect no data" to invisible
    [self.privacyInformationText setHidden:YES];
#else
    // Set "we collect no data" to visible
    [self.privacyInformationText setHidden:NO];
#endif
    self.canGoUp = NO;
    //    self.makeLastEmailTextFieldFirstResponder = NO;
    
    [self.birdImage setTintColor:NAVBAR_COLOUR];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controlTextDidChange:)  name:NSControlTextDidChangeNotification object:self.passwordField];
    
    [self updateDetailView];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



- (void)loadAccounts
{
    //don't check the keychain more than once
    if(self.connectionItemList)
        return;
    
    self.connectionItemList = [NSMutableArray new];
    
    //first show the accounts already set up
    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext){
        
        for(IMAPAccount* account in [AccountCreationManager sharedInstance].allAccounts)
        {
            IMAPAccountSetting* accountSetting = [IMAPAccountSetting accountSettingForAccount:account inContext:localContext];
            ConnectionItem* connectionItem = [[ConnectionItem alloc] initWithAccountSetting:accountSetting];
            
            ConnectionItem* __weak weakConnectionItem = connectionItem;
            
            //the persistent refs ought to be set, so use them to extract the actual passwords
            [connectionItem pullPasswordFromKeychainWithCallback:^{
                
                [self addOrUpdateConnectionItem:weakConnectionItem];
            }];
        }
        
        NSArray* localKeychainItems = [KeychainHelper listLocalKeychainItems];
        
        for(ConnectionItem* connectionItem in localKeychainItems)
        {
            ConnectionItem* __weak weakConnectionItem = connectionItem;
            
            //the persistent refs have been found in the keychain, so use them to extract the actual passwords
            [connectionItem pullPasswordFromKeychainWithCallback:^{
                
                [self addOrUpdateConnectionItem:weakConnectionItem];
            }];
        }
    }];
}








#pragma mark - Page navigation

- (BOOL)canGoBack
{
    NSString* nextLayoutConstraintName = [NSString stringWithFormat:@"showScreenConstraint%ld", (long)self.currentPage-1];
    
    NSLayoutConstraint* nextConstraint = [self valueForKey:nextLayoutConstraintName];
    
    return nextConstraint!=nil;
}


- (BOOL)canGoForward
{
    NSString* nextLayoutConstraintName = [NSString stringWithFormat:@"showScreenConstraint%ld", (long)self.currentPage+1];
    
    NSLayoutConstraint* nextConstraint = [self valueForKey:nextLayoutConstraintName];
    
    return nextConstraint!=nil;
}


- (void)nextScreen
{
    if(self.currentPage == 5)
    {
        [self openSettingsFile];
    }
    else if(self.currentPage == 6)
    {
        //move on from the accounts list
        
        //warn the user if there are accounts that have been selected for use, but can't connect
        BOOL shouldWarnUser = NO;
        
        for(ConnectionItem* connectionItem in self.connectionItemList)
        {
            if(/*connectionItem.shouldUseForImport &&*/ !connectionItem.isSuccessfullyImported)
            {
                shouldWarnUser = YES;
            }
        }
        
        if(shouldWarnUser)
        {
            NSInteger returnValue = [AlertHelper showAlertWithMessage:NSLocalizedString(@"Some of the accounts you have selected cannot connect to the provider. The settings may not be correct.", @"Setup screens") informativeText:NSLocalizedString(@"Are you sure you want to proceed?", @"Setup screens") otherButtonTitle:NSLocalizedString(@"Cancel", @"Cancel Button")];
            
            if(returnValue == NSOKButton)
            {
                [self moveToPage:self.currentPage+1];
                [self setUpAccountsFromConnectionItemList];
            }
        }
        else
        {
            [self moveToPage:self.currentPage+1];
            [self setUpAccountsFromConnectionItemList];
        }
        
    }
    else
        [self moveToPage:self.currentPage+1];
}

- (void)previousScreen
{
    if([self canGoUp])
    {
        [self popDetailedSettingsOutOfView];
        return;
    }
    
    [self moveToPage:self.currentPage-1];
}


- (void)moveToPage:(NSInteger)newPage
{
    NSString* previousLayoutConstraintName = [NSString stringWithFormat:@"showScreenConstraint%ld", (long)self.currentPage];
    NSString* nextLayoutConstraintName = [NSString stringWithFormat:@"showScreenConstraint%ld", (long)newPage];
    
    NSLayoutConstraint* previousConstraint = [self valueForKey:previousLayoutConstraintName];
    NSLayoutConstraint* nextConstraint = [self valueForKey:nextLayoutConstraintName];
    
    if(previousConstraint && nextConstraint)
    {
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:1];
        [previousConstraint.animator setPriority:1];
        [nextConstraint.animator setPriority:999];
        [[NSAnimationContext currentContext] setAllowsImplicitAnimation:YES];
        [self.view setNeedsLayout:YES];
        [self.view layoutSubtreeIfNeeded];
        [NSAnimationContext endGrouping];
        
        self.currentPage = newPage;
        
        if(newPage == 6)
        {
            [self loadAccounts];
        }
    }
}

- (IBAction)skipButtonClicked:(id)sender
{
    [self moveToPage:5];
    
    NSView* setupView = self.view.superview.superview;
    
    if([setupView respondsToSelector:@selector(setCorrectButtonTitles)])
        [setupView performSelector:@selector(setCorrectButtonTitles)];
}

- (IBAction)skipPlistSelection:(id)sender
{
    [self moveToPage:6];
}


#pragma mark - Detailed settings navigation

- (void)pushDetailedSettingsIntoViewForCollectionItem:(ConnectionItem*)item
{
    if(!self.detailedSetupController)
    {
        self.detailedSetupController = [[DetailedSetupController alloc] initWithNibName:@"DetailedSetup" bundle:nil];
        
        [self.detailedSetupController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        [self.accountsListPage addSubview:self.detailedSetupController.view];
        
        NSView* subView = self.detailedSetupController.view;
        NSView* superView = self.accountsListPage;
        
        subView.hidden = YES;
        
        NSLayoutConstraint* centerHorizontallyConstraint = [NSLayoutConstraint constraintWithItem:subView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:superView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
        
        NSLayoutConstraint* centerVerticallyConstraint = [NSLayoutConstraint constraintWithItem:subView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:superView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
        
        [superView addConstraints:@[centerHorizontallyConstraint, centerVerticallyConstraint]];
        
        NSRect frame = self.detailedSetupController.view.layer.frame;
        NSPoint center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
        self.detailedSetupController.view.layer.position = center;
        self.detailedSetupController.view.layer.anchorPoint = CGPointMake(0.5, 0.5);
    }
    
    [self.detailedSetupController setupWithConnectionItem:item];
    
    CATransition* transition = [CATransition animation];
    transition.startProgress = 0;
    transition.endProgress = 1.0;
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromBottom;
    transition.duration = 0.7;
    
    // Add the transition animation to both layers
    [self.detailedSetupController.view.layer addAnimation:transition forKey:@"transition"];
    [self.accountsTableRoundedBox.layer addAnimation:transition forKey:@"transition"];
    
    // Finally, change the visibility of the layers.
    self.detailedSetupController.view.hidden = NO;
    self.accountsTableRoundedBox.hidden = YES;
    
    [self.accountsTableRoundedBox.layer setZPosition:5];
    [self.detailedSetupController.view.layer setZPosition:1];
    
    self.canGoUp = YES;
    
    NSView* setupView = self.view.superview.superview;
    
    if([setupView respondsToSelector:@selector(setCorrectButtonTitles)])
        [setupView performSelector:@selector(setCorrectButtonTitles)];
}



- (void)popDetailedSettingsOutOfView
{
    [self.detailedSetupController setIsClosing:YES];
    
    CATransition* transition = [CATransition animation];
    transition.startProgress = 0;
    transition.endProgress = 1.0;
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromTop;
    transition.duration = 0.7;
    
    // Add the transition animation to both layers
    [self.detailedSetupController.view.layer addAnimation:transition forKey:@"transition"];
    [self.accountsTableRoundedBox.layer addAnimation:transition forKey:@"transition"];
    
    // Finally, change the visibility of the layers.
    self.detailedSetupController.view.hidden = YES;
    self.accountsTableRoundedBox.hidden = NO;
    
    self.canGoUp = NO;
    
    NSView* setupView = self.view.superview.superview;
    
    if([setupView respondsToSelector:@selector(setCorrectButtonTitles)])
        [setupView performSelector:@selector(setCorrectButtonTitles)];
    
    [self updateDetailView];
}



#pragma mark - Connection items


- (void)addOrUpdateConnectionItem:(ConnectionItem*)item
{
    if(![item isKindOfClass:[ConnectionItem class]])
        return;
    
    __block ConnectionItem* connectionItem = item;
    
    [ThreadHelper runAsyncOnMain:^{
        
        ConnectionItem* existingItem = [self existingConnectionItemForEmail:connectionItem.emailAddress];
        
        if(existingItem)
        {
            BOOL changedSomething = NO;
            
            //this item is already shown in the list
            //fill the existing item with the passwords from the keychain
            if(connectionItem.password.length && (!existingItem.password.length || existingItem.sourceOfPassword < connectionItem.sourceOfPassword))
            {
                [existingItem setPassword:connectionItem.password];
                changedSomething = YES;
            }
            
            if(connectionItem.incomingPassword && (!existingItem.incomingPassword || existingItem.sourceOfPassword < connectionItem.sourceOfPassword))
            {
                [existingItem setIncomingPassword:connectionItem.incomingPassword];
                
                if(!existingItem.password)
                    [existingItem setPassword:connectionItem.incomingPassword];
                
                changedSomething = YES;
            }
            
            //            if(connectionItem.incomingPersistentRef && (!existingItem.incomingPersistentRef || existingItem.sourceOfPassword < connectionItem.sourceOfPassword))
            //            {
            //                [existingItem setIncomingPersistentRef:connectionItem.incomingPersistentRef];
            //                changedSomething = YES;
            //            }
            
            if(connectionItem.outgoingPassword && (!existingItem.outgoingPassword || existingItem.sourceOfPassword < connectionItem.sourceOfPassword))
            {
                [existingItem setOutgoingPassword:connectionItem.outgoingPassword];
                changedSomething = YES;
            }
            
            //            if(connectionItem.outgoingPersistentRef && (!existingItem.outgoingPersistentRef|| existingItem.sourceOfPassword < connectionItem.sourceOfPassword))
            //            {
            //                [existingItem setOutgoingPersistentRef:connectionItem.outgoingPersistentRef];
            //                changedSomething = YES;
            //            }
            
            if(existingItem.sourceOfPassword < connectionItem.sourceOfPassword)
            {
                [existingItem setSourceOfPassword:connectionItem.sourceOfPassword];
            }
            
            if(existingItem.sourceOfData <= connectionItem.sourceOfData)
            {
                [existingItem setIncomingAuth:connectionItem.incomingAuth];
                [existingItem setIncomingConnectionType:connectionItem.incomingConnectionType];
                [existingItem setIncomingHost:connectionItem.incomingHost];
                [existingItem setIncomingPort:connectionItem.incomingPort];
                [existingItem setIncomingUsername:connectionItem.incomingUsername];
                
                [existingItem setOutgoingAuth:connectionItem.outgoingAuth];
                [existingItem setOutgoingConnectionType:connectionItem.outgoingConnectionType];
                [existingItem setOutgoingHost:connectionItem.outgoingHost];
                [existingItem setOutgoingPort:connectionItem.outgoingPort];
                [existingItem setOutgoingUsername:connectionItem.outgoingUsername];
                
                [existingItem setSendingAliases:connectionItem.sendingAliases];
                [existingItem setSourceOfData:connectionItem.sourceOfData];
                [existingItem setAccountName:connectionItem.accountName];
                [existingItem setEmailAddress:connectionItem.emailAddress];
                [existingItem setEmailAddresses:connectionItem.emailAddresses];
                [existingItem setFullName:connectionItem.fullName];
                
                changedSomething = YES;
            }
            
            if(changedSomething)
            {
                [existingItem cancelAndResetConnections];
                
                [existingItem lookForSettingsWithCallback:^{
                    
                    [existingItem attemptImportWithCallback:nil];
                    
                }];
                
                [self refreshConnectionItemInTable:existingItem];
            }
        }
        else
        {
            //don't have this item yet
            [self.connectionItemList addObject:connectionItem];
            
            __weak ConnectionItem* weakItem = connectionItem;
            
            [connectionItem setChangeCallback:^{
                
                [self refreshConnectionItemInTable:weakItem];
            }];
            
            [connectionItem lookForSettingsWithCallback:^{
                
                [connectionItem attemptImportWithCallback:nil];
                
            }];
            
            [self reloadTableViewKeepingSelection];
            
            //ensure that there is a selection
            NSInteger selectedRow = [self.accountsListTableView selectedRow];
            
            if(0 <= selectedRow && selectedRow < self.connectionItemList.count && self.connectionItemList.count > 0)
                [self.accountsListTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        }
    }];
}


- (ConnectionItem*)existingConnectionItemForEmail:(NSString*)emailAddress
{
    __block ConnectionItem* returnValue = nil;
    
    //run on main to revent race conditions and ensure thread safety (NSMutableArray!)
    [ThreadHelper runSyncOnMain:^{
        
        //this shouldn't take too long - there will rarely be more than a dozen items in the list
        for(ConnectionItem* connectionItem in self.connectionItemList)
        {
            if([connectionItem.emailAddress.canonicalForm isEqual:emailAddress.canonicalForm])
            {
                returnValue = connectionItem;
                break;
            }
        }
    }];
    
    return returnValue;
}



- (void)setUpAccountsFromConnectionItemList
{
    [AccountCreationManager disuseAllAccounts];
    
    for(ConnectionItem* connectionItem in self.connectionItemList)
    {
        //        if(connectionItem.shouldUseForImport)
        [AccountCreationManager useConnectionItem:connectionItem];
    }
    
    //shouldn't be necessary - only the selected connection items should be used anyway
    //[AccountCreationManager resetIMAPAccountsFromAccountSettings];
    
    //also unnecessary - done by the useConectionItem method
    //[MODEL startupCheck];
}











- (id)valueForUndefinedKey:(NSString *)key
{
    return nil;
}





#pragma mark - Plist loading

- (IBAction)openSettingsFile
{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    
    [openPanel setAllowsOtherFileTypes:NO];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanCreateDirectories:NO];
    [openPanel setAllowsMultipleSelection:NO];
    
    NSViewController* accessoryViewController = [[NSViewController alloc] initWithNibName:@"OpenPanelAccessoryView" bundle:nil];
    
    NSView* openPanelAccessoryView = accessoryViewController.view;
    
    [openPanel setAccessoryView:openPanelAccessoryView];
    
    [openPanel setMessage:NSLocalizedString(@"Click 'Open' to let Mynigma access the Mail settings file", @"Open Apple Mail settings file")];
    
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:[@"~/Library/Mail/V2/MailData/Accounts.plist" stringByExpandingTildeInPath]]];
    
    
    NSInteger result = [openPanel runModal];
    
    [self moveToPage:self.currentPage+1];
    
    if(result == NSFileHandlingPanelOKButton)
    {
        NSURL* settingsFileURL = [openPanel URL];
        
        [self loadApplePlistAccounts:settingsFileURL];
    }
}

- (void)loadApplePlistAccounts:(NSURL*)plistURL
{
    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext)
     {
         NSArray* plistItems = [SetupScreensViewController parsePlistAtURL:plistURL];
         
         for(ConnectionItem* connectionItem in plistItems)
         {
             [connectionItem pullPasswordFromKeychainWithCallback:^{
                 
                 [self addOrUpdateConnectionItem:connectionItem];
             }];
         }
     }];
}

+ (NSArray*)parsePlistAtURL:(NSURL*)plistURL
{
    NSDictionary* plistDict = [NSDictionary dictionaryWithContentsOfURL:plistURL];
    
    NSMutableArray* connectionItems = [NSMutableArray new];
    
    if(plistDict)
    {
        NSArray* imapAccounts = [plistDict objectForKey:@"MailAccounts"];
        
        NSArray* smtpAccounts = [plistDict objectForKey:@"DeliveryAccounts"];
        
        for(NSDictionary* imapAccount in imapAccounts)
        {
            NSString* smtpIdentifier = [imapAccount objectForKey:@"SMTPIdentifier"];
            
            for(NSDictionary* smtpAccount in smtpAccounts)
            {
                NSString* smtpHostname = [smtpAccount objectForKey:@"Hostname"];
                NSString* smtpUsername = [smtpAccount objectForKey:@"Username"];
                
                NSString* idenitifer = [NSString stringWithFormat:@"%@:%@", smtpHostname, smtpUsername];
                
                if([idenitifer isEqualToString:smtpIdentifier])
                {
                    //NSLog(@"Found an IMAP/SMTP pair: %@", smtpUsername);
                    
                    NSArray* emailAddresses = [imapAccount objectForKey:@"EmailAddresses"];
                    if(emailAddresses.count>0)
                    {
                        NSString* email = [emailAddresses[0] lowercaseString];
                        NSString* fullName = [imapAccount objectForKey:@"FullUserName"];
                        NSString* accountName = [imapAccount objectForKey:@"AccountName"];
                        
                        NSNumber* connectionType = [imapAccount objectForKey:@"SecurityLayerType"];
                        
                        NSNumber* imapConnectionType = nil;
                        
                        if([connectionType isEqual:@2])
                            imapConnectionType = @(MCOConnectionTypeStartTLS);
                        if([connectionType isEqual:@3])
                            imapConnectionType = @(MCOConnectionTypeTLS);
                        
                        NSNumber* imapAuthType = @(MCOAuthTypeSASLPlain | MCOAuthTypeSASLLogin);
                        
                        NSNumber* shouldUseAuthentication = [imapAccount objectForKey:@"ShouldUseAuthentication"];
                        
                        if([shouldUseAuthentication boolValue])
                        {
                            imapAuthType = @(MCOAuthTypeSASLLogin);
                        }
                        
                        NSString* imapHostname = [[imapAccount objectForKey:@"Hostname"] lowercaseString];
                        NSString* imapUsername = [imapAccount objectForKey:@"Username"];
                        
                        
                        NSNumber* imapPort = nil;
                        
                        NSObject* imapPortObject = [imapAccount objectForKey:@"PortNumber"];
                        
                        if([imapPortObject isKindOfClass:[NSNumber class]])
                        {
                            if([(NSNumber*)imapPortObject integerValue]>0)
                                imapPort = (NSNumber*)imapPortObject;
                        }
                        
                        if([imapPortObject isKindOfClass:[NSString class]])
                        {
                            if([(NSString*)imapPortObject integerValue]>0)
                                imapPort = @([(NSString*)imapPortObject integerValue]);
                        }
                        
                        
                        connectionType = [imapAccount objectForKey:@"SecurityLayerType"];
                        
                        NSNumber* smtpConnectionType = nil;
                        
                        if([connectionType isEqual:@2])
                            smtpConnectionType = @(MCOConnectionTypeStartTLS);
                        if([connectionType isEqual:@3])
                            smtpConnectionType = @(MCOConnectionTypeTLS);
                        
                        NSNumber* smtpAuthType = @(MCOAuthTypeSASLPlain | MCOAuthTypeSASLLogin);
                        
                        shouldUseAuthentication = [smtpAccount objectForKey:@"ShouldUseAuthentication"];
                        
                        if([shouldUseAuthentication boolValue])
                        {
                            smtpAuthType = @(MCOAuthTypeSASLLogin);
                        }
                        
                        NSString* smtpHostname = [[smtpAccount objectForKey:@"Hostname"] lowercaseString];
                        NSString* smtpUsername = [smtpAccount objectForKey:@"Username"];
                        
                        NSNumber* smtpPort = nil;
                        
                        NSObject* smtpPortObject = [smtpAccount objectForKey:@"PortNumber"];
                        
                        if([smtpPortObject isKindOfClass:[NSNumber class]])
                        {
                            if([(NSNumber*)smtpPortObject integerValue]>0)
                                smtpPort = (NSNumber*)smtpPortObject;
                        }
                        
                        if([imapPortObject isKindOfClass:[NSString class]])
                        {
                            if([(NSString*)smtpPortObject integerValue]>0)
                                smtpPort = @([(NSString*)smtpPortObject integerValue]);
                        }
                        
                        //TO DO: set sending aliases
                        
                        ConnectionItem* connectionItem = [[ConnectionItem alloc] initWithEmail:email];
                        
                        [connectionItem setEmailAddress:email];
                        [connectionItem setEmailAddresses:emailAddresses];
                        [connectionItem setFullName:fullName];
                        [connectionItem setAccountName:accountName];
                        
                        [connectionItem setIncomingAuth:imapAuthType];
                        [connectionItem setIncomingConnectionType:imapConnectionType];
                        [connectionItem setIncomingHost:imapHostname];
                        [connectionItem setIncomingPort:imapPort];
                        [connectionItem setIncomingUsername:imapUsername];
                        
                        [connectionItem setOutgoingAuth:smtpAuthType];
                        [connectionItem setOutgoingConnectionType:smtpConnectionType];
                        [connectionItem setOutgoingHost:smtpHostname];
                        [connectionItem setOutgoingPort:smtpPort];
                        [connectionItem setOutgoingUsername:smtpUsername];
                        
                        //data stems from the Accounts.plist
                        [connectionItem setSourceOfData:ConnectionItemSourceOfDataAppleMail];
                        
                        //[connectionItem setSendingAliases:];
                        
                        [connectionItems addObject:connectionItem];
                    }
                }
            }
        }
    }
    
    return connectionItems;
}


#pragma mark - NSTableView data source

//the list of connection items
//plus one for the "add another account" row
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.connectionItemList.count;
}




#pragma mark - Filling table view cells

- (NSImage*)feedbackImageForConnectionItem:(ConnectionItem*)representedItem
{
    NSImage* feedbackImage = nil;
    
    if([representedItem showsError])
        feedbackImage = [NSImage imageNamed:NSImageNameStatusUnavailable];
    else
    {
        if([representedItem isSuccessfullyImported])
            feedbackImage = [NSImage imageNamed:NSImageNameStatusAvailable];
        else
        {
            if([representedItem isImporting])
            {
                feedbackImage = [NSImage imageNamed:NSImageNameStatusPartiallyAvailable];
            }
            else
            {
                feedbackImage = [NSImage imageNamed:NSImageNameStatusNone];
            }
        }
        
    }
    
    return feedbackImage;
}

- (void)fillTableViewCell:(ConnectionItemCellView*)view withConnectionItem:(ConnectionItem*)representedItem
{
    [view setObjectValue:representedItem];
    
    [view.shouldUseButton setState:representedItem.shouldUseForImport?NSOnState:NSOffState];
    
    if(![view.emailField.stringValue isEqualToString:representedItem.emailAddress])
        [view.emailField setStringValue:representedItem.emailAddress?representedItem.emailAddress:@""];
    
    if(![view.passwordField.stringValue isEqualToString:representedItem.password])
        [view.passwordField setStringValue:representedItem.password?representedItem.password:@""];
    
    if(![view.feedbackButton.attributedTitle isEqual:representedItem.feedbackString])
        [view.feedbackButton setAttributedTitle:representedItem.feedbackString?representedItem.feedbackString:[NSAttributedString new]];
    
    NSImage* feedbackImage = [self feedbackImageForConnectionItem:representedItem];
    
    if(feedbackImage && ![feedbackImage isEqual:view.feedbackIconButton.image])
        [view.feedbackIconButton setImage:feedbackImage];
    
    if(feedbackImage && ![feedbackImage isEqual:view.imageView.image])
        [view.imageView setImage:feedbackImage];
    //    if(self.makeLastEmailTextFieldFirstResponder && row == self.connectionItemList.count-1)
    //    {
    //        [self.window makeFirstResponder:view.textField];
    //    }
}

- (void)focusEmailFieldOnLastConnectionItem
{
    NSInteger row = self.connectionItemList.count - 1;
    
    if(row >= 0)
    {
        ConnectionItemCellView* cellView = (ConnectionItemCellView*)[self.accountsListTableView viewAtColumn:0 row:row makeIfNecessary:YES];
        
        if([cellView isKindOfClass:[ConnectionItemCellView class]])
        {
            [self.view.window makeFirstResponder:[(ConnectionItemCellView*)cellView emailField]];
        }
    }
}

- (void)reloadTableViewKeepingSelection
{
    NSInteger selectedRow = [self.accountsListTableView selectedRow];
    
    [self.accountsListTableView reloadData];
    
    if(0 <= selectedRow && selectedRow < self.connectionItemList.count)
        [self.accountsListTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
    else if(self.connectionItemList.count > 0)
        [self.accountsListTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}

- (void)refreshConnectionItemInTable:(ConnectionItem*)connectionItem
{
    [ThreadHelper runAsyncOnMain:^{
        
        if(connectionItem)
        {
            NSInteger row = [self.connectionItemList indexOfObject:connectionItem];
            
            if(row >= 0 && row < self.connectionItemList.count)
            {
                ConnectionItemCellView* view = (ConnectionItemCellView*)[self.accountsListTableView viewAtColumn:0 row:row makeIfNecessary:NO];
                
                if([view isKindOfClass:[ConnectionItemCellView class]])
                {
                    //don't reload the row if one of the two text fields is currently being edited - it would lose focus(!)
                    //if(![[(ConnectionItemCellView*)view objectValue] isEqual:self.itemBeingEdited])
                    [self fillTableViewCell:view withConnectionItem:connectionItem];
                    
                    //if the connection item is selected, the detail view on the right must be updated
                    if([self.accountsListTableView selectedRow] == row)
                    {
                        [self updateDetailView];
                    }
                }
            }
        }
    }];
}


#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    //the last row is "add another account"
    if(row == self.connectionItemList.count)
    {
        NSTableCellView* view = [tableView makeViewWithIdentifier:@"addCell" owner:self];
        
        return view;
    }
    
    ConnectionItemCellView* view = [tableView makeViewWithIdentifier:@"accountCell" owner:self];
    
    ConnectionItem* representedItem = self.connectionItemList[row];
    
    [self fillTableViewCell:view withConnectionItem:representedItem];
    
    return view;
}

- (NSIndexSet*)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes
{
    //if no selection at all is proposed, force a selection
    if(proposedSelectionIndexes.count == 0 && self.connectionItemList.count > 0)
    {
        //either keep the current selection, if there is one...
        NSInteger currentSelection = [tableView selectedRow];
        
        if(0 <= currentSelection && currentSelection < self.connectionItemList.count)
            return [tableView selectedRowIndexes];
            
        //otherwise select the first row instead
        return [NSIndexSet indexSetWithIndex:0];
    }
    
    //otherwise go ahead with the proposed selection
    return proposedSelectionIndexes;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [self.passwordField setStringValue:@""];
    [self.feedbackBox setHidden:YES];
    
    //[self pushDetailedSettingsIntoViewForCollectionItem:nil];
    NSInteger selectedIndex = [self.accountsListTableView selectedRow];
    
    if(0 <= selectedIndex && selectedIndex < self.connectionItemList.count)
    {
        ConnectionItem* item = self.connectionItemList[selectedIndex];
        [self setItemBeingEdited:item];
    }
    else
    {
        [self setItemBeingEdited:nil];
    }
    
    [self updateDetailView];
}


//obsolete
- (IBAction)setUpNewAccountButtonClicked:(id)sender
{
    ConnectionItem* newConnectionItem = [ConnectionItem new];
    
    __weak ConnectionItem* weakItem = newConnectionItem;
    
    [newConnectionItem setChangeCallback:^{
        
        [self refreshConnectionItemInTable:weakItem];
    }];
    
    [self.connectionItemList addObject:newConnectionItem];
    
    //    self.makeLastEmailTextFieldFirstResponder = YES;
    
    [self reloadTableViewKeepingSelection];
    
    [self focusEmailFieldOnLastConnectionItem];
}





#pragma mark - NSTextFieldDelegate & notifications

- (void)controlTextDidChange:(NSNotification *)obj
{
    if([obj.object isEqual:self.passwordField])
    {
        NSImage* image = [NSImage imageNamed:self.passwordField.stringValue.length?@"BirdClosedEyes64":@"BirdOpenEyes64"];
        [self.birdImage setImage:image];
        [self.birdImage setTintColor:NAVBAR_COLOUR];
    }
}

- (void)controlTextDidBeginEditing:(NSNotification *)obj
{
    //select the row if not already done
    NSTableCellView* cell = (NSTableCellView*)[obj.object superview];
    if([cell isKindOfClass:[NSTableCellView class]])
    {
        NSInteger row = [self.accountsListTableView rowForView:cell];
        if(row >= 0 && row < self.connectionItemList.count)
        {
            [self.accountsListTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        }
    }
}



- (void)controlTextDidEndEditing:(NSNotification *)obj
{
    if([obj.object isEqual:self.passwordField])
    {
        [self connectWithPassword:self.passwordField];
        
        return;
    }
    
    //if ([obj.userInfo[@"NSTextMovement"] unsignedIntegerValue])
    {
        
        //only need to update the settings (if applicable) and then attempt to connect
        ConnectionItemCellView* cell = (ConnectionItemCellView*)[obj.object superview];
        if([cell isKindOfClass:[ConnectionItemCellView class]])
        {
            NSInteger row = [self.accountsListTableView rowForView:cell];
            if(row >= 0 && row < self.connectionItemList.count)
            {
                ConnectionItem* item = self.connectionItemList[row];
                
                //reset the sources
                NSString* emailAddress = [(NSTextField*)obj.object stringValue];
                
                if(![item.emailAddress isEqual:emailAddress])
                {
                    [item clear];
                    
                    [item setEmailAddress:emailAddress];
                    
                    //the email address has been changed
                    //first update the connection settings
                    //then attempt an import
                    
                    //first find the right hostname
                    [item lookForSettingsWithCallback:^{
                        
                        //then look for the password
                        [item pullPasswordFromKeychainWithCallback:^{
                            
                            //update the UI
                            if(item.changeCallback)
                                item.changeCallback();
                            
                            //now attempt to import
                            [item attemptImportWithCallback:^{
                                
                                [self updateDetailView];
                                [self fillTableViewCell:cell withConnectionItem:item];
                            }];
                            
                            [self updateDetailView];
                            [self fillTableViewCell:cell withConnectionItem:item];
                        }];
                        
                    }];
                    
                    [self updateDetailView];
                    [self fillTableViewCell:cell withConnectionItem:item];
               }
                
                [self setItemBeingEdited:item];
            }
            else
                [self setItemBeingEdited:nil];
        }
        else
        {
            [self setItemBeingEdited:nil];
        }
    }
}


#pragma mark - Special buttons

- (IBAction)shouldUseButtonClicked:(id)sender
{
    NSInteger row = [self.accountsListTableView rowForView:sender];
    ConnectionItem* representedItem = self.connectionItemList[row];
    
    [representedItem setShouldUseForImport:[(NSButton*)sender state]==NSOnState];
}


- (IBAction)showPrivacyPolicy:(id)sender
{
#if ULTIMATE
    NSString* privacyPolicyLocation = NSLocalizedString(@"https://mynigma.org/en/privacypolicy-b2b.html", @"Privacy policy link B2B");
#else
    NSString* privacyPolicyLocation = NSLocalizedString(@"https://mynigma.org/en/PPApp.html", @"Privacy policy link");
#endif
    
    NSURL* privacyPolicyURL = [NSURL URLWithString:privacyPolicyLocation];
    
    [[NSWorkspace sharedWorkspace] openURL:privacyPolicyURL];
}

- (IBAction)errorLinkClickedInCell:(id)sender
{
    NSInteger row = [self.accountsListTableView rowForView:sender];
    ConnectionItem* representedItem = self.connectionItemList[row];
    
    if([representedItem isSuccessfullyImported])
        return;
    
    if([representedItem isImporting])
        [representedItem userCancelWithFeedback];
    else
    {
        if([representedItem isCancelled])
        {
            [representedItem attemptImportWithCallback:nil];
        }
        else if([representedItem showsError])
        {
            [self pushDetailedSettingsIntoViewForCollectionItem:representedItem];
        }
    }
}

- (IBAction)errorLampClicked:(id)sender
{
    NSInteger row = [self.accountsListTableView rowForView:sender];
    ConnectionItem* representedItem = self.connectionItemList[row];
    
    [self pushDetailedSettingsIntoViewForCollectionItem:representedItem];
}




- (IBAction)accountsPlusButtonClicked:(id)sender
{
    [self.connectionItemList addObject:[ConnectionItem new]];
    
    [self reloadTableViewKeepingSelection];
    
    [self performSelector:@selector(focusEmailFieldOnLastConnectionItem) withObject:nil afterDelay:.1];
}

- (IBAction)accountsEditButtonClicked:(id)sender
{
    NSInteger selectedIndex = [self.accountsListTableView selectedRow];
    
    if(0 <= selectedIndex && selectedIndex < self.connectionItemList.count)
    {
        ConnectionItemCellView* cellView = [self.accountsListTableView viewAtColumn:0 row:selectedIndex makeIfNecessary:YES];
        
        [self.view.window makeFirstResponder:cellView.emailField];
    }
}

- (IBAction)accountsMinusButtonClicked:(id)sender
{
    NSInteger selectedIndex = [self.accountsListTableView selectedRow];
    
    if(0 <= selectedIndex && selectedIndex < self.connectionItemList.count)
    {
        [self.connectionItemList removeObjectAtIndex:selectedIndex];
        
        [self reloadTableViewKeepingSelection];
        
        [self updateDetailView];
    }
}

- (IBAction)cancelConnectionTry:(id)sender
{
    NSInteger row = [self.accountsListTableView selectedRow];
    ConnectionItem* representedItem = self.connectionItemList[row];

    [representedItem userCancelWithFeedback];
    [self updateDetailView];
}

#pragma mark - New style accounts setup

- (IBAction)loginWithOAuth:(id)sender
{
    ConnectionItem* item = self.itemBeingEdited;

    [WindowManager showOAuthLoginForConnectionItem:item withCallback:^{
        
        [self updateDetailView];
    }];
}

- (IBAction)usePasswordLoginInstead:(id)sender
{
    [self showPasswordLogin];
}

- (IBAction)connectWithPassword:(id)sender
{
    ConnectionItem* item = self.itemBeingEdited;
    
    //reset the sources
    NSString* password = [self.passwordField stringValue];
    
    //if(![item.password isEqual:password])
    {
        [item setPassword:password];
        
        //start importing
        [item attemptImportWithCallback:^{
        
            [self updateDetailView];
        }];
        
        [self updateDetailView];
    }
}

- (IBAction)detailedSettings:(id)sender
{
    [self pushDetailedSettingsIntoViewForCollectionItem:self.itemBeingEdited];
}

- (void)showPasswordLogin
{
    [self.tabView selectTabViewItemAtIndex:0];
    
    if(self.itemBeingEdited.showsError && self.itemBeingEdited.password.length)
    {
        [self.feedbackTextField setAttributedTitle:self.itemBeingEdited.feedbackString];
        [self.feedbackTextField setTarget:self];
        [self.feedbackTextField setAction:@selector(detailedSettings:)];
        [self.feedbackTextField layout];
        
        [self.feedbackBox setHidden:NO];
    }
    else
    {
        [self.feedbackBox setHidden:YES];
    }
    
    NSString* password = self.itemBeingEdited.password;

    [self.passwordField setStringValue:password?password:@""];
}

- (void)showOAuthLogin
{
    [self.tabView selectTabViewItemAtIndex:1];
}

- (void)showInvalidEmail
{
    [self.tabView selectTabViewItemAtIndex:2];
}

- (void)showConnectionProgress
{
    [self.tabView selectTabViewItemAtIndex:3];
    [self.connectionProgressIndicator startAnimation:self];
}

- (void)showEmptyView
{
    [self.tabView selectTabViewItemAtIndex:4];
}

- (void)showConnectionSuccess
{
    [self.tabView selectTabViewItemAtIndex:5];
}




- (void)updateDetailView
{
    NSInteger selectedIndex = [self.accountsListTableView selectedRow];
    
    if(0 <= selectedIndex && selectedIndex < self.connectionItemList.count)
    {
        ConnectionItem* connectionItem = self.connectionItemList[selectedIndex];
        
        if(connectionItem.isSuccessfullyImported)
        {
            [self showConnectionSuccess];
        }
        else if(connectionItem.isImporting)
        {
            [self showConnectionProgress];
        }
        else
        {
            if(connectionItem.emailAddress.isValidEmailAddress)
            {
                if(connectionItem.canUseOAuth)
                {
                    [self showOAuthLogin];
                }
                else
                {
                    [self showPasswordLogin];
                }
            }
            else
            {
                [self showInvalidEmail];
            }
        }
        
        [self.accountsEditButton setEnabled:YES];
        [self.accountsMinusButton setEnabled:YES];
    }
    else
    {
        [self showEmptyView];
        [self.accountsEditButton setEnabled:NO];
        [self.accountsMinusButton setEnabled:NO];
    }
}

#pragma mark - OAuth delegate

- (void)windowController:(GTMOAuth2WindowController*)viewController finishedWithAuth:(GTMOAuth2Authentication *)auth error:(NSError *)error
{
    if (error != nil)
    {
        [AlertHelper presentError:error];
        
        //[self dismissViewControllerAnimated:YES completion:nil];
        
        // Authentication failed
        // Error handling here
        return;
    }
    
    NSString * email = [auth userEmail];
    NSString * accessToken = [auth accessToken];
    
    if ((error != nil) || ![email isValidEmailAddress] || !accessToken)
    {
        [AlertHelper showAlertWithMessage:NSLocalizedString(@"Error", nil) informativeText:NSLocalizedString(@"Provider failed to return email address", nil)];
        
        [AlertHelper showTwoOptionDialogueWithTitle:NSLocalizedString(@"Error!", nil) message:NSLocalizedString(@"An error occured while authenticating your account.", nil) OKOption:NSLocalizedString(@"Try again", nil) cancelOption:NSLocalizedString(@"Use basic login", nil) suppressionIdentifier:nil callback:^(BOOL OKOptionSelected){
            
            if(OKOptionSelected)
            {
#warning GOTO OAUTH CONTROLLER AGAIN
                // try OAuth again
                //[self dismissViewControllerAnimated:YES completion:^{
                    
                 //   [[[ViewControllersManager sharedInstance] splitViewController] dismissViewControllerAnimated:YES completion:nil];
                //}];
            }
            else
            {
#warning GOTO STANDARD LOGIN
                // navigate to standard login
                //[self dismissViewControllerAnimated:YES completion:^{
                    
                //    [[[ViewControllersManager sharedInstance] splitViewController] dismissViewControllerAnimated:YES completion:nil];
                //}];
            }
            
        }];
        
        // we depend on the email !!!
        // do something useful here !!
        return;
    }
    
    NSInteger selectedIndex = [self.accountsListTableView selectedRow];
    ConnectionItem* connectionItem = self.connectionItemList[selectedIndex];
    
    [connectionItem setEmailAddress:email];
    
    [connectionItem setIncomingUsername:email];
    [connectionItem setOutgoingUsername:email];
    
    // if outlook...
    if ([connectionItem.incomingHost isEqual:@"imap-mail.outlook.com"])
    {
        [connectionItem setIncomingAuth:@(MCOAuthTypeXOAuth2Outlook)];
        [connectionItem setOutgoingAuth:@(MCOAuthTypeXOAuth2Outlook)];
    }
    else
    {
        [connectionItem setIncomingAuth:@(MCOAuthTypeXOAuth2)];
        [connectionItem setOutgoingAuth:@(MCOAuthTypeXOAuth2)];
    }
    
    [connectionItem setOAuth2Token:accessToken];
    
    // no need to test the connection settings - they have been looked up, so they really ought to be OK
    
    if([AccountCreationManager haveAccountForEmail:email])
    {
        [AlertHelper showAlertWithMessage:NSLocalizedString(@"Account exists", nil) informativeText:NSLocalizedString(@"This account has already been set up!", nil)];
        return;
    }
    
    [AccountCreationManager makeNewAccountWithLocalKeychainItem:connectionItem];
    
    [AlertHelper showTwoOptionDialogueWithTitle:NSLocalizedString(@"Success!", nil) message:NSLocalizedString(@"Would you like to set up another account?", nil) OKOption:NSLocalizedString(@"Yes", nil) cancelOption:NSLocalizedString(@"No", nil) suppressionIdentifier:nil callback:^(BOOL OKOptionSelected){
        
       /* if(OKOptionSelected)
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else
        {
            [self dismissViewControllerAnimated:YES completion:^{
                
                [[[ViewControllersManager sharedInstance] splitViewController] dismissViewControllerAnimated:YES completion:nil];
            }];
        }*/
        
    }];
}


@end
