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

@interface ZLNavigationController()<UIGestureRecognizerDelegate> {
    BOOL _isAnimationInProgress;
    //    BOOL _popAnimationInProgress;
}
@property (nonatomic, strong, readwrite) NSArray *viewControllers;

@property (nonatomic, strong) NSMutableArray *viewControllerStack;

@property (nonatomic, weak) UIViewController *currentDisplayViewController;

@property (nonatomic, strong) UIView *transitionMaskView;

@property (nonatomic, strong, readwrite) UIPanGestureRecognizer *interactiveGestureRecognizer;

@property (nonatomic, strong) ZLPercentDrivenInteractiveTransition *percentDrivenInteractiveTransition;


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
    self.view = [[UIView alloc] init];
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.frame = [[UIScreen mainScreen] bounds];
    
    self.interactiveGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleNavigationTransition:)];
    self.interactiveGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:self.interactiveGestureRecognizer];
    
    self.transitionMaskView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.transitionMaskView.backgroundColor = [UIColor blackColor];
    self.transitionMaskView.alpha = 0;
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

#pragma mark Push & Pop Method
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (_isAnimationInProgress) return;
    _isAnimationInProgress = YES;
    [self.view bringSubviewToFront:self.transitionMaskView];
    self.transitionMaskView.hidden = NO;
    
    [self.viewControllerStack addObject:viewController];
    
    [viewController willMoveToParentViewController:self];
    [self addChildViewController:viewController];
    
    UIView *toView = viewController.view;
    toView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:toView];
    
    [viewController didMoveToParentViewController:self];
    [self addNavigationBarIfNeededByViewController:viewController];
    CALayer *shadowLayer = [self addShadowLayerIn:viewController];
    
    [self startPushAnimationWithToViewController:viewController animated:animated withCompletion:^{
        [shadowLayer removeFromSuperlayer];
        [viewController.view.layer removeAnimationForKey:@"zhoulee.transition.to"];
        [self.currentDisplayViewController.view removeFromSuperview];
        self.currentDisplayViewController = viewController;
    }];
}

- (void)popViewControllerAnimated:(BOOL)animated {
    if (_isAnimationInProgress) return;
    if (![self previousViewController]) return;
    
    self.transitionMaskView.hidden = NO;
    
    UIViewController *viewController = [self previousViewController];
    [self.view insertSubview:viewController.view belowSubview:self.transitionMaskView];
    
    CALayer *shadowLayer = [self addShadowLayerIn:self.currentDisplayViewController];
    
    [self startPopAnimationWithFromViewController:self.currentDisplayViewController animated:animated withCompletion:^{
        [shadowLayer removeFromSuperlayer];
        [self.currentDisplayViewController.view.layer removeAnimationForKey:@"zhoulee.transition.from"];
        [self.currentDisplayViewController.view removeFromSuperview];
        [self.currentDisplayViewController removeFromParentViewController];
        self.currentDisplayViewController = viewController;
        [self.viewControllerStack removeLastObject];
        self.transitionMaskView.hidden = YES;
        [self.view bringSubviewToFront:viewController.view];
    }];
}

#pragma mark - Animation
- (CGFloat)transitionDuration {
    return kZLNavigationControllerPushPopTransitionDuration;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    void(^callback)() = [anim valueForKeyPath:@"callback"];
    if (callback){
        _isAnimationInProgress = NO;
        callback();
        callback = nil;
    }
}

- (void)startPushAnimationWithToViewController:(UIViewController *)toViewController animated:(BOOL)animated withCompletion:(void(^)())callback {
    if (!animated) {
        callback();
        callback = nil;
        return;
    }
    CABasicAnimation *toAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
    toAnimation.fromValue = @(CGRectGetWidth(self.view.frame)*1.5);
    toAnimation.toValue = @(CGRectGetWidth(self.view.frame)*0.5);
    toAnimation.duration = [self transitionDuration];
    toAnimation.fillMode = kCAFillModeBoth;
    toAnimation.removedOnCompletion = NO;
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
    maskAnimation.fromValue = @(0);
    maskAnimation.toValue = @(0);
    maskAnimation.fillMode = kCAFillModeRemoved;
    maskAnimation.duration = [self transitionDuration];
    maskAnimation.removedOnCompletion = YES;
    [self.transitionMaskView.layer addAnimation:maskAnimation forKey:@"zhoulee.transition.opacity"];
}

- (void)startPopAnimationWithFromViewController:(UIViewController *)fromViewController animated:(BOOL)animated withCompletion:(void(^)())callback {
    if (!animated) {
        callback();
        callback = nil;
        return;
    }
    CABasicAnimation *fromAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
    fromAnimation.fromValue = @(CGRectGetWidth(self.view.frame)*0.5);
    fromAnimation.toValue = @(CGRectGetWidth(self.view.frame) * 1.5);
    fromAnimation.duration = [self transitionDuration];
    fromAnimation.fillMode = kCAFillModeBoth;
    fromAnimation.removedOnCompletion = NO;
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
    maskAnimation.toValue = @(0);
    maskAnimation.fillMode = kCAFillModeRemoved;
    maskAnimation.duration = [self transitionDuration];
    maskAnimation.removedOnCompletion = YES;
    [self.transitionMaskView.layer addAnimation:maskAnimation forKey:@"zhoulee.transition.opacity"];
}

