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





#import "SettingsController.h"
#import "AppDelegate.h"

#import "UserSettings.h"
#import "IMAPAccountSetting+Category.h"
#import "IMAPAccount.h"
#import "MynigmaPublicKey+Category.h"
#import "EmailContactDetail.h"
#import "DataWrapHelper.h"
#import "IconListAndColourHelper.h"
#import "EmailFooter.h"
#import "FooterSelectionCellView.h"
#import "MynigmaPrivateKey+Category.h"
#import "EmailContactDetail+Category.h"
#import "FileAttachment+Category.h"
#import "DeviceMessage+Category.h"
#import "NSData+Base64.h"
#import "AccountsListCellView.h"
#import "KeychainHelper.h"
#import "EmailAddress+Category.h"
#import "AlertHelper.h"
#import "SelectionAndFilterHelper.h"
#import "DeviceConnectionHelper.h"
#import "WindowManager.h"
#import "UserSettings+Category.h"





@interface SettingsController ()

@end

@implementation SettingsController

@synthesize accountsTable;
@synthesize appDelegate;
@synthesize accountFileView;


- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        publicKeys = @[];
        // Initialization code here.
    }

    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MynigmaPublicKey"];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"keyLabel" ascending:YES]]];
    publicKeys = [MAIN_CONTEXT executeFetchRequest:fetchRequest error:nil];
    [self setAppDelegate:APPDELEGATE];

    fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"EmailFooter"];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
    self.footers = [[MAIN_CONTEXT executeFetchRequest:fetchRequest error:nil] mutableCopy];


    [accountsTable setDoubleAction:@selector(showAccountSettings:)];
    [accountsTable setTarget:self];
    
    // set width to 31 if german
    if ([[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode] isEqual:@"de"])
        [(NSTableColumn*)[[[[accountsTable headerView] tableView] tableColumns] firstObject] setWidth:31.];
    // set width to 41 if german
    else if ([[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode] isEqual:@"fr"])
        [(NSTableColumn*)[[[[accountsTable headerView] tableView] tableColumns] firstObject] setWidth:41.];

    [self tableViewSelectionDidChange:nil];
}



#pragma mark - UI ACTIONS

- (IBAction)importFromKeychain:(id)sender
{
    NSButton* button = (NSButton*)sender;

    if([button isKindOfClass:[NSButton class]])
    {
        [button setEnabled:NO];
        [KeychainHelper fetchAllKeysFromKeychainWithCallback:^{

            NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MynigmaPublicKey"];
            publicKeys = [MAIN_CONTEXT executeFetchRequest:fetchRequest error:nil];

            [self.connectionsTableView reloadData];
            [button setEnabled:YES];
        }];
    }
}

- (IBAction)addButton:(id)sender
{
    //[APPDELEGATE showAddAccountSheet];
    [AlertHelper showWelcomeSheet];
}

- (IBAction)deleteButton:(id)sender
{
    NSInteger row = accountsTable.selectedRow;
    if(row>=0 && row<accountsTable.numberOfRows)
    {
        NSArray* accountsArray = [[UserSettings currentUserSettings].accounts sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"emailAddress" ascending:YES]]];
        IMAPAccountSetting* accountSetting = [accountsArray objectAtIndex:row];
        NSAlert* alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to delete the account %@?",@"Alerttitle <Account name>"),accountSetting.displayName] defaultButton:NSLocalizedString(@"Cancel",@"Cancel Button") alternateButton:NSLocalizedString(@"Delete account",@"Delete Button") otherButton:nil informativeTextWithFormat:NSLocalizedString(@"This action cannot be undone.",@"infotext")];
        if([alert runModal]==NSAlertAlternateReturn)
        {
            [accountSetting removeAccountWithCallback:^{

                [MAIN_CONTEXT performBlock:^{

                    [accountsTable reloadData];
                }];
            }];
        }
    }
}

- (IBAction)privacySettingsButton:(id)sender
{

}

- (IBAction)closeWindow:(id)sender
{
    [self webViewDidEndEditing:nil];

    [self.footerEditView stopLoading:nil];

    [self.footerEditView removeFromSuperviewWithoutNeedingDisplay];


    [NSApp endSheet:[self window] returnCode:NSOKButton];
    [[self window] orderOut:self];
}

- (IBAction)fetchKeys:(id)sender
{
    /*
     UserSettings* userSetting = MODEL.currentUserSettings;
     if(userSetting)
     {
     IMAPAccountSetting* accountSetting = userSetting.preferredAccount;
     [SERVER sendAllContactsToServerWithAccount:accountSetting withCallback:nil];
     }
     */
}

