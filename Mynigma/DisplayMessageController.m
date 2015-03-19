//Copyright © 2012 - 2015 Roman Priebe
//
//This file is part of M - Safe email made simple.
//
//M is free software: you can redistribute it and/or modify
//it under the terms of the GNU General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.
//
//M is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU General Public License
//along with M.  If not, see <http://www.gnu.org/licenses/>.
//



#import "AppDelegate.h"
#import "DisplayMessageController.h"
#import "ShowAllRecipientsCell.h"
#import "Recipient.h"
#import "EmailContactDetail+Category.h"
#import "RecipientCell.h"
#import "Contact+Category.h"
#import "ABContactDetail.h"
#import "ShowMessageCell.h"
#import "EmailMessage+Category.h"
#import "MynigmaMessage+Category.h"
#import "EmailRecipient.h"
#import "ComposeController.h"
#import "TextEntryCell.h"
#import "TITokenField.h"
#import "LoadingCell.h"
#import "MessagesController.h"
#import "IMAPAccount.h"
#import "IMAPAccountSetting+Category.h"
#import "IMAPFolderSetting+Category.h"
#import "ComposeNewController.h"
#import "EmailMessageInstance+Category.h"
#import "EmailMessageData.h"
#import "AddressDataHelper.h"
#import "IconListAndColourHelper.h"
#import <MailCore/MailCore.h>
#import "MynTokenIBField.h"
#import "FormattingHelper.h"
#import "AttachmentListView.h"
#import "MynTokenFieldController.h"
#import "EmailMessageController.h"
#import "AttachmentsListPopoverController.h"
#import "FileAttachment+Category.h"
#import "AttachmentsDetailListController.h"
#import "SplitViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "MynigmaFeedback.h"
#import "ViewControllersManager.h"
#import "SafeDoorsView.h"
#import "SplitViewController.h"




@interface DisplayMessageController ()

@end

@implementation DisplayMessageController


#pragma mark - Initialisation


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.toView setEnabled:NO];
    [self.replyToView setEnabled:NO];
    [self.fromView setEnabled:NO];
    [self.ccView setEnabled:NO];
    [self.bccView setEnabled:NO];


    [self.bodyView.scrollView setBounces:NO];
    [self.bodyView.scrollView setBouncesZoom:NO];

    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }

    [self.bodyView.scrollView setScrollEnabled:NO];
    
    //initially cover all fields with a white screen
    [self.coverView setHidden:NO];

    [[ViewControllersManager sharedInstance] setDisplayMessageController:self];
    
    if([ViewControllersManager isHorizontallyCompact])
    {
        [self.bodyView setScalesPageToFit:YES];
    }

    [self setBodyScrollDelegate:self.bodyView.scrollView.delegate];
    
//    [self.scrollView setDelegate:self];
    
    [self.bodyView.scrollView setDelegate:self];
}


- (void)viewWillAppear:(BOOL)animated
{
    //need to clip to bounds - otherwise the shadow sometimes overlays the master view
    [self.view setClipsToBounds:YES];
    
    //on iOS 7 the willTransitionToSize delegate methods won't be called, so we need to set the width
    [self adjustWidthIfNeeded];

    [self setShowAdditionalReplyButtons:(self.widthConstraint.constant > 400)];

    [self configureToolbarButtonsAnimated:YES];

    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    
    [self adjustWidthIfNeeded];

    [self.downloadProgressView setHidden:YES];
}



#pragma mark - Rotation

- (BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    [self adjustWidth];

    [self adjustHeight:self.bodyView];
    
    [self refreshBodyAnimated:NO];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         CGFloat newWidth = size.width;
         
         [self adjustToWidth:newWidth];
         
         [self adjustHeight:self.bodyView];
         
     } completion:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         
     }];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}



#pragma mark - Setting the display


- (void)refreshAnimated:(BOOL)animated alsoRefreshBody:(BOOL)reloadBody
{
    //refresh the subject
    [self refreshSubject];
    
    //refresh the flags
    [self refreshFlags];
    
    //refresh the title (date) in navigation bar
    [self refreshNavigationBarTitle];
    
    [self refreshDoorsAnimated:animated];

    if(reloadBody)
        [self refreshBodyAnimated:animated];
    
    //don't animate the recipient list, it looks weird...
    [self refreshRecipientsAnimated:NO];
    
    [self refreshLockView];
    
    [self refreshMynigmaFeedback];
    
    [self refreshEditDraftButton];
    
    //attachments
    [self refreshAttachments];
}

