//
//  HJDiskCache.h
//  HJAudioPlayerDemo
//
//  Created by bianrongqiang on 6/17/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HJCacheConfig;

typedef void(^WriteDataCompletionBlock)(bool done, int error);
typedef void(^IOReadCompletionBlock)(bool done, dispatch_data_t data, int error);
typedef BOOL(^DataApplyCompletionBlock)(bool done, int error, dispatch_data_t region,
                                          size_t offset, const void *buffer, size_t size);

@protocol HJDiskCache <NSObject>

// All of these method are called from the same global queue to avoid blocking on main queue and thread-safe problem.
@required

- (nullable instancetype)initWithCachePath:(nonnull NSString *)cachePatch
                                    config:(nonnull HJCacheConfig *)config;

- (BOOL)containsDataForKey:(nonnull NSString *)key;

- (void)writeDataForKey:(nonnull NSString *)key
            startOffset:(NSUInteger)startOffset
                   data:(NSData *)data
             completion:(WriteDataCompletionBlock)completion;

- (void)readDataForKey:(nonnull NSString *)key
           startOffset:(off_t)startOffset
              dataSize:(size_t)dataSize
      ioReadCompletion:(IOReadCompletionBlock)ioReadCompletion
   dataApplyCompletion:(DataApplyCompletionBlock)dataApplyCompletion;

- (void)removeDataForKey:(nonnull NSString *)key;

- (void)removeAllData;

- (nullable NSString *)cachePathForKey:(nonnull NSString *)key;

/**
 Returns the number of data in this cache.
 This method may blocks the calling thread until file read finished.
 
 @return The total data count.
 */
- (NSUInteger)totalCount;

/**
 Returns the total size (in bytes) of data in this cache.
 This method may blocks the calling thread until file read finished.
 
 @return The total data size in bytes.
 */
- (NSUInteger)totalSize;

- (size_t)fileSizeForKey:(nonnull NSString *)key;

- (nullable NSString *)filePathForKey:(nonnull NSString *)key;
- (nullable NSString *)fileNameForKey:(nonnull NSString *)key;

#pragma mark - plist
- (NSUInteger)getFileLengthInLocalPlistFileForKey:(nonnull NSString *)key;

- (void)writeFileLengthToLocalPlistForKey:(nonnull NSString *)key fileLength:(NSUInteger)length;

- (NSArray<NSNumber *> *)getDownloadRangeInLocalPlistFileForKey:(nonnull NSString *)key loaingRequestRange:(NSArray<NSNumber *> *)loaingRequestRange;

- (void)updateDownloadRangeInLocalPlistFileForKey:(nonnull NSString *)key responseRange:(NSArray<NSNumber *> *)responseRange;
@end


@interface HJDiskCache : NSObject<HJDiskCache>

- (nonnull instancetype)init NS_UNAVAILABLE;
+ (nonnull instancetype)new NS_UNAVAILABLE;
@property (nonatomic, strong, readonly, nonnull) HJCacheConfig *config;

@end
