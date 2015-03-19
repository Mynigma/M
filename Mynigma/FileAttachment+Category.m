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





#import "FileAttachment+Category.h"

#import "AppDelegate.h"
#import "FileAttachment+Category.h"
#import "EmailMessage+Category.h"
#import "MynigmaMessage+Category.h"
#import "IMAPAccount.h"
#import "EmailMessageInstance+Category.h"
#import "IMAPFolderSetting+Category.h"
#import "EncryptionHelper.h"
#import "ZipArchive.h"
#import "DisconnectOperation.h"
#import "FetchAttachmentOperation.h"
#import "AccountCheckManager.h"
#import "SelectionAndFilterHelper.h"
#import "NSString+EmailAddresses.h"
#import "MynigmaFeedback.h"




#if TARGET_OS_IPHONE

#else

#import <AppKit/AppKit.h>

#endif



static NSMutableSet* beingDecrypted;
static NSMutableSet* beingDownloaded;

@implementation FileAttachment (Category)


- (BOOL)havePublicData
{
    return [self publicBookmark]!=nil || [self publicURLString]!=nil;
}


- (BOOL)havePrivateData
{
    return [self privateBookmark]!=nil || [self privateURLString]!=nil;
}


- (BOOL)isAnImage
{
    NSString* fileName = self.fileName;

    NSString* extension = [[fileName pathExtension] lowercaseString];

    if(extension)
        if([@[@"png", @"jpeg", @"jpg", @"gif"] containsObject:extension])
        {
            return YES;
        }

    return NO;
}


- (BOOL)isInline
{
    if (self.attachedToMessage)
        return NO;
    else
        return YES;
}



- (BOOL)isDownloaded
{
    if([self isMissing])
        return NO;

    EmailMessage* message = [self attachedAllToMessage];
    if(message)
    {
        if([message isKindOfClass:[MynigmaMessage class]])
            return [self privateEncryptedDataBookmark] || [self privateEncryptedDataURLString] || [self havePublicData] || [self havePrivateData];
        else
            return [self havePrivateData] || [self havePublicData];
    }
    else
    {
        //NSLog(@"Download queried for attachment without a message: %@", self);
        return [self havePrivateData] || [self havePublicData];
    }
}

- (BOOL)isDecrypted
{
    if([self isMissing])
        return NO;

    EmailMessage* message = [self attachedAllToMessage];
    if([message isSafe])
    {
        return [self havePrivateData] || [self havePublicData];
    }
    else
    {
        //NSLog(@"Decryption queried for attachment %@ with invalid message: %@", object, message);
        return NO;
    }
}

- (BOOL)isDecrypting
{
    if([self isMissing])
        return NO;

    BOOL result = [beingDecrypted containsObject:self.objectID];

    //sanity check
    if(result && [self isDecrypted])
    {
        NSLog(@"Decrypted attachment is reporting that decryption is in progress!!");
        return NO;
    }

    if(result && ![self isDownloaded])
        NSLog(@"Attachment being decrypted is not downloaded!!");

    return result;
}

- (BOOL)isDownloading
{
    if([self isMissing])
        return NO;

    BOOL result = [beingDownloaded containsObject:self.objectID];

    //sanity check
    if(result && [self isDownloaded])
        NSLog(@"Downloading attachment that is already downloaded!!");

    if(result && [self isDecrypted])
        NSLog(@"Downloading attachment that is already decrypted!!");

    //if(result && [attachment downloadProgress].floatValue>=1)
    //    NSLog(@"Downloading attachment, but progress is 1!!");

    return result;
}

- (void)setIsDownloading:(BOOL)isDownloading
{
    [self willChangeValueForKey:@"overlayString"];
    if(!beingDownloaded)
        beingDownloaded = [NSMutableSet new];

    if(isDownloading)
        [beingDownloaded addObject:self.objectID];
    else
        if([beingDownloaded containsObject:self.objectID])
            [beingDownloaded removeObject:self.objectID];
    [self didChangeValueForKey:@"overlayString"];
}

- (void)setIsDecrypting:(BOOL)isDecrypting
{
    [self willChangeValueForKey:@"overlayString"];
    if(!beingDecrypted)
        beingDecrypted = [NSMutableSet new];

    if(isDecrypting)
        [beingDecrypted addObject:self.objectID];
    else
        if([beingDecrypted containsObject:self.objectID])
            [beingDecrypted removeObject:self.objectID];

    [self didChangeValueForKey:@"overlayString"];
}

