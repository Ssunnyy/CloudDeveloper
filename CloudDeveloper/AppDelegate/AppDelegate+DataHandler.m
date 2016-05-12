//
//  AppDelegate+DataHandler.m
//  CloudDeveloper
//
//  Created by _Finder丶Tiwk on 16/5/8.
//  Copyright © 2016年 _Finder丶Tiwk. All rights reserved.
//

#import "AppDelegate+DataHandler.h"

@implementation AppDelegate (DataHandler)

- (void)xks_dataHandle{
    dispatch_async(dispatch_get_global_queue(0, 0), ^(void) {
        NSLog(@"上传数据");
    });
}

@end
