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





#import <UIKit/UIKit.h>


@class EmailMessageInstance, MynTokenIBField, AttachmentsListPopoverController, SafeDoorsView;


@interface DisplayMessageController : UIViewController <UIActionSheetDelegate, UIWebViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIPopoverPresentationControllerDelegate, UIScrollViewDelegate>
{
    CGFloat downloadProgressAngle;
    NSTimer* downloadProgressTimer;
}



#pragma mark -
#pragma mark - Nav bar button


@property UIBarButtonItem* editDraftButton;




#pragma mark -
#pragma mark - Toolbar buttons



#pragma mark - IBOutlets

@property IBOutlet UIBarButtonItem* readButton;
@property IBOutlet UIBarButtonItem* flagButton;
@property IBOutlet UIBarButtonItem* replyButton;
@property IBOutlet UIBarButtonItem* replyAllButton;
@property IBOutlet UIBarButtonItem* forwardButton;
@property IBOutlet UIBarButtonItem* separator1;
@property IBOutlet UIBarButtonItem* separator2;
@property IBOutlet UIBarButtonItem* flexibleSpace;


#pragma mark - IBActions

- (IBAction)readButtonHit:(id)sender;
- (IBAction)flagButtonHit:(id)sender;
- (IBAction)replyButtonHit:(id)sender;
- (IBAction)replyAllButtonHit:(id)sender;
- (IBAction)forwardButtonHit:(id)sender;

//set to YES when "reply all" & "forward" are shown
@property BOOL showAdditionalReplyButtons;



#pragma mark -
#pragma mark - Alert view

//set height to 0 to hide the alert view
@property(weak, nonatomic) IBOutlet NSLayoutConstraint* alertViewHeightConstraint;

@property(weak, nonatomic) IBOutlet UIButton* alertButton;

@property(weak, nonatomic) IBOutlet UILabel* alertMessageLabel;



#pragma mark -
#pragma mark - Feedback view


#pragma mark - IBOutlets

//@property IBOutlet NSLayoutConstraint* feedbackViewHeightConstraint;
@property IBOutlet UIView* overlayView;
@property IBOutlet NSLayoutConstraint* overlayHeightConstraint;
@property IBOutlet NSLayoutConstraint* overlayViewHeightConstraint;
@property IBOutlet NSLayoutConstraint* activityIndicatorConstraint;
@property IBOutlet UILabel* feedBackLabel;
@property IBOutlet UIActivityIndicatorView* activityIndicator;
@property IBOutlet UIButton* tryAgainButton;
@property IBOutlet UIView* downloadingView;


@property UIView* downloadProgressView;


#pragma mark - IBActions

- (IBAction)tryAgainButtonClicked:(id)sender;




#pragma mark -
#pragma mark - Cover view & doors

@property IBOutlet UIView* coverView;

@property IBOutlet SafeDoorsView* doorsView;



#pragma mark -
#pragma mark - Message display

@property EmailMessageInstance* displayedMessageInstance;

- (void)showMessageInstance:(EmailMessageInstance*)messageInstance;

- (void)refreshAnimated:(BOOL)animated alsoRefreshBody:(BOOL)refreshBody;


@property IBOutlet UIWebView* bodyView;
@property IBOutlet UIScrollView* scrollView;


@property id<UIScrollViewDelegate> bodyScrollDelegate;

@property IBOutlet UITextField* subjectField;

//the bar that indicates whether the message is open (red) or safe (green)
@property IBOutlet UIView* lockView;

@property IBOutlet NSLayoutConstraint* subjectHeightConstraint;
@property IBOutlet NSLayoutConstraint* bodyViewContentHeightConstraint;
@property IBOutlet NSLayoutConstraint* lockLayoutConstraint;

@property IBOutlet NSLayoutConstraint* attachmentButtonSubjectAdjustConstraint;

@property IBOutlet UIButton* numberOfAttachmentsButton;

@property IBOutlet UIButton* attachmentsButton;




#pragma mark -
#pragma mark - Adjusting the width

- (void)adjustWidthIfNeeded;
- (void)adjustWidthIfNeededWithAnimations;
- (void)adjustWidth;

@property IBOutlet NSLayoutConstraint* widthConstraint;




#pragma mark -
#pragma mark - Recipients

@property IBOutlet MynTokenIBField* toView;
@property IBOutlet MynTokenIBField* fromView;
@property IBOutlet MynTokenIBField* replyToView;
@property IBOutlet MynTokenIBField* ccView;
@property IBOutlet MynTokenIBField* bccView;


//
//
//#pragma mark -
//#pragma mark - Popover
//
//@property UIPopoverController* popover;






@end
