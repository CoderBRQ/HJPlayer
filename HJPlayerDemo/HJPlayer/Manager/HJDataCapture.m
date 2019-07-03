
//
//  HJDataCapture.m
//  HJPlayerDemo2
//
//  Created by bianrongqiang on 6/2/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#import "HJDataCapture.h"
#import "HJPlayerDownloader.h"
#import "HJCache.h"
#import "HJInternalMacors.h"
#import <MobileCoreServices/MobileCoreServices.h>

typedef NSMapTable<NSURLRequest *, id> HJLoadingRequestMapTable;

@interface HJDataCapture ()

@property (nonatomic, strong, nullable) NSMutableArray<HJLoadingRequestMapTable *> *loadingRequests;
@property (nonatomic, strong, nonnull) dispatch_semaphore_t loadingRequestsLock;

@end

@implementation HJDataCapture
+ (instancetype)sharedDataCapture {
    static HJDataCapture *_dataCapture = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dataCapture = [[super allocWithZone:NULL] init];
    });
    return _dataCapture;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self sharedDataCapture];
}

- (instancetype)init {
    if (self = [super init]) {
        _loadingRequests = [NSMutableArray new];
        _loadingRequestsLock = dispatch_semaphore_create(1);
    }
    return self;
}

#pragma mark - HJDataCapture protocol

- (void)captureDataFromDiskWithStartOffset:(off_t)startOffset
                                  dataSize:(size_t)dataSize
                            loadingRequest:(nonnull AVAssetResourceLoadingRequest *)loadingRequest
                             originRequest:(nonnull NSURLRequest *)originRequest {
    
    [self addLoadingRequest:loadingRequest originRequest:originRequest];
    
    [HJCache.sharedCache readDataFromDiskWithURL:originRequest.URL
                                     startOffset:startOffset
                                        dataSize:dataSize
                                ioReadCompletion:^(HJReadDataStatus status) {
        
        switch (status) {
            case HJReadDataStatusFaild:
                break;
            case HJReadDataStatusPart:
                [self captureDataFromNetWithRequestedOffset:startOffset
                                            requestedLength:dataSize
                                             loadingRequest:loadingRequest
                                              originRequest:originRequest];
                break;
            case HJReadDataStatusNoData:
                [self captureDataFromNetWithRequestedOffset:startOffset
                                            requestedLength:dataSize
                                             loadingRequest:loadingRequest
                                              originRequest:originRequest];
                break;
            default:
                break;
        }
    }dataApplyCompletion:^bool(const void *buffer, size_t size, BOOL finished) {
        __block bool isApplying = NO;
        [self getLoadingRequestForRequest:originRequest
                        applyDataFinished:finished
                                   result:^(AVAssetResourceLoadingRequest *obj) {
                                       if (finished) {
                                           NSString *filePath = [HJCache.sharedCache filePathWithFileURL:originRequest.URL];
                                           [self fillContentInfo:filePath loadingRequest:obj originRequest:originRequest];
                                           [obj finishLoading];
                                           isApplying = false;
                                       }else {
                                           NSData *data = [[NSData alloc] initWithBytes:buffer length:size];
                                           [obj.dataRequest respondWithData:data];
                                           isApplying = true;
                                       }
                                   }];
        return isApplying;
    }];
}

- (void)captureDataFromNetWithRequestedOffset:(long long)requestedOffset
                              requestedLength:(NSInteger)requestedLength
                               loadingRequest:(nonnull AVAssetResourceLoadingRequest *)loadingRequest
                                originRequest:(nonnull NSURLRequest *)originRequest {
    NSParameterAssert(loadingRequest);
    NSParameterAssert(originRequest);
    [self addLoadingRequest:loadingRequest originRequest:originRequest];
    HJPlayerLoaderResponseBlock responseBlock = [self createResponseBlock];
    HJPlayerLoaderProgressBlock processBlock = [self createProgressBlock];
    HJPlayerDownloaderCompltedBlock completedBlock = [self createCompleteBlockWithRequestOffset:requestedOffset];
    // download
    [HJPlayerDownloader.sharedDownloader downloadDataWithRequest:originRequest
                                                        response:responseBlock
                                                        progress:processBlock
                                                       completed:completedBlock];
}

