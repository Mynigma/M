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
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "ComposeController.h"
#import "ContactSuggestions.h"
#import "ComposeBodyCell.h"
#import "RecipientCell.h"
#import "Recipient.h"
#import <QuartzCore/QuartzCore.h>
#import "TextEntryCell.h"
#import "ShowMessageCell.h"
#import "MynigmaMessage.h"
#import "EmailMessage.h"
#import <MailCore/MailCore.h>
#import "EmailRecipient.h"
#import "ABContactDetail.h"
#import "ShowAllRecipientsCell.h"
#import "IMAPFolderSetting.h"
#import "IMAPAccountSetting.h"
#import "IMAPAccount.h"
#import "UserSettings.h"
#import "TITokenField.h"
#import "EmailMessageData.h"
#import "EmailMessageInstance.h"
#import "IconListAndColourHelper.h"
#import "EmailMessageInstance.h"


@interface ComposeController ()

@end

@implementation ComposeController

@synthesize composeRecipients;
@synthesize sendButton;
@synthesize cancelButton;
@synthesize composeTableView;
@synthesize recipientsExpanded;
@synthesize isDirty;
@synthesize showExtraFields;

@synthesize toFieldHeight;
@synthesize ccFieldHeight;
@synthesize bccFieldHeight;

@synthesize toField;
@synthesize ccField;
@synthesize bccField;

@synthesize toRecipients;
@synthesize ccRecipients;
@synthesize bccRecipients;
@synthesize replyToRecipient;
@synthesize fromRecipient;

@synthesize keyBoardDistanceConstraint;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        shownMessageHeight = 386;
    }
    return self;
}

- (void)viewDidLoad
{
    toFieldHeight = 43;
    ccFieldHeight = 43;
    bccFieldHeight = 43;

    keyboardShown = NO;

    [super viewDidLoad];
    //APPDELEGATE.contactSuggestions = [ContactSuggestions new];
    textViewForCalculatingHeight = [[UITextView alloc] initWithFrame:CGRectMake(0,0,320,3000)];

    keyboardHeight = 180;
    composeRecipients = [NSMutableArray new];
    //[self.navigationController.toolbar setTintColor:[UIColor colorWithRed:0 green:23./255 blue:100./255 alpha:1]];
    
    //[self.navigationController setToolbarHidden:NO];
    currentlyEditing = NO;

    //[APPDELEGATE setComposeController:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector (keyboardDidShow:)
                                                 name: UIKeyboardDidShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector (keyboardWillHide:)
                                                 name: UIKeyboardWillHideNotification object:nil];

    [self setCorrectColour];
    keyboardVisible = NO;
    [self refresh];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)swipeLeft:(id)sender
{
    //[self.tabBarController setSelectedIndex:4];
    /*UIPanGestureRecognizer* recognizer = sender;
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        startLocation = [recognizer locationInView:self.view];
        NSLog(@"Start: %f",startLocation.x);
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint stopLocation = [recognizer locationInView:self.view];
        NSLog(@"Stop: %f",stopLocation.x);
        CGFloat dx = stopLocation.x - startLocation.x;
        if(dx>200)
            [self.tabBarController setSelectedIndex:4];
        NSLog(@"left: %f",dx);
    }*/
}

- (IBAction)swipeRight:(UIPanGestureRecognizer *)sender
{
    //[self.tabBarController setSelectedIndex:2];
/*    UIPanGestureRecognizer* recognizer = sender;
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        startLocation = [recognizer locationInView:self.view];
        NSLog(@"Start: %f",startLocation.x);
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint stopLocation = [recognizer locationInView:self.view];
        NSLog(@"Stop: %f",stopLocation.x);
        CGFloat dx = stopLocation.x - startLocation.x;
        if(dx<-200)
            [self.tabBarController setSelectedIndex:2];
        NSLog(@"right: %f",dx);
    }*/
}

- (IBAction)tap:(id)sender
{
    [self.view endEditing:YES];
}