- (void)showMessageInstance:(EmailMessageInstance*)messageInstance
{
    [ThreadHelper ensureMainThread];
    
    [self setDisplayedMessageInstance:messageInstance];
    
    if([messageInstance.message isDownloaded] && [messageInstance isUnread])
    {
        [messageInstance markRead];
    }
    
    
    //don't animate the doors etc...
    [self refreshAnimated:NO alsoRefreshBody:YES];
    
    [messageInstance.message downloadUsingSession:nil disconnectOperation:nil urgent:YES alsoDownloadAttachments:NO];
}


#pragma mark - private

- (void)refreshMynigmaFeedback
{
    MynigmaFeedback* feedback = self.displayedMessageInstance.message.feedback;

    BOOL showAlertView = [feedback showAlert];
    
    if(showAlertView)
    {
        [self.alertViewHeightConstraint setConstant:32];
        [self.alertMessageLabel setText:[feedback localizedDescription]];
    }
    else
    {
        [self.alertViewHeightConstraint setConstant:0];
    }
    
    [self.doorsView showMynigmaFeedback:feedback];
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

- (void)refreshSubject
{
    NSString* subject = self.displayedMessageInstance.message.messageData.subject;
    
    if([self.displayedMessageInstance.message isSafe] && ![self.displayedMessageInstance.message isDecrypted])
        subject = NSLocalizedString(@"Safe message",@"Safe, secure email message");
    
    if(subject.length && [self.displayedMessageInstance.message.feedback showMessage])
    {
        [self.subjectHeightConstraint setConstant:42];
    }
    else
    {
        [self.subjectHeightConstraint setConstant:0];
    }
    
    [self.subjectField setText:subject?subject:@""];
}

- (void)refreshBodyAnimated:(BOOL)animated
{
    MynigmaFeedback* feedback = self.displayedMessageInstance.message.feedback;
    
    if([feedback showMessage])
    {
        NSString* bodyString = self.displayedMessageInstance.message.messageData.htmlBody;
        
        if(!bodyString.length)
            bodyString = self.displayedMessageInstance.message.messageData.body;
        
        bodyString = [FormattingHelper prepareHTMLContentForDisplay:bodyString makeEditable:NO];
        
        [self.bodyView loadHTMLString:bodyString baseURL:nil];
        
        [self.doorsView openDoorsAnimated:animated];
    }
    else
    {
        [self.bodyView loadHTMLString:@"" baseURL:nil];
    }
}

- (void)refreshDoorsAnimated:(BOOL)animated
{
    if(!self.displayedMessageInstance)
    {
        //the cover view is displayed above the entire content if nothing should be shown
        //mostly used for iPad
        [self.coverView setHidden:NO];
        [self.doorsView closeDoorsAnimated:NO];
        
        [self.navigationItem setTitle:NSLocalizedString(@"M - Safe email made simple", @"Navigation bar default title")];
        
        [self.lockView setBackgroundColor:OPEN_DARK_COLOUR];
        
        return;
    }

    [self.coverView setHidden:YES];

    if([self.displayedMessageInstance isSafe])
    {
        if([self.displayedMessageInstance.message.feedback showMessage])
        {
            [self.doorsView openDoorsAnimated:animated];
        }
        else
        {
            [self.doorsView closeDoorsAnimated:animated];
        }
    }
    else
    {
        //don't show the doors at all for open messages
        
//        if([self.displayedMessageInstance.message.feedback showMessage])
            [self.doorsView openDoorsAnimated:NO];
//        else
//        {
//            [self.doorsView closeDoorsAnimated:NO];
//            [self.coverView setHidden:NO];
//        }
    }
}

- (void)refreshRecipientsAnimated:(BOOL)animated
{
    if([self.displayedMessageInstance.message.feedback showMessage])
    {
    NSData* addressData = self.displayedMessageInstance.message.messageData.addressData;
    
    NSArray* recArray = [AddressDataHelper emailRecipientsForAddressData:addressData];
    
    NSMutableArray* recipientsArray = [NSMutableArray new];
    
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
    
        [UIView animateWithDuration:animated?.3:0 animations:^{
        
        [self.toView removeAllTokens];
        [self.fromView removeAllTokens];
        [self.replyToView removeAllTokens];
        [self.ccView removeAllTokens];
        [self.bccView removeAllTokens];
        
        [self.toView setPrompt:NSLocalizedString(@"To:",@"To lable (recipient)")];
        [self.fromView setPrompt:NSLocalizedString(@"From:",@"From lable (sender)")];
        [self.ccView setPrompt:NSLocalizedString(@"Cc:",@"Cc lable (recipient)")];
        [self.bccView setPrompt:NSLocalizedString(@"Bcc:",@"Bcc lable (recipient)")];
        [self.replyToView setPrompt:NSLocalizedString(@"Reply To:",@"Reply To lable (sender)")];
        
        BOOL isDraftMessage = [self.displayedMessageInstance isInDraftsFolder];
        
        for(EmailRecipient* rec in newToArray)
        {
            UIColor* tokenColor = NAVBAR_COLOUR;
            
            if(isDraftMessage)
                tokenColor = [rec isSafeAsNonSender]?SAFE_DARK_COLOUR:OPEN_DARK_COLOUR;
            
            [self.toView addTokenWithTitle:rec.displayString representedObject:rec tintColour:tokenColor];
        }
        
        for(EmailRecipient* rec in newFromArray)
        {
            UIColor* tokenColor = NAVBAR_COLOUR;
            
            if(isDraftMessage)
                tokenColor = [rec isSafeAsNonSender]?SAFE_DARK_COLOUR:OPEN_DARK_COLOUR;
            
            [self.fromView addTokenWithTitle:rec.displayString representedObject:rec tintColour:tokenColor];
        }
        
        for(EmailRecipient* rec in newReplyToArray)
        {
            UIColor* tokenColor = NAVBAR_COLOUR;
            
            if(isDraftMessage)
                tokenColor = [rec isSafeAsNonSender]?SAFE_DARK_COLOUR:OPEN_DARK_COLOUR;
            
            [self.replyToView addTokenWithTitle:rec.displayString representedObject:rec tintColour:tokenColor];
        }
        
        for(EmailRecipient* rec in newCcArray)
        {
            UIColor* tokenColor = NAVBAR_COLOUR;
            
            if(isDraftMessage)
                tokenColor = [rec isSafeAsNonSender]?SAFE_DARK_COLOUR:OPEN_DARK_COLOUR;
            
            [self.ccView addTokenWithTitle:rec.displayString representedObject:rec tintColour:tokenColor];
        }
        
        for(EmailRecipient* rec in newBccArray)
        {
            UIColor* tokenColor = NAVBAR_COLOUR;
            
            if(isDraftMessage)
                tokenColor = [rec isSafeAsNonSender]?SAFE_DARK_COLOUR:OPEN_DARK_COLOUR;
            
            [self.bccView addTokenWithTitle:rec.displayString representedObject:rec tintColour:tokenColor];
        }
        
        [self.toView setHidden:newToArray.count==0];
        [self.ccView setHidden:newCcArray.count==0];
        [self.bccView setHidden:newBccArray.count==0];
        [self.fromView setHidden:newFromArray.count==0];
        
        //show the reply to field iff there is a reply to recipient and it's different from the sender
        BOOL showReplyToField = newReplyToArray.count && ![[(EmailRecipient*)newFromArray.firstObject email] isEqualToString:[newReplyToArray.firstObject email]];
        
        [self.replyToView setHidden:!showReplyToField];
    }];
    }
    else
    {
    [self.toView removeAllTokens];
    [self.fromView removeAllTokens];
    [self.replyToView removeAllTokens];
    [self.ccView removeAllTokens];
    [self.bccView removeAllTokens];
    
    [self.toView setHidden:YES];
    [self.ccView setHidden:YES];
    [self.bccView setHidden:YES];
    [self.fromView setHidden:YES];
    [self.replyToView setHidden:YES];
    }
}

- (void)refreshFlags
{
    if(self.displayedMessageInstance.isUnread)
    {
        [self.readButton setImage:[UIImage imageNamed:@"unreadB22Template"]];
        //[self.unreadLogoHideConstraint setPriority:1];
    }
    else
    {
        [self.readButton setImage:[UIImage imageNamed:@"read22"]];
        //[self.unreadLogoHideConstraint setPriority:999];
    }
    
    if(self.displayedMessageInstance.isFlagged)
    {
        [self.flagButton setImage:[UIImage imageNamed:@"starredB22"]];
        //[self.flaggedLogoHideConstraint setPriority:1];
    }
    else
    {
        [self.flagButton setImage:[UIImage imageNamed:@"starred22"]];
        //[self.flaggedLogoHideConstraint setPriority:999];
    }
}

- (void)refreshNavigationBarTitle
{
    NSDate* sentDate =  self.displayedMessageInstance.message.dateSent;
    
    if(sentDate)
    {
        NSString* formattedDate = [NSDateFormatter localizedStringFromDate:sentDate dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterShortStyle];
        
        [self.navigationItem setTitle:formattedDate];
    }
    else
        [self.navigationItem setTitle:@""];
}

- (void)refreshLockView
{
    if([self.displayedMessageInstance.message isSafe])
    {
        [self.lockView setBackgroundColor:SAFE_DARK_COLOUR];
        [self.lockLayoutConstraint setConstant:10];
    }
    else
    {
        [self.lockView setBackgroundColor:OPEN_DARK_COLOUR];
        [self.lockLayoutConstraint setConstant:0];
    }
}

- (void)refreshEditDraftButton
{
    if([self.displayedMessageInstance isInDraftsFolder] && [self.displayedMessageInstance.message isDownloaded])
    {
        self.editDraftButton = [UIBarButtonItem new];
        
        [self.editDraftButton setTarget:self];
        
        [self.editDraftButton setAction:@selector(editDraftButtonHit:)];
        
        self.editDraftButton.title = NSLocalizedString(@"Edit draft", @"Edit as draft button");
        self.editDraftButton.tintColor = [UIColor whiteColor];
        self.navigationItem.rightBarButtonItem = self.editDraftButton;
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else
    {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)refreshAttachments
{
    NSInteger attachmentCount = self.displayedMessageInstance.message.allAttachments.count;
    
    NSString* attachmentCountString = attachmentCount==0?@"":[NSString stringWithFormat:@"%ld", (long)attachmentCount];
    
    [self.numberOfAttachmentsButton setTitle:attachmentCountString forState:UIControlStateNormal];
    
    [self.numberOfAttachmentsButton setHidden:attachmentCount==0];
    [self.attachmentsButton setHidden:attachmentCount==0];
    
    [self.attachmentButtonSubjectAdjustConstraint setPriority:(attachmentCount==0)?1:999];
}


#pragma mark - Adjusting width & height

- (void)adjustWidthIfNeededWithAnimations
{
    CGFloat newWidth = self.view.frame.size.width;
    if(fabs(self.widthConstraint.constant-newWidth)>0)
    {
        [self.widthConstraint setConstant:newWidth];

        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }
}

- (void)adjustWidthIfNeeded
{
    CGFloat newWidth = self.view.frame.size.width;
    if(fabs(self.widthConstraint.constant-newWidth)>0)
    {
        [self adjustWidth];
    }
}

- (void)adjustWidth
{
    CGFloat newWidth = CGRectGetWidth(self.view.bounds);
    [self adjustToWidth:newWidth];
}

- (void)adjustToWidth:(CGFloat)newWidth
{
    [self.widthConstraint setConstant:newWidth];

    [self setShowAdditionalReplyButtons:(self.widthConstraint.constant > 400)];

    [self configureToolbarButtonsAnimated:YES];

    [UIView animateWithDuration:0 animations:^{

        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        [self.view layoutSubviews];

        [self.fromView setNeedsLayout];
        [self.replyToView setNeedsLayout];
        [self.toView setNeedsLayout];
        [self.ccView setNeedsLayout];
        [self.bccView setNeedsLayout];

        [self.fromView layoutIfNeeded];
        [self.replyToView layoutIfNeeded];
        [self.toView layoutIfNeeded];
        [self.ccView layoutIfNeeded];
        [self.bccView layoutIfNeeded];

        [self.fromView.tokenFieldController layoutTokensAnimated:NO];
        [self.toView.tokenFieldController layoutTokensAnimated:NO];
        [self.replyToView.tokenFieldController layoutTokensAnimated:NO];
        [self.ccView.tokenFieldController layoutTokensAnimated:NO];
        [self.bccView.tokenFieldController layoutTokensAnimated:NO];
        [self.replyToView.tokenFieldController layoutTokensAnimated:NO];

    }];
}

- (void)adjustHeight:(UIWebView*)webView
{
    [UIView animateWithDuration:0 animations:^{

        [webView.scrollView setContentOffset:CGPointMake(0, 0) animated:NO];
        
        [self.bodyView setNeedsLayout];
        [self.bodyView layoutIfNeeded];

        // First, we need to calculate the new content sizes
        CGSize contentSize = webView.scrollView.contentSize;

        CGFloat fittingHeight = contentSize.height;
        
        CGRect frame = webView.scrollView.frame;
        
        frame.size.width = 320;
        
        frame.size.height = 1;
        
        [webView setFrame:frame];

//        contentSize = webView.scrollView.contentSize;
//        
//        CGFloat newFittingHeight = contentSize.height;
//        
//        
        NSString *documentHeight = [webView stringByEvaluatingJavaScriptFromString:@"document.body.scrollHeight;"];
        
        NSString *documentWidth = [webView stringByEvaluatingJavaScriptFromString:@"document.body.scrollWidth;"];
        
//
//        CGSize goodSize = [webView sizeThatFits:CGSizeMake(self.view.bounds.size.width, MAXFLOAT)];
//        
//        frame = webView.frame;
//        frame.size.height = 1;
//        webView.frame = frame;
//        CGSize fittingSize = [webView sizeThatFits:CGSizeZero];
//        
//        CGFloat betterSize = fittingSize.height;
        
        //if the split view shows the master on the side (iPad, iOS8), the web view is actually smaller than the documentWidth indicates
        //we need to set the correct value for the width of the webView to ensure the height does not end up too short
        
        CGFloat docWidth = documentWidth.floatValue;
        
        if([[ViewControllersManager sharedInstance].splitViewController detailViewSquashed])
        {
            docWidth = CGRectGetWidth(self.view.bounds);
        }
        
        if(docWidth < .01)
        {
            docWidth = contentSize.width;
        }
        
        fittingHeight = documentHeight.floatValue * CGRectGetWidth(self.view.bounds) / docWidth;
        
        [self.bodyViewContentHeightConstraint setConstant:fittingHeight];

        [self.bodyViewContentHeightConstraint setPriority:980];

        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        [self.view layoutSubviews];

        [self.bodyView setHidden:NO];
    }];
}



#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"replySegue"])
    {
        UINavigationController* navigationController = segue.destinationViewController;
        if(navigationController.viewControllers.count==0)
            return;
        ComposeNewController* composeController = navigationController.viewControllers[0];
        if([composeController isKindOfClass:[ComposeNewController class]])
        {
            [composeController startReplyToMessageInstance:self.displayedMessageInstance];
        }
    }
    if([segue.identifier isEqualToString:@"replyAllSegue"])
    {
        UINavigationController* navigationController = segue.destinationViewController;
        if(navigationController.viewControllers.count==0)
            return;
        ComposeNewController* composeController = navigationController.viewControllers[0];
        if([composeController isKindOfClass:[ComposeNewController class]])
        {
            [composeController startReplyAllToMessageInstance:self.displayedMessageInstance];
        }
    }
    if([segue.identifier isEqualToString:@"forwardSegue"])
    {
        UINavigationController* navigationController = segue.destinationViewController;
        if(navigationController.viewControllers.count==0)
            return;
        ComposeNewController* composeController = navigationController.viewControllers[0];
        if([composeController isKindOfClass:[ComposeNewController class]])
        {
            [composeController startForwardOfMessageInstance:self.displayedMessageInstance];
        }
    }
    if([segue.identifier isEqualToString:@"recomposeMessage"])
    {
        //iPhone never reaches this point
        [self.navigationController.navigationBar.topItem setPrompt:nil];

        if(self.displayedMessageInstance)
        {
            ComposeNewController* composeController = (ComposeNewController*)[(UINavigationController*)segue.destinationViewController topViewController];

            if([composeController isKindOfClass:[ComposeNewController class]])
            {
                [(ComposeNewController*)composeController showDraftMessageInstance:self.displayedMessageInstance];
            }
        }
    }

    if([segue.destinationViewController isKindOfClass:[AttachmentsDetailListController class]])
    {
        AttachmentsDetailListController* destinationController = (AttachmentsDetailListController*)segue.destinationViewController;

        //only iOS 8.0 and above
        if([destinationController respondsToSelector:@selector(popoverPresentationController)])
            destinationController.popoverPresentationController.delegate = self;

        NSInteger numberOfAttachments = self.displayedMessageInstance.message.allAttachments.count;
        
        destinationController.preferredContentSize = CGSizeMake(300, 73*numberOfAttachments);
        [destinationController setCanAddAndRemove:NO];
        [destinationController setupWithAttachments:[self.displayedMessageInstance.message.allAttachments sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"fileName" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"contentid" ascending:YES]]]];

        destinationController.callingViewController = self;
    }

    [super prepareForSegue:segue sender:sender];
}


