//
//  ZLNavigationController.m
//  ZLNavigationController
//
//  Created by PatrickChow on 16/7/4.
//  Copyright © 2016-2017年 ZhouLee. All rights reserved.
//

#import "ZLNavigationController.h"
#import <objc/runtime.h>


static CGFloat kZLNavigationBarHeight = 64.0f;
static CGFloat kZLNavigationControllerPushPopTransitionDuration = .275f;

@interface ZLTouchFilterView : UIView
@end

@implementation ZLTouchFilterView
- (nullable UIView *)hitTest:(CGPoint)point withEvent:(nullable UIEvent *)event {return self;}
@end

@interface ZLContextTransitioning : NSObject <ZLViewControllerContextTransitioning>
@property(nonatomic, assign) UINavigationControllerOperation operation;
@end

@implementation ZLContextTransitioning
@synthesize containerView = _containerView;
@synthesize fromViewController = _fromViewController;
@synthesize toViewController = _toViewController;
@synthesize animating = _animating;

- (CGFloat)transitionDuration {
    return kZLNavigationControllerPushPopTransitionDuration;
}

- (void)finishInteractiveTransition {
    self.animating = NO;
    if (self.operation == UINavigationControllerOperationPush) {
        [self.fromView removeFromSuperview];
        [self.toViewController didMoveToParentViewController:nil];
        [self.toViewController endAppearanceTransition];
        [self.fromViewController endAppearanceTransition];
    } else {
        [self.fromView removeFromSuperview];
        [self.fromViewController removeFromParentViewController];
        [self.toViewController endAppearanceTransition];
        [self.fromViewController endAppearanceTransition];
        [self.containerView bringSubviewToFront:self.toView];
    }
}

- (void)cancelInteractiveTransition {
    self.animating = NO;
    [self.toViewController beginAppearanceTransition:NO animated:NO];
    [self.fromViewController beginAppearanceTransition:YES animated:NO];
    [self.toView removeFromSuperview];
    [self.toViewController endAppearanceTransition];
    [self.fromViewController endAppearanceTransition];
}

#pragma mark - Properties

- (UIView *)fromView {
    return self.fromViewController.view;
}

- (UIView *)toView {
    return self.toViewController.view;
}

@end


@interface ZLNavigationController () <UIGestureRecognizerDelegate,
        CAAnimationDelegate,
        ZLViewControllerAnimatedTransitioning>

@property(nonatomic, strong) NSMutableArray *viewControllerStack;

@property(nonatomic, strong) ZLTouchFilterView *transitionMaskView;

@property(nonatomic, strong, readwrite) UIPanGestureRecognizer *interactiveGestureRecognizer;

@property(nonatomic, strong, readwrite) ZLPercentDrivenInteractiveTransition *percentDrivenInteractiveTransition;

@property(nonatomic, strong) ZLContextTransitioning *contextTransitioning;
@end


@implementation ZLNavigationController {
    struct DelegateFlags {
        unsigned int willShowViewController:1;
        unsigned int didShowViewController:1;
    } _delegateFlags;
}

- (void)dealloc {
    self.viewControllerStack = nil;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    self = [super init];
    if (self) {
        _viewControllerStack = [@[rootViewController] mutableCopy];
        _contextTransitioning = [[ZLContextTransitioning alloc] init];
    }
    return self;
}

- (void)loadView {
    CGRect bounds = [[UIScreen mainScreen] bounds];

    self.view = [[UIView alloc] initWithFrame:bounds];
    self.view.backgroundColor = [UIColor whiteColor];

    self.contextTransitioning.containerView = self.view;

    self.interactiveGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(handleNavigationTransition:)];
    self.interactiveGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:self.interactiveGestureRecognizer];

    self.transitionMaskView = [[ZLTouchFilterView alloc] initWithFrame:bounds];
    self.transitionMaskView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.transitionMaskView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.transitionMaskView];

    UIViewController *rootViewController = self.viewControllerStack[0];

    [self addChildViewController:rootViewController];
    [rootViewController willMoveToParentViewController:self];
    UIView *rootView = rootViewController.view;
    rootView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [self.view addSubview:rootView];

    [rootViewController didMoveToParentViewController:self];
    [self addNavigationBarIfNeededByViewController:rootViewController];
}

#pragma mark - Properties

- (UIView *)containerView {
    return self.view;
}

- (NSArray *)viewControllers {
    return [NSArray arrayWithArray:self.viewControllerStack];
}

- (UIViewController *)topViewController {
    return self.viewControllerStack.lastObject;
}

- (ZLPercentDrivenInteractiveTransition *)percentDrivenInteractiveTransition {
    if (!_percentDrivenInteractiveTransition) {
        _percentDrivenInteractiveTransition = [[ZLPercentDrivenInteractiveTransition alloc] init];
        _percentDrivenInteractiveTransition.contextTransitioning = self.contextTransitioning;
    }
    return _percentDrivenInteractiveTransition;
}

