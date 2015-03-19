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

@interface CoreDataHelper : NSObject
{
    //store coordinator and managed object contexts
    NSPersistentStoreCoordinator* persistentStoreCoordinator;
    NSManagedObjectModel* managedObjectModel;
    NSManagedObjectContext* mainObjectContext;
    NSManagedObjectContext* storeObjectContext;

    //the object context used for storing and fetching keys
    NSManagedObjectContext* keyObjectContext;
}


//store coordinator and managed object contexts
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *mainObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectContext *storeObjectContext;

//the object context used for storing and fetching keys
@property (readonly, strong, nonatomic) NSManagedObjectContext* keyObjectContext;


+ (instancetype)sharedInstance;




+ (NSString*)coreDataStoreType;

+ (NSURL*)coreDataStoreURL;

- (BOOL)haveInitialisedManagedObjectContext;



#pragma mark -
#pragma mark SAVING


+ (void)saveOnlyMain;
+ (void)saveOnlyMainWithCallback:(void(^)(void))callback;
+ (void)save;
+ (void)saveAndWait;
+ (void)saveWithCallback:(void(^)(void))callback;
+ (void)saveOnlyStoreContextWithCallback:(void(^)(void))callback;


@end
