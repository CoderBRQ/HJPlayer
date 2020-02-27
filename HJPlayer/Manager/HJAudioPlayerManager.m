//
//  HJAudioPlayerManager.m
//  HJAudioPlayerDemo
//
//  Created by bianrongqiang on 5/28/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#import "HJAudioPlayerManager.h"
#import <MediaPlayer/MediaPlayer.h>
#import "HJPlayerDownloader.h"
#import "HJInternalMacors.h"
#import "HJCache.h"
#import "HJDebugLog.h"
#import "HJDataCapture.h"

static void *context = (void *)@"hj_context";

@interface HJAudioPlayerManager ()<AVAssetResourceLoaderDelegate>

@property (nonatomic, strong) id timeObserver;
@property (nonatomic, strong) NSMutableArray *audioInfos;
@property (nonatomic, strong) NSMutableArray *audios;
@property (nonatomic, strong) HJPlayerNowPlayingCenterModel *nowPlayingCenterInfo;
@property (nonatomic, strong) NSURL *currentAudioURL;
@property (nonatomic, copy) NSString *cachePath;
@property (nonatomic, assign) HJPlayerType playType;
@property (nonatomic, strong) dispatch_semaphore_t audioLock;
@property (nonatomic, copy) NSString *userAgent;
@end

@implementation HJAudioPlayerManager

#pragma mark - lazy load

- (AVPlayer *)player {
    if (_player == nil) {
        _player = [[AVPlayer alloc] init];
        _player.volume = 1.0;
    }
    return _player;
}

#pragma mark - setter

- (void)setProgress:(CGFloat)progress {_progress = progress;}
- (void)setPlayTime:(CGFloat)playTime {_playTime = playTime;}
- (void)setPlayDuration:(CGFloat)playDuration {_playDuration = playDuration;}
- (void)setTotalBufferTime:(NSTimeInterval)totalBufferTime {_totalBufferTime = totalBufferTime;}
- (void)setStatus:(HJPlayerStatus)status {_status = status;}
- (void)setRate:(CGFloat)rate {
    _rate = rate;
    if (rate != 1) {
        _player.currentItem.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmSpectral;
    }
}

#pragma mark - sharedManager

+ (instancetype)sharedManager {
    static HJAudioPlayerManager *_manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[super alloc] init];
    });
    return _manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [UIApplication.sharedApplication beginReceivingRemoteControlEvents];// 接收远程线控事件
        // 后台播放
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryPlayback
                       error:nil];
        [session setActive:YES
                     error:nil];
        // 系统事件打断播放监听
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(AVAudioSessionInterruptionNotification:)
                                                     name:AVAudioSessionInterruptionNotification
                                                   object:session];
        // 播放速度
        self.rate = 1.0;
        self.audioLock = dispatch_semaphore_create(1);
        
        // User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
        NSString *userAgent = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)",
                               [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey],
                               [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey],
                               [[UIDevice currentDevice] model],
                               [[UIDevice currentDevice] systemVersion],
                               [[UIScreen mainScreen] scale]];
        if (userAgent) {
            if (![userAgent canBeConvertedToEncoding:NSASCIIStringEncoding]) {
                NSMutableString *mutableUserAgent = [userAgent mutableCopy];
                if (CFStringTransform((__bridge CFMutableStringRef)(mutableUserAgent), NULL, (__bridge CFStringRef)@"Any-Latin; Latin-ASCII; [:^ASCII:] Remove", false)) {
                    userAgent = mutableUserAgent;
                }
            }
            self.userAgent = userAgent;
        }
    }
    return self;
}

// 接收通知方法
- (void)AVAudioSessionInterruptionNotification: (NSNotification *)notificaiton {
    AVAudioSessionInterruptionType type = [notificaiton.userInfo[AVAudioSessionInterruptionTypeKey] intValue];
    if (type == AVAudioSessionInterruptionTypeBegan) {
        [self.player pause];
    } else {
        [self.player play];
    }
}

#pragma mark - public method
- (void)hj_palyWithURL:(NSURL *)url playerType:(HJPlayerType)type {
    [self hj_playWithURL:url cachePath:@"" playerType:type];
}

