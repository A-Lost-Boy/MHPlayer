//
//  MKHPlayView.h
//  MKHPlayer
//
//  Created by apple on 16/5/5.
//  Copyright © 2016年 Mike. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MHPlayView;
@protocol MHPlayViewDelegate <NSObject>

@optional
- (void)playViewDidClickedPlayButton:(MHPlayView *)playView;

@end


@interface MHPlayView : UIImageView
@property (nonatomic , copy) NSString *videoCover;

@property (nonatomic , weak) id <MHPlayViewDelegate> delegate;
@end
