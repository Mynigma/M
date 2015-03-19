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





#import "MynigmaDevice+Category.h"
#import "AppDelegate.h"

#import "KeychainHelper.h"
#import "MynigmaPrivateKey+Category.h"
#import "UserSettings+Category.h"

#import <sys/utsname.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import <stdlib.h>
#import <stdio.h>
#import <sys/types.h>
#import <sys/sysctl.h>

@interface MynigmaPrivateKey()

+ (void)asyncCreateNewMynigmaPrivateKeyForDeviceWithUUID:(NSString*)deviceUUID withCallback:(void(^)(void))callback;

@end


@implementation MynigmaDevice(Category)


+ (MynigmaDevice*)currentDevice
{
//    [ThreadHelper ensureMainThread];

    return [MynigmaDevice currentDeviceInContext:MAIN_CONTEXT];
}

+ (MynigmaDevice*)currentDeviceInContext:(NSManagedObjectContext*)localContext
{
//    [ThreadHelper ensureLocalThread:localContext];

    if([UserSettings currentUserSettingsInContext:localContext].currentDevice)
        return [UserSettings currentUserSettingsInContext:localContext].currentDevice;
    
    NSString* UUID = [KeychainHelper fetchUUIDFromKeychain];
    
    MynigmaDevice* newDevice = [MynigmaDevice deviceWithUUID:UUID addIfNotFound:YES inContext:localContext];

    [newDevice setDateAdded:[NSDate date]];

    [newDevice setDeviceId:UUID];

#if TARGET_OS_IPHONE

    [newDevice setDisplayName:[[UIDevice currentDevice] name]];

    [newDevice setType:[[UIDevice currentDevice] model]];

    [newDevice setOperatingSystemIdentifier:[NSString stringWithFormat:@"%@ %@", [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion]]];

#else

    CFStringRef computerNameRef = SCDynamicStoreCopyComputerName (NULL, NULL);
    NSString * computerName = [NSString stringWithString: (__bridge NSString *)(computerNameRef)];

    [newDevice setDisplayName:computerName];

    NSString* deviceType = nil;

    size_t len = 0;
    sysctlbyname("hw.model", NULL, &len, NULL, 0);
    if (len)
    {
        char *model = malloc(len*sizeof(char));
        sysctlbyname("hw.model", model, &len, NULL, 0);
        deviceType = [NSString stringWithCString:model encoding:NSUTF8StringEncoding];
        free(model);
    }

    [newDevice setType:deviceType];

    [newDevice setOperatingSystemIdentifier:[[NSProcessInfo processInfo] operatingSystemVersionString]];


#endif

    [newDevice setMynigmaVersion:MYNIGMA_VERSION];

//    struct utsname systemInfo;
//
//    uname(&systemInfo);
//
//    NSString *machineType = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
//
//    [newDevice setType:machineType];
//
//    [newDevice setUser:[UserSettings currentUserSettingsInContext:localContext]];

    [[UserSettings currentUserSettingsInContext:localContext] setCurrentDevice:newDevice];

    if(!newDevice.syncKey)
    {
        [MynigmaPrivateKey asyncCreateNewMynigmaPrivateKeyForDeviceWithUUID:UUID withCallback:nil];
    }

    return newDevice;
}

+ (MynigmaDevice*)deviceWithUUID:(NSString*)UUID
{
//    [ThreadHelper ensureMainThread];

    return [self deviceWithUUID:UUID addIfNotFound:NO inContext:MAIN_CONTEXT];
}

+ (MynigmaDevice*)deviceWithUUID:(NSString*)UUID addIfNotFound:(BOOL)addIfNotFound
{
//    [ThreadHelper ensureMainThread];

    return [self deviceWithUUID:UUID addIfNotFound:addIfNotFound inContext:MAIN_CONTEXT];
}

+ (MynigmaDevice*)deviceWithUUID:(NSString*)UUID inContext:(NSManagedObjectContext*)localContext
{
//    [ThreadHelper ensureLocalThread:localContext];

    return [self deviceWithUUID:UUID addIfNotFound:NO inContext:localContext];
}

