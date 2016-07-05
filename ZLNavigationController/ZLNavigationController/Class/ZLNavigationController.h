//
//  ZLNavigationController.h
//  ZLNavigationController
//
//  Created by PatrickChow on 16/7/4.
//  Copyright © 2016年 ZhouLee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZLNavigationController : UIViewController
@property (nonatomic, strong, readonly) NSArray *viewControllers;

@property (nonatomic, strong, readonly) UIPanGestureRecognizer *interactiveGestureRecognizer;

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController;

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

- (void)popViewControllerAnimated:(BOOL)animated;
@end



@interface UIViewController(ZLNavigationController)
@property (nonatomic, weak, readonly) ZLNavigationController *zl_navigationController;

@property (nonatomic, assign) BOOL zl_navigationBarHidden;
@end

@interface UIViewController(ZLNavigationBar)
@property (nonatomic, strong) UINavigationBar *zl_navigationBar;
@end

@interface UIViewController(ZLNavigationItem)
@property (nonatomic, strong) UINavigationItem *zl_navigationItem;
@end

@interface ZLPercentDrivenInteractiveTransition : NSObject
- (void)startInteractiveTransition;

- (void)updateInteractiveTransition:(CGFloat)percentComplete;

- (void)finishInteractiveTransition:(CGFloat)percentComplete;
@end

