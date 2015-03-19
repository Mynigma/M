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
#import <WebKit/WebKit.h>


@interface SendCellView : NSTableCellView
{
    WebView* bodyView;
    NSTextField* subjectField;
    NSTextField* recipientField;
    NSTextField* headField;
    NSString* attachmentDisplayString;
    NSImageView* lockImage;
    NSImageView* typeImage;
    NSBox* box;
    
    NSTokenField* tokenField;
    
    float height;
    
    NSBox* outerBox;
}

@property IBOutlet WebView* bodyView;
@property IBOutlet NSTextField* subjectField;
@property IBOutlet NSTextField* recipientField;
@property IBOutlet NSTextField* headField;
@property NSString* attachmentDisplayString;
@property IBOutlet NSImageView* lockImage;
@property IBOutlet NSImageView* typeImage;
@property IBOutlet NSBox* box;
@property IBOutlet NSBox* outerBox;

@property IBOutlet NSTokenField* tokenField;
@property IBOutlet NSTokenField* ccField;
@property IBOutlet NSTokenField* bccField;

@property IBOutlet NSTokenField* fromField;

@property IBOutlet NSBox* subjectBox;

@property float height;

@property BOOL showsCCandBCC;

@end