+ (MynigmaDevice*)deviceWithUUID:(NSString*)UUID addIfNotFound:(BOOL)addIfNotFound inContext:(NSManagedObjectContext*)localContext
{
    //[ThreadHelper ensureLocalThread:localContext];

    if(!UUID)
        return nil;

    NSPredicate* UUIDPickPredicate = [NSPredicate predicateWithFormat:@"deviceId == %@", UUID];

    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MynigmaDevice"];

    [fetchRequest setPredicate:UUIDPickPredicate];

    NSError* error = nil;

    NSArray* results = [localContext executeFetchRequest:fetchRequest error:&error];

    if(results.count>1)
        NSLog(@"More than one device with the same ID!!");

    if(results.count>0)
        return results[0];

    //no device with this UUID could be found
    //add a new one? if not return nil
    if(!addIfNotFound)
        return nil;

    NSEntityDescription* entity = [NSEntityDescription entityForName:@"MynigmaDevice" inManagedObjectContext:localContext];

    MynigmaDevice* newDevice = [[MynigmaDevice alloc] initWithEntity:entity insertIntoManagedObjectContext:localContext];

    [newDevice setDateAdded:[NSDate date]];

    [newDevice setDeviceId:UUID];

    [newDevice setIsTrusted:@NO];
    
    [localContext save:nil];
    
    [CoreDataHelper saveAndWait];

    return newDevice;
}

+ (NSArray*)listAllKnownDevices
{
    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MynigmaDevice"];
    NSError* error = nil;
    NSArray* results = [MAIN_CONTEXT executeFetchRequest:fetchRequest error:&error];
    if(!error)
    {
        return results;
    }

    return nil;
}

+ (BOOL)haveKeyForDeviceWithUUID:(NSString*)deviceUUID
{
    __block BOOL haveKey = NO;
    
    if([NSThread isMainThread])
    {
        //on main running a sync local child context might cause deadlock, so just stay on main in this case...
        MynigmaDevice* device = [MynigmaDevice deviceWithUUID:deviceUUID inContext:MAIN_CONTEXT];
        
        haveKey = (device.syncKey != nil);
    }
    else
    {
        [ThreadHelper runSyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {
       
            MynigmaDevice* device = [MynigmaDevice deviceWithUUID:deviceUUID inContext:localContext];
        
            haveKey = (device.syncKey != nil);
        }];
    }
    
    return haveKey;
}

- (IMAGE*)image
{
    //    if ([sDeviceModel isEqual:@"i386"])      return @"Simulator";  //iPhone Simulator
    //    if ([sDeviceModel isEqual:@"iPhone1,1"]) return @"iPhone1G";   //iPhone 1G
    //    if ([sDeviceModel isEqual:@"iPhone1,2"]) return @"iPhone3G";   //iPhone 3G
    //    if ([sDeviceModel isEqual:@"iPhone2,1"]) return @"iPhone3GS";  //iPhone 3GS
    //    if ([sDeviceModel isEqual:@"iPhone3,1"]) return @"iPhone4 AT&T";  //iPhone 4 - AT&T
    //    if ([sDeviceModel isEqual:@"iPhone3,2"]) return @"iPhone4 Other";  //iPhone 4 - Other carrier
    //    if ([sDeviceModel isEqual:@"iPhone3,3"]) return @"iPhone4";    //iPhone 4 - Other carrier
    //    if ([sDeviceModel isEqual:@"iPhone4,1"]) return @"iPhone4S";   //iPhone 4S
    //    if ([sDeviceModel isEqual:@"iPhone5,1"]) return @"iPhone5";    //iPhone 5 (GSM)
    //    if ([sDeviceModel isEqual:@"iPod1,1"])   return @"iPod1stGen"; //iPod Touch 1G
    //    if ([sDeviceModel isEqual:@"iPod2,1"])   return @"iPod2ndGen"; //iPod Touch 2G
    //    if ([sDeviceModel isEqual:@"iPod3,1"])   return @"iPod3rdGen"; //iPod Touch 3G
    //    if ([sDeviceModel isEqual:@"iPod4,1"])   return @"iPod4thGen"; //iPod Touch 4G
    //    if ([sDeviceModel isEqual:@"iPad1,1"])   return @"iPadWiFi";   //iPad Wifi
    //    if ([sDeviceModel isEqual:@"iPad1,2"])   return @"iPad3G";     //iPad 3G
    //    if ([sDeviceModel isEqual:@"iPad2,1"])   return @"iPad2";      //iPad 2 (WiFi)
    //    if ([sDeviceModel isEqual:@"iPad2,2"])   return @"iPad2";      //iPad 2 (GSM)
    //    if ([sDeviceModel isEqual:@"iPad2,3"])   return @"iPad2";      //iPad 2 (CDMA)
    //
    //    NSString *aux = [[sDeviceModel componentsSeparatedByString:@","] objectAtIndex:0];
    //
    //    //If a newer version exist
    //    if ([aux rangeOfString:@"iPhone"].location!=NSNotFound) {
    //        int version = [[aux stringByReplacingOccurrencesOfString:@"iPhone" withString:@""] intValue];
    //        if (version == 3) return @"iPhone4"
    //            if (version >= 4) return @"iPhone4s";
    //
    //    }
    //    if ([aux rangeOfString:@"iPod"].location!=NSNotFound) {
    //        int version = [[aux stringByReplacingOccurrencesOfString:@"iPod" withString:@""] intValue];
    //        if (version >=4) return @"iPod4thGen";
    //    }
    //    if ([aux rangeOfString:@"iPad"].location!=NSNotFound) {
    //        int version = [[aux stringByReplacingOccurrencesOfString:@"iPad" withString:@""] intValue];
    //        if (version ==1) return @"iPad3G";
    //        if (version >=2) return @"iPad2";
    //    }

    if([self.type.lowercaseString hasPrefix:@"iphone"])
    {
        return [IMAGE imageNamed:@"iPhone4S.png"];
    }

    if([self.type.lowercaseString hasPrefix:@"ipad"])
    {
        return [IMAGE imageNamed:@"iPad.png"];
    }

    //TO DO: add iPod and other types of iPhone/iPad etc... (4S, 5, 5S, 5C, 6, 6+, ...)

    if([self.type isEqual:@"x86_64"])
    {
        //the simulator
        return [IMAGE imageNamed:@"iPhone4S.png"];
    }

    //TO DO: add more images for laptop and desktop computers...
    return [IMAGE imageNamed:@"MacBookPro_Small.png"];
}


