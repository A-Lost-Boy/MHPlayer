//
//  MHPlayer.m
//  MHPlayer
//
//  Created by apple on 16/4/25.
//  Copyright © 2016年 Mike_He. All rights reserved.
//


/**
 *              Masonry使用小结:
 1.
 在Masonry中，and,with都没有具体操作，仅仅是为了提高程序的可读性
 make.left.and.top.mas_equalTo(20);
 等价于
 make.left.top.mas_equalTo(20);
 
 equalTo与mas_equalTo
 如果约束条件是数值或者结构体等类型，可以使用mas_equalTo进行包装。
 我一般将数值类型的约束用mas_equalTo，而相对于某个控件，或者某个控件的某个约束，我会使用equalTo，如：
 make.size.mas_equalTo(CGSizeMake(100, 100));
 make.center.equalTo(weakSelf.view);
 
 1.可以看到 mas_equalTo只是对其参数进行了一个BOX操作(装箱) MASBoxValue
 所支持的类型 除了NSNumber支持的那些数值类型之外 就只支持CGPoint CGSize UIEdgeInsets
 即:数值 或者结构体


 2.
 可以给控件添加left/right/top/bottom/size/height/width/insert约束；
 库提供了三个方法
 ****  mas_makeConstraints    添加约束
 ****  mas_updateConstraints  修改约束
 ****  mas_remakeConstraints  清除以前约束并添加新约束；
 可以通过view.mas_bottom获得view的某个约束；
 在约束的block中，使用make来给当前控件添加约束。
 
 
 3.
 - (NSArray *)mas_makeConstraints:(void(^)(MASConstraintMaker *make))block;
 - (NSArray *)mas_updateConstraints:(void(^)(MASConstraintMaker *make))block;
 - (NSArray *)mas_remakeConstraints:(void(^)(MASConstraintMaker *make))block;

 mas_makeConstraints   只负责新增约束 Autolayout不能同时存在两条针对于同一对象的约束 否则会报错
 mas_updateConstraints 针对上面的情况 会更新在block中出现的约束 不会导致出现两个相同约束的情况
 mas_remakeConstraints 则会清除之前的所有约束 仅保留最新的约束

 
 4.
 with and  程序中不起任何作用
 - (MASConstraint *)with
 {
 return self;
 }
 - (MASConstraint *)and 
 {
 return self;
 }
 
 
 5.
 
 */






#import "MHPlayer.h"
#import <AVFoundation/AVFoundation.h>


/**
 *  发送单击视频的通知
 */
NSString * const MHPlayerSingleTapNotification = @"MHPlayerSingleTapNotification";
/**
 *  发送双击视频的通知
 */
NSString * const MHPlayerDoubleTapNotification = @"MHPlayerDoubleTapNotification";
/**
 *  发送点击关闭视频的通知
 */
NSString * const MHPlayerClosedNotification = @"MHPlayerClosedNotification";
/**
 *  发送播放完毕的通知
 */
NSString * const MHPlayerDidPlayToEndTimeNotification = @"MHPlayerDidPlayToEndTimeNotification";
/**
 *  播放状态改变
 */
NSString * const MHPlayerStateChangedNotification    = @"MHPlayerStateChangedNotification";
/**
 *  播放进度更新的通知
 */
NSString * const MHPlayerProgressChangedNotification = @"MHPlayerProgressChangedNotification";
/**
 *  全屏按钮被点击的通知
 */
NSString * const MHPlayerFullScreenButtonClickedNotification = @"MHPlayerFullScreenButtonClickedNotification";

/**
 *  5s 隐藏bottomView 和 closeBtn
 *
 */
static CGFloat const MHPlayerAutoDismissStatusViewDuration = 5.0f;




#define MHVideoSrcName(file) [@"MHPlayer.bundle" stringByAppendingPathComponent:file]
#define MHVideoFrameworkSrcName(file) [@"Frameworks/MHPlayer.framework/MHPlayer.bundle" stringByAppendingPathComponent:file]
#define kHalfWidth  (self.frame.size.width * 0.5f)
#define kHalfHeight (self.frame.size.height * 0.5f)

//1.日记输出宏
#ifdef DEBUG // 调试状态, 打开LOG功能
#define MHLog(...) NSLog(__VA_ARGS__)
#else // 发布状态, 关闭LOG功能
#define MHLog(...)
#endif


//打印方法
#define MHLogFunc MHLog(@"%s", __func__)

/**
 *  视频播放状态
 */
static void *PlayViewStatusObservationContext = &PlayViewStatusObservationContext;
/**
 *  视频缓存
 */
static void *PlayViewLoadedTimeRangesObservationContext = &PlayViewLoadedTimeRangesObservationContext;
/**
 *  视频缓存 失效PlaybackBufferEmpty
 */
static void *PlayViewPlaybackBufferEmptyObservationContext = &PlayViewPlaybackBufferEmptyObservationContext;
/**
 *  playbackLikelyToKeepUp
 */
static void *PlayViewPlaybackLikelyToKeepUpObservationContext = &PlayViewPlaybackLikelyToKeepUpObservationContext;


@interface MHPlayer ()


/**
 *  播放器player
 */
@property (nonatomic ,strong) AVPlayer *player;

/**
 *  时间格式
 */
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

/**
 *  playerLayer,可以修改frame
 */
@property(nonatomic, strong)  AVPlayerLayer *playerLayer;
/**
 *  当前播放的item
 */
@property (nonatomic, strong) AVPlayerItem *currentPlayerItem;
/**
 *  原始的父类
 */
@property (nonatomic , weak)   UIView *originalSuperView;
/**
 *  原始尺寸
 */
@property (nonatomic , assign) CGRect originalFrame;
/**
 *  底部栏
 */
@property (nonatomic , strong) UIView *bottomView;
/**
 *  时间轴
 */
@property (nonatomic , weak) UILabel *timeLabel ;
/**
 *  全屏按钮
 */
@property (nonatomic , weak) UIButton *fullScreenBtn ;
/**
 * 关闭按钮
 *
 */
@property (nonatomic , weak) UIButton *closeBtn ;

/**
 *  暂停和播放按钮
 */
@property (nonatomic , weak) UIButton *playOrPauseBtn ;

/**
 *  进度条
 */
@property (nonatomic , weak) UISlider *playSlider;

/**
 *  缓存进度条
 */
@property (nonatomic , weak) UIProgressView *buffProgressView;
/**
 *  监听每分每秒的观察者
 */
@property (nonatomic , strong) id periodicTimeObserver;

/**
 *自动隐藏bottomview
 */
@property (nonatomic , strong) NSTimer *autoDismissTimer;

/**
 *  保存播放滑块value值
 */
@property (nonatomic , strong) NSMutableArray *sliderValues;
/**
 *  保存左右滑动播放的value值  每次取最后面的值 即：lastObject
 */
@property (nonatomic , strong) NSMutableArray *moveValues;
/**
 *  是否手动滑动 playerSlider
 */
@property (nonatomic , assign , getter= isMovePlayerSlider) BOOL movePlayerSlider;
/**
 *  是否左右滑动 屏幕
 */
@property (nonatomic , assign , getter= isMoveLeftOrRight) BOOL moveLeftOrRight;

/**
 *  起始点
 */
@property (nonatomic,assign)  CGPoint firstPoint;
/**
 * 移动的点
 */
@property (nonatomic,assign)  CGPoint secondPoint;
/**
 *  原始点
 */
@property (nonatomic, assign) CGPoint originalPoint;

/**
 *  系统的控制音量键
 */
