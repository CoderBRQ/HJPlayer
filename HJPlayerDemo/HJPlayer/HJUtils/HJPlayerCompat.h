//
//  HJPlayerCompat.h
//  NSOperationDemo
//
//  Created by bianrongqiang on 6/1/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//


#import <TargetConditionals.h>

// iOS and tvOS are very similar, UIKit exists on both platforms
// Note: watchOS also has UIKit, but it's very limited
#if TARGET_OS_IOS || TARGET_OS_TV
#define HJ_UIKIT 1
#else
#define HJ_UIKIT 0
#endif

#ifndef dispatch_main_async_safe
#define dispatch_main_async_safe(block)\
if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(dispatch_get_main_queue())) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}
#endif
