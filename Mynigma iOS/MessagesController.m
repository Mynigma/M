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





#import "AppDelegate.h"




#import <CoreData/CoreData.h>
#import "MessagesController.h"
#import "EmailMessage+Category.h"
#import "MessageCell.h"
#import "IMAPAccountSetting+Category.h"
#import "IMAPFolderSetting+Category.h"
#import "IMAPAccount.h"
#import "ComposeController.h"
#import "EmailMessage+Category.h"
#import "DisplayMessageController.h"
#import "EmailMessageController.h"
#import "JASidePanelController.h"
#import "EmailMessageInstance+Category.h"
#import "EmailMessageData.h"
#import "IconListAndColourHelper.h"
#import "OutlineObject.h"
#import "GmailLabelSetting.h"
#import "AccountCheckManager.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "EmailMessageController.h"
#import "ComposeNewController.h"
#import "SelectionAndFilterHelper.h"
#import "ViewControllersManager.h"




#define TABLE_SIZE 100

static BOOL haveNewMessageToSelect = NO;

@interface MessagesController ()

@end

@implementation MessagesController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshTableContent:)
             forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    [self setRefreshControl:refreshControl];

    //set the images for the scope search bar
    id temp = [UISegmentedControl appearanceWhenContainedIn:[UISearchBar class], nil];

    UIImage * img = [UIImage imageNamed:@"unread16"];
    [temp setImage:img forSegmentAtIndex:1];

    img = [UIImage imageNamed:@"starred16"];
    [temp setImage:img forSegmentAtIndex:2];

    img = [UIImage imageNamed:@"attachment16"];
    [temp setImage:img forSegmentAtIndex:3];

    img = [UIImage imageNamed:@"lockClosed16"];
    [temp setImage:img forSegmentAtIndex:4];


    dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];

    timeFormatter = [NSDateFormatter new];
    [timeFormatter setDateStyle:NSDateFormatterNoStyle];
    [timeFormatter setTimeStyle:NSDateFormatterShortStyle];

    [[ViewControllersManager sharedInstance] setMessagesController:self];

    numberOfMessagesToBeDisplayed = 50;

    if([SelectionAndFilterHelper sharedInstance].filterPredicate)
    {
        APPDELEGATE.displayedMessages = [[NSArray alloc] initWithArray:[APPDELEGATE.messages.fetchedObjects filteredArrayUsingPredicate:[SelectionAndFilterHelper sharedInstance].filterPredicate]];
    }
    else
    {
        APPDELEGATE.displayedMessages = [NSMutableArray arrayWithArray:APPDELEGATE.messages.fetchedObjects];
    }
    
    [SelectionAndFilterHelper setSelectedMessages:@[]];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}

- (void)refreshTableContent:(id)sender
{
    [AccountCheckManager manualReloadWithProgressCallback:^(NSArray *namesOfFoldersStillBeingChecked, BOOL allSuccessful) {
        if(namesOfFoldersStillBeingChecked.count==0)
            [(UIRefreshControl*)sender endRefreshing];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.tableView.allowsMultipleSelectionDuringEditing = NO;

    [self.tableView setEditing:NO animated:NO];

    if(self.refreshControl.isRefreshing)
    {
        CGPoint offset = self.tableView.contentOffset;
        [self.refreshControl endRefreshing];
        [self.refreshControl beginRefreshing];
        self.tableView.contentOffset = offset;
    }

    [self.navigationController setToolbarHidden:YES];
    

    //need to clip to bounds - otherwise the shadow sometimes overlays the detail view
    [self.view setClipsToBounds:YES];

    //[APPDELEGATE updateFilters];
}


#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row;

    if(index>=0 && index<[SelectionAndFilterHelper sharedInstance].filteredMessages.count)
        return YES;

    return NO;
}

- (NSString*)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
    // NSLocalizedString(@"Move", @"Editing button");
}


//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//
//}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @[];
    
    UITableViewRowAction* firstAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Bin" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {

    }];

    [firstAction setBackgroundColor:[UIColor orangeColor]];

    UITableViewRowAction* secondAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Spam" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {

    }];

    [secondAction setBackgroundColor:[UIColor grayColor]];

    UITableViewRowAction* thirdAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"More" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {

    }];

    [thirdAction setBackgroundColor:[UIColor blueColor]];


    return @[/*firstAction, secondAction,*/ thirdAction];
}

