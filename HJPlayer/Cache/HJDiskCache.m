//
//  HJDiskCache.m
//  HJAudioPlayerDemo
//
//  Created by bianrongqiang on 6/17/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#import "HJDiskCache.h"
#import <CommonCrypto/CommonDigest.h>
#import "HJCacheConfig.h"

@interface HJDiskCache ()

@property (nonatomic, copy) NSString *diskCachePath;
@property (nonatomic, strong, nonnull) NSFileManager *fileManager;
@property (nonatomic, strong, nullable) dispatch_io_t writeOnlyChannel;
@property (nonatomic, strong, nullable) dispatch_io_t readOnlyChannel;

@end

@implementation HJDiskCache

#pragma mark - HJDiskCache protocol

- (nullable instancetype)initWithCachePath:(nonnull NSString *)cachePatch
                                    config:(nonnull HJCacheConfig *)config {
    NSParameterAssert(cachePatch);
    NSParameterAssert(config);
    if (self = [super init]) {
        _diskCachePath = cachePatch;
        _config =config;
        if (self.config.fileManager) {
            self.fileManager = self.config.fileManager;
        }else {
            self.fileManager = [NSFileManager new];
        }
    }
    
    return self;
}

- (nullable NSString *)cachePathForKey:(nonnull NSString *)key {
    NSParameterAssert(key);
    return [self cachePathForKey:key inPath:self.diskCachePath];
}

- (BOOL)containsDataForKey:(nonnull NSString *)key {
    NSParameterAssert(key);
    NSString *filePath = [self cachePathForKey:key];
    BOOL exists = [self.fileManager fileExistsAtPath:filePath];
    return exists;
}

- (void)removeAllData {
    [self.fileManager removeItemAtPath:self.diskCachePath error:nil];
    [self.fileManager createDirectoryAtPath:self.diskCachePath
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:NULL];
}

- (void)removeDataForKey:(nonnull NSString *)key {
    NSParameterAssert(key);
    NSString *filePath = [self cachePathForKey:key];
    [self.fileManager removeItemAtPath:filePath error:nil];
}

- (NSUInteger)totalCount {
    NSUInteger count = 0;
    NSDirectoryEnumerator *fileEnumerator = [self.fileManager enumeratorAtPath:self.diskCachePath];
    count = fileEnumerator.allObjects.count;
    return count;
}

- (NSUInteger)totalSize {
    NSUInteger size = 0;
    NSDirectoryEnumerator *fileEnumerator = [self.fileManager enumeratorAtPath:self.diskCachePath];
    for (NSString *fileName in fileEnumerator) {
        NSString *filePath = [self.diskCachePath stringByAppendingPathComponent:fileName];
        NSDictionary<NSString *, id> *attrs = [self.fileManager attributesOfItemAtPath:filePath error:nil];
        size += [attrs fileSize];
    }
    return size;
}

