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





#import <Cocoa/Cocoa.h>

@class BlueTextButton;

@class EmailMessage, MynigmaFeedback;

@interface FeedbackView : NSBox


//@property NSString* feedBackString;
@property IBOutlet NSBox* feedbackBox;
@property IBOutlet NSTextField* feedBackLabel;
@property IBOutlet NSProgressIndicator* progressBar;

@property EmailMessage* message;
@property MynigmaFeedback* error;


@property IBOutlet BlueTextButton* firstButton;
@property IBOutlet BlueTextButton* secondButton;
@property IBOutlet BlueTextButton* thirdButton;
@property IBOutlet BlueTextButton* fourthButton;

@property IBOutlet NSLayoutConstraint* buttonsHeightConstraint;

- (IBAction)firstButtonClicked:(id)sender;
- (IBAction)secondButtonClicked:(id)sender;
- (IBAction)thirdButtonClicked:(id)sender;
- (IBAction)fourthButtonClicked:(id)sender;



@property SEL actionSelector;
@property id actionTarget;


- (void)showFeedback:(NSString*)feedback withTryAgainAction:(SEL)tryAgainAction target:(id)target;

- (void)hideFeedback;

- (void)showFeedbackForMessage:(EmailMessage*)message;


@end
