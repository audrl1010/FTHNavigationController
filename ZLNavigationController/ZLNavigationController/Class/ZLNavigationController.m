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

@interface ZLNavigationController()<UIGestureRecognizerDelegate,ZLViewControllerAnimatedTransitioning,ZLViewControllerContextTransitioning> {
    BOOL _isAnimationInProgress;
    //    BOOL _popAnimationInProgress;
}
@property (nonatomic, strong, readwrite) NSArray *viewControllers;

@property (nonatomic, strong) NSMutableArray *viewControllerStack;

@property (nonatomic, weak) UIViewController *currentDisplayViewController;

@property (nonatomic, strong) UIView *transitionMaskView;

@property (nonatomic, strong, readwrite) UIPanGestureRecognizer *interactiveGestureRecognizer;

@property (nonatomic, strong) ZLPercentDrivenInteractiveTransition *percentDrivenInteractiveTransition;

@property (nonatomic, weak) id<ZLViewControllerAnimatedTransitioning> animatedTransitioning;
@property (nonatomic, weak) id<ZLViewControllerContextTransitioning> contextTransitioning;

@property (nonatomic, strong) UIView *zl_containerView;
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
        self.animatedTransitioning = self;
        self.contextTransitioning = self;
    }
    return self;
}

- (void)loadView {
    self.view = [[UIView alloc] init];
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.frame = [[UIScreen mainScreen] bounds];
    
    self.zl_containerView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.zl_containerView.backgroundColor = [UIColor clearColor];
    self.zl_containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.zl_containerView];
    
    self.interactiveGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleNavigationTransition:)];
    self.interactiveGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:self.interactiveGestureRecognizer];
    
    self.transitionMaskView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.transitionMaskView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.transitionMaskView.backgroundColor = [UIColor blackColor];
    self.transitionMaskView.alpha = 0;
    self.transitionMaskView.hidden = YES;
    [self.zl_containerView addSubview:self.transitionMaskView];
    
    UIViewController *rootViewController = self.viewControllerStack[0];
    
    [rootViewController willMoveToParentViewController:self];
    [self addChildViewController:rootViewController];
    
    UIView *rootView = rootViewController.view;
    rootView.backgroundColor = [UIColor whiteColor];
    rootView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.zl_containerView addSubview:rootView];
    
    [rootViewController didMoveToParentViewController:self];
    [self addNavigationBarIfNeededByViewController:rootViewController];
}

#pragma mark Push & Pop Method
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (_isAnimationInProgress) return;
    _isAnimationInProgress = YES;
    [self.zl_containerView bringSubviewToFront:self.transitionMaskView];
    self.transitionMaskView.hidden = NO;
    
    [self.viewControllerStack addObject:viewController];
    
    [viewController willMoveToParentViewController:self];
    [self addChildViewController:viewController];
    
    UIView *toView = viewController.view;
    toView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.zl_containerView addSubview:toView];
    
    [viewController didMoveToParentViewController:self];
    [self addNavigationBarIfNeededByViewController:viewController];
    
    [self.animatedTransitioning pushAnimation:animated withFromViewController:self.currentDisplayViewController andToViewController:viewController];
}

- (void)popToRootViewControllerAnimated:(BOOL)animated {
    [self popToViewController:self.rootViewController animated:animated];
}

- (void)popViewControllerAnimated:(BOOL)animated {
    [self popToViewController:self.previousViewController animated:animated];
}

- (void)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (!viewController) return;
    if (_isAnimationInProgress) return;
    _isAnimationInProgress = YES;
    self.transitionMaskView.hidden = NO;
    
    [self.zl_containerView insertSubview:viewController.view belowSubview:self.transitionMaskView];
    
    [self.animatedTransitioning popAnimation:animated withFromViewController:self.currentDisplayViewController andToViewController:viewController];
}

#pragma mark - ZLViewControllerContextTransitioning
- (UIView *)containerView {
    return self.zl_containerView;
}

