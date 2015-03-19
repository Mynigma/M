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





#import "TargetConditionals.h"

#if TARGET_OS_IPHONE

#import "FolderListController_iOS.h"

#import "FolderCell.h"
#import "CustomBadge.h"
#import "ContactCell.h"
#import "AccountCell.h"
#import "MessagesController.h"
#import "TopBarCell.h"
#import "HeadingCell.h"
#import "JASidePanelController.h"
#import "SplitViewController.h"
#import "ViewControllersManager.h"

#else

#import "FolderListController_MacOS.h"
#import "AccountOrFolderView.h"
#import "AccountRowView.h"
#import "MessageListController.h"
#import "ReloadViewController.h"
#import "ABContactDetail+Category.h"
#import "WindowManager.h"

#endif

#import "AppDelegate.h"
#import "GmailAccountSetting.h"
#import "Contact+Category.h"
#import "EmailContactDetail+Category.h"
#import "IMAPAccount.h"
#import "IMAPAccountSetting+Category.h"
#import "UserSettings+Category.h"
#import "GmailLabelSetting.h"
#import "IconListAndColourHelper.h"
#import "OutlineObject.h"
#import "EmailMessageInstance+Category.h"
#import "IMAPFolderSetting+Category.h"
#import "AccountCheckManager.h"
#import "SelectionAndFilterHelper.h"



#define REAL_HEADERS NO



@interface FolderListController ()

@end

@implementation FolderListController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)awakeFromNib
{
    _isChangingSelection = NO;

#if TARGET_OS_IPHONE

    [self.view.layer setZPosition:-10];
    [[ViewControllersManager sharedInstance] setFoldersController:self];

#else

//    [[WindowManager sharedInstance] setFoldersController:self];


#endif
}



#if TARGET_OS_IPHONE

- (IBAction)showSettings:(id)sender
{
    [ViewControllersManager hideSidePanel];

    UIViewController* settingsController = [[ViewControllersManager menuStoryboard] instantiateInitialViewController];

    if(RUNNING_AT_LEAST_IOS8)
    {
        [[[ViewControllersManager sharedInstance] splitViewController] presentViewController:settingsController animated:YES completion:nil];
    }
    else
    {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        
        [[[ViewControllersManager sharedInstance] messagesController] presentModalViewController:settingsController animated:YES];
        
#pragma GCC diagnostic pop
    }
}

- (void)viewDidLoad
{
    [SelectionAndFilterHelper updateFilters];

    [super viewDidLoad];
    
    [[ViewControllersManager sharedInstance] setFoldersController:self];
    [APPDELEGATE setContactTable:self.tableView];

    [self.navigationController.navigationBar.topItem setTitle:@""];

    [self setShownOutlineObjects:[NSMutableArray new]];

    [self refreshListOfShownAccountsAndFolders];

    if(![SelectionAndFilterHelper sharedInstance].topSelection)
    {
        [[SelectionAndFilterHelper sharedInstance] setTopSelection:[[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_ACCOUNTS]];
    }

    if(![SelectionAndFilterHelper sharedInstance].bottomSelection)
        [[SelectionAndFilterHelper sharedInstance] setBottomSelection:[[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_FOLDERS]];

    NSIndexPath* indexPath = [self indexPathForOutlineObject:[SelectionAndFilterHelper sharedInstance].topSelection];

    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];

    indexPath = [self indexPathForOutlineObject:[SelectionAndFilterHelper sharedInstance].bottomSelection];

    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];


    NSArray* barButtons = [self.navigationItem leftBarButtonItems];

    if(barButtons.count < 2)
    {
        //UIBarButtonItem* inviteButton = [[UIBarButtonItem alloc] initWithImage:[IMAGE imageNamed:@"heart22Template"] style:UIBarButtonItemStylePlain target:self action:@selector(inviteButtonPressed:)];

        UIBarButtonItem* feedbackButton = [[UIBarButtonItem alloc] initWithImage:[IMAGE imageNamed:@"loudspeaker22Template"] style:UIBarButtonItemStylePlain target:self action:@selector(feedbackButtonPressed:)];

        UIBarButtonItem* searchButton = [[UIBarButtonItem alloc] initWithImage:[IMAGE imageNamed:@"search22"] style:UIBarButtonItemStylePlain target:self action:@selector(searchButtonPressed:)];

        NSArray* newBarButtons = [barButtons arrayByAddingObjectsFromArray:@[/*inviteButton ,*/ feedbackButton, searchButton]];

        [self.navigationItem setLeftBarButtonItems:newBarButtons];
    }

    //NSLog(@"Selected rows: %@", self.tableView.indexPathsForSelectedRows);

    //    for(NSInteger index=0; index<[self.tableView numberOfRowsInSection:0]; index++)
    //    {
    //        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    //
    //        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
    //
    //
    //        [cell setSelected:NO animated:YES];
    //    }
}

- (IBAction)inviteButtonPressed:(id)sender
{

}

- (IBAction)feedbackButtonPressed:(id)sender
{
    [[ViewControllersManager sharedInstance].messagesController performSegueWithIdentifier:@"composeFeedback" sender:sender];
    [ViewControllersManager hideSidePanel];
}

- (IBAction)searchButtonPressed:(id)sender
{
    [[ViewControllersManager sharedInstance].messagesController setSearchBarShown:YES animated:YES];
    [ViewControllersManager hideSidePanel];
}

- (NSIndexPath*)indexPathForOutlineObject:(OutlineObject*)outlineObject
{
    NSInteger index = [self.shownOutlineObjects indexOfObject:outlineObject];

    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];

    return indexPath;
}