- (IBAction)showAccountSettings:(id)sender;
{
    [self editButton:self];
    /*
     NSInteger index = [accountsTable clickedRow];
     NSArray* accountsArray = [MODEL.currentUserSettings.accounts sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"emailAddress" ascending:YES]]];
     if(index!=NSNotFound && index<accountsArray.count)
     {
     [APPDELEGATE setAccountBeingSetup:[MODEL accountForSettingID:[accountsArray[index] objectID]]];
     [APPDELEGATE showAddAccountSheet];
     }*/
}


- (IBAction)saveKey:(id)sender
{
    [DataWrapHelper saveAsDialogue];
}

- (IBAction)restoreKey:(id)sender
{
    [DataWrapHelper openDialogue];
}

- (IBAction)launchSetupAssistant:(id)sender
{
    [AlertHelper showWelcomeSheet];
}

- (IBAction)useAccountCheckButton:(id)sender
{
    //reload the outline and update the unread count
    [SelectionAndFilterHelper refreshUnreadCount];
}



#pragma mark - TABLE VIEW DELEGATE

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if([tableView isEqual:self.footersList])
    {
        NSTableCellView* tableCellView = [tableView makeViewWithIdentifier:@"FooterTableCell" owner:self];

        if(row>=0 && row<self.footers.count)
        {
            EmailFooter* footer = self.footers[row];

            [tableCellView.textField setStringValue:footer.name?footer.name:NSLocalizedString(@"No name", @"Placeholder name for footer")];
        }

        return tableCellView;
    }

    if([tableView isEqual:self.connectionsTableView])
    {
        MynigmaPublicKey* publicKey = publicKeys[row];

        if([tableColumn.identifier isEqualTo:@"fingerprint"])
        {
            NSTableCellView* newCell = [tableView makeViewWithIdentifier:@"fingerprintCell" owner:self];
            
            [newCell.textField setStringValue:[MynigmaPublicKey fingerprintForKeyWithLabel:publicKey.keyLabel]];
            
            return newCell;
        }
        
        NSTableCellView* newCell = [tableView makeViewWithIdentifier:@"keyLabelCell" owner:self];

        NSFont* font = [publicKey isKindOfClass:[MynigmaPrivateKey class]]?[NSFont boldSystemFontOfSize:13]:[NSFont systemFontOfSize:13];

        [newCell.textField setFont:font];

        NSObject* objectValue = [publicKey valueForKey:tableColumn.identifier];

        if([objectValue isKindOfClass:[NSDate class]])
        {
            NSString* shownText = [NSDateFormatter localizedStringFromDate:(NSDate*)objectValue dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle];
            [newCell.textField setStringValue:shownText];
        }
        else
            [newCell.textField setStringValue:(NSString*)objectValue];

        return newCell;
    }

    if([tableView isEqual:self.emailAddressesTable])
    {
        NSTableCellView* newCell = [tableView makeViewWithIdentifier:@"onlyCell" owner:self];

        EmailAddress* address = [self.selectedKey.emailAddresses sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"address" ascending:YES]]][row];

        if([tableColumn.identifier isEqualTo:@"isCurrent"])
        {
            NSString* textValue = [[MynigmaPublicKey publicKeyLabelForEmailAddress:address.address] isEqual:self.selectedKey.keyLabel]?@"✔︎":@"";

            [newCell.textField setStringValue:textValue];

            return newCell;
        }

        NSObject* objectValue = [address valueForKey:tableColumn.identifier];

        if([objectValue isKindOfClass:[NSDate class]])
        {
            NSString* shownText = [NSDateFormatter localizedStringFromDate:(NSDate*)objectValue dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle];
            [newCell.textField setStringValue:shownText];
        }
        else
            [newCell.textField setStringValue:(NSString*)objectValue];

        return newCell;
    }

    NSArray* accountsArray = [[UserSettings currentUserSettings].accounts sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"emailAddress" ascending:YES]]];

    if(row>=accountsArray.count)
    {
        NSTableCellView* tableCellView = [tableView makeViewWithIdentifier:@"EmailAddressCell" owner:self];
        [tableCellView.textField setStringValue:@"--"];
        return tableCellView;
    }

    IMAPAccountSetting* accountSetting = (IMAPAccountSetting*)[accountsArray objectAtIndex:row];

    //cell reuse identifiers are set identical to the corresponding column identifiers in IB
    AccountsListCellView* tableCellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];

    if([tableCellView isKindOfClass:[AccountsListCellView class]])
        [tableCellView setAccountSetting:accountSetting];

    return tableCellView;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if([notification.object isEqual:self.accountsTable])
    {
        [self.editAccountButton setEnabled:self.accountsTable.selectedRowIndexes.count>0];
        [self.deleteAccountButton setEnabled:self.accountsTable.selectedRowIndexes.count>0];
    }

    if([notification.object isEqual:self.connectionsTableView])
    {
        if(self.connectionsTableView.selectedRowIndexes.count == 0)
        {
            [self setSelectedKey:nil];
        }
        else
        {
            self.selectedKey = publicKeys[self.connectionsTableView.selectedRow];
        }
        [self.emailAddressesTable reloadData];
    }

    if([notification.object isEqual:self.footersList])
    {
        //disable the "-" button if no footer is selected
        [self.removeFromFooterListButton setEnabled:self.footersList.selectedRowIndexes.count>0];
        [self.footerEditView setEditable:self.footersList.selectedRowIndexes.count>0];
        [self.footerEditView setEditingDelegate:self];

        if(self.footersList.selectedRowIndexes.count==0)
        {
            [self.footerEditView.mainFrame loadHTMLString:nil baseURL:nil];
        }
        else
        {
            NSInteger selectedRow = self.footersList.selectedRow;
            if(selectedRow>=0 && selectedRow<self.footers.count)
            {
                EmailFooter* selectedFooter = self.footers[selectedRow];

                [self.footerEditView.mainFrame loadHTMLString:selectedFooter.htmlContent baseURL:nil];
            }
        }
    }
}


