//
//  orcaViewController.h
//  Esh7nLite
//
//  Created by Mohamed Ahmed Fouad on 11/16/13.
//  Copyright (c) 2013 Orca Tech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CameraView.h"

@interface orcaViewController : UIViewController<NSURLSessionDelegate,NSURLSessionDataDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *FlashButton;

@property (weak, nonatomic) IBOutlet UIButton *CaptureBtn;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *LastOperationBtn;

@property (weak, nonatomic) IBOutlet CameraView *CameraOverlay;

@property (weak, nonatomic) IBOutlet UIView *CameraLayout;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progressSpinner;


- (IBAction)FlashButton_Touch:(id)sender;
- (IBAction)CaptureButton_Touch:(id)sender;
- (IBAction)LastNo_Touch:(id)sender;

@end


@interface NSString (URLEncoding)
-(NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding;
@end