- (void)finishInteractiveTransition {
    _isAnimationInProgress = NO;
}

- (void)cancelInteractiveTransition {
    _isAnimationInProgress = NO;
}

#pragma mark - ZLViewControllerAnimatedTransitioning
- (CGFloat)transitionDuration {
    return kZLNavigationControllerPushPopTransitionDuration;
}

- (void)pushAnimation:(BOOL)animated withFromViewController:(UIViewController *)fromViewController andToViewController:(UIViewController *)toViewController {
    [self addShadowLayerIn:toViewController];
    
    [self startPushAnimationWithFromViewController:fromViewController
                                  toViewController:toViewController
                                          animated:animated
                                    withCompletion:^{
                                        [self.currentDisplayViewController.view removeFromSuperview];
                                        self.currentDisplayViewController = toViewController;
                                    }];
}

- (void)popAnimation:(BOOL)animated withFromViewController:(UIViewController *)fromViewController andToViewController:(UIViewController *)toViewController {
    [self addShadowLayerIn:self.currentDisplayViewController];
    
    [self startPopAnimationWithFromViewController:fromViewController
                                 toViewController:toViewController
                                         animated:animated
                                   withCompletion:^{
                                       [self.currentDisplayViewController.view removeFromSuperview];
                                       [self.currentDisplayViewController removeFromParentViewController];
                                       self.currentDisplayViewController = toViewController;
                                       [self releaseViewControllersAfterPopToViewController:toViewController];
                                       self.transitionMaskView.hidden = YES;
                                       [self.zl_containerView bringSubviewToFront:toViewController.view];
                                   }];
}

#pragma mark - Animation
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (flag && self.zl_containerView.layer.speed == 1.0f) {
        void(^callback)() = [anim valueForKeyPath:@"callback"];
        if (callback){
            _isAnimationInProgress = NO;
            callback();
            callback = nil;
        }
    }else {
        
    }
}

- (void)startPushAnimationWithFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController animated:(BOOL)animated withCompletion:(void(^)())callback {
    if (!animated) {
        callback();
        callback = nil;
        return;
    }
    CABasicAnimation *toAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
    toAnimation.fromValue = @(CGRectGetWidth(self.view.frame) * 1.5);
    toAnimation.toValue = @(CGRectGetWidth(self.view.frame) * 0.5);
    toAnimation.duration = [self.animatedTransitioning transitionDuration];
    toAnimation.fillMode = kCAFillModeBoth;
    toAnimation.removedOnCompletion = NO;
    toAnimation.delegate = self;
    [toAnimation setValue:callback forKeyPath:@"callback"];
    [toViewController.view.layer addAnimation:toAnimation forKey:@"zhoulee.transition.to"];
    
    CABasicAnimation *fromAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
    fromAnimation.fromValue = @(CGRectGetWidth(self.view.frame) *.5);
    fromAnimation.toValue = @0;
    fromAnimation.fillMode = kCAFillModeRemoved;
    fromAnimation.duration = [self.animatedTransitioning transitionDuration];
    fromAnimation.removedOnCompletion = YES;
    [fromViewController.view.layer addAnimation:fromAnimation forKey:@"zhoulee.transition.from"];
    
    CABasicAnimation *maskAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    maskAnimation.fromValue = @(0);
    maskAnimation.toValue = @(0);
    maskAnimation.fillMode = kCAFillModeRemoved;
    maskAnimation.duration = [self.animatedTransitioning transitionDuration];
    maskAnimation.removedOnCompletion = YES;
    [self.transitionMaskView.layer addAnimation:maskAnimation forKey:@"zhoulee.transition.opacity"];
}

