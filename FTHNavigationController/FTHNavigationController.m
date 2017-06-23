//
//  FTHNavigationController.m
//  FTHNavigationController
//
//  Created by Patrick Chow on 16/7/4.
//  Copyright © 2016-2017年 ZhouLee. All rights reserved.
//

#import "FTHNavigationController.h"
#import <objc/runtime.h>

static CGFloat kFTHNavigationBarHeight = 64.0f;
static CGFloat kFTHNavigationControllerPushPopTransitionDuration = .275f;

@interface ZLTouchFilterView : UIView
@end

@implementation ZLTouchFilterView
- (nullable UIView *)hitTest:(CGPoint)point withEvent:(nullable UIEvent *)event {
    return self;
}
@end

@interface FTHContextTransitioning : NSObject <FTHViewControllerContextTransitioning>
@property(nonatomic, assign) UINavigationControllerOperation operation;
@property(nonatomic, assign) BOOL transitionWasCancelled;
@property(nonatomic, weak) FTHNavigationController *navigationController;
@property(nonatomic, assign) BOOL animated;
@end

@implementation FTHContextTransitioning
@synthesize containerView = _containerView;
@synthesize fromViewController = _fromViewController;
@synthesize toViewController = _toViewController;
@synthesize animating = _animating;

- (CGFloat)transitionDuration {
    return kFTHNavigationControllerPushPopTransitionDuration;
}

- (void)completeTransition:(BOOL)didComplete {
    if (didComplete) {
        switch (self.operation) {
            case UINavigationControllerOperationPop:
                [self completePopOperation];
                break;
            case UINavigationControllerOperationPush:
                [self completePushOperation];
                break;
            case UINavigationControllerOperationNone:break;
        }
    } else {
        [self cancelPopOperation];
    }
    self.animating = NO;
}

- (void)completePushOperation {
    [self.fromView removeFromSuperview];
    [self.toViewController didMoveToParentViewController:self.navigationController];

    [self.toViewController endAppearanceTransition];
    [self.fromViewController endAppearanceTransition];
}

- (void)completePopOperation {
    [self.fromView removeFromSuperview];
    [self.fromViewController removeFromParentViewController];

    [self.fromViewController endAppearanceTransition];
    [self.toViewController endAppearanceTransition];

    [self.containerView bringSubviewToFront:self.toView];
}

- (void)cancelPopOperation {
    [self.toViewController beginAppearanceTransition:NO animated:self.animated];
    [self.fromViewController beginAppearanceTransition:YES animated:self.animated];

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


@interface FTHNavigationController () <UIGestureRecognizerDelegate,
        CAAnimationDelegate,
        FTHViewControllerAnimatedTransitioning>

@property(nonatomic, strong) NSMutableArray<__kindof UIViewController *> *viewControllerStack;

@property(nonatomic, strong) ZLTouchFilterView *transitionMaskView;

@property(nonatomic, strong, readwrite) UIPanGestureRecognizer *interactiveGestureRecognizer;

@property(nonatomic, strong, readwrite) FTHPercentDrivenInteractiveTransition *percentDrivenInteractiveTransition;

@property(nonatomic, strong) FTHContextTransitioning *contextTransitioning;


@end


@implementation FTHNavigationController

- (void)dealloc {
    self.viewControllerStack = nil;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _viewControllerStack = [@[rootViewController] mutableCopy];
        _contextTransitioning = [[FTHContextTransitioning alloc] init];
        _contextTransitioning.navigationController = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.contextTransitioning.containerView = self.view;

    self.interactiveGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(handleNavigationTransition:)];
    self.interactiveGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:self.interactiveGestureRecognizer];

    self.transitionMaskView = [[ZLTouchFilterView alloc] initWithFrame:self.view.bounds];
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

- (NSArray<__kindof UIViewController *> *)viewControllers {
    return [NSArray arrayWithArray:self.viewControllerStack];
}

- (UIViewController *)topViewController {
    return self.viewControllerStack.lastObject;
}

- (FTHPercentDrivenInteractiveTransition *)percentDrivenInteractiveTransition {
    if (!_percentDrivenInteractiveTransition) {
        _percentDrivenInteractiveTransition = [[FTHPercentDrivenInteractiveTransition alloc] init];
        _percentDrivenInteractiveTransition.contextTransitioning = self.contextTransitioning;
    }
    return _percentDrivenInteractiveTransition;
}

#pragma mark Push & Pop Method

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {

    NSAssert(viewController, @"Must specify a view controller");
    if (!viewController) return;
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
    self.contextTransitioning.animated = animated;
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

    NSAssert(viewController, @"Must specify a view controller");
    if (!viewController) return;
    if (self.contextTransitioning.animating) return;

    [viewController beginAppearanceTransition:YES animated:animated];
    [self.containerView insertSubview:viewController.view belowSubview:self.transitionMaskView];

    viewController.view.frame = self.containerView.frame;

    UIViewController *fromViewController = self.topViewController;
    [fromViewController beginAppearanceTransition:NO animated:animated];

    self.contextTransitioning.animating = YES;
    self.contextTransitioning.animated = animated;
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
                                    withCompletion:^(BOOL isFinish) {
                                        [self.contextTransitioning completeTransition:isFinish];
                                        [self setNeedsStatusBarAppearanceUpdate];
                                    }];
}

