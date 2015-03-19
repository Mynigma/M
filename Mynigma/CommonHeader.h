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



#ifndef Mynigma_CommonHeader_h
#define Mynigma_CommonHeader_h


#import "ThreadHelper.h"
#import "CoreDataHelper.h"


#define POST_DEVICE_MESSAGES NO
#define PROCESS_DEVICE_MESSAGES NO
#define VERBOSE_TRUST_ESTABLISHMENT NO



#define HEADER_KEY_THREAD_ID @"X-Mynigma-Device-ThreadID"
#define HEADER_KEY_MESSAGE_COMMAND @"X-Mynigma-Device-Command"
#define HEADER_KEY_SENDER_UUID @"X-Mynigma-Device-Sender"
#define HEADER_KEY_TARGET_UUIDS @"X-Mynigma-Device-Targets"



#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#define RUNNING_AT_LEAST_IOS8 SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")

#if TARGET_OS_IPHONE


#define APPDELEGATE ((AppDelegate*)[[UIApplication sharedApplication] delegate])
#define MODEL ((AppDelegate*)[[UIApplication sharedApplication] delegate]).model


#define COLOUR UIColor
#define IMAGE UIImage

#else

#define APPDELEGATE ((AppDelegate*)[[NSApplication sharedApplication] delegate])

#define COLOUR NSColor
#define IMAGE NSImage

//write the log to console.log in Release builds on Mac OS
#ifdef DEBUG
#define REDIRECT_LOG_TO_FILE NO
#else
#define REDIRECT_LOG_TO_FILE YES
#endif

//drag & drop types not applicable to iPhone
#define DRAGANDDROPMESSAGE @"org.mynigma.message"
#define DRAGANDDROPLABEL @"org.mynigma.label"
#define DRAGANDDROPCONTACT @"org.mynigma.contact"
#define DRAGANDDROPEMAIL @"org.mynigma.email"

#endif

//the main context
#define MAIN_CONTEXT ([CoreDataHelper sharedInstance].mainObjectContext)

//the key context
#define KEY_CONTEXT ([CoreDataHelper sharedInstance].keyObjectContext)


#define MYNIGMA_VERSION [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]

//prepare the object for addition to a collection
//if it's nil, it must be replaced by an NSNull object
#define WRAP(object) (object?object:[NSNull null])

//having removed the object from a collection, replace NSNull objects with nil values
#define UNWRAP(object) ([object isEqual:[NSNull null]]?nil:object)

//decrytion result dictionary keys
#define RESULT @"result"
#define DECRYPTED_DATA @"decryptedData"
#define SESSION_KEY_DATA @"sessionKeyData"

//recipient types
#define TYPE_FROM 1
#define TYPE_REPLY_TO 2
#define TYPE_TO 3
#define TYPE_CC 4
#define TYPE_BCC 5

//iff unit tests are running this will return YES
#define IS_IN_TESTING_MODE (NSClassFromString(@"Unit_Tests")!=NULL)

//this returns the main bundle or, if unit tests are running, the unit tests bundle
#define BUNDLE (NSClassFromString(@"Unit_Tests")!=nil)?[NSBundle bundleForClass:[NSClassFromString(@"Unit_Tests") class]]:[NSBundle mainBundle]

//the width of the coloured boxes
#define LEFT_BORDER_OFFSET 10

#define VERBOSE_DELETE NO


#define FONT_SIZE 12


#endif