#pragma mark - Privite Method
- (void)addNavigationBarIfNeededByViewController:(UIViewController *)viewController {
    if (viewController.zl_navigationBarHidden) return;
    UINavigationBar *navigationBar = viewController.zl_navigationBar;
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

- (CALayer *)addShadowLayerIn:(UIViewController *)viewController {
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


#pragma mark - Interactive Gesture Recognizer
- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer {
    if (_isAnimationInProgress) {
        return NO;
    }
    
    CGFloat translate = [gestureRecognizer translationInView:self.view].x;
    if (translate < 0) {
        return NO;
    }
    
    if (self.viewControllerStack.count == 1) {
        return NO;
    }
    
    return YES;
}

- (void)handleNavigationTransition:(UIPanGestureRecognizer *)recognizer {
    CGFloat translate = [recognizer translationInView:self.view].x;
    CGFloat percent = translate / CGRectGetWidth(self.view.bounds);
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self popViewControllerAnimated:YES];
        [self.percentDrivenInteractiveTransition startInteractiveTransition];
    }else if (recognizer.state == UIGestureRecognizerStateChanged) {
        [self.percentDrivenInteractiveTransition updateInteractiveTransition:percent];
    }else if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.percentDrivenInteractiveTransition finishInteractiveTransition:percent];
    }
}

#pragma mark - Properties Getter
- (NSArray *)viewControllers {
    return [NSArray arrayWithArray:self.viewControllerStack];
}

- (ZLPercentDrivenInteractiveTransition *)percentDrivenInteractiveTransition {
    if (!_percentDrivenInteractiveTransition) {
        _percentDrivenInteractiveTransition = [[ZLPercentDrivenInteractiveTransition alloc] init];
        [_percentDrivenInteractiveTransition setValue:self.view.layer forKeyPath:@"containerLayer"];
        [_percentDrivenInteractiveTransition setValue:@([self transitionDuration]) forKeyPath:@"duration"];
    }
    return _percentDrivenInteractiveTransition;
}
@end

#pragma mark -
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
- (UINavigationBar *)zl_navigationBar {
    UINavigationBar *navigationBar = objc_getAssociatedObject(self, _cmd);
    if (!navigationBar) {
        navigationBar = [[UINavigationBar alloc] initWithFrame:
                             CGRectMake(0, 0, CGRectGetWidth(self.view.frame), kZLNavigationBarHeight)];
        navigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        objc_setAssociatedObject(self, @selector(zl_navigationBar), navigationBar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return navigationBar;
}

- (void)setZl_navigationBar:(UINavigationBar *)zl_navigationBar {
    objc_setAssociatedObject(self, @selector(zl_navigationBar), zl_navigationBar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UIViewController (ZLNavigationItem)

- (UINavigationItem *)zl_navigationItem {
    UINavigationItem *item = objc_getAssociatedObject(self, _cmd);
    if (!item) {
        item = [[UINavigationItem alloc] initWithTitle:self.title?:@""];
        objc_setAssociatedObject(self, @selector(zl_navigationItem), item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return item;
}

- (void)setZl_navigationItem:(UINavigationItem *)zl_navigationItem {
    objc_setAssociatedObject(self, @selector(zl_navigationItem), zl_navigationItem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@interface ZLPercentDrivenInteractiveTransition()
@property (nonatomic, strong) CALayer *containerLayer;

@property (nonatomic, assign) CGFloat pausedTime;

@property (nonatomic, assign) CGFloat completionSpeed;

@property (nonatomic, strong) NSNumber *duration;
@end

@implementation ZLPercentDrivenInteractiveTransition
- (void)startInteractiveTransition {
    [self pauseLayer:self.containerLayer];
}

- (void)updateInteractiveTransition:(CGFloat)percentComplete {
    self.containerLayer.timeOffset =  self.pausedTime + self.duration.floatValue * percentComplete;
}

- (void)finishInteractiveTransition:(CGFloat)percentComplete {
    self.completionSpeed = percentComplete;
    [self resumeLayer:self.containerLayer];
}

#pragma mark - Handle Layer
- (void)pauseLayer:(CALayer*)layer {
    CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
    layer.speed = 0.0;
    layer.timeOffset = pausedTime;
    self.pausedTime = pausedTime;
}

- (void)resumeLayer:(CALayer*)layer {
    CFTimeInterval pausedTime = [layer timeOffset];
    layer.speed = 1.0;
    layer.timeOffset = 0.0;
    layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    layer.beginTime = timeSincePause;
}
@end












