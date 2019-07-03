//
//  HJCache.m
//  HJAudioPlayerDemo
//
//  Created by bianrongqiang on 6/16/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#import "HJCache.h"
#import "HJDiskCache.h"

@interface HJCache ()

@property (nonatomic, copy, readwrite, nonnull) HJCacheConfig *config;
@property (nonatomic, copy, readwrite, nonnull) NSString *diskCachePath;
@property (nonatomic, strong, nonnull) id<HJDiskCache> diskCache;
@property (nonatomic, strong, nullable) dispatch_queue_t ioQueue;

@end

@implementation HJCache

#pragma mark - Singleton, init

+ (HJCache *)sharedCache {
    static HJCache *_cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _cache = [HJCache new];
    });
    return _cache;
}

- (instancetype)init {
    return [self initWithNameSpace:@"default" diskCacheDirectory:nil config:nil];
}


- (instancetype)initWithNameSpace:(nonnull NSString *)nameSpace diskCacheDirectory:(nullable NSString *)directory config:(nullable HJCacheConfig *)config {
    NSParameterAssert(nameSpace);
    self = [super init];
    if (self) {
        _ioQueue = dispatch_queue_create("com.hibrq.HJCache", DISPATCH_QUEUE_SERIAL);
        
        if (!config) {
            config = HJCacheConfig.defaultCacheConfig;
        }
        _config = [config copy];
        
        NSAssert([_config.diskCacheClass conformsToProtocol:@protocol(HJDiskCache)], @"Custom disk cache class must conform to `HJDiskCache` protocol");
    
        if (directory.length > 0) {
            _diskCachePath = [directory stringByAppendingPathComponent:nameSpace];
        }else {
            NSString *path = [[[self userCacheDirectory]
                               stringByAppendingPathComponent:@"com.hibrq.HJCache"]
                              stringByAppendingPathComponent:nameSpace];
            
            _diskCachePath = path;
        }
        
        _diskCache = [[config.diskCacheClass alloc] initWithCachePath:_diskCachePath config:_config];
    }
    
    return self;
}

#pragma mark - private method
- (nullable NSString *)userCacheDirectory {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return paths.firstObject;
}

#pragma mark - HJCache protocol method

- (NSUInteger)totalDiskSize {
    __block NSUInteger size = 0;
    dispatch_sync(self.ioQueue, ^{
        size = [self.diskCache totalSize];
    });
    return size;
}

- (NSUInteger)totalDiskCount {
    __block NSUInteger count = 0;
    dispatch_sync(self.ioQueue, ^{
        count = [self.diskCache totalCount];
    });
    return count;
}

- (void)calculateSizeWithCompletionBlock:(nullable HJPlayerCaculateCacheSizeBlock)completionBlock {
    dispatch_async(self.ioQueue, ^{
        NSUInteger size = [self.diskCache totalSize];
        NSUInteger count = [self.diskCache totalCount];
        if (completionBlock) {
            completionBlock(size, count);
        }
    });
}

- (size_t)fileSizeWithFileURL:(nullable NSURL *)url {
    if (!url) {
        return 0;
    }
    __block size_t size = 0;
    dispatch_sync(self.ioQueue, ^{
        size = [self.diskCache fileSizeForKey:url.absoluteString];
    });
    return size;
}

- (void)fileSizeWithFileURL:(nullable NSURL *)url completed:(void(^)(size_t size))completedBlock {
    if (!url) {
        completedBlock(0);
    }
    __block size_t size = 0;
    dispatch_async(self.ioQueue, ^{
        size = [self.diskCache fileSizeForKey:url.absoluteString];
    });
    completedBlock(size);
}

- (nullable NSString *)filePathWithFileURL:(nullable NSURL *)url {
    if (!url) {
        return nil;
    }
    
    return [self.diskCache filePathForKey:url.absoluteString];
}

- (nullable NSString *)fileNameWithFileURL:(nullable NSURL *)url {
    return [self.diskCache fileNameForKey:url.absoluteString];
}

- (BOOL)diskDataExistsWithKey:(nullable NSString *)key {
    if (!key) {
        return NO;
    }
    __block BOOL exists = NO;
    dispatch_sync(self.ioQueue, ^{
        exists = [self.diskCache containsDataForKey:key];
    });
    return exists;
}

- (void)clearAllDataOnCompletion:(nullable HJPlayerNoParamsBlock)completionBlock {
    dispatch_async(self.ioQueue, ^{
        [self.diskCache removeAllData];
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock();
            });
        }
    });
}

- (void)removeDataWithFileURL:(nullable NSURL *)url completion:(nullable HJPlayerNoParamsBlock)completionBlock {
    
    if (!url) {
        return;
    }
    dispatch_async(self.ioQueue, ^{
        [self.diskCache removeDataForKey:url.absoluteString];
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock();
            });
        }
    });
}

