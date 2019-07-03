//
//  HJPlayerDownloaderOperation.m
//  NSOperationDemo
//
//  Created by bianrongqiang on 6/4/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#import "HJPlayerDownloaderOperation.h"
#import "HJPlayerCompat.h"
#import "HJPlayerError.h"


@interface HJPlayerDownloaderOperation ()

#pragma mark - properties in protocol

@property (strong, nonatomic, nullable, readwrite) NSURLRequest *request;
@property (strong, nonatomic, nullable, readwrite) NSURLResponse *response;
@property (strong, nonatomic, readwrite, nullable) NSURLSessionTask *dataTask;

#pragma mark - private properties

@property (nonatomic, assign, getter=isExecuting) BOOL executing;
@property (nonatomic, assign, getter=isFinished) BOOL finished;
// This is weak because it is injected by whoever manages this session. If this gets nil-ed out, we won't be able to run.the task associated with this operation
@property (weak, nonatomic, nullable) NSURLSession *unownedSession;
// This is set if we're using not using an injected NSURLSession. We're responsible of invalidating this one
@property (strong, nonatomic, nullable) NSURLSession *ownedSession;
@property (assign, nonatomic) NSUInteger totalSize; // may be 0
@property (strong, nonatomic, nullable) NSError *responseError;
@property (nonatomic, copy, nullable) HJPlayerLoaderResponseBlock responseBlock;
@property (nonatomic, copy, nullable) HJPlayerDownloaderProgressBlock progressBlock;
@property (nonatomic, copy, nullable) HJPlayerDownloaderCompltedBlock completeBlock;
@property (nonatomic, assign) NSUInteger currentOffset;

@end

@implementation HJPlayerDownloaderOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

#pragma mark - HJPlayerDownloaderOperation protocol

- (nonnull instancetype)initWithRequest:(nullable NSURLRequest *)request
                              inSession:(nullable NSURLSession *)session
                               response:(nullable HJPlayerLoaderResponseBlock)responseBlock
                               progress:(nullable HJPlayerDownloaderProgressBlock)progressBlock
                              completed:(nullable HJPlayerDownloaderCompltedBlock)completedBlock {
    if (self = [super init]) {
        _request = request;
        _executing = NO;
        _finished = NO;
        _totalSize = 0;
        _unownedSession = session;
        _responseBlock = responseBlock;
        _progressBlock = progressBlock;
        _completeBlock = completedBlock;
        
        NSString *contentRange = [_request valueForHTTPHeaderField:@"Range"];
        NSRange startRange = [contentRange rangeOfString:@"="];
        NSRange endRange = [contentRange rangeOfString:@"-"];
        NSRange range = NSMakeRange(startRange.location + startRange.length, endRange.location - startRange.location - startRange.length);
        _currentOffset = [[contentRange substringWithRange:range] integerValue];
    }
    return self;
}

#pragma mark - over load
// 重写start方法，main方法可选，如果在start方法中定义了你的任务，则main方法就可以不实现
- (void)start {
    @synchronized (self) {
        if (self.isCancelled) {
            self.finished = YES;
            [self reset];
            return;
        }
        NSURLSession *session = self.unownedSession;
        if (!session) {
            NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
            sessionConfig.timeoutIntervalForRequest = 15;
            
            /**
             *  Create the session for this task
             *  We send nil as delegate queue so that the session creates a serial operation queue for performing all delegate
             *  method calls and completion handler calls.
             */
            session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                    delegate:self
                                               delegateQueue:nil];
            self.ownedSession = session;
        }
        self.dataTask = [session dataTaskWithRequest:self.request];
        self.executing = YES;
    }
    
    if (self.dataTask) {
        [self.dataTask resume];
        
    } else {
        NSError *error = [NSError errorWithDomain:HJPlayerErrorDomain
                                             code:HJPlayerErrorInvalidDownloadOperation
                                         userInfo:@{NSLocalizedDescriptionKey : @"Task can't be initialized"}];
        _completeBlock(error, _request, _response, _currentOffset, _totalSize);
        
        [self done];
    }
}