#pragma mark - Table View Data Source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    EmailMessageInstance* messageInstance = (EmailMessageInstance*)[EmailMessageController messageObjectAtIndex:indexPath.row];

    if(!messageInstance)
    {
        if(indexPath.row == [[EmailMessageController sharedInstance] numberOfMessages])
        {
            if([[EmailMessageController sharedInstance] moreToBeLoadedInSelectedFolder])
            {
                [[EmailMessageController sharedInstance] loadMoreMessagesInSelectedFolder];

                MessageCell* cell = [tableView dequeueReusableCellWithIdentifier:@"LoadingMoreCell" forIndexPath:indexPath];

                [self configureLoadMoreCell:cell atIndexPath:indexPath];

                return cell;
            }
            else
            {
                MessageCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NoMoreCell" forIndexPath:indexPath];

                NSString* feedBackString = (indexPath.row==0)?NSLocalizedString(@"No messages to display", @"Feedback string in messages view"):NSLocalizedString(@"No more messages", @"Feedback string in messages view");

                [cell.feedBackLabel setText:feedBackString];

                return cell;
            }
        }
    }

    NSString* cellIdentifier = @"ShortMessageCell";

    MessageCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

    [self configureCell:cell atIndexPath:indexPath];

    UILongPressGestureRecognizer *longPressRecogniser = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [cell addGestureRecognizer:longPressRecogniser];

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numRows = [[EmailMessageController sharedInstance] numberOfMessages];

    numRows++;

    return numRows;
}