- (void)hj_playWithURL:(NSURL *)url
             cachePath:(NSString *)cachePath
            playerType:(HJPlayerType)type{
    
    NSAssert(url.absoluteString.length != 0, @"hj_playWithURL:cachePath method in HJAudioPlayerManager missing required parameters URL:%@", url);
    self.currentAudioURL = url;
    self.cachePath = cachePath;
    self.playType = type;
    [self hj_internalPlay];
}

- (void)hj_palyWithURL:(NSURL *)url
  nowPlayingCenterInfo:(HJPlayerNowPlayingCenterModel*)info
            playerType:(HJPlayerType)type{
    [self hj_playWithURL:url nowPlayingCenterInfo:info cachePath:@"" playerType:type];
}

- (void)hj_playWithURL:(NSURL *)url
  nowPlayingCenterInfo:(HJPlayerNowPlayingCenterModel*)info
             cachePath:(NSString *)cachePath
            playerType:(HJPlayerType)type;{
    NSAssert(url.absoluteString.length != 0, @"hj_playWithURL:cachePath method in HJAudioPlayerManager missing required parameters URL:%@", url);
    self.currentAudioURL = url;
    self.cachePath = cachePath;
    self.playType = type;
    [self hj_internalPlay];
    self.nowPlayingCenterInfo = info;
    [self configNowPlayingCenter];
}

- (void)hj_seekToTimeWithPercent:(CGFloat)value {
    [HJPlayerDownloader.sharedDownloader cancelAllDownloads];
    NSString *filePath = [HJCache.sharedCache filePathWithFileURL:_currentAudioURL];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:filePath] options:nil];
    CMTime duration = asset.duration;
    NSTimeInterval audioTotalTime = duration.value/duration.timescale;
    [_player seekToTime:CMTimeMake(floorf(audioTotalTime * value), 1)
        toleranceBefore:CMTimeMake(1, 1)
         toleranceAfter:CMTimeMake(1, 1)];
}

- (void)hj_play {
    [_player play];
    self.status = HJPlayerStatusPlaying;
}

- (void)hj_pause {
    self.rate = 0;
    self.status = HJPlayerStatusPausing;
}

- (void)hj_last {
    if (self.audios.count < 2) {return;}
    [_audios enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj == self.currentAudioURL && idx > 0) {
            self.currentAudioURL = self.audios[idx - 1];
            [self hj_internalPlay];
            self.nowPlayingCenterInfo = self.audioInfos[idx - 1];
            [self updateConfigNowPlayingCenter];
        }
    }];
}

- (void)hj_next {
    if (self.audios.count < 2) {return;}
    [_audios enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj == self.currentAudioURL && idx < self.audios.count - 1) {
            self.currentAudioURL = self.audios[idx + 1];
            [self hj_internalPlay];
            self.nowPlayingCenterInfo = self.audioInfos[idx + 1];
            [self updateConfigNowPlayingCenter];
        }
    }];
}

- (void)hj_restart {
    [_player play];
}

- (void)hj_stop {
    [_player pause];
    [self hj_seekToTimeWithPercent:0];
    [self currentItemRemoveObserver];
    _player = nil;
    self.status = HJPlayerStatusStoped;
}

- (void)hj_reloadData {
    if ([self.dataSource respondsToSelector:@selector(hj_audioInfos)]) {
        self.audioInfos = [[self.dataSource hj_audioInfos] mutableCopy];
    }
    if ([self.dataSource respondsToSelector:@selector(hj_audios)]) {
        self.audios = [[self.dataSource hj_audios] mutableCopy];
    }
}

