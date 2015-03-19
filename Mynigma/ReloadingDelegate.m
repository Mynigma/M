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





#import "ReloadingDelegate.h"
#import "OutlineObject.h"
#import "IMAPFolderSetting+Category.h"
#import "IMAPAccountSetting+Category.h"
#import "IMAPAccount.h"
#import "AppDelegate.h"

#import "PullToReloadViewController.h"
#import "ReloadingView.h"
#import "ReloadButton.h"
#import "AccountCheckManager.h"



static PullToReloadViewController* reloadViewController;

@implementation ReloadingDelegate


- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setBusyFolders:[NSMutableSet new]];
        [self setErrorFolders:[NSMutableSet new]];
    }
    return self;
}

+ (ReloadingDelegate*)sharedInstance
{
    static dispatch_once_t p = 0;

    __strong static id sharedObject = nil;

    dispatch_once(&p, ^{
        sharedObject = [ReloadingDelegate new];
    });

    return sharedObject;
}


+ (PullToReloadViewController*)reloadController
{
    if(!reloadViewController)
        reloadViewController = [PullToReloadViewController new];
    return reloadViewController;
}

+ (NSString*)nameOfFolder:(NSManagedObjectID*)folderObjectID
{
    IMAPFolderSetting* folderSetting = (IMAPFolderSetting*)[MAIN_CONTEXT existingObjectWithID:folderObjectID error:nil];
    if([folderSetting isKindOfClass:[IMAPFolderSetting class]])
    {
        return folderSetting.displayName;
    }

    return @"";
}

+ (void)startNewLoad
{
    [APPDELEGATE.refreshInboxButton startLoading:nil];

    [AccountCheckManager manualReload];

    ReloadingDelegate* sharedDelegate = [ReloadingDelegate sharedInstance];

    [sharedDelegate.busyFolders removeAllObjects];
    [sharedDelegate.errorFolders removeAllObjects];

    NSSet* allFolders = [OutlineObject selectedFolderSettingsForSyncing];

    for(IMAPFolderSetting* folderSetting in allFolders)
    {
        [sharedDelegate.busyFolders addObject:folderSetting.objectID];

        IMAPAccountSetting* accountSetting = folderSetting.inIMAPAccount;
        IMAPAccount* account = accountSetting.account;
        if(!account)
        {
            continue;
        }

        [account checkFolder:folderSetting userInitiated:YES];
    }

    NSInteger busyCount = sharedDelegate.busyFolders.count;

    NSMutableString* feedbackLabel = [NSMutableString new];

    switch(busyCount)
    {
        case 0:
        {
            [feedbackLabel appendFormat:NSLocalizedString(@"All folders checked", @"Refresh view feedback label")];
            break;
        }
        case 1:
        {
            NSManagedObjectID* folderObjectID = sharedDelegate.busyFolders.anyObject;
            [feedbackLabel appendFormat:NSLocalizedString(@"Checking '%@'", @"Refresh view feedback label"), [self nameOfFolder:folderObjectID]];
            break;
        }
        case 2:
        {
            NSArray* pair = [sharedDelegate.busyFolders sortedArrayUsingDescriptors:@[]];

            NSString* firstName = [self nameOfFolder:pair[0]];
            NSString* secondName = [self nameOfFolder:pair[1]];

            [feedbackLabel appendFormat:NSLocalizedString(@"Checking '%@' and '%@'", @"Refresh view feedback label"), firstName, secondName];
            break;
        }
        default:
        {
            NSManagedObjectID* folderObjectID = sharedDelegate.busyFolders.anyObject;

            NSString* name = [self nameOfFolder:folderObjectID];

            [feedbackLabel appendFormat:NSLocalizedString(@"Checking '%@' and %ld other folders", @"Refresh view feedback label"), name, busyCount-1];
            break;
        }
    }


    BOOL haveSomethingToReload = allFolders.count>0;

    if(!haveSomethingToReload)
    {
        //[[ReloadingDelegate reloadController] stopReloadingAndScrollOutOfViewAnimated:YES withCallback:nil];
        return;
    }
    
    [[ReloadingDelegate reloadController] showActiveWithFeedback:feedbackLabel];
}


+ (void)pullWithIndex:(NSInteger)index
{
    NSDate* lastChecked = [NSDate date];

    NSSet* allFolders = [OutlineObject selectedFolderSettingsForSyncing];

    for(IMAPFolderSetting* folderSetting in allFolders)
    {
        if(folderSetting.lastNewCheck == nil)
            lastChecked = nil;

        if([lastChecked compare:folderSetting.lastNewCheck]==NSOrderedDescending)
        {
            lastChecked = folderSetting.lastNewCheck;
        }
    }

    NSString* feedBackLabel = nil;

    if(allFolders.count==0)
    {
        feedBackLabel = NSLocalizedString(@"Nothing to check", @"Refresh view feedback label");
        [[ReloadingDelegate reloadController] showEmptyWithFeedback:feedBackLabel];
        return;
    }
    else if(lastChecked.timeIntervalSince1970<1)
    {
        feedBackLabel = NSLocalizedString(@"Last checked: never", @"Refresh view feedback label");
    }
    else if(lastChecked.timeIntervalSinceNow<60)
    {
        feedBackLabel = NSLocalizedString(@"Last checked: just now", @"Refresh view feedback label");
    }
    else
    {
        NSDateFormatter* timeFormatter = [NSDateFormatter new];
        [timeFormatter setDateStyle:NSDateFormatterNoStyle];
        [timeFormatter setTimeStyle:NSDateFormatterShortStyle];

        feedBackLabel = [NSString stringWithFormat:NSLocalizedString(@"Last checked %@", @"Refresh view feedback label"), [timeFormatter stringFromDate:lastChecked]];
    }

    [[ReloadingDelegate reloadController] showPullWithFeedback:feedBackLabel withIndex:index];
}


