//
//  Util.m
//

#import "Util.h"

@implementation Util

static NSMutableString *outputText = nil;

+ (void)appendTextToOutput:(NSString *)text {
    static NSRegularExpression *remove = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        remove = [NSRegularExpression \
                  regularExpressionWithPattern:@"^\\d{4}-\\d{2}-\\d{2}\\s\\d{2}:\\d{2}:\\d{2}\\.\\d+[-\\d\\s]+\\S+\\[\\d+:\\d+\\]\\s+" \
                  options:NSRegularExpressionAnchorsMatchLines error:nil];
        outputText = [NSMutableString new];
    });

    text = [remove stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:@""];
    text = [text stringByAppendingString:@"\n"];

    @synchronized (outputText) {
        [outputText appendString:text];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ViewUpdateNotification object:nil];
}

+ (NSMutableString *)getOutputText {
    return outputText;
}

@end