#pragma mark - AVAssetResourceLoaderDelegate
//Returning YES from this method will tell resource loader that you will be responsible for loading this request. Returning NO will result in an error inside AVURLAsset because neither resource loader, nor delegate can’t load this request.
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    
    long long requestedOffset = loadingRequest.dataRequest.requestedOffset;
    NSInteger requestedLength = loadingRequest.dataRequest.requestedLength;
    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:_currentAudioURL];
    NSString *range=[NSString stringWithFormat:@"bytes=%lld-%lld",requestedOffset,requestedOffset + requestedLength - 1];
    [mutableRequest setValue:range forHTTPHeaderField:@"Range"];
    [mutableRequest setValue:@"identity" forHTTPHeaderField:@"Accept-Encoding"];
    
    mutableRequest.allHTTPHeaderFields = @{@"User-Agent" : self.userAgent};
    
    NSURLRequest * originRequest = [mutableRequest copy];
    
    size_t size = [HJCache.sharedCache fileSizeWithFileURL:self.currentAudioURL];
    if (size == 0) {
        [HJDataCapture.sharedDataCapture captureDataFromNetWithRequestedOffset:requestedOffset requestedLength:requestedLength loadingRequest:loadingRequest originRequest:originRequest];
    }else {
        NSArray<NSNumber *> *loadingRequestRange = @[@(requestedOffset), @(requestedOffset + requestedLength - 1)];
        NSArray<NSNumber *> *range = [HJCache.sharedCache queryDownloadFileRangeInLocalPlistWithURL:_currentAudioURL loadingRequestRange:loadingRequestRange];
        
        if (range.count == 0) {// 已经全部下载完毕
            [HJDataCapture.sharedDataCapture captureDataFromDiskWithStartOffset:requestedOffset dataSize:requestedLength loadingRequest:loadingRequest originRequest:originRequest];
        }else {// 未下载；下载了一部分
            NSNumber *startOffset = range[0];
            NSNumber *endOffset = range[1];
            long long offset = startOffset.longLongValue;
            long long length = endOffset.longLongValue - startOffset.longLongValue + 1;
            [HJDataCapture.sharedDataCapture captureDataFromNetWithRequestedOffset:offset requestedLength:length loadingRequest:loadingRequest originRequest:originRequest];
        }
    }
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSLog(@"请求取消");
}
#pragma mark - private

- (void)hj_internalPlay {
    
//    [HJPlayerDownloader.sharedDownloader cancelAllDownloads];
    [self currentItemRemoveObserver];
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:_currentAudioURL resolvingAgainstBaseURL:NO];
    components.scheme = @"HJScheme";
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[components URL] options:nil];
    [asset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    [self.player replaceCurrentItemWithPlayerItem:item];
    if (@available(iOS 10.0, *)) {
        self.player.automaticallyWaitsToMinimizeStalling = NO;
        [self.player play];// 如果网速很慢，也不能立即播放
    }
    [self currentItemAddObserver];
    [self resetAudioList];
}

- (void)resetAudioList {
//    switch (type) {
//        case HJPlayerTypeSingeAudio:
//        {
//            [self.audios removeAllObjects];
//            [self.audioInfos removeAllObjects];
//        }
//            break;
//        case HJPlayerTypeAnotherAudioList:
//        {
//            [self.audios removeAllObjects];
//            [self.audioInfos removeAllObjects];
//        }
//            break;
//        default:
//            break;
//    }
    HJ_LOCK(self.audioLock);
    [self.audios removeAllObjects];
    [self.audioInfos removeAllObjects];
    HJ_UNLOCK(self.audioLock);
}

- (void)configNowPlayingCenter {
    if (_nowPlayingCenterInfo == nil) {return;}
    NSMutableDictionary * info = [NSMutableDictionary dictionary];
    //音频标题
    [info setObject:_nowPlayingCenterInfo.audioName forKey:MPMediaItemPropertyTitle];
    //音频艺术家
    [info setObject:_nowPlayingCenterInfo.audioSinger forKey:MPMediaItemPropertyArtist];
    //音频播放时间
    [info setObject:@(0) forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    //音频播放速度
    [info setObject:@(1) forKey:MPNowPlayingInfoPropertyPlaybackRate];
    //音频总时间
    [info setObject:@(0) forKey:MPMediaItemPropertyPlaybackDuration];
    //音频封面
    MPMediaItemArtwork * artwork = [[MPMediaItemArtwork alloc] initWithImage:_nowPlayingCenterInfo.audioImage];
    [info setObject:artwork forKey:MPMediaItemPropertyArtwork];
    //完成设置
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:info];
}

