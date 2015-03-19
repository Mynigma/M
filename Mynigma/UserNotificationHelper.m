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





#import "UserNotificationHelper.h"
#import "EmailMessageInstance+Category.h"
#import "AppDelegate.h"
#import "EmailMessage+Category.h"
#import "DownloadHelper.h"
#import "MynigmaMessage+Category.h"
#import "EmailMessageData.h"
#import "SelectionAndFilterHelper.h"





#if TARGET_OS_IPHONE

#import <CoreFoundation/CoreFoundation.h>

#else

#import <Foundation/Foundation.h>

#endif




static NSMutableArray* queuedMessageInstances;
static dispatch_queue_t designatedQueue;


@implementation UserNotificationHelper


+ (instancetype)sharedInstance
{
    static dispatch_once_t p = 0;

    __strong static id sharedObject = nil;

    dispatch_once(&p, ^{
        sharedObject = [self new];
    });

    return sharedObject;
}

#if TARGET_OS_IPHONE

#else

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.notificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
        [self.notificationCenter setDelegate:(id<NSUserNotificationCenterDelegate>)self];
    }
    return self;
}

#endif


#if TARGET_OS_IPHONE

/**CALL ON MAIN*/
+ (void)notifyOfMessage:(NSManagedObjectID*)emailMessageInstanceObjectID
{
    [ThreadHelper ensureMainThread];

    if(!emailMessageInstanceObjectID)
        return;

    NSError* error = nil;

    EmailMessageInstance* messageInstance = (EmailMessageInstance*)[MAIN_CONTEXT existingObjectWithID:emailMessageInstanceObjectID error:&error];

    if(error)
    {
        NSLog(@"Error creating message instance for notification! %@", error);
        return;
    }

    EmailMessage* emailMessage = messageInstance.message;

    UILocalNotification* notification = [UILocalNotification new];
    if([emailMessage isKindOfClass:[MynigmaMessage class]])
    {
        NSString* senderString = emailMessage.messageData.fromName;
        NSString* subTitle = [NSString stringWithFormat:NSLocalizedString(@"Safe message from %@",@"Safe msg subject <sender name>"),senderString];
        [notification setAlertBody:subTitle];
        [notification setSoundName:@"DingLing.caf"];
        [notification setUserInfo:@{@"messageID":emailMessage.messageid}];
        if(notification)
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    }
    else
    {
        NSString* name = emailMessage.messageData.fromName;
        [notification setAlertBody:[NSString stringWithFormat:@"%@\n%@", name, emailMessage.messageData.subject]];
        [notification setSoundName:@"Morse"];
        [notification setUserInfo:@{@"messageID":emailMessage.messageid}];
        if(notification)
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    }
}

+ (void)notifyOfMessageBatch:(NSInteger)numberOfMessages
{
    UILocalNotification* notification = [UILocalNotification new];
    [notification setHasAction:YES];
    [notification setAlertAction:@"View"];
    [notification setAlertBody:[NSString stringWithFormat:NSLocalizedString(@"%ld new messages",@"Notification Titel <number of msgs>"), numberOfMessages]];
    [notification setSoundName:@"Morse"];
    if(notification)
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}


#else


/**CALL ON MAIN*/
+ (void)notifyOfMessage:(NSManagedObjectID*)emailMessageInstanceObjectID
{
    [ThreadHelper ensureMainThread];

    NSUserNotification* notification = [NSUserNotification new];

    NSError* error = nil;

    EmailMessageInstance* emailMessageInstance = (EmailMessageInstance*)[MAIN_CONTEXT existingObjectWithID:emailMessageInstanceObjectID error:&error];

    if(error || !emailMessageInstance)
    {
        NSLog(@"Unable to reconstruct email message for notification");
        return;
    }

    if([emailMessageInstance.message isKindOfClass:[MynigmaMessage class]])
    {
        [notification setTitle:NSLocalizedString(@"Mynigma Safe Email",@"Notification Title")];
        NSString* senderString = emailMessageInstance.message.messageData.fromName;
        NSString* subTitle = [NSString stringWithFormat:NSLocalizedString(@"Safe message from %@",@"Safe msg subject <sender name>"),senderString];
        [notification setSubtitle:subTitle];
        [notification setSoundName:@"DingLing.mp3"];
        [notification setUserInfo:@{@"messageID":emailMessageInstance.message.messageid?emailMessageInstance.message.messageid:@""}];

        if([emailMessageInstance.message haveProfilePic])
        {
            NSImage* image = [emailMessageInstance.message profilePic];
            if([notification respondsToSelector:@selector(setContentImage:)])
                [notification setContentImage:image];
        }

        if(notification) //<-this avoids a crash in OS X 10.7 (which does not have a notification center)
            [[UserNotificationHelper sharedInstance].notificationCenter deliverNotification:notification];
    }
    else
    {
        NSString* name = emailMessageInstance.message.messageData.fromName;
        [notification setTitle:name?name:@""];
        [notification setSubtitle:emailMessageInstance.message.messageData.subject?emailMessageInstance.message.messageData.subject:@""];
        [notification setSoundName:@"Morse"];
        [notification setUserInfo:@{@"messageID":emailMessageInstance.message.messageid?emailMessageInstance.message.messageid:@""}];

        if([emailMessageInstance.message haveProfilePic])
        {
            NSImage* image = [emailMessageInstance.message profilePic];
            if([notification respondsToSelector:@selector(setContentImage:)])
                [notification setContentImage:image];
        }

        if(notification)
            [[UserNotificationHelper sharedInstance].notificationCenter deliverNotification:notification];
    }
}

