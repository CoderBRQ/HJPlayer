//
//  HJApplication.m
//  HJAudioPlayerDemo
//
//  Created by bianrongqiang on 5/30/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#import "HJApplication.h"
#import "HJAudioPlayerManager.h"

@implementation HJApplication
- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    if (event.type == UIEventTypeRemoteControl) {
        switch (event.subtype) {
            case UIEventSubtypeRemoteControlPlay:
                [HJAudioPlayerManager.sharedManager hj_play];
                break;
            case UIEventSubtypeRemoteControlPause:
                [HJAudioPlayerManager.sharedManager hj_pause];
                break;
            case UIEventSubtypeRemoteControlStop:
                [HJAudioPlayerManager.sharedManager hj_stop];
                break;
            case UIEventSubtypeRemoteControlTogglePlayPause:
            {
                //播放暂停切换键：103
                if (HJAudioPlayerManager.sharedManager.status == HJPlayerStatusPausing) {
                    [HJAudioPlayerManager.sharedManager hj_restart];
                }else{
                    [HJAudioPlayerManager.sharedManager hj_pause];
                }
            }
                break;
            case UIEventSubtypeRemoteControlNextTrack:
                //双击暂停键（下一曲）：104
                [HJAudioPlayerManager.sharedManager hj_next];
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                //三击暂停键（上一曲）：105
                [HJAudioPlayerManager.sharedManager hj_last];
                break;
            case UIEventSubtypeRemoteControlBeginSeekingBackward:
                //三击不松开（快退开始）：106
                break;
            case UIEventSubtypeRemoteControlEndSeekingBackward:
                //三击到了快退的位置松开（快退停止）：107
                break;
            case UIEventSubtypeRemoteControlBeginSeekingForward:
                //两击不要松开（快进开始）：108
                break;
            case UIEventSubtypeRemoteControlEndSeekingForward:
                //两击到了快进的位置松开（快进停止）：109
                break;
            default:
                break;
        }
    }
}
@end
