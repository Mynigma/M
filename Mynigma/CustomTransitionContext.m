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

#import "CustomTransitionContext.h"

@implementation CustomTransitionContext

- (CGRect)initialFrameForViewController:(UIViewController *)viewController
{
    if (viewController == [self viewControllerForKey:UITransitionContextFromViewControllerKey])
    {
        return self.privateDisappearingFromRect;
    }
    else
    {
        return self.privateAppearingFromRect;
    }
}

- (CGRect)finalFrameForViewController:(UIViewController *)viewController
{
    if (viewController == [self viewControllerForKey:UITransitionContextFromViewControllerKey])
    {
        return self.privateDisappearingToRect;
    }
    else
    {
        return self.privateAppearingToRect;
    }
}


// Supress warnings by implementing empty interaction methods for the remainder of the protocol:

- (void)updateInteractiveTransition:(CGFloat)percentComplete {}
- (void)finishInteractiveTransition {}
- (void)cancelInteractiveTransition {}

- (void)completeTransition:(BOOL)didComplete
{
    if (self.completionBlock)
    {
        self.completionBlock (didComplete);
    }
}

- (BOOL)transitionWasCancelled
{
    return NO;
}

- (UIViewController *)viewControllerForKey:(NSString *)key
{
    return self.privateViewControllers[key];
}


@end
