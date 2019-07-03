//
//  HJCacheConfig.h
//  HJAudioPlayerDemo
//
//  Created by bianrongqiang on 6/17/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HJCacheConfig : NSObject<NSCopying>

/**
 Gets the default cache config used for shared instance or initialization when it does not provide and cache config.
 */
@property (nonatomic, class, readonly, nonnull) HJCacheConfig *defaultCacheConfig;

/**
 * The custom file manager for disk cache. Pass nil to let disk cache choose the proper file manager.
 * Defaults to nil.
 * @note This value does not support dynamic changes. Which means further modification on this value after cache initlized has no effect.
 * @note Since `NSFileManager` does not support `NSCopying`. We just pass this by reference during copying. So it's not recommend to set this value on `defaultCacheConfig`.
 */
@property (nonatomic, strong, nullable) NSFileManager *fileManager;

@property (nonatomic, assign, nonnull) Class diskCacheClass;
@end

