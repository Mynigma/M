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





#import "ContentViewer.h"
#import "MynigmaMessage+Category.h"
#import "IMAPAccount.h"
#import "IMAPAccountSetting+Category.h"
#import "IMAPFolderSetting+Category.h"
#import "AppDelegate.h"
#import "EmailMessageInstance+Category.h"
#import "ContentView.h"
#import "IconListAndColourHelper.h"
#import "EmailMessage+Category.h"
#import "SelectionAndFilterHelper.h"
#import "DownloadHelper.h"




@implementation ContentViewer

@synthesize fromToTextView;
@synthesize subjectField;
@synthesize bodyView;
@synthesize height;
@synthesize replyAllButton;
@synthesize lockView;
@synthesize unreadButton;
@synthesize flagButton;
@synthesize outerBox;
@synthesize showImagesLabel;
@synthesize feedBackString;
@synthesize feedBackIndicatorShown;
@synthesize tryAgainButton;
@synthesize progressBar;
@synthesize feedbackBox;
@synthesize tryAgainLabel;

@synthesize picHiderConstraint;
@synthesize profilePicView;

@synthesize boxWidthConstraint;


- (void)awakeFromNib
{
    height = 300;
    [showImagesLabel setHidden:YES];
    [self setFeedBackString:nil];
    [self setFeedBackIndicatorShown:NO];
    [progressBar setHidden:YES];
    [progressBar startAnimation:nil];
    [tryAgainButton setHidden:YES];
    [tryAgainLabel setHidden:YES];

    boxWidthConstraint.constant = 0;

    [feedbackBox setCornerRadius:5];

    CALayer* layer = profilePicView.layer;

    [layer setCornerRadius:profilePicView.frame.size.height/2];
    [layer setBorderColor:DARK_BLUE_COLOUR.CGColor];
    [layer setBorderWidth:1];
    [layer setMasksToBounds:YES];

    // CSS for blockquotes
    WebPreferences *webPrefs = [WebPreferences standardPreferences];
    [webPrefs setUserStyleSheetEnabled:YES];
    //Point to wherever your local/custom css is
    [webPrefs setUserStyleSheetLocation:[[NSBundle mainBundle] URLForResource:@"style" withExtension:@"css"]];
    //Set your webview's preferences
    [bodyView setPreferences:webPrefs];
}


- (IBAction)tryAgainButtonClicked:(id)sender
{
    if([messageInstance isKindOfClass:[EmailMessageInstance class]])
    {
        [DownloadHelper downloadMessageInstance:messageInstance urgent:YES];
        [SelectionAndFilterHelper refreshViewerShowingMessageInstance:messageInstance];
    }
    else if([self.message isKindOfClass:[EmailMessage class]])
    {
        [DownloadHelper downloadMessage:self.message urgent:YES];
        [SelectionAndFilterHelper refreshViewerShowingMessage:self.message];
    }

    else
        NSLog(@"Try again button clicked with invalid message!!!");
}



@end
