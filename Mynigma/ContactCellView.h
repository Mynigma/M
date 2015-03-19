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
#import "AppDelegate.h"
@class Contact;

@interface ContactCellView : NSTableCellView
{
    NSTextField* detailView;
    NSImageView* fbView;
    NSImageView* skypeView;
    NSImageView* lockView;
    
    NSImageView* groupImage1;
    NSImageView* groupImage2;
    NSImageView* groupImage3;
    NSImageView* groupImage4;
    NSImageView* groupImage5;
    NSImageView* groupImage6;
    NSImageView* groupImage7;
    NSImageView* groupImage8;
    NSImageView* groupImage9;
    Contact* contact;
    
    BOOL hasPicture;
    
}
@property IBOutlet NSTextField* detailView;
@property IBOutlet NSImageView* fbView;
@property IBOutlet NSImageView* skypeView;
@property IBOutlet NSImageView* lockView;

@property IBOutlet NSImageView* groupImage1;
@property IBOutlet NSImageView* groupImage2;
@property IBOutlet NSImageView* groupImage3;
@property IBOutlet NSImageView* groupImage4;
@property IBOutlet NSImageView* groupImage5;
@property IBOutlet NSImageView* groupImage6;
@property IBOutlet NSImageView* groupImage7;
@property IBOutlet NSImageView* groupImage8;
@property IBOutlet NSImageView* groupImage9;
@property Contact* contact;

@property BOOL hasPicture;

//- (NSArray *)draggingImageComponents;
- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle;

@end