- (void)setDelegate:(id <ZLNavigationControllerDelegate>)delegate {
    _delegate = delegate;

    memset(&_delegateFlags, 0, sizeof(_delegateFlags));
    if ([delegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)]) {
        _delegateFlags.willShowViewController = 1;
    }
    if ([delegate respondsToSelector:@selector(navigationController:didShowViewController:)]) {
        _delegateFlags.didShowViewController = 1;
    }
}

#pragma mark Push & Pop Method

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.contextTransitioning.animating) return;

    UIViewController *fromViewController = self.topViewController;
    [self.containerView bringSubviewToFront:self.transitionMaskView];
    [self addChildViewController:viewController];
    [self.viewControllerStack addObject:viewController];
    ///
    UIView *toView = viewController.view;
    toView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [viewController beginAppearanceTransition:YES animated:animated];
    [self.containerView addSubview:toView];
    
    [fromViewController beginAppearanceTransition:NO animated:animated];
    
//    [viewController didMoveToParentViewController:self]; // 在结束动画的时候需要手动调用一下，系统不会自己调用这个方法。
    [self addNavigationBarIfNeededByViewController:viewController];

    self.contextTransitioning.animating = YES;
    self.contextTransitioning.fromViewController = fromViewController;
    self.contextTransitioning.toViewController = viewController;
    self.contextTransitioning.operation = UINavigationControllerOperationPush;

    [self pushAnimation:animated
     fromViewController:fromViewController
       toViewController:viewController];
}

- (void)popToRootViewControllerAnimated:(BOOL)animated {
    if (self.previousViewController) [self popToViewController:self.rootViewController animated:animated];
}

- (void)popViewControllerAnimated:(BOOL)animated {
    [self popToViewController:self.previousViewController animated:animated];
}

- (void)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (!viewController) return;
    if (self.contextTransitioning.animating) return;

    [viewController beginAppearanceTransition:YES animated:animated];
    [self.containerView insertSubview:viewController.view belowSubview:self.transitionMaskView];
    
    viewController.view.frame = self.containerView.frame;

    UIViewController *fromViewController = self.topViewController;
    [fromViewController beginAppearanceTransition:NO animated:animated];
    
    self.contextTransitioning.animating = YES;
    self.contextTransitioning.fromViewController = fromViewController;
    self.contextTransitioning.toViewController = viewController;
    self.contextTransitioning.operation = UINavigationControllerOperationPop;

    [self popAnimation:animated
    fromViewController:fromViewController
      toViewController:viewController];
}

#pragma mark - ZLViewControllerAnimatedTransitioning

- (void)pushAnimation:(BOOL)animated
   fromViewController:(UIViewController *)fromViewController
     toViewController:(UIViewController *)toViewController {
    [self addShadow:toViewController];

    [self startPushAnimationWithFromViewController:fromViewController
                                  toViewController:toViewController
                                          animated:animated
                                    withCompletion:^(BOOL isCancel) {
                                        [self.contextTransitioning finishInteractiveTransition];
                                    }];
}

- (void)popAnimation:(BOOL)animated
  fromViewController:(UIViewController *)fromViewController
    toViewController:(UIViewController *)toViewController {
    [self addShadow:toViewController];

    [self startPopAnimationWithFromViewController:fromViewController
                                 toViewController:toViewController
                                         animated:animated
                                   withCompletion:^(BOOL isCancel) {
                                       if (isCancel) {
                                           [self.contextTransitioning cancelInteractiveTransition];
                                       } else {
                                           [self.contextTransitioning finishInteractiveTransition];
                                           [self releaseViewControllersAfterPopToViewController:toViewController];
                                       }
                                   }];
}


#pragma mark - Animation

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    void (^callback)() = [anim valueForKeyPath:@"callback"];
    if (callback) {
        callback(!flag);
        callback = nil;
    }
}

- (void)startPushAnimationWithFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController animated:(BOOL)animated withCompletion:(void (^)(BOOL isCancel))callback {
    if (!animated) {
        callback(NO);
        callback = nil;
        return;
    }
    CABasicAnimation *toAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
    toAnimation.fromValue = @(CGRectGetWidth(self.view.frame) * 1.5);
    toAnimation.toValue = @(CGRectGetWidth(self.view.frame) * 0.5);
    toAnimation.duration = [self.contextTransitioning transitionDuration];
    toAnimation.fillMode = kCAFillModeBoth;
    toAnimation.removedOnCompletion = YES;
    toAnimation.delegate = self;
    [toAnimation setValue:callback forKeyPath:@"callback"];
    [toViewController.view.layer addAnimation:toAnimation forKey:@"zhoulee.transition.to"];

    CABasicAnimation *fromAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
    fromAnimation.fromValue = @(CGRectGetWidth(self.view.frame) * .5);
    fromAnimation.toValue = @0;
    fromAnimation.fillMode = kCAFillModeBoth;
    fromAnimation.duration = [self.contextTransitioning transitionDuration];
    fromAnimation.removedOnCompletion = YES;
    [fromViewController.view.layer addAnimation:fromAnimation forKey:@"zhoulee.transition.from"];
}

