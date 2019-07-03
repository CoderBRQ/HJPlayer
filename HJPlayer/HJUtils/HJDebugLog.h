//
//  HJDebugLog.h
//  HJAudioPlayer
//
//  Created by bianrongqiang on 6/24/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//


#ifdef DEBUG
#define NSLog(FORMAT, ...) fprintf(stderr,"%s\n",[[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define NSLog(...)
#endif

