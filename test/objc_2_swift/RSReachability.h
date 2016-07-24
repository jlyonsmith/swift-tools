//
//  RSReachability.h
//  RealSelf
//
//  Created by Marcin Butanowicz on 05/03/15.
//  Copyright (c) 2015 RealSelf. All rights reserved.
//

@import Foundation;
#import "AFNetworkReachabilityManager.h"
#import "RSNoInternetConnectionView.h"

// RSReachabilityNotifications information about changed status
static NSString *const RSNotoficationDidChangeReachabilityStatus = @"RSNotoficationDidChangeReachabilityStatus";
@interface RSReachability : NSObject

@property (readonly, assign, nonatomic, getter=isReachable) BOOL reachable;
@property (readonly, assign, nonatomic) AFNetworkReachabilityStatus reachabilityStatus;

+ (instancetype)sharedInstance;
- (void)startObserveReachability;
@end