- (void)startPopAnimationWithFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController animated:(BOOL)animated withCompletion:(void (^)(BOOL isCancel))callback {
    if (!animated) {
        callback(NO);
        callback = nil;
        return;
    }

    CABasicAnimation *fromAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
    fromAnimation.fromValue = @(CGRectGetWidth(self.view.frame) * 0.5);
    fromAnimation.toValue = @(CGRectGetWidth(self.view.frame) * 1.5);
    fromAnimation.duration = [self.contextTransitioning transitionDuration];
    fromAnimation.fillMode = kCAFillModeBoth;
    fromAnimation.removedOnCompletion = NO;
    fromAnimation.delegate = self;
    [fromAnimation setValue:callback forKeyPath:@"callback"];
    [fromViewController.view.layer addAnimation:fromAnimation forKey:@"zhoulee.transition.from"];

    CABasicAnimation *toAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
    toAnimation.fromValue = @(0);
    toAnimation.toValue = @(CGRectGetWidth(self.view.frame) * 0.5);
    toAnimation.fillMode = kCAFillModeBoth;
    toAnimation.duration = [self.contextTransitioning transitionDuration];
    toAnimation.removedOnCompletion = YES;
    [toViewController.view.layer addAnimation:toAnimation forKey:@"zhoulee.transition.to"];
}

#pragma mark -

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.topViewController.preferredStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden {
    return self.topViewController.prefersStatusBarHidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationNone;
}

#pragma mark - Private Method

- (void)addNavigationBarIfNeededByViewController:(UIViewController *)viewController {
    if (viewController.zl_navigationBarHidden) return;

    [viewController.zl_navigationBar pushNavigationItem:viewController.zl_navigationItem animated:NO];
    [viewController.view addSubview:viewController.zl_navigationBar];

    [viewController.view setNeedsLayout];

    if (viewController.zl_automaticallyAdjustsScrollViewInsets) {
        [viewController.view.subviews enumerateObjectsUsingBlock:^(__kindof UIView *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if (CGRectGetMinY(obj.frame) == 0) {
                UIScrollView *scrollView;
                if ([obj isKindOfClass:[UIScrollView class]] && ![obj isMemberOfClass:[UITextView class]]) {
                    scrollView = obj;
                }
                if ([obj isKindOfClass:[UIWebView class]]) {
                    scrollView = ((UIWebView *) obj).scrollView;
                }
                if (scrollView) {
                    UIEdgeInsets insets = scrollView.contentInset;
                    insets.top += 64.0f;
                    scrollView.contentInset = insets;
                    scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(64, 0, 0, 0);
                    scrollView.contentOffset = CGPointMake(0, -64);
                }

            }
        }];
    }
}

- (UIViewController *)rootViewController {
    return [self.viewControllerStack firstObject];
}

- (UIViewController *)previousViewController {
    unsigned long count = self.viewControllerStack.count;
    if (count > 1) {
        return self.viewControllerStack[count - 2];
    } else {
        return nil;
    }
}

- (NSUInteger)indexForViewControllerInStack:(UIViewController *)viewController {
    return [self.viewControllerStack indexOfObject:viewController];
}

- (void)releaseViewControllersAfterPopToViewController:(UIViewController *)viewController {
    NSUInteger index = [self.viewControllerStack indexOfObject:viewController];
    NSUInteger count = self.viewControllerStack.count;

    for (NSUInteger i = index + 1; i < count; i++) {
        UIViewController *destroyViewController = self.viewControllerStack[i];
        [destroyViewController removeFromParentViewController];
    }
    [self.viewControllerStack removeObjectsInRange:NSMakeRange(index + 1, count - index - 1)];
}

- (void)addShadow:(UIViewController *)viewController {
    CALayer *shadowLayer = viewController.view.layer;
    shadowLayer.shadowOffset = CGSizeMake(-3, 0);
    shadowLayer.shadowRadius = 2.0;
    shadowLayer.shadowColor = [UIColor blackColor].CGColor;
    shadowLayer.shadowOpacity = 0.1;
    shadowLayer.shadowPath = [UIBezierPath bezierPathWithRect:viewController.view.bounds].CGPath;
}

