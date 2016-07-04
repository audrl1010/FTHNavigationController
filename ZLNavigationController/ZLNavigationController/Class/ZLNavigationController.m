//
//  ZLNavigationController.m
//  ZLNavigationController
//
//  Created by PatrickChow on 16/7/4.
//  Copyright © 2016年 ZhouLee. All rights reserved.
//

#import "ZLNavigationController.h"

#import <objc/runtime.h>

static CGFloat kZLNavigationBarHeight = 64.0f;
static CGFloat kZLNavigationControllerPushPopTransitionDuration = .375f;

@interface ZLNavigationController() {
    BOOL _animationInProgress;
}
@property (nonatomic, strong, readwrite) NSArray *viewControllers;

@property (nonatomic, strong) NSMutableArray *viewControllerStack;

@property (nonatomic, weak) UIViewController *currentDisplayViewController;

@property (nonatomic, strong) UIView *transitionMaskView;
@end


@implementation ZLNavigationController

- (void)dealloc {
    self.viewControllerStack = nil;
    self.viewControllers = nil;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    self = [super init];
    if (self) {
        self.viewControllerStack = [NSMutableArray arrayWithObject:rootViewController];
        self.currentDisplayViewController = rootViewController;
    }
    return self;
}

- (void)loadView {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor whiteColor];
    view.frame = [[UIScreen mainScreen] bounds];
    self.view = view;
    
    self.transitionMaskView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.transitionMaskView.backgroundColor = [UIColor blackColor];
    self.transitionMaskView.hidden = YES;
    [self.view addSubview:self.transitionMaskView];
    
    
    UIViewController *rootViewController = self.viewControllerStack[0];
    
    [rootViewController willMoveToParentViewController:self];
    [self addChildViewController:rootViewController];
    
    UIView *rootView = rootViewController.view;
    rootView.backgroundColor = [UIColor whiteColor];
    rootView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:rootView];
    
    [rootViewController didMoveToParentViewController:self];
    [self addNavigationBarIfNeededByViewController:rootViewController];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}



#pragma mark Push & Pop Method
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (_animationInProgress) return;
    
    [self.view bringSubviewToFront:self.transitionMaskView];
    self.transitionMaskView.hidden = NO;
    
    [self.viewControllerStack addObject:viewController];
    [self addNavigationBarIfNeededByViewController:viewController];
    [viewController willMoveToParentViewController:self];
    [self addChildViewController:viewController];
    
    UIView *toView = viewController.view;
    toView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:toView];
    
    if (animated) {
        [self addShadowLayerBy:viewController];
        
        [self startPushAnimationWithToViewController:viewController withCompletion:^{
            [self.currentDisplayViewController.view removeFromSuperview];
            [viewController didMoveToParentViewController:self];
            self.currentDisplayViewController = viewController;
        }];
    }else{
        [self.currentDisplayViewController.view removeFromSuperview];
        [viewController didMoveToParentViewController:self];
        self.currentDisplayViewController = viewController;
    }
}

- (void)popViewControllerAnimated:(BOOL)animated {
    if (_animationInProgress) return;
    if (![self previousViewController]) return;
    
    UIViewController *viewController = [self previousViewController];
    [self.view insertSubview:viewController.view belowSubview:self.transitionMaskView];
    
    if (animated) {
         [self addShadowLayerBy:self.currentDisplayViewController];
        [self startPopAnimationWithFromViewController:self.currentDisplayViewController withCompletion:^{
            [self.currentDisplayViewController.view removeFromSuperview];
            [self.currentDisplayViewController removeFromParentViewController];
            self.currentDisplayViewController = viewController;
            [self.viewControllerStack removeLastObject];
            self.transitionMaskView.hidden = YES;
        }];
    }else {
        [self.currentDisplayViewController.view removeFromSuperview];
        [self.currentDisplayViewController removeFromParentViewController];
        self.currentDisplayViewController = viewController;
        [self.viewControllerStack removeLastObject];
    }
}

#pragma mark - Animation
- (CGFloat)transitionDuration {
    return kZLNavigationControllerPushPopTransitionDuration;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    void(^callback)() = [anim valueForKeyPath:@"callback"];
    if (callback){
        callback();
        callback = nil;
    }
}

- (void)startPushAnimationWithToViewController:(UIViewController *)toViewController withCompletion:(void(^)())callback {
    CABasicAnimation *toAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
    toAnimation.fromValue = @(CGRectGetWidth(self.view.frame)*1.5);
    toAnimation.toValue = @(CGRectGetWidth(self.view.frame)*0.5);
    toAnimation.duration = [self transitionDuration];
    toAnimation.fillMode = kCAFillModeRemoved;
    toAnimation.removedOnCompletion = YES;
    toAnimation.delegate = self;
    [toAnimation setValue:callback forKeyPath:@"callback"];
    [toViewController.view.layer addAnimation:toAnimation forKey:@"zhoulee.transition.to"];
    
    CABasicAnimation *fromAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
    fromAnimation.fromValue = @(CGRectGetWidth(self.view.frame)*.5);
    fromAnimation.toValue = @0;
    fromAnimation.fillMode = kCAFillModeRemoved;
    fromAnimation.duration = [self transitionDuration];
    fromAnimation.removedOnCompletion = YES;
    [self.currentDisplayViewController.view.layer addAnimation:fromAnimation forKey:@"zhoulee.transition.from"];
    
    CABasicAnimation *maskAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    maskAnimation.fromValue = @(.1f);
    maskAnimation.toValue = @(.4f);
    maskAnimation.fillMode = kCAFillModeBoth;
    maskAnimation.duration = [self transitionDuration];
    maskAnimation.removedOnCompletion = YES;
    [self.transitionMaskView.layer addAnimation:maskAnimation forKey:@"zhoulee.transition.opacity"];
}

