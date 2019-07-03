//
//  HJPlayerError.h
//  NSOperationDemo
//
//  Created by bianrongqiang on 6/1/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSErrorDomain const _Nonnull HJPlayerErrorDomain;

FOUNDATION_EXPORT NSErrorUserInfoKey const _Nonnull HJPlayerErrorDownloadStatusCodeKey;

typedef NS_ERROR_ENUM(HJPlayerErrorDomain, HJPlayerError) {
    HJPlayerErrorInvalidURL = 1000, // The URL is invalid, such as nil URL or corrupted URL
    HJPlayerErrorBadData = 1001, // The  data data is empty
    HJPlayerErrorInvalidDownloadOperation = 2000, // The  download operation is invalid, such as nil operation or unexpected error occur when operation initialized
    HJPlayerErrorInvalidDownloadStatusCode = 2001, // The  download response a invalid status code. You can check the status code in error's userInfo under `HJPlayerErrorDownloadStatusCodeKey`
};
