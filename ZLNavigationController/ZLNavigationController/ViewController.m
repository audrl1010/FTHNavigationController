//
//  ViewController.m
//  ZLNavigationController
//
//  Created by 技术部 on 16/7/4.
//  Copyright © 2016年 JIEMIAN. All rights reserved.
//

#import "ViewController.h"
#import "ZLNavigationController.h"
@interface ViewController ()


@end

@implementation ViewController
- (void)dealloc {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [NSString stringWithFormat:@"TEST %d",self.index];

    self.view.backgroundColor = [UIColor whiteColor];
    {
        UIScrollView * scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        for (int i = 0; i < 10; i ++) {
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds)/5.0 * i, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)/5.0)];
            view.backgroundColor = [UIColor colorWithRed:arc4random_uniform(255)/255.0 green:arc4random_uniform(255)/255.0 blue:arc4random_uniform(255)/255.0 alpha:1];
            [scrollView addSubview:view];
        }
        scrollView.contentSize = CGSizeMake(0, CGRectGetHeight(self.view.bounds) * 2);
        
        [self.view addSubview:scrollView];
    }
    {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        [button setTitle:@"push" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(pushAction) forControlEvents:UIControlEventTouchUpInside];
        button.backgroundColor = [UIColor colorWithRed:arc4random_uniform(255)/255.0 green:arc4random_uniform(255)/255.0 blue:arc4random_uniform(255)/255.0 alpha:1];
        button.center = CGPointMake(CGRectGetMidX(self.view.bounds), 200);
        
        [self.view addSubview:button];
    }
    {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        [button setTitle:@"pop" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(popAction) forControlEvents:UIControlEventTouchUpInside];
        button.backgroundColor = [UIColor colorWithRed:arc4random_uniform(255)/255.0 green:arc4random_uniform(255)/255.0 blue:arc4random_uniform(255)/255.0 alpha:1];
        button.center = CGPointMake(CGRectGetMidX(self.view.bounds), 400);
        
        [self.view addSubview:button];
    }
    {
        self.zl_navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(didSelectedRightBarButtonItem)],[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(didSelectedRightBarButtonItem)]];
    }

//    {
//        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 100)];
//        view.backgroundColor = [UIColor colorWithRed:arc4random_uniform(255)/255.0 green:arc4random_uniform(255)/255.0 blue:arc4random_uniform(255)/255.0 alpha:1];
//        [self.view addSubview:view];
//    }
    [self.zl_navigationBar setBarTintColor:[UIColor colorWithRed:arc4random_uniform(255)/255.0 green:arc4random_uniform(255)/255.0 blue:arc4random_uniform(255)/255.0 alpha:1]];
}

- (void)didSelectedRightBarButtonItem {
//    NSLog(@"%s",__FUNCTION__);
}

- (void)pushAction {
    ViewController *vc = [[ViewController alloc] init];
    vc.index = self.index + 1;
    [self.zl_navigationController pushViewController:vc animated:NO];
//    [self presentViewController:vc animated:YES completion:nil];
//    [self.zl_navigationController presentViewController:vc animated:YES completion:nil];
}

- (void)popAction {
    [self.zl_navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"invoke viewWillAppear  %d\n",self.index);
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"invoke viewDidAppear  %d\n",self.index);
}

- (void)viewWillDisappear:(BOOL)animated {
    NSLog(@"invoke viewWillDisappear  %d\n",self.index);
}

- (void)viewDidDisappear:(BOOL)animated {
    NSLog(@"invoke viewDidDisappear  %d\n",self.index);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
