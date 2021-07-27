//
//  Util.h
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static NSString *ViewUpdateNotification = @"ViewUpdate";

@interface Util: NSObject

+ (void)appendTextToOutput:(NSString *)text;

+ (NSMutableString *)getOutputText;

@end
