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





#import "ReloadButton.h"
#import "ReloadingDelegate.h"
#import <QuartzCore/QuartzCore.h>


@implementation ReloadButton

- (IBAction)startLoading:(id)sender
{
    [self setEnabled:NO];

    [self setWantsLayer:YES];

    static CABasicAnimation* reloadButtonRotationAnimation = nil;

    if(!reloadButtonRotationAnimation)
    {
        reloadButtonRotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        reloadButtonRotationAnimation.fromValue = @(self.layer.timeOffset);
        reloadButtonRotationAnimation.toValue = @(self.layer.timeOffset - 2*M_PI);
        reloadButtonRotationAnimation.duration = 1;
        reloadButtonRotationAnimation.cumulative = NO;
        reloadButtonRotationAnimation.repeatCount = HUGE_VALF;
        reloadButtonRotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];

    }

    [self.layer addAnimation:reloadButtonRotationAnimation forKey:@"rot"];
}

- (void)doneLoading
{
    //TO DO: pause animation. stop at current position and allow resume from the same position
    [self.layer removeAllAnimations];
    [self setEnabled:YES];
}

@end
