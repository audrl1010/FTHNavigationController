//
//  FTHNavigationController.h
//  FTHNavigationController
//
//  Created by Patrick Chow on 2017/9/26.
//  Copyright © 2017年 For the Horde. All rights reserved.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXPORT double FTHNavigationControllerVersionNumber;
FOUNDATION_EXPORT const unsigned char FTHNavigationControllerVersionString[];

NS_ASSUME_NONNULL_BEGIN

@class FTHNavigationController;
@protocol FTHNavigationControllerDelegate <NSObject>
@optional
- (void)navigationController:(FTHNavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)navigationController:(FTHNavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated;

- (nullable id <UIViewControllerInteractiveTransitioning>)navigationController:(FTHNavigationController *)navigationController
                          interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>) animationController NS_AVAILABLE_IOS(7_0);

- (nullable id <UIViewControllerAnimatedTransitioning>)navigationController:(FTHNavigationController *)navigationController
                                   animationControllerForOperation:(UINavigationControllerOperation)operation
                                                fromViewController:(UIViewController *)fromVC
                                                  toViewController:(UIViewController *)toVC  NS_AVAILABLE_IOS(7_0);
@end


@interface FTHNavigationController : UIViewController
@property(nonatomic, strong, readonly) NSArray<__kindof UIViewController *> *viewControllers;
@property(nonatomic, strong, readonly, nullable) UIViewController *topViewController;
@property(nonatomic, strong, readonly) UIPanGestureRecognizer *interactiveGestureRecognizer __TVOS_PROHIBITED;

@property(nonatomic, weak, nullable) id <FTHNavigationControllerDelegate> delegate;

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

- (void)showViewController:(UIViewController *)viewController sender:(nullable id)sender;

- (nullable UIViewController *)popViewControllerAnimated:(BOOL)animated;

- (nullable NSArray<__kindof UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated;

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController NS_DESIGNATED_INITIALIZER;

@end

@interface FTHNavigationController (Unavailable)
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
@end

@interface UIViewController (FTHNavigationController)
@property(nonatomic, weak, readonly, nullable) FTHNavigationController *fth_navigationController;
@property(nonatomic, assign) BOOL fth_automaticallyAdjustsScrollViewInsets API_DEPRECATED_WITH_REPLACEMENT("Use UIScrollView's contentInsetAdjustmentBehavior instead", ios(7.0, 11.0), tvos(7.0, 11.0));
@end

@interface UIViewController (FTHNavigationBar)
@property(nonatomic, strong, readonly, nullable) UINavigationBar *fth_navigationBar;
@property(nonatomic, assign) BOOL fth_navigationBarHidden;
@end

@interface UIViewController (FTHNavigationItem)
@property(nonatomic, strong, readonly, nullable) UINavigationItem *fth_navigationItem;
@end

NS_ASSUME_NONNULL_END

