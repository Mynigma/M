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





#import <Foundation/Foundation.h>
#import "ComposeNewController.h"
#import "DisplayMessageController.h"
#import "MessagesController.h"
#import "AttachmentsDetailListController.h"
#import "FolderListController_iOS.h"
#import "MoveMessageViewController.h"
#import "SplitViewController.h"
#import "SidePanelController.h"




@interface ViewControllersManager : NSObject

+ (instancetype)sharedInstance;


@property(weak) ComposeNewController* composeController;
@property(weak) DisplayMessageController* displayMessageController;
@property(weak) MessagesController* messagesController;
@property(weak) AttachmentsDetailListController* attachmentsListController;
@property(weak) FolderListController* foldersController;
@property(strong) MoveMessageViewController* moveMessageViewController;
@property(weak) SplitViewController* splitViewController;
@property(weak) SidePanelController* sidePanelController;



@property BOOL hideTheStatusBar;



+ (BOOL)isSidePanelShown;
+ (void)toggleSidePanel;
+ (void)showSidePanel;
+ (void)hideSidePanel;



+ (void)showMoveMessageOptions;
+ (void)removeMoveMessageOptionsIfNecessary;
+ (void)adjustMoveMessageOptions;
+ (BOOL)isShowingMoveMessageOptions;



+ (BOOL)isHorizontallyCompact;
+ (BOOL)canDoPopovers;


#pragma mark - Storyboards

+ (UIStoryboard*)menuStoryboard;
+ (UIStoryboard*)setupFlowStoryboard;
+ (UIStoryboard*)mainStoryboard;



@end
