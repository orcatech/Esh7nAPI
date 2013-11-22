//
//  CameraView.m
//  Esh7nLite
//
//  Created by Mohamed Ahmed Fouad on 11/16/13.
//  Copyright (c) 2013 Orca Tech. All rights reserved.
//

#import "CameraView.h"

@implementation CameraView
@synthesize cardframe;
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.


- (void)drawRect:(CGRect)rect {
    [[UIColor clearColor] setFill];
    UIRectFill(rect);
    
    UIBezierPath *bigMaskPath = [UIBezierPath bezierPathWithRect:rect];
    int padding = 3;
    cardframe = CGRectMake(20 +padding, 80+padding, 280-2*padding, 50-2*padding);
    
    
    UIBezierPath *smallMaskPath = [UIBezierPath  bezierPathWithRoundedRect:cardframe
                                                         byRoundingCorners:(UIRectCornerAllCorners)
                                                               cornerRadii:CGSizeMake(10, 10)];
    
    
    UIBezierPath *clipPath = [UIBezierPath bezierPathWithRect:CGRectInfinite];
    [clipPath appendPath:smallMaskPath];
    clipPath.usesEvenOddFillRule = YES;
    
    CGContextSaveGState(UIGraphicsGetCurrentContext()); {
        [clipPath addClip];
        [[UIColor colorWithRed:219 green:219 blue:219 alpha:0.7] setFill];
        [bigMaskPath fill];
    } CGContextRestoreGState(UIGraphicsGetCurrentContext());
}

@end
