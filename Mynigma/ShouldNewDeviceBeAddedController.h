//
//  ShouldNewDeviceBeAddedController.h
//  Mynigma
//
//  Created by Roman Priebe on 05/03/2013.
//  Copyright (c) 2013 Parakeet. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ShouldNewDeviceBeAddedController : NSWindowController
{
    IBOutlet NSTextField* deviceNameField;
    IBOutlet NSTextField* deviceTypeField;
    IBOutlet NSTextField* dateField;
    IBOutlet NSImageView* typeImage;
}

@property NSDictionary* deviceData;

@end
