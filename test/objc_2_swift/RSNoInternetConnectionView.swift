//
//  Copyright (c) 2015 RealSelf. All rights reserved.
//

import UIKit


@objc class RSNoInternetConnectionView: UIView{
    @IBOutlet weak var errorLabel: UILabel

    private func drawRect(rect: CGRect) {    
        // Drawing code
    }

    private func awakeFromNib() {    
        super.awakeFromNib()
        self.errorLabel().setText(NSLocalizedString("We're not finding a network connection", nil))
        self.errorLabel.adjustsFontSizeToFitWidth = true
    }
}
