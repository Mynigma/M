//
//  MessagesController.m
//  Mynigma iOS
//
//  Created by Roman Priebe on 02/03/2013.
//  Copyright (c) 2013 Mynigma. All rights reserved.
//

#import "AppDelegate.h"
#import "Model.h"



#import <CoreData/CoreData.h>
#import "MessagesController.h"
#import "EmailMessage.h"
#import "MessageCell.h"
#import "IMAPAccountSetting.h"
#import "IMAPFolderSetting.h"
#import "IMAPAccount.h"
#import "ComposeController.h"
#import "AccountAndFolderListController.h"
#import "EmailMessage.h"
#import "DisplayMessageController.h"
#import "IMAPFolderSetting.h"
#import "EmailMessageController.h"
#import "JASidePanelController.h"
#import "EmailMessageInstance.h"
#import "EmailMessageData.h"
#import "IconListAndColourHelper.h"


#define TABLE_SIZE 100

@interface MessagesController ()

@end

@implementation MessagesController


- (void)viewDidLoad
{
    [super viewDidLoad];

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshTableContent:)
             forControlEvents:UIControlEventValueChanged];
    [self setRefreshControl:refreshControl];

    //[self.navigationController setNeedsStatusBarAppearanceUpdate];

    dateFormatter = [NSDateFormatter new];
    //[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    timeFormatter = [NSDateFormatter new];
    //[timeFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [timeFormatter setDateStyle:NSDateFormatterNoStyle];
    [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    [toolBar setHidden:YES];
    //[self.navigationItem setTitle:APPDELEGATE.titleBarString];

    [APPDELEGATE setMessagesController:self];

    numberOfMessagesToBeDisplayed = 50;
    
    if(APPDELEGATE.filterPredicate)
    {
        APPDELEGATE.displayedMessages = [[NSArray alloc] initWithArray:[APPDELEGATE.messages.fetchedObjects filteredArrayUsingPredicate:APPDELEGATE.filterPredicate]];
        //NSLog(@"Set %d messages! Predicate: %@",APPDELEGATE.displayedMessages.count,APPDELEGATE.filterPredicate);
    }
    else
    {
        //NSLog(@"Filter predicate is nil!");
        APPDELEGATE.displayedMessages = [NSMutableArray arrayWithArray:APPDELEGATE.messages.fetchedObjects];
    }
    
}

- (void)refreshTableContent:(id)sender
{
    NSSet* folders = [APPDELEGATE.emailMessageController allSelectedFolders];
    __block NSInteger counter = folders.count;
    for(IMAPFolderSetting* folderSetting in folders)
    {
        IMAPAccountSetting* accountSetting = folderSetting.inIMAPAccount;
        IMAPAccount* account = [MODEL accountForSettingID:accountSetting.objectID];
        if(!account)
        {
            counter--;
            continue;
        }
        /*
        [account downloadAnyNewMessageHeadersInFolder:folderSetting withCallBack:^(BOOL success) {
            counter--;
            if(counter==0)
                [(UIRefreshControl*)sender endRefreshing];
        }];*/
    }
    if(counter==0)
        [(UIRefreshControl*)sender endRefreshing];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [self refresh];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setBarTintColor:NAVBAR_COLOUR];
    self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    [self.navigationController.toolbar setBarTintColor:NAVBAR_COLOUR];
    [self.navigationController.toolbar setTintColor:[UIColor whiteColor]];

    [self.navigationController setToolbarHidden:YES];

    [APPDELEGATE updateFilters];
}


#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}