- (BOOL)canBeDecrypted
{
    if([self isMissing])
        return NO;

    EmailMessage* message = [self attachedAllToMessage];

    if(![message isKindOfClass:[MynigmaMessage class]])
        return NO;

    BOOL result = [self isDownloaded] && ![self isDecrypted] && ![self isDecrypting];

    //sanity check
    if(result && !(self.privateEncryptedDataBookmark || self.privateEncryptedDataURLString))
        NSLog(@"Downloaded Mynigma attachment has no data to be decrypted!!");

    return result;
}

- (BOOL)canBeDownloaded
{
    if([self isMissing])
        return NO;

    BOOL result = ![self isDownloaded];

    if(result && [self havePrivateData])
        NSLog(@"Attachment not yet downloaded, but has data set!!");

    return result;
}

- (BOOL)canBeSavedByUser
{
    if([self isMissing])
        return NO;

    BOOL result = [self havePrivateData] || [self havePublicData];

    //sanity check
    if(result && [self isDownloading])
    {
        NSLog(@"Attachment can be saved, but is still being downloaded!!");
        return YES;
    }

    if(result && [self isDecrypting])
    {
        NSLog(@"Attachment can be saved, but is being decrypted!!");
        return YES;
    }

    return result;
}

- (BOOL)isMissing
{
    return [self.downloadProgress isEqual:@(-1)];
}




- (NSURL*)publicURL
{
    if(self.publicBookmark)
    {
        NSError* error = nil;

#if TARGET_OS_IPHONE

        NSURL* returnURL = [NSURL URLByResolvingBookmarkData:self.publicBookmark options:0 relativeToURL:nil bookmarkDataIsStale:nil error:&error];

#else

        NSURL* returnURL = [NSURL URLByResolvingBookmarkData:self.publicBookmark options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:nil error:&error];

#endif

        if(error)
        {
            NSLog(@"Error resolving public bookmark for attachment %@: %@", self, error);
        }
        else
            return returnURL;
    }

    if(self.publicURLString)
        return [NSURL URLWithString:self.publicURLString];

    return nil;
}


- (NSURL*)privateEncryptedURL
{
    if(self.privateEncryptedDataBookmark)
    {
        NSError* error = nil;

#if TARGET_OS_IPHONE

        NSURL *returnURL = [NSURL URLByResolvingBookmarkData:self.privateEncryptedDataBookmark options:0 relativeToURL:nil bookmarkDataIsStale:nil error:&error];

#else

        NSURL *returnURL = [NSURL URLByResolvingBookmarkData:self.privateEncryptedDataBookmark options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:NO error:&error];

#endif

        if(error)
        {
            NSLog(@"Error resolving private bookmark for attachment %@: %@", self, error);
        }
        else
            return returnURL;
    }

    if(self.privateEncryptedDataURLString)
        return [NSURL fileURLWithPath:self.privateEncryptedDataURLString isDirectory:NO];

    return nil;
}


- (NSURL*)privateURL
{
    /* bookmark updated itself to publicURL

     if(self.privateBookmark)
     {
     NSError* error = nil;

     #if TARGET_OS_IPHONE

     NSURL *returnURL = [NSURL URLByResolvingBookmarkData:self.privateBookmark options:0 relativeToURL:nil bookmarkDataIsStale:NO error:&error];


     #else

     NSURL *returnURL = [NSURL URLByResolvingBookmarkData:self.privateBookmark options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:NO error:&error];


     #endif
     if(error)
     {
     NSLog(@"Error resolving private bookmark for attachment %@: %@", self, error);
     }
     else
     return returnURL;
     }
     */

    if(self.privateURLString)

        return [NSURL fileURLWithPath:self.privateURLString isDirectory:NO];

    return nil;
}