- (void)keyboardDidShow: (NSNotification *)aNotification
{
    NSDictionary* userInfo = [aNotification userInfo];
    
    CGRect keyboardEndFrame;
        
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];

    CGRect newKbRect = [self.view.window convertRect:keyboardEndFrame toView:self.view];


    keyboardHeight = newKbRect.size.height;


    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self.tableView numberOfRowsInSection:0] inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    keyboardShown = YES;
    [self.tableView endUpdates];
}

- (void)keyboardWillHide: (NSNotification *)aNotification
{
    /*NSDictionary* userInfo = [aNotification userInfo];
    
    CGRect keyboardEndFrame;
    
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    
    keyboardHeight = keyboardEndFrame.size.height;*/

    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self.tableView numberOfRowsInSection:0]-1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    keyboardShown = NO;
    [self.tableView endUpdates];

}




- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    if(row==0)
    {
        TextEntryCell* cell = [tableView dequeueReusableCellWithIdentifier:@"AddRecipientCell"];
        [[cell expandButton] setHidden:showExtraFields];
        [cell.tokenView.tokenField setPromptText:@"To:"];
        [cell.tokenView.tokenField setResultsModeEnabled:NO];
        [cell.tokenView.tokenField setDelegate:(id<TITokenFieldDelegate>)self];
        [cell.tokenView setDelegate:self];
        [self setToField:cell.tokenView.tokenField];
        [cell.tokenView.tokenField removeAllTokens];
        for(Recipient* rec in toRecipients)
            [cell.tokenView.tokenField addTokenWithTitle:[rec displayName] representedObject:rec];
        return cell;
    }

    if(showExtraFields)
        switch(row)
    {
            case 1:
        {
            TextEntryCell* cell = [tableView dequeueReusableCellWithIdentifier:@"AddRecipientCell"];
            [[cell expandButton] setHidden:YES];
            [cell.tokenView.tokenField setPromptText:@"Cc:"];
            [cell.tokenView.tokenField setResultsModeEnabled:NO];
            [cell.tokenView.tokenField setDelegate:(id<TITokenFieldDelegate>)self];
            [cell.tokenView setDelegate:self];
            [self setCcField:cell.tokenView.tokenField];
            [cell.tokenView.tokenField removeAllTokens];
            for(Recipient* rec in ccRecipients)
                [cell.tokenView.tokenField addTokenWithTitle:[rec displayName] representedObject:rec];
            return cell;
        }
case 2:
        {
            TextEntryCell* cell = [tableView dequeueReusableCellWithIdentifier:@"AddRecipientCell"];
            [[cell expandButton] setHidden:YES];
            [cell.tokenView.tokenField setPromptText:@"Bcc:"];
            [cell.tokenView.tokenField setResultsModeEnabled:NO];
            [cell.tokenView.tokenField setDelegate:(id<TITokenFieldDelegate>)self];
            [cell.tokenView setDelegate:self];
            [self setBccField:cell.tokenView.tokenField];
            return cell;
        }
case 3:
        {
            TextEntryCell* cell = [tableView dequeueReusableCellWithIdentifier:@"AddRecipientCell"];
            [[cell expandButton] setHidden:YES];
            [cell.tokenView.tokenField setPromptText:@"Reply to:"];
            [cell.tokenView.tokenField setResultsModeEnabled:NO];
            [cell.tokenView.tokenField setDelegate:(id<TITokenFieldDelegate>)self];
            [cell.tokenView setDelegate:self];
            [cell.tokenView.tokenField removeAllTokens];
            for(Recipient* rec in bccRecipients)
                [cell.tokenView.tokenField addTokenWithTitle:[rec displayName] representedObject:rec];
            return cell;
        }
    case 4:
        {
         TextEntryCell* subjectCell = [tableView dequeueReusableCellWithIdentifier:@"SubjectCell"];
            [subjectCell.textEntryField setText:composeSubject?composeSubject:@""];
            return subjectCell;
        }
    case 5:
        {
            ComposeBodyCell* composeCell = [tableView dequeueReusableCellWithIdentifier:@"ComposeCell"];
            [composeCell.composeBodyView loadHTMLString:composeHtml?composeHtml:@"<html><body><div id=\"content\" contenteditable=\"true\" style=\"font-family: Helvetica\"></div></body></html>" baseURL:nil];
            [composeCell.composeBodyView.scrollView setScrollEnabled:NO];
            [composeCell.composeBodyView.scrollView setShowsHorizontalScrollIndicator:NO];
            [composeCell.composeBodyView.scrollView setShowsVerticalScrollIndicator:NO];

            UITapGestureRecognizer* singleTap=[[UITapGestureRecognizer
                                                alloc]initWithTarget:self action:@selector(handleSingleTap:)];
            singleTap.numberOfTouchesRequired=1;
            singleTap.delegate = self;
            [composeCell.composeBodyView addGestureRecognizer:singleTap];

            return composeCell;
        }
    case 6:
            return [tableView dequeueReusableCellWithIdentifier:@"EmptyCell"];
    default:
    NSLog(@"Too many cells in table view!!!!");
    }
    else
        switch(row)
    {
        case 1:
        {
            TextEntryCell* subjectCell = [tableView dequeueReusableCellWithIdentifier:@"SubjectCell"];
            [subjectCell.textEntryField setText:composeSubject?composeSubject:@""];
            return subjectCell;
        }
        case 2:
        {
            ComposeBodyCell* composeCell = [tableView dequeueReusableCellWithIdentifier:@"ComposeCell"];
            [composeCell.composeBodyView loadHTMLString:composeHtml?composeHtml:@"<html><body><div id=\"content\" contenteditable=\"true\" style=\"font-family: Helvetica\"></div></body></html>" baseURL:nil];
            [composeCell.composeBodyView.scrollView setScrollEnabled:NO];
            [composeCell.composeBodyView.scrollView setShowsHorizontalScrollIndicator:NO];
            [composeCell.composeBodyView.scrollView setShowsVerticalScrollIndicator:NO];

            UITapGestureRecognizer* singleTap=[[UITapGestureRecognizer
                                                alloc]initWithTarget:self action:@selector(handleSingleTap:)];
            singleTap.numberOfTouchesRequired=1;
            singleTap.delegate = self;
            [composeCell.composeBodyView addGestureRecognizer:singleTap];

            return composeCell;
        }
        case 3:
            return [tableView dequeueReusableCellWithIdentifier:@"EmptyCell"];
        default:
            NSLog(@"Too many cells in table view!!!!");
    }

    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3 + (showExtraFields?3:0) + (keyboardShown?1:0);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row==0)
        return toFieldHeight+1;

    if(showExtraFields && indexPath.row==1)
        return ccFieldHeight+1;

    if(showExtraFields && indexPath.row==2)
        return bccFieldHeight+1;

    if(indexPath.row<(2+(showExtraFields?3:0)))
        return 36;

    if(keyboardShown && indexPath.row==2+(showExtraFields?3:0)+(keyboardShown?1:0))
        return keyboardHeight;

    CGFloat proposedBodyHeight = self.view.frame.size.height-toFieldHeight-1-(showExtraFields?(ccFieldHeight+1+bccFieldHeight+1):0)-36;

    if(proposedBodyHeight>300)
        return proposedBodyHeight;
    else
        return 300;
}



