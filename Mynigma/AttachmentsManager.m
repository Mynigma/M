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
#import "AttachmentsManager.h"
#import "EmailMessage+Category.h"
#import "MynigmaMessage+Category.h"
#import "IMAPFolderSetting+Category.h"
#import "IMAPAccountSetting+Category.h"
#import "IMAPAccount.h"
#import "EmailMessageData.h"
#import "EncryptionHelper.h"
#import "FileAttachment+Category.h"

#if TARGET_OS_IPHONE

#else

#import "AttachmentItem.h"

#endif


static AttachmentsManager* theInstance;

@implementation AttachmentsManager


- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

+ (AttachmentsManager*)sharedInstance
{
    if(!theInstance)
        theInstance = [AttachmentsManager new];

    return theInstance;
}




+ (void)promptUserToSaveAttachment:(FileAttachment*)fileAttachment
{
#if TARGET_OS_IPHONE
    if([fileAttachment.attachedAllToMessage isKindOfClass:[MynigmaMessage class]] && ![fileAttachment isDecrypted])
    {
        [fileAttachment urgentlyDownloadWithCallback:nil];
    }

    if([fileAttachment canBeSavedByUser])
    {
        //else
        //    NSLog(@"Could not find documents directory!!");
    }
    else
        NSLog(@"Cannot prompt user to save attachment! %@", fileAttachment);

#else

    [AttachmentsManager promptUserToSaveAttachment:fileAttachment withWindow:nil];

#endif
}


+ (void)promptUserToSaveAttachments:(NSArray *)attachments
{
#if TARGET_OS_IPHONE
#else

    [AttachmentsManager promptUserToSaveAttachments:attachments withWindow:nil];

#endif
}

/*
//saves a file into the local attachments directory and returns bookmark data on success
+ (NSData*)saveData:(NSData*)fileData

           withName:(NSString*)proposedFileName
{
    NSArray* downloadsDirectoryArray = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
    if(downloadsDirectoryArray.count==0)
    {
        NSLog(@"Downloads folder not found!");
        return nil;
    }

    NSString* mynigmaAttachmentsDirectory = [downloadsDirectoryArray[0] stringByAppendingPathComponent:@"Mynigma Attachments"];

    NSError* error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:mynigmaAttachmentsDirectory withIntermediateDirectories:NO attributes:nil error:&error];

    error = nil;
    NSArray* dirContents = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:mynigmaAttachmentsDirectory error:&error] valueForKey:@"lastPathComponent"];
    if(error)
    {
        NSLog(@"Could not list directory at path %@!!!",mynigmaAttachmentsDirectory);
        return nil;
    }

    if(!proposedFileName)
        proposedFileName = @"Inline-attachment.dat";

    NSString* fileName = proposedFileName;
    NSInteger index = 1;
    while(index<1000 && [dirContents containsObject:fileName])
    {
        fileName = [NSString stringWithFormat:@"%@-%ld.%@",[proposedFileName stringByDeletingPathExtension],index,proposedFileName.pathExtension];
        index++;
    }
    NSString* filePath = [mynigmaAttachmentsDirectory stringByAppendingPathComponent:fileName];
    NSURL*  theFile = [NSURL fileURLWithPath:filePath];
    if([fileData writeToURL:theFile options:0 error:&error])
    {
        NSData* theData = [theFile bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:&error];
        if(error)
        {
            NSLog(@"Error setting bookmark: %@, %@",theFile,error);
            return nil;
        }

        return theData;
    }

    return nil;
}*/

#if TARGET_OS_IPHONE
#else