@property (nonatomic , weak) UISlider *systemSlider;

@property (nonatomic , assign) MHPlayerState  state;
@property (nonatomic , assign) CGFloat        duration;//视频总时间
@property (nonatomic , assign) CGFloat        current;//当前播放时间
@property (nonatomic , assign) BOOL           isPauseByUser; //是否被用户暂停
@property (nonatomic , assign) BOOL           stopWhenAppDidEnterBackground;// default is YES

/**
 *  声音和亮度提示
 */
@property (nonatomic , strong) UILabel *voiceOrLightLabel;
/**
 *  进度提示
 */
@property (nonatomic , strong) UILabel *progressLabel;



@end

@implementation MHPlayer
#pragma mark - ==============================公有方法==============================
#pragma mark - 初始化播放器
//初始化 播放器
+ (instancetype)videoPlayer
{
    return [[self alloc] init];
}
//初始化 播放器
+ (instancetype)videoPlayerWithFrame:(CGRect)frame videoUrlString:(NSString *)videoUrlString
{
    return [[self alloc] initWithVideoPlayerFrame:frame videoUrlString:videoUrlString];
}
//初始化 播放器
- (instancetype)initWithVideoPlayerFrame:(CGRect)frame videoUrlString:(NSString *)videoUrlString
{
    self = [self initWithFrame:frame];
    if (self)
    {
        //1设置视频Url 内部会重写setter方法
        self.videoUrlString = videoUrlString;
    }
    return self;
}
//初始化 播放器
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        /**
         *  YES:subview随父视图大小而自动适应大小
         *  NO :subview不随父视图大小而自动适应大小
         */
        [self setAutoresizesSubviews:NO];
        
        //1.基础配置
        [self setUpBasicData];
        
        //2.设置bottomView
        [self setupBottomViewWithSubviews];
        
        //3.设置自己view
        [self setupSubViews];
        
        //4.添加手势
        [self setupGestureRecognizer];
        
    }
    return self;
}


#pragma mark - 重写setter方法
- (void)setVideoUrlString:(NSString *)videoUrlString
{
    //相同的视频链接  就不做处理 就是是当前的播放视频  则return
    if ([_videoUrlString isEqualToString:videoUrlString]) return;
    
    _videoUrlString = [videoUrlString copy];

    
    //1.show HUD
    MBProgressHUD *progressHUD = [MBProgressHUD mh_showMessage:nil toView:self];
    [progressHUD mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
    }];
    
    if (self.currentPlayerItem) {
        //已经有视频资源 需要切换视频资源
        [self replaceCurrentPlayerItemWithUrlString:videoUrlString];
        
    }else{
        //暂无视频资源
        //1.设置自己layer
        [self setupSubLayersWithUrlString:videoUrlString];
    }
    
    //2.将bottomview放到最上层
    [self bringSelfSomeSubviewsToFront];
}

#pragma mark - getter
- (CGFloat)progress
{
    if (self.duration > 0)
    {
        return self.current / self.duration;
    }
    
    return 0;
}

#pragma mark - 视频功能按钮的action操作
/**
 *  播放
 */
-(void)play
{
    if (!self.currentPlayerItem) return;  //没有视频资源
    
    self.isPauseByUser = NO;
    if (self.player.rate !=1.f) [self.player play];
    
    self.playOrPauseBtn.selected = NO;

}
/**
 *  暂停
 */
-(void)pause
{
    if (!self.currentPlayerItem) return;  //没有视频资源
    
    
    self.isPauseByUser = YES;
    self.state = MHPlayerStatePause;
    if (self.player.rate !=0.f) [self.player pause];
    self.playOrPauseBtn.selected = YES;
}

- (void)stop
{

}


- (void)destroy
{
    //释放掉 定时器
    [self invalidTimer];
}

#pragma mark - ==============================私有方法=============================
#pragma mark - 设置缓冲值
- (void)updateBuffProgressValue:(CGFloat)timeValue
{
    [self.buffProgressView setProgress:timeValue animated:YES];
}

#pragma mark - 设置播放滑块的值
- (void) updatePlaySliderValue:(CGFloat)timeValue
{
    [self.playSlider setValue:timeValue animated:YES];
}
#pragma mark - 更新当前的时间
- (void) updateCurrentPlayerTime:(CGFloat)timeValue
{
    self.timeLabel.text = [NSString stringWithFormat:@"%@/%@",[self convertTime:timeValue],[self convertTime:[self currentPlayerDuration]]];
    
    
    
    //以下是显示 进度条提示
    if (self.progressLabel.hidden) return;
    
    self.progressLabel.text = [self convertTime:timeValue];
    [self.progressLabel sizeToFit];
    
    
    if(self.bottomView.alpha ==.0f){
        //显示在顶部
        [self.progressLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).with.offset(0);
            make.top.equalTo(self).with.offset(0);
        }];
    }else{
        //显示在底部
        [self.progressLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).with.offset(0);
            make.bottom.equalTo(self.bottomView.mas_top).with.offset(0);
        }];
    }
    
}

#pragma mark - 销毁定时器
- (void)invalidTimer
{
    //销毁自动隐藏状态栏的定时器
    [self invalidAutoDismissTimer];
}

/**
 *  销毁自动隐藏状态栏的定时器
 */
- (void)invalidAutoDismissTimer
{
    if (self.autoDismissTimer == nil)  return;
    
    if ([self.autoDismissTimer isValid])
    {
        //销毁定时器
        [self.autoDismissTimer invalidate];
    }
    
    self.autoDismissTimer = nil;
}

