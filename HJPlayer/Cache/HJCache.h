//
//  HJCache.h
//  HJAudioPlayerDemo
//
//  Created by bianrongqiang on 6/16/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJCacheConfig.h"

typedef NS_ENUM(NSInteger, HJWriteDataStatus) {
    HJWriteDataStatusComplete,// Write data is complete.
    HJWriteDataStatusPart,// Only part of the data was written.
    HJWriteDataStatusFailed,// An unrecoverable error occurs on the channel’s file descriptor
};

typedef NS_ENUM(NSInteger, HJReadDataStatus) {
    HJReadDataStatusComplete,// Read suceessfully and completly.
    HJReadDataStatusPart,// Read operation is complete and the handler will not be submitted again. An data object is not empty, but the file which current reading is not complete.
    HJReadDataStatusNoData,// NO data.
    HJReadDataStatusFaild,// If an unrecoverable error occurs on the channel’s file descriptor...
};

typedef void(^HJPlayerNoParamsBlock)(void);
typedef void(^HJPlayerCaculateCacheSizeBlock)(NSUInteger cacheSize, NSUInteger cacheCount);
typedef void(^HJWriteDataCompletionBlock)(HJWriteDataStatus status);
typedef void(^HJReadDataCompletionBlock)(HJReadDataStatus status);
typedef BOOL(^HJDataApplyCompletionBlock)(const void *buffer, size_t size, bool finished);

@protocol HJCache <NSObject>

@required

- (void)removeDataWithFileURL:(nullable NSURL *)url completion:(nullable HJPlayerNoParamsBlock)completionBlock;

/**
 Remove all data.
 
 @param completionBlock A block excuted after the operation is finished.
 */
- (void)clearAllDataOnCompletion:(nullable HJPlayerNoParamsBlock)completionBlock;

- (void)writeDataToDiskWithURL:(nonnull NSURL *)url
                   startOffset:(NSUInteger)startOffset
                          data:(nonnull NSData *)data
                    completion:(nullable HJWriteDataCompletionBlock)completion;

- (void)readDataFromDiskWithURL:(nonnull NSURL *)url
                    startOffset:(NSUInteger)startOffset
                       dataSize:(NSUInteger)dataSize
               ioReadCompletion:(nullable HJReadDataCompletionBlock)ioReadCompletion
            dataApplyCompletion:(nullable HJDataApplyCompletionBlock)dataApplyCompletion;

#pragma mark - the operation of file length in plist file
- (NSUInteger)queryFileLengthInLocalPlistFileWithURL:(nonnull NSURL *)url;

- (void)queryFileLengthInLocalPlistFileWithURL:(nonnull NSURL *)url completed:(void(^)(NSUInteger fileLength))completedBlock;

- (void)saveFileLengthToLocalPlistWithURL:(nonnull NSURL *)url fileLength:(NSUInteger)length;

- (NSArray<NSNumber *> *)queryDownloadFileRangeInLocalPlistWithURL:(nonnull NSURL *)url loadingRequestRange:(NSArray<NSNumber *> *)loadingRequestRange;

- (void)updateDownloadFileRangeInLocalPlistWithURL:(nonnull NSURL *)url responseRange:(NSArray<NSNumber *> *)responseRange;

#pragma mark - Cache Info

/**
 * Synchronously get the total bytes size of images in the disk cache.
 */
- (NSUInteger)totalDiskSize;

/**
 *  Synchronously get the number of images in the disk cache.
 */
- (NSUInteger)totalDiskCount;

/**
 *  Synchronously get the size of data in the disk cache.
 */
- (size_t)fileSizeWithFileURL:(nullable NSURL *)url;

/**
 *  Asynchronously get the size of data in the disk cache.
 */
- (void)fileSizeWithFileURL:(nullable NSURL *)url completed:(void(^)(size_t size))completedBlock;

- (nullable NSString *)filePathWithFileURL:(nullable NSURL *)url;

- (nullable NSString *)fileNameWithFileURL:(nullable NSURL *)url;

- (BOOL)diskDataExistsWithKey:(nullable NSString *)key;

/**
 * Asynchronously calculate the disk cache's size.
 */
- (void)calculateSizeWithCompletionBlock:(nullable HJPlayerCaculateCacheSizeBlock)completionBlock;

@property (nonatomic, copy, nonnull, readonly) NSString *diskCachePath;

@end


@interface HJCache : NSObject<HJCache>

@property (nonatomic, class, nonnull, readonly) HJCache *sharedCache;

@property (nonatomic, copy, nonnull, readonly) HJCacheConfig *config;

- (nonnull instancetype)initWithNameSpace:(nonnull NSString *)nameSpace
                       diskCacheDirectory:(nullable NSString *)directory
                                   config:(nullable HJCacheConfig *)config
                                        NS_DESIGNATED_INITIALIZER;

@end

