//
//  FTHNavigationController.m
//  FTHNavigationController
//
//  Created by Patrick Chow on 2017/9/26.
//  Copyright © 2017年 For the Horde. All rights reserved.
//

#import "FTHNavigationController.h"
#import <objc/runtime.h>

#define FTHNodeAssert(condition, desc, ...) NSAssert(condition, desc, ##__VA_ARGS__)
#define FTHAssertNotSupported() FTHNodeAssert(NO, nil, @"This method is not supported by class %@", [self class]);

static NSString *const FTHTransitionContextParentViewControllerKey = @"kFTHTransitionContextParentViewControllerKey";

typedef void (^FTHAnimationDidStopCallback)(CAAnimation *anim, BOOL finished);

typedef void (^FTHContextTransitioningDidCompleteTransition)(BOOL transitionWasCancelled);

@interface FTHViewControllerContextTransitioning : NSObject <UIViewControllerContextTransitioning> {
    CFTimeInterval _pausedTime;
    CFTimeInterval _duration;
    CFTimeInterval _completeSpeed;
}

@property(nonatomic, strong) UIView *containerView;
@property(nonatomic, assign, getter=isAnimated) BOOL animated;
@property(nonatomic, assign, getter=isInteractive) BOOL interactive;
@property(nonatomic, assign) BOOL transitionWasCancelled;
@property(nonatomic, copy) NSDictionary *viewControllerDict;
@property(nonatomic, assign) UINavigationControllerOperation operation;
@property(nonatomic, copy) FTHContextTransitioningDidCompleteTransition didCompleteTransition;
@end

@implementation FTHViewControllerContextTransitioning
- (UIModalPresentationStyle)presentationStyle {
    return UIModalPresentationCustom;
}

- (void)updateInteractiveTransition:(CGFloat)percentComplete {
    if (percentComplete == 0) {
        [self pauseLayer:_containerView.layer];
        _duration = [_containerView.subviews[0].layer animationForKey:@"ForTheHorde.transition.to"].duration;
    } else {
        _containerView.layer.timeOffset = _pausedTime + _duration * percentComplete;
    }
}

- (void)finishInteractiveTransition {
    [self resumeLayer:_containerView.layer];
}

- (void)cancelInteractiveTransition {
    CALayer *containerLayer = _containerView.layer;
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleDisplayLink)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    _completeSpeed = containerLayer.timeOffset - _pausedTime;
    // 12 times
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [displayLink invalidate];
        
        for (UIView *subView in _containerView.subviews) {
            [subView.layer removeAllAnimations];
        }
        
        containerLayer.speed = 1.0;
        containerLayer.timeOffset = 0;
    });
}

- (void)handleDisplayLink {
    CFTimeInterval timeOffset = _containerView.layer.timeOffset;
    timeOffset -= (_completeSpeed / 12);
    _containerView.layer.timeOffset = timeOffset;
}

- (void)pauseInteractiveTransition {}

