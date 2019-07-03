//
//  HJTestCase.h
//  HJPlayerDemo2Tests
//
//  Created by bianrongqiang on 6/28/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#define EXP_SHORTHAND   // required by Expecta

#import <XCTest/XCTest.h>
#import <Expecta/Expecta.h>
#import "HJPlayer.h"


FOUNDATION_EXPORT const int64_t kAsyncTestTimeout;
FOUNDATION_EXPORT const int64_t kMinDelayNanosecond;
FOUNDATION_EXPORT NSString *_Nonnull const kTestAudioURL;

@interface HJTestCase : XCTestCase

- (void)waitForExpectationsWithCommonTimeout;
- (void)waitForExpectationsWithCommonTimeoutUsingHandler:(nullable XCWaitCompletionHandler)handler;

@end

