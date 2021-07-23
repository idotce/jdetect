//
//  ViewController.m
//  jdetect
//
//  Created by youcheng on 2021/6/25.
//

#include <sys/time.h>
#import "ViewController.h"
#import "XFJailbreakOtherCheck.h"
#import "XFJailbreakFileCheck.h"
#import "XFJailbreakInjectCheck.h"
#import "XFJailbreakURLCheck.h"

@interface ViewController () {
    Boolean isInitUIView;
    UIInterfaceOrientation orientation;
}

@property (nonatomic, strong) UILabel *JBResult;
@property (nonatomic, strong) UITextView *outputView;

@end

@implementation ViewController

static NSMutableString *outputText = nil;

- (void)viewDidLoad {
    [super viewDidLoad];
    //
    isInitUIView = false;
    [self redirectSTD:STDOUT_FILENO];
    [self redirectSTD:STDERR_FILENO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //
    orientation = [[UIApplication sharedApplication] statusBarOrientation];
    [self initUIView];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}

- (void)dealloc {
    //
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

# pragma mark - UIView

- (void)initUIView
{
    if (!isInitUIView) {
        self.JBResult = [[UILabel alloc] init];
        [self.JBResult setBackgroundColor:[UIColor whiteColor]];
        [self.JBResult setTextColor:[UIColor blackColor]];
        [self.JBResult setTextAlignment:NSTextAlignmentCenter];
        [self.JBResult setFont:[UIFont systemFontOfSize:32.0f]];
        [self.view addSubview:self.JBResult];

        self.outputView = [[UITextView alloc] init];
        [self.outputView setBackgroundColor:[UIColor whiteColor]];
        [self.outputView setTextColor:[UIColor blackColor]];
        [self.outputView setFont:[UIFont systemFontOfSize:12.0f]];
        [self.outputView setEditable:FALSE];
        [self.view addSubview:self.outputView];

        [self.view setBackgroundColor:[UIColor whiteColor]];
        isInitUIView = true;
    }
    float width = CGRectGetWidth(self.view.frame);
    float height = CGRectGetHeight(self.view.frame);
    [self.JBResult setFrame:CGRectMake(10, 24, width-20, 60)];
    [self.outputView setFrame:CGRectMake(10, 80, width-20, height-100)];

    BOOL isJB = NO;
#if !(TARGET_IPHONE_SIMULATOR)
    if ([XFJailbreakOtherCheck isJailbreakOtherAvailable]) {
        isJB = YES;
    }
    if ([XFJailbreakFileCheck isJailbreakFileExist]) {
        isJB = YES;
    }
    if ([XFJailbreakInjectCheck isJailbreakInjectExist]) {
        isJB = YES;
    }
    if ([XFJailbreakURLCheck isJailbreakURLAvailable]) {
        isJB = YES;
    }
#endif
    if (isJB) {
        self.JBResult.text = @"Jailbroken";
    }
    else {
        self.JBResult.text = @"Not Jailbroken";
    }
}

# pragma mark - redirect

- (void)redirectNotificationHandle:(NSNotification *)nf{
    NSData *data = [[nf userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    [self appendTextToOutput:[NSString stringWithFormat:@"%@\n", str]];

    [[nf object] readInBackgroundAndNotify];
}

- (void)redirectSTD:(int )fd {
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *pipeReadHandle = [pipe fileHandleForReading];
    dup2([[pipe fileHandleForWriting] fileDescriptor], fd);

    [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(redirectNotificationHandle:)
                                               name:NSFileHandleReadCompletionNotification
                                             object:pipeReadHandle] ;
    [pipeReadHandle readInBackgroundAndNotify];
}

# pragma mark - outputView

- (void)updateOutputView {
    [self updateOutputViewFromQueue:@NO];
}

- (void)updateOutputViewFromQueue:(NSNumber*)fromQueue {
    static BOOL updateQueued = NO;
    static struct timeval last = {0,0};
    static dispatch_queue_t updateQueue;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        updateQueue = dispatch_queue_create("updateView", NULL);
    });

    dispatch_async(updateQueue, ^{
        struct timeval now;
        if (fromQueue.boolValue) {
            updateQueued = NO;
        }
        if (updateQueued) {
            return;
        }
        if (gettimeofday(&now, NULL)) {
            NSLog(@"gettimeofday failed");
            return;
        }
        uint64_t elapsed = (now.tv_sec - last.tv_sec) * 1000000 + now.tv_usec - last.tv_usec;
        // 30 FPS
        if (elapsed > 1000000/30) {
            updateQueued = NO;
            gettimeofday(&last, NULL);
            dispatch_async(dispatch_get_main_queue(), ^{
                self.outputView.text = outputText;
                [self.outputView scrollRangeToVisible:NSMakeRange(self.outputView.text.length, 0)];
            });
        } else {
            NSTimeInterval waitTime = ((1000000/30) - elapsed) / 1000000.0;
            updateQueued = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSelector:@selector(updateOutputViewFromQueue:) withObject:@YES afterDelay:waitTime];
            });
        }
    });
}

- (void)appendTextToOutput:(NSString *)text {
    if (_outputView == nil) {
        return;
    }
    static NSRegularExpression *remove = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        remove = [NSRegularExpression \
                  regularExpressionWithPattern:@"^\\d{4}-\\d{2}-\\d{2}\\s\\d{2}:\\d{2}:\\d{2}\\.\\d+[-\\d\\s]+\\S+\\[\\d+:\\d+\\]\\s+" \
                  options:NSRegularExpressionAnchorsMatchLines error:nil];
        outputText = [NSMutableString new];
    });

    text = [remove stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:@""];

    @synchronized (outputText) {
        [outputText appendString:text];
    }
    [self updateOutputView];
}

@end