- (void)completeTransition:(BOOL)didComplete {
    UIViewController *fromViewController = [self viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *parentViewController = [self viewControllerForKey:FTHTransitionContextParentViewControllerKey];
    UIViewController *toViewController = [self viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (didComplete) {
        if (fromViewController.view) {
            [fromViewController.view removeFromSuperview];
        }
        // handle push operation
        if (self.operation == UINavigationControllerOperationPush) {
            [fromViewController endAppearanceTransition];
            [toViewController endAppearanceTransition];
            [fromViewController didMoveToParentViewController:parentViewController];
        }
        // handle pop operation
        if (self.operation == UINavigationControllerOperationPop) {
            [fromViewController endAppearanceTransition];
            [toViewController endAppearanceTransition];
            [fromViewController removeFromParentViewController];
        }
    } else {
        [toViewController beginAppearanceTransition:NO animated:self.animated];
        [fromViewController beginAppearanceTransition:YES animated:self.animated];
        [toViewController.view removeFromSuperview];
        [toViewController endAppearanceTransition];
        [fromViewController endAppearanceTransition];
    }
    // update status bar appearance
    [parentViewController setNeedsStatusBarAppearanceUpdate];
    // release viewControllerDict
    self.viewControllerDict = nil;
    
    if (self.didCompleteTransition) {
        self.didCompleteTransition(didComplete);
        self.didCompleteTransition = nil;
    }
}

- (nullable __kindof UIViewController *)viewControllerForKey:(UITransitionContextViewControllerKey)key {
    return _viewControllerDict[key];
}

- (nullable __kindof UIView *)viewForKey:(UITransitionContextViewKey)key {
    if ([key isEqualToString:UITransitionContextFromViewKey]) {
        return [self viewControllerForKey:UITransitionContextFromViewControllerKey].view;
    } else {
        return [self viewControllerForKey:UITransitionContextToViewControllerKey].view;
    }
}

- (CGAffineTransform)targetTransform {
    return CGAffineTransformIdentity;
}

- (CGRect)initialFrameForViewController:(UIViewController *)vc {
    return vc.parentViewController.view.bounds;
}

- (CGRect)finalFrameForViewController:(UIViewController *)vc {
    return vc.parentViewController.view.bounds;
}

- (void)pauseLayer:(CALayer *)layer {
    CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
    layer.speed = 0.0;
    layer.timeOffset = pausedTime;
    _pausedTime = pausedTime;
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

@interface FTHViewControllerAnimatedTransitioning : NSObject <UIViewControllerAnimatedTransitioning, CAAnimationDelegate> {
    UINavigationControllerOperation _operation;
}

- (instancetype)initWithOperation:(UINavigationControllerOperation)operation;
@end

@implementation FTHViewControllerAnimatedTransitioning
- (instancetype)initWithOperation:(UINavigationControllerOperation)operation {
    self = [super init];
    if (self) {
        _operation = operation;
    }
    return self;
}

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.275f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    if (_operation == UINavigationControllerOperationPush) {
        [self _pushAnimateTransition:transitionContext];
    } else {
        [self _popAnimateTransition:transitionContext];
    }
}

- (void)_pushAnimateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    
    toView.frame = [transitionContext finalFrameForViewController:[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey]];
    
    CABasicAnimation *toAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
    toAnimation.delegate = self;
    toAnimation.duration = [self transitionDuration:transitionContext];
    toAnimation.fillMode = kCAFillModeBoth;
    toAnimation.fromValue = @(toView.layer.position.x + CGRectGetWidth(toView.bounds));
    toAnimation.removedOnCompletion = YES;
    toAnimation.toValue = @(toView.layer.position.x);
    
    FTHAnimationDidStopCallback callback = ^(CAAnimation *animation, BOOL finished) {
        [transitionContext completeTransition:finished];
    };
    [toAnimation setValue:callback forUndefinedKey:@"callback"];
    
    [toView.layer addAnimation:toAnimation forKey:@"ForTheHorde.transition.to"];
    
    CABasicAnimation *fromAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
    fromAnimation.duration = [self transitionDuration:transitionContext];
    fromAnimation.fillMode = kCAFillModeBoth;
    fromAnimation.fromValue = @(fromView.layer.position.x);
    fromAnimation.removedOnCompletion = YES;
    fromAnimation.toValue = @(fromView.layer.position.x - CGRectGetMidX(fromView.bounds));
    [fromView.layer addAnimation:fromAnimation forKey:@"ForTheHorde.transition.from"];
}

- (void)_popAnimateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    
    toView.frame = [transitionContext finalFrameForViewController:[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey]];
    
    CABasicAnimation *fromAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
    fromAnimation.delegate = self;
    fromAnimation.duration = [self transitionDuration:transitionContext];
    fromAnimation.fillMode = kCAFillModeBoth;
    fromAnimation.fromValue = @(fromView.layer.position.x);
    fromAnimation.removedOnCompletion = NO;
    fromAnimation.toValue = @(fromView.layer.position.x + CGRectGetWidth(fromView.bounds));
    
    FTHAnimationDidStopCallback callback = ^(CAAnimation *animation, BOOL finished) {
        [transitionContext completeTransition:finished];
    };
    [fromAnimation setValue:callback forUndefinedKey:@"callback"];
    
    [fromView.layer addAnimation:fromAnimation forKey:@"ForTheHorde.transition.from"];
    
    CABasicAnimation *toAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
    toAnimation.duration = [self transitionDuration:transitionContext];
    toAnimation.fillMode = kCAFillModeBoth;
    toAnimation.fromValue = @(toView.layer.position.x - CGRectGetMidX(toView.bounds));
    toAnimation.removedOnCompletion = YES;
    toAnimation.toValue = @(toView.layer.position.x);
    
    [toView.layer addAnimation:toAnimation forKey:@"ForTheHorde.transition.to"];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    FTHAnimationDidStopCallback callback = [anim valueForUndefinedKey:@"callback"];
    if (callback) {
        callback(anim, flag);
    }
}
@end

