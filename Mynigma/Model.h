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

@class UserSettings, Message, User, IMAPAccount, EmailContactDetail, GmailAccountSetting, MessageSieve, Settings, Contact, MessageViewerRenderer, GmailAccount, KeychainHelper, EncryptionHelper, MynigmaDevice, EmailMessage, MynigmaControlMessagesEngine, ServerHelper, NSManagedObjectID, IMAPFolderSetting, MynigmaMessage, FileAttachment;

@interface Model : NSObject
{
    //the UserSettings object in the store that holds information on set up accounts, preferences, etc.
    UserSettings* currentUserSettings;
    
    //dict of all email addresses - needed to ensure that tasks in different threads do not add the same address independently of each other
    //keys: email address strings (all lowercase), values: object IDs of EmailContactDetails
    //NSMutableDictionary* allEmailAddresses;

    //dict of all messages - used to find messages quickly by messageID
    //keys: messageIDs (strings), values: object IDs of EmailMessages
    //NSMutableDictionary* allMessages;
    
    //dict of all contacts - used to get completion list for partial input strings etc.
    //keys: names of contacts in "FirstName LastName" as well as "LastName, FirstName" format, values: object IDs of Contacts
    //NSMutableDictionary* allContacts;


    NSMutableSet* objectsBeingDownloaded;

    NSMutableSet* objectsBeingDecrypted;

    NSMutableSet* objectsBeingCleaned;
}

@property NSMutableSet* objectsBeingDownloaded;

@property NSMutableSet* objectsBeingDecrypted;

@property NSMutableSet* objectsBeingCleaned;



//the UserSettings object in the store that holds information on set up accounts, preferences, etc.
@property UserSettings* currentUserSettings;

//dict of all email addresses - needed to ensure that tasks in different threads do not add the same address independently of each other
//@property NSMutableDictionary* allEmailAddresses;

//dict of all messages - used to find messages quickly by messageID
//@property NSMutableDictionary* allMessages;

//dict of all contacts - used to get completion list for partial input strings, checking contacts with server, etc.
//@property NSMutableDictionary* allContacts;



//the device the app is being run on
@property MynigmaDevice* currentDevice;




@end
