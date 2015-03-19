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

#import "ContainerView.h"
#import "NSView+LayoutAdditions.h"



@implementation ContainerView


- (NSViewController*)loadViewControllerOfClass:(Class)viewControllerClass fromXIB:(NSString*)XIBName
{
    if(!XIBName)
        return nil;
    
    //don't load the subview more than once
    if(self.subviews.count)
        return nil;
    
    NSViewController* viewController = [[viewControllerClass alloc] initWithNibName:XIBName bundle:[NSBundle mainBundle]];
    
    NSView* loadedView = viewController.view;
    
    [self addSubview:loadedView];
    
    [loadedView setFrame:self.bounds];
    
    [loadedView setTranslatesAutoresizingMaskIntoConstraints:YES];
    
    [loadedView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    
    return viewController;
}


@end
