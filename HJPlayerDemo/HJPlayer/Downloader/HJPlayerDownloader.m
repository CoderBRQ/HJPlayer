//
//  HJPlayerDownloader.m
//  NSOperationDemo
//
//  Created by bianrongqiang on 6/1/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#import "HJPlayerDownloader.h"
#import "HJPlayerDownloaderOperation.h"
#import "HJInternalMacors.h"
#import "HJPlayerError.h"

@interface HJPlayerDownloader ()

@property (nonatomic, strong, nonnull) dispatch_semaphore_t operationsLock;
@property (nonatomic, strong, nonnull) NSOperationQueue *downloadQueue;

@end

@implementation HJPlayerDownloader

#pragma mark - shared instance
+ (instancetype)sharedDownloader {
    static HJPlayerDownloader *_sharedDownloader;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedDownloader = [[super allocWithZone:NULL] init];
    });
    return _sharedDownloader;
}

+ (instancetype)allocWithZone:(NSZone *)zone {
    return [self sharedDownloader];
}

- (instancetype)init {
    if (self = [super init]) {
        _operationsLock = dispatch_semaphore_create(1);
    }
    return self;
}

#pragma mark - public methods
- (void)downloadDataWithRequest:(nullable NSURLRequest *)request
                       response:(nullable HJPlayerLoaderResponseBlock)responseBlock
                       progress:(nullable HJPlayerDownloaderProgressBlock)progressBlock
                      completed:(nullable HJPlayerDownloaderCompltedBlock)completedBlock {
    HJ_LOCK(self.operationsLock);
    if (request.URL == nil) {
        if (completedBlock) {
            NSError *error = [NSError errorWithDomain:HJPlayerErrorDomain code:HJPlayerErrorInvalidURL userInfo:@{NSLocalizedDescriptionKey : @"Data url is nil"}];
            completedBlock(error, request, nil, 0, 0);
        }
        return ;
    }
    if (_downloadQueue == nil) {
        _downloadQueue = [[NSOperationQueue alloc] init];
        _downloadQueue.maxConcurrentOperationCount = 1;
    }
    NSURLSession *session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration];
    HJPlayerDownloaderOperation<HJPlayerDownloaderOperation> *operation;
    operation = [[HJPlayerDownloaderOperation alloc]
                 initWithRequest:request
                 inSession:session
                 response:responseBlock
                 progress:progressBlock
                 completed:completedBlock];
    [_downloadQueue addOperation:operation];
    HJ_UNLOCK(self.operationsLock);
}

- (void)cancelAllDownloads {
    // 已经加入队列，并等待执行的操作，队列必须尝试执行，执行之前判断取消、完成状态。
    // 对于正在执行的操作，操作对象本身必须检查取消、完成状态。这样做的目的是，在这两种情况下，一个完成了（或取消了）的操作仍有机会在操作从队列移除之前，回调block。
    [_downloadQueue cancelAllOperations];
}

- (NSUInteger)currentDownloadCount {
    return self.downloadQueue.operationCount;
}

@end