- (void)setCorrectSendButtonColour
{
    /*
    if([(RightMenuNavigationController*)self.navigationController contentController])
    {
    CALayer* layer = [(RightMenuNavigationController*)self.navigationController contentController].view.layer;
    layer.shadowColor = [UIColor colorWithRed:0 green:100/255. blue:0 alpha:1].CGColor;
    layer.shadowOpacity = 0.3;
    }
     */
    //[sendButton setTintColor:[UIColor colorWithRed:200/255. green:100/255. blue:100/255. alpha:1]];
    //[sendButton setTintColor:[UIColor colorWithRed:100/255. green:200/255. blue:100/255. alpha:1]];
    //[self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:0 green:100/255. blue:0 alpha:1]];
    //[self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:100/255. green:0 blue:0 alpha:1]];
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{

    if([textField isKindOfClass:[TITokenField class]])
    {
    NSMutableString* completeString = [NSMutableString stringWithString:[textField.attributedText string]?[textField.attributedText string]:@""];
    [completeString replaceCharactersInRange:range withString:string];
    NSString* partialString = [completeString substringWithRange:NSMakeRange(0,range.location+string.length)];
    NSString* suggestion = [APPDELEGATE.contactSuggestions getSuggestionForPartialString:partialString];
    NSMutableAttributedString* newText = [[NSMutableAttributedString alloc] initWithString:partialString?partialString:@"" attributes:@{NSForegroundColorAttributeName:[UIColor blackColor], NSFontAttributeName:[UIFont systemFontOfSize:FONT_SIZE]}];
    [newText appendAttributedString:[[NSAttributedString alloc] initWithString:suggestion?suggestion:@"" attributes:@{NSForegroundColorAttributeName:[UIColor grayColor],NSFontAttributeName:[UIFont systemFontOfSize:FONT_SIZE]}]];
    [textField setAttributedText:newText];
    UITextPosition *beginningPosition = textField.beginningOfDocument;
    UITextPosition *newCaretPosition = [textField positionFromPosition:beginningPosition offset:partialString.length];
    UITextRange *newRange = [textField textRangeFromPosition:newCaretPosition toPosition:newCaretPosition];
    [textField setSelectedTextRange:newRange];
    
    return NO;
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if(textField.tag==12)
    {
        composeSubject = textField.text;

        UITableViewCell* cell = [composeTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2+(showExtraFields?3:0) inSection:0]];
        if([cell isKindOfClass:[ComposeBodyCell class]])
        {
            [[(ComposeBodyCell*)cell composeBodyView] setKeyboardDisplayRequiresUserAction:NO];
            [[(ComposeBodyCell*)cell composeBodyView] stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"content\").focus();"];
            [composeTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:2+(showExtraFields?3:0) inSection:0]
                             atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
        return NO;
    }

    if([textField isKindOfClass:[TITokenField class]])
    {

        //THIS DOES NOT WORK - NEED TO PRIZE APART CASES WHERE THE TOKEN FIELD IS ADDING A TOKEN FROM RETURNS WITH NO TEXT ENTERED!

        NSArray* enteredTokens = [textField.text componentsSeparatedByCharactersInSet:[(TITokenField*)textField tokenizingCharacters]];
        NSString* lastBit = [enteredTokens objectAtIndex:enteredTokens.count-1];
        if(lastBit.length<=1)
        {
            UITableViewCell* cell = (UITableViewCell*)textField.superview.superview.superview.superview;
            if([cell isKindOfClass:[UITableViewCell class]])
            {
                NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
                TextEntryCell* nextCell = (TextEntryCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row+1 inSection:0]];
                [nextCell.tokenView becomeFirstResponder];
                [nextCell.textEntryField becomeFirstResponder];
            }
        }
    }

    /*
    NSManagedObjectID* suggestedID = [APPDELEGATE.contactSuggestions suggestionObjectIDforPartialString:typedString];
    if(suggestedID)
    {
        NSObject* object = [APPDELEGATE.mainObjectContext objectWithID:suggestedID];
        if(object && [object isKindOfClass:[Contact class]])
        {
            Recipient* rec = [[Recipient alloc] initWithContact:(Contact*)object];
            [composeRecipients addObject:rec];
            //index at which the new contact will be inserted
            NSInteger index = [composeRecipients count]-1;
            [composeTableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
            [textField setText:@""];
            [textField becomeFirstResponder];
        }
        if(object && [object isKindOfClass:[EmailContactDetail class]])
        {
            Recipient* rec = [[Recipient alloc] initWithEmailContactDetail:(EmailContactDetail*)object];
            [composeRecipients addObject:rec];
            [composeTableView reloadData];
            [textField setText:@""];
            [textField becomeFirstResponder];
        }
    }
    else
    {
        Recipient* rec = [[Recipient alloc] initWithEmail:typedString andName:typedString];
        [composeRecipients addObject:rec];
        [composeTableView reloadData];
        [textField setText:@""];
        [textField becomeFirstResponder];
    }*/
    return NO;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    composedText = textView.attributedText;
    [composeTableView beginUpdates];
    [composeTableView endUpdates];
}

- (IBAction)backButton:(id)sender
{
    /*
    composedText = [NSAttributedString new];
    composeHtml = nil;
    [self.navigationItem setTitle:@"New message"];
    for(NSInteger index = composeRecipients.count;index<composeRecipients.count+3;index++)
    {
    UITableViewCell* cell = [composeTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    
    if(cell && [cell isKindOfClass:[ComposeBodyCell class]])
    {
        //[[(ComposeBodyCell*)cell composeBodyView] setText:@""];
    }
    if(cell && [cell isKindOfClass:[TextEntryCell class]])
    {
        [[(TextEntryCell*)cell textEntryField] setText:@""];
    }
    }
    [self setComposeRecipients:[NSMutableArray new]];
    [composeTableView reloadData];
     */

    /*SASlideMenuRootViewController *root = (SASlideMenuRootViewController *)[(UIWindow*)[(AppDelegate*)[[UIApplication sharedApplication]delegate] window] rootViewController];
    [root doSlideIn:nil];*/
    [self.navigationController.navigationBar setBackgroundColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor blackColor]}];
    //[self dismissViewControllerAnimated:YES completion:^{ }];
    [self.navigationController setToolbarHidden:YES animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)displayMessage:(EmailMessage*)message
{
    /*
    APPDELEGATE.selectedMessage = message;
    NSData* addressData = APPDELEGATE.selectedMessage.addressData;
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:addressData];
    NSArray* recArray = [unarchiver decodeObjectForKey:@"recipients"];
    [unarchiver finishDecoding];
    NSMutableArray* recipientsArray = [NSMutableArray new];
    if(recArray)
    {
        for(EmailRecipient* emailRecipient in recArray)
        {
            NSInteger type = [emailRecipient type];
            if(type==TYPE_TO || type==TYPE_CC || type==TYPE_BCC)
            {
                //Recipient* recipient = [[Recipient alloc] initWithEmail:emailRecipient.email andName:emailRecipient.name];
                //[recipient setType:type];
                [recipientsArray addObject:emailRecipient];
            }
        }
    }
    [recipientsArray sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"email" ascending:YES]]];
    APPDELEGATE.selectedMessageRecipients = recipientsArray;
    recipientsExpanded = recipientsArray.count>2?NO:YES;
    [self refresh];
     */
}

