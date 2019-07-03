//
//  HJPlayerDownloaderOperation.h
//  NSOperationDemo
//
//  Created by bianrongqiang on 6/4/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HJPlayerDownloader.h"

@protocol HJPlayerDownloaderOperation <NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

@required
- (nonnull instancetype)initWithRequest:(nullable NSURLRequest *)request
                              inSession:(nullable NSURLSession *)session
                               response:(nullable HJPlayerLoaderResponseBlock)responseBlock
                               progress:(nullable HJPlayerDownloaderProgressBlock)progressBlock
                              completed:(nullable HJPlayerDownloaderCompltedBlock)completedBlock;


/**
 * The request used by the operation's task.
 */
@property (strong, nonatomic, readonly, nullable) NSURLRequest *request;
/**
 * The response returned by the operation's task.
 */
@property (strong, nonatomic, readonly, nullable) NSURLResponse *response;

@optional
/**
 * The operation's task
 */
@property (strong, nonatomic, readonly, nullable) NSURLSessionTask *dataTask;

@end

@interface HJPlayerDownloaderOperation : NSOperation<HJPlayerDownloaderOperation>


@end