@interface FTHPercentDrivenInteractiveTransition : NSObject <UIViewControllerInteractiveTransitioning> {
    id <UIViewControllerAnimatedTransitioning> _animator;
    id <UIViewControllerContextTransitioning> _transitionContext;
}

- (instancetype)initWithAnimator:(id <UIViewControllerAnimatedTransitioning>)animator;

- (void)pauseInteractiveTransition NS_AVAILABLE_IOS(10_0);

- (void)updateInteractiveTransition:(CGFloat)percentComplete;

- (void)finishInteractiveTransition;

- (void)cancelInteractiveTransition;
@end

@implementation FTHPercentDrivenInteractiveTransition
- (instancetype)initWithAnimator:(id <UIViewControllerAnimatedTransitioning>)animator {
    self = [super init];
    if (self) {
        _animator = animator;
    }
    return self;
}

- (void)startInteractiveTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    _transitionContext = transitionContext;
    
    [_animator animateTransition:transitionContext];
}

- (void)updateInteractiveTransition:(CGFloat)percentComplete {
    [_transitionContext updateInteractiveTransition:percentComplete];
}

- (void)finishInteractiveTransition {
    [_transitionContext finishInteractiveTransition];
}

- (void)pauseInteractiveTransition {
    [_transitionContext pauseInteractiveTransition];
}

- (void)cancelInteractiveTransition {
    [_transitionContext cancelInteractiveTransition];
}
@end

@interface FTHNavigationController () <UIGestureRecognizerDelegate> {
    UIPanGestureRecognizer *_interactiveGestureRecognizer;
    FTHPercentDrivenInteractiveTransition *_percentDrivenInteractiveTransition;
    
    struct {
        unsigned int willShowViewController:1;
        unsigned int didShowViewController:1;
        unsigned int animationControllerForOperation:1;
        unsigned int interactionControllerForAnimationController:1;
    } _delegateFlags;
    
#if DEBUG
    NSPointerArray *_viewControllerStack;
#endif
}
@end

@implementation FTHNavigationController
- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
#if DEBUG
        _viewControllerStack = [NSPointerArray weakObjectsPointerArray];
        [_viewControllerStack addPointer:(__bridge void *) rootViewController];
#endif
        [self addChildViewController:rootViewController];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIViewController *topViewController = self.topViewController;
    UIView *topView = topViewController.view;
    
    topView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.view addSubview:topView];
    [topViewController didMoveToParentViewController:self];
    [self addNavigationBarIfNeededByViewController:topViewController];
    
    _interactiveGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handelPanGesture:)];
    _interactiveGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:_interactiveGestureRecognizer];
}

#pragma mark -
- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.topViewController.preferredStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden {
    return self.topViewController.prefersStatusBarHidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return self.topViewController.preferredStatusBarUpdateAnimation;
}

#pragma mark Getter & Setter
- (NSArray<__kindof UIViewController *> *)viewControllers {
    return self.childViewControllers;
}

