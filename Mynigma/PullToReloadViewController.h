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






#define TOTAL_PULL_HEIGHT 55
#define ACTIVE_RELOAD_HEIGHT 50

#import <Cocoa/Cocoa.h>

@class ReloadingView;

@interface PullToReloadViewController : NSViewController


@property ReloadingView* reloadingView;

@property NSTimer* hideTimer;

@property BOOL isInErrorState;

@property BOOL canReload;

@property BOOL isScrolledToTop;


//don't start reloading multiple times during a single scroll
//this is most pertient when there is no connection and the reloading attempt may return very quickly
@property BOOL alreadyReloadedOnThisScroll;


- (BOOL)shouldReload;


- (void)startReloadingAnimated:(BOOL)animated withCallback:(void(^)(void))callback;

- (void)stopReloadingAndScrollOutOfViewAnimated:(BOOL)animated withCallback:(void(^)(void))callback;

- (void)scrollToTopAnimated:(BOOL)animated withCallback:(void(^)(void))callback;

- (void)scrollToActiveHeightAnimated:(BOOL)animated withCallback:(void(^)(void))callback;



- (void)resetScrollPointAnimated:(BOOL)animated withCallback:(void(^)(void))callback;



- (void)showSuccessWithFeedback:(NSString*)feedbackString;

- (void)showErrorWithFeedback:(NSString*)feedbackString;

- (void)showEmptyWithFeedback:(NSString*)feedbackString;

- (void)showActiveWithFeedback:(NSString*)feedBackString;

- (void)showPullWithFeedback:(NSString*)feedBackString withIndex:(NSInteger)pullIndex;



- (BOOL)isCurrentlyReloading;

@end
