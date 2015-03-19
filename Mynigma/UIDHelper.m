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



#import "UIDHelper.h"
#import "IMAPFolderSetting+Category.h"
#import "ThreadHelper.h"


static NSMutableDictionary* uidFolderIndex;
static dispatch_queue_t uidIndexingQueue;

BOOL haveCompiledUIDIndex;



@implementation UIDHelper

#pragma mark - PRIVATE METHODS

+ (dispatch_queue_t)uidIndexQueue
{
    if(!uidIndexingQueue)
        uidIndexingQueue = dispatch_queue_create("org.mynigma.uidIndexQueue", NULL);
    
    return uidIndexingQueue;
}

+ (NSIndexSet*)fetchUidsFromStoreForFolder:(IMAPFolderSetting*)folderSetting
{
    //don't use temporary objectIDs as keys
    if(folderSetting.objectID.isTemporaryID)
    {
        [folderSetting.managedObjectContext obtainPermanentIDsForObjects:@[folderSetting] error:nil];
    }
    
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"EmailMessageInstance"];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"EmailMessageInstance" inManagedObjectContext:folderSetting.managedObjectContext];
    
    NSDictionary *entityProperties = [entity propertiesByName];
    
    [request setPredicate:[NSPredicate predicateWithFormat:@"inFolder == %@", folderSetting]];
    [request setEntity:entity];
    [request setReturnsDistinctResults:YES];
    [request setResultType:NSDictionaryResultType];
    
    NSPropertyDescription* UIDProperty = [entityProperties objectForKey:@"uid"];
    
    [request setPropertiesToFetch:@[UIDProperty]];
    
    NSArray* results = [folderSetting.managedObjectContext executeFetchRequest:request error:nil];
    
    
    NSMutableIndexSet* newIndexSet = [NSMutableIndexSet new];
    
    for(NSDictionary* uidDict in results)
    {
        [newIndexSet addIndex:[uidDict[@"uid"] integerValue]];
    }

    NSManagedObjectID* key = folderSetting.objectID;

    dispatch_sync([self uidIndexQueue], ^{

        [uidFolderIndex setObject:newIndexSet forKey:key];

    });

    return newIndexSet;
    
}



#pragma mark - PUBLIC METHODS


+ (void)compileUIDinFolderIndex
{
    haveCompiledUIDIndex = NO;

    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext){
        
        //create a fresh index
        uidFolderIndex = [NSMutableDictionary new];
        
        //fetch all instances
        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"EmailMessageInstance"];
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"EmailMessageInstance" inManagedObjectContext:localContext];
        
        NSDictionary *entityProperties = [entity propertiesByName];
        
        [request setPredicate:[NSPredicate predicateWithFormat:@"inFolder != nil"]];
        [request setEntity:entity];
        [request setReturnsDistinctResults:YES];
        [request setResultType:NSDictionaryResultType];
        
        NSPropertyDescription* UIDProperty = [entityProperties objectForKey:@"uid"];

        NSExpressionDescription* inFolderObjectIDProperty = [NSExpressionDescription new];
        inFolderObjectIDProperty.name = @"inFolderObjectID";
        inFolderObjectIDProperty.expression = [NSExpression expressionForKeyPath:@"inFolder"];
        inFolderObjectIDProperty.expressionResultType = NSObjectIDAttributeType;
        
        [request setPropertiesToFetch:@[UIDProperty, inFolderObjectIDProperty]];
        
        NSError* error = nil;
        NSArray* results = [localContext executeFetchRequest:request error:&error];
        if(error)
        {
            NSLog(@"Error fetching instances array!!!");
        }
        
        for(NSDictionary* resultDict in results)
        {
            NSInteger uid = [resultDict[@"uid"] integerValue];
            NSManagedObjectID* inFolderObjectID = resultDict[@"inFolderObjectID"];
            
            if (inFolderObjectID && uid)
            {
                dispatch_sync([self uidIndexQueue], ^{

                    NSMutableIndexSet* uidSet = (NSMutableIndexSet*)[uidFolderIndex objectForKey:inFolderObjectID];

                if(!uidSet)
                {
                    uidSet = [NSMutableIndexSet new];
                    [uidFolderIndex setObject:uidSet forKey:inFolderObjectID];
                }

                    [uidSet addIndex:uid];

                    });
            }
        }
        
        haveCompiledUIDIndex = YES;
        
        NSLog(@"Done compiling uid in folder index");
        
    }];
}


+ (NSIndexSet*)UIDsInFolder:(IMAPFolderSetting*)folderSetting
{
    if(folderSetting.objectID.isTemporaryID)
    {
        [folderSetting.managedObjectContext obtainPermanentIDsForObjects:@[folderSetting] error:nil];
    }
    
    NSManagedObjectID* key = folderSetting.objectID;

    __block NSIndexSet* uidSet = nil;

    dispatch_sync([self uidIndexQueue], ^{
        uidSet = [[uidFolderIndex objectForKey:key] copy];
    });
    
    if (uidSet)
        return uidSet;
    else
        return [self fetchUidsFromStoreForFolder:folderSetting];
}

+ (void)addUID:(NSInteger)UIDIndex toFolder:(IMAPFolderSetting*)folderSetting
{
    if(folderSetting.objectID.isTemporaryID)
    {
        [folderSetting.managedObjectContext obtainPermanentIDsForObjects:@[folderSetting] error:nil];
    }
    
    NSManagedObjectID* key = folderSetting.objectID;
    
    if (key)
    {
        dispatch_sync([self uidIndexQueue], ^{

            NSMutableIndexSet* uidSet = [uidFolderIndex objectForKey:key];

            if(!uidSet)
            {
                uidSet = [NSMutableIndexSet new];
                [uidFolderIndex setObject:uidSet forKey:key];
            }

            [uidSet addIndex:UIDIndex];

        });
    }
}

+ (void)removeUID:(NSInteger)UIDIndex fromFolder:(IMAPFolderSetting*)folderSetting
{
    if(UIDIndex == 0 || !folderSetting)
        return;
    
    if(folderSetting.objectID.isTemporaryID)
    {
        [folderSetting.managedObjectContext obtainPermanentIDsForObjects:@[folderSetting] error:nil];
    }
    
    NSManagedObjectID* key = folderSetting.objectID;
    
    if (key)
    {
        dispatch_sync([self uidIndexQueue], ^{

            NSMutableIndexSet* uidSet = [uidFolderIndex objectForKey:key];

        if ([uidSet isKindOfClass:[NSIndexSet class]] && [uidSet containsIndex:UIDIndex])
        {
            [uidSet removeIndex:UIDIndex];
        }
        });
    }
}


@end