- (UIViewController *)topViewController {
    return self.childViewControllers.lastObject;
}

- (UIPanGestureRecognizer *)interactiveGestureRecognizer {
    return _interactiveGestureRecognizer;
}

- (void)setDelegate:(id <FTHNavigationControllerDelegate>)delegate {
    if (delegate) {
        _delegate = delegate;
        
        _delegateFlags.animationControllerForOperation = [_delegate respondsToSelector:@selector(navigationController:animationControllerForOperation:fromViewController:toViewController:)];
        _delegateFlags.willShowViewController = [_delegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)];
        _delegateFlags.didShowViewController = [_delegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)];
        _delegateFlags.interactionControllerForAnimationController = [_delegate respondsToSelector:@selector(navigationController:interactionControllerForAnimationController:)];
    } else {
        _delegate = nil;
        memset(&_delegateFlags, 0, sizeof(_delegateFlags));
    }
}

#pragma mark Public Method

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    UIViewController *fromViewController = self.topViewController;
    UIViewController *toViewController = viewController;
    
#if DEBUG
    [_viewControllerStack addPointer:(__bridge void *) toViewController];
#endif
    
    [self addChildViewController:toViewController];
    UIView *toView = toViewController.view;
    toView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [toViewController beginAppearanceTransition:YES animated:animated];
    [fromViewController beginAppearanceTransition:NO animated:animated];
    
    [self.view addSubview:toView];
    [self addNavigationBarIfNeededByViewController:toViewController];
    
    [self beginPerformAnimationOperation:UINavigationControllerOperationPush fromViewController:fromViewController toViewController:toViewController animated:animated interactive:NO];
}

- (void)showViewController:(UIViewController *)viewController sender:(nullable id)sender {
    [self pushViewController:viewController animated:YES];
}

- (nullable UIViewController *)popViewControllerAnimated:(BOOL)animated {
    return [self _popViewControllerAnimated:animated interactive:NO];
}

- (nullable NSArray<__kindof UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated {
    NSArray<__kindof UIViewController *> *viewControllers = [self.viewControllers subarrayWithRange:NSMakeRange(1, self.viewControllers.count - 2)];
    for (NSUInteger i = 0; i < viewControllers.count; i ++) {
        UIViewController *viewController = viewControllers[i];
        [viewController removeFromParentViewController];
    }
    [self _popViewControllerAnimated:animated interactive:NO];
    return viewControllers;
}

#pragma mark Private Method

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index {
    return self.viewControllers[index];
}

- (nullable UIViewController *)viewControllerAbove:(UIViewController *)viewController {
    unsigned long count = self.viewControllers.count;
    if (count > 1) {
        return self.viewControllers[count - 2];
    } else {
        return nil;
    }
}

- (void)setViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers {
    
};

- (void)addNavigationBarIfNeededByViewController:(UIViewController *)viewController {
    if (viewController.fth_navigationBarHidden) return;
    
    UINavigationBar *navigationBar = viewController.fth_navigationBar;
    UINavigationItem *navigationItem = viewController.fth_navigationItem;
    [navigationBar pushNavigationItem:navigationItem animated:NO];
    
    [viewController.view addSubview:navigationBar];
    [self constraintNavigationBar:navigationBar onViewController:viewController];
    
    if (viewController.fth_automaticallyAdjustsScrollViewInsets) {
        UIScrollView *firstView = viewController.view.subviews.firstObject;
        if ([firstView isKindOfClass:[UIScrollView class]]) {
            UIEdgeInsets contentInset = firstView.contentInset;
            CGPoint contentOffset = firstView.contentOffset;
            
            CGFloat constant = 0;
            if (@available(iOS 11.0, *)) {
                constant = navigationBar.intrinsicContentSize.height;
            } else {
                constant = navigationBar.intrinsicContentSize.height + CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                    if (self.presentingViewController && self.modalPresentationStyle == UIModalPresentationFormSheet) {
                        constant = navigationBar.intrinsicContentSize.height;
                    }
                }
            }
            contentInset.top += constant;
            contentOffset.y -= constant;
            [firstView setScrollIndicatorInsets:contentInset];
            [firstView setContentInset:contentInset];
            [firstView setContentOffset:contentOffset animated:NO];
        }
    }
}

