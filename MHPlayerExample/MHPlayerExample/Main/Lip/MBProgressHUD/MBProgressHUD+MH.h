//
//
//  MBProgressHUD+MH.m
//
//  Created by apple on 16/5/10.
//  Copyright © 2016年 Mike_He. All rights reserved.
//

#import "MBProgressHUD.h"

@interface MBProgressHUD (MH)

+ (void)mh_show:(NSString *)text icon:(NSString *)icon view:(UIView *)view;

+ (void)mh_showSuccess:(NSString *)success toView:(UIView *)view;
+ (void)mh_showError:(NSString *)error toView:(UIView *)view;

+ (MBProgressHUD *)mh_showMessage:(NSString *)message toView:(UIView *)view;
+ (MBProgressHUD *)mh_showMessage:(NSString *)message;

+ (void)mh_showSuccess:(NSString *)success;
+ (void)mh_showError:(NSString *)error;



+ (void)mh_hideHUDForView:(UIView *)view;
+ (void)mh_hideHUD;


// 显示在上方
+ (void)mh_showHint:(NSString *)hint;
// 显示在下方
+ (void)mh_showBottomHint:(NSString *)hint;
// 从默认(mh_showHint:)显示的位置再往上(下)yOffset
+ (void)mh_showHint:(NSString *)hint yOffset:(float)yOffset;

@end