#pragma mark - UIPopoverPresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller;
{
    return UIModalPresentationNone;
}




#pragma mark - UI actions

- (IBAction)tryAgainButtonClicked:(id)sender
{
    [self.displayedMessageInstance.message downloadUsingSession:nil disconnectOperation:nil urgent:YES alsoDownloadAttachments:NO];
}

- (IBAction)editDraftButtonHit:(id)sender
{
    if (![self.displayedMessageInstance isInDraftsFolder])
        return;

    [[ViewControllersManager sharedInstance].messagesController performSegueWithIdentifier:@"recomposeMessage" sender:self];
}


- (IBAction)readButtonHit:(id)sender
{
    if(!self.displayedMessageInstance)
        return;

    if([self.displayedMessageInstance isUnread])
    {
        [self.displayedMessageInstance markRead];
    }
    else
    {
        [self.displayedMessageInstance markUnread];
    }

    [self refreshFlags];
}

- (IBAction)flagButtonHit:(id)sender
{
    if(!self.displayedMessageInstance)
        return;

    if([self.displayedMessageInstance isFlagged])
    {
        [self.displayedMessageInstance markUnflagged];
        [self.flagButton setImage:[UIImage imageNamed:@"starred22.png"]];
    }
    else
    {
        [self.displayedMessageInstance markFlagged];
        [self.flagButton setImage:[UIImage imageNamed:@"starredB22.png"]];
    }

    [self refreshFlags];
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

- (IBAction)replyButtonHit:(id)sender
{
    if(!self.displayedMessageInstance)
        return;

    if(!self.showAdditionalReplyButtons)
    {
        //only a single reply button is shown, so ask the user what they want to do (reply/reply all/forward)
        [self replyOrForwardButtonHit:sender];
        return;
    }

    //REPLY
    [self performSegueWithIdentifier:@"replySegue" sender:self];
}

- (IBAction)replyAllButtonHit:(id)sender
{
    if(!self.displayedMessageInstance)
        return;

    //REPLY ALL
    [self performSegueWithIdentifier:@"replyAllSegue" sender:self];
}

- (IBAction)forwardButtonHit:(id)sender
{
    if(!self.displayedMessageInstance)
        return;

    //FORWARD
    [self performSegueWithIdentifier:@"forwardSegue" sender:self];
}

- (IBAction)spamButtonHit:(id)sender
{
    if(!self.displayedMessageInstance)
        return;

    NSIndexPath* currentSelectedIndexPath = [ViewControllersManager sharedInstance].messagesController.tableView.indexPathForSelectedRow;

    if([self.displayedMessageInstance isKindOfClass:[EmailMessageInstance class]])
    {
        if([self.displayedMessageInstance isInSpamFolder])
            [self.displayedMessageInstance moveToInbox];
        else
            [self.displayedMessageInstance moveToSpam];
    }

    if([AppDelegate isIPhone])
    {
        [self.navigationController popViewControllerAnimated:NO];
    }

    if(currentSelectedIndexPath.row >= 0 && currentSelectedIndexPath.row != NSNotFound)
        [[EmailMessageController sharedInstance] updateFiltersReselectingIndexPath:currentSelectedIndexPath];
}

- (IBAction)deleteButtonHit:(id)sender
{
    if(!self.displayedMessageInstance)
        return;

    NSIndexPath* currentSelectedIndexPath = [ViewControllersManager sharedInstance].messagesController.tableView.indexPathForSelectedRow;

    if([self.displayedMessageInstance isKindOfClass:[EmailMessageInstance class]])
    {
        [self.displayedMessageInstance moveToBinOrDelete];
    }

    if([AppDelegate isIPhone])
    {
        [self.navigationController popViewControllerAnimated:NO];
    }

    if(currentSelectedIndexPath.row >= 0 && currentSelectedIndexPath.row != NSNotFound)
        [[EmailMessageController sharedInstance] updateFiltersReselectingIndexPath:currentSelectedIndexPath];
}

- (IBAction)attachmentButtonHit:(id)sender
{
    if([ViewControllersManager canDoPopovers])
    {
        [self performSegueWithIdentifier:@"attachmentSegue" sender:self];
        
    }
    else
    {
        //iOS 7 (iPhone)
        [self performSegueWithIdentifier:@"attachmentSegue_iOS7" sender:self];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch(buttonIndex)
    {
        case 0:
        {
            //[self.navigationController popViewControllerAnimated:NO];
            [self performSegueWithIdentifier:@"replySegue" sender:self];
            break;
        }
        case 1:
        {
            //[self.navigationController popViewControllerAnimated:NO];
            [self performSegueWithIdentifier:@"replyAllSegue" sender:self];
            break;
        }
        case 2:
        {
            //[self.navigationController popViewControllerAnimated:NO];
            [self performSegueWithIdentifier:@"forwardSegue" sender:self];
            break;
        }
    }
}

- (IBAction)replyOrForwardButtonHit:(id)sender
{
    UIActionSheet* newActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel Button") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Reply", @"Display message controller"), NSLocalizedString(@"Reply all", @"Display message controller"), NSLocalizedString(@"Forward", @"Display message controller"), nil];

    [newActionSheet setTag:168];

    [newActionSheet showInView:self.view.window];
}

