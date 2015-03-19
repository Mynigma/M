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
#import "IconListAndColourHelper.h"
#import "ContactSuggestions.h"
#import "SelectionAndFilterHelper.h"
#import "EmailMessageController.h"
#import "MynigmaURLCache.h"
#import "UserSettings+Category.h"
#import "AccountCheckManager.h"
#import "DataWrapHelper.h"
#import "MigrationHelper.h"
#import "EmailMessageInstance+Category.h"
#import "EmailMessage+Category.h"
#import "EmailMessageData.h"
#import "MynigmaMessage+Category.h"
#import "StartUpHelper.h"




@implementation AppDelegate(iOS)


#pragma mark - iPhone/iPad convenience method (iOS 7)

+ (BOOL)isIPhone
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        return NO;
    }
    else
        return YES;
}



#pragma mark - UIApplicationDelegate methods


- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    return YES;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UINavigationBar appearance] setBarTintColor:NAVBAR_COLOUR];
    
    NSDictionary *attributes = @{ NSForegroundColorAttributeName : [UIColor whiteColor] };
    
    [[UINavigationBar appearance] setTitleTextAttributes:attributes];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];

    
    [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil, nil] setTitleTextAttributes:attributes forState:UIControlStateNormal];
    
    [[UIBarButtonItem appearanceWhenContainedIn:[UIToolbar class], nil, nil] setTintColor:[UIColor whiteColor]];
    
    [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
    
    [[UIToolbar appearance] setBarTintColor:NAVBAR_COLOUR];
    
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:NAVBAR_COLOUR];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTintColor:NAVBAR_COLOUR];

    
    
    //stop auto-correction "Mynigma" to "MyEnigma"
    [UITextChecker learnWord:@"Mynigma"];
    [UITextChecker unlearnWord:@"MyEnigma"];


    //make animations faster
    self.window.layer.speed = 2.0f;

    [application setStatusBarStyle:UIStatusBarStyleLightContent];

    //fetch frequently
    //TO DO: offer customisation
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    self.contactSuggestions = [ContactSuggestions new];
    [EmailMessageController sharedInstance];


    [SelectionAndFilterHelper sharedInstance].filterPredicate = [NSPredicate predicateWithValue:YES];
    //    self.titleBarString = NSLocalizedString(@"All Messages", @"Messages Controller");
    self.displayedMessages = @[];
    self.selectedMessageInstance = nil;

    MynigmaURLCache *URLCache = [[MynigmaURLCache alloc] initWithMemoryCapacity:10*1024*1024 diskCapacity:50*1024*1024 diskPath:@"/MynigmaCache/"];

    [NSURLCache setSharedURLCache:URLCache];

    [ThreadHelper runAsyncOnMain:^{

        [StartUpHelper performStartupTasks];

        //check if an account data file has been dropped into iTunes
        [self lookForAccountDataFileWithCallback:
         ^{

             [SelectionAndFilterHelper performSelector:@selector(updateFilters) withObject:nil afterDelay:.2];

             [SelectionAndFilterHelper reloadOutlinePreservingSelection];

             NSString* lastVersionString = [UserSettings currentUserSettings].lastVersionUsed;
             [MigrationHelper migrateFromVersion:lastVersionString];

         }];
    }];

    //if no accounts are installed prompt user to add one
    // Override point for customization after application launch.
    return YES;

}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];

    // Start the long-running task and return immediately.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        [CoreDataHelper saveWithCallback:^{
            NSLog(@"Background time remaining: %f",[[UIApplication sharedApplication] backgroundTimeRemaining]);

            [application endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }];
    });
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
//    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
//        [application endBackgroundTask:bgTask];
//        bgTask = UIBackgroundTaskInvalid;
//    }];
//
//    // Start the long-running task and return immediately.
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

    NSLog(@"Saving store!");
    
    [self removeDeletedMessagesFromStoreWithCallback:^{

        [CoreDataHelper saveWithCallback:^{

            [CoreDataHelper saveOnlyStoreContextWithCallback:^{
            
                NSLog(@"Saved store! %f", [[UIApplication sharedApplication] backgroundTimeRemaining]);
            }];
//            [application endBackgroundTask:bgTask];
//            bgTask = UIBackgroundTaskInvalid;
        }];
        
    }];
//    });
}



#pragma mark -
#pragma mark BACKGROUND FETCHING

- (void)backgroundTimeOutWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    if(completionHandler && !self.backgroundHandlerCalled)
    {
        self.backgroundHandlerCalled = YES;
    }
    
    if(completionHandler)
        completionHandler(UIBackgroundFetchResultFailed);
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    self.backgroundHandlerCalled = NO;

    CGFloat remainingTime = [[UIApplication sharedApplication] backgroundTimeRemaining]-1;

    [self performSelector:@selector(backgroundTimeOutWithCompletionHandler:) withObject:completionHandler afterDelay:remainingTime];


    [AccountCheckManager iOSBackgroundCheckWithCallback:^(BOOL successful, BOOL newMessages)
     {

         [ThreadHelper runAsyncOnMain:^{

             //        UILocalNotification* notification = [UILocalNotification new];
             //
             //        NSString* subTitle = [NSString stringWithFormat:@"Finished message check (%@, %@)", successful?@"successful":@"unsuccessful", newMessages?@"new messages":@"no new messages"];
             //
             //        [notification setAlertBody:subTitle];
             //        [notification setSoundName:@"DingLing.caf"];
             //        if(notification)
             //            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];

             if(completionHandler && !self.backgroundHandlerCalled)
             {
                 self.backgroundHandlerCalled = YES;

                 if(newMessages)
                     completionHandler(UIBackgroundFetchResultNewData);
                 else if(successful)
                     completionHandler(UIBackgroundFetchResultNoData);
                 else
                     completionHandler(UIBackgroundFetchResultFailed);
             }
         }];
     }];
}

- (void)lookForAccountDataFileWithCallback:(void(^)(void))callback
{
    NSString* accountDataFileName = [[AppDelegate applicationDocumentsDirectory] stringByAppendingPathComponent:@"Mynigma.AccountData"];

    if([[NSFileManager defaultManager] fileExistsAtPath:accountDataFileName])
    {
        [DataWrapHelper unwrapAccountDataPackage:[NSData dataWithContentsOfFile:accountDataFileName] passphrase:@"password" withCallback:[^(NSArray* importedKeyLabels, NSArray* errorLabels){
            [[NSFileManager defaultManager] removeItemAtPath:accountDataFileName error:nil];
            callback();
        } copy]];
    }
    else
        callback();
}


- (BOOL)application:(UIApplication *)application
      handleOpenURL:(NSURL *)url
{
    [AppDelegate openURL:url];

    return YES;
}







+ (void)openURL:(NSURL*)URL
{
#warning Unimplemented
}


@end