#pragma mark - TABLE VIEW DATA SOURCE

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if([aTableView isEqual:self.footersList])
    {
        return self.footers.count;
    }

    if([aTableView isEqual:self.emailAddressesTable])
    {
        return self.selectedKey.emailAddresses.count;
    }

    if(aTableView.tag==333)
    {
        NSLog(@"%ld public keys in table", [publicKeys count]);
        return [publicKeys count];
    }
    else
    {
        return [UserSettings currentUserSettings].accounts.count;
    }
}


- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if([aTableView isEqual:self.footersList])
    {
        if(rowIndex>=0 && rowIndex<self.footers.count)
        {
            return self.footers[rowIndex];
        }
    }

    if([aTableView isEqual:self.emailAddressesTable])
    {
        return nil;
//        NSArray* sortedAddresses = [self.selectedKey.emailAddresses sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"address" ascending:YES]]];
//
//        EmailAddress* emailAddress = sortedAddresses[rowIndex];
//
//        return [emailAddress valueForKey:aTableColumn.identifier];
    }

    if(rowIndex<publicKeys.count)
    {
        MynigmaPublicKey* publicKey = [[publicKeys sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"keyLabel" ascending:YES]]] objectAtIndex:rowIndex];
        if([[aTableColumn identifier] isEqualToString:@"KeyID"])
        {
            return [publicKey keyLabel];
        }
        if([[aTableColumn identifier] isEqualToString:@"Email"])
        {
            NSString* email = [publicKey emailAddress];

            if(!email)
                email = [publicKey keyForEmail].address;

            if(!email)
                email = NSLocalizedString(@"(no email)", @"(no email)");

            BOOL isSafe = [publicKey isKindOfClass:[MynigmaPrivateKey class]];

            NSAttributedString* addressString = [[NSAttributedString alloc] initWithString:email attributes:isSafe?@{NSFontAttributeName:[NSFont boldSystemFontOfSize:13]}:@{}];
            return addressString;
        }
        if([[aTableColumn identifier] isEqualToString:@"Current"])
        {
            if(publicKey.currentForEmailAddress.count == 0)
                return @"";
            return @"✔︎";
        }
        if([[aTableColumn identifier] isEqualToString:@"Declaration"])
        {
            return [publicKey declaration]?@"Yes":@"No";
        }
    }
    return @"Oups";
}


#pragma mark - CONTROL EDITING DELEGATE

//editing the account name
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    if(control.tag==782)
    {
        NSInteger selectedRow = self.footersList.selectedRow;
        if(selectedRow>=0 && selectedRow<self.footers.count)
        {
            EmailFooter* selectedFooter = self.footers[selectedRow];

            [selectedFooter setName:control.stringValue];
            [self.footersList reloadData];

            [CoreDataHelper save];
        }

        return YES;
    }

    NSInteger index = [accountsTable rowForView:control.superview];
    NSArray* accountsArray = [[UserSettings currentUserSettings].accounts sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"emailAddress" ascending:YES]]];
    if(index!=NSNotFound && index<accountsArray.count)
    {
        [[accountsArray objectAtIndex:index] setDisplayName:control.stringValue];
        [SelectionAndFilterHelper reloadOutlinePreservingSelection];
    }
    return YES;
}