+ (void)promptUserToSaveAttachment:(FileAttachment*)fileAttachment withWindow:(NSWindow*)window
{
    if([fileAttachment.attachedAllToMessage isKindOfClass:[MynigmaMessage class]] && ![fileAttachment isDecrypted])
    {
        [fileAttachment urgentlyDownloadWithCallback:nil];
    }

    if([fileAttachment canBeSavedByUser])
    {
        NSSavePanel *savePanel = [NSSavePanel savePanel];
        [savePanel setCanCreateDirectories:YES];
        [savePanel setNameFieldStringValue:fileAttachment.fileName];
        //NSArray* documentsDirectoryArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

        //NSArray* urlPaths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];

        //if(documentsDirectoryArray.count>0)
        {
            //NSString* documentsDirectory = documentsDirectoryArray[0];

            //[savePanel setDirectoryURL:[NSURL URLWithString:documentsDirectory]];

            [savePanel beginSheetModalForWindow:APPDELEGATE.window completionHandler:^(NSInteger result){
                if (result == NSFileHandlingPanelOKButton)
                {
                    NSURL*  newURL = [savePanel URL];

                    NSURL *oldURL = [fileAttachment privateURL];

                    if(!oldURL)
                    {
                        oldURL = [fileAttachment publicURL];

                        NSError* error = nil;

                        // in case of replace
                        [newURL startAccessingSecurityScopedResource];
                        [oldURL startAccessingSecurityScopedResource];
                        if(![[NSFileManager defaultManager] copyItemAtURL:oldURL toURL:newURL error:&error])
                        {

                            if ([error code] == NSFileWriteFileExistsError)
                            {
                                if ([[NSFileManager defaultManager] replaceItemAtURL:newURL withItemAtURL:oldURL backupItemName:nil options:NSFileManagerItemReplacementUsingNewMetadataOnly resultingItemURL:nil error:&error])
                                {
                                    [newURL stopAccessingSecurityScopedResource];
                                    [oldURL stopAccessingSecurityScopedResource];
                                    return;
                                }
                            }

                            NSLog(@"Error copying file: %@",error);
                            NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Error copying file", @"File copy operation error") defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", error.localizedDescription];
                            [alert runModal];

                        }
                        [newURL stopAccessingSecurityScopedResource];
                        [oldURL stopAccessingSecurityScopedResource];

                        return;
                    }

                    NSError* error = nil;

                    //no need for these: the private URL is in the App's sandbox...
                    //[oldURL startAccessingSecurityScopedResource];

                    // in case of replace
                    [newURL startAccessingSecurityScopedResource];

                    if(![[NSFileManager defaultManager] copyItemAtURL:oldURL toURL:newURL error:&error])
                    {

                        if ([error code] == NSFileWriteFileExistsError)
                        {
                            if ([[NSFileManager defaultManager] replaceItemAtURL:newURL withItemAtURL:oldURL backupItemName:nil options:NSFileManagerItemReplacementUsingNewMetadataOnly resultingItemURL:nil error:&error])
                            {
                                [newURL stopAccessingSecurityScopedResource];
                                return;
                            }
                        }

                        NSLog(@"Error copying file: %@",error);
                        NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Error copying file", @"File copy operation error") defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", error.localizedDescription];
                        [alert runModal];
                    }

                    [newURL stopAccessingSecurityScopedResource];

                    //[oldURL stopAccessingSecurityScopedResource];

                }
            }];
        }
        //else
        //    NSLog(@"Could not find documents directory!!");
    }
    else
        NSLog(@"Cannot prompt user to save attachment! %@", fileAttachment);
}


+ (void)promptUserToSaveAttachments:(NSArray *)attachments withWindow:(NSWindow*)window
{
    NSOpenPanel *savePanel = [NSOpenPanel openPanel];
    [savePanel setCanCreateDirectories:YES];
    [savePanel setCanSelectHiddenExtension:YES];
    [savePanel setNameFieldStringValue:@""];

    [savePanel setCanChooseFiles:NO];
    [savePanel setCanChooseDirectories:YES];

    [savePanel setPrompt:NSLocalizedString(@"Save", @"Save prompt button")];

    NSArray* documentsDirectoryArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if(documentsDirectoryArray.count>0)
    {
        [savePanel setDirectoryURL:[NSURL URLWithString:documentsDirectoryArray[0]]];

        [savePanel beginSheetModalForWindow:window?window:APPDELEGATE.window completionHandler:^(NSInteger result){
            if (result == NSFileHandlingPanelOKButton)
            {
                NSURL*  newURL = [savePanel URL];
                NSError* error = nil;
                if(!error)
                {
                    for(FileAttachment* fileAttachment in attachments)
                    {
                        NSURL* fileURL = [newURL URLByAppendingPathComponent:[fileAttachment fileName]];
                        NSURL *oldURL = [fileAttachment privateURL];

                        if(!oldURL)
                        {
                            oldURL = [fileAttachment publicURL];

                            if(!oldURL)
                                continue;

                            NSError* error = nil;

                            [oldURL startAccessingSecurityScopedResource];
                            if(![[NSFileManager defaultManager] copyItemAtURL:oldURL toURL:fileURL error:&error])
                                NSLog(@"Error copying file: %@",error);
                            [oldURL stopAccessingSecurityScopedResource];

                            return;
                        }

                        NSError* error = nil;

                        //no need for these: the private URL is in the App's sandbox...
                        //[oldURL startAccessingSecurityScopedResource];
                        if(![[NSFileManager defaultManager] copyItemAtURL:oldURL toURL:fileURL error:&error])
                            NSLog(@"Error copying file: %@",error);
                        //[oldURL stopAccessingSecurityScopedResource];
                    }
                }

            }
        }];
    }
}

