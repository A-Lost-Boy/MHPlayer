//
//  Const.h
//  MKHNetworking
//
//  Created by apple on 16/3/8.
//  Copyright © 2016年 Mike. All rights reserved.
//

#ifndef Constant_h
#define Constant_h

/**
 *  比较实用的宏定义
 */

//
#define WS(weakSelf)  __weak __typeof(&*self)weakSelf = self;



//适配AF
#ifndef TARGET_OS_IOS

#define TARGET_OS_IOS TARGET_OS_IPHONE

#endif

#ifndef TARGET_OS_WATCH

#define TARGET_OS_WATCH 0

#endif


//1.日记输出宏
#ifdef DEBUG // 调试状态, 打开LOG功能
#define MyLog(...) NSLog(__VA_ARGS__)
#else // 发布状态, 关闭LOG功能
#define MyLog(...)
#endif




//2.严谨的判断
#define IS_IPAD   (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_RETINA ([[UIScreen mainScreen] scale] >= 2.0)

#define SCREEN_WIDTH      ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT     ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define SCREEN_MIN_LENGTH (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))

#define IS_IPHONE_4_OR_LESS (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)
#define IS_IPHONE_5         (IS_IPHONE && SCREEN_MAX_LENGTH == 568.0)
#define IS_IPHONE_6         (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
#define IS_IPHONE_6P        (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)
/****/


//3.颜色
#define YBColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]

//4.颜色+透明度
#define YBAlphaColor(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:a]


//4.随机色
#define YBRandomColor YBColor(arc4random_uniform(256), arc4random_uniform(256), arc4random_uniform(256))
//5.根据rgbValue获取值
#define YBColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

//6.是否为iOS7+
#define kIOS7 ([[UIDevice currentDevice].systemVersion doubleValue] >= 7.0)

//7.是否为4inch
#define kFourInch ([UIScreen mainScreen].bounds.size.height == 568.0)


// 4.取出滚动条 重写这个方法的目的。去掉父类默认的操作：显示滚动条
#define kHideScroll - (void)viewDidAppear:(BOOL)animated { }

// 5.屏幕总尺寸
#define kMainScreenHeight [UIScreen mainScreen].bounds.size.height
#define kMainScreenWidth  [UIScreen mainScreen].bounds.size.width

// 6.IOS版本
#define kIOSVersion [[[UIDevice currentDevice] systemVersion] floatValue]

//7.销毁打印
#define kDealloc MyLog(@"=========%@彻底销毁了========",[self class])

//11.打印失败信息
#define kLogError MyLog(@"网络请求失败：===%@\n===%@",[self class] ,error.description)

//9.是否为空对象
#define kObjectIsNil(__object)     ((nil == __object) || [__object isKindOfClass:[NSNull class]])

//10.字符串为空
#define kStringIsEmpty(__string)    (__string.length == 0)

//11.字符串部位nil也不为空
#define kStringIsNotNilAndNotEmpty(__string)   ((!kObjectIsNil(__string)) && (!kStringIsEmpty(__string)))

//13.数组为空
#define kArrayIsEmpty(__array) ((__array==nil) || ([__array isKindOfClass:[NSNull class]]) || (array.count==0))

//12.取消ios7以后下移
#define kDisabledAutomaticallyAdjustsScrollViewInsets \
if (kIOSVersion>=7.0) {\
self.automaticallyAdjustsScrollViewInsets = NO;\
}

//13.AppCaches
#define kCachesDirectory [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]

//14.系统放大倍数
#define kScale [[UIScreen mainScreen] scale]

//15.App DocumentDirectory
#define kDocumentDirectory [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) lastObject]


#import "MHConstant.h"
#import "MBProgressHUD+MH.h"
#import "Colours.h"

#endif /* Constant_h */