- (NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.tableView.isEditing)
        return indexPath;

    [ViewControllersManager removeMoveMessageOptionsIfNecessary];

    haveNewMessageToSelect = YES;
    
    return indexPath;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //remove from selected message instances list
    EmailMessageInstance* messageInstance = (EmailMessageInstance*)[EmailMessageController messageObjectAtIndex:indexPath.row];

    NSMutableArray* mutableSelectedMessageInstances = [[SelectionAndFilterHelper selectedMessages] mutableCopy];

    if(messageInstance && ![mutableSelectedMessageInstances containsObject:messageInstance])
    {
        [mutableSelectedMessageInstances addObject:messageInstance];
        [SelectionAndFilterHelper setSelectedMessages:mutableSelectedMessageInstances];
    }

    if(self.tableView.isEditing)
    {
        [[ViewControllersManager sharedInstance].moveMessageViewController selectionDidChange];
        return;
    }

    haveNewMessageToSelect = NO;

    //don't attempt to segue to emtpy messages
    if(!messageInstance)
        return;

    if([APPDELEGATE.window respondsToSelector:@selector(traitCollection)])
    {
        //iOS 8 : use size class to determine whether to display the message in detail view or to segue to another view
        if((APPDELEGATE.window.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular))
        {
            if(![messageInstance isEqual:[ViewControllersManager sharedInstance].displayMessageController.displayedMessageInstance])
                [self performSegueWithIdentifier:@"displayMessageRegular" sender:self];
        }
        else
        {
            if([messageInstance isKindOfClass:[EmailMessageInstance class]] && [messageInstance isInDraftsFolder])
                [self performSegueWithIdentifier:@"recomposeMessage" sender:self];
            else
                [self performSegueWithIdentifier:@"displayMessageCompact" sender:self];
            
            //deselect the row
            [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
        }
    }
    else
    {
        //iOS 7
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            if([ViewControllersManager sharedInstance].displayMessageController)
            {
                if(messageInstance && ![messageInstance isEqual:[ViewControllersManager sharedInstance].displayMessageController.displayedMessageInstance])
                {
                    [[ViewControllersManager sharedInstance].displayMessageController showMessageInstance:messageInstance];
                }
            }
        }
        else
        {
            EmailMessageInstance* messageInstance = (EmailMessageInstance*)[EmailMessageController messageObjectAtIndex:indexPath.row];
            if(messageInstance)
            {
                if([messageInstance isKindOfClass:[EmailMessageInstance class]] && [messageInstance.inFolder isDrafts])
                    [self performSegueWithIdentifier:@"recomposeMessage" sender:self];
                else
                    [self performSegueWithIdentifier:@"displayMessageCompact" sender:self];

                //deselect the row
                [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //remove from selected message instances list
    EmailMessageInstance* messageInstance = (EmailMessageInstance*)[EmailMessageController messageObjectAtIndex:indexPath.row];

    NSMutableArray* mutableSelectedMessageInstances = [[SelectionAndFilterHelper selectedMessages] mutableCopy];

    if(messageInstance && [mutableSelectedMessageInstances containsObject:messageInstance])
    {
        [mutableSelectedMessageInstances removeObject:messageInstance];
        [SelectionAndFilterHelper setSelectedMessages:mutableSelectedMessageInstances];
    }

    if(self.tableView.isEditing)
    {
        [[ViewControllersManager sharedInstance].moveMessageViewController selectionDidChange];
        return;
    }
    

    //    if(self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular)
    //    {
    //        //it's horizontally regular
    //        if(!haveNewMessageToSelect)
    //        {
    //            //there is no new message about to be selected, so find one!
    //            NSInteger proposedNewSelectionRow = indexPath.row;
    //
    //            if(proposedNewSelectionRow >= [self.tableView numberOfRowsInSection:0])
    //            {
    //                proposedNewSelectionRow--;
    //                if(proposedNewSelectionRow >= [self.tableView numberOfRowsInSection:0])
    //                {
    //                    proposedNewSelectionRow = 0;
    //
    //                    if(proposedNewSelectionRow >= [self.tableView numberOfRowsInSection:0])
    //                        return;
    //                }
    //            }
    //
    //            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:proposedNewSelectionRow inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
    //
    //        }
    //    }

}

- (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.tableView.isEditing)
        return indexPath;

    [ViewControllersManager removeMoveMessageOptionsIfNecessary];

    return indexPath;
}



//- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    //[cell setBackgroundColor:[UIColor colorWithRed:239./255 green:241./255 blue:248./255 alpha:1]];
//}




- (void)refreshMessage:(NSManagedObjectID*)messageID
{
    if(!messageID)
        return;


    [MAIN_CONTEXT performBlock:^{
        EmailMessage* message = (EmailMessage*)[MAIN_CONTEXT existingObjectWithID:messageID error:nil];
        if([message isKindOfClass:[EmailMessage class]])
        {
            for(EmailMessageInstance* instance in message.instances)
            {
                NSInteger index = [EmailMessageController indexForMessageObject:instance];
                if(index!=NSNotFound && index<[self.tableView numberOfRowsInSection:0])
                {
                    if(index<[self.tableView numberOfRowsInSection:0])
                    {
                        NSIndexPath *selectedRow = [self.tableView indexPathForSelectedRow];
                        [self.tableView beginUpdates];
                        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                        [self.tableView endUpdates];
                        if (selectedRow)
                        {
                            [self.tableView selectRowAtIndexPath:selectedRow animated:NO scrollPosition:UITableViewScrollPositionNone];
                        }
                    }
                }
            }
        }
    }];
}

- (void)refreshMessageInstance:(NSManagedObjectID*)messageID
{
    if(!messageID)
        return;
    
    
    [MAIN_CONTEXT performBlock:^{
        EmailMessageInstance* messageInstance = (EmailMessageInstance*)[MAIN_CONTEXT existingObjectWithID:messageID error:nil];
        if([messageInstance isKindOfClass:[EmailMessageInstance class]])
        {
                NSInteger index = [EmailMessageController indexForMessageObject:messageInstance];
                if(index!=NSNotFound && index<[self.tableView numberOfRowsInSection:0])
                {
                    if(index<[self.tableView numberOfRowsInSection:0])
                    {
                        NSIndexPath *selectedRow = [self.tableView indexPathForSelectedRow];
                        [self.tableView beginUpdates];
                        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                        [self.tableView endUpdates];
                        if (selectedRow)
                        {
                            [self.tableView selectRowAtIndexPath:selectedRow animated:NO scrollPosition:UITableViewScrollPositionNone];
                        }
                    }
                }
        }
    }];
}


#pragma mark - UI Elements

- (void)removeComposeNewButton
{
    NSMutableArray* toolbarItems = [self.navigationItem.rightBarButtonItems mutableCopy];

    if([toolbarItems containsObject:self.composeNewButton])
    {
        [toolbarItems removeObject:self.composeNewButton];
        [self.navigationItem setRightBarButtonItems:toolbarItems];
    }
}

- (void)addComposeNewButton
{
    NSMutableArray* toolbarItems = [self.navigationItem.rightBarButtonItems mutableCopy];

    if(self.composeNewButton && ![toolbarItems containsObject:self.composeNewButton])
    {
        [toolbarItems addObject:self.composeNewButton];
        [self.navigationItem setRightBarButtonItems:toolbarItems];
    }
}

- (IBAction)menuButtonPressed:(id)sender
{
    if ([ViewControllersManager isShowingMoveMessageOptions])
    {
        // do nothing 
    }
    else
    {

    //[ViewControllersManager removeMoveMessageOptionsIfNecessary];

    UISplitViewController* splitController = self.splitViewController;
        
    JASidePanelController* sidePanelController = (JASidePanelController *)splitController.viewControllers.firstObject;

    //needed for iOS 7 (iPhone 4)
    if(!sidePanelController)
    {
        UIViewController* rootController = APPDELEGATE.window.rootViewController;
        if([rootController isKindOfClass:[JASidePanelController class]])
            sidePanelController = (JASidePanelController*)rootController;
    }

    if([sidePanelController respondsToSelector:@selector(showLeftPanelAnimated:)])
        [sidePanelController showLeftPanelAnimated:YES];
    else
    {
        sidePanelController = (JASidePanelController *)splitController.viewControllers.lastObject;
        if([sidePanelController respondsToSelector:@selector(showLeftPanelAnimated:)])
            [sidePanelController showLeftPanelAnimated:YES];
    }
        
    }
}

- (IBAction)rightActionButtonPressed:(id)sender
{
    [ViewControllersManager removeMoveMessageOptionsIfNecessary];

    [self removeComposeNewButton];

    if([ViewControllersManager sharedInstance].displayMessageController)
    {
        if([AppDelegate isIPhone])
        {
            if(![ViewControllersManager sharedInstance].composeController)
                [[ViewControllersManager sharedInstance].displayMessageController performSegueWithIdentifier:@"composeNew" sender:self];
        }
        else
        {
            //            [UIView animateWithDuration:.4 animations:^{

            //            UISplitViewController* rootController = (UISplitViewController*)[self.view.window rootViewController];
            //
            //            if([rootController isKindOfClass:[UISplitViewController class]])
            //            {
            //                if([rootController respondsToSelector:@selector(setPreferredDisplayMode:)])
            //                    [rootController setPreferredDisplayMode:UISplitViewControllerDisplayModePrimaryHidden];
            //            }

            UIViewController* composeScreenController = [self.storyboard instantiateViewControllerWithIdentifier:@"composeNewController"];

            [self.view.window.rootViewController presentViewController:composeScreenController animated:YES completion:nil];

            //            }];
        }
    }
    else
        [self performSegueWithIdentifier:@"composeNew" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [ViewControllersManager removeMoveMessageOptionsIfNecessary];

    //replace segue
    if([segue.identifier isEqualToString:@"displayMessageRegular"])
    {
        [self.navigationController.navigationBar.topItem setPrompt:nil];

        NSIndexPath* selectedIndexPath = [self.tableView indexPathForSelectedRow];
        EmailMessageInstance* selectedMessageInstance = (EmailMessageInstance*)[EmailMessageController messageObjectAtIndex:selectedIndexPath.row];
        if(selectedMessageInstance)
        {
            if([segue.destinationViewController isKindOfClass:[UINavigationController class]])
                if([[(UINavigationController*)segue.destinationViewController topViewController] isKindOfClass:[DisplayMessageController class]])
                {
                    DisplayMessageController* displayMessageController = (DisplayMessageController*)[(UINavigationController*)segue.destinationViewController topViewController];
                    (void)displayMessageController.view;
                    [displayMessageController showMessageInstance:selectedMessageInstance];
                }
        }
    }

    //push segue
    if([segue.identifier isEqualToString:@"displayMessageCompact"])
    {
        [self.navigationController.navigationBar.topItem setPrompt:nil];

        NSIndexPath* selectedIndexPath = [self.tableView indexPathForSelectedRow];
        EmailMessageInstance* selectedMessageInstance = (EmailMessageInstance*)[EmailMessageController messageObjectAtIndex:selectedIndexPath.row];
        if(selectedMessageInstance)
            if([segue.destinationViewController isKindOfClass:[DisplayMessageController class]])
            {
                [self.navigationController setToolbarHidden:NO animated:YES];
                
                (void)[(DisplayMessageController*)segue.destinationViewController view];

                [(DisplayMessageController*)segue.destinationViewController showMessageInstance:selectedMessageInstance];
            }
    }

    if([segue.identifier isEqualToString:@"recomposeMessage"])
    {
        [self.navigationController.navigationBar.topItem setPrompt:nil];

        NSIndexPath* selectedIndexPath = [self.tableView indexPathForSelectedRow];
        EmailMessageInstance* selectedMessageInstance = (EmailMessageInstance*)[EmailMessageController messageObjectAtIndex:selectedIndexPath.row];
        if(selectedMessageInstance)
        {
            ComposeNewController* composeController = (ComposeNewController*)[(UINavigationController*)segue.destinationViewController topViewController];

            if([composeController isKindOfClass:[ComposeNewController class]])
            {
                (void)[composeController view];
                [(ComposeNewController*)composeController showDraftMessageInstance:selectedMessageInstance];
            }
        }
    }

    if([segue.identifier isEqualToString:@"composeFeedback"])
    {
        [self.navigationController.navigationBar.topItem setPrompt:nil];

        ComposeNewController* composeController = (ComposeNewController*)[(UINavigationController*)segue.destinationViewController topViewController];

        if([composeController isKindOfClass:[ComposeNewController class]])
        {
            (void)[composeController view];            
            [(ComposeNewController*)composeController showNewFeedbackMessageInstance];
        }
    }
}



- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if(self.tableView.isEditing)
        return NO;

    return YES;
}


#pragma mark - UIAction

- (IBAction)handleLongPress:(id)sender
{
    // Disable MOVE for iOS 7 due to unsolvable UI bugs
    if(![APPDELEGATE.window respondsToSelector:@selector(traitCollection)])
        return;
    
    if(![sender isKindOfClass:[UILongPressGestureRecognizer class]])
        return;

    UITableViewCell* cell = (UITableViewCell*)[(UILongPressGestureRecognizer*)sender view];

    if(![cell isKindOfClass:[UITableViewCell class]])
        return;

    NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];

    EmailMessageInstance* messageInstance = (EmailMessageInstance*)[EmailMessageController messageObjectAtIndex:indexPath.row];

    if(messageInstance && ![ViewControllersManager isShowingMoveMessageOptions])
    {
        if([[ViewControllersManager sharedInstance].messagesController isEditing])
        {
            //on the iPhone, the move message options are hidden when more messages are being selected...
            //don't do anything in this case
            return;
        }
            
        [SelectionAndFilterHelper setSelectedMessages:@[messageInstance]];
        [ViewControllersManager showMoveMessageOptions];
    }
}



#pragma mark - Message List Filters

- (void)updateFiltersWithObject:(NSManagedObject*)object
{
    if(object && [object isKindOfClass:[IMAPAccountSetting class]])
    {
        //        [APPDELEGATE setTitleBarString:[(IMAPAccountSetting*)object displayName]];
        //NSLog(@"Account: %@",[(IMAPAccountSetting*)object displayName]);
        NSMutableSet* folders = [[(IMAPAccountSetting*)object folders] mutableCopy];
        if([(IMAPAccountSetting*)object outboxFolder])
            [folders addObject:[(IMAPAccountSetting*)object outboxFolder]];
        [SelectionAndFilterHelper sharedInstance].filterPredicate = [NSPredicate predicateWithFormat:@"(inFolder in %@)",folders];
        //[self refresh];
        return;
    }
    if(object && [object isKindOfClass:[IMAPFolderSetting class]])
    {
        //        [APPDELEGATE setTitleBarString:[(IMAPFolderSetting*)object displayName]];
        //NSLog(@"Folder: %@",[(IMAPFolderSetting*)object displayName]);
        [SelectionAndFilterHelper sharedInstance].filterPredicate = [NSPredicate predicateWithFormat:@"(inFolder == %@)",object];
        //[self refresh];
        return;
    }
    //if(!object)
    {
        //    [APPDELEGATE setTitleBarString:NSLocalizedString(@"All Messages", @"Messages Controller")];
        [SelectionAndFilterHelper sharedInstance].filterPredicate = [NSPredicate predicateWithValue:YES];
    }
    //[self refresh];
}





#pragma mark - Message Cell Formatting

- (void)configureLoadMoreCell:(MessageCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    if(!cell.feedbackActivityIndicator.isAnimating)
        [cell.feedbackActivityIndicator startAnimating];

    NSSet* selectedFolders = [OutlineObject selectedFolderSettingsForSyncing];

    NSInteger totalCount = selectedFolders.count;

    NSInteger doneCount = 0;

    for(IMAPFolderSetting* folderSetting in selectedFolders)
    {
        if(![folderSetting isBackwardLoading])
        {
            doneCount++;
        }
    }

    NSString* feedbackLabelText = [NSString stringWithFormat:NSLocalizedString(@"Loaded %ld of %ld folders", @"Loading feedback label"), doneCount, totalCount];

    [cell.feedBackLabel setText:feedbackLabelText];
}


- (void)configureCell:(MessageCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    EmailMessageInstance* messageInstance = (EmailMessageInstance*)[EmailMessageController messageObjectAtIndex:indexPath.row];

    [cell.messageContainer setHidden:NO];
    [cell.coinView setHidden:YES];
    [cell.feedBackContainer setHidden:YES];

    if([messageInstance isFlagged])
    {
        UIImage* whiteImage = [UIImage imageNamed:@"starred16Template"];

        UIImage* yellowImage = [whiteImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

        [cell.starImageView setHighlightedImage:whiteImage];
        [cell.starImageView setImage:yellowImage];
    }
    else
    {
        [cell.starImageView setImage:nil];
        [cell.starImageView setHighlightedImage:nil];
    }


    [cell setMessageInstance:messageInstance];
    [cell.nameLabel setText:messageInstance.message.messageData.fromName];
    [cell.subjectLabel setText:messageInstance.message.messageData.subject];
    [cell.dateLabel setText:[self formattedDate:messageInstance.message.dateSent]];

    NSMutableString* previewString = [NSMutableString new];

    if(![messageInstance.inFolder isKindOfClass:[GmailLabelSetting class]] || ![(GmailLabelSetting*)messageInstance.inFolder allMailForAccount])
    {
        NSString* folderName = messageInstance.inFolder.displayName;
        if(folderName)
        {
            [previewString appendString:folderName];
            [previewString appendString:@" "];
        }
    }
    for(GmailLabelSetting* labelSetting in [messageInstance.hasLabels sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES]]])
    {
        [previewString appendString:labelSetting.displayName];
        [previewString appendString:@" "];
    }

    [cell.feedBackLabel setText:previewString];

    [cell setUpIcons];
    [cell setUpLockBox];
}

