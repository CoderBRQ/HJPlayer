//
//  HJAudioPlayerManager.h
//  HJAudioPlayerDemo
//
//  Created by bianrongqiang on 5/28/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HJPlayerModel.h"
#import <AVFoundation/AVFoundation.h>
/**
 播放器状态
 */
typedef NS_ENUM(NSInteger, HJPlayerStatus) {
    HJPlayerStatusUnknown = 1,                // 未知错误，播放失败
    HJPlayerStatusFailed = 2,                 // 有错误，播放失败
    HJPlayerStatusPlaybackBufferEmpty = 3,     // 缓冲为空，正在缓冲。。（转菊花）
    HJPlayerStatusPlaybackLikelyToKeepUp = 4,  // 可以播放（是时候取消菊花了）
    HJPlayerStatusPausing = 5,                 // 暂停中
    HJPlayerStatusStoped = 6,                  // 结束播放
    HJPlayerStatusFinished = 7,                // 播放完成
    HJPlayerStatusPlaying = 8                  // 正在播放
};

typedef NS_ENUM(NSInteger, HJPlayerType) {
    HJPlayerTypeSingeAudio,// 单个音频播放
    HJPlayerTypeAnotherAudioList,// 列表播放
    HJPlayerTypeInSameAudioList// 同一个列表播放
};

@protocol HJPlayerDataSource <NSObject>

- (NSArray<HJPlayerNowPlayingCenterModel *> *_Nullable)hj_audioInfos;
- (NSArray<HJPlayerModel *> *_Nullable)hj_audios;
@end


@interface HJAudioPlayerManager : NSObject

/**
 Returns the global shared audio player manager instance. By default we will set into the array.
 */
@property (nonatomic, class, readonly, nonnull) HJAudioPlayerManager *sharedManager;
- (id _Nonnull )copy NS_UNAVAILABLE;
- (id _Nonnull )mutableCopy NS_UNAVAILABLE;
+ (instancetype _Nonnull )new NS_UNAVAILABLE;
+(instancetype _Nonnull )alloc NS_UNAVAILABLE;
+(instancetype _Nonnull )allocWithZone:(struct _NSZone *_Nullable)zone NS_UNAVAILABLE;

@property (nonatomic, weak) id <HJPlayerDataSource> _Nullable dataSource;

@property (nonatomic, strong) AVPlayer * _Nullable player;

/**
 Play an audio with an `url`.

 @param url The url for the audio.
 */
- (void)hj_palyWithURL:(nonnull NSURL *)url playerType:(HJPlayerType)type;

- (void)hj_playWithURL:(nonnull NSURL *)url
             cachePath:(nonnull NSString *)cachePath
            playerType:(HJPlayerType)type;

- (void)hj_palyWithURL:(nonnull NSURL *)url
  nowPlayingCenterInfo:(nullable HJPlayerNowPlayingCenterModel*)info
            playerType:(HJPlayerType)type;


- (void)hj_playWithURL:(nonnull NSURL *)url
  nowPlayingCenterInfo:(nullable HJPlayerNowPlayingCenterModel*)info
             cachePath:(nonnull NSString *)cachePath
            playerType:(HJPlayerType)type;

/**刷新数据源数据*/
- (void)hj_reloadData;
/**
 播放
 */
- (void)hj_play;
/**
 暂停
 */
- (void)hj_pause;


/**
 上一曲
 */
- (void)hj_last;

/**
 下一曲
 */
- (void)hj_next;

/**
 暂停后，恢复播放。stop后，restart不起作用
 */
- (void)hj_restart;

/**
 停止
 */
- (void)hj_stop;


/**
 设置播放速度
 */
@property (nonatomic, assign) CGFloat rate;


/**
 seekToTime

 @param value 百分比
 */
- (void)hj_seekToTimeWithPercent:(CGFloat)value;

//@property (nonatomic, copy, nullable) HJAudioPlayerCallBackBlock callBackBlock;

/**
 播放进度
 */
@property (nonatomic, assign, readonly) CGFloat progress;
/**
 当前播放到xx秒
 */
@property (nonatomic, assign, readonly) CGFloat playTime;

/**
 音频总时长
 */
@property (nonatomic, assign, readonly) CGFloat playDuration;

/**
 缓冲总时长
 */
@property (nonatomic, assign, readonly) NSTimeInterval totalBufferTime;

/**播放器状态*/
@property (nonatomic, assign, readonly) HJPlayerStatus status;
@end
