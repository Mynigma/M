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

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

#else

#import <Cocoa/Cocoa.h>

#endif



@class MynigmaFeedback;


#if TARGET_OS_IPHONE

@interface FeedbackOverlayView : UIView

#else

@interface FeedbackOverlayView : NSView

#endif

@property MynigmaFeedback* feedback;

- (void)setUpWithFeedback:(MynigmaFeedback*)feedback;




#pragma mark - IBOutlets


#if TARGET_OS_IPHONE

@property(weak, nonatomic) IBOutlet UIView* roundedCornerView;

@property(weak, nonatomic) IBOutlet UILabel *messageTextLabel;

@property (weak, nonatomic) IBOutlet UIButton *button1;
@property (weak, nonatomic) IBOutlet UIButton *button2;
@property (weak, nonatomic) IBOutlet UIButton *button3;
@property (weak, nonatomic) IBOutlet UIButton *button4;


@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

#else


@property(weak, nonatomic) IBOutlet NSView* roundedCornerView;

@property(weak, nonatomic) IBOutlet NSTextField *messageTextLabel;

@property (weak, nonatomic) IBOutlet NSButton *button1;
@property (weak, nonatomic) IBOutlet NSButton *button2;
@property (weak, nonatomic) IBOutlet NSButton *button3;
@property (weak, nonatomic) IBOutlet NSButton *button4;


@property (weak, nonatomic) IBOutlet NSProgressIndicator *activityIndicator;


#endif


#pragma mark - Layout constraints

@property (weak, nonatomic) IBOutlet NSLayoutConstraint* totalButtonsHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* hideActivityIndicatorConstraint;

@end
