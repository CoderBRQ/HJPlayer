//
//  HJInternalMacors.h
//  NSOperationDemo
//
//  Created by bianrongqiang on 6/1/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef HJ_LOCK
#define HJ_LOCK(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#endif

#ifndef HJ_UNLOCK
#define HJ_UNLOCK(lock) dispatch_semaphore_signal(lock);
#endif