- (IBAction)alertButtonTapped:(id)sender
{
    
}



//- (IBAction)showAttachmentsButtonClicked:(id)sender
//{
//    NSInteger numberOfAttachments = self.displayedMessageInstance.message.allAttachments.count;
//
//    if(numberOfAttachments==0)
//        return;
//
//    if(APPDELEGATE.isIPhone)
//    {
//
//    }
//    else
//    {
//        UIButton* button = (UIButton*)sender;
//
//        if(!self.popover.isPopoverVisible)
//        {
//            if(!self.popover)
//            {
//                AttachmentsListPopoverController* newPopoverViewController = [[AttachmentsListPopoverController alloc] initWithNibName:@"AttachmentsListPopoverController" bundle:BUNDLE];
//                self.popover = [[UIPopoverController alloc] initWithContentViewController:newPopoverViewController];
//            }
//
//            if(button.superview.window)
//                [self.popover presentPopoverFromRect:button.frame inView:button.superview permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
//        }
//    }
//}






#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType
{
    if ( inType == UIWebViewNavigationTypeLinkClicked )
    {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }

    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
//
//    [webView setHidden:YES];

    [self.bodyViewContentHeightConstraint setConstant:1];
    [self.bodyViewContentHeightConstraint setPriority:1];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self adjustHeight:webView];
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self.bodyScrollDelegate scrollViewDidZoom:scrollView];
    
    [scrollView setScrollEnabled:fabs(scrollView.zoomScale - 1.) > .1];
}

