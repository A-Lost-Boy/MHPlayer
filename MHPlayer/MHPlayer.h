//
//  MHPlayer.h
//  MHPlayer
//
//  Created by apple on 16/4/25.
//  Copyright © 2016年 Mike_He. All rights reserved.
//

/**
 *  AVPlayer 小结
 
 AVPlayer 本身并不能显示视频，而且它也不像MPMoviePlayerController有一个view属性。如果AVPlayer要显示必须创建一个播放器层AVPlayerLayer用于展示，播放器层继承于CALayer，有了AVPlayerLayer之添加到控制器视图的layer中即可。
 
 AVAsset：主要用于获取多媒体信息，是一个抽象类，不能直接使用。
 AVURLAsset：AVAsset的子类，可以根据一个URL路径创建一个包含媒体信息的AVURLAsset对象。
 AVPlayerItem：一个媒体资源管理对象，管理者视频的一些基本信息和状态，一个AVPlayerItem对应着一个视频资源。
 
 AVPlayer对应着两个方法play、pause来实现
 通常情况下可以通过判断播放器的播放速度来获得播放状态。如果rate为0说明是停止状态，1是则是正常播放状态
 
 在前面的播放器中通常是使用通知来获得播放器的状态，媒体加载状态等，但是无论是AVPlayer还是AVPlayerItem（AVPlayer有一个属性currentItem是AVPlayerItem类型，表示当前播放的视频对象）都无法获得这些信息。当然AVPlayerItem是有通知的，但是对于获得播放状态和加载状态有用的通知只有一个：播放完成通知AVPlayerItemDidPlayToEndTimeNotification。在播放视频时，特别是播放网络视频往往需要知道视频加载情况、缓冲情况、播放情况，这些信息可以通过KVO监控AVPlayerItem的status、loadedTimeRanges属性来获得。当AVPlayerItem的status属性为AVPlayerStatusReadyToPlay是说明正在播放，只有处于这个状态时才能获得视频时长等信息；当loadedTimeRanges的改变时（每缓冲一部分数据就会更新此属性）可以获得本次缓冲加载的视频范围（包含起始时间、本次加载时长），这样一来就可以实时获得缓冲情况。然后就是依靠AVPlayer的- (id)addPeriodicTimeObserverForInterval:(CMTime)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(CMTime time))block方法获得播放进度，这个方法会在设定的时间间隔内定时更新播放进度，通过time参数通知客户端。
 
 最后就是视频切换的功能，在前面介绍的所有播放器中每个播放器对象一次只能播放一个视频，如果要切换视频只能重新创建一个对象，但是AVPlayer却提供了- (void)replaceCurrentItemWithPlayerItem:(AVPlayerItem *)item方法用于在不同的视频之间切换（事实上在AVFoundation内部还有一个AVQueuePlayer专门处理播放列表切换，有兴趣的朋友可以自行研究，这里不再赘述）。
 
 */




#import <UIKit/UIKit.h>
@import MediaPlayer;
@import AVFoundation;



//播放器的几种状态
typedef NS_ENUM(NSInteger, MHPlayerState) {
    MHPlayerStateBuffering = 1,  //缓冲
    MHPlayerStatePlaying   = 2,  //播放
    MHPlayerStateStopped   = 3,  //停止
    MHPlayerStatePause     = 4   //暂停
};



/**
 *  发送单击视频的通知
 */
UIKIT_EXTERN NSString * const MHPlayerSingleTapNotification ;
/**
 *  发送双击视频的通知
 */
UIKIT_EXTERN NSString * const MHPlayerDoubleTapNotification;
/**
 *  发送点击关闭视频的通知
 */
UIKIT_EXTERN NSString * const MHPlayerClosedNotification;
/**
 *  发送播放完毕的通知
 */
UIKIT_EXTERN NSString * const MHPlayerDidPlayToEndTimeNotification ;
/**
 *  播放状态改变
 */
UIKIT_EXTERN NSString * const MHPlayerStateChangedNotification  ;
/**
 *  播放进度更新的通知
 */
UIKIT_EXTERN NSString * const MHPlayerProgressChangedNotification ;
/**
 *  全屏按钮被点击的通知
 */
UIKIT_EXTERN NSString * const MHPlayerFullScreenButtonClickedNotification;




@interface MHPlayer : UIView

@property (nonatomic, readonly ,assign) MHPlayerState state;            //视频播放状态
@property (nonatomic, readonly ,assign) CGFloat       duration;         //视频总时间
@property (nonatomic, readonly ,assign) CGFloat       current;          //当前播放时间
@property (nonatomic, readonly ,assign) CGFloat       progress;         //播放进度

/**
 *  视频播放地址
 */
@property (nonatomic , copy) NSString  *videoUrlString;


/**
 *  初始化播放器
 *  @param frame          播放器的尺寸
 *  @param videoUrlString 播放器的描述
 */
- (instancetype) initWithVideoPlayerFrame:(CGRect)frame videoUrlString:(NSString *)videoUrlString;
+ (instancetype) videoPlayerWithFrame:(CGRect)frame videoUrlString:(NSString *)videoUrlString;
+ (instancetype) videoPlayer;
/**
 *  播放
 */
-(void)play;
/**
 *  暂停
 */
-(void)pause;
/**
 *  手动销毁播放器
 *  由于这个播放器里面使用了NSTimer 这个类导致播放器释放不掉 需要手动释放
 *  切记：必须要在使用的类中的 dealloc 里面 使用  否则会导致播放器  和控制器都释放不了
 *  解释:http://www.jianshu.com/p/2287344894ae
 */
- (void) destroy;

@end