#pragma mark - 懒加载
- (NSDateFormatter *)dateFormatter
{
    if(_dateFormatter == nil)
    {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    return _dateFormatter;
}

- (NSMutableArray *)sliderValues
{
    if(_sliderValues == nil)
    {
        _sliderValues = [[NSMutableArray alloc] init];
    }
    return _sliderValues;
}

- (NSMutableArray *)moveValues
{
    if(_moveValues == nil)
    {
        _moveValues = [[NSMutableArray alloc] init];
    }
    return _moveValues;
}


#pragma mark - 播放器状态改变
- (void)setState:(MHPlayerState)state
{
    if (state != MHPlayerStateBuffering)
    {
        //不是缓存状态 hid hud
        [MBProgressHUD mh_hideHUDForView:self];
    }
    //去掉相同状态
    if (_state == state) return;
    
    _state = state;
    
    //播放状态改变的通知
    [[NSNotificationCenter defaultCenter] postNotificationName:MHPlayerStateChangedNotification object:@(state)];
    
}

#pragma mark - 切换视频资源
- (void)replaceCurrentPlayerItemWithUrlString:(NSString *)urlString
{
    //立即 停止掉当前视频的播放 否则画面没有了 还存在身音
    //    if(self.player.rate == 1.0f) [self.player pause];
    [self pause];
    
    //停止进度
    [self.player.currentItem cancelPendingSeeks];
    [self.player.currentItem.asset cancelLoading];
    
    //0.销魂掉定时器
    [self invalidTimer];

    //显示底部的view
    self.bottomView.alpha = 1.0f;
    self.closeBtn.alpha = 1.0f;
    
    //重新配置
    [self setUpBasicData];
    
    //更新值
    [self updateBuffProgressValue:.0f];
    [self updatePlaySliderValue:.0f];
    [self updateCurrentPlayerTime:.0f];
    
    
    
    
    //1.移除当前视频资源的监听
    [self removePlayerItemObserverWithPlayerItem:self.currentPlayerItem];
    
    //2.移除掉当前视频资源通知
    [self removePlayerItemNotificationWithPlayerItem:self.currentPlayerItem];
    
    //4.移除时间监听的KVO
    [self.player removeTimeObserver:self.periodicTimeObserver];
    
    //5.获取切换的视频资源
    self.currentPlayerItem = [self getPlayItemWithURLString:urlString];
    
    //6.切换资源
    [self.player replaceCurrentItemWithPlayerItem:self.currentPlayerItem];
    
    //7.添加切换视频资源的监听
    [self addPlayerItemObserverWithPlayerItem:self.currentPlayerItem];
    
    //8.添加切换视频资源的通知
    [self addPlayerItemNotificationWithPlayerItem:self.currentPlayerItem];
    
    //9.继续播放
    [self pause];
   
}

#pragma mark - 设置时间
- (void)seekToTime:(CGFloat)seconds
{
    if (self.state == MHPlayerStateStopped) return;  //停止状态下  直接return
    
    seconds = MAX(0, seconds);
    seconds = MIN(seconds, self.duration);
    
    //现暂停一会儿  以免卡顿
    if(self.player.rate == 1.0f) [self.player pause];
    
    [self.player seekToTime:CMTimeMakeWithSeconds(seconds, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
        if (finished)
        {
            //设置为播放按钮
            if (self.playOrPauseBtn.isSelected) self.playOrPauseBtn.selected = NO;
            //不是人为暂停
            self.isPauseByUser = NO;
            
            //播放
            if(self.player.rate == 0.0f) [self.player play];
            
            //如果是不支持播放  则缓冲一段时间
            if (!self.currentPlayerItem.isPlaybackLikelyToKeepUp)
            {
                self.state = MHPlayerStateBuffering;
                
                //show hud
                MBProgressHUD *progressHUD = [MBProgressHUD mh_showMessage:@"" toView:self];
                [progressHUD mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.center.equalTo(self);
                }];
            }
        }
    }];
}
#pragma mark - 基础配置
- (void) setUpBasicData
{
    _moveLeftOrRight = NO;
    _movePlayerSlider = NO;
    
    _isPauseByUser = NO;
    _duration = 0;
    _current  = 0;
    _state = MHPlayerStateStopped;
    _stopWhenAppDidEnterBackground = YES;
}
#pragma mark - 布局
- (void) layoutSubviews
{
    [super layoutSubviews];
    
    MHLogFunc;
}
#pragma mark - 释放播放器
- (void)dealloc
{
    MHLog(@"-----MHPlayer Dealloc-----");
    
    //停止进度
    [self.player.currentItem cancelPendingSeeks];
    [self.player.currentItem.asset cancelLoading];
    
    //0.移掉视频播放的载体
    if (self.player.rate == 1.0f) [self.player pause];
    
    [self.playerLayer removeFromSuperlayer];
    
    //1.移除KVO监听
    [self removePlayerItemObserverWithPlayerItem:self.currentPlayerItem];
    
    //2.移除时间监听的KVO
    [self.player removeTimeObserver:self.periodicTimeObserver];
    
    //3.移除播放完毕的通知
    [self removePlayerItemNotificationWithPlayerItem:self.currentPlayerItem];
    
    //4.销毁时间
    [self invalidTimer];
    
    //销毁视频
    [self.player replaceCurrentItemWithPlayerItem:nil];
    
    
    
    self.currentPlayerItem = nil;
    
    self.player = nil;
    
    self.periodicTimeObserver = nil;

}
#pragma mark - 视频大小的总时间 以及当前播放的时间
/**
 *  获取当前资源视频的总大小
 *  @return 时间
 */
- (double) currentPlayerDuration
{
    AVPlayerItem *playerItem = self.player.currentItem;
    
    if(!playerItem) return .0f;
    
    if (playerItem.status == AVPlayerItemStatusReadyToPlay)
    {
        return CMTimeGetSeconds([[playerItem asset] duration]);
    }
    else{
        return 0.f;
    }
}
/**
 *  当前时间
 *  @return 返回当前播放器的播放时间
 */
- (double)currentTime
{
    return CMTimeGetSeconds([[self player] currentTime]);
}

- (CMTime)playerItemDuration
{
    AVPlayerItem *playerItem = [self.player currentItem];
    
    if (playerItem.status == AVPlayerItemStatusReadyToPlay)
    {
#warning Mike_He 温馨提示
        //通过这个 可能会返回一个不正确的值 通过通过CMTimeGetSeconds(time)得到的是1秒,而同时[asset duration]返回的却是正确的数据.
        return([playerItem duration]);
    }
    return(kCMTimeInvalid);
}



#pragma mark -获取视频资源
/**
 *  获取资源管理的playerItem的对象  主要一种是  是视频格式   一种是 录像格式
 *
 *  @param urlString 视频url地址
 */
- (AVPlayerItem *) getPlayItemWithURLString:(NSString *)urlString
{
    if ([urlString rangeOfString:@"http"].location!=NSNotFound)
    {
        AVPlayerItem *playerItem=[AVPlayerItem playerItemWithURL:[NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        return playerItem;
    }else{
        AVAsset *movieAsset  = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:urlString] options:nil];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
        return playerItem;
    }
    
}
#pragma mark - 将时间秒 转换成  时分秒  或者 分秒
/**
 *  将时间秒 转换成  时分秒  或者 分秒
 *  @param second 多少秒
 *  @return 时分秒 分秒
 */
- (NSString *)convertTime:(CGFloat)second
{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    
    if (second/3600 >= 1)
    {
        [[self dateFormatter] setDateFormat:@"HH:mm:ss"];
    } else {
        [[self dateFormatter] setDateFormat:@"mm:ss"];
    }
    NSString *newTime = [[self dateFormatter] stringFromDate:d];
    
    return newTime;
}

#pragma mark - color
- (UIColor*)colorWithHex:(NSInteger)hexValue alpha:(CGFloat)alphaValue
{
    return [UIColor colorWithRed:((float)((hexValue & 0xFF0000) >> 16))/255.0
                           green:((float)((hexValue & 0xFF00) >> 8))/255.0
                            blue:((float)(hexValue & 0xFF))/255.0
                           alpha:alphaValue];
}
#pragma mark - ==================以下是 添加和删除监听 以及通知事件的处理==================
#pragma mark - 添加 视频资源监听
- (void) addPlayerItemObserverWithPlayerItem:(AVPlayerItem *)playerItem
{
    if (!playerItem) return;
   
    //监听播放状态
    [playerItem addObserver:self
                        forKeyPath:@"status"
                           options:NSKeyValueObservingOptionNew
                           context:PlayViewStatusObservationContext];
    
    //监听缓存进度
    [playerItem addObserver:self
                 forKeyPath:@"loadedTimeRanges"
                    options:NSKeyValueObservingOptionNew
                    context:PlayViewLoadedTimeRangesObservationContext];
    
    
    
    //监听seekToTime后，缓冲数据为空，而且有效时间内数据无法补充，播放失败
    [playerItem addObserver:self
                 forKeyPath:@"playbackBufferEmpty"
                    options:NSKeyValueObservingOptionNew
                    context:PlayViewPlaybackBufferEmptyObservationContext];
    
    
    
    //监听seekToTime后,可以正常播放，相当于readyToPlay，一般拖动滑竿菊花转，到了这个这个状态菊花隐藏
    [playerItem addObserver:self
                 forKeyPath:@"playbackLikelyToKeepUp"
                    options:NSKeyValueObservingOptionNew
                    context:PlayViewPlaybackLikelyToKeepUpObservationContext];
    
}

