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





#import "DeviceConnectionController.h"
#import "MynigmaDevice+Category.h"
#import "DeviceItem.h"
#import "AppDelegate.h"



@interface DeviceConnectionController ()

@end

@implementation DeviceConnectionController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}


- (void)windowDidLoad
{
    [super windowDidLoad];

    [self resetCollection];

    [self setFeedbackString:NSLocalizedString(@"Looking for other devices in connection mode...", @"Connection mode controller feedback")];
}


- (void)resetCollection
{
    //make sure the current device is actually created
    [MynigmaDevice currentDevice];

    //list all devices
    NSArray* allDevices = [MynigmaDevice listAllKnownDevices];

    //remove all previous objects
    if([self.collectionController.arrangedObjects count])
        [self.collectionController removeObjects:self.collectionController.arrangedObjects];

    //now add the devices
    for(MynigmaDevice* device in allDevices)
    {
        DeviceItem* newItem = [DeviceItem new];

        [newItem setDevice:device];

        NSImage* image = [device image];

        [newItem setFirstLine:[device deviceTypeName]];

        [newItem setDeviceImage:image];

//        if([device.deviceId isEqualTo:[MynigmaDevice currentDevice].deviceId])
//            [newItem setSecondLine:NSLocalizedString(@"This device", @"Device connection UI")];
//        else
        {
            //NSDate* lastSynced = device.lastSynced;
            //[newItem setSecondLine:lastSynced?[NSString stringWithFormat:@"Last synced: %@", lastSynced]:@"Last synced: never"];

            [newItem setTopLine:[device displayName]];

            [newItem setSecondLine:[device deviceId]?[device deviceId]:@"no UUID"];

            [newItem setThirdLine:[device operatingSystemIdentifier]?[device operatingSystemIdentifier]:@"unkown OS"];
        }

        //[newItem setRepresentedObject:device];
        [self.collectionController addObject:newItem];
        
    }
}

- (IBAction)cancel:(id)sender
{
    [NSApp endSheet:[self window] returnCode:NSOKButton];
    [[self window] orderOut:self];
}

- (IBAction)connect:(id)sender
{
//    NSArray* selectedObjects = self.collectionController.selectedObjects;
//    if(selectedObjects.count>0)
//    {
//        DeviceItem* deviceItem = selectedObjects[0];
//        if([deviceItem isKindOfClass:[DeviceItem class]])
//        {
//            [NSApp endSheet:[self window] returnCode:NSOKButton];
//            [[self window] orderOut:self];
//            [AlertHelper showDeviceInfo:deviceItem.device];
//        }
//    }
}

@end