#pragma mark - Interactive Gesture Recognizer

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer {
    if (self.contextTransitioning.animating) return NO;
    if (self.viewControllerStack.count == 1) return NO;
    CGPoint translate = [gestureRecognizer translationInView:self.view];
    if (translate.x < 0) return NO;
    return YES;
}

- (void)handleNavigationTransition:(UIPanGestureRecognizer *)recognizer {
    CGFloat translate = [recognizer translationInView:self.view].x;
    ZLFloat percent = (ZLFloat) translate / (ZLFloat) CGRectGetWidth(self.view.bounds);

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self popViewControllerAnimated:YES];
        [self.percentDrivenInteractiveTransition startInteractiveTransition];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        [self.percentDrivenInteractiveTransition updateInteractiveTransition:percent];
    } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        CGFloat velocity = [recognizer velocityInView:self.view].x;
        if (percent > 0.2 || velocity > 100.0f) {
            [self.percentDrivenInteractiveTransition finishInteractiveTransition];
        } else {
            [self.percentDrivenInteractiveTransition cancelInteractiveTransition:percent];
        }
    }
}

@end

#pragma mark -

@implementation UIViewController (ZLNavigationController)
@dynamic zl_navigationController, zl_automaticallyAdjustsScrollViewInsets;

- (ZLNavigationController *)zl_navigationController {
    UIViewController *parentViewController = self.parentViewController;
    while (parentViewController && ![parentViewController isKindOfClass:[ZLNavigationController class]]) {
        parentViewController = parentViewController.parentViewController;
    }
    return (ZLNavigationController *) parentViewController;
}

- (BOOL)zl_navigationBarHidden {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setZl_navigationBarHidden:(BOOL)zl_navigationBarHidden {
    objc_setAssociatedObject(self, @selector(zl_navigationBarHidden), @(zl_navigationBarHidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)zl_automaticallyAdjustsScrollViewInsets {
    id obj = objc_getAssociatedObject(self, _cmd);
    if (obj == nil) {
        return YES;
    }
    return [obj boolValue];
}

- (void)setZl_automaticallyAdjustsScrollViewInsets:(BOOL)zl_automaticallyAdjustsScrollViewInsets {
    objc_setAssociatedObject(self, @selector(zl_automaticallyAdjustsScrollViewInsets), @(zl_automaticallyAdjustsScrollViewInsets), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UIViewController (ZLNavigationBar)
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
        item = [[UINavigationItem alloc] init];
        if (self.title) {
            item.title = self.title;
        }
        objc_setAssociatedObject(self, _cmd, item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return item;
}

- (void)setZl_navigationItem:(UINavigationItem *)zl_navigationItem {
    objc_setAssociatedObject(self, @selector(zl_navigationItem), zl_navigationItem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@interface ZLPercentDrivenInteractiveTransition ()
@property(nonatomic, assign) CFTimeInterval pausedTime;
@property(nonatomic, assign) ZLFloat completeSpeed;
@end

@implementation ZLPercentDrivenInteractiveTransition
- (void)startInteractiveTransition {
    [self pauseLayer:[self.contextTransitioning containerView].layer];
}

- (void)updateInteractiveTransition:(ZLFloat)percentComplete {
    [self.contextTransitioning containerView].layer.timeOffset = self.pausedTime + [self.contextTransitioning transitionDuration] * percentComplete;
}

- (void)finishInteractiveTransition {
    [self resumeLayer:[self.contextTransitioning containerView].layer];
}

- (void)cancelInteractiveTransition:(ZLFloat)percentComplete {
    CALayer *containerLayer = [self.contextTransitioning containerView].layer;
    containerLayer.fillMode = kCAFillModeBoth;

    self.completeSpeed = percentComplete > 0.0 ? percentComplete : 0.0;

    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleDisplayLink)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (kZLNavigationControllerPushPopTransitionDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [displayLink invalidate];
        containerLayer.timeOffset = 0;
        for (CALayer *subLayer in containerLayer.sublayers) {
            [subLayer removeAllAnimations];
        }
        containerLayer.speed = 1.0;
    });
}

- (void)handleDisplayLink {
    ZLFloat timeOffset = [self.contextTransitioning containerView].layer.timeOffset;
    timeOffset -= self.completeSpeed / 30.0;
    [self.contextTransitioning containerView].layer.timeOffset = timeOffset;
}

#pragma mark - Handle Layer

- (void)pauseLayer:(CALayer *)layer {
    CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
    layer.speed = 0.0;
    layer.timeOffset = pausedTime;
    self.pausedTime = pausedTime;
}

- (void)resumeLayer:(CALayer *)layer {
    CFTimeInterval pausedTime = [layer timeOffset];
    layer.speed = 1.0;
    layer.timeOffset = 0.0;
    layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    layer.beginTime = timeSincePause;
}

@end
