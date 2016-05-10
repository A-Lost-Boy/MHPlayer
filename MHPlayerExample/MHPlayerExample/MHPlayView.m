//
//  MHPlayView.m
//  MHPlayer
//
//  Created by apple on 16/5/5.
//  Copyright © 2016年 Mike_He. All rights reserved.
//

#import "MHPlayView.h"
#import "Masonry.h"
#import "UIImageView+WebCache.h"
@implementation MHPlayView

- (void)dealloc
{
    kDealloc;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.userInteractionEnabled = YES;
        
        UIButton *playBtn = [[UIButton alloc] init];
        playBtn.frame = CGRectMake(0, 0, 128.0f, 128.0f);
        [playBtn setBackgroundImage:[UIImage imageNamed:@"video_play_btn_bg"] forState:UIControlStateNormal];
        [playBtn addTarget:self action:@selector(playBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:playBtn];
        
        [playBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
        }];
        
    }
    return self;
}

- (void)setVideoCover:(NSString *)videoCover
{
    _videoCover = [videoCover copy];
    
    [self sd_setImageWithURL:[NSURL URLWithString:videoCover] placeholderImage:[UIImage imageNamed:@"logo"] options:SDWebImageRetryFailed|SDWebImageRefreshCached];
}

- (void)playBtnClicked
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(playViewDidClickedPlayButton:)]) {
        [self.delegate playViewDidClickedPlayButton:self];
    }
}
@end
