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




#import "MessageViewController.h"
#import "ShowAllRecipientsCell.h"
#import "Recipient.h"
#import "EmailContactDetail.h"
#import "RecipientCell.h"
#import "Contact.h"
#import "ABContactDetail.h"
#import "ShowMessageCell.h"
#import "EmailMessage.h"
#import "MynigmaMessage.h"
#import "EmailRecipient.h"
#import "ComposeController.h"
#import "TextEntryCell.h"
#import "TITokenField.h"
#import "LoadingCell.h"
#import "MessagesController.h"
#import "EmailMessageData.h"
#import "EmailMessageInstance.h"
#import "AddressDataHelper.h"
#import "ViewControllersManager.h"




@interface MessageViewController ()

@end

@implementation MessageViewController

@synthesize displayedMessageInstance;
@synthesize recipientsExpanded;
@synthesize replyButton;

@synthesize toRecipients;
@synthesize ccRecipients;
@synthesize bccRecipients;
@synthesize fromRecipients;
@synthesize replyToRecipients;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    if(displayedMessageInstance.message.messageData)
    {
        if(displayedMessageInstance.message.messageData.fromName && displayedMessageInstance.message.messageData.fromName.length>0)
            [self.navigationItem setTitle:displayedMessageInstance.message.messageData.fromName];
        else
            [self.navigationItem setTitle:@"Message"];
    }
    else
        [self.navigationItem setTitle:@"New message"];
    NSData* addressData = displayedMessageInstance.message.messageData.addressData;

    NSArray* recArray = [AddressDataHelper emailRecipientsForAddressData:addressData];

    NSMutableArray* recipientsArray = [NSMutableArray new];
    if(recArray)
    {
        NSMutableArray* newToArray = [NSMutableArray new];
        NSMutableArray* newCcArray = [NSMutableArray new];
        NSMutableArray* newBccArray = [NSMutableArray new];
        NSMutableArray* newFromArray = [NSMutableArray new];
        NSMutableArray* newReplyToArray = [NSMutableArray new];

        for(EmailRecipient* emailRecipient in recArray)
        {
            NSInteger type = [emailRecipient type];
            if(type==TYPE_TO || type==TYPE_CC || type==TYPE_BCC)
            {
                //Recipient* recipient = [[Recipient alloc] initWithEmail:emailRecipient.email andName:emailRecipient.name];
                //[recipient setType:type];
                [recipientsArray addObject:emailRecipient];
            }
            switch(type)
            {
                    case TYPE_TO:
                    [newToArray addObject:emailRecipient];
                    break;
                    case TYPE_CC:
                    [newCcArray addObject:emailRecipient];
                    break;
                    case TYPE_BCC:
                    [newBccArray addObject:emailRecipient];
                    break;
                    case TYPE_FROM:
                    [newFromArray addObject:emailRecipient];
                    break;
                    case TYPE_REPLY_TO:
                    [newReplyToArray addObject:emailRecipient];
                    break;
                    default:
                    break;
            }
        }
        [self setToRecipients:newToArray];
        [self setCcRecipients:newCcArray];
        [self setBccRecipients:newBccArray];
        [self setFromRecipients:newFromArray];
        [self setReplyToRecipients:newReplyToArray];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 2; //subject and body

    if(fromRecipients.count>0)
        numberOfRows++;
    if(replyToRecipients.count>0)
        numberOfRows++;
    if(toRecipients.count>0)
        numberOfRows++;
    if(ccRecipients.count>0)
        numberOfRows++;
    if(bccRecipients.count>0)
        numberOfRows++;

    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    if(fromRecipients.count>0)
    {
        if(row==0)
        {
            TextEntryCell* recCell = [self.tableView dequeueReusableCellWithIdentifier:@"RecipientCell" forIndexPath:indexPath];
            [recCell.tokenView.tokenField setUserInteractionEnabled:NO];
            [recCell.tokenView.tokenField removeAllTokens];
            for(EmailRecipient* emailRec in fromRecipients)
                [recCell.tokenView.tokenField addTokenWithTitle:[emailRec displayString] representedObject:emailRec];
            [recCell.tokenView.tokenField setPromptText:NSLocalizedString(@"From:",@"From lable (sender)")];
            [recCell.tokenView.tokenField setDelegate:(id<TITokenFieldDelegate>)self];
            [recCell.tokenView setDelegate:self];
            return recCell;
        }
        else
            row--;
    }
    
    if(replyToRecipients.count>0)
    {
        if(row==0)
        {
            TextEntryCell* recCell = [self.tableView dequeueReusableCellWithIdentifier:@"RecipientCell" forIndexPath:indexPath];
            [recCell.tokenView.tokenField setUserInteractionEnabled:NO];
            [recCell.tokenView.tokenField removeAllTokens];
            for(EmailRecipient* emailRec in replyToRecipients)
                [recCell.tokenView.tokenField addTokenWithTitle:[emailRec displayString] representedObject:emailRec];
            [recCell.tokenView.tokenField setPromptText:NSLocalizedString(@"Reply To:",@"Reply To lable (sender)")];
            [recCell.tokenView.tokenField setDelegate:(id<TITokenFieldDelegate>)self];
            [recCell.tokenView setDelegate:self];
            return recCell;
        }
        else
            row--;
    }
    if(toRecipients.count>0)
    {
        if(row==0)
        {
            TextEntryCell* recCell = [self.tableView dequeueReusableCellWithIdentifier:@"RecipientCell" forIndexPath:indexPath];
            [recCell.tokenView.tokenField setUserInteractionEnabled:NO];
            [recCell.tokenView.tokenField removeAllTokens];
            for(EmailRecipient* emailRec in toRecipients)
                [recCell.tokenView.tokenField addTokenWithTitle:[emailRec displayString] representedObject:emailRec];
            [recCell.tokenView.tokenField setPromptText:NSLocalizedString(@"To:",@"To lable (recipient)")];
            [recCell.tokenView.tokenField setDelegate:(id<TITokenFieldDelegate>)self];
            [recCell.tokenView setDelegate:self];
            return recCell;
        }
        else
            row--;
    }
    if(ccRecipients.count>0)
    {
        if(row==0)
        {
            TextEntryCell* recCell = [self.tableView dequeueReusableCellWithIdentifier:@"RecipientCell" forIndexPath:indexPath];
            [recCell.tokenView.tokenField setUserInteractionEnabled:NO];
            [recCell.tokenView.tokenField removeAllTokens];
            for(EmailRecipient* emailRec in ccRecipients)
                [recCell.tokenView.tokenField addTokenWithTitle:[emailRec displayString] representedObject:emailRec];
            [recCell.tokenView.tokenField setPromptText:NSLocalizedString(@"Cc:",@"Cc lable (recipient)")];
            [recCell.tokenView.tokenField setDelegate:(id<TITokenFieldDelegate>)self];
            [recCell.tokenView setDelegate:self];
            return recCell;
        }
        else
            row--;
    }
    if(bccRecipients.count>0)
    {
        if(row==0)
        {
            TextEntryCell* recCell = [self.tableView dequeueReusableCellWithIdentifier:@"RecipientCell" forIndexPath:indexPath];
            [recCell.tokenView.tokenField setUserInteractionEnabled:NO];
            [recCell.tokenView.tokenField removeAllTokens];
            for(EmailRecipient* emailRec in bccRecipients)
                [recCell.tokenView.tokenField addTokenWithTitle:[emailRec displayString] representedObject:emailRec];
            [recCell.tokenView.tokenField setPromptText:NSLocalizedString(@"Bcc:",@"Bcc lable (recipient)")];
            [recCell.tokenView.tokenField setDelegate:(id<TITokenFieldDelegate>)self];
            [recCell.tokenView setDelegate:self];
            return recCell;
        }
        else
            row--;
    }

    if(row==0)
    {
        TextEntryCell* subjectCell = [tableView dequeueReusableCellWithIdentifier:@"SubjectCell" forIndexPath:indexPath];

        [subjectCell.textEntryField setText:displayedMessageInstance.message.messageData.subject?displayedMessageInstance.message.messageData.subject:@""];
        return subjectCell;
    }

    NSString* bodyString = displayedMessageInstance.message.messageData.htmlBody;

    if(!bodyString || bodyString.length==0)
        bodyString = displayedMessageInstance.message.messageData.body;

    if(!bodyString)
    {
        LoadingCell* loadingCell = [tableView dequeueReusableCellWithIdentifier:@"LoadingCell" forIndexPath:indexPath];
        [loadingCell.activityIndicator startAnimating];
        return loadingCell;
    }
    ShowMessageCell* showMessageCell = (ShowMessageCell*)[tableView dequeueReusableCellWithIdentifier:@"ShowMessageCell"];
    
    [showMessageCell.bodyView.scrollView setBounces:NO];
    [showMessageCell.bodyView.scrollView setZoomScale:1];

    [showMessageCell.bodyView loadHTMLString:[self cleanUpReceivedHtmlBodyString:bodyString] baseURL:nil];
    return showMessageCell;
}