#pragma mark - Table View Data Source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MessageCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ShortMessageCell" forIndexPath:indexPath];

    [self configureCell:cell atIndexPath:indexPath];

    return cell;

    /*
    NSInteger index = indexPath.row;

    EmailMessage* message = [APPDELEGATE.emailMessageController messageAtIndex:index];

    if(!message)
    {
        if(index==[APPDELEGATE.emailMessageController numberOfMessages])
        {
            if([APPDELEGATE.emailMessageController moreToBeLoadedInSelectedFolder])
            {
                 [APPDELEGATE.emailMessageController loadMoreMessagesInSelectedFolder];
                    MessageCell* cell =

                    [cell.reloadingIndicator startAnimating];
                    [cell setMessage:nil];
                    NSString* folderStatus = [APPDELEGATE.emailMessageController folderString];

                    [cell.nameLabel setText:folderStatus];

                    return cell;
            }
            else
            {
                return [tableView dequeueReusableCellWithIdentifier:@"CoinLogoCell" forIndexPath:indexPath];
            }
        }

        return [tableView dequeueReusableCellWithIdentifier:@"CoinLogoCell" forIndexPath:indexPath];
    }

    MessageCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ShortMessageCell" forIndexPath:indexPath];
    [self configureCell:cell withMessage:(EmailMessage*)message];
    return cell;
     */
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    NSInteger numRows = [APPDELEGATE.emailMessageController numberOfMessages];

    numRows++;

    NSLog(@"%d rows in table view", numRows);
    
    return numRows;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row<[APPDELEGATE.emailMessageController numberOfMessages])
        return indexPath;
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
   if(APPDELEGATE.displayMessageController)
    {
        EmailMessageInstance* messageInstance = [APPDELEGATE.emailMessageController messageInstanceAtIndex:indexPath.row];
        if(messageInstance)
        {
            [APPDELEGATE.displayMessageController setDisplayedMessageInstance:messageInstance];
            [APPDELEGATE.displayMessageController refreshMessage];
        }
    }
    }
    else
        [self performSegueWithIdentifier:@"displayMessage" sender:self];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //[cell setBackgroundColor:[UIColor colorWithRed:239./255 green:241./255 blue:248./255 alpha:1]];
}




- (void)refreshMessage:(NSManagedObjectID*)messageID
{
    if(!messageID)
        return;
    [MODEL.mainObjectContext performBlock:^{
        EmailMessage* message = (EmailMessage*)[MODEL.mainObjectContext objectWithID:messageID];
        if(message)
        {
            NSInteger index = [APPDELEGATE.messages.fetchedObjects indexOfObject:message];
            if(index!=NSNotFound && index<TABLE_SIZE)
            {
                [self.tableView beginUpdates];
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView endUpdates];
            }
        }
    }];
}

#pragma mark - UI Elements

- (IBAction)menuButtonPressed:(id)sender
{
    JASidePanelController *root = (JASidePanelController *)[(UIWindow*)[(AppDelegate*)[[UIApplication sharedApplication]delegate] window] rootViewController];
    if([root respondsToSelector:@selector(showLeftPanelAnimated:)])
        [root showLeftPanelAnimated:YES];
}

- (IBAction)rightActionButtonPressed:(id)sender
{
    if(APPDELEGATE.displayMessageController)
    {
        if(!APPDELEGATE.composeController)
            [APPDELEGATE.displayMessageController performSegueWithIdentifier:@"composeNew" sender:self];
    }
    else
        [self performSegueWithIdentifier:@"composeNew" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"displayMessage"])
    {
        [self.navigationController.navigationBar.topItem setPrompt:nil];
        NSIndexPath* selectedIndexPath = [self.tableView indexPathForSelectedRow];
        EmailMessageInstance* selectedMessageInstance = [APPDELEGATE.emailMessageController messageInstanceAtIndex:selectedIndexPath.row];
        if(selectedMessageInstance)
            if([segue.destinationViewController isKindOfClass:[DisplayMessageController class]])
            {
                [(DisplayMessageController*)segue.destinationViewController setDisplayedMessageInstance:selectedMessageInstance];
            }
    }
    /*
    if([segue.identifier isEqualToString:@"replyToSegue"])
    {
        if([sender isKindOfClass:[MessageViewController class]])
            if([segue.destinationViewController isKindOfClass:[ComposeController class]])
            {
                [(ComposeController*)segue.destinationViewController startReplyToMessage:[(MessageViewController*)sender displayedMessage]];
            }
    }
    if([segue.identifier isEqualToString:@"replyToAllSegue"])
    {
        if([sender isKindOfClass:[MessageViewController class]])
            if([segue.destinationViewController isKindOfClass:[ComposeController class]])
            {
                [(ComposeController*)segue.destinationViewController startReplyAllToMessage:[(MessageViewController*)sender displayedMessage]];
            }
    }
    if([segue.identifier isEqualToString:@"forwardSegue"])
    {
        if([sender isKindOfClass:[MessageViewController class]])
            if([segue.destinationViewController isKindOfClass:[ComposeController class]])
            {
                [(ComposeController*)segue.destinationViewController startForwardOfMessage:[(MessageViewController*)sender displayedMessage]];
            }
    }
     */
}


- (void)replyToMessageInstance:(EmailMessageInstance*)messageInstance
{
    
}


- (void)replyAllToMessageInstance:(EmailMessageInstance*)messageInstance
{

}


