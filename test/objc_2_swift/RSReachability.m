//
//  RSReachability.m
//  RealSelf
//
//  Created by Marcin Butanowicz on 05/03/15.
//  Copyright (c) 2015 RealSelf. All rights reserved.
//

@import Crashlytics;

#import "RSReachability.h"

@interface RSReachability ()
@property (nonatomic, strong) RSNoInternetConnectionView *noInternetConnectionView;
@property (nonatomic, strong) UIView *navigationOverlayView;
@end

@implementation RSReachability

#pragma mark - Object Life cycle

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });

    return sharedInstance;
}

#pragma mark - Public methods

- (void)startObserveReachability
{
    if (!self.noInternetConnectionView) {
        self.noInternetConnectionView = [[NSBundle mainBundle] loadNibNamed:@"RSNoInternetConnectionView" owner:self options:nil].firstObject;
        self.noInternetConnectionView.alpha = 0;
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        CGFloat screenHeight = screenRect.size.height;

        self.noInternetConnectionView.frame = CGRectMake(0, 20, screenWidth, screenHeight - 20);
        self.navigationOverlayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 64)];
        [self.navigationOverlayView setBackgroundColor:[UIColor clearColor]];
    }
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        BOOL newReachable;
        switch (status) {
        case AFNetworkReachabilityStatusNotReachable:
            CLS_LOG(@"----network not reachable----");
            newReachable = NO;
            break;
        case AFNetworkReachabilityStatusReachableViaWiFi:
            CLS_LOG(@"----network reachable WiFi----");
            newReachable = YES;
            break;
        case AFNetworkReachabilityStatusReachableViaWWAN:
            CLS_LOG(@"----network reachable 3G----");
            newReachable = YES;
            break;
        default:
            CLS_LOG(@"----network unkown status----");
            newReachable = NO;
            break;
        }

        _reachabilityStatus = status;
        if (newReachable != _reachable) {
            // Notify about just made status change
            [[NSNotificationCenter defaultCenter] postNotificationName:RSNotoficationDidChangeReachabilityStatus object:nil];
            _reachable = newReachable;
        }
        [UIView beginAnimations:NULL context:NULL];
        [UIView setAnimationDuration:0.5];
        if (newReachable == NO) {
            [self.noInternetConnectionView setAlpha:1];
            [[[UIApplication sharedApplication] keyWindow] addSubview:self.noInternetConnectionView];
            [[[UIApplication sharedApplication] keyWindow] addSubview:self.navigationOverlayView];
        }
        else {
            [self.noInternetConnectionView setAlpha:0];
            [self.noInternetConnectionView removeFromSuperview];
            [self.navigationOverlayView removeFromSuperview];
        }
        [UIView commitAnimations];
    }];

    // start observing reachability.
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

@end
