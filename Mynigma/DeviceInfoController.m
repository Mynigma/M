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





#import "DeviceInfoController.h"
#import "MynigmaDevice+Category.h"
#import "AppDelegate.h"
#import "SharedSecretConfirmationController.h"
#import "TrustEstablishmentThread.h"
#import "AlertHelper.h"




@interface DeviceInfoController ()

@end

@implementation DeviceInfoController

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
}

- (void)loadDevice:(MynigmaDevice*)device
{
    [self setShownDevice:device];

    [self setDeviceImage:device.image];

    NSDate* lastSynced = device.lastSynced;
    [self setLastSyncedString:lastSynced?[NSString stringWithFormat:@"Last synced: %@", lastSynced]:@"Last synced: never"];

    [self setDeviceName:device.displayName];
    [self setUUID:device.deviceId];
}


- (IBAction)cancel:(id)sender
{
//    [NSApp endSheet:[self window] returnCode:NSOKButton];
//    [[self window] orderOut:self];
//    [AlertHelper showConnectionMode:nil];
}

- (IBAction)connect:(id)sender
{

}

- (IBAction)startTrustEstablishment:(id)sender
{
//    [NSApp endSheet:[self window] returnCode:NSOKButton];
//    [[self window] orderOut:self];
//    [APPDELEGATE showTrustEstablishmentWithDevice:self.shownDevice];

//    self.trustEstablishmentController = [[SharedSecretConfirmationController alloc] initWithWindowNibName:@"SharedSecretConfirmationController"];
//
//    [self.trustEstablishmentController setTargetDevice:self.shownDevice];
//
//    [NSApp beginSheet:self.trustEstablishmentController.window modalForWindow:self.window modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo: nil];
}


@end
