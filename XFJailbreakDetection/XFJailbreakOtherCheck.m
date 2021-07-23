//
//  XFJailbreakOtherCheck.m
//  XFJailbreakDetection
//
//  Created by youcheng on 22/07/2021.
//  Copyright © 2021 youcheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "XFJailbreakOtherCheck.h"
#import "XFJailbreakPattern.h"
#include <sys/stat.h>

@implementation XFJailbreakOtherCheck

+ (BOOL)isJailbreakOtherAvailable {
    BOOL check = NO;

    struct stat s;
    int iret = stat("/Applications/AppStore.app", &s);
    if (iret != 0) {
        NSLog(@"stat /Applications/AppStore.app %d", iret);
        check = YES;
    }

    return check;
}

@end