- (void)refresh
{
    //[self.navigationController setToolbarHidden:APPDELEGATE.selectedMessage==nil animated:NO];
    //EmailMessage* message = APPDELEGATE.selectedMessage;
    //[self.navigationItem setLeftBarButtonItem:message?nil:cancelButton animated:NO];
    //[self.navigationItem setRightBarButtonItem:message?nil:sendButton animated:NO];
    //[self.navigationItem setRightBarButtonItem:message?[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(replyOrSendButton:)]:sendButton animated:NO];
   //[self.navigationItem.rightBarButtonItem setTitle:message?@"Reply":@"Send"];
    //[self.navigationItem.rightBarButtonItem setImage:message?[UIImage imageNamed:UIBarButtonSystemItemReply]:nil];
    //if(message)
      //  [self.navigationItem.rightBarButtonItem setEnabled:YES];
    [self setCorrectSendButtonColour];
    /*if(message)
    {
        if(message.fromName && message.fromName.length>0)
            [self.navigationItem setTitle:message.fromName];
        else
            [self.navigationItem setTitle:@"(no sender name)"];
    }
    else
        [self.navigationItem setTitle:@"New message"];*/
    [composeTableView reloadData];
}

#pragma mark - WebViewDelegate

-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
    if ( inType == UIWebViewNavigationTypeLinkClicked ) {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }
    
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    //NSLog(@"Error: %@",error);
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{

    //CGSize contentSize = webView.scrollView.contentSize;
    //CGSize viewSize = self.view.bounds.size;
    
/*    float rw = viewSize.width / contentSize.width;


    if(APPDELEGATE.selectedMessage.hasImages.boolValue)
        webView.scrollView.zoomScale = rw;
    
    CGRect frame = webView.frame;
    frame.size.height = 1;
    frame.size.width = viewSize.width;
    [webView setFrame:frame];
    [webView sizeToFit];
    CGFloat height = webView.frame.size.height;
    if(height<350)
    {
        height = 350;
        //frame.size.height = height;
        [webView setFrame:webView.superview.bounds];
       
    }
    if(shownMessageHeight!=height)
    {
        shownMessageHeight = height;
        [composeTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2+(showExtraFields?3:0) inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    }
*/
    //NSLog(@"Did finish load");
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    //NSLog(@"Did start load");
}