- (void)popAnimation:(BOOL)animated
  fromViewController:(UIViewController *)fromViewController
    toViewController:(UIViewController *)toViewController {
    [self addShadow:toViewController];

    [self startPopAnimationWithFromViewController:fromViewController
                                 toViewController:toViewController
                                         animated:animated
                                   withCompletion:^(BOOL isFinish) {
                                       [self.contextTransitioning completeTransition:isFinish];
                                       if (isFinish) {
                                           [self releaseViewControllersAfterPopToViewController:toViewController];
                                       }
                                       [self setNeedsStatusBarAppearanceUpdate];
                                   }];
}


#pragma mark - Animation

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    void (^callback)(BOOL isFinish) = [anim valueForKeyPath:@"callback"];
    if (callback) {
        callback(flag);
    }
}

- (void)startPushAnimationWithFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController animated:(BOOL)animated withCompletion:(void (^)(BOOL isFinish))callback {
    if (!animated) {
        callback(YES);
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

- (void)startPopAnimationWithFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController animated:(BOOL)animated withCompletion:(void (^)(BOOL isFinish))callback {
    if (!animated) {
        callback(YES);
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
    if (viewController.fth_navigationBarHidden) return;

    [viewController.fth_navigationBar pushNavigationItem:viewController.fth_navigationItem animated:NO];
    [viewController.view addSubview:viewController.fth_navigationBar];

    [viewController.view setNeedsLayout];

    if (viewController.fth_automaticallyAdjustsScrollViewInsets) {
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
                    CGPoint offset = scrollView.contentOffset;
                    insets.top += 64.0f;
                    offset.y -= 64.0f;
                    scrollView.contentInset = insets;
                    scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(64, 0, 0, 0);
                    scrollView.contentOffset = offset;
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
    return translate.x > 0.0f;
}

- (void)handleNavigationTransition:(UIPanGestureRecognizer *)recognizer {
    CGFloat translate = [recognizer translationInView:self.view].x;
    FTHFloat percent = (FTHFloat) translate / (FTHFloat) CGRectGetWidth(self.view.bounds);

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

@implementation UIViewController (FTHNavigationController)
//@dynamic fth_navigationController, fth_automaticallyAdjustsScrollViewInsets;

- (FTHNavigationController *)fth_navigationController {
    UIViewController *parentViewController = self.parentViewController;
    while (parentViewController && ![parentViewController isKindOfClass:[FTHNavigationController class]]) {
        parentViewController = parentViewController.parentViewController;
    }
    return (FTHNavigationController *) parentViewController;
}

- (BOOL)fth_automaticallyAdjustsScrollViewInsets {
    id obj = objc_getAssociatedObject(self, _cmd);
    if (obj == nil) {
        return YES;
    }
    return [obj boolValue];
}

- (void)setFth_automaticallyAdjustsScrollViewInsets:(BOOL)fth_automaticallyAdjustsScrollViewInsets {
    objc_setAssociatedObject(self, @selector(fth_automaticallyAdjustsScrollViewInsets), @(fth_automaticallyAdjustsScrollViewInsets), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UIViewController (FTHNavigationBar)
- (UINavigationBar *)fth_navigationBar {
    UINavigationBar *navigationBar = objc_getAssociatedObject(self, _cmd);
    if (!navigationBar) {
        navigationBar = [[UINavigationBar alloc] initWithFrame:
                CGRectMake(0, 0, CGRectGetWidth(self.view.frame), kFTHNavigationBarHeight)];
        navigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        objc_setAssociatedObject(self, _cmd, navigationBar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return navigationBar;
}

- (void)setFth_navigationBar:(UINavigationBar *)fth_navigationBar {
    objc_setAssociatedObject(self, @selector(fth_navigationBar), fth_navigationBar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fth_navigationBarHidden {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFth_navigationBarHidden:(BOOL)fth_navigationBarHidden {
    objc_setAssociatedObject(self, @selector(fth_navigationBarHidden), @(fth_navigationBarHidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UIViewController (ZLNavigationItem)

- (UINavigationItem *)fth_navigationItem {
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

- (void)setFth_navigationItem:(UINavigationItem *)FTH_navigationItem {
    objc_setAssociatedObject(self, @selector(fth_navigationItem), FTH_navigationItem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@interface FTHPercentDrivenInteractiveTransition ()
@property(nonatomic, assign) CFTimeInterval pausedTime;
@property(nonatomic, assign) FTHFloat completeSpeed;
@end

@implementation FTHPercentDrivenInteractiveTransition
- (void)startInteractiveTransition {
    [self pauseLayer:[self.contextTransitioning containerView].layer];
}

- (void)updateInteractiveTransition:(FTHFloat)percentComplete {
    [self.contextTransitioning containerView].layer.timeOffset = self.pausedTime + [self.contextTransitioning transitionDuration] * percentComplete;
}

- (void)finishInteractiveTransition {
    [self resumeLayer:[self.contextTransitioning containerView].layer];
}

- (void)cancelInteractiveTransition:(FTHFloat)percentComplete {
    CALayer *containerLayer = [self.contextTransitioning containerView].layer;
    containerLayer.fillMode = kCAFillModeBoth;

    self.completeSpeed = percentComplete > 0.0 ? percentComplete : 0.0;

    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleDisplayLink)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (kFTHNavigationControllerPushPopTransitionDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [displayLink invalidate];
        containerLayer.timeOffset = 0;
        for (CALayer *subLayer in containerLayer.sublayers) {
            [subLayer removeAllAnimations];
        }
        containerLayer.speed = 1.0;
    });
}

- (void)handleDisplayLink {
    CFTimeInterval timeOffset = [self.contextTransitioning containerView].layer.timeOffset;
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
