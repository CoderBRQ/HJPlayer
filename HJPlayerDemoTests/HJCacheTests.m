//
//  HJCacheTests.m
//  HJPlayerDemo2Tests
//
//  Created by bianrongqiang on 6/28/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#import "HJTestCase.h"

static NSString *kTestAudioKeyMP3 = @"TestAudio.mp3";

@interface HJCache ()
@property (nonatomic, strong, nonnull) id<HJDiskCache> diskCache;
@end


@interface HJCacheTests : HJTestCase

@end

@implementation HJCacheTests
- (void)test01ThatSharedCahce {
    expect(HJCache.sharedCache).toNot.beNil();
}

- (void)test02ThatSingleton {
    expect(HJCache.sharedCache).to.equal(HJCache.sharedCache);
}

- (void)test03ThatCacheCanBeInstantiated {
    HJCache *cache = [[HJCache alloc] init];
    expect(cache).toNot.equal([HJCache sharedCache]);
}

- (void)test04ThatRemoveAllData {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Remove all data"];
    
    HJCache *cache = [[HJCache alloc] initWithNameSpace:@""  diskCacheDirectory:[self testFileDirection] config:nil];
    size_t size = [cache fileSizeWithFileURL:[NSURL URLWithString:kTestAudioKeyMP3]];
    __block off_t startOffset = 0;

    [cache readDataFromDiskWithURL:[NSURL URLWithString:kTestAudioKeyMP3] startOffset:startOffset dataSize:size ioReadCompletion:nil dataApplyCompletion:^BOOL(const void *buffer, size_t size, BOOL finished) {
        if (!finished) {
            NSData *data = [[NSData alloc] initWithBytes:buffer length:size];
            
            [HJCache.sharedCache writeDataToDiskWithURL:[NSURL URLWithString:kTestAudioKeyMP3] startOffset:startOffset data:data completion:^(HJWriteDataStatus status) {

            }];
            startOffset += size;
            return false;
        }else {
            if ([HJCache.sharedCache diskDataExistsWithKey:kTestAudioKeyMP3]) {
                [HJCache.sharedCache clearAllDataOnCompletion:^{
                    [expectation fulfill];
                }];
            }
            
        }
        return true;
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test05ThatInsertionOfData {
    XCTestExpectation *expectation = [self expectationWithDescription:@"wirteDataToDisk"];
    
    HJCache *cache = [[HJCache alloc] initWithNameSpace:@""  diskCacheDirectory:[self testFileDirection] config:nil];
    size_t size = [cache fileSizeWithFileURL:[NSURL URLWithString:kTestAudioKeyMP3]];
    __block off_t startOffset = 0;
    
    [cache readDataFromDiskWithURL:[NSURL URLWithString:kTestAudioKeyMP3] startOffset:0 dataSize:size ioReadCompletion:nil dataApplyCompletion:^BOOL(const void *buffer, size_t size, BOOL finished) {
        if (!finished) {
            NSData *data = [[NSData alloc] initWithBytes:buffer length:size];
            [HJCache.sharedCache writeDataToDiskWithURL:[NSURL URLWithString:kTestAudioKeyMP3] startOffset:startOffset data:data completion:^(HJWriteDataStatus status) {

            }];
            
            startOffset += size;
            return false;
        }else {
            if ([HJCache.sharedCache diskDataExistsWithKey:kTestAudioKeyMP3]) {
                [HJCache.sharedCache removeDataWithFileURL:[NSURL URLWithString:kTestAudioKeyMP3] completion:^{
                    [expectation fulfill];
                }];
            }else {
                XCTFail(@"Data should be in cache");
            }
        }
        return true;
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test06ThatRemoveDataForKey{
    XCTestExpectation *expectation = [self expectationWithDescription:@"removeDataForKey"];
    
    HJCache *cache = [[HJCache alloc] initWithNameSpace:@""  diskCacheDirectory:[self testFileDirection] config:nil];
    size_t size = [cache fileSizeWithFileURL:[NSURL URLWithString:kTestAudioKeyMP3]];
    __block off_t startOffset = 0;
    
    [cache readDataFromDiskWithURL:[NSURL URLWithString:kTestAudioKeyMP3] startOffset:0 dataSize:size ioReadCompletion:nil dataApplyCompletion:^BOOL(const void *buffer, size_t size, BOOL finished) {
        if (!finished) {
            NSData *data = [[NSData alloc] initWithBytes:buffer length:size];
            [HJCache.sharedCache writeDataToDiskWithURL:[NSURL URLWithString:kTestAudioKeyMP3] startOffset:startOffset data:data completion:^(HJWriteDataStatus status) {
                
            }];
            
            startOffset += size;
            return false;
        }else {
            if ([HJCache.sharedCache diskDataExistsWithKey:kTestAudioKeyMP3]) {
                [HJCache.sharedCache removeDataWithFileURL:[NSURL URLWithString:kTestAudioKeyMP3] completion:^{
                    if (![HJCache.sharedCache diskDataExistsWithKey:kTestAudioKeyMP3]) {
                        [expectation fulfill];
                    }
                }];
            }else {
                XCTFail(@"Data should be in cache");
            }
        }
        return true;
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

#pragma mark Helper methods

- (NSString *)testFileDirection {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return testBundle.resourcePath;
}
@end
