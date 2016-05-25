//
//
//  MBProgressHUD+MH.m
//
//  Created by apple on 16/5/10.
//  Copyright © 2016年 Mike_He. All rights reserved.
//

#import "MBProgressHUD+MH.h"
//导航栏高度
static CGFloat const MHNavigationBarHeight = 64;
//tabBar高度
static CGFloat const MHTabBarHeight = 49;

@implementation MBProgressHUD (MH)
#pragma mark 显示信息
+ (void)mh_show:(NSString *)text icon:(NSString *)icon view:(UIView *)view
{
    if (view == nil)
    {
        view = [[UIApplication sharedApplication].delegate window];
        if (!view) {
            view = [[[UIApplication sharedApplication] windows] lastObject];
        }
    }
    // 快速显示一个提示信息
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.opacity = 0.45;
    hud.labelText = text;
    // 设置图片
    hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"MBProgressHUD.bundle/%@", icon]]];
    // 再设置模式
    hud.mode = MBProgressHUDModeCustomView;
    
    // 隐藏时候从父控件中移除
    hud.removeFromSuperViewOnHide = YES;
    
    // 1秒之后再消失
    [hud hide:YES afterDelay:1.0f];
}

#pragma mark 显示错误信息
+ (void)mh_showError:(NSString *)error toView:(UIView *)view
{
    [self mh_show:error icon:@"error.png" view:view];
}

+ (void)mh_showSuccess:(NSString *)success toView:(UIView *)view
{
    [self mh_show:success icon:@"success.png" view:view];
}

#pragma mark 显示一些信息
+ (MBProgressHUD *)mh_showMessage:(NSString *)message toView:(UIView *)view
{
    BOOL isNil = NO;
    if (view == nil)
    {
        isNil = YES;
        view = [[UIApplication sharedApplication].delegate window];
        if (!view) {
            view = [[[UIApplication sharedApplication] windows] lastObject];
        }
    }
    // 快速显示一个提示信息
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.opacity = 0.45;
    hud.labelText = message;
    // 隐藏时候从父控件中移除
    hud.removeFromSuperViewOnHide = YES;
    // YES代表需要蒙版效果
//    hud.color = [UIColor black25PercentColor];
    hud.dimBackground = isNil;
    return hud;
}

+ (void)mh_showSuccess:(NSString *)success
{
    [self mh_showSuccess:success toView:nil];
}

+ (void)mh_showError:(NSString *)error
{
    [self mh_showError:error toView:nil];
}

+ (MBProgressHUD *)mh_showMessage:(NSString *)message
{
    return [self mh_showMessage:message toView:nil];
}

+ (void)mh_hideHUDForView:(UIView *)view
{
    if (view == nil)
    {
        view = [[UIApplication sharedApplication].delegate window];
        if (!view) {
            view = [[[UIApplication sharedApplication] windows] lastObject];
        }
    }
    [self hideHUDForView:view animated:YES];
}

+ (void)mh_hideHUD
{
    [self mh_hideHUDForView:nil];
}





//MKH  这个默认显示上方
+ (void)mh_showHint:(NSString *)hint
{
    [self mh_hideHUD];
    //显示提示信息
    UIView *view = [[UIApplication sharedApplication].delegate window];
    [self mh_showHint:hint yOffset:(-(view.frame.size.height*0.5-MHNavigationBarHeight-MHNavigationBarHeight*0.5))];
}

// 从默认(mh_showHint:)显示的位置再往上(下)yOffset
+ (void)mh_showHint:(NSString *)hint yOffset:(float)yOffset
{
    [self mh_hideHUD];
    //显示提示信息
    UIView *view = [[UIApplication sharedApplication].delegate window];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.userInteractionEnabled = NO;
    // Configure for text only and offset down
    hud.mode = MBProgressHUDModeText;
    hud.labelText = hint;
    hud.opacity = 0.45;
    hud.margin = 10.f;
    hud.yOffset = yOffset;
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:2.0f];
}


//显示在下方
+ (void)mh_showBottomHint:(NSString *)hint
{
    [self mh_hideHUD];
    //显示提示信息
    UIView *view = [[UIApplication sharedApplication].delegate window];
    [self mh_showHint:hint yOffset:((view.frame.size.height*0.5-MHTabBarHeight-MHNavigationBarHeight*0.5))];
}


@end