- (void)saveDataToPrivateURL:(NSData*)data
{
    EmailMessage* message = self.attachedAllToMessage;

    NSString* messageID = message.messageid;

    if(!messageID)
    {
        NSLog(@"Attachment being saved not attached to a message! %@", self);

        if(!self.managedObjectContext)
        {
            //the attachment has been deleted!!
            return;
        }

        messageID = [@"unattachedAttachment@mynigmaAttachment.org" generateMessageID];
    }

    NSCharacterSet *charactersToRemove = [[NSCharacterSet alphanumericCharacterSet] invertedSet];

    NSString* shortenedMessageID = [[messageID componentsSeparatedByCharactersInSet:charactersToRemove] componentsJoinedByString:@""];

    NSString* folder = [NSString stringWithFormat:@"%@-%ld-%ld", shortenedMessageID, (long)[[NSDate date] timeIntervalSince1970], (long)rand()];

#if ULTIMATE

    NSString* containerDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];

#else

    NSString* containerDirectory = NSHomeDirectory();

#endif

#if TARGET_OS_IPHONE

    NSURL* documentsDirectoryURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];

    containerDirectory = documentsDirectoryURL.path;

#endif

    NSString* attachmentsDirectory = [NSString stringWithFormat:@"%@/Attachments/%@/", containerDirectory, folder];

    NSError* error = nil;


    [[NSFileManager defaultManager] createDirectoryAtPath:attachmentsDirectory withIntermediateDirectories:YES attributes:nil error:&error];

    if(error)
    {
        NSLog(@"Error creating directory at path %@: %@", attachmentsDirectory, error);
    }

    error = nil;

    NSString* fileName = self.fileName;

    if(!fileName)
    {
        NSLog(@"Trying to save attachment without a valid file name: %@", self);

        fileName = @"noname.file";
    }

    NSString* filePath = [attachmentsDirectory stringByAppendingPathComponent:fileName];


    NSURL*  theFile = [NSURL fileURLWithPath:filePath];

    if([data writeToURL:theFile options:0 error:&error])
    {
        if(!error)
        {
            [self willChangeValueForKey:@"thumbnail"];

            [self setDownloadProgress:@(1.1)];

            [self setPrivateURLString:filePath];

            [self didChangeValueForKey:@"thumbnail"];

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
            [self setPrivateBookmark:bookmarkData];
        }
        else
            NSLog(@"Error writing private attachment data to URL %@ - error: %@ (%ld bytes)", theFile, error, (unsigned long)data.length);
    }
    else
        NSLog(@"Failed writing private attachment data to URL %@ - error: %@ (%ld bytes)", theFile, error, (unsigned long)data.length);
}


- (void)saveDataToPrivateEncryptedURL:(NSData*)data
{
    EmailMessage* message = self.attachedAllToMessage;

    NSString* messageID = message.messageid;

    if(!messageID)
    {
        NSLog(@"Attachment being saved not attached to a message! %@", self);
        messageID = [@"unattachedAttachment@mynigmaAttachment.org" generateMessageID];
    }

    NSCharacterSet *charactersToRemove = [[NSCharacterSet alphanumericCharacterSet] invertedSet];

    NSString* shortenedMessageID = [[messageID componentsSeparatedByCharactersInSet:charactersToRemove] componentsJoinedByString:@""];

    NSString* folder = [NSString stringWithFormat:@"%@-%ld-%ld", shortenedMessageID, (long)[[NSDate date] timeIntervalSince1970], (long)rand()];

#if ULTIMATE

    NSString* containerDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];

#else

    NSString* containerDirectory = NSHomeDirectory();

#endif

#if TARGET_OS_IPHONE

    NSURL* documentsDirectoryURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];

    containerDirectory = documentsDirectoryURL.path;

#endif

    NSString* attachmentsDirectory = [NSString stringWithFormat:@"%@/Attachments/%@/", containerDirectory, folder];

    NSError* error = nil;


    [[NSFileManager defaultManager] createDirectoryAtPath:attachmentsDirectory withIntermediateDirectories:YES attributes:nil error:&error];

    if(error)
    {
        NSLog(@"Error creating directory at path %@: %@", attachmentsDirectory, error);
    }

    error = nil;

    NSString* filePath = [attachmentsDirectory stringByAppendingPathComponent:self.fileName];

    NSURL*  theFile = [NSURL fileURLWithPath:filePath];

    if([data writeToURL:theFile options:0 error:&error])
    {
        if(!error)
        {
            [self setDownloadProgress:@(1.1)];

            [self setPrivateEncryptedDataURLString:filePath];


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
            [self setPrivateEncryptedDataBookmark:bookmarkData];
        }
    }
}