+ (void)refreshCheckedFolders
{
    ReloadingDelegate* sharedDelegate = [ReloadingDelegate sharedInstance];

    if(![ReloadingDelegate reloadController].reloadingView.circularProgressIndicator.isHidden)
    {
        if(sharedDelegate.busyFolders.count==0)
        {
            if(sharedDelegate.errorFolders.count>0)
            {
                NSMutableString* errorString = [NSMutableString new];

                NSInteger numberOfErrors = sharedDelegate.errorFolders.count;

                switch(numberOfErrors)
                {
                    case 0:
                        [errorString appendString:NSLocalizedString(@"An error occurred", @"Generic error")];
                        break;
                    case 1:
                    {
                        NSManagedObjectID* folderObjectID = sharedDelegate.errorFolders.anyObject;
                        IMAPFolderSetting* folder = (IMAPFolderSetting*)[MAIN_CONTEXT existingObjectWithID:folderObjectID error:nil];
                        if([folder isKindOfClass:[IMAPFolderSetting class]])
                            [errorString appendFormat:NSLocalizedString(@"Error checking '%@'", @"Refresh view feedback"), folder.displayName?folder.displayName:@""];
                        else
                            [errorString appendFormat:NSLocalizedString(@"Error checking one folder", @"Refresh view feedback")];
                        break;
                    }
                    default:
                        [errorString appendFormat:NSLocalizedString(@"Error checking %ld folders", @"Refresh view feedback"), numberOfErrors];
                }
                
                [[ReloadingDelegate reloadController] showErrorWithFeedback:errorString];
            }
            else
            {
                NSDate* lastChecked = [NSDate date];

                NSSet* allFolders = [OutlineObject selectedFolderSettingsForSyncing];

                for(IMAPFolderSetting* folderSetting in allFolders)
                {
                    if(folderSetting.lastNewCheck == nil)
                        lastChecked = nil;

                    if([lastChecked compare:folderSetting.lastNewCheck]==NSOrderedDescending)
                    {
                        lastChecked = folderSetting.lastNewCheck;
                    }
                }

                NSString* feedBackLabel = nil;

                if(lastChecked.timeIntervalSince1970<1)
                {

                    feedBackLabel = NSLocalizedString(@"Last checked: never", @"Refresh view feedback label");

                }
                else
                {
                    NSDateFormatter* timeFormatter = [NSDateFormatter new];
                    [timeFormatter setDateStyle:NSDateFormatterNoStyle];
                    [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
                    
                    feedBackLabel = [NSString stringWithFormat:NSLocalizedString(@"Last checked %@", @"Refresh view feedback label"), [timeFormatter stringFromDate:lastChecked]];
                }

                [[ReloadingDelegate reloadController] showSuccessWithFeedback:feedBackLabel];
            }

            [APPDELEGATE.refreshInboxButton doneLoading];
        }
        else
        {
            NSInteger busyCount = 0;

            NSSet* allFolders = [OutlineObject selectedFolderSettingsForSyncing];

            for(IMAPFolderSetting* folderSetting in allFolders)
            {
                if([sharedDelegate.busyFolders containsObject:folderSetting.objectID])
                {
                    busyCount++;
                }
            }

            NSMutableString* stringValue = [NSMutableString new];

            switch(busyCount)
            {
                case 0:
                    [stringValue appendFormat:NSLocalizedString(@"All folders checked", @"Refresh view feedback label")];
                    break;
                case 1:
                {
                    NSString* folderName = [self nameOfFolder:sharedDelegate.busyFolders.anyObject];

                    [stringValue appendFormat:NSLocalizedString(@"Checking '%@'", @"Refresh view feedback label"), folderName];
                    break;
                }
                case 2:
                {
                    NSArray* pair = [sharedDelegate.busyFolders sortedArrayUsingDescriptors:@[]];

                    NSString* firstName = [self nameOfFolder:pair[0]];
                    NSString* secondName = [self nameOfFolder:pair[1]];

                    [stringValue appendFormat:NSLocalizedString(@"Checking '%@' and '%@'", @"Refresh view feedback label"), firstName, secondName];
                    break;
                }
                default:
                {
                    NSManagedObjectID* folderObjectID = sharedDelegate.busyFolders.anyObject;

                    NSString* name = [self nameOfFolder:folderObjectID];

                    [stringValue appendFormat:NSLocalizedString(@"Checking '%@' and %ld other folders", @"Refresh view feedback label"), name, busyCount-1];
                    break;
                }
            }

            [[ReloadingDelegate reloadController] showActiveWithFeedback:stringValue];

        }
    }
}


+ (void)doneCheckingFolder:(NSManagedObjectID*)folderID
{
    ReloadingDelegate* sharedDelegate = [ReloadingDelegate sharedInstance];

    if([sharedDelegate.busyFolders containsObject:folderID])
    {
        [sharedDelegate.busyFolders removeObject:folderID];

        [self refreshCheckedFolders];
    }

}

+ (void)errorCheckingFolder:(NSManagedObjectID*)folderID
{
    ReloadingDelegate* sharedDelegate = [ReloadingDelegate sharedInstance];

    if([sharedDelegate.busyFolders containsObject:folderID])
    {
        [sharedDelegate.busyFolders removeObject:folderID];
        [sharedDelegate.errorFolders addObject:folderID];

        [self refreshCheckedFolders];
    }
}

+ (void)startedCheckingFolder:(NSManagedObjectID*)folderID
{
    
}




@end