- (NSString*)formattedDate:(NSDate*)date
{
    if(!date)
        date = [NSDate date];

    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:[NSDate date]];
    NSDate *today = [cal dateFromComponents:components];
    components = [cal components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:date];
    NSDate *otherDate = [cal dateFromComponents:components];

    if([otherDate isEqualToDate:today]) //today, so return something like "Today 9:30am"
    {
        return [NSString stringWithFormat:NSLocalizedString(@"Today %@",@"Date <some date>"),[timeFormatter stringFromDate:date]];
    }
    /*if([otherDate isEqualToDate:[today dateByAddingTimeInterval:-24*60*60]]) //yesterday. return "Yesterday 10:46pm"
     {
     return [NSString stringWithFormat:@"Yesterday %@",[timeFormatter stringFromDate:date]];
     }*/
    if([date compare:[today dateByAddingTimeInterval:-5*24*60*60]]==NSOrderedDescending) //this week, so return "Wed 9:23pm"
    {
        NSDateComponents *weekdayComponents =[cal components:NSWeekdayCalendarUnit fromDate:date];

        NSInteger weekday = [weekdayComponents weekday];
        NSString* weekdayString = @"";
        switch(weekday)
        {
            case 1: weekdayString = NSLocalizedString(@"Sun",@"Sunday short");
                break;
            case 2: weekdayString = NSLocalizedString(@"Mon",@"Monday short");
                break;
            case 3: weekdayString = NSLocalizedString(@"Tue",@"Tuesday short");
                break;
            case 4: weekdayString = NSLocalizedString(@"Wed",@"Wednesday short");
                break;
            case 5: weekdayString = NSLocalizedString(@"Thu",@"Thursday short");
                break;
            case 6: weekdayString = NSLocalizedString(@"Fri",@"Friday short");
                break;
            case 7: weekdayString = NSLocalizedString(@"Sat",@"Saturday short");
                break;
        }
        return [NSString stringWithFormat:@"%@ %@",weekdayString,[timeFormatter stringFromDate:date]];

    }
    return [dateFormatter stringFromDate:date];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.;
}