- (void)viewWillAppear:(BOOL)animated
{
    _isChangingSelection = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#endif


- (void)showProperSelection
{
#if TARGET_OS_IPHONE

    //    NSArray* selectionIndexes = APPDELEGATE.contactTable.indexPathsForSelectedRows;
    //
    //    NSMutableIndexSet* properSelectionIndices = [NSMutableIndexSet new];
    //
    //    if(APPDELEGATE.topSelection)
    //    {
    //        NSInteger index = [APPDELEGATE.foldersController. indexOfObject:APPDELEGATE.topSelection];
    //        if(index!=NSNotFound)
    //            [properSelectionIndices addIndex:index];
    //    }
    //
    //    if(APPDELEGATE.bottomSelection)
    //    {
    //        NSInteger index = [APPDELEGATE.contactOutlineController.arrangedObjects indexOfObject:APPDELEGATE.bottomSelection];
    //        if(index!=NSNotFound)
    //            [properSelectionIndices addIndex:index];
    //    }
    //
    //    if(![selectionIndices isEqual:properSelectionIndices])
    //    {
    //        _isChangingSelection = YES;
    //        [APPDELEGATE.contactTable selectRowIndexes:properSelectionIndices byExtendingSelection:NO];
    //    }


#else

    NSIndexSet* selectionIndices = self.tableView.selectedRowIndexes;

    NSMutableIndexSet* properSelectionIndices = [NSMutableIndexSet new];

    if([SelectionAndFilterHelper sharedInstance].topSelection)
    {
        NSInteger index = [APPDELEGATE.contactOutlineController.arrangedObjects indexOfObject:[SelectionAndFilterHelper sharedInstance].topSelection];
        if(index!=NSNotFound)
            [properSelectionIndices addIndex:index];
    }

    if([SelectionAndFilterHelper sharedInstance].bottomSelection)
    {
        NSInteger index = [APPDELEGATE.contactOutlineController.arrangedObjects indexOfObject:[SelectionAndFilterHelper sharedInstance].bottomSelection];
        if(index!=NSNotFound)
            [properSelectionIndices addIndex:index];
    }

    if(![selectionIndices isEqual:properSelectionIndices])
    {
        _isChangingSelection = YES;
        [self.tableView selectRowIndexes:properSelectionIndices byExtendingSelection:NO];
    }

#endif

}

#if TARGET_OS_IPHONE

#else

- (void)loadView
{
    [super loadView];
    
    [self.tableView registerForDraggedTypes:[NSArray arrayWithObjects:DRAGANDDROPMESSAGE,nil]];
    //the filters should be off to begin with
    [self folderOrContactsChoiceMade:self.showFoldersButton];
}

#endif


#pragma mark -
#pragma mark IBACTIONS

#if TARGET_OS_IPHONE

#else

//the "Folders" or the "Contacts" button has been pressed
- (IBAction)folderOrContactsChoiceMade:(id)sender
{
    if(sender == self.showContactsButton)
    { //the "Contacts" button has been clicked
        
        //set the contactsBox to dark blue colour, the foldersBox to light
        //[self.contactsBox setFillColor:[NSColor colorWithCalibratedRed:41/255. green:52/255. blue:86/255. alpha:1]];
        //[self.foldersBox setFillColor:[NSColor colorWithCalibratedRed:19/255. green:34/255. blue:67/255. alpha:1]];
        [self.foldersBox setFillColor:DISABLED_DARK_COLOUR];
        //        [self.contactsBox setFillColor:ACCOUNT_SELECTION_COLOUR];
        [self.contactsBox setFillColor:[NSColor clearColor]];
        
        if(![SelectionAndFilterHelper sharedInstance].showContacts)
        {
            //contacts should be shown, duh!
            [[SelectionAndFilterHelper sharedInstance] setShowContacts:YES];
            
            //undo any selections in either the contact outline or the message list
            
            [[SelectionAndFilterHelper sharedInstance] setTopSelection:nil];
            [[SelectionAndFilterHelper sharedInstance] setBottomSelection:nil];
            [SelectionAndFilterHelper reloadOutlinePreservingSelection];
        }
        
        //the "Contacts" button should be selected
        [self.showFoldersButton setState:NSOffState];
        [self.showContactsButton setState:NSOnState];
        
    }
    else
    {
        //set the contactsBox to light blue colour, the foldersBox to dark
        [self.contactsBox setFillColor:DISABLED_DARK_COLOUR];
        [self.foldersBox setFillColor:[NSColor clearColor]];
        //        [self.foldersBox setFillColor:ACCOUNT_SELECTION_COLOUR];
        
        if([SelectionAndFilterHelper sharedInstance].showContacts)
        {
            [[SelectionAndFilterHelper sharedInstance] setShowContacts:NO];
            
            [[SelectionAndFilterHelper sharedInstance] setTopSelection:[[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_ACCOUNTS]];
            [[SelectionAndFilterHelper sharedInstance] setBottomSelection:[[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_FOLDERS]];
            [SelectionAndFilterHelper reloadOutlinePreservingSelection];
        }
        
        [self.showContactsButton setState:NSOffState];
        [self.showFoldersButton setState:NSOnState];
        
    }
    [SelectionAndFilterHelper updateFilters];
}

#endif

#pragma mark -
#pragma mark TABLE VIEW DATA SOURCE


- (void)recurseThroughSubfoldersOfFolder:(IMAPFolderSetting*)folderSetting addingToArray:(NSMutableArray*)outlineObjects withIndentationLevel:(NSInteger)indentationLevel
{
    for(IMAPFolderSetting* subFolderSetting in folderSetting.subFolders)
    {
        OutlineObject* folderObject = [[OutlineObject alloc] initAsFolder:subFolderSetting];

        [folderObject setIndentationLevel:@(indentationLevel)];

        [outlineObjects addObject:folderObject];

        [self recurseThroughSubfoldersOfFolder:subFolderSetting addingToArray:outlineObjects withIndentationLevel:indentationLevel+1];
    }
}


- (void)refreshListOfShownAccountsAndFolders
{
    NSMutableArray* newListOfShownObjects = [NSMutableArray new];

#if TARGET_OS_IPHONE

    BOOL showContacts = NO;

#else

    BOOL showContacts = [SelectionAndFilterHelper sharedInstance].showContacts;

#endif

    if(showContacts)
    {
        OutlineObject* emptyObject = [[OutlineObject alloc] initAsEmptyInSection:@1 identifier:@"Top" separator:NO];
        [newListOfShownObjects addObject:emptyObject];

        OutlineObject* allContactsObject = [[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_CONTACTS];
        [newListOfShownObjects addObject:allContactsObject];

        OutlineObject* recentContactsObject = [[OutlineObject alloc] initAsStandardWithType:STANDARD_RECENT_CONTACTS];
        [newListOfShownObjects addObject:recentContactsObject];

        OutlineObject* separatorObject = [[OutlineObject alloc] initAsEmptyInSection:@4 identifier:@"Center" separator:YES];
        [newListOfShownObjects addObject:separatorObject];

        if([SelectionAndFilterHelper sharedInstance].topSelection.type==STANDARD_ALL_CONTACTS)
        {
            NSInteger count = 0;

#if TARGET_OS_IPHONE

            NSArray* unfilteredContacts = APPDELEGATE.contacts.fetchedObjects;

#else

            NSArray* unfilteredContacts = APPDELEGATE.contacts.arrangedObjects;

#endif

            for(Contact* contact in [unfilteredContacts filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@" emailAddresses[SIZE] > 0"]])
            {
                OutlineObject* contactObject = [[OutlineObject alloc] initAsContact:contact];
                [newListOfShownObjects addObject:contactObject];
                count++;
                //if(count>=25)
                //    break;
            }
        }
        else
        {
            NSInteger count = 0;

#if TARGET_OS_IPHONE

            NSArray* unfilteredRecentContacts = APPDELEGATE.contacts.fetchedObjects;

#else

            NSArray* unfilteredRecentContacts = APPDELEGATE.contacts.arrangedObjects;

#endif

            for(Contact* contact in unfilteredRecentContacts)
                if(contact.dateLastContacted)
                {
                    OutlineObject* contactObject = [[OutlineObject alloc] initAsRecentContact:contact];
                    [newListOfShownObjects addObject:contactObject];
                    count++;
                    if(count>=25)
                        break;
                }

        }
        OutlineObject* bottomSpaceObject = [[OutlineObject alloc] initAsEmptyInSection:@6 identifier:@"Bottom" separator:NO];
        [newListOfShownObjects addObject:bottomSpaceObject];

        OutlineObject* importButtonObject = [[OutlineObject alloc] initAsButtonInSection:@16 identifier:@"ImportButton" title:NSLocalizedString(@"Import from Contacts.app", nil)];

        [newListOfShownObjects addObject:importButtonObject];
    }
    else
    {
        OutlineObject* emptyObject = [[OutlineObject alloc] initAsEmptyInSection:@1 identifier:@"Top" separator:NO];
        [newListOfShownObjects addObject:emptyObject];

        //Model* model = MODEL;

        //UserSettings* userSettings = MODEL.currentUserSettings;

        NSArray* listOfAccounts = [[UserSettings currentUserSettings].accounts sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES],[NSSortDescriptor sortDescriptorWithKey:@"accountID" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"emailAddress" ascending:YES]]];

        NSPredicate* filterAccountsToBeUsed = [NSPredicate predicateWithFormat:@"shouldUse == YES"];

        listOfAccounts = [listOfAccounts filteredArrayUsingPredicate:filterAccountsToBeUsed];

        if(listOfAccounts.count>1)
        {
            OutlineObject* allAccountsObject = [[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_ACCOUNTS];
            [newListOfShownObjects addObject:allAccountsObject];

            for(IMAPAccountSetting* accountSetting in listOfAccounts)
            {
                OutlineObject* accountObject = [[OutlineObject alloc] initAsAccount:accountSetting];
                [newListOfShownObjects addObject:accountObject];
            }

            OutlineObject* separatorObject = [[OutlineObject alloc] initAsEmptyInSection:@4 identifier:@"Center" separator:YES];
            [newListOfShownObjects addObject:separatorObject];
        }

        //update the list of folders...

        NSMutableArray* standardFolderList = [NSMutableArray arrayWithObjects:[[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_FOLDERS], [[OutlineObject alloc] initAsStandardWithType:STANDARD_INBOX], [[OutlineObject alloc] initAsStandardWithType:STANDARD_OUTBOX], [[OutlineObject alloc] initAsStandardWithType:STANDARD_SENT], [[OutlineObject alloc] initAsStandardWithType:STANDARD_DRAFTS], [[OutlineObject alloc] initAsStandardWithType:STANDARD_BIN], [[OutlineObject alloc] initAsStandardWithType:STANDARD_SPAM], nil];

        [newListOfShownObjects addObjectsFromArray:standardFolderList];

        if([SelectionAndFilterHelper sharedInstance].topSelection.type!=STANDARD_ALL_ACCOUNTS || listOfAccounts.count==1)
        {
            IMAPAccountSetting* accountSetting = [[SelectionAndFilterHelper sharedInstance].topSelection accountSetting];

            if(listOfAccounts.count==1)
                accountSetting = listOfAccounts.firstObject;

            NSArray* sortedFolders = [accountSetting.folders sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES],[NSSortDescriptor sortDescriptorWithKey:@"path" ascending:YES]]];

            //go through the sorted folders list
            for(IMAPFolderSetting* folderSetting in sortedFolders)
            {
                //first check that the folder isn't in the list of standard folders already shown
                if(![folderSetting isStandardFolder])
                {
                    //if the folder is either not a child or a child of one of the standard folders then it should be shown as a root
                    if(!folderSetting.parentFolder || [folderSetting.parentFolder isStandardFolder])
                    {
                        //show the folder itself, followed by all its subfolders
                        OutlineObject* folderObject = [[OutlineObject alloc] initAsFolder:folderSetting];
                        [newListOfShownObjects addObject:folderObject];

                        [self recurseThroughSubfoldersOfFolder:folderSetting addingToArray:newListOfShownObjects withIndentationLevel:1];
                    }
                }
            }
        }   
//#if ULTIMATE
//
//        OutlineObject* separatorObject = [[OutlineObject alloc] initAsEmptyInSection:@13 identifier:@"BottomSeparator" separator:NO];
//        [newListOfShownObjects addObject:separatorObject];
//
//        [newListOfShownObjects addObject:[[OutlineObject alloc] initAsStandardWithType:STANDARD_LOCAL_ARCHIVE]];
//
//#endif

        OutlineObject* bottomSpaceObject = [[OutlineObject alloc] initAsEmptyInSection:@15 identifier:@"Bottom" separator:NO];
        [newListOfShownObjects addObject:bottomSpaceObject];

    }

#if TARGET_OS_IPHONE

    NSMutableArray* objectsToBeAdded = [NSMutableArray new];
    NSMutableArray* objectsToBeDeleted = [NSMutableArray new];
    for(NSObject* object in self.shownOutlineObjects)
        if(![newListOfShownObjects containsObject:object])
            [objectsToBeDeleted addObject:object];

    for(NSObject* object in newListOfShownObjects)
        if(![self.shownOutlineObjects containsObject:object])
            [objectsToBeAdded addObject:object];

    if(objectsToBeDeleted.count>0)
        [self.shownOutlineObjects removeObjectsInArray:objectsToBeDeleted];
    if(objectsToBeAdded.count>0)
        [self.shownOutlineObjects addObjectsFromArray:objectsToBeAdded];

    [self.shownOutlineObjects sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"sortSection" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"sortDate" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"sortName" ascending:YES]]];