/**CALL ON MAIN THREAD*/
- (void)saveAndDecryptData:(NSData*)data
{
    [ThreadHelper ensureMainThread];

    EmailMessage* message = self.attachedAllToMessage;

    if([message isSafe])
    {
        [self saveDataToPrivateEncryptedURL:data];

        [self setIsDecrypting:YES];

        [SelectionAndFilterHelper refreshMessage:message.objectID];

        NSManagedObjectID* thisObjectID = self.objectID;

        [EncryptionHelper asyncDecryptFileAttachment:thisObjectID  withCallback:^(NSData* data, MynigmaFeedback* feedback)
        {
            [MAIN_CONTEXT performBlock:^{

                if(data)
                {
                    [self willChangeValueForKey:@"sizeString"];
                    [self setDownloadProgress:@(1.1)];
                    [self didChangeValueForKey:@"sizeString"];
                    [self saveDataToPrivateURL:data];
                }

                [self setIsDecrypting:NO];

                [CoreDataHelper save];

                [SelectionAndFilterHelper refreshMessage:message.objectID];
                [SelectionAndFilterHelper refreshViewerShowingMessage:message];
            }];
        }];

    }
    else
    {
        [self saveDataToPrivateURL:data];
    }


    //don't refresh yet, set isDownloading to NO first...
    //[MODEL saveMainContext];
    //[APPDELEGATE refreshMessage:message.objectID];
    //[APPDELEGATE refreshAttachment:self];
}

- (NSData*)data
{
    if(![self isDownloaded])
        return nil;

    NSURL* theURL = [self privateURL];

    NSError* error = nil;

    if(theURL)
        return [NSData dataWithContentsOfURL:theURL options:NSDataReadingUncached error:&error];

    theURL = [self publicURL];

    if(!theURL)
        return nil;

#if TARGET_OS_IPHONE

    NSData* returnValue = [NSData dataWithContentsOfURL:theURL options:NSDataReadingUncached error:&error];

#else
    [theURL startAccessingSecurityScopedResource];
    NSData* returnValue = [NSData dataWithContentsOfURL:theURL options:NSDataReadingUncached error:&error];
    [theURL stopAccessingSecurityScopedResource];
#endif

    if(error)
        NSLog(@"Error opening public attachment URL: %@", error);

    return returnValue;
}

- (NSData*)encryptedData
{
    if(![self isDownloaded])
        return nil;

    NSURL* theURL = [self privateEncryptedURL];

#if TARGET_OS_IPHONE

    NSData* returnValue = [NSData dataWithContentsOfURL:theURL];

#else

    [theURL startAccessingSecurityScopedResource];

    NSData* returnValue = [NSData dataWithContentsOfURL:theURL];

    [theURL stopAccessingSecurityScopedResource];

#endif

    return returnValue;
}

- (FileAttachment*)copyInContext:(NSManagedObjectContext*)localContext
{
    [ThreadHelper ensureLocalThread:localContext];

    NSEntityDescription* entity = [NSEntityDescription entityForName:@"FileAttachment" inManagedObjectContext:localContext];

    FileAttachment* newAttachment = [[FileAttachment alloc] initWithEntity:entity insertIntoManagedObjectContext:localContext];

    [newAttachment setContentid:self.contentid];
    [newAttachment setContentType:self.contentType];
    [newAttachment setDecryptionStatus:self.decryptionStatus];
    [newAttachment setDownloadProgress:self.downloadProgress];
    [newAttachment setEncoding:self.encoding];
    [newAttachment setFileName:self.fileName];
    [newAttachment setHashedValue:self.hashedValue];
    [newAttachment setName:self.name];
    [newAttachment setPrivateBookmark:self.privateBookmark];
    [newAttachment setPrivateEncryptedDataBookmark:self.privateEncryptedDataBookmark];
    [newAttachment setPrivateEncryptedDataURLString:self.privateEncryptedDataURLString];
    [newAttachment setPrivateURLString:self.privateURLString];
    [newAttachment setPublicBookmark:self.publicBookmark];
    [newAttachment setPublicURLString:self.publicURLString];
    [newAttachment setRemoteURLString:self.remoteURLString];
    [newAttachment setSize:self.size];

    return newAttachment;
}