#pragma mark - private methods
- (void)addLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest originRequest:(NSURLRequest *)originRequest{
    HJ_LOCK(self.loadingRequestsLock);
    NSMapTable<NSURLRequest *, id> *mapTable = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
    [mapTable setObject:loadingRequest forKey:originRequest];
    [self.loadingRequests addObject:mapTable];
    HJ_UNLOCK(self.loadingRequestsLock);
}

#pragma mark create response,process,complete block

- (HJPlayerLoaderResponseBlock)createResponseBlock {
    
    HJPlayerLoaderResponseBlock responseBlock = ^(NSUInteger totalSize, NSURLRequest *request){
        for (NSMapTable<NSURLRequest *, AVAssetResourceLoadingRequest *> *rMapTable in self.loadingRequests) {
            NSEnumerator *enumerator = [rMapTable keyEnumerator];
            id key;
            while ((key = [enumerator nextObject])) {
                /* code that uses the returned key */
                if ([key isEqual:request]) {
                    [HJCache.sharedCache saveFileLengthToLocalPlistWithURL:request.URL fileLength:totalSize];
                }
            }
        }
    };
    return responseBlock;
}

- (HJPlayerLoaderProgressBlock)createProgressBlock {
    
    HJPlayerLoaderProgressBlock processBlock = ^(NSData *data, NSUInteger startOffset, NSInteger receivedSize, NSInteger totalSize, NSURLRequest *request) {
        
        for (NSMapTable<NSURLRequest *, AVAssetResourceLoadingRequest *> *rMapTable in self.loadingRequests) {
            
            NSEnumerator *enumerator = [rMapTable keyEnumerator];
            id key;
            while ((key = [enumerator nextObject])) {
                if ([key isEqual:request]) {
                    AVAssetResourceLoadingRequest *loadingRequest = [rMapTable objectForKey:key];
                    [loadingRequest.dataRequest respondWithData:data];
                    [HJCache.sharedCache writeDataToDiskWithURL:request.URL
                                                    startOffset:startOffset
                                                           data:data
                                                     completion:^(HJWriteDataStatus status) {
                                                         switch (status) {
                                                             case HJWriteDataStatusComplete:
                                                                 
                                                                 break;
                                                             case HJWriteDataStatusPart:
                                                                 
                                                                 break;
                                                             case HJWriteDataStatusFailed:
                                                                 // 提示缓存失败
                                                                 break;
                                                             default:
                                                                 break;
                                                         }
                                                     }];
                }
            }
        }
    };
    return processBlock;
}

- (HJPlayerDownloaderCompltedBlock)createCompleteBlockWithRequestOffset:(long long)requestedOffset {
    
    HJPlayerDownloaderCompltedBlock completedBlock = ^(NSError * _Nullable error, NSURLRequest *_Nonnull request, NSURLResponse *response, NSUInteger currentOffset, NSInteger totalSize) {
        
        [self getLoadingRequestForRequest:request result:^(AVAssetResourceLoadingRequest *loadingRequest) {
            
            NSString *filePath = [HJCache.sharedCache filePathWithFileURL:request.URL];
            [self fillContentInfo:filePath loadingRequest:loadingRequest response:response];
            [loadingRequest finishLoading];
            NSMutableArray *arr = [NSMutableArray arrayWithCapacity:2];
            [arr addObject:@(requestedOffset)];
            [arr addObject:@(currentOffset - 1)];
            [HJCache.sharedCache updateDownloadFileRangeInLocalPlistWithURL:request.URL responseRange:[arr copy]];
        }];
        
    };
    return completedBlock;
}

