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





#import "AppDelegate.h"
#import "IconListAndColourHelper.h"
#import "EmailMessage+Category.h"
#import "MynigmaMessage+Category.h"
#import <MailCore/MailCore.h>
#import "UserSettings.h"
#import "EmailMessageInstance+Category.h"
#import "DeviceMessage+Category.h"

#if ULTIMATE

#import "CustomerManager.h"

#endif



@implementation IconListAndColourHelper


#pragma mark - ICON LIST

//returns a dictionary contain the icon and the background colour for each icon that is to be displayed on the left edge of an item in the message list
+ (NSArray*)leftEdgeIconsForMessageInstance:(EmailMessageInstance*)messageInstance
{
    if(!messageInstance)
        return @[];
    
    NSMutableArray* returnArray = [NSMutableArray new];

    if(messageInstance)
    {
        //message is safe
        if([messageInstance isSafe])
        {
            IMAGE* image = [IMAGE imageNamed:@"lockClosed16"];

            if(SAFE_DARK_COLOUR && image)
                [returnArray addObject:@{@"image":image, @"colour":SAFE_DARK_COLOUR, @"colourBG":SAFE_DARK_COLOUR, @"tooltip":NSLocalizedString(@"Safe message", @"Safe, secure email message")}];
        }


        //message is unread
        if([messageInstance isUnread])
        {
            IMAGE* image = [IMAGE imageNamed:@"unreadFilled16"];

            if(ACCOUNTS_LIST_COLOUR && image)
                [returnArray addObject:@{@"image":image, @"colour":ACCOUNTS_LIST_COLOUR, @"colourBG":ACCOUNTS_LIST_COLOUR, @"tooltip":NSLocalizedString(@"Unread message",@"Tooltip Unread message")}];
        }
    }
    
    return returnArray;
}


//returns the list of additional icons that should appear toward the bottom of the message list item, just right of the left border
+ (NSArray*)otherIconsForMessageInstance:(EmailMessageInstance*)messageInstance
{
    if(!messageInstance)
        return @[];

    NSMutableArray* newList = [@[] mutableCopy];

    //these icons should never be shown on the left

    //message is safe
    if([messageInstance.message isSafe])
    {
        IMAGE* image = [IMAGE imageNamed:@"lockClosed16"];

        if(SAFE_DARK_COLOUR && image)
            [newList addObject:@{@"image":image, @"colour":SAFE_DARK_COLOUR, @"colourBG":[COLOUR whiteColor], @"tooltip":NSLocalizedString(@"Safe message", @"Safe, secure email message")}];
    }

    //message is unread
    if([messageInstance isUnread])
    {
        IMAGE* image = [IMAGE imageNamed:@"unreadFilled16"];

        if(NAVBAR_COLOUR && image)
            [newList addObject:@{@"image":image, @"colour":NAVBAR_COLOUR, @"colourBG":[COLOUR whiteColor], @"colourBG":[COLOUR whiteColor], @"tooltip":NSLocalizedString(@"Unread message",@"Tooltip Unread message")}];
    }

    //message has attachments
    if(messageInstance.message.allAttachments.count>0)
    {
        IMAGE* image = [IMAGE imageNamed:@"attachment16"];

        if(ATTACHMENT_COLOUR && image)
            [newList addObject:@{@"image":image, @"colourBG":[COLOUR whiteColor], @"colour":ATTACHMENT_COLOUR, @"tooltip":NSLocalizedString(@"Attachments",@"Tooltip Attachments")}];
    }

    //no need for the star - it's displayed in the upper right hand corner

    //message is flagged
//    if([messageInstance isFlagged])
//    {
//        if(!messageListColour_flagged)
//            messageListColour_flagged = FLAGGED_COLOUR;
//
//        IMAGE* image = [IMAGE imageNamed:@"starred16"];
//
//        if(messageListColour_flagged && image)
//            [newList addObject:@{@"image":image, @"colour":messageListColour_flagged, @"colourBG":[COLOUR whiteColor], @"tooltip":NSLocalizedString(@"Flagged message", @"Tooltip Flagged message")}];
//    }
//

    if(![messageInstance.message isDownloaded])
    {
        IMAGE* image = [IMAGE imageNamed:@"cloudSmallWhite16"];

        if(DOWNLOAD_COLOUR && image)
            [newList addObject:@{@"image":image, @"colour":DOWNLOAD_COLOUR, @"colourBG":[COLOUR whiteColor], @"tooltip":NSLocalizedString(@"Downloading message", @"Tooltip Downloading message")}];
    }

    //the message has been forwarded
    if(messageInstance.flags.intValue & MCOMessageFlagForwarded)
    {
        IMAGE* image = [IMAGE imageNamed:@"forwardWhite16"];

        if(FORWARDED_COLOUR && image)
            [newList addObject:@{@"image":image, @"colour":FORWARDED_COLOUR, @"colourBG":[COLOUR whiteColor], @"tooltip":NSLocalizedString(@"Message has been forwarded", @"Tooltip Message has been forwarded")}];
    }

    //the message has been replied to
    if(messageInstance.flags.intValue & MCOMessageFlagAnswered)
    {
        IMAGE* image = [IMAGE imageNamed:@"reply16"];

        if(REPLIED_COLOUR && image)
            [newList addObject:@{@"image":image, @"colour":REPLIED_COLOUR, @"colourBG":[COLOUR whiteColor], @"tooltip":NSLocalizedString(@"Message has been replied to", @"Tooltip Message has been replied to")}];
    }

    //the message is the current device discovery message
    if([messageInstance.message isKindOfClass:[DeviceMessage class]] && [(DeviceMessage*)messageInstance.message discoveryMessageForDevice])
    {
        IMAGE* image = [IMAGE imageNamed:@"muenzeGrau"];

        if(REPLIED_COLOUR && image)
            [newList addObject:@{@"image":image, @"colour":REPLIED_COLOUR, @"colourBG":[COLOUR whiteColor], @"tooltip":NSLocalizedString(@"This is a device message", @"Tooltip")}];
    }

#if TARGET_OS_IPHONE

#else

#if ULTIMATE

    if([CustomerManager isExclusiveVersion])
    {
        if([messageInstance addedToFolder])
        {
            IMAGE* image = [IMAGE imageNamed:@"cloud.png"];

            if(image)
                [newList addObject:@{@"image":image, @"colour":[COLOUR grayColor], @"colourBG":[COLOUR grayColor], @"tooltip":NSLocalizedString(@"Locally added (not yet synced)", @"Tooltip")}];
        }

        if([messageInstance movedFromInstance])
        {
            IMAGE* image = [IMAGE imageNamed:@"arrowRight.png"];

            if(image)
                [newList addObject:@{@"image":image, @"colour":[COLOUR grayColor], @"colourBG":[COLOUR grayColor], @"tooltip":NSLocalizedString(@"Locally moved to this location (not yet synced)", @"Tooltip")}];
        }
    }

#endif

#endif

    return newList;
}