- (void)refreshLoadMoreCell
{

    NSInteger indexOfLastRow = [[ViewControllersManager sharedInstance].messagesController.tableView numberOfRowsInSection:0]-1;

    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:indexOfLastRow inSection:0];

    if(indexOfLastRow>=0)
    {
        MessageCell* cell = (MessageCell*)[self.tableView cellForRowAtIndexPath:indexPath];

        if([[cell reuseIdentifier] isEqualToString:@"LoadMoreCell"])
        {
            [self configureLoadMoreCell:cell atIndexPath:indexPath];
        }
    }
}

- (BOOL)moveUpInMessagesList
{
    NSInteger currentSelection = self.tableView.indexPathForSelectedRow.row;

    currentSelection--;

    if(currentSelection >= 0 && currentSelection < [self.tableView numberOfRowsInSection:0])
    {
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:currentSelection inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];

        return YES;
    }

    return NO;
}

- (BOOL)moveDownInMessagesList
{
    NSInteger currentSelection = self.tableView.indexPathForSelectedRow.row;

    currentSelection++;

    if(currentSelection >= 0 && currentSelection < [self.tableView numberOfRowsInSection:0])
    {
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:currentSelection inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];

        return YES;
    }

    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}



#pragma mark - Select more mode

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [self.tableView setAllowsMultipleSelectionDuringEditing:YES];
    [self.tableView setAllowsSelectionDuringEditing:YES];

    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];

    if(!editing)
    {
        NSArray* selectedMessages = [SelectionAndFilterHelper selectedMessages];

        if(selectedMessages.count && [ViewControllersManager isHorizontallyCompact])
            [ViewControllersManager showMoveMessageOptions];

        self.navigationItem.rightBarButtonItem = self.composeNewButton;

        if(![ViewControllersManager isHorizontallyCompact])
            [ViewControllersManager removeMoveMessageOptionsIfNecessary];
    }
    else
    {
        //need a "Done" button only in the horizontally compact environment
        if([ViewControllersManager isHorizontallyCompact])
            self.navigationItem.rightBarButtonItem = self.editButtonItem;
    }
}

