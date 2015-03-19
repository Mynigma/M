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





#import "CoreDataHelper.h"
#import "ThreadHelper.h"
#import "AppDelegate.h"




@implementation CoreDataHelper

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize storeObjectContext = _storeObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize mainObjectContext = _mainObjectContext;
@synthesize keyObjectContext = _keyObjectContext;





+ (instancetype)sharedInstance
{
    static dispatch_once_t p = 0;

    __strong static id sharedObject = nil;

    dispatch_once(&p, ^{
        sharedObject = [self new];
    });

    return sharedObject;
}


+ (NSURL*)coreDataDirectory
{
    NSURL* url = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    return url;
}


#if TARGET_OS_IPHONE

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"org.mynigma.Mynigma-iOS"];
    if(!bundle)
        NSLog(@"No bundle!");
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:@[bundle]];
    if(!managedObjectModel)
    {
        NSLog(@"No managed object model!!!");
    }
    return managedObjectModel;
}

#else

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel)
    {
        return _managedObjectModel;
    }

    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Mynigma" withExtension:@"momd"];

    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

#endif


+ (NSURL*)coreDataStoreURL
{
    NSURL* storeURL = [[AppDelegate applicationFilesDirectory] URLByAppendingPathComponent:@"Mynigma.storedata"];

    [storeURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];

    return storeURL;
}


// Returns the store object context for the application (which is already bound to the persistent store coordinator for the application.)
- (NSManagedObjectContext *)storeObjectContext
{
    if (_storeObjectContext)
    {
        return _storeObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];

#if TARGET_OS_IPHONE

        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Store incompatibility", nil) message:NSLocalizedString(@"The store on disk is incompatible with this version. Would you like to delete the current store?",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Delete store",@"Delete Store Button"), nil];

        [alert show];

        return nil;

#else

        NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"The store on disk is incompatible with this version. Would you like to delete the current store?",nil) defaultButton:NSLocalizedString(@"Cancel",@"Cancel Button") alternateButton:NSLocalizedString(@"Delete store",@"Delete Store Button") otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Note: This will remove all data and settings!!",nil)];

        switch([alert runModal])
        {
            case NSAlertDefaultReturn:
                [NSApp terminate:self];
                return nil;
            case NSAlertAlternateReturn:
            {
                NSURL *applicationFilesDirectory = [AppDelegate applicationFilesDirectory];
                NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"Mynigma.storedata"];

                [url setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];

                [[NSFileManager defaultManager] removeItemAtPath:url.path error:nil];
                if (![self persistentStoreCoordinator])
                {
                    NSLog(@"Unresolved error!!");
                    [NSApp terminate:self];
                }
            }
        }

#endif


    }
    _storeObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_storeObjectContext setUndoManager:nil];
    [_storeObjectContext setPersistentStoreCoordinator:coordinator];
    [_storeObjectContext setMergePolicy:NSErrorMergePolicy];

    return _storeObjectContext;
}




//returns the main object context (which is a child of the store context and runs on the main thread)
- (NSManagedObjectContext *)mainObjectContext
{
    if (_mainObjectContext)
    {
        return _mainObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator)
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];

#if TARGET_OS_IPHONE

        return nil;

#else

        NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"The store on disk is incompatible with this version. Would you like to delete the current store?",nil) defaultButton:NSLocalizedString(@"Cancel",@"Cancel Button") alternateButton:NSLocalizedString(@"Delete store",@"Delete Store Button") otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Note: This will remove all data and settings!!",nil)];
        //NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        //[[NSApplication sharedApplication] presentError:error];
        switch([alert runModal])
        {
            case NSAlertDefaultReturn:
                [NSApp terminate:self];
                return nil;
            case NSAlertAlternateReturn:
            {
                NSURL *url = [CoreDataHelper coreDataStoreURL];

                [url setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];

                [[NSFileManager defaultManager] removeItemAtPath:url.path error:nil];
                if (![self persistentStoreCoordinator])
                {
                    NSLog(@"Unresolved error!!");
                    [NSApp terminate:self];
                }
            }
        }

#endif

    }


    _mainObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];

    //Undo Support
    //NSUndoManager* undoManager = [NSUndoManager new];
    [_mainObjectContext setUndoManager:nil];
    //[_mainObjectContext.undoManager disableUndoRegistration];
    [_mainObjectContext setMergePolicy:NSErrorMergePolicy];

    NSManagedObjectContext* storeContext = [self storeObjectContext];

    if(storeContext)
        [_mainObjectContext setParentContext:storeContext];

    return _mainObjectContext;
}

