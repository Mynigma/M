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





#import "MainSplitViewDelegate.h"


@implementation MainSplitViewDelegate

+ (instancetype)sharedInstance
{
    static dispatch_once_t p = 0;

    __strong static id sharedObject = nil;

    dispatch_once(&p, ^{
        sharedObject = [self new];
    });

    return sharedObject;
}


#pragma mark - NSSplitViewDelegate

//all subview of the main split view are collapsible
- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
    return YES;
}

////always collapse on double click
//- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex
//{
//    return YES;
//}

////constrain the split view coordinates
//- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
//{
//    switch(dividerIndex)
//    {
//        case 0:
//            //folder list should have width at least 150 (or be hidden)
//            return 150;
//        case 1:
//            //message list should have width at least 200 (or be hidden)
//            return ((NSView*)[splitView.subviews firstObject]).frame.size.width+200;
//        default:
//            return proposedMin;
//    }
//}
//
//- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
//{
//    switch(dividerIndex)
//    {
//        case 0:
//            //moving the first divider changes the width of the message list
//            //make sure it is at least 200
//            return splitView.frame.size.width-((NSView*)[splitView.subviews lastObject]).frame.size.width-200;
//        case 1:
//            //message display view should have width at least 400 (or be hidden)
//            return splitView.frame.size.width-400;
//        default:
//            return proposedMax;
//    }
//}

////don't let dividers be dragged off the edge of the split view
//- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex
//{
//    return NO;
//}

@end
