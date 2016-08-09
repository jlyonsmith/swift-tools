//
//  RSNoInternetConnectionView.m
//  RealSelf
//
//  Created by ak on 03.08.2015.
//  Copyright (c) 2015 RealSelf. All rights reserved.
//

#import "RSNoInternetConnectionView.h"

@implementation RSNoInternetConnectionView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(void)awakeFromNib {
    [super awakeFromNib];
    [[self errorLabel] setText:NSLocalizedString(@"We're not finding a network connection", nil)];
    _errorLabel.adjustsFontSizeToFitWidth = true;
}

@end
