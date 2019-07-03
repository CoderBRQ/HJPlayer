
//
//  HJTestCase.m
//  HJPlayerDemo2Tests
//
//  Created by bianrongqiang on 6/28/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#import "HJTestCase.h"

const int64_t kAsyncTestTimeout = 5;
const int64_t kMinDelayNanosecond = NSEC_PER_MSEC * 100; // 0.1s
NSString *const kTestAudioURL = @"http://mpge.5nd.com/2018/2018-1-23/74521/1.mp3";

@implementation HJTestCase
- (void)waitForExpectationsWithCommonTimeout {
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

- (void)waitForExpectationsWithCommonTimeoutUsingHandler:(XCWaitCompletionHandler)handler {
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout handler:handler];
}
@end
