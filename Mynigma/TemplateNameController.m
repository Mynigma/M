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





#import "TemplateNameController.h"
#import "MessageTemplate+Category.h"



@interface TemplateNameController ()

@end

@implementation TemplateNameController

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
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)OKButtonPressed:(id)sender
{
    [MessageTemplate addNewTemplateWithDisplayName:self.textField.stringValue subject:self.subject andHTMLBody:self.HTMLBody recipients:self.recipients attachments:self.attachments allAttachments:self.allAttachments];

    [NSApp endSheet:[self window] returnCode:NSOKButton];
    [[self window] orderOut:self];
}

- (IBAction)cancelButtonPressed:(id)sender
{
    [NSApp endSheet:[self window] returnCode:NSOKButton];
    [[self window] orderOut:self];
}

@end
