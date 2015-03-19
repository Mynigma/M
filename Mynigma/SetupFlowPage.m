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

#import "SetupFlowPage.h"

@implementation SetupFlowPage



- (void)awakeFromNib
{
    //set up the collapsing constraint
    
    self.collapseWidthConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:0];

    [self.collapseWidthConstraint setPriority:1];
    
    [self addConstraint:self.collapseWidthConstraint];
    
    //it's useful to have a non-white background colour in the interface builder
    //set it to transparent to reveal the background image
    [self setBackgroundColor:[UIColor clearColor]];
}


- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    
    if(hidden)
        [self.collapseWidthConstraint setPriority:999];
    else
        [self.collapseWidthConstraint setPriority:1];
}



#pragma mark - IBActions

- (IBAction)topButtonTapped:(id)sender
{
    
}

- (IBAction)bottomButtonTapped:(id)sender
{
    
}
    

@end
