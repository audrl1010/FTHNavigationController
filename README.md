# FTHNavigationController
更好用的导航控制器  
- [x] 全屏手势返回
- [x] 适配iOS 11
- [x] 动画更流畅顺滑
# Usage
1.UINavigationController  

  完全移植UINavigationController的API到FTHNavigationController, 用法完全一样 
  
```
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)showViewController:(UIViewController *)viewController sender:(nullable id)sender;
- (nullable UIViewController *)popViewControllerAnimated:(BOOL)animated;
- (nullable NSArray<__kindof UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated;
```  

2.UINavigationBar  
  导航栏的层级移动到了UIViewController中，独立的控制器，更方便的自定义.  
  
3.UINavigationItem
  
# Installation
```
pod 'FTHNavigationController'
```  
# License
MIT License