- (IBAction)replyButton:(id)sender
{
    
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    EmailMessageInstance* messageInstance = APPDELEGATE.selectedMessageInstance;
    switch(buttonIndex)
    {
        case 0: [self startReplyToMessageInstance:messageInstance];
            break;
        case 1: [self startReplyAllToMessageInstance:messageInstance];
            break;
        case 2: [self startForwardOfMessageInstance:messageInstance];
            break;
    }
}

- (EmailMessageInstance*)saveDraft
{
    if(!savedMessageInstance)
    {
    }


    if(composeSubject)
        [savedMessageInstance.message.messageData setSubject:composeSubject];
    else
        [savedMessageInstance.message.messageData setSubject:@""];
        
    NSMutableArray* emailRecArray = [NSMutableArray new];
    
    for(Recipient* rec in composeRecipients)
    {
        EmailRecipient* emailRec = [EmailRecipient new];
            
        [emailRecArray addObject:emailRec];
            
        [emailRec setName:rec.displayName];
        [emailRec setEmail:rec.displayEmail];
    
        [emailRec setType:rec.type];
    }

    IMAPAccountSetting* preferredAccount = MODEL.currentUserSettings.preferredAccount;

    if(preferredAccount)
    {
        EmailRecipient* emailRec = [EmailRecipient new];

        [emailRecArray addObject:emailRec];

        [emailRec setName:preferredAccount.senderName];
        [emailRec setEmail:preferredAccount.senderEmail];

        [emailRec setType:TYPE_FROM];
    }
        
    NSMutableData* addressData = [NSMutableData new];
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:addressData];
    [archiver encodeObject:emailRecArray forKey:@"recipients"];
    [archiver finishEncoding];
        
    [savedMessageInstance.message.messageData setAddressData:addressData];

    NSString* plainBody = [composedText string];

    [savedMessageInstance.message.messageData setBody:plainBody?plainBody:@""];

    [savedMessageInstance.message.messageData setHtmlBody:composeHtml?composeHtml:@""];

    //UserSettings* userSetting = MODEL.currentUserSettings;

    if(MODEL.currentUserSettings.preferredAccount.draftsFolder)
        [savedMessageInstance setInFolder:MODEL.currentUserSettings.preferredAccount.draftsFolder];

    return savedMessageInstance;
}

