//
//  HJPlayer.h
//  HJAudioPlayerDemo
//
//  Created by bianrongqiang on 6/23/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<Player/HJPlayer.h>)

FOUNDATION_EXPORT double HJPlayerVersionNumber;
FOUNDATION_EXPORT const unsigned char HJPlayerVersionString[];

// manager
#import <HJPlayer/HJAudioPlayerManager.h>
#import <HJPlayer/HJDataCapure.h>
#import <HJPlayer/HJApplication.h>
// models
#import <HJPlayer/HJPlayerModel.h>
// down loader
#import <HJPlayer/HJPlayerDownloader.h>
#import <HJPlayer/HJPlayerDownloaderOperation.h>
// cache
#import <HJPlayer/HJCache.h>
#import <HJPlayer/HJDiskCache.h>
#import <HJPlayer/HJCacheConfig.h>
//utils
#import <HJPlayer/HJInternalMacors.h>
#import <HJPlayer/HJPlayerCompat.h>
#import <HJPlayer/HJPlayerError.h>
#import <HJPlayer/HJPlayerOperation.h>
#import <HJPlayer/HJDebugLog.h>

#else

// manager
#import "HJAudioPlayerManager.h"
#import "HJDataCapture.h"
#import "HJApplication.h"
// models
#import "HJPlayerModel.h"
// down loader
#import "HJPlayerDownloader.h"
#import "HJPlayerDownloaderOperation.h"
// cache
#import "HJCache.h"
#import "HJDiskCache.h"
#import "HJCacheConfig.h"
//utils
#import "HJInternalMacors.h"
#import "HJPlayerCompat.h"
#import "HJPlayerError.h"
#import "HJPlayerOperation.h"
#import "HJDebugLog.h"

#endif