- (void)constraintNavigationBar:(UINavigationBar *)navigationBar onViewController:(UIViewController *)viewController {
    navigationBar.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *constraint;
    if (@available(iOS 11.0, *)) {
        UILayoutGuide *safeAreaLayoutGuide = viewController.view.safeAreaLayoutGuide;
        NSLayoutConstraint *a = [navigationBar.widthAnchor constraintEqualToAnchor:viewController.view.widthAnchor];
        NSLayoutConstraint *b = [navigationBar.centerXAnchor constraintEqualToAnchor:viewController.view.centerXAnchor constant:0];
        NSLayoutConstraint *c = [navigationBar.topAnchor constraintEqualToAnchor:safeAreaLayoutGuide.topAnchor constant:0];
        
        constraint = @[a, b, c];
    } else {
        NSLayoutConstraint *a = [NSLayoutConstraint constraintWithItem:navigationBar attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:viewController.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
        NSLayoutConstraint *b = [NSLayoutConstraint constraintWithItem:navigationBar attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:viewController.view attribute:NSLayoutAttributeRight multiplier:1 constant:0];
        CGFloat constant = 0;
        constant = CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            if (self.presentingViewController && self.modalPresentationStyle == UIModalPresentationFormSheet) {
                constant = 0;
            }
        }
        NSLayoutConstraint *c = [NSLayoutConstraint constraintWithItem:navigationBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:viewController.view attribute:NSLayoutAttributeTop multiplier:1 constant:constant];
        constraint = @[a, b, c];
    }
    [NSLayoutConstraint activateConstraints:constraint];
}

- (nullable UIViewController *)_popViewControllerAnimated:(BOOL)animated interactive:(BOOL)interactive {
    UIViewController *toViewController = [self viewControllerAbove:self.topViewController];
    if (!toViewController) {
        return toViewController;
    }
    UIViewController *fromViewController = self.topViewController;
    
    [fromViewController willMoveToParentViewController:nil];
    
    [toViewController beginAppearanceTransition:YES animated:animated];
    [fromViewController beginAppearanceTransition:NO animated:animated];
    
    [self.view insertSubview:toViewController.view belowSubview:fromViewController.view];
    
    [self beginPerformAnimationOperation:UINavigationControllerOperationPop fromViewController:fromViewController toViewController:toViewController animated:animated interactive:interactive];
    
    return toViewController;
}

- (void)beginPerformAnimationOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController animated:(BOOL)animated interactive:(BOOL)interactive {
    // wrapper transition context
    FTHViewControllerContextTransitioning *transitionContext = [[FTHViewControllerContextTransitioning alloc] init];
    transitionContext.animated = animated;
    transitionContext.containerView = self.view;
    transitionContext.interactive = interactive;
    transitionContext.operation = operation;
    transitionContext.transitionWasCancelled = NO;
    transitionContext.viewControllerDict = @{
                                             UITransitionContextToViewControllerKey: toViewController,
                                             UITransitionContextFromViewControllerKey: fromViewController,
                                             FTHTransitionContextParentViewControllerKey: self
                                             };
    
    if (_delegateFlags.willShowViewController) {
        [self.delegate navigationController:self willShowViewController:toViewController animated:animated];
    }
    
    if (_delegateFlags.didShowViewController) {
        transitionContext.didCompleteTransition = ^(BOOL transitionWasCancelled) {
            if (!transitionWasCancelled) {
                [self.delegate navigationController:self didShowViewController:toViewController animated:animated];
            }
        };
    }
    
    if (_delegateFlags.animationControllerForOperation) {
        id <UIViewControllerAnimatedTransitioning> animator = [self.delegate navigationController:self
                                                                  animationControllerForOperation:operation
                                                                               fromViewController:fromViewController
                                                                                 toViewController:toViewController];
        
        if (_delegateFlags.interactionControllerForAnimationController && interactive) {
            id <UIViewControllerInteractiveTransitioning> interactiveAnimator = [self.delegate navigationController:self interactionControllerForAnimationController:animator];
            FTHPercentDrivenInteractiveTransition *driven = [[FTHPercentDrivenInteractiveTransition alloc] initWithAnimator:nil];
            [interactiveAnimator startInteractiveTransition:transitionContext];
        
            _percentDrivenInteractiveTransition = driven;
        } else {
            [animator animateTransition:transitionContext];
        }
    } else {
        if (interactive) {
            FTHViewControllerAnimatedTransitioning *animator = [[FTHViewControllerAnimatedTransitioning alloc] initWithOperation:operation];
            FTHPercentDrivenInteractiveTransition *interactiveAnimator = [[FTHPercentDrivenInteractiveTransition alloc] initWithAnimator:animator];
            [interactiveAnimator startInteractiveTransition:transitionContext];
            
            _percentDrivenInteractiveTransition = interactiveAnimator;
        } else {
            FTHViewControllerAnimatedTransitioning *animator = [[FTHViewControllerAnimatedTransitioning alloc] initWithOperation:operation];
            [animator animateTransition:transitionContext];
        }
    }
}

