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
#import "AppDelegate.h"


@class EmailMessageInstance;

//standard colours

#if TARGET_OS_IPHONE

#define SAFE_COLOUR [COLOUR colorWithRed:214/255. green:240/255. blue:209/255. alpha:1]
#define SAFE_FAINT_COLOUR [COLOUR colorWithDeviceRed:247/255. green:255/255. blue:247/255. alpha:1]

#define OPEN_COLOUR [COLOUR colorWithRed:255/255. green:255/255. blue:255/255. alpha:1]

#define SAFE_DARK_COLOUR [COLOUR colorWithRed:18/255. green:133/255. blue:43/255. alpha:1]
#define OPEN_DARK_COLOUR [COLOUR colorWithRed:200/255. green:41/255. blue:26/255. alpha:1]


#define SEND_COLOUR [COLOUR colorWithDeviceCyan:20./255 magenta:0./255 yellow:20./255 black:0 alpha:1]

#define OPEN_BAR_COLOUR [COLOUR colorWithRed:191/255. green:74/255. blue:91/255. alpha:1]
#define SAFE_BAR_COLOUR [COLOUR colorWithRed:38/255. green:164/255. blue:99/255. alpha:1]


#define UNREAD_COLOUR [COLOUR colorWithRed:210/255. green:227/255. blue:239/255. alpha:1]

#define ATTACHMENT_COLOUR [COLOUR colorWithRed:242/255. green:242/255. blue:218/255. alpha:1]
#define DOWNLOAD_COLOUR [COLOUR colorWithRed:242/255. green:242/255. blue:242/255. alpha:1]
#define FLAGGED_COLOUR [COLOUR colorWithRed:242/255. green:218/255. blue:218/255. alpha:1]
#define FORWARDED_COLOUR [COLOUR colorWithRed:231/255. green:242/255. blue:242/255. alpha:1]
#define REPLIED_COLOUR [COLOUR colorWithRed:242/255. green:231/255. blue:231/255. alpha:1]


#define SAFE_SHADOW_COLOUR [COLOUR colorWithRed:25/255. green:156/255. blue:56/255. alpha:1]
#define OPEN_SHADOW_COLOUR [COLOUR colorWithRed:114./255 green:47./255 blue:77./255 alpha:1]

#define SAFE_SHADOW_BUTTON_COLOUR [COLOUR colorWithRed:25/255. green:156/255. blue:56/255. alpha:0.6]
//#define OPEN_SHADOW_BUTTON_COLOUR [COLOUR colorWithDeviceCyan:125./255 magenta:255./255 yellow:125./255 black:0 alpha:0.6]

#define SAFE_TOKENFIELD_BACKGROUND_COLOUR [COLOUR colorWithRed:219/255. green:236/255. blue:201/255. alpha:1]
#define OPEN_TOKENFIELD_BACKGROUND_COLOUR [COLOUR colorWithRed:248/255. green:218/255. blue:226/255. alpha:1]


#define SAFE_TOKENFIELD_BACKGROUND_COLOUR_UNFOCUSSED [COLOUR colorWithRed:247/255. green:255/255. blue:247/255. alpha:1]
#define OPEN_TOKENFIELD_BACKGROUND_COLOUR_UNFOCUSSED [COLOUR colorWithRed:255/255. green:247/255. blue:247/255. alpha:1]

#define HAVE_ATTACHMENTS_COLOUR [COLOUR colorWithDeviceRed:0/255. green:0/255. blue:255/255. alpha:0.6]



#define ACCOUNTS_LIST_COLOUR [COLOUR colorWithRed:54/255. green:69/255. blue:105/255. alpha:1]

#define DARK_BLUE_COLOUR [COLOUR colorWithRed:41/255. green:52/255. blue:86/255. alpha:1]
#define DARKISH_BLUE_COLOUR [COLOUR colorWithRed:0/255. green:61/255. blue:118/255. alpha:1]
#define SELECTION_BLUE_COLOUR [COLOUR colorWithRed:51/255. green:82/255. blue:126/255. alpha:1]
#define NAVBAR_COLOUR [COLOUR colorWithRed:51/255. green:82/255. blue:126/255. alpha:1]


#define SAFE_BG_COLOUR [COLOUR colorWithRed:215/255. green:242/255. blue:212/255. alpha:1]


#define ACCOUNT_SELECTION_COLOUR [COLOUR colorWithRed:51/255. green:82/255. blue:126/255. alpha:1]


#else

#define SAFE_COLOUR [COLOUR colorWithDeviceRed:214/255. green:240/255. blue:209/255. alpha:1]
#define SAFE_FAINT_COLOUR [COLOUR colorWithDeviceRed:247/255. green:255/255. blue:247/255. alpha:1]

#define OPEN_COLOUR [COLOUR colorWithDeviceRed:255/255. green:255/255. blue:255/255. alpha:1]

#define SAFE_DARK_COLOUR [COLOUR colorWithDeviceRed:28/255. green:143/255. blue:42/255. alpha:1]
#define OPEN_DARK_COLOUR [COLOUR colorWithDeviceRed:202/255. green:34/255. blue:0/255. alpha:1]

#define SAFE_SELECTED_COLOUR [COLOUR colorWithDeviceRed:65/255. green:196/255. blue:96/255. alpha:1]
#define OPEN_SELECTED_COLOUR [COLOUR colorWithDeviceRed:242/255. green:74/255. blue:40/255. alpha:1]

#define SEND_COLOUR [COLOUR colorWithDeviceCyan:20./255 magenta:0./255 yellow:20./255 black:0 alpha:1]