- (void)startPopAnimationWithFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController animated:(BOOL)animated withCompletion:(void(^)())callback {
    if (!animated) {
        callback();
        callback = nil;
        return;
    }
    
    CABasicAnimation *fromAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
    fromAnimation.fromValue = @(CGRectGetWidth(self.view.frame) * 0.5);
    fromAnimation.toValue = @(CGRectGetWidth(self.view.frame) * 1.5);
    fromAnimation.duration = [self.animatedTransitioning transitionDuration];
    fromAnimation.fillMode = kCAFillModeBoth;
    fromAnimation.removedOnCompletion = NO;
    fromAnimation.delegate = self;
    [fromAnimation setValue:callback forKeyPath:@"callback"];
    [fromViewController.view.layer addAnimation:fromAnimation forKey:@"zhoulee.transition.from"];
    
    CABasicAnimation *toAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
    toAnimation.fromValue = @(0);
    toAnimation.toValue = @(CGRectGetWidth(self.view.frame) * 0.5);
    toAnimation.fillMode = kCAFillModeBoth;
    toAnimation.duration = [self.animatedTransitioning transitionDuration];
    toAnimation.removedOnCompletion = NO;
    [toViewController.view.layer addAnimation:toAnimation forKey:@"zhoulee.transition.to"];
    
    CABasicAnimation *maskAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    maskAnimation.fromValue = @(.4f);
    maskAnimation.toValue = @(0);
    maskAnimation.fillMode = kCAFillModeRemoved;
    maskAnimation.duration = [self.animatedTransitioning transitionDuration];
    maskAnimation.removedOnCompletion = YES;
    [self.transitionMaskView.layer addAnimation:maskAnimation forKey:@"zhoulee.transition.opacity"];
}

#pragma mark - Privite Method
- (void)addNavigationBarIfNeededByViewController:(UIViewController *)viewController {
    if (viewController.zl_navigationBarHidden) return;
    UINavigationBar *navigationBar = viewController.zl_navigationBar;
    navigationBar.translucent = YES;
    UINavigationItem *barItem = [[UINavigationItem alloc] initWithTitle:viewController.title?:@""];
    
    barItem.leftBarButtonItem = viewController.zl_navigationItem.leftBarButtonItem;
    barItem.leftBarButtonItems = viewController.zl_navigationItem.leftBarButtonItems;
    barItem.rightBarButtonItem = viewController.zl_navigationItem.rightBarButtonItem;
    barItem.rightBarButtonItems = viewController.zl_navigationItem.rightBarButtonItems;
    
    [navigationBar pushNavigationItem:barItem animated:NO];
    [viewController.view insertSubview:navigationBar atIndex:NSIntegerMax];
}

- (UIViewController *)rootViewController {
    return [self.viewControllerStack firstObject];
}

- (UIViewController *)previousViewController {
    return [self previousViewControllerByViewController:self.currentDisplayViewController];
}

- (UIViewController *)previousViewControllerByViewController:(UIViewController *)viewController {
    if (![self.viewControllerStack containsObject:viewController]) {
        return nil;
    }
    NSUInteger index = [self.viewControllerStack indexOfObject:viewController];
    if (index) {
        return [self.viewControllerStack objectAtIndex:index - 1];
    }else {
        return nil;
    }
}

- (NSUInteger)indexForViewControllerInStack:(UIViewController *)viewController {
    return [self.viewControllerStack indexOfObject:viewController];
}

- (void)releaseViewControllersAfterPopToViewController:(UIViewController *)viewController {
    NSUInteger index = [self.viewControllerStack indexOfObject:viewController];
    
    for (NSUInteger i = index + 1; i < self.viewControllerStack.count; i ++) {
        UIViewController *viewController = self.viewControllerStack[i];
        [viewController removeFromParentViewController];
    }
    [self.viewControllerStack removeObjectsInRange:NSMakeRange(index+1, self.viewControllerStack.count-index-1)];
}

- (void )addShadowLayerIn:(UIViewController *)viewController {
    CALayer *shadowLayer = viewController.view.layer;
//    shadowLayer.backgroundColor = [UIColor clearColor].CGColor;
//    shadowLayer.frame = CGRectMake(0, 0, 0.5, CGRectGetHeight(viewController.view.frame));
    shadowLayer.shadowOffset = CGSizeMake(-3, 0);
    shadowLayer.shadowRadius = 2.0;
    shadowLayer.shadowColor = [UIColor blackColor].CGColor;
    shadowLayer.shadowOpacity = 0.1;
    shadowLayer.shadowPath = [UIBezierPath bezierPathWithRect:viewController.view.bounds].CGPath;
}


