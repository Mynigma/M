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





#import "TestHelper.h"
#import "AppDelegate.h"
#import "MynigmaDevice+Category.h"
#import "NSData+Base64.h"
#import "MynigmaPublicKey+Category.h"


//#if TARGET_OS_IPHONE
//
//#define HC_SHORTHAND
//#import <OCHamcrestIOS/OCHamcrestIOS.h>
//
//#define MOCKITO_SHORTHAND
//#import <OCMockitoIOS/OCMockitoIOS.h>
//
//#else
//
//#define HC_SHORTHAND
//#import <OCHamcrest/OCHamcrest.h>
//
//#define MOCKITO_SHORTHAND
//#import <OCMockito/OCMockito.h>
//
//#endif

@protocol MynigmaDeviceCoreDataObjectProtocol <NSObject>

@required

@property NSString* deviceId;

@end

@interface ManagedObjectProtocolCategory : MynigmaDevice<MynigmaDeviceCoreDataObjectProtocol>

@end

@implementation ManagedObjectProtocolCategory

@end


@implementation TestHelper

+ (NSArray*)privateKeySampleData:(NSNumber*)index
{
    NSData* encData = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:[NSString stringWithFormat:@"Sample_EncKey%@", index?index:@""] ofType:@"txt"]];
    NSData* verData = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:[NSString stringWithFormat:@"Sample_VerKey%@", index?index:@""] ofType:@"txt"]];
    NSData* decData = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:[NSString stringWithFormat:@"Sample_DecKey%@", index?index:@""] ofType:@"txt"]];
    NSData* sigData = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:[NSString stringWithFormat:@"Sample_SigKey%@", index?index:@""] ofType:@"txt"]];

    NSArray* privateKeyData = @[decData, sigData, encData, verData];

    return privateKeyData;
}


+ (NSArray*)publicKeySampleData:(NSNumber*)index
{
    NSData* encData = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:[NSString stringWithFormat:@"Sample_EncKey%@", index?index:@""] ofType:@"txt"]];
    NSData* verData = [NSData dataWithContentsOfFile:[BUNDLE pathForResource:[NSString stringWithFormat:@"Sample_VerKey%@", index?index:@""] ofType:@"txt"]];

    NSArray* publicKeyData = @[encData, verData];
    
    return publicKeyData;
}

+ (NSData*)sampleData:(NSNumber*)index
{
    NSString* base64DataString = [NSString stringWithContentsOfURL:[BUNDLE URLForResource:[NSString stringWithFormat:@"Sample_Data%@", index?index:@""] withExtension:@"txt"] encoding:NSUTF8StringEncoding error:nil];

    NSData* rawData = [NSData dataWithBase64String:base64DataString];

    return rawData;
}

+ (NSData*)AESSessionKey:(NSNumber*)index
{
    NSString* base64DataString = [NSString stringWithContentsOfURL:[BUNDLE URLForResource:[NSString stringWithFormat:@"AESSessionKey%@", index?index:@""] withExtension:@"txt"] encoding:NSUTF8StringEncoding error:nil];

    NSData* rawData = [NSData dataWithBase64String:base64DataString];

    return rawData;
}



#pragma mark - HELPERS

+ (NSData*)getDataFromDesktopFile:(NSString*)fileName
{
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"/Users/romanpriebe/Desktop/%@", fileName]];

    NSData* data = [NSData dataWithContentsOfURL:url];

    return data;
}

+ (BOOL)putData:(NSData*)data intoDesktopFile:(NSString*)fileName
{
    NSArray * paths = NSSearchPathForDirectoriesInDomains (NSDesktopDirectory, NSUserDomainMask, YES);
    NSString * desktopPath = paths.firstObject;
    NSString* directory = [NSString stringWithFormat:@"%@/Unit Tests/", desktopPath];

    [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];

    //#if TARGET_OS_IPHONE

    //NSURL* url = [NSURL URLWithString:[APPDELEGATE.applicationDocumentsDirectory stringByAppendingPathComponent:fileName]];

    //#else

    NSURL* url = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:fileName]];

    //#endif

    BOOL result = [[NSFileManager defaultManager] createFileAtPath:url.path contents:data attributes:nil];

    if(!result)
        NSLog(@"Error: %d - message: %s", errno, strerror(errno));

    return result;
}

+ (NSData*)readBase64DataFromFile:(NSString*)fileName extension:(NSString*)extension
{
    NSURL* fileURL = [BUNDLE URLForResource:fileName withExtension:extension];

    NSString* fileDataString = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:nil];

    NSData* base64Data = [NSData dataWithBase64String:fileDataString];
    
    return base64Data;
}


+ (void)makeSamplePublicKeyWithLabel:(NSString*)keyLabel inContext:(NSManagedObjectContext*)localContext
{
    NSArray* publicKeySampleData = [self publicKeySampleData:@1];

    [MynigmaPublicKey syncMakeNewPublicKeyWithEncKeyData:publicKeySampleData.firstObject andVerKeyData:publicKeySampleData.lastObject forEmail:nil keyLabel:keyLabel];
}


+ (void)makeSampleDevicePublicKeyWithLabel:(NSString*)keyLabel forDeviceUUID:(NSString*)deviceUUID
{
    NSArray* publicKeySampleData = [self publicKeySampleData:@1];

    [MynigmaPublicKey syncMakeNewPublicKeyWithEncKeyData:publicKeySampleData.firstObject andVerKeyData:publicKeySampleData.lastObject forDeviceWithUUID:deviceUUID keyLabel:keyLabel];
}

@end