#pragma mark - 移除 视频资源监听
- (void) removePlayerItemObserverWithPlayerItem:(AVPlayerItem *)playerItem
{
    if (!playerItem) return;
    
   
#warning Mike_He 如果你添加的观察者添加了上下下文 context 你移除的时候必须也要移除对应的上下文的 context 的观察者
    [playerItem removeObserver:self forKeyPath:@"status" context:PlayViewStatusObservationContext];
    
    
    [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:PlayViewLoadedTimeRangesObservationContext];
    
    
    [playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty" context:PlayViewPlaybackBufferEmptyObservationContext];
    
    [playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp" context:PlayViewPlaybackLikelyToKeepUpObservationContext];
    
    
}


#pragma mark - 添加视频播放发出的通知
- (void) addPlayerItemNotificationWithPlayerItem:(AVPlayerItem *)playerItem
{
    if (playerItem==nil) return;

    //视频播放发出通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
    
    //视频异常
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemPlaybackStalled:) name:AVPlayerItemPlaybackStalledNotification object:playerItem];
    
    //进入后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
    
    //进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayGround) name:UIApplicationDidBecomeActiveNotification object:nil];
    
}

#pragma mark - 移除视频播放发出的通知
- (void) removePlayerItemNotificationWithPlayerItem:(AVPlayerItem *)playerItem
{
    if (!playerItem) return;

    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:playerItem];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - 通知事件处理
//播放完毕
- (void)playerDidPlayToEnd:(NSNotification *)note
{
    //播放完毕  回到视频起始点
    MHLog(@"---->>>>>    playerDidPlayToEnd    <<<<<---------");
    __weak typeof(self) weakSelf = self;
    //设置时间为起始时间
    [self.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        if (finished) {
            
            [weakSelf.playSlider setValue:0.0 animated:YES];
            //暂停
            if(self.player.rate == 1.0f) [self.player pause];
            //修改播放状态
            self.state = MHPlayerStatePause;
            //按钮为播放状态
            weakSelf.playOrPauseBtn.selected = YES;
            
            
            //发送播放完毕的通知
            [[NSNotificationCenter defaultCenter] postNotificationName:MHPlayerDidPlayToEndTimeNotification object:nil];
        }
        
    }];
}

//进入后台
- (void)appDidEnterBackground
{
    if (self.stopWhenAppDidEnterBackground)
    {
        //暂停
        [self pause];
        
        self.state = MHPlayerStatePause;
        
        self.isPauseByUser = NO;
    }
}
//进入前台
- (void)appDidEnterPlayGround
{
    if (!self.isPauseByUser)
    {
        //播放
        [self play];
        
        self.state = MHPlayerStatePlaying;
    }
}
//在监听播放器状态中处理比较准确
- (void)playerItemPlaybackStalled:(NSNotification *)notification
{
    // 这里网络不好的时候，就会进入，不做处理，会在playbackBufferEmpty里面缓存之后重新播放
    MHLog(@"----------buffing-----buffing------------");
}


#pragma mark - ==================以上是 添加和删除监听 以及通知事件的处理==================
#pragma mark - ==================以下是手势处理区==================
#pragma mark - 添加手势
- (void)setupGestureRecognizer
{
    // 单击的 Recognizer
    UITapGestureRecognizer* singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap)];
    singleTap.numberOfTapsRequired = 1; // 单击
    [self addGestureRecognizer:singleTap];
    
    // 双击的 Recognizer
    UITapGestureRecognizer* doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap)];
    doubleTap.numberOfTapsRequired = 2; // 双击
    [self addGestureRecognizer:doubleTap];
}


#pragma mark - 播放进度条点击手势事件处理
- (void) sliderTapGesture:(UIGestureRecognizer *)tap
{
    CGPoint touchPoint = [tap locationInView:self.playSlider];
    CGFloat value = (self.playSlider.maximumValue - self.playSlider.minimumValue) * (touchPoint.x / self.playSlider.frame.size.width);
    [self.playSlider setValue:value animated:YES];
    
    //设置时间
    [self seekToTime:value];
}

#pragma mark - 双击手势方法  播放或者暂停
- (void)handleDoubleTap
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MHPlayerDoubleTapNotification object:nil];
    
    //点击播放和暂停
    [self playOrPauseBtnClicked:self.playOrPauseBtn];
}


#pragma mark - 单击手势方法
- (void)handleSingleTap
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MHPlayerSingleTapNotification object:nil];
    
    //显示或隐藏状态栏
    [self hidedenOrShowStatusView];
    
}
// 显示或隐藏状态栏
- (void) hidedenOrShowStatusView
{
    __block BOOL isShow = YES;
    __block CGFloat alpha = 1.0f;
    
    CGFloat duration = 0.15f;
    [UIView animateWithDuration:duration animations:^{
        
        isShow = (self.bottomView.alpha == 1.0f);
        
        alpha = (isShow?0.75f:0.25f);
        self.bottomView.alpha = alpha;
        self.closeBtn.alpha = alpha;
        
    } completion:^(BOOL finish){
        
        [UIView animateWithDuration:duration animations:^{
            
            alpha = (isShow?0.5f:0.5f);
            self.bottomView.alpha = alpha;
            self.closeBtn.alpha = alpha;
            
            
        } completion:^(BOOL finished) {
            
            [UIView animateWithDuration:duration animations:^{
                
                alpha = (isShow?0.25f:0.75f);
                self.bottomView.alpha = alpha;
                self.closeBtn.alpha = alpha;
                
            } completion:^(BOOL finished) {
                
                [UIView animateWithDuration:duration animations:^{
                    alpha = (isShow?0.0f:1.0f);
                    self.bottomView.alpha = alpha;
                    self.closeBtn.alpha = alpha;
                    
                } completion:^(BOOL finished) {
                    
                }];
                
            }];
        }];
    }];
}

#pragma mark - ==================以上是手势处理区==================




#pragma mark - ==================以下是 事件处理 ==================
#pragma mark - 播放和暂停按钮被点击
- (void)playOrPauseBtnClicked:(UIButton *)sender
{
    if (!self.currentPlayerItem) return;
    
    
    if (self.player.rate != 1.f)
    {
        //播放
        [self.player play];
        self.state = MHPlayerStatePlaying;
        sender.selected = NO;
    } else {
        
        //暂停
        [self.player pause];
        sender.selected = YES;
        self.state = MHPlayerStatePause;
    }
    
    self.isPauseByUser = YES;
}

#pragma mark - 手指离开触发事件 这个时候需要  设置时间 播放进度条改变
- (void) playSliderChangeEnd:(UISlider *)slider
{
    //隐藏进度条
    self.progressLabel.hidden = NO;
    
    //停止滑动进度条 设置时间 开机系统更新的时间
    self.movePlayerSlider = NO;
    
    //如果数组里面没有值  证明没有进行过滑动
    if (self.sliderValues.count == 0) return;
    
    //设置时间
    double value = [self.sliderValues.lastObject doubleValue];
    
    [self.sliderValues removeAllObjects];
    //设置播放器的时间
    [self seekToTime:value];
    //更新当前时间
    [self updateCurrentPlayerTime:slider.value];
    
}
/**
 *  更新进度条  slider的值改变  手指正在拖动滑杆，播放器继续播放，但是停止滑竿的时间走动  只允许时间随着滑杆改变 
 *  细节:这样保证滑块不卡顿
 */