- (void)clear
{
    composeHtml = @"<html><body><div id=\"content\" contenteditable=\"true\" style=\"font-family: Helvetica\"></div></body></html>";
    composeSubject = @"";
    [self.tableView reloadData];
    isDirty = NO;
}

-(NSString*)trimLeadingWhitespaces:(NSString*)originalString
{
    NSInteger i = 0;

    NSMutableCharacterSet* charSet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [charSet addCharactersInString:@":"];

    while ((i < [originalString length])
           && [charSet characterIsMember:[originalString characterAtIndex:i]]) {
        i++;
    }
    return [originalString substringFromIndex:i];
}

- (NSString*)stripReReRes:(NSString*)subjectString
{
    NSString* string = [self trimLeadingWhitespaces:subjectString];
    NSArray* toBeStripped = @[@"Re:",@"Fw:",@"RE:",@"FW:",@"re:",@"fw:",@"Aw:",@"AW:"];
    while(string.length>=3 && [toBeStripped containsObject:[string substringToIndex:3]])
    {
        if(string.length==3)
            string = @"";
        else
            string = [self trimLeadingWhitespaces:[string substringFromIndex:3]];
    }
    return string;
}


- (void)startReplyToMessageInstance:(EmailMessageInstance*)messageInstance
{
    NSData* addressData = messageInstance.message.messageData.addressData;

    if(!addressData)
        return;

    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:addressData];
    NSArray* recArray = [unarchiver decodeObjectForKey:@"recipients"];
    [unarchiver finishDecoding];

    Recipient* recipient = nil;

    NSMutableArray* recipientsArray = [NSMutableArray new];
    if(recArray)
    {
        /*NSMutableArray* newToArray = [NSMutableArray new];
        NSMutableArray* newCcArray = [NSMutableArray new];
        NSMutableArray* newBccArray = [NSMutableArray new];
        NSMutableArray* newFromArray = [NSMutableArray new];
        NSMutableArray* newReplyToArray = [NSMutableArray new];*/

        for(EmailRecipient* emailRecipient in recArray)
        {
            NSInteger type = [emailRecipient type];
            if(type==TYPE_TO || type==TYPE_CC || type==TYPE_BCC)
            {
                [recipientsArray addObject:emailRecipient];
            }
            switch(type)
            {
                case TYPE_FROM:
                    if(!recipient)
                        recipient = [[Recipient alloc] initWithEmail:emailRecipient.email andName:emailRecipient.name];
                    break;
                case TYPE_REPLY_TO:
                    recipient = [[Recipient alloc] initWithEmail:emailRecipient.email andName:emailRecipient.name];
                    break;
                default:
                    break;
            }
        }
        if(recipient)
            [self setToRecipients:@[recipient]];
        else
            [self setToRecipients:@[]];
        [self setCcRecipients:@[]];
        [self setBccRecipients:@[]];

        //TO DO: set a proper sender address(!!!)
        [self setFromRecipient:nil];
        [self setReplyToRecipient:nil];
    }

    NSString* subject = [NSString stringWithFormat:@"Re: %@",[self stripReReRes:messageInstance.message.messageData.subject]];
    composeSubject = subject;

    NSString* body = messageInstance.message.messageData.htmlBody;
    BOOL substitutionSuccessful = NO;
    NSInteger index = [body rangeOfString:@"<body"].location;
    if(index!=NSNotFound)
    {
        index = [body rangeOfString:@">" options:0 range:NSMakeRange(index, body.length-index)].location;
        if(index!=NSNotFound)
        {
            body = [body stringByReplacingCharactersInRange:NSMakeRange(index, 1) withString:@"><div id=\"content\" contenteditable=\"true\">"];
            body = [body stringByReplacingOccurrencesOfString:@"</body" withString:@"</div></body"];
            substitutionSuccessful = YES;
        }
    }
    if(!substitutionSuccessful)
    {
        body = [NSString stringWithFormat:@"<html><body><div id=\"content\" contenteditable=\"true\">%@</div></body></html>", [body copy]];
    }
    composeHtml = body?body:messageInstance.message.messageData.body;
    [self.tableView reloadData];
}