+ (FileAttachment*)makeNewAttachmentFromURL:(NSURL*)url
{
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"FileAttachment" inManagedObjectContext:MAIN_CONTEXT];
    FileAttachment* newAttachment = [[FileAttachment alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];
#if TARGET_OS_IPHONE

#else

    [url startAccessingSecurityScopedResource];

#endif

    NSError* error = nil;

#if ULTIMATE

    NSString* containerDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];

#else

    NSString* containerDirectory = NSHomeDirectory();

#endif

#if TARGET_OS_IPHONE

    NSURL* documentsDirectoryURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];

    containerDirectory = documentsDirectoryURL.path;

#endif

    NSString* fileName = [url.path lastPathComponent];

    NSDictionary* fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:&error];

    if(!error)
    {
        //first check if it's a directory

        if([[fileAttributes objectForKey:NSFileType] isEqual:NSFileTypeDirectory])
        {
            //it's a directory!!
            //zip it!!!!

            NSString* subFolder = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];

            //this is where the zipped folder will be stored
            NSString* attachmentsDirectory = [NSString stringWithFormat:@"%@/Attachments/%@/", containerDirectory, subFolder];

            NSError* error = nil;


            [[NSFileManager defaultManager] createDirectoryAtPath:attachmentsDirectory withIntermediateDirectories:YES attributes:nil error:&error];

            if(error)
            {
                NSLog(@"Error creating directory at path %@: %@", attachmentsDirectory, error);
            }

            if(fileName.length == 0)
                fileName = @"folder";

            NSString* zipFilePath = [attachmentsDirectory stringByAppendingPathComponent:fileName];

            zipFilePath = [zipFilePath stringByAppendingString:@".zip"];

            NSArray* subpaths = [[NSFileManager defaultManager] subpathsAtPath:url.path];

            ZipArchive *archiver = [[ZipArchive alloc] init];
            [archiver CreateZipFile2:zipFilePath];
            for(NSString *path in subpaths)
            {
                BOOL isDir = NO;

                NSString *longPath = [url.path stringByAppendingPathComponent:path];

                if([[NSFileManager defaultManager] fileExistsAtPath:longPath isDirectory:&isDir] && !isDir)
                {
                    [archiver addFileToZip:longPath newname:path];
                }
            }

            BOOL successCompressing = [archiver CloseZipFile2];
            if(successCompressing)
            {
                [newAttachment setFileName:[zipFilePath lastPathComponent]];
                [newAttachment setName:[zipFilePath lastPathComponent]];
                [newAttachment setDownloadProgress:@1.1];

                error = nil;

                NSDictionary* fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:zipFilePath error:&error];

                if(!error)
                {
                    NSNumber* fileSize = [fileAttributes valueForKey:NSFileSize];
                    [newAttachment setSize:fileSize];
                }

                [newAttachment setPrivateURLString:zipFilePath];

#if TARGET_OS_IPHONE

#else

                [url stopAccessingSecurityScopedResource];

                NSURL* zipURL = [[NSURL alloc] initFileURLWithPath:zipFilePath];

                NSData* privateURLBookmark = [zipURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:&error];

                [newAttachment setPrivateBookmark:privateURLBookmark];

#endif

                return newAttachment;
            }
            else
            {
                NSLog(@"Failed to zip folder attachment");
                return nil;
            }

        }
        else
        {
            //it's a file
            //proceed normally

            [newAttachment setPublicURLString:url.path];

            [newAttachment setFileName:[url.path lastPathComponent]];

            [newAttachment setName:newAttachment.fileName];

            [newAttachment setDownloadProgress:@1.1];

            NSNumber* fileSize = [fileAttributes valueForKey:NSFileSize];

            [newAttachment setSize:fileSize];

#if TARGET_OS_IPHONE

#else

            [url startAccessingSecurityScopedResource];

            NSData* publicURLBookmark = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:&error];

            if(error)
            {
                NSLog(@"Error creating bookmark for dragged & dropped URL: %@", error);

                NSAlert* alert = [NSAlert alertWithMessageText:@"Error creating bookmark" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"No bookmark could be created for the selected file"];

                [alert runModal];
            }

            NSError* error = nil;

            NSData* fileData = [NSData dataWithContentsOfURL:url options:0 error:&error];

            if(fileData)
                [newAttachment saveDataToPrivateURL:fileData];
            else
                NSLog(@"Failed to copy data from public to private URL: %@", error);

            [url stopAccessingSecurityScopedResource];

            [newAttachment setPublicBookmark:publicURLBookmark];