#else

    NSMutableArray* objectsToBeAdded = [NSMutableArray new];
    NSMutableArray* objectsToBeDeleted = [NSMutableArray new];
    for(NSObject* object in APPDELEGATE.contactOutlineController.arrangedObjects)
        if(![newListOfShownObjects containsObject:object])
            [objectsToBeDeleted addObject:object];


    for(NSObject* object in newListOfShownObjects)
        if(![APPDELEGATE.contactOutlineController.arrangedObjects containsObject:object])
            [objectsToBeAdded addObject:object];

    if(objectsToBeDeleted.count>0)
        [APPDELEGATE.contactOutlineController removeObjects:objectsToBeDeleted];
    if(objectsToBeAdded.count>0)
        [APPDELEGATE.contactOutlineController addObjects:objectsToBeAdded];

#endif

}

- (void)reloadTable
{
    //whether a change was made to the current selection
    //BOOL changeMade = NO;

#if TARGET_OS_IPHONE

    BOOL showContacts = NO;

#else

    BOOL showContacts = [SelectionAndFilterHelper sharedInstance].showContacts;

#endif

    if(showContacts)
    {
        if(![[SelectionAndFilterHelper sharedInstance].topSelection isContactsOption])
        {
            //changeMade = YES;
            [[SelectionAndFilterHelper sharedInstance] setTopSelection:[[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_CONTACTS]];
        }
        if(![[SelectionAndFilterHelper sharedInstance].bottomSelection isContact])
        {
            //changeMade = YES;
            [[SelectionAndFilterHelper sharedInstance] setBottomSelection:nil];
        }
    }
    else
    {
        if(![[SelectionAndFilterHelper sharedInstance].topSelection isAccount])
        {
            //changeMade = YES;
            [[SelectionAndFilterHelper sharedInstance] setTopSelection:[[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_ACCOUNTS]];
        }

        if(![[SelectionAndFilterHelper sharedInstance].bottomSelection isFolder])
        {
            //changeMade = YES;
            [[SelectionAndFilterHelper sharedInstance] setBottomSelection:[[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_FOLDERS]];
        }
    }


    [self refreshListOfShownAccountsAndFolders];
    [self.tableView reloadData];
    [self showProperSelection];

    //NSLog(@"Selected objects: %@, %@\n---\nArray controller: %@\n---\nTable: %@", APPDELEGATE.topSelection, APPDELEGATE.bottomSelection, APPDELEGATE.contactOutlineController.selectedObjects, APPDELEGATE.contactTable.selectedRowIndexes);
}

- (void)refreshTable
{
    //whether a change was made to the current selection
    BOOL changeMade = NO;

#if TARGET_OS_IPHONE

    BOOL showContacts = NO;

#else

    BOOL showContacts = [SelectionAndFilterHelper sharedInstance].showContacts;

#endif

    if(showContacts)
    {
        if(![[SelectionAndFilterHelper sharedInstance].topSelection isContactsOption])
        {
            changeMade = YES;
            [[SelectionAndFilterHelper sharedInstance] setTopSelection:[[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_CONTACTS]];
        }
        if(![[SelectionAndFilterHelper sharedInstance].bottomSelection isContact])
        {
            changeMade = YES;
            [[SelectionAndFilterHelper sharedInstance] setBottomSelection:nil];
        }
    }
    else
    {
        if(![[SelectionAndFilterHelper sharedInstance].topSelection isAccount])
        {
            changeMade = YES;
            [[SelectionAndFilterHelper sharedInstance] setTopSelection:[[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_ACCOUNTS]];
        }

        if(![[SelectionAndFilterHelper sharedInstance].bottomSelection isFolder] && ![[SelectionAndFilterHelper sharedInstance].bottomSelection isLocalArchive])
        {
            changeMade = YES;
            [[SelectionAndFilterHelper sharedInstance] setBottomSelection:[[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_FOLDERS]];
        }
    }


    [self refreshListOfShownAccountsAndFolders];
    [self.tableView reloadData];
    [self showProperSelection];
}

#if TARGET_OS_IPHONE


#else

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    /*
     if(APPDELEGATE.showContacts)
     { //show contacts rather than folders

     if(APPDELEGATE.selectedContactListIndex==0) //"Recent Contacts" is selected
     return 4+[(NSArray*)APPDELEGATE.recentContacts.arrangedObjects count];
     else //"All Contacts" is selected
     return 4+[[APPDELEGATE.contacts.arrangedObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"ANY emailAddresses.address > ''"]] count];

     }*/

    return [(NSArray*)APPDELEGATE.contactOutlineController.arrangedObjects count];
}



#pragma mark -
#pragma mark TABLE VIEW DELEGATE


- (NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(row<[(NSArray*)APPDELEGATE.contactOutlineController.arrangedObjects count])
    {
        OutlineObject* shownObject = (OutlineObject*)APPDELEGATE.contactOutlineController.arrangedObjects[row];

        if(![shownObject isKindOfClass:[OutlineObject class]])
            return [tableView makeViewWithIdentifier:@"EmptyCell" owner:self];

        //the "import from address book" button
        if(shownObject.isButton)
        {
            AccountOrFolderView* tableViewCell = [tableView makeViewWithIdentifier:@"ButtonCell" owner:self];

            //[tableViewCell.unreadButton setTitle:shownObject.buttonTitle];

            return tableViewCell;
        }

        if(shownObject.isEmpty)
        {
            if(shownObject.showSeparator)
                return [tableView makeViewWithIdentifier:@"DividerCell" owner:self];
            else
                return [tableView makeViewWithIdentifier:@"EmptyCell" owner:self];
        }

        if(shownObject.contact)
        {
            AccountOrFolderView* cellView = (AccountOrFolderView*)[tableView makeViewWithIdentifier:@"ContactCell" owner:self];

            [cellView setRepresentedObject:shownObject];
            [shownObject configureCellView:cellView];
            return cellView;
        }

        AccountOrFolderView* newView = (AccountOrFolderView*)[tableView makeViewWithIdentifier:@"SimpleCell" owner:self];
        [newView setRepresentedObject:shownObject];
        [shownObject configureCellView:newView];
        return newView;


        if([shownObject isKindOfClass:[Contact class]])
        {
            Contact* contact = (Contact*)shownObject;
            AccountOrFolderView* folderRow = nil;
            if([contact isSafe])
            {
                folderRow = (AccountOrFolderView*)[tableView makeViewWithIdentifier:@"SecureContactCell" owner:self];
            }
            else
            {
                folderRow = (AccountOrFolderView*)[tableView makeViewWithIdentifier:@"ContactCell" owner:self];
            }

            NSImage* image = [contact profilePic];
            if(image)
            {
                CALayer* layer = folderRow.statusImage.layer;
                [layer setShadowRadius:0];

                [layer setCornerRadius:16];
                [layer setBorderColor:[NSColor colorWithDeviceRed:1 green:1 blue:1 alpha:.7].CGColor];
                [layer setBorderWidth:1];
                [layer setMasksToBounds:YES];
                folderRow.imageConstraint.priority = 1;
            }
            else
            {
                CALayer* layer = folderRow.statusImage.layer;
                [layer setBorderWidth:0];
                folderRow.imageConstraint.priority = 999;
            }
            [folderRow.statusImage setImage:image];

            NSString* displayName = [contact displayName];

            [folderRow.textField setStringValue:displayName?displayName:@""];

            [folderRow.statusLabel setStringValue:@""];

            [folderRow setRepresentedObject:shownObject];

            return folderRow;
        }


    }

    return [tableView makeViewWithIdentifier:@"EmptyCell" owner:self];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    //if(row==0)
    //    return 20;
    return 38;
}


- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    return [AccountRowView new];
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    return YES;
}


- (NSIndexSet*)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes
{
    if([(NSArray*)APPDELEGATE.contactOutlineController.arrangedObjects count]<=1)
        return proposedSelectionIndexes;

    if(![SelectionAndFilterHelper sharedInstance].showContacts && ![SelectionAndFilterHelper sharedInstance].topSelection)
    {
        OutlineObject* allAccountsObject = [[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_ACCOUNTS];
        [[SelectionAndFilterHelper sharedInstance] setTopSelection:allAccountsObject];
    }

    if(![SelectionAndFilterHelper sharedInstance].showContacts && ![SelectionAndFilterHelper sharedInstance].bottomSelection)
    {
        OutlineObject* allFoldersObject = [[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_FOLDERS];
        [[SelectionAndFilterHelper sharedInstance] setBottomSelection:allFoldersObject];
    }

    OutlineObject* newTopSelection = [SelectionAndFilterHelper sharedInstance].topSelection;
    OutlineObject* newBottomSelection = [SelectionAndFilterHelper sharedInstance].bottomSelection;

    NSInteger index = proposedSelectionIndexes.firstIndex;

    while(index!=NSNotFound && index<[(NSArray*)APPDELEGATE.contactOutlineController.arrangedObjects count])
    {
        OutlineObject* object = (OutlineObject*)[APPDELEGATE.contactOutlineController.arrangedObjects objectAtIndex:index];

        //catching a click on the "import from contacts.app" cell
        if(object.isButton)
        {
            NSTableCellView* tableCellView = [tableView viewAtColumn:0 row:index makeIfNecessary:NO];

            [tableCellView.textField setStringValue:NSLocalizedString(@"Importing...", nil)];
                [ABContactDetail loadAdditionalContactsFromAddressbookWithCallback:^{
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        
                        [tableCellView.textField setStringValue:NSLocalizedString(@"Import from Contacts.app", nil)];
                        [self refreshListOfShownAccountsAndFolders];
                        [tableView reloadData];
                        [self showProperSelection];

                    });
            }];
        }

        if(![object isKindOfClass:[OutlineObject class]])
        {
            index = [proposedSelectionIndexes indexGreaterThanIndex:index];
            continue;
        }

        if([object isEqual:[SelectionAndFilterHelper sharedInstance].topSelection] || [object isEqual:[SelectionAndFilterHelper sharedInstance].bottomSelection])
        {
            index = [proposedSelectionIndexes indexGreaterThanIndex:index];
            continue;
        }

        if([object isAccount])
        {
            newTopSelection = object;
            break;
        }

        if([object isFolder])
        {
            newBottomSelection = object;
        }

        if([object isContactsOption])
        {
            newTopSelection = object;
            newBottomSelection = nil;
            break;
        }

        if([object isLocalArchive])
        {
            newBottomSelection = object;
        }

        if([object isContact])
        {
            newBottomSelection = object;
        }
        index = [proposedSelectionIndexes indexGreaterThanIndex:index];
    }

    if(![[SelectionAndFilterHelper sharedInstance].topSelection isEqual:newTopSelection])
    {
        [[SelectionAndFilterHelper sharedInstance] setTopSelection:newTopSelection];
        [self refreshListOfShownAccountsAndFolders];
        [self.tableView reloadData];
    }

    if(![[SelectionAndFilterHelper sharedInstance].bottomSelection isEqual:newBottomSelection])
    {
        [[SelectionAndFilterHelper sharedInstance] setBottomSelection:newBottomSelection];
    }


    NSMutableIndexSet* newIndexSet = [NSMutableIndexSet new];

    NSInteger topIndex = [APPDELEGATE.contactOutlineController.arrangedObjects indexOfObject:[SelectionAndFilterHelper sharedInstance].topSelection];
    if(topIndex!=NSNotFound)
        [newIndexSet addIndex:topIndex];

    if([SelectionAndFilterHelper sharedInstance].bottomSelection)
    {
        NSInteger bottomIndex = [APPDELEGATE.contactOutlineController.arrangedObjects indexOfObject:[SelectionAndFilterHelper sharedInstance].bottomSelection];
        if(bottomIndex!=NSNotFound)
            [newIndexSet addIndex:bottomIndex];
    }

    //NSLog(@"Proposed indices: %@, new indices: %@, selection objects: (%@, %@), %ld outline objects", proposedSelectionIndexes, newIndexSet, APPDELEGATE.topSelection, APPDELEGATE.bottomSelection, [(NSArray*)APPDELEGATE.contactOutlineController.arrangedObjects count]);
    return newIndexSet;


}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    //[APPDELEGATE.contactTable reloadData];
    if(!_isChangingSelection)
    {
        //if the account selection has changed and the selected folder is not applicable for the new account, switch to "All Mail" instead
        IMAPFolderSetting* selectedFolder = [SelectionAndFilterHelper sharedInstance].bottomSelection.folderSetting;
        IMAPAccountSetting* selectedAccount = [SelectionAndFilterHelper sharedInstance].topSelection.accountSetting;

        //only do this if there is actually more than one account
        if(![SelectionAndFilterHelper sharedInstance].showContacts)
        {
            if([UserSettings usedAccounts].count>1)
            {
                if(selectedAccount)
                {
                    //a specific account is selected, so if there is also a specific folder, it must actually be linked to the account
                    if(selectedFolder && ![selectedAccount isEqual:selectedFolder.inIMAPAccount])
                    {
                        [[SelectionAndFilterHelper sharedInstance] setBottomSelection:[[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_FOLDERS]];
                        [SelectionAndFilterHelper reloadOutlinePreservingSelection];
                    }
                }
                else
                {
                    //"All Accounts" is selected, so the folder had better be a standard one
                    BOOL isStandardFolder = [SelectionAndFilterHelper sharedInstance].bottomSelection.isStandard;
                    if(!isStandardFolder)
                    {
                        [[SelectionAndFilterHelper sharedInstance] setBottomSelection:[[OutlineObject alloc] initAsStandardWithType:STANDARD_ALL_FOLDERS]];
                        [SelectionAndFilterHelper reloadOutlinePreservingSelection];
                    }
                }
            }
        }

        [SelectionAndFilterHelper updateFilters];
        for(IMAPAccountSetting* accountSetting in [UserSettings usedAccounts])
        {
            //checks the account, so long as it hasn't been done in the last 10 seconds
            [AccountCheckManager clickedOnAccountSetting:accountSetting];
        }
    }
    else
        _isChangingSelection = NO;
}



#pragma mark -
#pragma mark TABLE VIEW DRAG AND DROP

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    if([info.draggingSource isEqual:APPDELEGATE.messagesTable])
    {
        if([info.draggingSource isEqual:APPDELEGATE.messagesTable])
        {
            if([SelectionAndFilterHelper sharedInstance].showContacts)
            {
                /*
                 for(NSManagedObjectID* messageID in APPDELEGATE.draggedObjects)
                 {
                 EmailMessage* message = (EmailMessage*)[MAIN_CONTEXT objectWithID:messageID];
                 if(message && [message isKindOfClass:[EmailMessage class]])
                 {
                 NSData* recData = message.addressData;
                 NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:recData];
                 NSArray* recArray = [unarchiver decodeObjectForKey:@"recipients"];
                 [unarchiver finishDecoding];

                 for(EmailRecipient* rec in recArray)
                 {
                 [MODEL addEmailToContacts:rec.email withName:rec.name];
                 [APPDELEGATE reloadOutlinePreservingSelection];
                 }
                 return YES;
                 }
                 }*/
            }
            else
            {
                if(!(row<tableView.numberOfRows))
                    return NO;

                AccountOrFolderView* accountOrFolderView = [tableView viewAtColumn:0 row:row makeIfNecessary:NO];
                if(![accountOrFolderView isKindOfClass:[AccountOrFolderView class]])
                    return NO;

                NSObject* representedObject = accountOrFolderView.representedObject;
                if(![representedObject isKindOfClass:[OutlineObject class]])
                    return NO;

                if(![(OutlineObject*)representedObject isFolder])
                {
                    if(![(OutlineObject*)representedObject isLocalArchive])
                        return NO;

                    //ok, we are dragging something into the local backup "folder"
                    //that's alright, so long as we aren't already looking at local backup messages
                    if([SelectionAndFilterHelper sharedInstance].bottomSelection.type!=STANDARD_LOCAL_ARCHIVE)
                    {
                        [tableView setDropRow:row dropOperation:NSTableViewDropOn];
                        return NSDragOperationMove;
                    }

                    return NO;
                }

                BOOL shouldMove = YES;
                for(NSManagedObjectID* messageObjectID in [SelectionAndFilterHelper sharedInstance].draggedObjects)
                {
                    EmailMessageInstance* messageInstance = [EmailMessageInstance messageInstanceWithObjectID:messageObjectID inContext:MAIN_CONTEXT];
                    if([messageInstance isKindOfClass:[EmailMessageInstance class]])
                    {
                        IMAPAccountSetting* oldAccountSetting = messageInstance.accountSetting;

                        if(!oldAccountSetting)
                        {
                            shouldMove = NO;
                            break;
                        }

                        NSSet* newFolderSet = [(OutlineObject*)representedObject associatedFoldersForAccountSettings:[NSSet setWithObject:oldAccountSetting]];

                        if(newFolderSet.count!=1)
                        {
                            shouldMove = NO;
                            break;
                        }

                        IMAPFolderSetting* newFolder = [newFolderSet anyObject];

                        //the message should be in the same account
                        if(![newFolder.accountSetting isEqual:oldAccountSetting])
                        {
                            shouldMove = NO;
                            break;
                        }

                        if([newFolder.accountSetting isKindOfClass:[GmailAccountSetting class]])
                        {

                            NSSet* selectedFolderSet = [[SelectionAndFilterHelper sharedInstance].bottomSelection associatedFoldersForAccountSettings:[NSSet setWithObject:oldAccountSetting]];

                            IMAPFolderSetting* selectedFolder = selectedFolderSet.anyObject;

                            if(selectedFolderSet.count!=1)
                            {
                                shouldMove = NO;
                                break;
                            }

                            if(![messageInstance canMoveToFolderOrAddLabel:newFolder fromFolder:selectedFolder])
                            {
                                shouldMove = NO;
                                break;
                            }
                        }
                        else
                        {
                            IMAPFolderSetting* sourceFolder = messageInstance.inFolder;
                            if(![messageInstance canMoveToFolderOrAddLabel:newFolder fromFolder:sourceFolder])
                            {
                                shouldMove = NO;
                                break;
                            }
                        }
                    }

                }
                if(shouldMove)
                {
                    [tableView setDropRow:row dropOperation:NSTableViewDropOn];
                    return NSDragOperationMove;
                }
                else
                    return NSDragOperationNone;

            }
        }
    }
    return NSDragOperationNone;
}

- (BOOL)askForConfirmationToMoveNMessages:(NSInteger)movedMessageCount
{
    //only  ask for confirmation if at least a dozen messages were moved
    if(movedMessageCount<12)
        return YES;

    NSAlert* alertView = [NSAlert alertWithMessageText:NSLocalizedString(@"Please confirm", @"Seeking confirmation alert message") defaultButton:NSLocalizedString(@"OK", @"OK button") alternateButton:NSLocalizedString(@"Cancel", @"Cancel Button") otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Are you sure you would like to move %ld messages?", @"Message batch move confirmation"), movedMessageCount];

    if(alertView.runModal != NSAlertDefaultReturn)
    {
        //don't do anything unless the user confirms
        return NO;
    }

    return YES;
}

- (BOOL)askForConfirmationToMoveNMessages:(NSInteger)movedMessageCount fromFolderWithName:(NSString*)fromFolderName toFolder:(NSString*)toFolderName
{
    //only  ask for confirmation if at least a dozen messages were moved
    if(movedMessageCount<12)
        return YES;

    NSAlert* alertView = [NSAlert alertWithMessageText:NSLocalizedString(@"Please confirm", @"Seeking confirmation alert message") defaultButton:NSLocalizedString(@"OK", @"OK button") alternateButton:NSLocalizedString(@"Cancel", @"Cancel Button") otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Are you sure you would like to move %ld messages from folder %@ to folder %@?", @"Message batch move confirmation"), movedMessageCount, fromFolderName, toFolderName];

    if(alertView.runModal != NSAlertDefaultReturn)
    {
        //don't do anything unless the user confirms
        return NO;
    }

    return YES;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{

    if([info.draggingSource isEqual:APPDELEGATE.messagesTable])
    {
        if([SelectionAndFilterHelper sharedInstance].showContacts)
        {
            /*
             for(NSManagedObjectID* messageID in APPDELEGATE.draggedObjects)
             {
             EmailMessage* message = (EmailMessage*)[MAIN_CONTEXT objectWithID:messageID];
             if(message && [message isKindOfClass:[EmailMessage class]])
             {
             NSData* recData = message.addressData;
             NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:recData];
             NSArray* recArray = [unarchiver decodeObjectForKey:@"recipients"];
             [unarchiver finishDecoding];

             for(EmailRecipient* rec in recArray)
             {
             [MODEL addEmailToContacts:rec.email withName:rec.name];
             [APPDELEGATE reloadOutlinePreservingSelection];
             }
             return YES;
             }
             }*/
        }
        else
        {
            if(!(row<tableView.numberOfRows))
                return NO;

            AccountOrFolderView* accountOrFolderView = [tableView viewAtColumn:0 row:row makeIfNecessary:NO];
            if(![accountOrFolderView isKindOfClass:[AccountOrFolderView class]])
                return NO;

            NSObject* representedObject = accountOrFolderView.representedObject;
            if(![representedObject isKindOfClass:[OutlineObject class]])
                return NO;

            if(![(OutlineObject*)representedObject isFolder])
            {
                if(![(OutlineObject*)representedObject isLocalArchive])
                    return NO;

                //ok, we are dragging something into the local backup "folder"
                //that's alright, so long as we aren't already looking at local backup messages
                if([SelectionAndFilterHelper sharedInstance].bottomSelection.type!=STANDARD_LOCAL_ARCHIVE)
                {
                    for(NSManagedObjectID* messageObjectID in [SelectionAndFilterHelper sharedInstance].draggedObjects)
                    {
                        EmailMessageInstance* messageInstance = [EmailMessageInstance messageInstanceWithObjectID:messageObjectID inContext:MAIN_CONTEXT];
                        if([messageInstance isKindOfClass:[EmailMessageInstance class]])
                        {

                            //return YES;
                        }
                    }
                }

                return NO;
            }

            BOOL shouldMove = YES;

            BOOL confirmationGivenOrNotRequired = [self askForConfirmationToMoveNMessages:[SelectionAndFilterHelper sharedInstance].draggedObjects.count];

            if(!confirmationGivenOrNotRequired)
                return NO;

            for(NSManagedObjectID* messageObjectID in [SelectionAndFilterHelper sharedInstance].draggedObjects)
            {
                EmailMessageInstance* messageInstance = [EmailMessageInstance messageInstanceWithObjectID:messageObjectID inContext:MAIN_CONTEXT];
                if([messageInstance isKindOfClass:[EmailMessageInstance class]])
                {
                    IMAPAccountSetting* oldAccountSetting = messageInstance.accountSetting;

                    if(!oldAccountSetting)
                    {
                        shouldMove = NO;
                        break;
                    }

                    NSSet* newFolderSet = [(OutlineObject*)representedObject associatedFoldersForAccountSettings:[NSSet setWithObject:oldAccountSetting]];

                    if(newFolderSet.count!=1)
                    {
                        shouldMove = NO;
                        break;
                    }

                    IMAPFolderSetting* newFolder = [newFolderSet anyObject];

                    //the message should be in the same account
                    if(![newFolder.accountSetting isEqual:oldAccountSetting])
                    {
                        shouldMove = NO;
                        break;
                    }

                    if([newFolder.accountSetting isKindOfClass:[GmailAccountSetting class]])
                    {
                        IMAPFolderSetting* selectedFolder = [FolderListController selectedFolderForMessageInstance:messageInstance];
                        [messageInstance moveToFolderOrAddLabel:newFolder fromFolder:selectedFolder];

                        [SelectionAndFilterHelper refreshAllMessages];
                        //[APPDELEGATE updateFilters];
                        [CoreDataHelper save];
                    }
                    else
                    {
                        IMAPFolderSetting* sourceFolder = messageInstance.inFolder;
                        if([messageInstance canMoveToFolderOrAddLabel:newFolder fromFolder:sourceFolder])
                        {
                            if([self askForConfirmationToMoveNMessages:[SelectionAndFilterHelper sharedInstance].draggedObjects.count fromFolderWithName:sourceFolder.displayName toFolder:newFolder.displayName])
                            {
                                [messageInstance moveToFolder:newFolder];
                                [SelectionAndFilterHelper refreshAllMessages];
                                //[APPDELEGATE updateFilters];
                                [CoreDataHelper save];
                            }
                        }
                    }
                }

            }
            return shouldMove;
        }
    }
    return NO;
}

- (void)tableView:(NSTableView *)aTableView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation
{

}


- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forRowIndexes:(NSIndexSet *)rowIndexes
{
    NSMutableSet* draggedObjectsSet = [NSMutableSet new];

    if(rowIndexes.count!=1)
        return;

    NSInteger row = rowIndexes.firstIndex;

    if(row<[(NSArray*)APPDELEGATE.contactOutlineController.arrangedObjects count])
    {
        OutlineObject* shownObject = (OutlineObject*)APPDELEGATE.contactOutlineController.arrangedObjects[row];

        [draggedObjectsSet addObject:shownObject];
    }

    [SelectionAndFilterHelper sharedInstance].draggedObjects = draggedObjectsSet;
}


- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    if(rowIndexes.count==1)
    {
        NSInteger row = rowIndexes.firstIndex;

        if(row<[(NSArray*)APPDELEGATE.contactOutlineController.arrangedObjects count])
        {
            OutlineObject* shownObject = (OutlineObject*)APPDELEGATE.contactOutlineController.arrangedObjects[row];
            if([shownObject isKindOfClass:[OutlineObject class]])
                return YES;
        }
    }
    return NO;
}


- (id < NSPasteboardWriting >)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row
{
    NSPasteboardItem *pasteboardItem = [[NSPasteboardItem alloc] init];
    NSArray *types = [[NSArray alloc] initWithObjects:DRAGANDDROPLABEL, nil];
    BOOL ok = [pasteboardItem setDataProvider:self forTypes:types];

    if (ok) {

        //NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        //[pasteboard clearContents];
        if(row<[(NSArray*)APPDELEGATE.contactOutlineController.arrangedObjects count])
        {
            OutlineObject* object = [APPDELEGATE.contactOutlineController.arrangedObjects objectAtIndex:row];
            if([object isKindOfClass:[OutlineObject class]])
                if(object.isFolder)
                {
                    //not all folders can be dragged:
                    //first of all it must be a label
                    //so the account in question must be Gmail account or it must be "All accounts" with at least one Gmail account
                    //and it must not be the outbox

                    if([SelectionAndFilterHelper sharedInstance].topSelection.type==STANDARD_ALL_ACCOUNTS)
                    {
                        BOOL haveAtLeastOneGmailAccount = NO;

                        for(IMAPAccountSetting* accountSetting in [UserSettings currentUserSettings].accounts)
                        {
                            if([accountSetting isKindOfClass:[GmailAccountSetting class]])
                            {
                                haveAtLeastOneGmailAccount = YES;
                                break;
                            }
                        }

                        if(!haveAtLeastOneGmailAccount)
                            return nil;
                    }
                    else
                        if(![[SelectionAndFilterHelper sharedInstance].topSelection.accountSetting isKindOfClass:[GmailAccountSetting class]])
                            return nil;

                    if(object.folderSetting.isOutbox || object.type == STANDARD_OUTBOX)
                        return nil;

                    NSData *data = [object dataForDragAndDrop];
                    if(!data)
                        data = [@"Some replacement string." dataUsingEncoding:NSUTF8StringEncoding];
                    [pasteboardItem setData:data forType:DRAGANDDROPLABEL];
                    return pasteboardItem;
                }
        }
    }
    return nil;
}

- (void)pasteboard:(NSPasteboard *)pasteboard item:(NSPasteboardItem *)item provideDataForType:(NSString *)type
{

}

- (void)pasteboardFinishedWithDataProvider:(NSPasteboard *)pasteboard
{

}

#endif


/**CALL ON MAIN*/
+ (IMAPFolderSetting*)selectedFolderForMessageInstance:(EmailMessageInstance*)messageInstance
{
    //if the message is in the outbox and the outbox is selected, return the outbox
    if([messageInstance isInOutboxFolder] && [SelectionAndFilterHelper sharedInstance].bottomSelection.isOutbox)
        return messageInstance.folderSetting;


    NSManagedObjectID* messageInstanceObjectID = messageInstance.objectID;

    __block NSManagedObjectID* selectedFolderObjectID = nil;

    [ThreadHelper runSyncOnMain:^{

        EmailMessageInstance* messageInstanceOnMain = [EmailMessageInstance messageInstanceWithObjectID:messageInstanceObjectID inContext:MAIN_CONTEXT];

        IMAPAccountSetting* accountSetting = messageInstanceOnMain.accountSetting;

    NSSet* selectedFolderSet = [[SelectionAndFilterHelper sharedInstance].bottomSelection associatedFoldersForAccountSettings:[NSSet setWithObject:accountSetting]];

    IMAPFolderSetting* selectedFolder = selectedFolderSet.anyObject;

    if(selectedFolderSet.count!=1)
    {
        NSLog(@"%ld selected folders found for account setting: %@", (unsigned long)selectedFolderSet.count, accountSetting.displayName);
        selectedFolder = accountSetting.allMailOrInboxFolder;
    }

    }];

    if(!selectedFolderObjectID)
        return nil;

    IMAPFolderSetting* selectedFolder = [IMAPFolderSetting folderSettingWithObjectID:selectedFolderObjectID inContext:messageInstance.managedObjectContext];

    return selectedFolder;
}


- (NSArray*)shownObjects
{

#if TARGET_OS_IPHONE

    return self.shownOutlineObjects;

#else

    return APPDELEGATE.contactOutlineController.arrangedObjects;

#endif

}

- (OutlineObject*)objectAtIndex:(NSInteger)index
{
    NSArray* shownObjects = [self shownObjects];
    if(index>=0 && index<shownObjects.count)
    {
        NSObject* object = shownObjects[index];
        if([object isKindOfClass:[OutlineObject class]])
            return (OutlineObject*)object;
    }

    return nil;
}


#if TARGET_OS_IPHONE

#pragma mark -
#pragma mark UITableViewDataSource

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger numberOfSections = 1;

    return numberOfSections;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    switch (section) {
        case 2:
            return NSLocalizedString(@"Filters", @"Filters header");
            break;
        case 0:
            return NSLocalizedString(@"Accounts", @"Accounts header");
            break;
        case 1:
            return NSLocalizedString(@"Folders", @"Folders header");
            break;
        case 3:
            return NSLocalizedString(@"Recent contacts", @"Contacts header");
            break;

        default:
            return @"";
            break;
    }
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.shownOutlineObjects.count;
}


-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 18)];

    return view;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, tableView.frame.size.width, 18)];
    [label setFont:[UIFont boldSystemFontOfSize:12]];
    NSString *string = [self tableView:tableView titleForHeaderInSection:section];

    [label setText:string];
    [label setTextColor:[UIColor whiteColor]];
    [view addSubview:label];
    [view setBackgroundColor:[UIColor colorWithRed:42/255. green:54/255. blue:87/255. alpha:1]];

    return view;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"- Selected rows: %@", self.tableView.indexPathsForSelectedRows);

    [SelectionAndFilterHelper updateFilters];

    [ViewControllersManager hideSidePanel];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{

}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OutlineObject* object = [self objectAtIndex:indexPath.row];

    if([ViewControllersManager isShowingMoveMessageOptions])
    {
        //move the messages
        if(object.isFolder)
        {
            [ViewControllersManager removeMoveMessageOptionsIfNecessary];
            [SelectionAndFilterHelper moveSelectedMessagesToOutlineObject:object];
            //[SelectionAndFilterHelper moveSelectedMessagesToFolder:object.folderSetting];
            [ViewControllersManager hideSidePanel];
        }
        return nil;
    }

    if(object.isAccount)
    {
        [[SelectionAndFilterHelper sharedInstance] setTopSelection:object];
        [self refreshListOfShownAccountsAndFolders];
        [self.tableView reloadData];
    }

    if(object.isFolder)
        [[SelectionAndFilterHelper sharedInstance] setBottomSelection:object];

    for(NSIndexPath* indexPath in tableView.indexPathsForVisibleRows)
    {
        UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
        [cell setSelected:NO animated:YES];
    }

    return indexPath;
}


