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





#import "UserSettings+Category.h"
#import "IMAPAccountSetting.h"
#import "ThreadHelper.h"



static UserSettings* _currentUserSettings;


@implementation UserSettings (Category)

+ (void)setCurrentUserSettings:(UserSettings*)userSettings
{
    _currentUserSettings = userSettings;
}

+ (UserSettings*)currentUserSettings
{
    return _currentUserSettings;
}

+ (UserSettings*)currentUserSettingsInContext:(NSManagedObjectContext*)localContext
{
    __block NSManagedObjectID* userSettingsObjectID = nil;

    [ThreadHelper runSyncOnMain:^{

        userSettingsObjectID = _currentUserSettings.objectID;
    }];

    return (UserSettings*)[localContext objectWithID:userSettingsObjectID];
}

+ (NSSet*)usedAccounts
{
    NSMutableSet* returnValue = [NSMutableSet new];

    for (IMAPAccountSetting* accountSetting in [UserSettings currentUserSettings].accounts)
    {
        if (accountSetting.shouldUse.boolValue)
        {
            [returnValue addObject:accountSetting];
        }
    }

    return returnValue;
}

+ (NSSet*)usedAccountsInContext:(NSManagedObjectContext*)localContext
{
    NSMutableSet* returnValue = [NSMutableSet new];
    
    for (IMAPAccountSetting* accountSetting in [UserSettings currentUserSettingsInContext:localContext].accounts)
    {
        if (accountSetting.shouldUse.boolValue)
        {
            [returnValue addObject:accountSetting];
        }
    }
    
    return returnValue;
}

@end
