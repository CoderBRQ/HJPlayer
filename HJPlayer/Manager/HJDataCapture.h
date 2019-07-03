//
//  HJDataCapture.h
//  HJPlayerDemo2
//
//  Created by bianrongqiang on 6/2/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol HJDataCapture <NSObject>

- (void)captureDataFromNetWithRequestedOffset:(long long)requestedOffset
                              requestedLength:(NSInteger)requestedLength
                               loadingRequest:(nonnull AVAssetResourceLoadingRequest *)loadingRequest
                                originRequest:(nonnull NSURLRequest *)originRequest;

- (void)captureDataFromDiskWithStartOffset:(off_t)startOffset
                                  dataSize:(size_t)dataSize
                            loadingRequest:(nonnull AVAssetResourceLoadingRequest *)loadingRequest
                             originRequest:(nonnull NSURLRequest *)originRequest;

@end

@interface HJDataCapture : NSObject<HJDataCapture>

@property (nonatomic, class, readonly, nonnull) HJDataCapture *sharedDataCapture;

@end
