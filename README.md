# MHPlayer
一款基于AVPlayer开发的视频播放器。支持左滑右滑，改变视频播放进度；支持左边屏幕上滑下滑改变播放音量，右边屏幕上滑下滑改变屏幕亮度。

## 特性
* 支持横、竖屏切换
* 支持本地视频、网络视频播放
* 右侧1/2位置上下滑动调节屏幕亮度（模拟器调不了亮度，请在真机调试）
* 左侧1/2位置上下滑动调节音量（模拟器调不了音量，请在真机调试）
* 左右滑动调节播放进度

## 要求
- iOS 7+
- Xcode 6.0+

## 使用
#### 初始化播放器
```objc
- (instancetype) initWithVideoPlayerFrame:(CGRect)frame videoUrlString:(NSString *)videoUrlString;
+ (instancetype) videoPlayerWithFrame:(CGRect)frame videoUrlString:(NSString *)videoUrlString;
+ (instancetype) videoPlayer;
```

#### 播放
```objc
-(void)play;
`
```

#### 暂停
```objc
-(void)pause;
```

#### 销毁 <必须要手动调用>
```objc
-(void)destroy;
```

## 期待
* 如果在使用过程中遇到BUG，希望你能Issues我，谢谢（或者尝试下载最新的框架代码看看BUG修复没有）
* 如果在使用过程中发现功能不够用，希望你能Issues我，我非常想为这个框架增加更多好用的功能，谢谢
* 如果你想为MHPlayer输出代码，请拼命Pull Requests我