#endif

            return newAttachment;
        }
    }
    else
        NSLog(@"Error obtaining file attributes: %@", error);

    return nil;
}

- (NSString*)sizeString
{
    NSString* sizeString = nil;

    NSUInteger size = self.size.unsignedIntegerValue;
    if(size>1024*1024)
        sizeString = [NSString stringWithFormat:@"%.1f MB",ceil((1.*size)/1024/1024)];
    else
        sizeString = [NSString stringWithFormat:@"%.0f KB",ceil((1.*size)/1024)];


    if(self.isDownloading)
    {
        NSString* downloadedSizeString = nil;

        NSUInteger downloadedSize = size*self.downloadProgress.floatValue;
        if(size>1024*1024)
            downloadedSizeString = [NSString stringWithFormat:@"%.1f",ceil(10*(1.*downloadedSize)/1024/1024)/10.0];
        else
            downloadedSizeString = [NSString stringWithFormat:@"%.0f",ceil((1.*downloadedSize)/1024)];

        return [NSString stringWithFormat:NSLocalizedString(@"%@ of %@", @"Attachment size string"), downloadedSizeString, sizeString];
    }

    return sizeString;
}



- (IMAGE*)thumbnail
{
#if TARGET_OS_IPHONE

    return nil;

#else

    CGFloat size = 64;

    if([self isAnImage] && [self data])
    {
        IMAGE* image = [[IMAGE alloc] initWithData:self.data];

        if(image)
        {
            CGFloat scaleFactor = image.size.height>0?(image.size.width/image.size.height):1;

            CGFloat height = size;
            CGFloat width = size;

            if(scaleFactor<1)
            {
                //height>width
                width *= scaleFactor;
            }
            else if(scaleFactor > 0)
            {
                //width>height
                height /= scaleFactor;
            }

            //TO DO: cache this
            //perhaps using associated objects
            IMAGE* thumbnail = [[IMAGE alloc] initWithSize:CGSizeMake(width, height)];
            [thumbnail lockFocus];
            [[NSGraphicsContext currentContext]
             setImageInterpolation:NSImageInterpolationLow];

            [image drawInRect:CGRectMake(0, 0, width, height) fromRect:NSZeroRect operation:NSCompositeCopy fraction:[self isDownloaded]?1.:.3];

            [thumbnail unlockFocus];

            return thumbnail;
        }
    }

    //if([@[@"pdf", @"txt"] containsObject:[self.fileName pathExtension].lowercaseString])
    {
        NSURL* URL = self.privateURL;

        if(!URL)
            URL = self.publicURL;

        if(URL)
        {
            NSImage* image = [[NSImage alloc] initWithContentsOfURL:URL];
            if(image)
            {
                CGFloat scaleFactor = image.size.height>0?(image.size.width/image.size.height):1;

                CGFloat height = size;
                CGFloat width = size;

                if(scaleFactor<1)
                {
                    //height>width
                    width *= scaleFactor;
                }
                else if(scaleFactor > 0)
                {
                    //width>height
                    height /= scaleFactor;
                }

                NSImage * thumbnail = [[NSImage alloc] initWithSize:CGSizeMake(width, height)];
                [thumbnail lockFocus];
                [NSGraphicsContext saveGraphicsState];
                [[NSGraphicsContext currentContext]
                 setImageInterpolation:NSImageInterpolationHigh];

                [image drawInRect:CGRectMake(0, 0, width, height) fromRect:NSZeroRect operation:NSCompositeCopy fraction:[self isDownloaded]?1.:.3];

                [NSGraphicsContext restoreGraphicsState];
                [thumbnail unlockFocus];

                return thumbnail;
            }
        }
        //        UIGraphicsBeginImageContext(thumbnailSize);
        //        CGPDFDocumentRef pdfRef = CGPDFDocumentCreateWithProvider( (CGDataProviderRef)instanceOfNSDataWithPDFInside );
        //        CGPDFPageRef pageRef = CGPDFDocumentGetPage(pdfRef, 1); // get the first page
        //
        //        CGContextRef contextRef = UIGraphicsGetCurrentContext();
        //
        //        // ignore issues of transforming here; depends on exactly what you want and
        //        // involves a whole bunch of normal CoreGraphics stuff that is nothing to do
        //        // with PDFs
        //        CGContextDrawPDFPage(contextRef, pageRef);
        //
        //        UIImage *imageToReturn = UIGraphicsGetImageFromCurrentImageContext();
        //
        //        // clean up
        //        UIGraphicsEndImageContext();
        //        CGPDFDocumentRelease(pdfRef);
        //
        //        return imageToReturn;
    }

    NSString* extension = [[self.fileName pathExtension] lowercaseString];

    NSImage* image = [[NSWorkspace sharedWorkspace] iconForFileType:extension];

    CGFloat scaleFactor = image.size.height>0?(image.size.width/image.size.height):1;

    CGFloat height = size;
    CGFloat width = size;

    if(scaleFactor<1)
    {
        //height>width
        width *= scaleFactor;
    }
    else if(scaleFactor > 0)
    {
        //width>height
        height /= scaleFactor;
    }

    NSImage * thumbnail = [[NSImage alloc] initWithSize:CGSizeMake(width, height)];
    [thumbnail lockFocus];
    [[NSGraphicsContext currentContext]
     setImageInterpolation:NSImageInterpolationLow];

    [image drawInRect:CGRectMake(0, 0, width, height) fromRect:NSZeroRect operation:NSCompositeCopy fraction:[self isDownloaded]?1.:.3];

    [thumbnail unlockFocus];

    return thumbnail;

#endif

}

