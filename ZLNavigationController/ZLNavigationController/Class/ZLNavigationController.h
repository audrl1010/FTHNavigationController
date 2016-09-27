//
//  ZLNavigationController.h
//  ZLNavigationController
//
//  Created by PatrickChow on 16/7/4.
//  Copyright © 2016年 ZhouLee. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface ZLNavigationController : UIViewController 
@property (nonatomic, strong, readonly) NSArray *viewControllers;

@property (nonatomic, weak) UIViewController *topViewController;

@property (nonatomic, strong, readonly) UIPanGestureRecognizer *interactiveGestureRecognizer;

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController;


- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

- (void)popViewControllerAnimated:(BOOL)animated;
- (void)popToViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)popToRootViewControllerAnimated:(BOOL)animated;

@end



@interface UIViewController(ZLNavigationController)
@property (nonatomic, weak, readonly) ZLNavigationController *zl_navigationController;

@property (nonatomic, assign) BOOL zl_navigationBarHidden;

@property (nonatomic, assign) BOOL zl_automaticallyAdjustsScrollViewInsets;
@end

@interface UIViewController(ZLNavigationBar)
@property (nonatomic, weak) UINavigationBar *zl_navigationBar;
@end

@interface UIViewController(ZLNavigationItem)
@property (nonatomic, weak) UINavigationItem *zl_navigationItem;
@end

@protocol ZLViewControllerContextTransitioning;
@interface ZLPercentDrivenInteractiveTransition : NSObject
@property (nonatomic, weak) id<ZLViewControllerContextTransitioning> contextTransitioning;

- (void)startInteractiveTransition;
- (void)updateInteractiveTransition:(double)percentComplete;
- (void)finishInteractiveTransition:(double)percentComplete;
- (void)cancelInteractiveTransition:(double)percentComplete;
@end

@protocol ZLViewControllerAnimatedTransitioning <NSObject>
@required
- (CGFloat)transitionDuration;

- (void)pushAnimation:(BOOL)animated withFromViewController:(UIViewController *)fromViewController andToViewController:(UIViewController *)toViewController;

- (void)popAnimation:(BOOL)animated withFromViewController:(UIViewController *)fromViewController andToViewController:(UIViewController *)toViewController;
@end

@protocol ZLViewControllerContextTransitioning <NSObject>
@required
- (UIView *)containerView;
- (CGFloat)transitionDuration;
- (void)finishInteractiveTransition;
- (void)cancelInteractiveTransition;

@end

NS_ASSUME_NONNULL_END