- (void)playSliderValueChanged:(UISlider *)slider
{
     MHLog(@"---playSliderValueChanged----%f",slider.value);
    //显示进度条
    self.progressLabel.hidden = NO;
    
    //正在滑动进度条   只更新时间  停止掉系统播放更新时间
    self.movePlayerSlider = YES;
    
    //将滑块的值 放进数组里面
    [self.sliderValues addObject:[NSNumber numberWithDouble:slider.value]];
    
    //只更新时间
    [self updateCurrentPlayerTime:slider.value];
}


#pragma mark - 全屏按钮被点击了
- (void)fullScreenBtnClicked:(UIButton *)button
{
    button.selected = !button.isSelected;
    
    UIInterfaceOrientation orientation;
    
    if (button.isSelected) {
        //记录之前小屏显示的尺寸  和显示在谁身上的superView
        self.originalSuperView = self.superview;
        self.originalFrame = self.frame;
        orientation = UIInterfaceOrientationLandscapeLeft;
        //全屏
        [self fullScreenWithInterfaceOrientation:orientation];
        
    }else{
        orientation = UIInterfaceOrientationPortrait;
        //普通
        [self halfScreen];
    }
 
    
    //发送视频全屏切换的通知
    [[NSNotificationCenter defaultCenter] postNotificationName:MHPlayerFullScreenButtonClickedNotification object:@(orientation)];
}
//全屏显示
- (void)fullScreenWithInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
#warning  Mike_He 为何从父类删除了   还不销毁
    /**
     *  解释: 1.http://www.jianshu.com/p/6a222d693d50
     */
    
    [self removeFromSuperview];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [UIView animateWithDuration:0.25f animations:^{
        
        self.transform = CGAffineTransformIdentity;
        if (interfaceOrientation==UIInterfaceOrientationLandscapeLeft) {
            self.transform = CGAffineTransformMakeRotation(-M_PI_2);
        }else if(interfaceOrientation==UIInterfaceOrientationLandscapeRight){
            self.transform = CGAffineTransformMakeRotation(M_PI_2);
        }
        self.frame = CGRectMake(0, 0, kMainScreenWidth, kMainScreenHeight);
        self.playerLayer.frame =  CGRectMake(0, 0, kMainScreenHeight,kMainScreenWidth);
        
        [self.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).with.offset((0));
            make.top.mas_equalTo(kMainScreenWidth-40);
            make.width.mas_equalTo(kMainScreenHeight);
            make.height.mas_equalTo(40);
        }];
        
        [self.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).with.offset((5));
            make.height.mas_equalTo(30);
            make.width.mas_equalTo(30);
            make.top.equalTo(self).with.offset(5);
            
        }];
        
        [[UIApplication sharedApplication].keyWindow addSubview:self];
        [self bringSubviewToFront:self.bottomView];
    } completion:^(BOOL finished) {
        
        
        MHLog(@"full bottom frame is %@",NSStringFromCGRect(self.bottomView.frame));
        MHLog(@"full close frame is %@",NSStringFromCGRect(self.closeBtn.frame));
        
        //要显示bottomView和closeBtn
        self.bottomView.alpha = self.closeBtn.alpha = 1.0f;
        
    }];
}
/**
 *  常规显示
 */
- (void)halfScreen
{
    [self removeFromSuperview];
    
    //隐藏状态栏
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    
    [UIView animateWithDuration:0.25f animations:^{
        self.transform = CGAffineTransformIdentity;
        self.frame =CGRectMake(self.originalFrame.origin.x, self.originalFrame.origin.y, self.originalFrame.size.width, self.originalFrame.size.height);
        self.playerLayer.frame =  self.bounds;
        [self.originalSuperView addSubview:self];
        [self.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).with.offset(0);
            make.right.equalTo(self).with.offset(0);
            make.height.mas_equalTo(40);
            make.bottom.equalTo(self).with.offset(0);
        }];
        [self.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).with.offset(5);
            make.height.mas_equalTo(30);
            make.width.mas_equalTo(30);
            make.top.equalTo(self).with.offset(5);
        }];
        
    } completion:^(BOOL finished) {
        MHLog(@"half bottom frame is %@",NSStringFromCGRect(self.bottomView.frame));
        MHLog(@"half close frame is %@",NSStringFromCGRect(self.closeBtn.frame));
        
        //要显示bottomView和closeBtn
        self.bottomView.alpha = self.closeBtn.alpha = 1.0f;
    }];
    
}



#pragma mark - 关闭按钮被点击了
- (void)closeBtnClicked:(UIButton *)button
{
    MHLogFunc;
    //停止播放
    [self pause];
    
    
    //发送关闭视频的通知
    [[NSNotificationCenter defaultCenter] postNotificationName:MHPlayerClosedNotification object:nil];
}

#pragma mark - 声音改变
- (void)systemVolumeValueChanged:(UISlider *)slider
{

    //显示声音提示
    self.voiceOrLightLabel.hidden = NO;
    self.systemSlider.value = (self.systemSlider.value<0)?0:self.systemSlider.value;
    self.voiceOrLightLabel.text = [NSString stringWithFormat:@"声音:%.f%%",(self.systemSlider.value-self.systemSlider.minimumValue)*100/(self.systemSlider.maximumValue-self.systemSlider.minimumValue)];
    [self.voiceOrLightLabel sizeToFit];
    
    
    //正在滑动 就不要隐藏
    if(self.isMoveLeftOrRight) return;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //隐藏声音提示
        self.voiceOrLightLabel.hidden = YES;;
    });
    
}


#pragma mark - 自动影藏bottomView
- (void) autoDismissBottomView:(NSTimer *)timer
{
    //如果当前在滑动  playerSlider  或者在滑动左右屏幕  直接退出
    if (self.isMoveLeftOrRight || self.isMovePlayerSlider) return;
    
    if (self.player.rate==.0f && ([self currentTime] != [self duration]))
    {
        //暂停状态 不做任何处理
    }else if(self.player.rate==1.0f)
    {
        //播放状态下
        if (self.bottomView.alpha==1.0)
        {
            //显示或隐藏状态栏
            [self hidedenOrShowStatusView];
        }
    }
}


#pragma mark - ==================以上是 事件处理 ==================

#pragma mark - ==================以下是KVO 监听播放 观察事件处理==================
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    /* AVPlayerItem "status" property value observer. */
    if (context == PlayViewStatusObservationContext)
    {
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
            /* Indicates that the status of the player is not yet known because
                 it has not tried to load new media resources for playback */
            case AVPlayerStatusUnknown:
            {
                MHLog(@"---------AVPlayerStatusUnknown-------------");
            }
                break;
                
            case AVPlayerStatusReadyToPlay:
            {
                /* Once the AVPlayerItem becomes ready to play, i.e.
                 [playerItem status] == AVPlayerItemStatusReadyToPlay,
                 its duration can be fetched from the item. */
                MHLog(@"---------AVPlayerStatusReadyToPlay-------------");
                
                //1.  添加监听每秒监听
                [self monitoringPlayback:playerItem];

                //2.  开启5s dismiss bottomView
                if (self.autoDismissTimer==nil)
                {
                    self.autoDismissTimer = [NSTimer timerWithTimeInterval:MHPlayerAutoDismissStatusViewDuration target:self selector:@selector(autoDismissBottomView:) userInfo:nil repeats:YES];
                    //设置预留时间
                    self.autoDismissTimer.tolerance = MHPlayerAutoDismissStatusViewDuration *0.1f;
                    [[NSRunLoop currentRunLoop] addTimer:self.autoDismissTimer forMode:NSRunLoopCommonModes];
                }
            }
                break;
            case AVPlayerStatusFailed:
            {
                MHLog(@"---------AVPlayerStatusFailed-------------");
            }
                break;
        }
    }else if (context == PlayViewLoadedTimeRangesObservationContext)
    {
        //这里计算视频的缓存量
        NSTimeInterval timeInterval = [self calculateAvailableDurationWithPlayerItem:playerItem];
        
        
        
        //视频时间总量
        double totalDuration = [self currentPlayerDuration];
        MHLog(@"timeInterval----------*****     %f    , totalDuration ------- ****  %f",timeInterval , totalDuration);
        //设置缓存进度条
        [self updateBuffProgressValue:timeInterval / totalDuration];
        
    }else if (context == PlayViewPlaybackBufferEmptyObservationContext)
    {
        //show HUD
        MBProgressHUD *progressHUD = [MBProgressHUD mh_showMessage:@"" toView:self];
        [progressHUD mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
        }];
        //监听播放器在缓冲数据的状态
        if(playerItem.playbackBufferEmpty)
        {
            //指示播放已消耗所有缓冲介质，并且播放将停止或结束
            self.state = MHPlayerStateBuffering;
            
            //缓充一点时间
            [self bufferingSomeSecond];
        }
        
        
    }else if (context == PlayViewPlaybackLikelyToKeepUpObservationContext)
    {
        //允许播放了
    }

}