- (NSURL*)URL
{
    NSURL* URL = self.privateURL;

    if(!URL)
        URL = self.publicURL;

    return URL;
}

- (NSString*)overlayString
{
    if(self.downloadProgress.floatValue <= -.9)
        return NSLocalizedString(@"Attachment missing", @"Attachment icon overlay");

    if(self.downloadProgress.floatValue <= 0.01)
    {
        if([self isDownloading])
            return NSLocalizedString(@"Queued for download", @"Attachment icon overlay");
        else
            return NSLocalizedString(@"Click to download", @"Attachment icon overlay");
    }

    if(self.downloadProgress.floatValue < 1.)
        return NSLocalizedString(@"Downloading", @"User Interface State");

    return @"";
}

+ (FileAttachment*)makeAttachmentWithInlineImageData:(NSData*)imageData fileName:(NSString*)fileName contentType:(NSString*)contentType contentID:(NSString*)contentID inContext:(NSManagedObjectContext*)localContext
{
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"FileAttachment" inManagedObjectContext:localContext];

    FileAttachment* newAttachment = [[FileAttachment alloc] initWithEntity:entity insertIntoManagedObjectContext:localContext];

    [newAttachment setContentid:contentID];
    [newAttachment setContentType:contentType];
    [newAttachment setDownloadProgress:@1.1];
    [newAttachment setEncoding:@(MCOEncodingBase64)];
    [newAttachment setFileName:fileName];
    [newAttachment setName:fileName];

    [newAttachment saveDataToPrivateURL:imageData];
    [newAttachment setSize:@(imageData.length)];

    return newAttachment;
}



#pragma mark - Decryption

- (void)decryptWithCallback:(void(^)(NSData* data))callback
{
    EmailMessage* message = self.attachedAllToMessage;
    
    if(!message)
    {
        NSLog(@"Cannot decrypt attachment without message: %@", self);
        return;
    }

    //if the message is downloaded it doesn't need to be fetched again, but if it's a MynigmaMessage, then it should be decrypted if necessary...
    if(![message isSafe] || [self isDecrypted])
    {
        if(callback)
            callback(self.data);
        return;
    }


    //don't decrypt if decryption is already in progress...
    if([self isDecrypting])
        return;


    [self setIsDecrypting:YES];

    [SelectionAndFilterHelper refreshMessage:message.objectID];

    [EncryptionHelper asyncDecryptFileAttachment:self.objectID  withCallback:^(NSData* data, MynigmaFeedback* feedback)
    {

        [ThreadHelper runAsyncOnMain:^{

            [self setDecryptionStatus:feedback.archivableString];
            [self setIsDecrypting:NO];
            [CoreDataHelper save];
            [SelectionAndFilterHelper refreshMessage:message.objectID];

            if(callback)
                callback(data);
        }];

    }];


}





#pragma mark - Downloading

/**CALL ON MAIN*/
- (void)urgentlyDownloadWithCallback:(void(^)(NSData* data))callback
{
    [self downloadUsingSession:nil disconnectOperation:nil urgent:YES withCallback:callback];
}