- (void)forwardMessageInstance:(EmailMessageInstance*)messageInstance
{
    
}



- (BOOL)prefersStatusBarHidden
{
    return APPDELEGATE.hideTheStatusBar;
}




#pragma mark - Message List Filters

- (void)updateFiltersWithObject:(NSManagedObject*)object
{
    if(object && [object isKindOfClass:[IMAPAccountSetting class]])
    {
        [APPDELEGATE setTitleBarString:[(IMAPAccountSetting*)object displayName]];
        //NSLog(@"Account: %@",[(IMAPAccountSetting*)object displayName]);
        NSMutableSet* folders = [[(IMAPAccountSetting*)object folders] mutableCopy];
        if([(IMAPAccountSetting*)object outboxFolder])
            [folders addObject:[(IMAPAccountSetting*)object outboxFolder]];
        APPDELEGATE.filterPredicate = [NSPredicate predicateWithFormat:@"(inFolder in %@)",folders];
        [self refresh];
        return;
    }
    if(object && [object isKindOfClass:[IMAPFolderSetting class]])
    {
        [APPDELEGATE setTitleBarString:[(IMAPFolderSetting*)object displayName]];
        //NSLog(@"Folder: %@",[(IMAPFolderSetting*)object displayName]);
        APPDELEGATE.filterPredicate = [NSPredicate predicateWithFormat:@"(inFolder == %@)",object];
        [self refresh];
        return;
    }
    //if(!object)
    {
    [APPDELEGATE setTitleBarString:@"All Messages"];
    APPDELEGATE.filterPredicate = [NSPredicate predicateWithValue:YES];
    }
    [self refresh];
}

- (void)refresh
{
}




#pragma mark - Message Cell Formatting

- (void)configureCell:(MessageCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    EmailMessageInstance* messageInstance = [APPDELEGATE.emailMessageController messageInstanceAtIndex:indexPath.row];

    if(!messageInstance)
    {
        [cell.messageContainer setHidden:YES];
        if(indexPath.row == [APPDELEGATE.emailMessageController numberOfMessages])
        {
            if([APPDELEGATE.emailMessageController moreToBeLoadedInSelectedFolder])
            {
                [APPDELEGATE.emailMessageController loadMoreMessagesInSelectedFolder];

                [cell.feedBackContainer setHidden:NO];
                [cell.feedbackActivityIndicator startAnimating];
                [cell.feedbackActivityIndicator setHidden:NO];
                [cell.feedbackActivityIndicatorConstraint setPriority:1];
                [cell.coinView setHidden:YES];

                [cell.feedBackLabel setText:[APPDELEGATE.emailMessageController folderString]];
            }
            else
            {
                [cell.feedBackContainer setHidden:NO];
                [cell.feedbackActivityIndicator setHidden:YES];
                [cell.feedbackActivityIndicatorConstraint setPriority:999];
                [cell.coinView setHidden:YES];

                [cell.feedBackLabel setText:[APPDELEGATE.emailMessageController folderString]];
            }
        }
    }
    else
    {
    [cell.messageContainer setHidden:NO];
    [cell.coinView setHidden:YES];
    [cell.feedBackContainer setHidden:YES];

    [cell setMessageInstance:messageInstance];
    [cell.nameLabel setText:messageInstance.message.messageData.fromName];
    [cell.subjectLabel setText:messageInstance.message.messageData.subject];
    [cell.dateLabel setText:[self formattedDate:messageInstance.message.dateSent]];

        [cell setUpIcons];
    }
}

- (NSString*)formattedDate:(NSDate*)date
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:[NSDate date]];
    NSDate *today = [cal dateFromComponents:components];
    components = [cal components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:date];
    NSDate *otherDate = [cal dateFromComponents:components];

    if([otherDate isEqualToDate:today]) //today, so return something like "Today 9:30am"
    {
        return [NSString stringWithFormat:@"Today %@",[timeFormatter stringFromDate:date]];
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
            case 1: weekdayString = @"Sun";
                break;
            case 2: weekdayString = @"Mon";
                break;
            case 3: weekdayString = @"Tue";
                break;
            case 4: weekdayString = @"Wed";
                break;
            case 5: weekdayString = @"Thu";
                break;
            case 6: weekdayString = @"Fri";
                break;
            case 7: weekdayString = @"Sat";
                break;
        }
        return [NSString stringWithFormat:@"%@ %@",weekdayString,[timeFormatter stringFromDate:date]];

    }
    return [dateFormatter stringFromDate:date];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.000001;
}

@end