- (void)selectMessageInstances:(NSArray*)messageInstances
{
//    NSMutableArray* newSelectedIndexPaths = [NSMutableArray new];

    for(EmailMessageInstance* messageInstance in messageInstances)
    {
        NSInteger row = [EmailMessageController indexForMessageObject:messageInstance];
        if(row != NSNotFound)
        {
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:0];
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        }
    }
}


#pragma mark - Search bar

- (void)setSearchBarShown:(BOOL)shown animated:(BOOL)animated
{
    [UIView animateWithDuration:animated?.5:0 animations:^{
    
        [self.hideSearchBarContraint setPriority:shown?1:999];
        
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    } completion:^(BOOL completed){

        if(shown)
            [self.searchBar becomeFirstResponder];
    }];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [[SelectionAndFilterHelper sharedInstance] setSearchString:searchText];
    [SelectionAndFilterHelper updateFilters];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self.searchBar setText:@""];
    [self searchBar:self.searchBar textDidChange:@""];
    [self setSearchBarShown:NO animated:YES];
    [self.searchBar endEditing:YES];
    [[SelectionAndFilterHelper sharedInstance] setFilterIndex:0];
    [self searchBar:searchBar selectedScopeButtonIndexDidChange:0];
    [SelectionAndFilterHelper updateFilters];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    [[SelectionAndFilterHelper sharedInstance] setFilterIndex:selectedScope];
    [SelectionAndFilterHelper updateFilters];
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar endEditing:YES];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    UITextField *searchBarTextField = nil;
    for (UIView *subView in self.searchBar.subviews)
    {
        NSArray* subSubViews = subView.subviews;
        for(UIView* subSubView in subSubViews)
            if ([subSubView isKindOfClass:[UITextField class]])
            {
                searchBarTextField = (UITextField *)subSubView;
                break;
            }
    }
    searchBarTextField.enablesReturnKeyAutomatically = NO;
    searchBarTextField.returnKeyType = UIReturnKeyDone;
}

@end