- (void)downloadUsingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation *)disconnectOperation withCallback:(void(^)(NSData* data))callback
{
    [self downloadUsingSession:session disconnectOperation:disconnectOperation urgent:NO withCallback:callback];
}


- (void)downloadUsingSession:(MCOIMAPSession*)session disconnectOperation:(DisconnectOperation *)disconnectOperation urgent:(BOOL)urgent withCallback:(void(^)(NSData* data))callback
{
    [ThreadHelper ensureMainThread];

    EmailMessage* message = self.attachedAllToMessage;

    if(!message)
    {
        NSLog(@"Cannot download attachment without message: %@", self);
        return;
    }

    if([self isDownloaded])
    {
        if([message isSafe] && ![self isDecrypted])
            [self decryptWithCallback:callback];
        return;
    }

    //don't download an attachment that's alrady being downloaded
    if([self isDownloading])
        return;

    //first find an instance of the message that can be used on the IMAP server

    EmailMessageInstance* messageInstance = [message downloadableInstance];

    if(!messageInstance)
    {
        NSLog(@"No suitable instance found that can be used to download attachment: %@", self);
        return;
    }

    IMAPAccount* thisAccount = messageInstance.account;

    if(urgent)
    {
        session = thisAccount.quickAccessSession;
        disconnectOperation = nil;
    }


    if(!session)
    {
        NSLog(@"No SESSION in FILEATTACHMENT download");
        return;
    }

    [self setIsDownloading:YES];
    [SelectionAndFilterHelper refreshAttachment:self];

    MCOIMAPBaseOperationProgressBlock progressBlock = ^(unsigned int current, unsigned int maximum){

        NSNumber* progress = maximum>0?@(current*1./maximum):@0;

        //check this to avoid error: "mutating object after it has been removed from its managed object context"
        if(self.managedObjectContext)
        {
            [self willChangeValueForKey:@"overlayString"];
            [self willChangeValueForKey:@"sizeString"];
            [self setDownloadProgress:progress];
            [self didChangeValueForKey:@"sizeString"];
            [self didChangeValueForKey:@"overlayString"];
            [SelectionAndFilterHelper refreshAttachment:self];
        }
    };

    if(!self.partID)
    {
        NSLog(@"Attachment is missing partID!!");
        return;
    }

    FetchAttachmentOperation* fetchAttachmentOperation = [FetchAttachmentOperation fetchMessageAttachmentByUIDWithFolder:messageInstance.folderSetting.path uid:messageInstance.uid.unsignedIntegerValue partID:self.partID encoding:(MCOEncoding)self.encoding.integerValue urgent:urgent session:session withProgressBlock:progressBlock withCallback:^(NSError *error, NSData *partData){
        if(!self.managedObjectContext)
        {
            //the attachment has been deleted in the meantime!!
            //this might happen if messages are deleted or merged
            return;
        }
        
        BOOL executedCallback = NO;

        if(error)
        {
            NSLog(@"Error downloading attachment! %@", error);

            [self setIsDownloading:NO];

            [SelectionAndFilterHelper refreshAttachment:self];
        }
        else
        {
            if(partData.length == 0 && self.size.integerValue > 0)
            {
                NSLog(@"No data returned from attachment download... %@", self);

                [self setIsDownloading:NO];

                [SelectionAndFilterHelper refreshAttachment:self];
            }
            else
            {
                [self saveAndDecryptData:partData];

                [self setIsDownloading:NO];

                [SelectionAndFilterHelper refreshViewerShowingMessage:self.attachedAllToMessage];

                [SelectionAndFilterHelper refreshAttachment:self];

                executedCallback = YES;
                [self decryptWithCallback:callback];
            }
        }

        if(callback && !executedCallback)
            callback(partData);
    }];

    if(urgent)
        [fetchAttachmentOperation setHighPriority];
    else
        [fetchAttachmentOperation setLowPriority];
    
    if(urgent)
        [fetchAttachmentOperation addToUserActionQueue];
    else
    {
        if(![fetchAttachmentOperation addToMailCoreQueueWithDisconnectOperation:disconnectOperation])
        {
            [self setIsDownloading:NO];

            [SelectionAndFilterHelper refreshAttachment:self];
        }
    }
}



@end
