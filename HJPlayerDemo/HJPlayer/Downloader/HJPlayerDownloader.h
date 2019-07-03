//
//  HJPlayerDownloader.h
//  NSOperationDemo
//
//  Created by bianrongqiang on 6/1/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^HJPlayerLoaderResponseBlock)(NSUInteger totalSize, NSURLRequest *request);
typedef void(^HJPlayerLoaderProgressBlock)(NSData *data, NSUInteger startOffset, NSInteger receivedSize, NSInteger totalSize, NSURLRequest *request);
typedef void(^HJPlayerLoaderCompletedBlock)(NSError * _Nullable error, NSURLRequest *request, NSURLResponse *response, NSUInteger currentOffset, NSInteger totalSize);

typedef HJPlayerLoaderResponseBlock HJPlayerDownloaderResponseBlock;
typedef HJPlayerLoaderProgressBlock HJPlayerDownloaderProgressBlock;
typedef HJPlayerLoaderCompletedBlock HJPlayerDownloaderCompltedBlock;

@protocol HJPlayerDownloader <NSObject>

- (void)downloadDataWithRequest:(nullable NSURLRequest *)request
                       response:(nullable HJPlayerLoaderResponseBlock)responseBlock
                       progress:(nullable HJPlayerDownloaderProgressBlock)progressBlock
                      completed:(nullable HJPlayerDownloaderCompltedBlock)completedBlock;

/**
 * Cancels all download operations in the queue
 */
- (void)cancelAllDownloads;

- (NSUInteger)currentDownloadCount;
@end

@interface HJPlayerDownloader : NSObject<HJPlayerDownloader>

@property (nonatomic, class, readonly, nullable) HJPlayerDownloader *sharedDownloader;

@end


