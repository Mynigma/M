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
#import <MailCore/MailCore.h>


@interface MCOIMAPSession(CopySession)

- (MCOIMAPSession*)copyThisSession;

@end


@class IMAPFolderSetting;

@protocol AccountCheckDelegate <NSObject>

@required

+ (BOOL)shouldStartCheckingNewMessagesInFolder:(IMAPFolderSetting*)folderSetting userInitiated:(BOOL)userInitiated;
+ (BOOL)shouldStartCheckingOldMessagesInFolder:(IMAPFolderSetting*)folderSetting userInitiated:(BOOL)userInitiated;
+ (BOOL)shouldStartCheckingOldMessagesWithMODSEQInFolder:(IMAPFolderSetting*)folderSetting userInitiated:(BOOL)userInitiated;
+ (BOOL)shouldStartCheckingFolder:(IMAPFolderSetting*)folderSetting userInitiated:(BOOL)userInitiated;
+ (BOOL)shouldMergeLocalChangesInFolder:(IMAPFolderSetting*)folderSetting userInitiated:(BOOL)userInitiated;


+ (void)didCheckNewMessagesInFolder:(NSString*)folderName inAccount:(NSString*)accountName;
+ (void)didCheckOldMessagesInFolder:(IMAPFolderSetting*)folderSetting;
+ (void)didCheckOldMessagesWithMODSEQInFolder:(IMAPFolderSetting*)folderSetting;
+ (void)didCheckFolder:(IMAPFolderSetting*)folderSetting error:(NSError*)error foundNewMessages:(BOOL)foundNew;
+ (void)didMergeLocalChangesInFolder:(IMAPFolderSetting*)folderSetting;


@end



@class IMAPAccountSetting, RegistrationHelper;

@interface AccountCheckManager : NSObject <AccountCheckDelegate>
{
    NSDate* lastTriedAccountCheck; //last time an account check was started (though not necessarily completed)

    NSDate* lastSuccessfulAccountCheck; //last time an account check was completed
}

@property NSTimer* routineCheckTimer;

@property NSMutableSet* foldersBeingChecked;


#pragma mark - ACTION TRIGGERS

+ (void)appReactivated;

+ (void)awakeFromSleep;

+ (void)clickedOnAccountSetting:(IMAPAccountSetting*)accountSetting;

+ (void)initialCheckForAccountSetting:(IMAPAccountSetting*)accountSetting;

+ (void)startupCheckForAccountSetting:(IMAPAccountSetting*)accountSetting;

//+ (void)accountSettingClicked:(IMAPAccountSetting*)accountSetting;

+ (void)iOSBackgroundCheckWithCallback:(void(^)(BOOL successful, BOOL newMessages))callback;

+ (void)manualReload;

+ (void)manualReloadWithProgressCallback:(void(^)(NSArray* namesOfFoldersStillBeingChecked, BOOL allSuccessful))callback;


//+ (void)doneCheckingFolder:(NSManagedObjectID*)folderObjectID error:(NSError*)error foundNewMessages:(BOOL)newMessages;


#pragma mark - DISPATCH & OPERATION QUEUES

+ (dispatch_queue_t)mailcoreDispatchQueue;

+ (NSOperationQueue*)mailcoreOperationQueue;

+ (NSOperationQueue*)searchSignUpOperationQueue;

+ (NSOperationQueue*)userActionOperationQueue;

//+ (NSOperationQueue*)idleOperationQueue;


@end