- (void)writeDataForKey:(nonnull NSString *)key
            startOffset:(NSUInteger)startOffset
                   data:(NSData *)data
             completion:(WriteDataCompletionBlock)completion{
    
    if (![self.fileManager fileExistsAtPath:_diskCachePath]) {
        [self.fileManager createDirectoryAtPath:_diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    NSString *filePath = [self cachePathForKey:key inPath:_diskCachePath];
    
    if  (![self.fileManager fileExistsAtPath:filePath]) {
        [self.fileManager createFileAtPath:filePath contents:nil attributes:nil];
    }
    
    dispatch_io_t writeOnlyChannel = [self getChannelWithType:O_WRONLY filePath:filePath];
    
    dispatch_data_t cdata = dispatch_data_create(data.bytes, data.length, NULL, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
    
    dispatch_io_write(writeOnlyChannel,
                      startOffset,// offset
                      cdata,// data
                      dispatch_get_main_queue(),// IO header should submit
                      ^(bool done, dispatch_data_t  _Nullable data, int error) {// handler block
                          completion(done, error);
                      });
}

- (void)readDataForKey:(nonnull NSString *)key
           startOffset:(off_t)startOffset
              dataSize:(size_t)dataSize
      ioReadCompletion:(IOReadCompletionBlock)ioReadCompletion
   dataApplyCompletion:(DataApplyCompletionBlock)dataApplyCompletion {
    
    NSString *filePath = [self cachePathForKey:key inPath:_diskCachePath];
    dispatch_io_t readOnlyChannel = [self getChannelWithType:O_RDONLY filePath:filePath];
    /*
     * Dispatch I/O handlers are not reentrant. The system will ensure that no new
     * I/O handler instance is invoked until the previously enqueued handler block
     * has returned.
     */
    dispatch_io_read(readOnlyChannel,
                     startOffset,
                     dataSize,
                     dispatch_get_main_queue(),
                     ^(bool done, dispatch_data_t data, int error){
                         
                         ioReadCompletion(done, data, error);
                         
                         // Traverse the memory regions represented by the specified dispatch data object in logical order and invoke the specified block once for every contiguous memory region encountered.
                         dispatch_data_apply(data, (dispatch_data_applier_t)^(dispatch_data_t region,
                                                                              size_t offset, const void *buffer, size_t size){
                             
                             return dataApplyCompletion(done, error, region, offset, buffer, size);
                         });
                         
                     });
}


- (size_t)fileSizeForKey:(nonnull NSString *)key {
    
    if (![self.fileManager fileExistsAtPath:_diskCachePath]) {
        return 0;
    }
    
    NSString *filePath = [self cachePathForKey:key inPath:_diskCachePath];
    
    if  (![self.fileManager fileExistsAtPath:filePath]) {
        return 0;
    }
    NSInteger size = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil][NSFileSize] integerValue];
    
    return size;
}

- (nullable NSString *)filePathForKey:(nonnull NSString *)key {
    NSParameterAssert(key);
    if (![self.fileManager fileExistsAtPath:_diskCachePath]) {
        return nil;
    }
    NSString *filePath = [self cachePathForKey:key inPath:_diskCachePath];
    
//    NSLog(@"%@", filePath);
    
    if  (![self.fileManager fileExistsAtPath:filePath]) {
        return nil;
    }
    return [self cachePathForKey:key inPath:_diskCachePath];
}

- (nullable NSString *)fileNameForKey:(nonnull NSString *)key {
    return HJDiskCacheFileNameForKey(key);
}

#pragma mark - plist file operation
- (NSUInteger)getFileLengthInLocalPlistFileForKey:(nonnull NSString *)key {
    NSParameterAssert(key);
    NSString *filePatch = [_diskCachePath stringByAppendingPathComponent:@"HJPlayerFileInfo.plist"];
    NSMutableDictionary *sandBoxDataDic = [[NSMutableDictionary alloc] initWithContentsOfFile:filePatch];
    NSString *fileName = [self fileNameForKey:key];
    NSNumber *length = sandBoxDataDic[fileName];
    return length.unsignedIntegerValue;
}

- (void)writeFileLengthToLocalPlistForKey:(nonnull NSString *)key fileLength:(NSUInteger)length {
    NSParameterAssert(key);
    NSUInteger size = [self getFileLengthInLocalPlistFileForKey:key];
    if (size) {
        return;
    }
    NSString *filePath = [_diskCachePath stringByAppendingPathComponent:@"HJPlayerFileInfo.plist"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableDictionary *sandBoxDataDic;
    if  ([fileManager fileExistsAtPath:filePath]) {
        sandBoxDataDic = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
    }else{
        sandBoxDataDic = [[NSMutableDictionary alloc] init];
    }
    NSString *fileName = [self fileNameForKey:key];
    [sandBoxDataDic setObject:@(length) forKey:fileName];
    [sandBoxDataDic writeToFile:filePath atomically:YES];
}


- (NSArray<NSNumber *> *)getDownloadRangeInLocalPlistFileForKey:(nonnull NSString *)key loaingRequestRange:(NSArray<NSNumber *> *)loaingRequestRange {
    NSParameterAssert(key);
    
    NSString *filePath = [_diskCachePath stringByAppendingPathComponent:@"HJPlayerFileDownloadInfo.plist"];
    NSString *fileName = [self fileNameForKey:key];
    // 本地的
    NSMutableDictionary *fileDownloadInfo = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
    NSArray *infos = fileDownloadInfo[fileName];
    // 传入的
    NSMutableArray *t = [loaingRequestRange mutableCopy];
    NSNumber *tStart = t[0];
    NSNumber *tEnd = t[1];
    // 要返回的
    NSMutableArray *tmpA = [[NSMutableArray alloc] init];
    for (int i = 0; i < infos.count; i++) {
        NSArray *ranges = infos[i];
        NSNumber *start = ranges[0];
        NSNumber *end = ranges[1];
        // 比较
        if (tStart.integerValue > end.integerValue || tEnd.integerValue < start.integerValue) {// 没有交集
            // 如果全都没有交集表示一点都没下载
            tmpA[0] = tStart;
            tmpA[1] = tEnd;
        }else if (tStart.integerValue >= start.integerValue && tEnd.integerValue <= end.integerValue){// 有交集,交集为本身，表示全下载完了
            return [NSMutableArray new];
        }else {// 有交集，但交集不为本身，表示，有部分未下载。按原先的请求下载，覆盖不全的数据部分
            tmpA[0] = tStart;
            tmpA[1] = tEnd;
        }
    }
    return tmpA;
}


- (void)updateDownloadRangeInLocalPlistFileForKey:(nonnull NSString *)key responseRange:(NSArray<NSNumber *> *)responseRange {
    NSParameterAssert(key);
    NSString *filePath = [_diskCachePath stringByAppendingPathComponent:@"HJPlayerFileDownloadInfo.plist"];
    NSString *fileName = [self fileNameForKey:key];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // 本地的
    NSMutableDictionary *fileDownloadInfo;
    if  ([fileManager fileExistsAtPath:filePath]) {
        fileDownloadInfo = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
    }else{
        fileDownloadInfo = [[NSMutableDictionary alloc] init];
    }
    NSArray *infos = fileDownloadInfo[fileName];
    // 传入的
    NSMutableArray *t = [responseRange mutableCopy];
    NSNumber *tStart = t[0];
    NSNumber *tEnd = t[1];
    // 要存的
    NSMutableArray *tmpA = [[NSMutableArray alloc] init];
    for (int i = 0; i < infos.count; i++) {
        NSArray *ranges = infos[i];
        NSNumber *start = ranges[0];
        NSNumber *end = ranges[1];
        // 比较
        if (tStart.integerValue - end.integerValue == 1 || start.integerValue - tEnd.integerValue == 1) {// 没有交集，但是连续的，取并集
            tStart = @(MIN(tStart.integerValue, start.integerValue));
            tEnd= @(MAX(tEnd.integerValue, end.integerValue));
        }else if (tStart.integerValue > end.integerValue || tEnd.integerValue < start.integerValue) {// 没有交集也不连续
            [tmpA addObject:ranges];
        }else{// 有交集, 取并集
            tStart = @(MIN(tStart.integerValue, start.integerValue));
            tEnd= @(MAX(tEnd.integerValue, end.integerValue));
        }
    }
    [tmpA addObject:@[tStart, tEnd]];
    // Update plist.
    [fileDownloadInfo setObject:tmpA forKey:fileName];
    [fileDownloadInfo writeToFile:filePath atomically:YES];
}
#pragma mark - Cache paths

- (nullable NSString *)cachePathForKey:(nullable NSString *)key inPath:(nonnull NSString *)path {
    NSParameterAssert(key);
    NSParameterAssert(path);
    NSString *fileName = HJDiskCacheFileNameForKey(key);
    return [path stringByAppendingPathComponent:fileName];
}

#pragma mark - file name

#define HJ_MAX_FILE_EXTENSION_LENGTH (NAME_MAX - CC_MD5_DIGEST_LENGTH * 2 - 1)
static inline NSString * _Nonnull HJDiskCacheFileNameForKey(NSString * _Nullable key) {
    const char *str = key.UTF8String;
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSURL *keyURL = [NSURL URLWithString:key];
    NSString *ext = keyURL ? keyURL.pathExtension : key.pathExtension;
    // File system has file name length limit, we need to check if ext is too long, we don't add it to the filename
    if (ext.length > HJ_MAX_FILE_EXTENSION_LENGTH) {
        ext = nil;
    }
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%@",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
                          r[11], r[12], r[13], r[14], r[15], ext.length == 0 ? @"" : [NSString stringWithFormat:@".%@", ext]];
    return filename;
}

#pragma mark - create channel with type and file path.
- (dispatch_io_t)getChannelWithType:(int)type filePath:(nonnull NSString *)filePath{
    NSParameterAssert(filePath);
    switch (type) {
        case O_WRONLY:
        {
            if (self.writeOnlyChannel) {
                return self.writeOnlyChannel;
            }
        }
            break;
        case O_RDONLY:
        {
            if (self.readOnlyChannel) {
                return self.readOnlyChannel;
            }
        }
        default:
            break;
    }
    
    dispatch_io_t channel = dispatch_io_create_with_path(DISPATCH_IO_RANDOM,
                                                         [filePath UTF8String],
                                                         type,
                                                         0,
                                                         dispatch_get_main_queue(),
                                                         ^(int error) {
        // Cleanup code for normal channel operation.
        // Assumes that dispatch_io_close was called elsewhere.
        switch (type) {
            case O_WRONLY:
            {
                self.writeOnlyChannel = nil;
            }
                break;
            case O_RDONLY:
            {
                self.readOnlyChannel = nil;
            }
            default:
                break;
        }
    });
    
    switch (type) {
        case O_WRONLY:
        {
            self.writeOnlyChannel = channel;
        }
            break;
        case O_RDONLY:
        {
            self.readOnlyChannel = channel;
        }
        default:
            break;
    }
    
    return channel;
}
@end
//dispatch_io_close(self.channel, 0x0);
