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





#import <Cocoa/Cocoa.h>

@class ContentView, EmailMessageInstance, AddressLabelView, EmailMessage;

@interface ContentViewer : NSView
{
    ContentView* bodyView;
    NSTextField* subjectField;
    EmailMessageInstance* messageInstance;
    float height;

    NSImageView* lockView;

    NSButton* replyAllButton;

    NSBox* outerBox;
}

@property IBOutlet NSLayoutConstraint* boxWidthConstraint;
@property IBOutlet NSLayoutConstraint* picHiderConstraint;

@property IBOutlet NSImageView* profilePicView;

@property IBOutlet NSTextView* fromToTextView;

@property IBOutlet ContentView* bodyView;
@property IBOutlet NSTextField* subjectField;
@property EmailMessage* message;
@property float height;
@property IBOutlet NSBox* outerBox;
@property NSString* feedBackString;
@property BOOL feedBackIndicatorShown;
@property IBOutlet NSBox* feedbackBox;

@property IBOutlet NSButton* unreadButton;
@property IBOutlet NSButton* flagButton;

@property IBOutlet NSImageView* lockView;

@property IBOutlet NSButton* replyAllButton;

@property IBOutlet NSTextField* showImagesLabel;

@property IBOutlet NSButton* tryAgainButton;

@property IBOutlet NSTextField* tryAgainLabel;

- (IBAction)tryAgainButtonClicked:(id)sender;

@property IBOutlet NSProgressIndicator* progressBar;

@property IBOutlet AddressLabelView* addressLabelView;


@end