- (BOOL)isConcurrent {return YES;}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)cancel {
    @synchronized (self) {
        [self cancelInternal];
    }
}

#pragma mark - private method

- (void)cancelInternal {
    if (self.isFinished) return;
    [super cancel];// // this behavior allows the operation queue to call the operation’s start method sooner and clear the object out of the queue.
    
    if (self.dataTask) {
        // This method returns immediately, marking the task as being canceled. Once a task is marked as being canceled, URLSession:task:didCompleteWithError: will be sent to the task delegate, passing an error in the domain NSURLErrorDomain with the code NSURLErrorCancelled.
        [self.dataTask cancel];
        
        // As we cancelled the task, its callback won't be called and thus won't
        // maintain the isFinished and isExecuting flags.
        if (self.isExecuting) self.executing = NO;
        if (!self.isFinished) self.finished = YES;
    }
    
    [self reset];
}

- (void)done {
    self.finished = YES;
    self.executing = NO;
    [self reset];
}

- (void)reset {
    @synchronized (self) {
        self.dataTask = nil;
        if (self.ownedSession) {
            [self.ownedSession invalidateAndCancel];
            self.ownedSession = nil;
        }
    }
}

#pragma mark NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse * _Nullable))completionHandler {
    completionHandler(nil);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    NSURLSessionResponseDisposition disposition = NSURLSessionResponseAllow;
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSString *contentRange = httpResponse.allHeaderFields[@"Content-Range"];
    NSRange startRange = [contentRange rangeOfString:@"/"];
    NSInteger totalSize = [[contentRange substringFromIndex:startRange.location + 1] integerValue];
    totalSize = totalSize > 0 ? totalSize : 0;
    self.totalSize = totalSize;
    self.response = response;
    NSInteger statusCode = [response respondsToSelector:@selector(statusCode)] ? ((NSHTTPURLResponse *)response).statusCode : 200;
    BOOL valid = statusCode >= 200 && statusCode < 400;
    if (!valid) {
        self.responseError = [NSError errorWithDomain:HJPlayerErrorDomain
                                                 code:HJPlayerErrorInvalidDownloadStatusCode
                                             userInfo:@{HJPlayerErrorDownloadStatusCodeKey : @(statusCode)}];
    }
    
    if (!valid) {
        // Status code invalid and marked as cancelled. Do not call `[self.dataTask cancel]` which may mass up URLSession life cycle
        disposition = NSURLSessionResponseCancel;
    }else {
        if (self.responseBlock) {
            self.responseBlock(_totalSize, _request);
        }
    }
    if (completionHandler) {
        completionHandler(disposition);
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    completionHandler(request);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    
    if (data.length == 0) {
        NSError *error = [NSError errorWithDomain:HJPlayerErrorDomain code:HJPlayerErrorBadData userInfo:@{NSLocalizedDescriptionKey : @"Data is nil"}];
        dispatch_main_async_safe(^{
            self->_completeBlock(error, self->_request, self.response, self.currentOffset, self.totalSize);
        })
        return;
    }
    NSUInteger startOffset = self.currentOffset;
    dispatch_main_async_safe(^{
        if (self.progressBlock) {
            self.progressBlock(data,startOffset, data.length, self.totalSize, self.request);
        }
    })
    self.currentOffset += data.length;
}

#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    @synchronized(self) {
        self.dataTask = nil;
    }
    // make sure to call `[self done]` to mark operation as finished
    if (error) {
        // custom error instead of URLSession error
        if (self.responseError) {
            error = self.responseError;
        } 
        dispatch_main_async_safe(^{
            if (self.completeBlock) {
                self->_completeBlock(error, self.request, self.response, self.currentOffset, self.totalSize);
            }
        })
        [self done];
    } else {
        dispatch_main_async_safe(^{
            if (self.completeBlock) {
                self->_completeBlock(nil, self.request, self.response, self.currentOffset, self.totalSize);
            }
        })
        [self done];
    }
}

@end