+ (void)notifyOfMessageBatch:(NSInteger)numberOfMessages
{
    if(NSClassFromString(@"NSUserNotification"))
    {
        NSUserNotification* notification = [NSUserNotification new];
        [notification setHasActionButton:NO];
        [notification setTitle:[NSString stringWithFormat:NSLocalizedString(@"%ld new messages",@"Notification Titel <number of msgs>"), numberOfMessages]];
        [notification setSubtitle:NSLocalizedString(@"Click to view",@"Notification SubTitle")];
        [notification setSoundName:@"Morse"];
        if(notification)
            [[UserNotificationHelper sharedInstance].notificationCenter deliverNotification:notification];
    }
}


- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    [APPDELEGATE.window makeKeyAndOrderFront:self];

    NSDictionary* userInfo = notification.userInfo;
    NSString* messageID = [userInfo valueForKey:@"messageID"];
    [SelectionAndFilterHelper highlightMessageWithID:messageID];
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{

}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

#endif




+ (void)queueMessageInstanceForNotification:(EmailMessageInstance*)messageInstance
{
    NSManagedObjectID* objectID = messageInstance.objectID;

    dispatch_sync([self queue], ^{
        [self.messages addObject:objectID];
    });
}

+ (void)postNotifications
{
    if(self.messages.count==0)
        return;

    [ThreadHelper runAsyncOnMain:^{

        //if the new message is very recent, download it immediately
        for(NSManagedObjectID* messageInstanceObjectID in self.messages)
        {
            NSError* error = nil;
            EmailMessageInstance* messageInstance = (EmailMessageInstance*)[MAIN_CONTEXT existingObjectWithID:messageInstanceObjectID error:&error];
            if(error)
                continue;

            BOOL urgent = [messageInstance.message.dateSent timeIntervalSinceNow]>-60*60;
            if([messageInstance.message.dateSent timeIntervalSinceNow]>-3*24*60*60)
                [DownloadHelper downloadMessageInstance:messageInstance urgent:urgent alsoDownloadAttachments:NO];
        }

        if(self.messages.count>3)
            [UserNotificationHelper notifyOfMessageBatch:self.messages.count];
        else
        {
            //TO DO: take out lock to guard against crashes due to multi-thread access
            NSArray* newMessageObjectIDsCopy = [self.messages copy];

            for(NSManagedObjectID* messageInstanceObjectID in newMessageObjectIDsCopy)
            {
                [UserNotificationHelper notifyOfMessage:messageInstanceObjectID];
            }
        }

        queuedMessageInstances = [NSMutableArray new];

        [CoreDataHelper save];
    }];


}

+ (NSMutableArray*)messages
{
    static dispatch_once_t p1 = 0;

    dispatch_once(&p1, ^{
        queuedMessageInstances = [NSMutableArray new];
    });

    return queuedMessageInstances;
}

+ (dispatch_queue_t)queue
{
    static dispatch_once_t p = 0;

    dispatch_once(&p, ^{
        designatedQueue = dispatch_queue_create("org.mynigma.userNotificationQueue", NULL);
    });

    return designatedQueue;
}


#pragma mark - Setting the unread badge


#if TARGET_OS_IPHONE

#ifdef __IPHONE_8_0

+ (BOOL)checkNotificationType:(UIUserNotificationType)type
{
    UIUserNotificationSettings *currentSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];

    return (currentSettings.types & type);
}

#endif

+ (void)setUnreadBadgeTo:(NSInteger)badgeNumber
{
    UIApplication *application = [UIApplication sharedApplication];

#ifdef __IPHONE_8_0
    // compile with Xcode 6 or higher (iOS SDK >= 8.0)

    if(SYSTEM_VERSION_LESS_THAN(@"8.0"))
    {
        application.applicationIconBadgeNumber = badgeNumber;
    }
    else
    {
        if ([self checkNotificationType:UIUserNotificationTypeBadge])
        {
//            NSLog(@"badge number changed to %ld", (long)badgeNumber);
            application.applicationIconBadgeNumber = badgeNumber;
        }
//        else
//            NSLog(@"access denied for UIUserNotificationTypeBadge");
    }

#else
    // compile with Xcode 5 (iOS SDK < 8.0)
    application.applicationIconBadgeNumber = badgeNumber;

#endif
    
}

#else

+ (void)setUnreadBadgeTo:(NSInteger)badgeNumber
{
    if(badgeNumber)
    {
        [[[NSApplication sharedApplication] dockTile] setBadgeLabel:[NSString stringWithFormat:@"%ld", badgeNumber]];
    }
    else
    {
        [[[NSApplication sharedApplication] dockTile] setBadgeLabel:@""];
    }
}

#endif

@end