- (NSIndexPath*)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;

    OutlineObject* shownObject = [self objectAtIndex:row];

    if(![shownObject isKindOfClass:[OutlineObject class]])
    {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"SeparatorCell"];
        [cell setBackgroundColor:DARK_BLUE_COLOUR];
        return cell;
    }

    if(shownObject.isEmpty)
    {
        if(shownObject.showSeparator)
        {
            UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"DividerCell"];
            [cell setBackgroundColor:DARK_BLUE_COLOUR];
            return cell;
        }
        else
        {
            UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"SeparatorCell"];
            [cell setBackgroundColor:DARK_BLUE_COLOUR];
            return cell;
        }
    }
    
    if(shownObject.isAccount)
    {
        AccountCell* cell = [tableView dequeueReusableCellWithIdentifier:@"AccountCell" forIndexPath:indexPath];
        [[(AccountCell*)cell nameLabel] setText:shownObject.displayName];
        [(AccountCell*)cell setRepresentedObject:shownObject];
        [[(AccountCell*)cell accountImageView] setImage:shownObject.displayImage];
        return cell;
    }
    
    if(shownObject.isFolder)
    {
        FolderCell* cell = [tableView dequeueReusableCellWithIdentifier:@"FolderCell"];
        [[(FolderCell*)cell nameLabel] setText:shownObject.displayName];
        [[(FolderCell*)cell folderImageView] setImage:shownObject.displayImage];
        [(FolderCell*)cell setRepresentedObject:shownObject];
        NSInteger unreadCount = [shownObject unreadCount];
        [[(FolderCell*)cell detailLabel] setText:unreadCount>0?[NSString stringWithFormat:@"%ld", (long)unreadCount]:@""];
        return cell;
    }
    
    if(shownObject.isContact)
    {
        Contact* contact = shownObject.contact;
        ContactCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
        [[cell picView] setImage:[contact profilePic]];
        [[cell nameField] setText:[contact displayName]];
        [[cell detailLabel] setText:[[contact mostFrequentEmail] address]];
        return cell;
    }
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"SeparatorCell"];
    [cell setBackgroundColor:DARK_BLUE_COLOUR];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger contentCellHeight = 54;
    
    return contentCellHeight;
}

-(CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    if(REAL_HEADERS)
        return 30;
    else
        return 0;
}


- (void)showAddAccountSheet
{
    [self performSegueWithIdentifier:@"addAccount" sender:self];
}


#pragma mark - STATUS BAR

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


#endif



@end