//- (void)scrollViewDidScroll:(UIScrollView *)scrollView
//{
//    [self.bodyScrollDelegate scrollViewDidScroll:scrollView];
//}
//
//
//- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
//{
//    [self.bodyScrollDelegate scrollViewWillBeginDragging:scrollView];
//}
//
//- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
//{
//    [self.bodyScrollDelegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
//}
//
//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
//{
//    [self.bodyScrollDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
//}
//
//- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
//{
//    [self.bodyScrollDelegate scrollViewWillBeginDecelerating:scrollView];
//}
//
//- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
//{
//    [self.bodyScrollDelegate scrollViewDidEndDecelerating:scrollView];
//}
//
//- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
//{
//    [self.bodyScrollDelegate scrollViewDidEndScrollingAnimation:scrollView];
//}

//- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
//{
//    return self.bodyView;
//}

//- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
//{
//    [self.bodyScrollDelegate scrollViewWillBeginZooming:scrollView withView:view];
//}
//
//- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
//{
//    [self.bodyScrollDelegate scrollViewDidEndZooming:scrollView withView:view atScale:scale];
//}
//
//- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
//{
//    return [self.bodyScrollDelegate scrollViewShouldScrollToTop:scrollView];
//}
//
//- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
//{
//    [self.bodyScrollDelegate scrollViewDidScrollToTop:scrollView];
//}