#pragma mark - FOOTER TAB

- (IBAction)addToFootersList:(id)sender
{
    NSEntityDescription* footerEntity = [NSEntityDescription entityForName:@"EmailFooter" inManagedObjectContext:MAIN_CONTEXT];
    EmailFooter* newFooter = [[EmailFooter alloc] initWithEntity:footerEntity insertIntoManagedObjectContext:MAIN_CONTEXT];
    [newFooter setName:[NSString stringWithFormat:NSLocalizedString(@"New footer #%ld", @"footers settings table view - newly added footer name"), self.footers.count+1]];

    NSURL* defaultFooterInRTFFileHTML = [BUNDLE URLForResource:@"StandardFooter" withExtension:@"html"];

    NSString* defaultFooterString = [NSString stringWithContentsOfURL:defaultFooterInRTFFileHTML encoding:NSUTF8StringEncoding error:nil];

    //NSData* defaultFooterData = [NSData dataWithContentsOfURL:defaultFooterInRTFFileURL];

    //NSAttributedString* defaultFooterAttributedString = [[NSAttributedString alloc] initWithData:defaultFooterData options:@{NSDocumentTypeDocumentAttribute: NSRTFDTextDocumentType, NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)} documentAttributes:nil error:nil];

    //NSString* defaultFooterHTML = [defaultFooterAttributedString HTMLFrom

    [newFooter setHtmlContent:defaultFooterString];

    [self.footers addObject:newFooter];
    [self.footersList reloadData];
}

- (IBAction)removeFromFootersList:(id)sender
{
    NSInteger selectedRow = self.footersList.selectedRow;
    if(selectedRow>=0 && selectedRow<self.footers.count)
    {
        EmailFooter* selectedFooter = self.footers[selectedRow];
        if([selectedFooter isKindOfClass:[EmailFooter class]])
        {
            [self.footers removeObject:selectedFooter];
            [MAIN_CONTEXT deleteObject:selectedFooter];
            [self.footersList reloadData];

            [CoreDataHelper save];
        }
    }
}


- (void)textDidEndEditing:(NSNotification *)notification
{

}

- (IBAction)editButton:(id)sender
{
    NSInteger selectedRow = self.accountsTable.selectedRow;
    NSArray* accountsArray = [[UserSettings currentUserSettings].accounts sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"emailAddress" ascending:YES]]];

    if(selectedRow>=0 && selectedRow<accountsArray.count)
    {
        IMAPAccountSetting* accountSetting = accountsArray[selectedRow];
        if(accountSetting)
        {
            [AlertHelper showIndividualSettingsWithIMAPAccountSetting:accountSetting];
        }
    }
}


- (void)webView:(WebView *)sender willPerformDragDestinationAction:(WebDragDestinationAction)action forDraggingInfo:(id < NSDraggingInfo >)draggingInfo
{
    if ([draggingInfo draggingSource] == nil)
    {

        NSPasteboard *pboard = [draggingInfo draggingPasteboard];

        //NSData* imageData = nil;

        if ([[pboard types] containsObject:NSFilenamesPboardType])
        {
            NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];

            //if it's a single image, display it inline(!)
            if(files.count==1)
            {
                NSString* fileName = files[0];

                NSString* extension = [[fileName pathExtension] lowercaseString];

                if(extension)
                    if([@[@"png", @"jpeg", @"jpg", @"gif", @"tiff"] containsObject:extension])
                    {
                        //OK, it's an image that can be displayed inline

                        NSURL* url = [NSURL fileURLWithPath:fileName];

                        [url startAccessingSecurityScopedResource];

                        NSError* error = nil;

                        NSData* imageData = [NSData dataWithContentsOfURL:url options:0 error:&error];

                        if(error)
                        {
                            NSLog(@"Error getting image data from URL: %@ - %@", url, error);

                        }

                        [url stopAccessingSecurityScopedResource];


                        [pboard setPropertyList:@[] forType:NSFilenamesPboardType];
                        [pboard declareTypes: [NSArray arrayWithObject: NSHTMLPboardType] owner: self];

                        NSString* imageString = [imageData base64];


                        NSString* htmlInsertion = [NSString stringWithFormat:@"<img src='data:image/%@;base64,%@'>", extension, imageString];
                        [pboard setString:htmlInsertion forType:NSHTMLPboardType];

                        return;
                    }
                //not an image, so use default behaviour (attach expicitly)
            }
        }

        [pboard setPropertyList:@[] forType:NSFilenamesPboardType];

        [pboard declareTypes: [NSArray arrayWithObject:NSStringPboardType] owner: pboard];
        [pboard setString:@"" forType:NSStringPboardType];
    }
}