#pragma mark - 添加监听每秒监听
- (void) monitoringPlayback:(AVPlayerItem *)playerItem
{
    //更新总时间
    CMTime duration = [self playerItemDuration];
    
    //判断时间的有效性
    if (CMTIME_IS_VALID(duration))
    {
        //总时间
        self.duration = CMTimeGetSeconds(duration);
        //更新总时间进度条
        [self updateCurrentPlayerTime:.0f];
        //设置进度条的最大值
        self.playSlider.maximumValue = self.duration;
        
        //可以设置播放
#warning Mike_He 这个可以先不写 看你的需求是什么  如果是一进来 就立即播放 就打开这个  否则需要手动调用播放
        //        if (self.player.rate !=1.f) [self.player play];
        
        
    }else{
        
        self.playSlider.maximumValue = 0.0f;
    }
    
    double interval = 1.0f;
    
    __weak typeof(self) weakSelf = self;
    /**
     *  监听每秒的状态
     *
     *  @param interval     响应的间隔时间
     *  @param NSEC_PER_SEC queue是队列，传NULL代表在主线程执行
     */
    self.periodicTimeObserver = [weakSelf.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)  queue:NULL /* If you pass NULL, the main queue is used. */ usingBlock:^(CMTime time){
        
        //刷新进度
        [weakSelf syncScrubber:playerItem];
    }];
    
}
/**
 *  设置进度
 细节处理:由于这里是在监听视频播放的进度 每一秒就会调用这个方法 从而去更新时间轴  和 playerSlider的值
 情况一:当你手动滑动PlayerSlider的时候  只需要更新时间轴 而不需要调用下面的方法  否则会有卡顿的效果  影响用户体验
 情况二:当你手动滑动播放界面的时候  也只需要更新时间轴 而不需要调用下面的方法  否则会有卡顿的效果  影响用户体验
 */
- (void)syncScrubber:(AVPlayerItem *)playerItem
{
    __weak typeof(self) weakSelf = self;
    //如果当前在滑动  playerSlider  或者在滑动左右屏幕  直接退出
    if (weakSelf.isMoveLeftOrRight || weakSelf.isMovePlayerSlider) return;
    
    CMTime playerDuration = [weakSelf playerItemDuration];
    
    if (CMTIME_IS_INVALID(playerDuration))  //没有播放的意义 直接退出
    {
        weakSelf.playSlider.minimumValue = 0.0;
        
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    
    if (isfinite(duration))
    {
        
        if (weakSelf.isPauseByUser == NO)
        {
            weakSelf.state = MHPlayerStatePlaying;
        }
        
        float minValue = [weakSelf.playSlider minimumValue];
        float maxValue = [weakSelf.playSlider maximumValue];
        
        //获取当前时间
        double currentTime = CMTimeGetSeconds([weakSelf.player currentTime]);
        
        //更新时间轴
        [weakSelf updateCurrentPlayerTime:currentTime];
        
        
        CGFloat timeValue = ((maxValue - minValue) * currentTime / duration + minValue);
        
        //更新播放滑块的值
        [weakSelf updatePlaySliderValue:timeValue];
        
        
        // 不相等的时候才更新，并发通知，否则seek时会继续跳动
        if (weakSelf.current != currentTime)
        {
            weakSelf.current = currentTime;
            if (weakSelf.current > weakSelf.duration)
            {
                weakSelf.duration = weakSelf.current;
            }
            
            //进度更新的通知
            [[NSNotificationCenter defaultCenter] postNotificationName:MHPlayerProgressChangedNotification object:nil];
        }
        
        
    }
}


#pragma mark - 计算缓冲量
- (NSTimeInterval)calculateAvailableDurationWithPlayerItem:(AVPlayerItem *)playerItem
{
    NSArray *loadedTimeRanges = [playerItem loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}


#pragma mark - 缓冲一些时间
/**
 *  细节处理
 
 为了更好地用户体验，一般在滑竿滑动过程中，停止播放时间的走动，当前时间的显示随滑竿移动而改变，当手指离开滑竿后，播放器从当前点开始播放，在从当前点开始播放的时候，有可能没有缓冲数据，需要临时加载，这时候就需要掏用到上面的方法来判断当前状态，加载数据还没有播放的时候，时间走动需要停止，当开始播放了，才开始时间走动。
 
 */
- (void)bufferingSomeSecond
{
    // playbackBufferEmpty会反复进入，因此在bufferingOneSecond延时播放执行完之前再调用bufferingSomeSecond都忽略
    static BOOL isBuffering = NO;
    if (isBuffering) {
        return;
    }
    isBuffering = YES;
    // 需要先暂停一小会之后再播放，否则网络状况不好的时候时间在走，声音播放不出来
    if(self.player.rate == 1.0f) [self.player pause];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // 如果此时用户已经暂停了，则不再需要开启播放了
        if (self.isPauseByUser) {
            isBuffering = NO;
            return;
        }
        // 播放
        if(self.player.rate == 0.0f) [self.player play];
        // 如果执行了play还是没有播放则说明还没有缓存好，则再次缓存一段时间
        isBuffering = NO;
        if (!self.currentPlayerItem.isPlaybackLikelyToKeepUp)
        {
            //如果还是不能播放 那就继续缓存
            [self bufferingSomeSecond];
        }
    });
}


#pragma mark - ==================以上是KVO 监听播放 观察事件处理==================
#pragma mark - ==================以下是touch方法==================
- (void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    MHLog(@"----touchesBegan----");
    self.moveLeftOrRight = YES;
    UITouch *touch =event.allTouches.anyObject;
    self.firstPoint = [touch locationInView:self];
    //记录下第一个点的位置,用于moved方法判断用户是调节音量还是调节视频
    self.originalPoint = self.firstPoint;
}