//returns the main object context (which is a child of the store context and runs on the main thread)
- (NSManagedObjectContext *)keyObjectContext
{
    if (!_keyObjectContext)
    {
        NSManagedObjectContext* localContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [localContext setParentContext:MAIN_CONTEXT];
        [localContext setMergePolicy:NSErrorMergePolicy];
        [localContext setUndoManager:nil];

        _keyObjectContext = localContext;
    }

    return _keyObjectContext;
}

//unit test will use an in-memory type instead
+ (NSString*)coreDataStoreType
{
    return NSSQLiteStoreType;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if(persistentStoreCoordinator)
    {
        return persistentStoreCoordinator;
    }

    NSManagedObjectModel *mom = [self managedObjectModel];
    if(!mom)
    {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [AppDelegate applicationFilesDirectory];
    NSError *error = nil;

    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];

    if(!properties)
    {
        BOOL ok = NO;
        if([error code] == NSFileReadNoSuchFileError)
        {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if(!ok)
        {
            NSLog(@"Error creating directory: %@", error);
            return nil;
        }
    }
    else
    {
        if (![[properties valueForKey:NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:NSLocalizedString(@"Expected a folder to store application data, found a file (%@).",@"The filename"), [applicationFilesDirectory path]];

            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];

            NSLog(@"Error creating store: %@", error);
            return nil;
        }
    }

    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"Mynigma.storedata"];



    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];

    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption:@YES,
                              NSInferMappingModelAutomaticallyOption:@YES};

    if (![coordinator addPersistentStoreWithType:[CoreDataHelper coreDataStoreType] configuration:nil URL:url options:options error:&error]) {
        NSLog(@"Error creating persistent store: %@", error);
        return nil;
    }
    _persistentStoreCoordinator = coordinator;
    
    return _persistentStoreCoordinator;
}


- (BOOL)haveInitialisedManagedObjectContext
{
    return _mainObjectContext != nil;
}



#pragma mark -
#pragma mark SAVING


//saves the main context, but not the (parent) store context
+ (void)saveOnlyMain
{
    [self saveOnlyMainWithCallback:nil];
}

//saves the main context, but not the store context, then executes the callback
+ (void)saveOnlyMainWithCallback:(void(^)(void))callback
{
    //NSLog(@"Saving... ");

    [ThreadHelper runAsyncOnMain:^{

        @try {
            NSError* error = nil;
            [[CoreDataHelper sharedInstance].mainObjectContext save:&error];
            if(error)
                NSLog(@"Error saving main object context: %@",error);

        }
        @catch (NSException *exception) {
            NSLog(@"Exception while trying to save main context: %@", exception);
        }
        @finally {

        }

        if(callback)
            callback();
    }];
}


//saves the main context and then the store context (asynchronously)
+ (void)save
{
    [self saveWithCallback:nil];
}

+ (void)saveAndWait
{
    [ThreadHelper runSyncOnMain:^{

        @try {
            NSError* error = nil;
            [[CoreDataHelper sharedInstance].mainObjectContext save:&error];
            if(error)
                NSLog(@"Error saving main object context: %@",error);

        }
        @catch (NSException *exception) {
            NSLog(@"Exception while trying to save main context: %@", exception);
        }
        @finally {

        }

        [[CoreDataHelper sharedInstance].storeObjectContext performBlockAndWait:^{

            @try {
                NSError* error = nil;
                [[CoreDataHelper sharedInstance].storeObjectContext save:&error];
                if(error)
                    NSLog(@"Error saving store object context: %@",error);
            }
            @catch (NSException *exception) {
                NSLog(@"Exception while trying to save main context: %@", exception);
            }
            @finally {

            }
        }];

    }];
}

//saves the main context and then the store context asynchronously and then executes the callback
+ (void)saveWithCallback:(void(^)(void))callback
{
    [self saveOnlyMainWithCallback:^{

        if(callback)
            callback();

            [self saveOnlyStoreContextWithCallback:nil];
    }];
}

+ (void)saveOnlyStoreContextWithCallback:(void(^)(void))callback
{
    [[CoreDataHelper sharedInstance].storeObjectContext performBlock:^{
        
    @try {
        NSError* error = nil;
        [[CoreDataHelper sharedInstance].storeObjectContext save:&error];
        if(error)
            NSLog(@"Error saving store object context: %@",error);
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while trying to save main context: %@", exception);
    }
    @finally {
        
        if(callback)
            callback();
    }
    }];
}


@end
