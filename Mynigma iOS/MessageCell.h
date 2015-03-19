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
#import "LittleLogoView.h"



@class EmailMessageInstance, EmailMessage;

@interface MessageCell : UITableViewCell

@property IBOutlet UIWebView* bodyView;
@property IBOutlet UIImageView* pictureView;
@property IBOutlet UILabel* nameLabel;
@property IBOutlet UILabel* subjectLabel;
@property IBOutlet UILabel* dateLabel;

@property IBOutlet UIImageView* starImageView;

@property IBOutlet UIImageView* topLeftIcon;
@property IBOutlet UIImageView* centerLeftIcon;
@property IBOutlet UIImageView* bottomLeftIcon;

@property IBOutlet UIView* topLeftBox;
@property IBOutlet UIView* bottomLeftBox;

@property IBOutlet LittleLogoView* extraIcon1;
@property IBOutlet LittleLogoView* extraIcon2;
@property IBOutlet LittleLogoView* extraIcon3;
@property IBOutlet LittleLogoView* extraIcon4;

@property IBOutlet NSLayoutConstraint* leftBarWidthConstraint;

@property EmailMessageInstance* messageInstance;
@property EmailMessage* message;

@property IBOutlet UIActivityIndicatorView* feedbackActivityIndicator;

@property IBOutlet UIImageView* downloadProgressView;

@property IBOutlet UIImageView* coinView;

@property IBOutlet UIView* feedBackContainer;

@property IBOutlet NSLayoutConstraint* feedbackActivityIndicatorConstraint;

@property IBOutlet UIView* messageContainer;

@property IBOutlet UILabel* feedBackLabel;

@property IBOutlet NSLayoutConstraint* iconDistanceConstraint;


@property IBOutletCollection(UILabel) NSArray* allLabels;
@property IBOutletCollection(UIImageView) NSArray* allIcons;


- (void)setUpIcons;
- (void)setUpLockBox;


@end
