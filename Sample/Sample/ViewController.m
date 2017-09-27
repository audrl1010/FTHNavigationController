//
//  ViewController.m
//  Sample
//
//  Created by 技术部 on 2017/9/26.
//  Copyright © 2017年 For the Horde. All rights reserved.
//

#import "ViewController.h"
@import FTHNavigationController;

@interface ViewController ()
@property (nonatomic, assign) int index;
@end

@implementation ViewController

- (void)dealloc {
    NSLog(@"release index: %d",self.index);
}

- (instancetype)init {
    self = [super init];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [NSString stringWithFormat:@"TEST %d", self.index];

    self.view.backgroundColor = [UIColor whiteColor];
    {
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        for (int i = 0; i < 10; i++) {
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds) / 5.0 * i, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) / 5.0)];
            view.backgroundColor = [UIColor colorWithRed:arc4random_uniform(255) / 255.0 green:arc4random_uniform(255) / 255.0 blue:arc4random_uniform(255) / 255.0 alpha:1];
            [scrollView addSubview:view];
        }
        scrollView.contentSize = CGSizeMake(0, CGRectGetHeight(self.view.bounds) * 2);

        [self.view addSubview:scrollView];
    }
    {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        [button setTitle:@"push" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(pushAction) forControlEvents:UIControlEventTouchUpInside];
        button.backgroundColor = [UIColor colorWithRed:arc4random_uniform(255) / 255.0 green:arc4random_uniform(255) / 255.0 blue:arc4random_uniform(255) / 255.0 alpha:1];
        button.center = CGPointMake(CGRectGetMidX(self.view.bounds), 200);

        [self.view addSubview:button];
    }
    {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        [button setTitle:@"pop" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(popAction) forControlEvents:UIControlEventTouchUpInside];
        button.backgroundColor = [UIColor colorWithRed:arc4random_uniform(255) / 255.0 green:arc4random_uniform(255) / 255.0 blue:arc4random_uniform(255) / 255.0 alpha:1];
        button.center = CGPointMake(CGRectGetMidX(self.view.bounds), 400);

        [self.view addSubview:button];
    }
    {
        self.fth_navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(didSelectedRightBarButtonItem)], [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(didSelectedRightBarButtonItem)]];
    }

    //    {
    //        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 100)];
    //        view.backgroundColor = [UIColor colorWithRed:arc4random_uniform(255)/255.0 green:arc4random_uniform(255)/255.0 blue:arc4random_uniform(255)/255.0 alpha:1];
    //        [self.view addSubview:view];
    //    }
    [self.fth_navigationBar setBarTintColor:[UIColor colorWithRed:arc4random_uniform(255) / 255.0 green:arc4random_uniform(255) / 255.0 blue:arc4random_uniform(255) / 255.0 alpha:1]];
}

- (void)didSelectedRightBarButtonItem {
    //    NSLog(@"%s",__FUNCTION__);
}

- (void)willMoveToParentViewController:(nullable UIViewController *)parent {
    [super willMoveToParentViewController:parent];
    NSLog(@"willMoveToParentViewController: %@, index: %d",parent,self.index);
}

- (void)didMoveToParentViewController:(nullable UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    NSLog(@"didMoveToParentViewController: %@, index: %d",parent,self.index);
}

- (void)pushAction {
    ViewController *vc = [[ViewController alloc] init];
    vc.index = self.index + 1;


    if (self.index == 2) {
        ViewController *vc = [[ViewController alloc] init];
        FTHNavigationController *nav = [[FTHNavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:nav animated:YES completion:nil];
    }else{
        [self.fth_navigationController pushViewController:vc animated:YES];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (self.index % 2) {
        return UIStatusBarStyleDefault;
    }
    return UIStatusBarStyleLightContent;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationNone;
}

- (void)popAction {
    [self.fth_navigationController popViewControllerAnimated:YES];
}


- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"%s index: %d\n", __FUNCTION__, self.index);
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"%s index: %d\n", __FUNCTION__, self.index);
}

- (void)viewWillDisappear:(BOOL)animated {
    NSLog(@"%s index: %d\n", __FUNCTION__, self.index);
}

- (void)viewDidDisappear:(BOOL)animated {
    NSLog(@"%s index: %d\n", __FUNCTION__, self.index);
}


@end
