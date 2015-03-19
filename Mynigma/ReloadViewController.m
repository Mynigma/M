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





#import "ReloadViewController.h"
#import "AppDelegate.h"
#import "MessageListController.h"
#import "OutlineObject.h"
#import "IMAPFolderSetting+Category.h"
#import "ReloadingView.h"
#import "IMAPAccountSetting+Category.h"

#import "IMAPAccount.h"


@implementation ReloadViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _isReloading = NO;
        _showSmallHeight = NO;
        _showError = NO;
        _showSuccess = NO;
        _busyFolders = [NSMutableSet new];
        _errorFolders = [NSMutableSet new];
        _isScrolling = NO;
    }
    return self;
}


- (void)startReloading
{
    [self startReloadingAnimated:YES];
}

- (void)startReloadingAnimated:(BOOL)animated
{
    NSSet* allFolders = [OutlineObject selectedFolderSettingsForSyncing];

    [self.busyFolders removeAllObjects];
    [self.errorFolders removeAllObjects];
    [self setShowError:NO];
    [self setShowSuccess:NO];

    for(IMAPFolderSetting* folderSetting in allFolders)
    {
        [self.busyFolders addObject:folderSetting.objectID];

        IMAPAccountSetting* accountSetting = folderSetting.inIMAPAccount;
        IMAPAccount* account = [MODEL accountForSettingID:accountSetting.objectID];
        if(!account)
        {
            continue;
        }

        [account checkFolder:folderSetting];
    }

    BOOL haveSomethingToReload = allFolders.count>0;

    [self setCanReload:haveSomethingToReload];

    if(!haveSomethingToReload)
    {
        [self setShowSmallHeight:NO];

        [self stopReloadingAndScrollOutOfViewAnimated:animated];
        return;
    }

    [self setShowSmallHeight:YES];

    self.isReloading = YES;



    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:animated?.6:0];


    [[NSAnimationContext currentContext] setCompletionHandler:^{

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, .3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:0];
        
            //[APPDELEGATE.messagesTable noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:0]];
            [APPDELEGATE.messagesTable beginUpdates];
            [APPDELEGATE.messagesTable reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:0] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
            [APPDELEGATE.messagesTable endUpdates];

        [NSAnimationContext endGrouping];
        });

    }];
//[self resetScrollPointAnimated:NO];

    [APPDELEGATE.messagesTable beginUpdates];
    [APPDELEGATE.messagesTable reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:0] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    [APPDELEGATE.messagesTable noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:0]];
    [APPDELEGATE.messagesTable endUpdates];

    //   [self resetScrollPointAnimated:NO];

    [NSAnimationContext endGrouping];
}


- (void)stopReloadingAndScrollOutOfView
{
    [self stopReloadingAndScrollOutOfViewAnimated:NO];
}

- (void)stopReloadingAndScrollOutOfViewAnimated:(BOOL)animated
{
    [self stopReloadingAndScrollOutOfViewAnimated:animated withCallback:nil];
}

- (void)stopReloadingAndScrollOutOfViewAnimated:(BOOL)animated withCallback:(void(^)(void))callback
{
    [self.busyFolders removeAllObjects];
    [self.errorFolders removeAllObjects];
    [self setShowError:NO];
    [self setShowSuccess:NO];

    [self setIsScrolling:NO];

    NSPoint oldPoint = APPDELEGATE.messageListScrollView.documentVisibleRect.origin;

    NSInteger rowIndex = [APPDELEGATE.messagesTable rowAtPoint:oldPoint];

    //only scroll if the reload view is actually shown
    BOOL shouldScroll = (rowIndex == 0);

    if(!shouldScroll)
    {
        [self setIsReloading:NO];
        [self setShowSmallHeight:NO];
        [self setShowError:NO];
        [self setShowSuccess:NO];

        return;
    }

    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:animated?.3:0];

    [[NSAnimationContext currentContext] setCompletionHandler:^{
        
        [NSAnimationContext beginGrouping];

        [[NSAnimationContext currentContext] setDuration:0];

        [[NSAnimationContext currentContext] setCompletionHandler:^{
            if(callback)
                callback();
        }];

        [self resetScrollPoint];

        [self setIsReloading:NO];
        [self setShowSmallHeight:NO];
        [self setShowError:NO];

        [APPDELEGATE.messagesTable beginUpdates];

        [APPDELEGATE.messagesTable noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:0]];

        [APPDELEGATE.messagesTable reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:0] columnIndexes:[NSIndexSet indexSetWithIndex:0]];

        [APPDELEGATE.messagesTable endUpdates];

        [NSAnimationContext endGrouping];

        [self setShowSuccess:NO];

        [self resetScrollPoint];
    }];

    NSPoint newPoint = NSMakePoint(0, RELOAD_HEIGHT_SMALL);

    [[APPDELEGATE.messagesTable.superview animator] setBoundsOrigin:newPoint];
    [APPDELEGATE.messagesTable.enclosingScrollView reflectScrolledClipView:(NSClipView*)APPDELEGATE.messagesTable.superview];

    [NSAnimationContext endGrouping];
}