#pragma mark - Gesture recognition

- (IBAction)swipeUp:(id)sender
{
    [[ViewControllersManager sharedInstance].messagesController moveUpInMessagesList];
}

- (IBAction)swipeDown:(id)sender
{
    [[ViewControllersManager sharedInstance].messagesController moveDownInMessagesList];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}



#pragma mark - Toolbar management

- (void)configureToolbarButtonsAnimated:(BOOL)animated
{
    BOOL showReplyButtons = self.showAdditionalReplyButtons;

    if(self.replyAllButton && self.forwardButton && self.separator1 && self.separator2)
    {
        NSArray* currentToolbarButtons = self.toolbarItems;

        BOOL additionalButtonsCurrentlyShown = [currentToolbarButtons containsObject:self.replyAllButton];

        if(showReplyButtons)
        {
            //show the additional buttons, without animation, to check if the space is sufficient
            if(!additionalButtonsCurrentlyShown)
            {
                NSArray* newToolbarButtons = [currentToolbarButtons arrayByAddingObjectsFromArray:@[self.separator1, self.replyAllButton, self.separator2, self.forwardButton]];

                [self setToolbarItems:newToolbarButtons animated:NO];
            }
        }

        // the "width" property doesn't work here
        //        if(self.flexibleSpace.width < 20)
        //        {
        //            //there is insufficient space - hide the additonal buttons no matter what
        //            showAdditionalButtons = NO;
        //        }

        //now reset so the animation can start from the initial position
        [self setToolbarItems:currentToolbarButtons animated:NO];

        if(showReplyButtons)
        {
            //show the additional buttons, this time with animation
            if(!additionalButtonsCurrentlyShown)
            {
                NSArray* newToolbarButtons = [currentToolbarButtons arrayByAddingObjectsFromArray:@[self.separator1, self.replyAllButton, self.separator2, self.forwardButton]];

                [self setToolbarItems:newToolbarButtons animated:YES];
            }
        }
        else
        {
            if(additionalButtonsCurrentlyShown)
            {
                NSMutableArray* newButtons = [currentToolbarButtons mutableCopy];

                [newButtons removeObjectsInArray:@[self.separator1, self.replyAllButton, self.separator2, self.forwardButton]];

                [self setToolbarItems:newButtons animated:YES];
            }
        }
    }
    else
        NSLog(@"Toolbar items IBOutlets improperly configured");
}


