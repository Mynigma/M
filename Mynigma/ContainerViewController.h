//
//  ContainerViewController.h
//  Container Transitions
//
//  Created by Joachim Bondo on 30/04/2014.
//
//  Interactive transition support added by Alek Åström on 11/05/2014.
//

@import UIKit;
@import Foundation;

@protocol ContainerViewControllerDelegate;

/** A very simple container view controller for demonstrating containment in an environment different from UINavigationController and UITabBarController.
 @discussion This class implements support for non-interactive custom view controller transitions.
 @note One of the many current limitations, besides not supporting interactive transitions, is that you cannot change view controllers after the object has been initialized.
 */
@interface ContainerViewController : UIViewController

/// The container view controller delegate receiving the protocol callbacks.
@property (nonatomic, weak) id<ContainerViewControllerDelegate>delegate;

/// The view controllers currently managed by the container view controller.
@property (nonatomic, copy, readonly) NSArray *viewControllers;

/// The currently selected and visible child view controller.
@property (nonatomic, assign) UIViewController *selectedViewController;

/// The gesture recognizer responsible for changing view controllers. (read-only)
@property (nonatomic, readonly) UIGestureRecognizer *interactiveTransitionGestureRecognizer;

/** Designated initializer.
 @note The view controllers array cannot be changed after initialization.
 */
- (instancetype)initWithViewControllers:(NSArray *)viewControllers;

@end

@protocol ContainerViewControllerDelegate <NSObject>
@optional
/** Informs the delegate that the user selected view controller by tapping the corresponding icon.
 @note The method is called regardless of whether the selected view controller changed or not and only as a result of the user tapped a button. The method is not called when the view controller is changed programmatically. This is the same pattern as UITabBarController uses.
 */
- (void)containerViewController:(UIViewController *)containerViewController didSelectViewController:(UIViewController *)viewController;

/// Called on the delegate to obtain a UIViewControllerAnimatedTransitioning object which can be used to animate a non-interactive transition.
- (id <UIViewControllerAnimatedTransitioning>)containerViewController:(UIViewController *)containerViewController animationControllerForTransitionFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController;

/// Called on the delegate to obtain a UIViewControllerInteractiveTransitioning object which can be used to interact during a transition
- (id <UIViewControllerInteractiveTransitioning>)containerViewController:(UIViewController *)containerViewController interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>)animationController;
@end
