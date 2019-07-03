//
//  HJPlayerOperation.h
//  NSOperationDemo
//
//  Created by bianrongqiang on 6/1/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HJPlayerOperation <NSObject>

- (void)cancel;// 覆盖NSOperation中的cancel方法

@end

// NSOperation conform to `HJPlayerOperation`
@interface NSOperation (HJPlayerOperation) <HJPlayerOperation>

@end
