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

@interface AccountOrFolderView : NSTableCellView

@property IBOutlet NSImageView* statusImage;
@property IBOutlet NSButton* unreadButton;
@property IBOutlet NSTextField* statusLabel;
@property IBOutlet NSTextField* nameField;
@property IBOutlet NSTextField* unreadTextField;

@property IBOutlet NSProgressIndicator* progressIndicator;
@property IBOutlet NSProgressIndicator* progressBar;

@property NSObject* representedObject;

@property IBOutlet NSLayoutConstraint* imageConstraint;
@property IBOutlet NSLayoutConstraint* unreadContraint;
@property IBOutlet NSLayoutConstraint* safeConstraint;
@property IBOutlet NSLayoutConstraint* indentationConstraint;


@end