- (void) touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    MHLog(@"----touchesMoved----");
    UITouch *touch =event.allTouches.anyObject;
    self.secondPoint = [touch locationInView:self];

    //判断是左右滑动还是上下滑动
    CGFloat verValue = fabs(self.originalPoint.y - self.secondPoint.y);
    CGFloat horValue = fabs(self.originalPoint.x - self.secondPoint.x);
    
    //如果竖直方向的偏移量大于水平方向的偏移量,那么是调节音量或者亮度
    if (verValue > horValue) {//上下滑动
        self.progressLabel.hidden = YES;
        //判断是全屏模式还是正常模式
        if (self.fullScreenBtn.isSelected) {//全屏下
            
            //判断刚开始的点是左边还是右边,左边控制音量
            if (self.originalPoint.x <= kHalfHeight) {//全屏下:point在view的左边(控制音量)
                
                /* 手指上下移动的计算方式,根据y值,刚开始进度条在0位置,当手指向上移动600个点后,当手指向上移动N个点的距离后,
                 当前的进度条的值就是N/600,600随开发者任意调整,数值越大,那么进度条到大1这个峰值需要移动的距离也变大,反之越小 */
                self.systemSlider.value += (self.firstPoint.y - self.secondPoint.y)/600.0;
                //系统会自动调用 systemVolumeValueChanged: 这个方法
           
            }else{//全屏下:point在view的右边(控制亮度)
                //右边调节屏幕亮度
                CGFloat lightValue = [UIScreen mainScreen].brightness;
                lightValue +=(self.firstPoint.y - self.secondPoint.y)/600.0;
                lightValue = (lightValue<0)?0:lightValue;
                [[UIScreen mainScreen] setBrightness:lightValue];
                self.voiceOrLightLabel.hidden = NO;
                self.voiceOrLightLabel.text = [NSString stringWithFormat:@"亮度:%.f%%",lightValue*100/1.0f];
                [self.voiceOrLightLabel sizeToFit];
            }
        }else{//非全屏
            
            //判断刚开始的点是左边还是右边,左边控制音量
            if (self.originalPoint.x <= kHalfWidth) {//非全屏下:point在view的左边(控制音量)
                
                /* 手指上下移动的计算方式,根据y值,刚开始进度条在0位置,当手指向上移动600个点后,当手指向上移动N个点的距离后,
                 当前的进度条的值就是N/600,600随开发者任意调整,数值越大,那么进度条到大1这个峰值需要移动的距离也变大,反之越小 */
                self.systemSlider.value += (self.firstPoint.y - self.secondPoint.y)/600.0;
                //系统会自动调用 systemVolumeValueChanged: 这个方法
            }else{//非全屏下:point在view的右边(控制亮度)
                //右边调节屏幕亮度
                CGFloat lightValue = [UIScreen mainScreen].brightness;
                lightValue +=(self.firstPoint.y - self.secondPoint.y)/600.0;
                lightValue = (lightValue<0)?0:lightValue;
                [[UIScreen mainScreen] setBrightness:lightValue];
                self.voiceOrLightLabel.hidden = NO;
                self.voiceOrLightLabel.text = [NSString stringWithFormat:@"亮度:%.f%%",lightValue*100/1.0f];
                [self.voiceOrLightLabel sizeToFit];
                
            }
        }
    }else{//左右滑动,调节视频的播放进度
        //视频进度不需要除以600是因为self.progressSlider没设置最大值,它的最大值随着视频大小而变化
        //要注意的是,视频的一秒时长相当于progressSlider.value的1,视频有多少秒,progressSlider的最大值就是多少
        //隐藏
        self.voiceOrLightLabel.hidden = YES;
        self.progressLabel.hidden = NO;
        self.playSlider.value -= (self.firstPoint.x - self.secondPoint.x);
        
        [self.moveValues addObject:[NSNumber numberWithDouble:self.playSlider.value]];
        
        //只更新时间
        [self updateCurrentPlayerTime:self.playSlider.value];
        
    }
    
    //将第二个值 付给第一个
    self.firstPoint = self.secondPoint;
}

- (void) touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    MHLog(@"----touchesEnded----");
    self.moveLeftOrRight = NO;
    self.firstPoint = self.secondPoint = CGPointZero;
    
    //隐藏
    self.voiceOrLightLabel.hidden = YES;
    self.progressLabel.hidden = YES;
    //设置播放时间
    [self moveTheScreenToChangePlayerTime];
}

- (void) touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    MHLog(@"----touchesCancelled----");
    
    self.moveLeftOrRight = NO;

    self.firstPoint = self.secondPoint = CGPointZero;
    
    //隐藏
    self.voiceOrLightLabel.hidden = YES;
    self.progressLabel.hidden = YES;
    //设置播放时间
    [self moveTheScreenToChangePlayerTime];
    
}

/**
 *  滑动改变播放时间
 */
- (void)moveTheScreenToChangePlayerTime
{
    if (self.moveValues.count==0) return;
    
    
    double value = [self.moveValues.lastObject doubleValue];
    //更新时间
    [self updateCurrentPlayerTime:value];
    //跟新slider
    [self updatePlaySliderValue:value];
    //设置播放器的时间
    [self seekToTime:value];
    //移除所有数据
    [self.moveValues removeAllObjects];
}
#pragma mark - ==================以上是touch方法==================




#pragma mark - ==================以下是 UI设计==================
#pragma mark - 设置自己的views
- (void) setupSubViews
{
    //4.关闭按钮
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.showsTouchWhenHighlighted = YES;
    [closeBtn addTarget:self action:@selector(closeBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [closeBtn setImage:[UIImage imageNamed:MHVideoSrcName(@"close")] ?: [UIImage imageNamed:MHVideoFrameworkSrcName(@"close")] forState:UIControlStateNormal];
    [closeBtn setImage:[UIImage imageNamed:MHVideoSrcName(@"close")] ?: [UIImage imageNamed:MHVideoFrameworkSrcName(@"close")] forState:UIControlStateSelected];
    self.closeBtn = closeBtn;
    [self addSubview:closeBtn];
    [closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).with.offset(5);
        make.height.mas_equalTo(30);
        make.top.equalTo(self).with.offset(5);
        make.width.mas_equalTo(30);
    }];
    
    
    //设置
    MPVolumeView *volumeView = [[MPVolumeView alloc]init];
    volumeView.backgroundColor = [UIColor redColor];
    
    volumeView.frame = CGRectMake(-1000, 0, 0, 0);
    [volumeView sizeToFit];
    
    [self addSubview:volumeView];
    for (UIControl *view in volumeView.subviews)
    {
        if ([view.superclass isSubclassOfClass:[UISlider class]])
        {
            self.systemSlider = (UISlider *)view;
            [self.systemSlider addTarget:self action:@selector(systemVolumeValueChanged:) forControlEvents:UIControlEventValueChanged];
        }
    }
    
    
    
    
    
    
    //设置声音和亮度的提示
    if (self.voiceOrLightLabel == nil) {
        self.voiceOrLightLabel = [[UILabel alloc] init];
        self.voiceOrLightLabel.text = @"亮度:100%";
        [self.voiceOrLightLabel sizeToFit];
        self.voiceOrLightLabel.textColor = [UIColor whiteColor];
        self.voiceOrLightLabel.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.45f];
        [self addSubview:self.voiceOrLightLabel];
        
        //默认是隐藏的
        self.voiceOrLightLabel.hidden = YES;
        
        
        [self.voiceOrLightLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
        }];
    }
    
    
    //设置播放进度的提示
    if (self.progressLabel == nil) {
        self.progressLabel = [[UILabel alloc] init];
        self.progressLabel.text = @"00:00:00";
        [self.progressLabel sizeToFit];
        self.progressLabel.textColor = [UIColor whiteColor];
        self.progressLabel.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.45f];
        [self addSubview:self.progressLabel];
        
        //默认是隐藏的
        self.progressLabel.hidden = YES;
        
        
        [self.progressLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).with.offset(0);
            make.top.equalTo(self).with.offset(0);
        }];
    }
}