#endif



/*
 //saves a file into the local attachments directory and returns bookmark data on success
 + (NSData*)saveData:(NSData*)fileData

 withName:(NSString*)proposedFileName
 {
 NSArray* downloadsDirectoryArray = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
 if(downloadsDirectoryArray.count==0)
 {
 NSLog(@"Downloads folder not found!");
 return nil;
 }

 NSString* mynigmaAttachmentsDirectory = [downloadsDirectoryArray[0] stringByAppendingPathComponent:@"Mynigma Attachments"];

 NSError* error = nil;
 [[NSFileManager defaultManager] createDirectoryAtPath:mynigmaAttachmentsDirectory withIntermediateDirectories:NO attributes:nil error:&error];

 error = nil;
 NSArray* dirContents = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:mynigmaAttachmentsDirectory error:&error] valueForKey:@"lastPathComponent"];
 if(error)
 {
 NSLog(@"Could not list directory at path %@!!!",mynigmaAttachmentsDirectory);
 return nil;
 }

 if(!proposedFileName)
 proposedFileName = @"Inline-attachment.dat";

 NSString* fileName = proposedFileName;
 NSInteger index = 1;
 while(index<1000 && [dirContents containsObject:fileName])
 {
 fileName = [NSString stringWithFormat:@"%@-%ld.%@",[proposedFileName stringByDeletingPathExtension],index,proposedFileName.pathExtension];
 index++;
 }
 NSString* filePath = [mynigmaAttachmentsDirectory stringByAppendingPathComponent:fileName];
 NSURL*  theFile = [NSURL fileURLWithPath:filePath];
 if([fileData writeToURL:theFile options:0 error:&error])
 {
 NSData* theData = [theFile bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:&error];
 if(error)
 {
 NSLog(@"Error setting bookmark: %@, %@",theFile,error);
 return nil;
 }

 return theData;
 }

 return nil;
 }*/




+ (void)saveData:(NSData*)data toPrivateURLForAttachment:(FileAttachment*)attachment
{
    EmailMessage* message = attachment.attachedAllToMessage;

    if(!message)
    {
        NSLog(@"Cannot save downloaded attachment: not attached to a message! %@", attachment);
        return;
    }

    NSCharacterSet *charactersToRemove =
    [[ NSCharacterSet alphanumericCharacterSet ] invertedSet ];

    NSString* shortenedMessageID =
    [[message.messageid componentsSeparatedByCharactersInSet:charactersToRemove]
     componentsJoinedByString:@""];

    NSString* folder = [NSString stringWithFormat:@"%@-%ld-%ld", shortenedMessageID, (long)[[NSDate date] timeIntervalSince1970], (long)rand()];

    NSString* containerDirectory = NSHomeDirectory();

    NSString* attachmentsDirectory = [NSString stringWithFormat:@"%@/Attachments/%@/", containerDirectory, folder];

    NSError* error = nil;


    [[NSFileManager defaultManager] createDirectoryAtPath:attachmentsDirectory withIntermediateDirectories:YES attributes:nil error:&error];

    if(error)
    {
        NSLog(@"Error creating directory at path %@: %@", attachmentsDirectory, error);
    }

    error = nil;

    NSString* filePath = [attachmentsDirectory stringByAppendingPathComponent:attachment.fileName];

    NSURL*  theFile = [NSURL fileURLWithPath:filePath];

    if([data writeToURL:theFile options:0 error:&error])
    {
        if(!error)
        {
            [attachment setPrivateURLString:filePath];
#if TARGET_OS_IPHONE
            NSData* bookmarkData = [theFile bookmarkDataWithOptions:0 includingResourceValuesForKeys:nil relativeToURL:nil error:&error];
#else
            NSData* bookmarkData = [theFile bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:&error];
#endif
        if(error)
        {
            NSLog(@"Error setting bookmark: %@, %@",theFile,error);
            return;
        }
            [attachment setPrivateBookmark:bookmarkData];
        }
    }
}


