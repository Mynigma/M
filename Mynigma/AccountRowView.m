//Copyright © 2012 - 2015 Roman Priebe
//
//This file is part of M - Safe email made simple.
//
//M is free software: you can redistribute it and/or modify
//it under the terms of the GNU General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.
//
//M is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU General Public License
//along with M.  If not, see <http://www.gnu.org/licenses/>.
//



#if TARGET_OS_IPHONE

#else

#import "FolderListController_MacOS.h"

#endif
#import "AccountRowView.h"
#import "AccountView.h"
#import "NSView+LayoutAdditions.h"
#import "IMAPAccountSetting.h"
#import "AppDelegate.h"
#import "FolderView.h"
#import "IconListAndColourHelper.h"


@implementation AccountRowView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self setUp];
    }

    return self;
}

- (void)setUp
{
//    if(NSClassFromString(@"NSVisualEffectView"))
//    {
//        NSVisualEffectView* effectView = [[NSVisualEffectView alloc] init];
//        
//        [effectView setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
//        
//        [self addSubview:effectView];
//        
//        [effectView setUpConstraintsToFitIntoSuperview];
//    }
}

- (void)drawSelectionInRect:(NSRect)dirtyRect
{
//    [super drawSelectionInRect:dirtyRect];
//    [ACCOUNT_SELECTION_COLOUR setFill];
    [ACCOUNT_SELECTION_COLOUR setFill];
//    [[COLOUR colorWithDeviceRed:35/255. green:90/255. blue:145/255. alpha:1] setFill];
//    [[NSColor whiteColor] setFill];
    NSRectFill(dirtyRect);

    /*
    FolderListController* foldersController = (FolderListController*)[APPDELEGATE.contactTable delegate];
    if([foldersController isKindOfClass:[FolderListController class]])
    {
    NSView* cellView = [self.subviews objectAtIndex:0];
    if([cellView isKindOfClass:[FolderView class]])
    {
            NSObject* representedObject = [(FolderView*)cellView representedObject];
            
            if((!representedObject && !foldersController.selectedFolder) || [representedObject isEqual:foldersController.selectedFolder])
                {
                    [[NSColor colorWithCalibratedRed:51/255. green:82/255. blue:126/255. alpha:1] setFill];
                    NSRectFill(dirtyRect);
                    
                }
    }
    if([cellView isKindOfClass:[AccountView class]])
       {
           NSObject* representedObject = [(AccountView*)cellView representedObject];
           if((!representedObject && !foldersController.selectedAccount) || [representedObject isEqual:foldersController.selectedAccount])
                {
                    [[NSColor colorWithCalibratedRed:51/255. green:82/255. blue:126/255. alpha:1] setFill];
                    NSRectFill(dirtyRect);
                }
            
        }
    }*/
    
}

//- (BOOL)allowsVibrancy
//{
//    return NO;
//}

@end
