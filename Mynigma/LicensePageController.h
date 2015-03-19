//
//  LincensePageController.h
//  BlueBird
//
//  Created by Roman Priebe on 26/07/2013.
//  Copyright (c) 2013 Mynigma. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LicensePageController : NSWindowController

@property IBOutlet NSSegmentedControl* segmentSelector;

@property IBOutlet NSButton* acceptCheckbox;

@property IBOutlet NSTextView* tosField;

@property BOOL termsAccepted;

- (IBAction)segmentSelected:(id)sender;
- (IBAction)OKButtonClicked:(id)sender;
- (IBAction)cancelButtonClicked:(id)sender;

@end
