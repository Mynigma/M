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

@interface SplitViewController : UISplitViewController

- (IBAction)changeMessageListVisibility:(id)sender;
- (UIViewController*)detailController;


//the welcome screen might have to be shown straight after the view has appeared
@property BOOL completedInitialAppearance;
@property BOOL showWelcomeScreenAfterAppearance;


//to make this happen, call this following method
- (void)showWelcomeScreenWhenLoaded;


//the width of the master view (set to 0 if hidden)
@property CGFloat masterViewWidth;

//whether the master view is shown as a partial overlay, partly obscuring the detail view
@property BOOL detailViewObscured;

//whether the master view is shown without partial overlay, squashing the detail view
@property BOOL detailViewSquashed;


@end
