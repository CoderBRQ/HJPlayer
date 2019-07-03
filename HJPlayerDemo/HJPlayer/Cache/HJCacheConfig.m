//
//  HJCacheConfig.m
//  HJAudioPlayerDemo
//
//  Created by bianrongqiang on 6/17/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#import "HJCacheConfig.h"
#import "HJDiskCache.h"

//static const NSUInteger kDefaultCacheMaxDiskAge = 365 * 24 * 60 * 60;// one year.

@implementation HJCacheConfig
+ (HJCacheConfig *)defaultCacheConfig {
    static HJCacheConfig *_cacheConfig;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _cacheConfig = [HJCacheConfig new];
    });
    return _cacheConfig;
}

- (instancetype)init {
    if (self = [super init]) {
        _diskCacheClass = [HJDiskCache class];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    HJCacheConfig *config = [[[self class] allocWithZone:zone] init];
    config.diskCacheClass = self.diskCacheClass;
    config.fileManager = self.fileManager;// NSFileManager does not conform to NSCopying protocol, just pass the reference
    return config;
}

@end