- (void)startPopAnimationWithFromViewController:(UIViewController *)fromViewController withCompletion:(void(^)())callback {
    CABasicAnimation *fromAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
    fromAnimation.fromValue = @(CGRectGetWidth(self.view.frame)*0.5);
    fromAnimation.toValue = @(CGRectGetWidth(self.view.frame) * 1.5);
    fromAnimation.duration = [self transitionDuration];
    fromAnimation.fillMode = kCAFillModeRemoved;
    fromAnimation.removedOnCompletion = YES;
    fromAnimation.delegate = self;
    [fromAnimation setValue:callback forKeyPath:@"callback"];
    [fromViewController.view.layer addAnimation:fromAnimation forKey:@"zhoulee.transition.from"];
    
    CABasicAnimation *toAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
    toAnimation.fromValue = @(0);
    toAnimation.toValue = @(CGRectGetWidth(self.view.frame)*0.5);
    toAnimation.fillMode = kCAFillModeRemoved;
    toAnimation.duration = [self transitionDuration];
    toAnimation.removedOnCompletion = YES;
    [[self previousViewController].view.layer addAnimation:toAnimation forKey:@"zhoulee.transition.to"];
    
    CABasicAnimation *maskAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    maskAnimation.fromValue = @(.4f);
    maskAnimation.toValue = @(.1f);
    maskAnimation.fillMode = kCAFillModeBoth;
    maskAnimation.duration = [self transitionDuration];
    maskAnimation.removedOnCompletion = YES;
    [self.transitionMaskView.layer addAnimation:maskAnimation forKey:@"zhoulee.transition.opacity"];
}

#pragma mark - Privite Method
- (void)addNavigationBarIfNeededByViewController:(UIViewController *)viewController {
    if (viewController.zl_navigationBarHidden) return;
    UINavigationBar *navigationBar = [[UINavigationBar alloc] initWithFrame:
                                      CGRectMake(0, 0, CGRectGetWidth(viewController.view.frame), kZLNavigationBarHeight)];
    viewController.zl_navigationBar = navigationBar;
    navigationBar.translucent = YES;
    
    UINavigationItem *barItem = [[UINavigationItem alloc] initWithTitle:viewController.title?:@""];
    
    NSAssert(!(viewController.zl_navigationItem.leftBarButtonItem && viewController.zl_navigationItem.leftBarButtonItems), @"both of leftItems and leftItem is set");
    NSAssert(!(viewController.zl_navigationItem.rightBarButtonItem && viewController.zl_navigationItem.rightBarButtonItems), @"both of rightItems and rightItem is set");
    
    barItem.leftBarButtonItem = viewController.zl_navigationItem.leftBarButtonItem;
    barItem.leftBarButtonItems = viewController.zl_navigationItem.leftBarButtonItems;
    barItem.rightBarButtonItem = viewController.zl_navigationItem.rightBarButtonItem;
    barItem.rightBarButtonItems = viewController.zl_navigationItem.rightBarButtonItems;
    
    [navigationBar pushNavigationItem:barItem animated:NO];
    [viewController.view insertSubview:navigationBar atIndex:NSIntegerMax];
}

- (UIViewController *)previousViewController {
    NSUInteger index = [self.viewControllerStack indexOfObject:self.currentDisplayViewController];
    if (index) {
        return [self.viewControllerStack objectAtIndex:index - 1];
    }else {
        return nil;
    }
}

- (CALayer *)addShadowLayerBy:(UIViewController *)viewController {
    CALayer *shadowLayer = [CALayer layer];
    shadowLayer.backgroundColor = [UIColor whiteColor].CGColor;
    shadowLayer.frame = CGRectMake(0, 0, 1, CGRectGetHeight(viewController.view.frame));
    shadowLayer.shadowOffset = CGSizeMake(-4, 0);
    shadowLayer.shadowRadius = 4.0;
    shadowLayer.shadowColor = [UIColor blackColor].CGColor;
    shadowLayer.shadowOpacity = 1;
    shadowLayer.shadowPath = [UIBezierPath bezierPathWithRect:shadowLayer.frame].CGPath;
    [viewController.view.layer insertSublayer:shadowLayer atIndex:0];
    return shadowLayer;
}

#pragma mark - Properties
- (NSArray *)viewControllers {
    return [NSArray arrayWithArray:self.viewControllerStack];
}

@end


@implementation UIViewController(ZLNavigationController)
@dynamic zl_navigationController;

- (ZLNavigationController *)zl_navigationController {
    if ([self.parentViewController isKindOfClass:[ZLNavigationController class]]) {
        return (ZLNavigationController *)self.parentViewController;
    }
    return nil;
}

- (BOOL)zl_navigationBarHidden {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setZl_navigationBarHidden:(BOOL)zl_navigationBarHidden {
    objc_setAssociatedObject(self, @selector(zl_navigationBarHidden), @(zl_navigationBarHidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UIViewController(ZLNavigationBar)

- (UINavigationItem *)zl_navigationBar {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setZl_navigationBar:(UINavigationBar *)zl_navigationBar {
    objc_setAssociatedObject(self, @selector(zl_navigationBar), zl_navigationBar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UIViewController (ZLNavigationItem)

- (UINavigationItem *)zl_navigationItem {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setZl_navigationItem:(UINavigationItem *)zl_navigationItem {
    objc_setAssociatedObject(self, @selector(zl_navigationItem), zl_navigationItem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end