- (NSString*)deviceTypeName
{
    NSString* platform = self.type;

    if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,3"])    return @"Verizon iPhone 4";
    if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone5,1"])    return @"iPhone 5 (GSM)";
    if ([platform isEqualToString:@"iPhone5,2"])    return @"iPhone 5 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone5,3"])    return @"iPhone 5C (GSM)";
    if ([platform isEqualToString:@"iPhone5,4"])    return @"iPhone 5C (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone6,1"])    return @"iPhone 5S (GSM)";
    if ([platform isEqualToString:@"iPhone6,2"])    return @"iPhone 5S (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone7,1"])    return @"iPhone 6 Plus";
    if ([platform isEqualToString:@"iPhone7,2"])    return @"iPhone 6";

    if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPod5,1"])      return @"iPod Touch 5G";

    if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([platform isEqualToString:@"iPad2,4"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,5"])      return @"iPad Mini (WiFi)";
    if ([platform isEqualToString:@"iPad2,6"])      return @"iPad Mini (GSM)";
    if ([platform isEqualToString:@"iPad2,7"])      return @"iPad Mini (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,1"])      return @"iPad 3 (WiFi)";
    if ([platform isEqualToString:@"iPad3,2"])      return @"iPad 3 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,3"])      return @"iPad 3 (GSM)";
    if ([platform isEqualToString:@"iPad3,4"])      return @"iPad 4 (WiFi)";
    if ([platform isEqualToString:@"iPad3,5"])      return @"iPad 4 (GSM)";
    if ([platform isEqualToString:@"iPad3,6"])      return @"iPad 4 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad4,1"])      return @"iPad Air (WiFi)";
    if ([platform isEqualToString:@"iPad4,2"])      return @"iPad Air (Cellular)";
    if ([platform isEqualToString:@"iPad4,4"])      return @"iPad mini 2G (WiFi)";
    if ([platform isEqualToString:@"iPad4,5"])      return @"iPad mini 2G (Cellular)";

    if ([platform hasSuffix:@"86"] || [platform isEqual:@"x86_64"])
    {
        return @"iOS simulator";
    }

    if([platform.lowercaseString hasPrefix:@"powermac"])    return @"Power Mac";
    if([platform.lowercaseString hasPrefix:@"emac"])    return @"eMac";
    if([platform.lowercaseString hasPrefix:@"powerbook"])    return @"iBook / PowerBook";
    if([platform.lowercaseString hasPrefix:@"imac"])    return @"iMac";
//    if([platform.lowercaseString hasPrefix:@"powermac1,"])    return @"Mac Server G3";
//    if([platform.lowercaseString hasPrefix:@"powermac3,"])    return @"Mac Server G4";
    if([platform.lowercaseString hasPrefix:@"powermac10"])    return @"Mac mini G4";
    if([platform.lowercaseString hasPrefix:@"powermac"])    return @"iMac / PowerMac";
    if([platform.lowercaseString hasPrefix:@"macmini"])    return @"Mac mini";
    if([platform.lowercaseString hasPrefix:@"macpro"])    return @"Mac Pro";
    if([platform.lowercaseString hasPrefix:@"macbook"])    return @"MacBook";
    if([platform.lowercaseString hasPrefix:@"macbookair"])    return @"MacBook Air";
    if([platform.lowercaseString hasPrefix:@"macbookpro"])    return @"MacBook Pro";
    if([platform.lowercaseString hasPrefix:@"rackmac"])    return @"Xserve";
    if([platform.lowercaseString hasPrefix:@"xserve"])    return @"Xserve";

    return platform;
}

@end
