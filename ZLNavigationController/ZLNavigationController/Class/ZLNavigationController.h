//
//  ZLNavigationController.h
//  ZLNavigationController
//
//  Created by PatrickChow on 16/7/4.
//  Copyright © 2016-2017年 ZhouLee. All rights reserved.
//

#import <UIKit/UIKit.h>

#define ZLFloat double

NS_ASSUME_NONNULL_BEGIN
@protocol ZLNavigationControllerDelegate;

@interface ZLNavigationController : UIViewController
/// The designated initializer.
- (instancetype)initWithRootViewController:(UIViewController *)rootViewController;

@property(nonatomic, strong, readonly) NSArray *viewControllers;

@property(nonatomic, weak) UIViewController *topViewController;

@property(nonatomic, weak) id <ZLNavigationControllerDelegate> delegate;

@property(nonatomic, strong, readonly) UIPanGestureRecognizer *interactiveGestureRecognizer;


- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

- (void)popViewControllerAnimated:(BOOL)animated;

- (void)popToViewController:(UIViewController *)viewController animated:(BOOL)animated;

- (void)popToRootViewControllerAnimated:(BOOL)animated;

@end


@interface UIViewController (ZLNavigationController)
@property(nonatomic, weak, readonly) ZLNavigationController *zl_navigationController;

@property(nonatomic, assign) BOOL zl_navigationBarHidden;

@property(nonatomic, assign) BOOL zl_automaticallyAdjustsScrollViewInsets;
@end

@interface UIViewController (ZLNavigationBar)
@property(nonatomic, weak) UINavigationBar *zl_navigationBar;
@end

@interface UIViewController (ZLNavigationItem)
@property(nonatomic, weak) UINavigationItem *zl_navigationItem;
@end

@protocol ZLViewControllerContextTransitioning;

@interface ZLPercentDrivenInteractiveTransition : NSObject
@property(nonatomic, weak) id <ZLViewControllerContextTransitioning> contextTransitioning;

- (void)startInteractiveTransition;

- (void)updateInteractiveTransition:(ZLFloat)percentComplete;

- (void)finishInteractiveTransition;

- (void)cancelInteractiveTransition:(ZLFloat)percentComplete;
@end

@protocol ZLViewControllerAnimatedTransitioning;

@protocol ZLNavigationControllerDelegate <NSObject>
@optional
- (id <ZLViewControllerAnimatedTransitioning>)animationControllerForOperation:(UINavigationControllerOperation)operation
                                                           fromViewController:(UIViewController *)fromViewController
                                                             toViewController:(UIViewController *)toViewController;
- (void)navigationController:(ZLNavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController;

- (void)navigationController:(ZLNavigationController *)navigationController
      didShowViewController:(UIViewController *)viewController;


@end

@protocol ZLViewControllerAnimatedTransitioning <NSObject>
- (CGFloat)transitionDuration;

- (void)pushAnimation:(BOOL)animated
   fromViewController:(UIViewController *)fromViewController
     toViewController:(UIViewController *)toViewController;

- (void)popAnimation:(BOOL)animated
  fromViewController:(UIViewController *)fromViewController
    toViewController:(UIViewController *)toViewController;
@end

@protocol ZLViewControllerContextTransitioning <NSObject>
@required

@property(nonatomic, weak) UIView *containerView;

@property(nonatomic, weak) UIViewController *fromViewController;
@property(nonatomic, weak) UIViewController *toViewController;

@property(nonatomic, assign) BOOL animating;

- (CGFloat)transitionDuration;

- (void)finishInteractiveTransition;

- (void)cancelInteractiveTransition;

@end

NS_ASSUME_NONNULL_END