- (void)startReplyAllToMessageInstance:(EmailMessageInstance*)messageInstance
{
    
}


- (void)startForwardOfMessageInstance:(EmailMessageInstance*)messageInstance
{
    
}


- (IBAction)showAllRecipients:(id)sender
{
    recipientsExpanded = YES;
    [self refresh];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(!recipientsExpanded && indexPath.row==0)
    {
        recipientsExpanded = YES;
        [self refresh];
    }
}

- (IBAction)sendMessage:(id)sender
{
    EmailMessageInstance* messageInstance = [self saveDraft];
    
    if(messageInstance)
    {
    IMAPAccount* account = [MODEL accountForSettingID:messageInstance.inFolder.inIMAPAccount.objectID];

    
    if(account)
    {
        /*
        [account sendDraftMessage:messageInstance withCallback:^(NSInteger result) {
            if(result==1)
            {
                NSURL* sentSoundFile = [NSURL fileURLWithPath:[[NSBundle mainBundle]
                                                           pathForResource:@"mail_sent"
                                                           ofType:@"mp3"]];
                AVAudioPlayer *sentSound = [[AVAudioPlayer alloc] initWithContentsOfURL:sentSoundFile error:nil];
                [sentSound play];
                [self.navigationController popViewControllerAnimated:YES];
            }
            else
            {
                AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
                UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Error sending message" message:@"Try sending message again?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Retry", nil];
                [alertView show];
            }
               }];
         */
    }
    }
    
    [self clear];
}

