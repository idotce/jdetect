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
#include <dlfcn.h>
#import "Util.h"

@implementation XFJailbreakOtherCheck

+ (BOOL)isJailbreakOtherAvailable {
    BOOL check = NO;

    struct stat s;
    int iret;

    iret = stat("/Applications/AppStore.app", &s);
    if (iret != 0) {
        NSString *str = [NSString stringWithFormat:@"stat /Applications/AppStore.app %d", iret];
        [Util appendTextToOutput:str];
        check = YES;
    }
    
    if (NULL != getenv("DYLD_INSERT_LIBRARIES")) {
        NSString *str = [NSString stringWithFormat:@"getenv DYLD_INSERT_LIBRARIES exist!"];
        [Util appendTextToOutput:str];
        check = YES;
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/User/Applications/"]) {
        NSArray *applist = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/User/Applications/" error:nil];
        NSString *str = [NSString stringWithFormat:@"applist = %@", applist];
        [Util appendTextToOutput:str];
        if (applist.count>0) {
            check = YES;
        }
    }

    Dl_info dylib_info;
    int (*func_stat)(const char *, struct stat *) = stat;
    iret = dladdr(func_stat, &dylib_info);
    if (iret != 0) {
        NSString *str = [NSString stringWithFormat:@"lib :%s (/usr/lib/system/libsystem_kernel.dylib)", dylib_info.dli_fname];
        [Util appendTextToOutput:str];
    }

    iret = stat("/var/db/timezone/icutz", &s);
    if (iret != 0) {
        NSString *str = [NSString stringWithFormat:@"stat /var/db/timezone/icutz %d", iret];
        [Util appendTextToOutput:str];
    }
    
    FILE *f = fopen("/var/mobile//com.apple.mobileInfo", "r");
    if (f == NULL) {
        NSString *str = [NSString stringWithFormat:@"fopen /var/mobile//com.apple.mobileInfo"];
        [Util appendTextToOutput:str];
        fclose(f);
    }

    return check;
}

@end
