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
#import "EmailMessage.h"

@class EmailMessageInstance, MessageListIconView;

@interface MessageCellView : NSTableCellView
{
    BOOL hasBackgroundStyleLight;
}

@property IBOutlet NSTextField* fromField;
@property IBOutlet NSTextField* toField;
@property IBOutlet NSTextField* subjectField;
@property IBOutlet NSTextField* bodyField;
@property IBOutlet NSTextField* dateSentField;
@property IBOutlet NSTextField* toStringField;

@property IBOutlet NSImageView* symbol1;
@property IBOutlet NSImageView* symbol2;
@property IBOutlet NSImageView* symbol3;
@property IBOutlet NSImageView* symbol4;
@property IBOutlet NSImageView* symbol5;

@property IBOutlet NSImageView* leftSymbol1;
@property IBOutlet NSImageView* leftSymbol2;
@property IBOutlet NSImageView* leftSymbol3;
@property IBOutlet NSImageView* leftSymbol4;
@property IBOutlet NSImageView* leftSymbol5;

@property IBOutlet NSLayoutConstraint* widthConstraint1;
@property IBOutlet NSLayoutConstraint* widthConstraint2;
@property IBOutlet NSLayoutConstraint* widthConstraint3;
@property IBOutlet NSLayoutConstraint* widthConstraint4;
@property IBOutlet NSLayoutConstraint* widthConstraint5;


@property IBOutlet NSImageView* unreadSymbol;

@property IBOutlet NSBox* box;

@property IBOutlet NSTextField* detailField;

@property IBOutlet NSTokenField* labelField;

@property IBOutlet NSTextField* previewField;

@property IBOutlet NSLayoutConstraint* boxWidthConstraint;


@property IBOutlet NSBox* topBox;
@property IBOutlet NSBox* bottomBox;

@property BOOL expanded;

@property(weak, nonatomic) EmailMessageInstance* messageInstance;

@property(weak, nonatomic) EmailMessage* message;

@property IBOutlet NSButton* disclosureTriangle;

@property NSAttributedString* toString;
@property float toWidth;

- (NSArray *)draggingImageComponents;


@property IBOutlet MessageListIconView* starImageView;


@end
