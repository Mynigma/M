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



@class FeedbackOverlayView, MynigmaFeedback;



IB_DESIGNABLE

@interface SafeDoorsView : UIView

//set priority to 999 to open the doors
//and to 1 to close the doors
@property NSLayoutConstraint* openTopDoorsConstraint;
@property NSLayoutConstraint* openBottomDoorsConstraint;


@property UIView* bottomDoorView;
@property UIView* topDoorView;


@property NSLayoutConstraint* openDoorsConstraint;



- (void)openDoorsAnimated:(BOOL)animated;
- (void)closeDoorsAnimated:(BOOL)animated;
- (void)closeDoorsAnimated:(BOOL)animated completion:(void(^)(BOOL))completionCallback;

- (void)toggleDoorsAnimated:(BOOL)animated;


#pragma mark - Feedback view

@property(weak, nonatomic) FeedbackOverlayView* feedbackFrameView;

- (void)showMynigmaFeedback:(MynigmaFeedback*)feedback;


@end