#pragma mark - 设置底部视图
- (void) setupBottomViewWithSubviews
{
    //1.底部view
    if (!self.bottomView) {
        self.bottomView= [[UIView alloc] init];
        self.bottomView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.5f];
        [self addSubview:self.bottomView];
        
        //1.1适配 自动布局
        [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).with.offset(0);
            make.right.equalTo(self).with.offset(0);
            make.height.mas_equalTo(40);
            make.bottom.equalTo(self).with.offset(0);
        }];
    }
    
    
    
    //2.暂停和播放按钮
    UIButton *playOrPauseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    playOrPauseBtn.showsTouchWhenHighlighted = YES;
    [playOrPauseBtn addTarget:self action:@selector(playOrPauseBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [playOrPauseBtn setImage:[UIImage imageNamed:MHVideoSrcName(@"pause")] ?: [UIImage imageNamed:MHVideoFrameworkSrcName(@"pause")] forState:UIControlStateNormal];
    [playOrPauseBtn setImage:[UIImage imageNamed:MHVideoSrcName(@"play")] ?: [UIImage imageNamed:MHVideoFrameworkSrcName(@"play")] forState:UIControlStateSelected];
    playOrPauseBtn.selected = YES;
    self.playOrPauseBtn = playOrPauseBtn;
    [self.bottomView addSubview:playOrPauseBtn];
    //2.1自动布局 _playOrPauseBtn
    [playOrPauseBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomView).with.offset(0);
        make.height.mas_equalTo(40);
        make.bottom.equalTo(self.bottomView).with.offset(0);
        make.width.mas_equalTo(40);
    }];
    
    
    //3.添加进度条
    //缓存进度条
    UIProgressView *buffProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    buffProgressView.backgroundColor = [UIColor clearColor];
    buffProgressView.trackTintColor = [UIColor colorFromHexString:@"#2f2e2e"];
    buffProgressView.progressTintColor = [UIColor colorFromHexString:@"#656565"];
    buffProgressView.userInteractionEnabled = NO;
    [self.bottomView addSubview:buffProgressView];
    self.buffProgressView = buffProgressView;
    [self.buffProgressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomView).with.offset(45);
        make.right.equalTo(self.bottomView).with.offset(-45);
        make.height.mas_equalTo(2);
        make.centerY.equalTo(self.bottomView);
    }];

    
    
    
    
    UIImage *transparentImage = [UIImage imageNamed:MHVideoSrcName(@"dot")] ?: [UIImage imageNamed:MHVideoFrameworkSrcName(@"dot")];
    
    //slider
    UISlider *playSlider = [[UISlider alloc] init];
    playSlider.minimumValue = 0.0;
    [playSlider setThumbImage:transparentImage forState:UIControlStateNormal];
    playSlider.minimumTrackTintColor = [UIColor colorFromHexString:@"#ff4322"];
    playSlider.maximumTrackTintColor = [UIColor clearColor];
    playSlider.value = 0.0;//指定初始值
    [playSlider addTarget:self action:@selector(playSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    /**
     *  warning:细节 这三个方法  肯定会走一个
     *  在松手的时候，也有可能会走下面其中某一个时间，为了严谨，建议加上这些事件，当然，松手的时候，只可能走这3个事件中的某一个
     */
    //松手,滑块拖动停止
    [playSlider addTarget:self action:@selector(playSliderChangeEnd:) forControlEvents:UIControlEventTouchUpInside];
    [playSlider addTarget:self action:@selector(playSliderChangeEnd:) forControlEvents:UIControlEventTouchUpOutside];
    [playSlider addTarget:self action:@selector(playSliderChangeEnd:) forControlEvents:UIControlEventTouchCancel];
    
    
    //给进度条添加单击手势
    UITapGestureRecognizer *sliderTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sliderTapGesture:)];
    [playSlider addGestureRecognizer:sliderTap];
    
    self.playSlider = playSlider;
    [self.bottomView addSubview:playSlider];
    
    
    //3.1 自动布局 slider
    [playSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomView).with.offset(45);
        make.right.equalTo(self.bottomView).with.offset(-45);
        make.height.mas_equalTo(40);
        make.bottom.equalTo(self.bottomView).with.offset(0);
    }];
    
    
    //4.全屏按钮
    UIButton *fullScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    fullScreenBtn.showsTouchWhenHighlighted = YES;
    [fullScreenBtn addTarget:self action:@selector(fullScreenBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [fullScreenBtn setImage:[UIImage imageNamed:MHVideoSrcName(@"fullscreen")] ?: [UIImage imageNamed:MHVideoFrameworkSrcName(@"fullscreen")] forState:UIControlStateNormal];
    [fullScreenBtn setImage:[UIImage imageNamed:MHVideoSrcName(@"nonfullscreen")] ?: [UIImage imageNamed:MHVideoFrameworkSrcName(@"nonfullscreen")] forState:UIControlStateSelected];
    self.fullScreenBtn = fullScreenBtn;
    [self.bottomView addSubview:fullScreenBtn];
    
    //4.1 autoLayout fullScreenBtn
    [fullScreenBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.bottomView).with.offset(0);
        make.height.mas_equalTo(40);
        make.bottom.equalTo(self.bottomView).with.offset(0);
        make.width.mas_equalTo(40);
        
    }];
    
    
    //5.timeLabel
    UILabel *timeLabel = [[UILabel alloc]init];
    timeLabel.textAlignment = NSTextAlignmentRight;
    timeLabel.textColor = [UIColor whiteColor];
    timeLabel.backgroundColor = [UIColor clearColor];
    timeLabel.font = [UIFont systemFontOfSize:11];
    self.timeLabel = timeLabel;
    [self.bottomView addSubview:timeLabel];
    
    
    //5.1autoLayout timeLabel
    [timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomView).with.offset(45);
        make.right.equalTo(self.bottomView).with.offset(-45);
        make.height.mas_equalTo(20);
        make.bottom.equalTo(self.bottomView).with.offset(0);
    }];
    
    
}
#pragma mark - 设置layer层
- (void)setupSubLayersWithUrlString:(NSString *)urlString
{

    
    //1.初始化子控件  资源管理类
    if (self.currentPlayerItem == nil) {
        self.currentPlayerItem = [self getPlayItemWithURLString:urlString];
    }
    
    //2.AVPlayer
    if (self.player==nil) {
        self.player = [AVPlayer playerWithPlayerItem:self.currentPlayerItem];
    }
    
    
    //单纯使用AVPlayer类是无法显示视频的，要将视频层添加至AVPlayerLayer中，这样才能将视频显示出来
    //3.AVPlayerLayer
    if (self.playerLayer == nil) {
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.playerLayer.frame = self.layer.bounds;
        //设置视频模式
        self.playerLayer.videoGravity = AVLayerVideoGravityResize;
        [self.layer addSublayer:self.playerLayer];
    }
    
    
    //4.添加切换视频资源的监听
    [self addPlayerItemObserverWithPlayerItem:self.currentPlayerItem];
    
    //5.添加切换视频资源的通知
    [self addPlayerItemNotificationWithPlayerItem:self.currentPlayerItem];
    
}

#pragma mark - 将自己的一些子类移到最前面来显示
- (void)bringSelfSomeSubviewsToFront
{
    [self bringSubviewToFront:self.closeBtn];
    [self bringSubviewToFront:self.voiceOrLightLabel];
    [self bringSubviewToFront:self.progressLabel];
    [self bringSubviewToFront:self.bottomView];
}


#pragma mark - ==================以上是 UI设计==================

@end
