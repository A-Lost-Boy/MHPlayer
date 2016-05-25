//
//  MHPlayerController.m
//  MHPlayer
//
//  Created by apple on 16/5/5.
//  Copyright © 2016年 Mike_He. All rights reserved.
//

#import "MHPlayerController.h"
#import "MHPlayer.h"
#import "MHPlayView.h"
#import "MHConstant.h"
@interface MHPlayerController () <MHPlayViewDelegate>
@property (nonatomic , weak) MHPlayer *player;
@property (nonatomic , weak) MHPlayView  *playView ;
@end

@implementation MHPlayerController

- (void)dealloc
{
    kDealloc;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
// Mike_He  切记 这里必须要销毁掉播放器哦
    [self.player destroy];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //1.设置导航栏
    [self setupNavigationBar];
    
    //2.设置播放页面
    [self setupPlayer];
    
    //3.添加通知中心
    [self addNotificationCenter];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - 添加通知
- (void)addNotificationCenter
{
    //播放完毕的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidPlayEnd) name:MHPlayerDidPlayToEndTimeNotification object:nil];

    //播放器被关闭的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidClosed) name:MHPlayerClosedNotification object:nil];
    
    //播放器全屏的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidFullScreen:) name:MHPlayerFullScreenButtonClickedNotification object:nil];
    
}

#pragma mark - 设置player
- (void) setupPlayer
{
    CGRect playerFrame = CGRectMake(0, 64, kMainScreenWidth, (kMainScreenWidth)*3/4);
    
    MHPlayView *playView = [[MHPlayView alloc] initWithFrame:playerFrame];
    playView.videoCover = MHPlayerBaseUrlCover;
    playView.delegate = self;
    self.playView = playView;
    [self.view addSubview:playView];
    
    
    MHPlayer *player = [MHPlayer videoPlayer];
    player.frame = playerFrame;
    player.videoUrlString = MHPlayerBaseUrl;
    self.player = player;
    [self.view insertSubview:player belowSubview:playView];

}

#pragma mark - 设置导航栏
- (void) setupNavigationBar
{
    self.title = @"Player";
    
    //切换下一部视频
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add)];
    //切换上一部视频
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(del)];
    //默认左边不可点击
    self.navigationItem.leftBarButtonItem.enabled = NO;
}
//上个视频
- (void)del
{
    if (self.player && self.playView)
    {
        //切换视频
        [self.player setVideoUrlString:MHPlayerBaseUrl];
        //切换遮盖
        self.playView.videoCover = MHPlayerBaseUrlCover;
        
        
        
        self.navigationItem.rightBarButtonItem.enabled = YES;
        self.navigationItem.leftBarButtonItem.enabled = NO;
    }else{
        
        [self setupPlayer];
        
        self.navigationItem.rightBarButtonItem.enabled = YES;
        self.navigationItem.leftBarButtonItem.enabled = NO;
    }
}
//下个视频
- (void) add
{
    if (self.player && self.playView)
    {
        //切换视频
        [self.player setVideoUrlString:MHPlayerBaseUrl2];
        //切换遮盖
        self.playView.videoCover = MHPlayerBaseUrlCover2;
        
        self.navigationItem.rightBarButtonItem.enabled = NO;
        self.navigationItem.leftBarButtonItem.enabled = YES;

    }else{

        [self setupPlayer];
        
        self.navigationItem.rightBarButtonItem.enabled = YES;
        self.navigationItem.leftBarButtonItem.enabled = NO;
        
    }
}

#pragma mark - MHPlayViewDelegate
- (void)playViewDidClickedPlayButton:(MHPlayView *)playView
{
    //显示播放器
    [self.view insertSubview:self.playView belowSubview:self.player];
    //播放
    [self.player play];
}


#pragma mark - 播放器的通知事件 处理
- (void)playerDidPlayEnd
{
    //播放完毕
    //显示遮盖图
    [self.view insertSubview:self.player belowSubview:self.playView];
    
    //暂停
    [self.player pause];
    
    
}

- (void) playerDidClosed
{
    //播放器关掉
    
    //遮盖删除
    [self.playView removeFromSuperview];
    self.playView = nil;
    
    //播放器销毁
    [self.player removeFromSuperview];
    [self.player destroy];
    self.player = nil;
    
    self.navigationItem.rightBarButtonItem.enabled = YES;
    self.navigationItem.leftBarButtonItem.enabled = YES;
}


- (void)playerDidFullScreen:(NSNotification *)note
{
    //全屏或者正常
    UIInterfaceOrientation orientation = [note.object integerValue];
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
        {
            //竖屏
            //显示状态栏
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
            
            //显示导航栏
            [self.navigationController setNavigationBarHidden:NO animated:YES];
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:
        {
            //左横屏
            //隐藏状态栏
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
            
            //隐藏导航栏
            [self.navigationController setNavigationBarHidden:YES animated:YES];
        }
            break;
            
        default:
            break;
    }
    
}

@end