#pragma mark -
- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer {
    if (self.viewControllers.count == 1) return NO;
    CGPoint translate = [gestureRecognizer translationInView:self.view];
    if (translate.x <= 0) {
        return NO;
    }
    return fabs(translate.x) > fabs(translate.y);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
}

- (void)handelPanGesture:(UIPanGestureRecognizer *)recognizer {
    CGFloat translate = [recognizer translationInView:self.view].x;
    CGFloat percent = translate / CGRectGetWidth(self.view.bounds);
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            [self _popViewControllerAnimated:YES interactive:YES];
            [_percentDrivenInteractiveTransition updateInteractiveTransition:0];
            break;
        case UIGestureRecognizerStateChanged:
            [_percentDrivenInteractiveTransition updateInteractiveTransition:percent];
            break;
        case UIGestureRecognizerStateEnded:
            if (percent > 0.15f) {
                [_percentDrivenInteractiveTransition finishInteractiveTransition];
            } else {
                [_percentDrivenInteractiveTransition cancelInteractiveTransition];
            }
            break;
        default:
            break;
    }
}

#pragma mark Override Method

- (void)addChildViewController:(UIViewController *)childController {
    [super addChildViewController:childController];
    
#if DEBUG
    if (![_viewControllerStack.allObjects containsObject:childController]) {
        FTHAssertNotSupported()
    }
#endif
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end

@implementation UIViewController (FTHNavigationController)
- (nullable FTHNavigationController *)fth_navigationController {
    UIViewController *parentViewController = self.parentViewController;
    while (parentViewController && ![parentViewController isKindOfClass:[FTHNavigationController class]]) {
        parentViewController = parentViewController.parentViewController;
    }
    return (FTHNavigationController *) parentViewController;
}

- (BOOL)fth_automaticallyAdjustsScrollViewInsets {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFth_automaticallyAdjustsScrollViewInsets:(BOOL)fth_automaticallyAdjustsScrollViewInsets {
    objc_setAssociatedObject(self, @selector(fth_automaticallyAdjustsScrollViewInsets), @(fth_automaticallyAdjustsScrollViewInsets), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

@interface FTHNavigationBarDelegateProxy: NSObject <UINavigationBarDelegate> {
    struct {
        unsigned int shouldPushItem:1;
        unsigned int didPushItem:1;
        unsigned int shouldPopItem:1;
        unsigned int didPopItem:1;
        unsigned int positionForBar:1;
    } _delegateFlags;
}
@property(nonatomic, weak) id<UINavigationBarDelegate> delegate;
@end
@implementation FTHNavigationBarDelegateProxy
- (void)setDelegate:(id <UINavigationBarDelegate>)delegate {
    if (delegate) {
        _delegate = delegate;
        
        _delegateFlags.shouldPopItem = [_delegate respondsToSelector:@selector(navigationBar:shouldPopItem:)];
        _delegateFlags.didPopItem = [_delegate respondsToSelector:@selector(navigationBar:didPopItem:)];
        _delegateFlags.didPushItem = [_delegate respondsToSelector:@selector(navigationBar:didPushItem:)];
        _delegateFlags.shouldPushItem = [_delegate respondsToSelector:@selector(navigationBar:shouldPushItem:)];
        _delegateFlags.positionForBar = [_delegate respondsToSelector:@selector(positionForBar:)];
    } else {
        _delegate = nil;
        memset(&_delegateFlags, 0, sizeof(_delegateFlags));
    }
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPushItem:(UINavigationItem *)item {
    if (_delegateFlags.shouldPushItem) {
        return [_delegate navigationBar:navigationBar shouldPushItem:item];
    }
    return YES;
}

- (void)navigationBar:(UINavigationBar *)navigationBar didPushItem:(UINavigationItem *)item {
    if (_delegateFlags.didPushItem) {
        [_delegate navigationBar:navigationBar didPushItem:item];
    }
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
    if (_delegateFlags.shouldPopItem) {
        [_delegate navigationBar:navigationBar shouldPopItem:item];
    }
    return YES;
}

- (void)navigationBar:(UINavigationBar *)navigationBar didPopItem:(UINavigationItem *)item {
    if (_delegateFlags.didPopItem) {
        [_delegate navigationBar:navigationBar didPopItem:item];
    }
}

- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar {
    if (_delegateFlags.positionForBar) {
        return [_delegate positionForBar:bar];
    }
    return UIBarPositionTopAttached;
}
@end

@interface FTHNavigationBarInternal : UINavigationBar <UINavigationBarDelegate>
@end

@implementation FTHNavigationBarInternal
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.delegate = self;
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    if (@available(iOS 11.0, *)) {
        if (self.prefersLargeTitles) {
            UIFont *largeTitleFont = self.largeTitleTextAttributes[NSFontAttributeName];
            if (largeTitleFont) {
                return CGSizeMake(0, 44 + round(largeTitleFont.lineHeight));
            }
            return CGSizeMake(0, 96);
        }
    }
    return CGSizeMake(0, 44);
}

- (void)setDelegate:(id <UINavigationBarDelegate>)delegate {
    if (delegate) {
        FTHNavigationBarDelegateProxy *delegateProxy = [[FTHNavigationBarDelegateProxy alloc] init];
        delegateProxy.delegate = delegate;
        
        objc_setAssociatedObject(self, _cmd, delegateProxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        [super setDelegate:delegateProxy];
    } else {
        [super setDelegate:nil];
        objc_setAssociatedObject(self, _cmd, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (UIBarPosition)barPosition {
    return UIBarPositionTopAttached;
}
@end

@implementation UIViewController (FTHNavigationBar)
- (UINavigationBar *)fth_navigationBar {
    UINavigationBar *navigationBar = objc_getAssociatedObject(self, _cmd);
    if (!navigationBar) {
        // iOS 11
        //        if ([NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion) {11, 0, 0}]) {
        //            navigationBar = [[FTHNavigationBarInternal alloc]
        //                    initWithFrame:CGRectZero];
        //        } else {
        //            navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectZero];
        //        }
        navigationBar = [[FTHNavigationBarInternal alloc]
                         initWithFrame:CGRectZero];
        objc_setAssociatedObject(self, _cmd, navigationBar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return navigationBar;
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
        item = [[UINavigationItem alloc] initWithTitle:self.title];
        
        objc_setAssociatedObject(self, _cmd, item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return item;
}

- (void)setFth_navigationItem:(UINavigationItem *)FTH_navigationItem {
    objc_setAssociatedObject(self, @selector(fth_navigationItem), FTH_navigationItem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end
