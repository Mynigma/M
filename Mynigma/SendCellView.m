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





#import "SendCellView.h"
#import "ContentView.h"

@implementation SendCellView

@synthesize bodyView;
@synthesize subjectField;
@synthesize recipientField;
@synthesize attachmentDisplayString;
@synthesize headField;
@synthesize lockImage;
@synthesize typeImage;
@synthesize box;
@synthesize tokenField;
@synthesize ccField;
@synthesize bccField;
@synthesize outerBox;
@synthesize subjectBox;
@synthesize fromField;

@synthesize showsCCandBCC;
@synthesize height;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}

@end
