//
//  HJPlayerModel.h
//  HJAudioPlayerDemo
//
//  Created by bianrongqiang on 6/7/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface HJPlayerModel : NSObject

/**音频地址*/
@property (nonatomic, nonnull, strong) NSURL *url;

@end

@interface HJPlayerNowPlayingCenterModel : NSObject

/**歌词*/
@property (nonatomic, nullable, copy) NSString *audioLyric;
/**音频名称*/
@property (nonatomic, nullable, copy) NSString *audioName;
/**专辑名称*/
@property (nonatomic, nullable, copy) NSString *audioAlbum;
/**歌手名*/
@property (nonatomic, nullable, copy) NSString *audioSinger;
/**音频配图*/
@property (nonatomic, nullable, copy) UIImage  *audioImage;

@end