//returns a dictionary contain the icon and the background colour for each icon that is to be displayed on the left edge of an item in the message list
+ (NSArray*)leftEdgeIconsForMessage:(EmailMessage*)message
{
    if(!message)
        return @[];

    NSMutableArray* returnArray = [NSMutableArray new];

    if(message)
    {
        //message is safe
        if([message isSafe])
        {
            IMAGE* image = [IMAGE imageNamed:@"lockClosed16"];

            if(SAFE_DARK_COLOUR && image)
                [returnArray addObject:@{@"image":image, @"colour":SAFE_DARK_COLOUR, @"colourBG":SAFE_DARK_COLOUR, @"tooltip":NSLocalizedString(@"Safe message", @"Safe, secure email message")}];
        }
    }
    
    return returnArray;
}


//returns the list of additional icons that should appear toward the bottom of the message list item, just right of the left border
+ (NSArray*)otherIconsForMessage:(EmailMessage*)message
{
    if(!message)
        return @[];

    NSMutableArray* newList = [@[] mutableCopy];

    //these icons should never be shown on the left

    //message is safe
    if([message isSafe])
    {
        IMAGE* image = [IMAGE imageNamed:@"lockClosed16"];

        if(SAFE_DARK_COLOUR && image)
            [newList addObject:@{@"image":image, @"colour":SAFE_DARK_COLOUR, @"colourBG":[COLOUR whiteColor], @"tooltip":NSLocalizedString(@"Safe message", @"Safe, secure email message")}];
    }

    //message has attachments
    if(message.allAttachments.count>0)
    {
        IMAGE* image = [IMAGE imageNamed:@"attachment16"];

        if(ATTACHMENT_COLOUR && image)
            [newList addObject:@{@"image":image, @"colourBG":[COLOUR whiteColor], @"colour":ATTACHMENT_COLOUR, @"tooltip":NSLocalizedString(@"Attachments",@"Tooltip Attachments")}];
    }


    if(![message isDownloaded])
    {
        IMAGE* image = [IMAGE imageNamed:@"cloudSmallWhite16"];

        if(DOWNLOAD_COLOUR && image)
            [newList addObject:@{@"image":image, @"colour":DOWNLOAD_COLOUR, @"colourBG":[COLOUR whiteColor], @"tooltip":NSLocalizedString(@"Downloading message", @"Tooltip Downloading message")}];
    }

    return newList;
}


@end
