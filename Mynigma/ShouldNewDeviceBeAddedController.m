//
//  ShouldNewDeviceBeAddedController.m
//  Mynigma
//
//  Created by Roman Priebe on 05/03/2013.
//  Copyright (c) 2013 Parakeet. All rights reserved.
//

#import "ShouldNewDeviceBeAddedController.h"

@interface ShouldNewDeviceBeAddedController ()

@end

@implementation ShouldNewDeviceBeAddedController

@synthesize deviceData;

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
    
    if([deviceData objectForKey:@"deviceType"])
    {
        NSString* deviceType = [deviceData objectForKey:@"deviceType"];
        [deviceTypeField setStringValue:deviceType];
        if([deviceType rangeOfString:@"iPhone"].location!=NSNotFound)
            [typeImage setImage:[NSImage imageNamed:@"iPhone_5.png"]];
        else
            [typeImage setImage:[NSImage imageNamed:NSImageNameComputer]];
    }
    if([deviceData objectForKey:@"deviceName"])
        [deviceTypeField setStringValue:[deviceData objectForKey:@"deviceName"]];
    if([deviceData objectForKey:@"date"])
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-mm-dd hh:mm:ss"];
        
        NSString *stringFromDate = [formatter stringFromDate:[deviceData objectForKey:@"date"]];
        
        [deviceTypeField setStringValue:stringFromDate];
    }
}

@end