#pragma mark - UITraitEnvironment protocol

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [self adjustWidthIfNeeded];

    if([self.view respondsToSelector:@selector(traitCollection)])
    {
        if(self.view.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular)
        {
            UIButton* buttonView = [UIButton buttonWithType:UIButtonTypeCustom];

            [buttonView setFrame:CGRectMake(0, 0, 22, 22)];

            UIImage* image = [UIImage imageNamed:@"leftArrowHead"];

            [buttonView setBackgroundImage:image forState:UIControlStateNormal];
            
            //UIImage *highlightedImage = [UIImage imageNamed:@"leftArrowHeadThick"];
            
            //the image will be rendered in the tint colour whenever it is highlighted
            [buttonView setTintColor:[UIColor whiteColor]];
            
            [buttonView setBackgroundImage:image forState:UIControlStateHighlighted];
            
            [buttonView addTarget:self.splitViewController action:@selector(changeMessageListVisibility:) forControlEvents:UIControlEventTouchDown];
            
            UIBarButtonItem* backButton = [[UIBarButtonItem alloc] initWithCustomView:buttonView];
            
            [backButton setWidth:22];
            
            [self.navigationItem setLeftBarButtonItem:backButton];
            
            //adjust the button rotation
            [self.splitViewController.delegate splitViewController:self.splitViewController willChangeToDisplayMode:self.splitViewController.displayMode];
        }
    }
}




@end