#pragma mark mimeType
- (NSString *)getFileMIMETypeWithCAPIOfFilePath:(NSString*)filePath{
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return nil;
    }
    CFStringRef UTi = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef _Nonnull)([filePath pathExtension]), NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass(UTi, kUTTagClassMIMEType);
    CFRelease(UTi);
    if (!MIMEType) {
        return @"application/octet-stream";
    }else{
        return (__bridge NSString *)(MIMEType);
    }
}

#pragma mark fill contentInfo
- (void)fillContentInfo:(NSString *)filePath loadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest response:(NSURLResponse *)response{
    
    AVAssetResourceLoadingContentInformationRequest *contentInfoRequest = loadingRequest.contentInformationRequest;
    if (contentInfoRequest) {
        if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
            return;
        }
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        //服务器端是否支持分段传输
        BOOL byteRangeAccessSupported = [httpResponse.allHeaderFields[@"Accept-Ranges"] isEqualToString:@"bytes"];
        //获取返回文件的长度
        long long contentLength = [[[httpResponse.allHeaderFields[@"Content-Range"] componentsSeparatedByString:@"/"] lastObject] longLongValue];
        //获取返回文件的类型
        NSString *mimeType = httpResponse.MIMEType;
        CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)mimeType, NULL);//此处需要引入<MobileCoreServices/MobileCoreServices.h>头文件
        NSString *contentTypeStr = CFBridgingRelease(contentType);
        contentInfoRequest.byteRangeAccessSupported = byteRangeAccessSupported;
        contentInfoRequest.contentLength = contentLength;
        contentInfoRequest.contentType = contentTypeStr;
    }
}

- (void)fillContentInfo:(NSString *)filePath loadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest originRequest:(NSURLRequest *)originRequest{
    
    AVAssetResourceLoadingContentInformationRequest *contentInfoRequest = loadingRequest.contentInformationRequest;
    if (contentInfoRequest) {
        //服务器端是否支持分段传输
        BOOL byteRangeAccessSupported = YES;
        //获取返回文件的类型
        NSString *mimeType = [self getFileMIMETypeWithCAPIOfFilePath:filePath];
        CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)mimeType, NULL);//此处需要引入<MobileCoreServices/MobileCoreServices.h>头文件
        NSString *contentTypeStr = CFBridgingRelease(contentType);
        NSUInteger length = [HJCache.sharedCache queryFileLengthInLocalPlistFileWithURL:originRequest.URL];
        contentInfoRequest.byteRangeAccessSupported = byteRangeAccessSupported;
        contentInfoRequest.contentLength = length;
        contentInfoRequest.contentType = contentTypeStr;
    }
}

#pragma mark get loadingRequest

- (void)getLoadingRequestForRequest:(NSURLRequest *)request
                             result:(void(^)(AVAssetResourceLoadingRequest *obj))res {
    [self getLoadingRequestForRequest:request applyDataFinished:YES result:res];
}

- (void)getLoadingRequestForRequest:(NSURLRequest *)request
                  applyDataFinished:(BOOL)finished
                             result:(void(^)(AVAssetResourceLoadingRequest * obj))res{
    
    [self.loadingRequests enumerateObjectsUsingBlock:^(HJLoadingRequestMapTable * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSEnumerator *enumerator = [obj keyEnumerator];
        id key;
        while ((key = [enumerator nextObject])) {
            /* code that uses the returned key */
            if ([key isEqual:request]) {
                AVAssetResourceLoadingRequest *loadingRequest = [obj objectForKey:key];
                res(loadingRequest);
                *stop = YES;
                if (*stop == YES && finished) {
                    HJ_LOCK(self.loadingRequestsLock);
                    [obj removeObjectForKey:key];
                    HJ_UNLOCK(self.loadingRequestsLock);
                }
                break;
            }
        }
    }];
}

@end
