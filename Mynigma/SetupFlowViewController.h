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
#import "ConnectionItem.h"



@protocol SetupFlowDataProvisionProtocol

- (void)setSkipOAuth:(BOOL)skipOAuth;

- (void)moveToPage:(NSInteger)pageIndex;

- (void)changedName:(NSString*)name;

- (void)doneEnteringSenderName;

-(ConnectionItem*) getConnectionItem;


@end




@class SetupFlowPageController, SetupFlowPage;


@interface SetupFlowViewController : UIViewController <SetupFlowDataProvisionProtocol, UIPopoverPresentationControllerDelegate>





//individual pages

@property (weak, nonatomic)  IBOutlet SetupFlowPage *page1;
@property (weak, nonatomic)  IBOutlet SetupFlowPage *page2;
@property (weak, nonatomic)  IBOutlet SetupFlowPage *page3;
@property (weak, nonatomic)  IBOutlet SetupFlowPage *page4;
@property (weak, nonatomic)  IBOutlet SetupFlowPage *page5;
@property (weak, nonatomic)  IBOutlet SetupFlowPage *page6;
@property (weak, nonatomic)  IBOutlet SetupFlowPage *page7;
@property (weak, nonatomic)  IBOutlet SetupFlowPage *page8;
@property (weak, nonatomic)  IBOutlet SetupFlowPage *page9;
@property (weak, nonatomic)  IBOutlet SetupFlowPage *page10;
@property (weak, nonatomic)  IBOutlet SetupFlowPage *page11;
@property (weak, nonatomic)  IBOutlet SetupFlowPage *page12;



@property SetupFlowPageController *page1Controller;
@property SetupFlowPageController *page2Controller;
@property SetupFlowPageController *page3Controller;
@property SetupFlowPageController *page4Controller;
@property SetupFlowPageController *page5Controller;
@property SetupFlowPageController *page6Controller;
@property SetupFlowPageController *page7Controller;
@property SetupFlowPageController *page8Controller;
@property SetupFlowPageController *page9Controller;
@property SetupFlowPageController *page10Controller;
@property SetupFlowPageController *page11Controller;
@property SetupFlowPageController *page12Controller;






@property NSInteger numberOfDisplayedPages;
@property CGFloat pageWidth;


//different from pageControl.currentPage, as some pages are batched
@property NSInteger currentPage;


@property BOOL OAuthSkipped;

@property ConnectionItem* connectionItem;


#pragma mark - IBOutlets

@property(weak, nonatomic) IBOutlet UIScrollView* scrollView;
@property IBOutlet UIPageControl* pageControl;
@property IBOutlet UIView* containerView;
@property IBOutlet UIButton* exitButton;
//@property IBOutlet UIViewController* containerViewController;




//the bottom margin needs be adjusted to fit the keyboard, if applicable
@property IBOutlet NSLayoutConstraint* bottomMarginConstraint;



- (void)showPage:(BOOL)showPage withIndex:(NSInteger)index;


@end