#pragma mark - Interactive Gesture Recognizer
- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer {
    if (_isAnimationInProgress) {
        return NO;
    }
    
    CGPoint translate = [gestureRecognizer translationInView:self.view];
    if (translate.x < 0) {
        return NO;
    }
    
    if (self.viewControllerStack.count == 1) {
        return NO;
    }
    
    return fabs(translate.x) > fabs(translate.y);
}

- (void)handleNavigationTransition:(UIPanGestureRecognizer *)recognizer {
    CGFloat translate = [recognizer translationInView:self.view].x;
    CGFloat percent = translate / CGRectGetWidth(self.view.bounds);
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self popViewControllerAnimated:YES];
        [self.percentDrivenInteractiveTransition startInteractiveTransition];
    }else if (recognizer.state == UIGestureRecognizerStateChanged) {
        [self.percentDrivenInteractiveTransition updateInteractiveTransition:percent];
    }else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        CGFloat velocity = [recognizer velocityInView:self.view].x;
        if (percent > 0.2 || velocity > 100.0f) {
            [self.percentDrivenInteractiveTransition finishInteractiveTransition:percent];
        }else {
            [self.percentDrivenInteractiveTransition cancelInteractiveTransition:percent];
        }
    }
}

#pragma mark - Properties Getter
- (NSArray *)viewControllers {
    return [NSArray arrayWithArray:self.viewControllerStack];
}

- (ZLPercentDrivenInteractiveTransition *)percentDrivenInteractiveTransition {
    if (!_percentDrivenInteractiveTransition) {
        _percentDrivenInteractiveTransition = [[ZLPercentDrivenInteractiveTransition alloc] init];
        _percentDrivenInteractiveTransition.contextTransitioning = self;
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
        objc_setAssociatedObject(self, _cmd, navigationBar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
        objc_setAssociatedObject(self, _cmd, item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return item;
}

- (void)setZl_navigationItem:(UINavigationItem *)zl_navigationItem {
    objc_setAssociatedObject(self, @selector(zl_navigationItem), zl_navigationItem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@interface ZLPercentDrivenInteractiveTransition()

@property (nonatomic, assign) CGFloat pausedTime;

@property (nonatomic, assign) CGFloat completeSpeed;
@end

@implementation ZLPercentDrivenInteractiveTransition
- (void)startInteractiveTransition {
    [self pauseLayer:[self.contextTransitioning containerView].layer];
}

- (void)updateInteractiveTransition:(CGFloat)percentComplete {
    [self.contextTransitioning containerView].layer.timeOffset =  self.pausedTime + [self.contextTransitioning transitionDuration] * percentComplete;
}

- (void)finishInteractiveTransition:(CGFloat)percentComplete {
    [self resumeLayer:[self.contextTransitioning containerView].layer];
    [self.contextTransitioning finishInteractiveTransition];
}

- (void)cancelInteractiveTransition:(CGFloat)percentComplete {
    CALayer *containerLayer = [self.contextTransitioning containerView].layer;
    containerLayer.fillMode = kCAFillModeBoth;
    
    self.completeSpeed = percentComplete;
    
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleDisplayLink)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    CGFloat delay = 0.375;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [displayLink invalidate];
        for (CALayer *subLayer in containerLayer.sublayers) {
            [subLayer removeAllAnimations];
        }
        containerLayer.speed = 1.0;
        [self.contextTransitioning cancelInteractiveTransition];
    });
}

- (void)handleDisplayLink {
    CGFloat timeOffset = [self.contextTransitioning containerView].layer.timeOffset;
    timeOffset -= self.completeSpeed/30.0f;
    [self.contextTransitioning containerView].layer.timeOffset = timeOffset;
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












