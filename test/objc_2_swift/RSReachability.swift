//
//  Copyright (c) 2015 RealSelf. All rights reserved.
//

import Foundation
import Crashlytics
// TODO: Add '#import "AFNetworkReachabilityManager.h"' to bridging header
// TODO: Add '#import "RSNoInternetConnectionView.h"' to bridging header

// TODO: Add 'static let RSNotoficationDidChangeReachabilityStatus: String = "RSNotoficationDidChangeReachabilityStatus"' to one of your classes'

@objc class RSReachability: NSObject{
    private var reachable: Bool
    private(set) var reachabilityStatus: AFNetworkReachabilityStatus
    private var noInternetConnectionView: RSNoInternetConnectionView
    private var navigationOverlayView: UIView
    static let sharedInstance = RSReachability()
    var isReachable: Bool {
        return reachable
    }

    private override init() {}

    func startObserveReachability() {    
        if !self.noInternetConnectionView {
            self.noInternetConnectionView = NSBundle.mainBundle().loadNibNamed("RSNoInternetConnectionView", owner: self, options: nil).firstObject
            self.noInternetConnectionView.alpha = 0
            var screenRect: CGRect = UIScreen.mainScreen().bounds()
            var screenWidth: CGFloat = screenRect.size.width
            var screenHeight: CGFloat = screenRect.size.height
    
            self.noInternetConnectionView.frame = CGRectMake(0, 20, screenWidth, screenHeight - 20)
            self.navigationOverlayView = UIView(frame: CGRectMake(0, 0, screenWidth, 64))
            self.navigationOverlayView.setBackgroundColor(UIColor.clearColor())
        }
        AFNetworkReachabilityManager.sharedManager().setReachabilityStatusChangeBlock({ (status: AFNetworkReachabilityStatus) in 
            var newReachable: Bool
            switch status {
            case AFNetworkReachabilityStatusNotReachable:
                CLS_LOG("----network not reachable----")
                newReachable = false
            case AFNetworkReachabilityStatusReachableViaWiFi:
                CLS_LOG("----network reachable WiFi----")
                newReachable = true
            case AFNetworkReachabilityStatusReachableViaWWAN:
                CLS_LOG("----network reachable 3G----")
                newReachable = true
            default:
                CLS_LOG("----network unkown status----")
                newReachable = false
            }
    
            self.reachabilityStatus = status
            if newReachable != self.reachable {
                // Notify about just made status change
                NSNotificationCenter.defaultCenter().postNotificationName(RSNotoficationDidChangeReachabilityStatus, object: nil)
                self.reachable = newReachable
            }
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(0.5)
            if newReachable == false {
                self.noInternetConnectionView.setAlpha(1)
                UIApplication.sharedApplication().keyWindow().addSubview(self.noInternetConnectionView)
                UIApplication.sharedApplication().keyWindow().addSubview(self.navigationOverlayView)
            } else {
                self.noInternetConnectionView.setAlpha(0)
                self.noInternetConnectionView.removeFromSuperview()
                self.navigationOverlayView.removeFromSuperview()
            }
            UIView.commitAnimations()
        })
    
        // start observing reachability.
        AFNetworkReachabilityManager.sharedManager().startMonitoring()
    }

    private func test() -> Int {}
}