- (IBAction)expandRecipients:(id)sender
{
    showExtraFields = YES;
    [self.tableView reloadData];
}

- (void)setCorrectColour
{
    if(composeRecipients.count>0)
    {
        [self.navigationController.navigationBar setBackgroundColor:OPEN_SHADOW_COLOUR];
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:OPEN_COLOUR}];
        [self.navigationController.navigationBar.topItem setTitle:NSLocalizedString(@"Open message",@"Compose window title")];
    }
    else
    {
        [self.navigationController.navigationBar setBackgroundColor:SAFE_SHADOW_COLOUR];
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:SAFE_COLOUR}];
        [self.navigationController.navigationBar.topItem setTitle:NSLocalizedString(@"Safe message",@"Safe, secure email message")];
    }

}

- (BOOL)tokenField:(TITokenField *)tokenField didAddToken:(TIToken *)token
{
    [composeRecipients addObject:token];
    [token setTintColor:OPEN_DARK_COLOUR];
    [self setCorrectColour];

    return YES;
}

- (void)tokenField:(TITokenField *)tokenField didRemoveToken:(TIToken *)token
{
    [composeRecipients removeObject:token];
    [self setCorrectColour];
}

- (void)tokenField:(TITokenField *)tokenField didFinishSearch:(NSArray *)matches
{

}

- (NSString *)tokenField:(TITokenField *)tokenField displayStringForRepresentedObject:(id)object
{
    return @"display string";
}

- (NSString *)tokenField:(TITokenField *)tokenField searchResultStringForRepresentedObject:(id)object
{
    return @"results string";
}

- (NSString *)tokenField:(TITokenField *)tokenField searchResultSubtitleForRepresentedObject:(id)object
{
    return @"subtitle";
}



- (CGFloat)tokenField:(TITokenField *)tokenField resultsTableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 400;
}


- (void)adjustField:(TITokenField*)tokenField toHeight:(NSNumber*)height
{
    CGFloat currentHeight = -1;
    if([tokenField isEqual:toField])
    {
        currentHeight = toFieldHeight;
        toFieldHeight = height.floatValue;
    }
    if([tokenField isEqual:ccField])
    {
        currentHeight = ccFieldHeight;
        ccFieldHeight = height.floatValue;
    }
    if([tokenField isEqual:bccField])
    {
        currentHeight = bccFieldHeight;
        bccFieldHeight = height.floatValue;
    }

    if(currentHeight>=0)
    if(fabs(currentHeight-ceilf(height.floatValue))>0.001)
    {
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
    }
}

- (void)adjustCcField:(NSNumber*)height
{
    if(fabs(ccFieldHeight-ceilf(height.floatValue))>0.001)
    {
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
    }
}

- (void)adjustBccField:(NSNumber*)height
{
    if(fabs(bccFieldHeight-ceilf(height.floatValue))>0.001)
    {
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
    }
}

- (BOOL)resignFirstResponder
{
    return YES;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer
                                                    *)otherGestureRecognizer {
    return YES;
}

-(void) handleSingleTap:(UITapGestureRecognizer *)recognizer  {

    [UIView commitAnimations];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.3];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [UIView commitAnimations];

    [APPDELEGATE setHideTheStatusBar:YES];
    [self setNeedsStatusBarAppearanceUpdate];

    [(UIWebView*)recognizer.view setKeyboardDisplayRequiresUserAction:NO];
    [(UIWebView*)recognizer.view stringByEvaluatingJavaScriptFromString:@"document.getElementById('content').focus()"];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [UIView commitAnimations];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.3];
    [self.navigationController setNavigationBarHidden:NO animated:YES];

    [APPDELEGATE setHideTheStatusBar:NO];
    [self setNeedsStatusBarAppearanceUpdate];

    [UIView commitAnimations];
}

- (void)evaluateComposeBodyHeight
{

}


@end
