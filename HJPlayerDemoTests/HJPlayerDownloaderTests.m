//
//  HJPlayerDownloaderTests.m
//  HJPlayerDemo2Tests
//
//  Created by bianrongqiang on 6/28/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#import "HJTestCase.h"

@interface HJPlayerDownloaderTests : HJTestCase

@end

@implementation HJPlayerDownloaderTests

- (void)test01ThatASimpleDownloadWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"simple download"];
    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kTestAudioURL]];
    NSString *range=[NSString stringWithFormat:@"bytes=0-1"];
    [mutableRequest setValue:range forHTTPHeaderField:@"Range"];
    [mutableRequest setValue:@"identity" forHTTPHeaderField:@"Accept-Encoding"];
    NSURLRequest * request = [mutableRequest copy];
    
    [HJPlayerDownloader.sharedDownloader downloadDataWithRequest:request response:^(NSUInteger totalSize, NSURLRequest *request) {
        if (totalSize > 0) {
            [expectation fulfill];
        }else {
            XCTFail(@"Something went wrong");
        }
    } progress:nil completed:nil];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test02ThatCancelAllDownloadWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"CancelAllDownloads"];
    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kTestAudioURL]];
    NSString *range=[NSString stringWithFormat:@"bytes=0-163850"];
    [mutableRequest setValue:range forHTTPHeaderField:@"Range"];
    [mutableRequest setValue:@"identity" forHTTPHeaderField:@"Accept-Encoding"];
    NSURLRequest * request = [mutableRequest copy];
    
    [HJPlayerDownloader.sharedDownloader downloadDataWithRequest:request response:nil progress:nil completed:nil];
    
    expect(HJPlayerDownloader.sharedDownloader.currentDownloadCount).to.equal(1);
    [HJPlayerDownloader.sharedDownloader cancelAllDownloads];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kMinDelayNanosecond), dispatch_get_main_queue(), ^{
        expect(HJPlayerDownloader.sharedDownloader.currentDownloadCount).to.equal(0);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithCommonTimeout];
}
@end