- (void)webViewDidEndEditing:(NSNotification *)notification
{
    NSInteger selectedRow = self.footersList.selectedRow;
    if(selectedRow>=0 && selectedRow<self.footers.count)
    {
        EmailFooter* selectedFooter = self.footers[selectedRow];

        NSString* htmlString = [[self.footerEditView.mainFrame.DOMDocument body] innerHTML];

        [selectedFooter setHtmlContent:htmlString];

        [CoreDataHelper save];
    }
}

- (void)webView:(WebView *)webView
decidePolicyForNavigationAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request frame:(WebFrame *)frame
decisionListener:(id < WebPolicyDecisionListener >)listener
{
    //always open mailto: links with Mynigma

    if([request.URL.scheme.lowercaseString isEqual:@"mailto"])
    {
        [AppDelegate openURL:request.URL];
        return;
    }

    if([[actionInformation objectForKey:WebActionNavigationTypeKey] integerValue] == WebNavigationTypeLinkClicked)
    {
        [[NSWorkspace sharedWorkspace] openURL:[request URL]];
    }
    else
        [listener use];
}


#pragma mark - iOS link


- (IBAction)createAccountDataFile:(id)sender
{
    NSData* accountData = [DataWrapHelper makeIOSPackageIncludingAccountSettings:YES];

    NSString* bundleDirectory = [[AppDelegate applicationDocumentsDirectory] stringByAppendingString:@"/AccountData/"];

    NSError* error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:bundleDirectory withIntermediateDirectories:NO attributes:nil error:&error];

    error = nil;

    NSString* fileName = @"Mynigma.AccountData";

    NSString* filePath = [bundleDirectory stringByAppendingPathComponent:fileName];

    NSURL*  theFile = [NSURL fileURLWithPath:filePath];
    if([accountData writeToURL:theFile options:0 error:&error])
    {
        [accountFileView registerForDraggedTypes:@[NSFilesPromisePboardType, NSURLPboardType, NSFileContentsPboardType, NSFilenamesPboardType, NSURLPboardType]];
        [accountFileView setContent:@[@{@"name":@"Mynigma"}]];
    }
}

- (IBAction)deleteAccountDataFile:(id)sender
{
    NSString* bundleDirectory = [[AppDelegate applicationDocumentsDirectory] stringByAppendingString:@"/AccountData/"];

    NSString* fileName = @"Mynigma.AccountData";

    NSString* filePath = [bundleDirectory stringByAppendingPathComponent:fileName];

    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];

    [accountFileView setContent:@[]];
}



-(BOOL) collectionView:(NSCollectionView *)collectionView canDragItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event {

    NSLog(@"Event: %@", event);

    return YES;
}

- (BOOL)collectionView:(NSCollectionView *)collectionView writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard
{
    NSString* bundleDirectory = [[AppDelegate applicationDocumentsDirectory] stringByAppendingString:@"/AccountData/"];

    NSString* fileName = @"Mynigma.AccountData";

    NSString* filePath = [bundleDirectory stringByAppendingPathComponent:fileName];

    [pasteboard declareTypes:@[NSFilenamesPboardType] owner:nil];

    [pasteboard setPropertyList:@[filePath] forType:NSFilenamesPboardType];

    return YES;
}

- (void)pasteboard:(NSPasteboard *)pboard provideDataForType:
(NSString *)type {
    if ([type isEqualToString:NSFilenamesPboardType]) {
        NSArray *fileNameList = [NSArray arrayWithObject:
                                 [NSTemporaryDirectory() stringByAppendingPathComponent:@"aFile.jpg"]];
        [pboard setPropertyList:fileNameList
                        forType:NSFilenamesPboardType];
    }
}

- (NSArray*)collectionView:(NSCollectionView *)collectionView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropURL forDraggedItemsAtIndexes:(NSIndexSet *)indexes
{
    return @[@"Mynigma.PrivateData"];
}

- (NSDragOperation)draggingSession:(NSDraggingSession*)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
    return 0;
}

- (NSArray*)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination
{
    return @[@"Mynigma.PrivateData"];
}


- (IBAction)showDeviceList:(id)sender
{

}

- (IBAction)makeNewDeviceDiscoveryMessage:(id)sender
{
    [DeviceMessage constructNewDeviceDiscoveryMessageWithCallback:^(DeviceMessage *deviceDiscoveryMessage) {

        [DeviceConnectionHelper postDeviceMessage:deviceDiscoveryMessage intoAllAccountsInContext:MAIN_CONTEXT];
        
    }];
}

@end
