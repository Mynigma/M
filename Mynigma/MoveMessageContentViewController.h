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
#import "MoveMessageImageView.h"



@interface MoveMessageContentViewController : UIViewController

@property (weak, nonatomic) IBOutlet MoveMessageImageView *moveToTrashOptionView;
@property (weak, nonatomic) IBOutlet MoveMessageImageView *moveToSpamOptionView;
@property(weak, nonatomic) IBOutlet MoveMessageImageView *moveElsewhereOptionView;


//@property (weak, nonatomic) IBOutlet MoveMessageImageView *replyOptionView;
//@property (weak, nonatomic) IBOutlet MoveMessageImageView *replyAllOptionView;
//@property (weak, nonatomic) IBOutlet MoveMessageImageView *forwardOptionView;


@property(weak, nonatomic) IBOutlet MoveMessageImageView *markUnreadOptionView;
@property(weak, nonatomic) IBOutlet MoveMessageImageView *markStarredOptionView;



@property (weak, nonatomic) IBOutlet MoveMessageImageView *selectMoreOptionView;
@property(weak, nonatomic) IBOutlet MoveMessageImageView *cancelOptionView;



@property(weak, nonatomic) IBOutlet NSLayoutConstraint* horizontalCenterConstraint;



- (IBAction)pickedOptionMoveToTrash:(id)sender;
- (IBAction)pickedOptionMoveToSpam:(id)sender;
- (IBAction)pickedOptionSelectMore:(id)sender;
//- (IBAction)pickedOptionReply:(id)sender;
//- (IBAction)pickedOptionReplyAll:(id)sender;
//- (IBAction)pickedOptionForward:(id)sender;
- (IBAction)pickedOptionCancel:(id)sender;


- (void)selectionDidChange;


@end
