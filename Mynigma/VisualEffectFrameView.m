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

#import "VisualEffectFrameView.h"
#import "IconListAndColourHelper.h"
#import "NSView+LayoutAdditions.h"




@implementation VisualEffectFrameView

- (void)awakeFromNib
{
    
    if(NSClassFromString(@"NSVisualEffectView"))
    {
        if(self.subviews.count)
            return;
        
        NSVisualEffectView* visualEffectView = [[NSVisualEffectView alloc] init];
        
        [visualEffectView setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
        [visualEffectView setMaterial:self.darkBlueBackground?NSVisualEffectMaterialDark:NSVisualEffectMaterialLight];
        [visualEffectView setAppearance:[NSAppearance appearanceNamed:self.darkBlueBackground?NSAppearanceNameVibrantDark:NSAppearanceNameVibrantLight]];
        [visualEffectView setState:self.darkBlueBackground?NSVisualEffectStateActive:NSVisualEffectStateFollowsWindowActiveState];
        
        [self addSubview:visualEffectView];
        
        [visualEffectView setUpConstraintsToFitIntoSuperview];
        
        if(self.darkBlueBackground)
        {
        NSBox* darkBlueBox = [[NSBox alloc] init];
        
        [darkBlueBox setBoxType:NSBoxCustom];
        NSColor* darkBlue = [NAVBAR_COLOUR colorWithAlphaComponent:.8];
        [darkBlueBox setFillColor:darkBlue];
        [darkBlueBox setBorderWidth:0];
        
        [visualEffectView addSubview:darkBlueBox];
        
        [darkBlueBox setUpConstraintsToFitIntoSuperview];
        [darkBlueBox setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
        }
    }
    else
    {
        if(self.darkBlueBackground)
        {
            NSBox* darkBlueBox = [[NSBox alloc] init];
            
            [darkBlueBox setBoxType:NSBoxCustom];
            [darkBlueBox setFillColor:NAVBAR_COLOUR];
            [darkBlueBox setBorderWidth:0];
            
            [self addSubview:darkBlueBox];
            
            [darkBlueBox setUpConstraintsToFitIntoSuperview];
        }
    }
}

@end