- (void)updateConfigNowPlayingCenter {
    if (_nowPlayingCenterInfo == nil) {return;}
    NSMutableDictionary * info = [NSMutableDictionary dictionary];
    //音频标题
    [info setObject:_nowPlayingCenterInfo.audioName forKey:MPMediaItemPropertyTitle];
    //音频艺术家
    [info setObject:_nowPlayingCenterInfo.audioSinger forKey:MPMediaItemPropertyArtist];
    //音频播放时间
    [info setObject:@(HJAudioPlayerManager.sharedManager.playTime) forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    //音频播放速度
    [info setObject:@(1) forKey:MPNowPlayingInfoPropertyPlaybackRate];
    //音频总时间
    [info setObject:@(HJAudioPlayerManager.sharedManager.playDuration) forKey:MPMediaItemPropertyPlaybackDuration];
    //音频封面
    MPMediaItemArtwork * artwork = [[MPMediaItemArtwork alloc] initWithImage:_nowPlayingCenterInfo.audioImage];
    [info setObject:artwork forKey:MPMediaItemPropertyArtwork];
    //完成设置
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:info];
}

- (void)currentItemRemoveObserver {
    [self.player.currentItem removeObserver:self
                                 forKeyPath:@"status"
                                    context:context];
    [self.player.currentItem removeObserver:self
                                 forKeyPath:@"loadedTimeRanges"
                                    context:context];
    [self.player.currentItem removeObserver:self
                                 forKeyPath:@"playbackBufferEmpty"
                                    context:context];
    [self.player.currentItem removeObserver:self
                                 forKeyPath:@"playbackLikelyToKeepUp"
                                    context:context];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:self.player.currentItem];
    if (_timeObserver) {
        [self.player removeTimeObserver:_timeObserver];
        _timeObserver = nil;
    }
}

- (void)currentItemAddObserver {
    
    //监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
    [self.player.currentItem addObserver:self
                              forKeyPath:@"status"
                                 options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew)
                                 context:context];
    //监控缓冲加载情况属性
    [self.player.currentItem addObserver:self
                              forKeyPath:@"loadedTimeRanges"
                                 options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew
                                 context:context];
    //seekToTime后的状态
    [self.player.currentItem addObserver:self
                              forKeyPath:@"playbackBufferEmpty"
                                 options:NSKeyValueObservingOptionNew
                                 context:context];
    //seekToTime后的状态
    [self.player.currentItem addObserver:self
                              forKeyPath:@"playbackLikelyToKeepUp"
                                 options:NSKeyValueObservingOptionNew
                                 context:context];
    //监控播放完通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackFinished:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.player.currentItem];
    //监控播放时间进度
    __weak typeof(self) weakSelf = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1)
                                                                  queue:dispatch_get_main_queue()
                                                             usingBlock:^(CMTime time) {
                                                                 
         __strong typeof(weakSelf) strongSelf = weakSelf;
        float current = CMTimeGetSeconds(time);
        float total = CMTimeGetSeconds(strongSelf.player.currentItem.duration);
        if (current) {
            strongSelf.progress = current/total;
            strongSelf.playTime = current;
            strongSelf.playDuration = total;
            [strongSelf updateConfigNowPlayingCenter];
            strongSelf.player.rate = strongSelf.rate;
        }
    }];
}


- (void)playbackFinished:(NSNotification *)notifi {
    self.status = HJPlayerStatusFinished;
    [self hj_stop];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    AVPlayerItem *item = object;
    if (item != self.player.currentItem) {return;}
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [change[@"new"] integerValue];
        switch (status) {
            case AVPlayerStatusUnknown:
                self.status = HJPlayerStatusUnknown;
                break;
            case AVPlayerStatusReadyToPlay:
            {
                self.status = HJPlayerStatusPlaying;
                [_player play];
            }
                break;
            case AVPlayerStatusFailed:
                self.status = HJPlayerStatusFailed;
                break;
            default:
                break;
        }
    }else  if ([keyPath isEqualToString:@"loadedTimeRanges"]) {// 数据缓冲状态进度
        NSArray *array = self.player.currentItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        
        NSTimeInterval totalBufferTime = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration);// 缓冲总时长
        self.totalBufferTime = totalBufferTime;
        [self updateConfigNowPlayingCenter];
    }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {//seekToTime后,可以正常播放，相当于readyToPlay，一般拖动滑竿菊花转，到了这个这个状态菊花隐藏
        self.status = HJPlayerStatusPlaybackLikelyToKeepUp;
        [_player play];
    }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {// seekToTime后，缓冲数据为空，而且有效时间内数据无法补充，播放失败；最开始播放时，如果没有缓存也会调用一次
        self.status = HJPlayerStatusPlaybackBufferEmpty;
    }
}

@end