- (void)writeDataToDiskWithURL:(nonnull NSURL *)url
                   startOffset:(NSUInteger)startOffset
                          data:(nonnull NSData *)data
                    completion:(nullable HJWriteDataCompletionBlock)completion {
    
    [self.diskCache writeDataForKey:url.absoluteString
                        startOffset:startOffset
                               data:data
                         completion:^(bool done, int error) {
        
        if (!completion) {
            return;
        }
        
        if (done && error == 0) {// Write data is complete.
            completion(HJWriteDataStatusComplete);
        }else if (done && error != 0) {// an unrecoverable error occurs on the channel’s file descriptor
            completion(HJWriteDataStatusFailed);
        }else {// Only part of the data was written.
            completion(HJWriteDataStatusPart);
        }
    }];
}

- (void)readDataFromDiskWithURL:(nonnull NSURL *)url
                    startOffset:(NSUInteger)startOffset
                       dataSize:(NSUInteger)dataSize
                 ioReadCompletion:(nullable HJReadDataCompletionBlock)ioReadCompletion
            dataApplyCompletion:(nullable HJDataApplyCompletionBlock)dataApplyCompletion{
    
    static size_t readSize = 0;
    readSize = 0;
    
    [self.diskCache readDataForKey:url.absoluteString
                       startOffset:startOffset
                          dataSize:dataSize
                  ioReadCompletion:^(bool done, dispatch_data_t data, int error){
                      // If an unrecoverable error occurs on the channel’s file descriptor, the done parameter is set to YES and an appropriate error value is reported in the handler’s error parameter.
                      if (done && error != 0) {
                          ioReadCompletion(HJReadDataStatusFaild);
                      }
                      
                      // If the done parameter is set to YES, it means the read operation is complete and the handler will not be submitted again.
                      // If the handler is submitted with the done parameter set to YES, an empty data object, and an error code of 0, it means that the channel reached the end of the file.
                      if (done && error == 0 && dispatch_data_get_size(data) == 0 && readSize == 0){
                          ioReadCompletion(HJReadDataStatusNoData);
                          return;
                      }
                      
                      // Read operation is complete and the handler will not be submitted again.
                      // An data object is not empty, but the file which current reading is not complete.
                      if (done && error == 0 && dispatch_data_get_size(data) == 0 && readSize < dataSize) {
                          ioReadCompletion(HJReadDataStatusPart);
                      }
                  }
               dataApplyCompletion:^bool(bool done, int error, dispatch_data_t region, size_t offset, const void *buffer, size_t size) {
                   readSize += size;
                   
                   dataApplyCompletion(buffer, size, NO);
                   
                   if (done && error == 0 && readSize >= dataSize){
                       dataApplyCompletion(NULL, 0, YES);
                       return false;
                   }
                   
                   return true;  // Keep processing if there is more data.
               }];
}

- (NSUInteger)queryFileLengthInLocalPlistFileWithURL:(nonnull NSURL *)url {
    NSParameterAssert(url);
    __block NSUInteger length = 0;
    dispatch_sync(self.ioQueue, ^{
        length = [self.diskCache getFileLengthInLocalPlistFileForKey:url.absoluteString];
    });
    return length;
}

- (void)queryFileLengthInLocalPlistFileWithURL:(nonnull NSURL *)url completed:(void (^)(NSUInteger))completedBlock {
    NSParameterAssert(url);
    __block NSUInteger length = 0;
    dispatch_async(self.ioQueue, ^{
        length = [self.diskCache getFileLengthInLocalPlistFileForKey:url.absoluteString];
    });
    completedBlock(length);
}

- (NSArray<NSNumber *> *)queryDownloadFileRangeInLocalPlistWithURL:(nonnull NSURL *)url loadingRequestRange:(NSArray<NSNumber *> *)loadingRequestRange {
    NSParameterAssert(url);
    __block NSArray<NSNumber *> *array;
    dispatch_sync(self.ioQueue, ^{
       array = [self.diskCache getDownloadRangeInLocalPlistFileForKey:url.absoluteString loaingRequestRange:loadingRequestRange];
    });
    return array;
}

- (void)saveFileLengthToLocalPlistWithURL:(nonnull NSURL *)url fileLength:(NSUInteger)length {
    NSParameterAssert(url);
    dispatch_async(self.ioQueue, ^{
        [self.diskCache writeFileLengthToLocalPlistForKey:url.absoluteString fileLength:length];
    });
}

- (void)updateDownloadFileRangeInLocalPlistWithURL:(nonnull NSURL *)url responseRange:(NSArray<NSNumber *> *)responseRange {
    NSParameterAssert(url);
    dispatch_async(self.ioQueue, ^{
        [self.diskCache updateDownloadRangeInLocalPlistFileForKey:url.absoluteString responseRange:responseRange];
    });
}


@end
