//
//  FTHNavigationController.h
//  FTHNavigationController
//
//  Created by Patrick Chow on 2017/6/22.
//  Copyright © 2017年 JIEMIAN. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for FTHNavigationController.
FOUNDATION_EXPORT double FTHNavigationControllerVersionNumber;

//! Project version string for FTHNavigationController.
FOUNDATION_EXPORT const unsigned char FTHNavigationControllerVersionString[];


#ifdef FTHFloat
#define FTHFloat double
#else
#define FTHFloat double
#endif

NS_ASSUME_NONNULL_BEGIN


@class FTHPercentDrivenInteractiveTransition;

@interface FTHNavigationController : UIViewController
@property(nonatomic, strong, readonly) NSArray<__kindof UIViewController *> *viewControllers;
@property(nonatomic, weak) UIViewController *topViewController;
@property(nonatomic, strong, readonly) UIPanGestureRecognizer *interactiveGestureRecognizer;
@property(nonatomic, strong, readonly) FTHPercentDrivenInteractiveTransition *percentDrivenInteractiveTransition;

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)popViewControllerAnimated:(BOOL)animated;
- (void)popToViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)popToRootViewControllerAnimated:(BOOL)animated;

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
@end


@interface UIViewController (FTHNavigationController)
@property(nonatomic, weak, readonly) FTHNavigationController *fth_navigationController;
@property(nonatomic, assign) BOOL fth_automaticallyAdjustsScrollViewInsets;
@end

@interface UIViewController (FTHNavigationBar)
@property(nonatomic, assign) BOOL fth_navigationBarHidden;

@property(nonatomic, weak) UINavigationBar *fth_navigationBar;
@end

@interface UIViewController (FTHNavigationItem)
@property(nonatomic, weak) UINavigationItem *fth_navigationItem;
@end

@protocol FTHViewControllerContextTransitioning;
@interface FTHPercentDrivenInteractiveTransition : NSObject
@property(nonatomic, weak) id <FTHViewControllerContextTransitioning> contextTransitioning;

- (void)startInteractiveTransition;
- (void)updateInteractiveTransition:(FTHFloat)percentComplete;
- (void)finishInteractiveTransition;
- (void)cancelInteractiveTransition:(FTHFloat)percentComplete;
@end



NS_ASSUME_NONNULL_END
