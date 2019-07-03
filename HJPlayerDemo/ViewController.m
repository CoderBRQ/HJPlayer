//
//  ViewController.m
//  HJAudioPlayer
//
//  Created by bianrongqiang on 6/24/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#import "ViewController.h"
#import "HJPlayer.h"
#import "ListView.h"

@interface ViewController ()
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, weak) ListView *v;

@property (nonatomic, strong) AVPlayer *player;
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUp];
}

- (void)playOnNet {
    NSURL *url = [NSURL URLWithString:@"http://sc1.111ttt.cn/2018/1/03/13/396131203208.mp3"];
    AVPlayerItem * songItem = [[AVPlayerItem alloc]initWithURL:url];
    AVPlayer * player = [[AVPlayer alloc]initWithPlayerItem:songItem];
    self.player = player;
    [player play];
}

- (void)setUp {
    
    self.url = [NSURL URLWithString:@"http://mpge.5nd.com/2018/2018-1-23/74521/1.mp3"];
    
    ListView *v = [[[NSBundle mainBundle] loadNibNamed:@"ListView" owner:nil options:nil] lastObject];
    [self.view addSubview:v];
    self.v = v;
    
    v.frame = self.view.bounds;
    
    v.urlLabel.text = self.url.absoluteString;
    
    [v.playButton addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
    
    [v.clearButton addTarget:self action:@selector(clear) forControlEvents:UIControlEventTouchUpInside];
    
    [self addObservers];
}

- (void)addObservers {
    [HJAudioPlayerManager.sharedManager addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
    
    [HJAudioPlayerManager.sharedManager addObserver:self forKeyPath:@"playTime" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
    [HJAudioPlayerManager.sharedManager addObserver:self forKeyPath:@"playDuration" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
    [HJAudioPlayerManager.sharedManager addObserver:self forKeyPath:@"totalBufferTime" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
    [HJAudioPlayerManager.sharedManager addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
    [HJAudioPlayerManager.sharedManager addObserver:self forKeyPath:@"downloadProgress" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

- (void)removeObservers {
    [HJAudioPlayerManager.sharedManager removeObserver:self forKeyPath:@"state"];
    [HJAudioPlayerManager.sharedManager removeObserver:self forKeyPath:@"playTime"];
    [HJAudioPlayerManager.sharedManager removeObserver:self forKeyPath:@"playDuration"];
    [HJAudioPlayerManager.sharedManager removeObserver:self forKeyPath:@"totalBufferTime"];
    [HJAudioPlayerManager.sharedManager removeObserver:self forKeyPath:@"progress"];
    [HJAudioPlayerManager.sharedManager removeObserver:self forKeyPath:@"downloadProgress"];
}

- (void)play {
    self.url = [NSURL URLWithString:@"http://sc1.111ttt.cn/2018/1/03/13/396131203208.mp3"];
    [HJAudioPlayerManager.sharedManager hj_palyWithURL:self.url playerType:HJPlayerTypeSingeAudio];
    HJAudioPlayerManager.sharedManager.rate = 1;
}

- (void)clear {
    [HJCache.sharedCache removeDataWithFileURL:self.url completion:^{
        NSLog(@"清除成功");
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"state"]) {
    }else if ([keyPath isEqualToString:@"playTime"]) {
    }else if ([keyPath isEqualToString:@"playDuration"]) {
    }else if ([keyPath isEqualToString:@"totalBufferTime"]) {
    }else if ([keyPath isEqualToString:@"progress"]) {
    }else if ([keyPath isEqualToString:@"downloadProgress"]) {
    }
    
    NSLog(@"|播放状态：%ld", (long)HJAudioPlayerManager.sharedManager.state);
    NSLog(@"|当前播放时间：%f", HJAudioPlayerManager.sharedManager.playTime);
    NSLog(@"|总时间：%f", HJAudioPlayerManager.sharedManager.playDuration);
    NSLog(@"|缓冲时间：%f", HJAudioPlayerManager.sharedManager.totalBufferTime);
    NSLog(@"|播放进度：%f", HJAudioPlayerManager.sharedManager.progress);
    NSLog(@"--------------------------");
    
    //    HJPlayerStatusUnknown = 1,                // 未知错误，播放失败
    //    HJPlayerStatusFailed = 2,                 // 有错误，播放失败
    //    HJPlayerStatePlaybackBufferEmpty = 3,     // 缓冲为空，正在缓冲。。（转菊花）
    //    HJPlayerStatePlaybackLikelyToKeepUp = 4,  // 可以播放（是时候取消菊花了）
    //    HJPlayerStatePausing = 5,                 // 暂停中
    //    HJPlayerStateStoped = 6,                  // 结束播放
    //    HJPlayerStateFinished = 7,                // 播放完成
    //    HJPlayerStatePlaying = 8
    
    switch (HJAudioPlayerManager.sharedManager.state) {
        case HJPlayerStatusUnknown:
            self.v.playStatus.text = [NSString stringWithFormat:@"播放状态：未知"];
            break;
        case HJPlayerStatusFailed:
            self.v.playStatus.text = [NSString stringWithFormat:@"播放状态：播放失败"];
            break;
        case HJPlayerStatePlaybackBufferEmpty:
            self.v.playStatus.text = [NSString stringWithFormat:@"播放状态：缓冲为空，正在缓冲。。"];
            break;
        case HJPlayerStatePlaybackLikelyToKeepUp:
            self.v.playStatus.text = [NSString stringWithFormat:@"播放状态：可以播放"];
            break;
        case HJPlayerStatePausing:
            self.v.playStatus.text = [NSString stringWithFormat:@"播放状态：暂停"];
            break;
        case HJPlayerStateStoped:
            self.v.playStatus.text = [NSString stringWithFormat:@"播放状态：停止"];
            break;
        case HJPlayerStateFinished:
            self.v.playStatus.text = [NSString stringWithFormat:@"播放状态：播放完成"];
            break;
        case HJPlayerStatePlaying:
            self.v.playStatus.text = [NSString stringWithFormat:@"播放状态：播放ing"];
            break;
        default:
            break;
    }
    
    self.v.playProgressLabel.text = [NSString stringWithFormat:@"播放进度：%.1f%%", HJAudioPlayerManager.sharedManager.progress * 100];
    self.v.totalTimeLabel.text = [NSString stringWithFormat:@"总共播放时间：%.1f s", HJAudioPlayerManager.sharedManager.playDuration];
    self.v.bufferSize.text = [NSString stringWithFormat:@"当前播放时间：%.1f s", HJAudioPlayerManager.sharedManager.playTime];
    self.v.bufferTimeLabel.text = [NSString stringWithFormat:@"缓冲时间：%.1f s", HJAudioPlayerManager.sharedManager.totalBufferTime];
}

- (void)dealloc {
    [self removeObservers];
}
@end


//@"http://download.lingyongqian.cn/music/ForElise.mp3",
//@"http://mpge.5nd.com/2018/2018-1-23/74521/1.mp3",
//@"http://download.lingyongqian.cn/music/AdagioSostenuto.mp3",
//@"http://vfx.mtime.cn/Video/2018/05/15/mp4/180515210431224977.mp4",


//    [HJAudioPlayerManager.sharedManager hj_playWithURLStringArray:@[
//                                                                    @"http://sc1.111ttt.cn/2018/1/03/13/396131232171.mp3",
//                                                                    @"http://sc1.111ttt.cn/2018/1/03/13/396131212186.mp3",
//                                                                    @"http://sc1.111ttt.cn/2018/1/03/13/396131226156.mp3",
//                                                                    @"http://sc1.111ttt.cn/2018/1/03/13/396131225385.mp3",
//                                                                    @"http://sc1.111ttt.cn/2018/1/03/13/396131203208.mp3",
//                                                                    @"http://sc1.111ttt.cn/2018/1/03/13/396131229550.mp3",
//                                                                    @"http://download.lingyongqian.cn/music/ForElise.mp3",
//                                                                    @"http://mpge.5nd.com/2018/2018-1-23/74521/1.mp3",
//                                                                    @"http://download.lingyongqian.cn/music/AdagioSostenuto.mp3",
//                                                                    @"http://vfx.mtime.cn/Video/2018/05/15/mp4/180515210431224977.mp4"
//                                                                    ]
//                                                        cachePath:@""];