+ (void)saveData:(NSData*)data toPrivateEncryptedURLForAttachment:(FileAttachment*)attachment
{
    EmailMessage* message = attachment.attachedAllToMessage;

    if(!message)
    {
        NSLog(@"Cannot save downloaded attachment: not attached to a message! %@", attachment);
        return;
    }

    NSString* bundleDirectory = [NSString stringWithFormat:@"%@/Attachments/%@/%ld", [BUNDLE bundlePath], message.messageid, (long)[[NSDate date] timeIntervalSince1970]];

    NSError* error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:bundleDirectory withIntermediateDirectories:YES attributes:nil error:&error];

    if(error)
    {
        NSLog(@"Error creating directory at path %@: %@", bundleDirectory, error);
    }

    error = nil;

    NSString* filePath = [bundleDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld-%ld-%ld-%ld.dat", (long)rand(), (long)rand(), (long)rand(), (long)rand()]];

    NSURL*  theFile = [NSURL fileURLWithPath:filePath];

    if([data writeToURL:theFile options:0 error:&error])
    {
        if(!error)
        {
            [attachment setPrivateURLString:filePath];

#if TARGET_OS_IPHONE
            NSData* bookmarkData = [theFile bookmarkDataWithOptions:0 includingResourceValuesForKeys:nil relativeToURL:nil error:&error];
#else
            NSData* bookmarkData = [theFile bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:&error];
#endif
            if(error)
            {
                NSLog(@"Error setting bookmark: %@, %@",theFile,error);
                return;
            }
            [attachment setPrivateBookmark:bookmarkData];
        }
    }
}



+ (void)openAttachment:(FileAttachment*)attachment
{
#if TARGET_OS_IPHONE
#else
    if([attachment isDownloaded])
    {
        NSURL* url = [attachment privateURL];

        if(url)
        {
            [[NSWorkspace sharedWorkspace] openFile:url.path];
        }
        else
        {
            url = [attachment publicURL];
            [url startAccessingSecurityScopedResource];
            [[NSWorkspace sharedWorkspace] openFile:url.path];
            [url stopAccessingSecurityScopedResource];
        }
    }
    else
    {
        [attachment urgentlyDownloadWithCallback:^(NSData *data) {

                        NSURL* url = [attachment privateURL];

                        if(url)
                        {
                            [[NSWorkspace sharedWorkspace] openFile:url.path];
                        }
                        else
                        {
                            url = [attachment publicURL];

                            [url startAccessingSecurityScopedResource];
                            [[NSWorkspace sharedWorkspace] openFile:url.path];
                            [url stopAccessingSecurityScopedResource];
                        }
                   }];
    }
#endif
}

+ (FileAttachment*)makeFreshCopyOfAttachment:(FileAttachment*)fileAttachment inContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    if(!fileAttachment)
        return nil;

    NSEntityDescription* description = [NSEntityDescription entityForName:@"FileAttachment" inManagedObjectContext:localContext];

    FileAttachment* newAttachment = [[FileAttachment alloc] initWithEntity:description insertIntoManagedObjectContext:localContext];

    [newAttachment setContentid:fileAttachment.contentid];
    [newAttachment setDecryptionStatus:fileAttachment.decryptionStatus];
    [newAttachment setDownloadProgress:fileAttachment.downloadProgress];
    [newAttachment setEncoding:fileAttachment.encoding];
    [newAttachment setFileName:fileAttachment.fileName];
    [newAttachment setHashedValue:fileAttachment.hashedValue];
    [newAttachment setName:fileAttachment.name];
    [newAttachment setPartID:fileAttachment.partID];
    [newAttachment setPrivateBookmark:fileAttachment.privateBookmark];
    [newAttachment setPrivateEncryptedDataBookmark:fileAttachment.privateEncryptedDataBookmark];
    [newAttachment setPrivateEncryptedDataURLString:fileAttachment.privateEncryptedDataURLString];
    [newAttachment setPrivateURLString:fileAttachment.privateURLString];
    [newAttachment setPublicBookmark:fileAttachment.publicBookmark];
    [newAttachment setPublicURLString:fileAttachment.publicURLString];
    [newAttachment setRemoteURLString:fileAttachment.remoteURLString];
    [newAttachment setSize:fileAttachment.size];
    [newAttachment setUniqueID:fileAttachment.uniqueID];

    return newAttachment;
}


+ (NSArray*)attachmentItemsForMessage:(EmailMessage*)message
{
    NSArray* sortedAttachments = [message.allAttachments sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"fileName" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"uniqueID" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"contentid" ascending:YES]]];

    NSMutableArray* array = [NSMutableArray new];

    for(FileAttachment* attachment in sortedAttachments)
    {
        //AttachmentItem* newItem = [[AttachmentItem alloc] initWithAttachment:attachment];

        [array addObject:/*newItem*/attachment];
    }

    return array;
}



@end