#define OPEN_BAR_COLOUR [COLOUR colorWithDeviceRed:191/255. green:74/255. blue:91/255. alpha:1]
#define SAFE_BAR_COLOUR [COLOUR colorWithDeviceRed:38/255. green:164/255. blue:99/255. alpha:1]


#define UNREAD_COLOUR [COLOUR colorWithDeviceRed:210/255. green:227/255. blue:239/255. alpha:1]

#define ATTACHMENT_COLOUR [COLOUR colorWithDeviceRed:242/255. green:242/255. blue:218/255. alpha:1]
#define DOWNLOAD_COLOUR [COLOUR colorWithDeviceRed:242/255. green:242/255. blue:242/255. alpha:1]
#define FLAGGED_COLOUR [COLOUR colorWithDeviceRed:242/255. green:218/255. blue:218/255. alpha:1]
#define FORWARDED_COLOUR [COLOUR colorWithDeviceRed:231/255. green:242/255. blue:242/255. alpha:1]
#define REPLIED_COLOUR [COLOUR colorWithDeviceRed:242/255. green:231/255. blue:231/255. alpha:1]


#define SAFE_SHADOW_COLOUR [COLOUR colorWithDeviceRed:25/255. green:156/255. blue:56/255. alpha:1]
#define OPEN_SHADOW_COLOUR [COLOUR colorWithDeviceRed:114./255 green:47./255 blue:77./255 alpha:1]

#define SAFE_SHADOW_BUTTON_COLOUR [COLOUR colorWithDeviceRed:25/255. green:156/255. blue:56/255. alpha:0.6]
//#define OPEN_SHADOW_BUTTON_COLOUR [COLOUR colorWithDeviceCyan:125./255 magenta:255./255 yellow:125./255 black:0 alpha:0.6]

#define SAFE_TOKENFIELD_BACKGROUND_COLOUR [COLOUR colorWithDeviceRed:219/255. green:236/255. blue:201/255. alpha:1]
#define OPEN_TOKENFIELD_BACKGROUND_COLOUR [COLOUR colorWithDeviceRed:255/255. green:189/255. blue:199/255. alpha:1]

#define SAFE_TOKENFIELD_BACKGROUND_COLOUR_UNFOCUSSED [COLOUR colorWithDeviceRed:247/255. green:255/255. blue:247/255. alpha:1]
#define OPEN_TOKENFIELD_BACKGROUND_COLOUR_UNFOCUSSED [COLOUR colorWithDeviceRed:255/255. green:247/255. blue:247/255. alpha:1]

#define SAFE_TOKENFIELD_BORDER_COLOUR [COLOUR colorWithDeviceRed:0/255. green:255/255. blue:0/255. alpha:1]

#define OPEN_TOKENFIELD_BORDER_COLOUR [COLOUR colorWithDeviceRed:255/255. green:0/255. blue:0/255. alpha:1]

#define HAVE_ATTACHMENTS_COLOUR [COLOUR colorWithDeviceRed:0/255. green:0/255. blue:255/255. alpha:0.6]




#define MYNIGMA_COLOUR [COLOUR colorWithDeviceRed:38/255. green:88/255. blue:147/255. alpha:1]
#define DARK_BLUE_COLOUR [COLOUR colorWithDeviceRed:41/255. green:52/255. blue:86/255. alpha:1]
#define DARKISH_BLUE_COLOUR [COLOUR colorWithDeviceRed:0/255. green:61/255. blue:118/255. alpha:1]
//#define SELECTION_BLUE_COLOUR [COLOUR colorWithDeviceRed:51/255. green:82/255. blue:126/255. alpha:1]
#define NAVBAR_COLOUR [COLOUR colorWithDeviceRed:51/255. green:82/255. blue:126/255. alpha:1]
#define FOLDER_SELECTION_COLOUR [COLOUR colorWithDeviceRed:91/255. green:132/255. blue:176/255. alpha:1]
#define SELECTION_BLUE_COLOUR [COLOUR colorWithCalibratedRed:151/255. green:182/255. blue:255/255. alpha:.8]



#define SAFE_BG_COLOUR [COLOUR colorWithDeviceRed:215/255. green:242/255. blue:212/255. alpha:1]

//#define ACCOUNT_SELECTION_COLOUR [COLOUR colorWithCalibratedRed:151/255. green:182/255. blue:255/255. alpha:.8]

#define ACCOUNT_SELECTION_COLOUR [COLOUR colorWithCalibratedRed:51/255. green:82/255. blue:126/255. alpha:1]


#define ACCOUNTS_LIST_COLOUR [COLOUR colorWithDeviceRed:54/255. green:69/255. blue:105/255. alpha:1]
#define DISABLED_DARK_COLOUR [COLOUR colorWithDeviceRed:29/255. green:44/255. blue:77/255. alpha:1]

//#define ACCOUNTS_LIST_COLOUR [COLOUR colorWithDeviceRed:43/255. green:90/255. blue:145/255. alpha:1]


#endif


@interface IconListAndColourHelper : NSObject


#pragma mark - Icon list

//returns a dictionary contain the icon and the background colour for each icon that is to be displayed on the left edge of an item in the message list
+ (NSArray*)leftEdgeIconsForMessageInstance:(EmailMessageInstance*)messageInstance;

//returns the list of additional icons that should appear toward the bottom of the message list item, just right of the left border
+ (NSArray*)otherIconsForMessageInstance:(EmailMessageInstance*)messageInstance;

//returns a dictionary contain the icon and the background colour for each icon that is to be displayed on the left edge of an item in the message list
+ (NSArray*)leftEdgeIconsForMessage:(EmailMessage*)message;

//returns the list of additional icons that should appear toward the bottom of the message list item, just right of the left border
+ (NSArray*)otherIconsForMessage:(EmailMessage*)message;


@end