- (NSString*)cleanUpReceivedHtmlBodyString:(NSString*)bodyString
{
    NSMutableString* newString = [NSMutableString stringWithString:bodyString];

    //delete any html and body tags

    

    return newString;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    if(fromRecipients.count>0)
    {
        if(row==0)
        {
            return 35;
        }
        else
            row--;
    }

    if(replyToRecipients.count>0)
    {
        if(row==0)
        {
            return 35;
        }
        else
            row--;
    }
    if(toRecipients.count>0)
    {
        if(row==0)
        {
            return 35;
        }
        else
            row--;
    }
    if(ccRecipients.count>0)
    {
        if(row==0)
        {
            return 35;
        }
        else
            row--;
    }
    if(bccRecipients.count>0)
    {
        if(row==0)
        {
            return 35;
        }
        else
            row--;
    }

    if(row==0)
    {
        return 35;
    }
    
    if(row==1)
        return shownMessageHeight+66>350?shownMessageHeight+66:350;

    return 3000;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    
    CGSize contentSize = webView.scrollView.contentSize;
    CGSize viewSize = self.view.bounds.size;
    
    float rw = viewSize.width / contentSize.width;
    if(displayedMessageInstance.message.messageData.hasImages.boolValue)
        webView.scrollView.zoomScale = rw;
    
    CGRect frame = webView.frame;
    frame.size.height = 1;
    frame.size.width = viewSize.width;
    [webView setFrame:frame];
    [webView sizeToFit];
    if(shownMessageHeight!=webView.frame.size.height)
    {
        shownMessageHeight = webView.frame.size.height;
        [self.tableView reloadData];
    }
    
    //NSLog(@"Did finish load");
}

- (IBAction)replyButton:(id)sender
{
    //REPLY
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Reply", @"Reply to all", @"Forward", nil];
    [actionSheet showFromBarButtonItem:replyButton animated:YES];
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch(buttonIndex)
    {
        case 0:
        {
            [self.navigationController popViewControllerAnimated:NO];
            [[ViewControllersManager sharedInstance].messagesController performSegueWithIdentifier:@"replyToSegue" sender:self];
            break;
        }
        case 1:
        {
            [self.navigationController popViewControllerAnimated:NO];
            [[ViewControllersManager sharedInstance].messagesController performSegueWithIdentifier:@"replyToAllSegue" sender:self];
            break;
        }
        case 2:
        {
            [self.navigationController popViewControllerAnimated:NO];
            [[ViewControllersManager sharedInstance].messagesController performSegueWithIdentifier:@"forwardSegue" sender:self];
            break;
        }
    }
}




@end