- (void)showErrorFeedback
{
    NSSound* sound = [NSSound soundNamed:@"errorLoadingNew.mp3"];

    [sound play];

    [self setShowError:YES];

    [self setIsReloading:NO];

    [APPDELEGATE.messagesTable reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:0] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

- (void)showSuccessFeedback
{
    //show the check mark
    [self setShowSuccess:YES];

    //don't show the progress indicator
    [self setIsReloading:NO];

    //reload the row
    [APPDELEGATE.messagesTable reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:0] columnIndexes:[NSIndexSet indexSetWithIndex:0]];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{

        [self stopReloadingAndScrollOutOfViewAnimated:YES];

    });
}

- (void)resetScrollPoint
{
    [self resetScrollPointAnimated:NO];
}

- (void)resetScrollPointAnimated:(BOOL)animated
{
    [self resetScrollPointAnimated:animated withCallback:nil];
}

- (void)resetScrollPointAnimated:(BOOL)animated withCallback:(void(^)(void))callback
{
    NSPoint currentScrollPoint = APPDELEGATE.messageListScrollView.documentVisibleRect.origin;

    NSLog(@"Reset scroll point");

    if(self.showSmallHeight)
    {
        if(currentScrollPoint.y < 0)
        {
            currentScrollPoint.y = 0;
        }

    }
    else
    {
        if(currentScrollPoint.y < RELOAD_HEIGHT_LARGE)
        {
            currentScrollPoint.y = RELOAD_HEIGHT_LARGE;
        }
    }

    NSInteger rowIndex = [APPDELEGATE.messagesTable rowAtPoint:currentScrollPoint];

    BOOL needToScroll = (rowIndex == 0);

    if(needToScroll)
    {
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:animated?.3:0];

    if(callback)
        [[NSAnimationContext currentContext] setCompletionHandler:^{
            callback();
        }];

    [[APPDELEGATE.messagesTable.superview animator] setBoundsOrigin:currentScrollPoint];
    [APPDELEGATE.messagesTable.enclosingScrollView.animator reflectScrolledClipView:(NSClipView*)APPDELEGATE.messagesTable.superview];

    [NSAnimationContext endGrouping];
    }
    else
    {
        if(callback)
            callback();
    }
}

- (void)refreshCheckedFolders
{
    if(self.isReloading)
    {
        if(self.busyFolders.count==0)
        {
            if(self.errorFolders.count>0)
            {
                [self showErrorFeedback];
            }
            else
            {
                [self showSuccessFeedback];
            }
        }
        else
        {

        }
    }
}


- (void)doneCheckingFolder:(NSManagedObjectID*)folderID
{
    if([self.busyFolders containsObject:folderID])
    {
        [self.busyFolders removeObject:folderID];

        [self refreshCheckedFolders];
    }
}

- (void)errorCheckingFolder:(NSManagedObjectID*)folderID
{
    if([self.busyFolders containsObject:folderID])
    {
        [self.busyFolders removeObject:folderID];
        [self.errorFolders addObject:folderID];

        [self refreshCheckedFolders];
    }
}

- (void)startedCheckingFolder:(NSManagedObjectID*)folderID
{
    
}


@end
