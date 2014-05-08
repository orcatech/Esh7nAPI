//
//  orcaViewController.m
//  Esh7nLite
//
//  Created by Mohamed Ahmed Fouad on 11/16/13.
//  Copyright (c) 2013 Orca Tech. All rights reserved.
//

#import "orcaViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

@implementation NSString (URLEncoding)
-(NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding {
	return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                               (CFStringRef)self,
                                                               NULL,
                                                               (CFStringRef)@"!*'\"();:@+$,%#[]% ",
                                                               CFStringConvertNSStringEncodingToEncoding(encoding)));
}
@end

@interface orcaViewController ()
    @property (nonatomic, weak) AVCaptureDevice *captureDevice;
    @property (nonatomic, strong) AVCaptureSession *captureSession;
@end

@implementation orcaViewController{
    //Get these info from http://esh7n.byorca.com/
    NSString* AppId;
    NSString* APPSecret;
    NSString* MinDetectedNumbers;
    BOOL isTestMode;
    /////////////////////////////////////////////
    
    NSString* Country;
    NSString* Manufacture;
    NSString* Model;
    NSString* OS;
    NSString* NetworkOperatorName;
    NSString* PhoneSerialNo;
    
    NSString* LastOperationid;
    NSString* LastNumbers;
    
    AVCaptureStillImageOutput * stillImageOutput;
    BOOL _isFlashAvailable;
    BOOL flashState;
    
    enum Esh7NErrorCodes : NSUInteger {
        ErrorUnexpected = -2,
        NoError = -1,
        SuccessfullInitialization = 0,
        ErrorInvalidAppidOrAppsecret = 1,
        ErrorInvalidImageFile = 2,
        ErrorServerDown = 3,
        ErrorOperationidNotfound = 4,
        ErrorTrialHasEnded = 5
    };
}


@synthesize FlashButton, CameraLayout, CameraOverlay, progressSpinner, CaptureBtn,LastOperationBtn;
@synthesize captureDevice;
@synthesize captureSession;

- (void) viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

    
#if !(TARGET_IPHONE_SIMULATOR)
    self.captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [FlashButton setEnabled:(_isFlashAvailable = self.captureDevice.hasTorch)];
#endif
    
    // Init Esh7n
	// Request your Credentials from info@byorca.com
    AppId = <APPID>;
    APPSecret = <APPSECRET>;
    MinDetectedNumbers = @"6";
    isTestMode = true;
    [self InitAPI];
    /////////////////////////////////////////////
    CTTelephonyNetworkInfo* info = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier* carrier = info.subscriberCellularProvider;
 
    Country = carrier.mobileCountryCode;
    Manufacture = @"Apple";
    UIDevice* device = [UIDevice  currentDevice];
    Model = [device model];
    OS = [[[device systemName] stringByAppendingString:@" - "] stringByAppendingString: [device  systemVersion]];
    NetworkOperatorName = carrier.carrierName;
    PhoneSerialNo = [[[UIDevice currentDevice]  identifierForVendor] UUIDString] ;
    
    LastOperationid = @"";
    LastNumbers = @"";
}
- (void) didReceiveMemoryWarning  {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) viewWillDisappear:(BOOL)animated {
    [[self.navigationController navigationBar] setHidden:false];
}
- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
#if !(TARGET_IPHONE_SIMULATOR)
    [self startCaptureSession];
#endif
}
- (void) viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	
#if !(TARGET_IPHONE_SIMULATOR)
    [self stopCaptureSession];
#endif
}
- (void) appDidBecomeActive:(NSNotification *)notification {
    if (flashState) [self turnLightOn];
}
- (void) appDidEnterForeground:(NSNotification *)notification {
    [self turnLightOff];
}

#pragma mark - IBActions
- (IBAction) FlashButton_Touch:(id)sender {
    
    flashState = !flashState;
    
    if (flashState ) {
        [self turnLightOn];
    }
    else
        [self turnLightOff];
    
    
    
}
- (IBAction) CaptureButton_Touch:(id)sender {
    [self startProgress];
    [self capImage];
}
- (IBAction) LastNo_Touch:(id)sender {
    
    NSString* trimmedLastOperationid = [LastOperationid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet] ];
    if([trimmedLastOperationid length] == 0){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Warning"
                                                        message: @"No Last Operation found"
                                                       delegate:self
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        [alert show];
    
    }else{
        [self startProgress];
        [self GetNumbersByLastOperationid];
    }
}

#pragma mark - Flash Functions
- (void) turnLightOn {
    if(!_isFlashAvailable) return;
    
    @synchronized(self) {
        [self.captureSession beginConfiguration];
        [self.captureDevice lockForConfiguration:nil];
        [self.captureDevice setTorchMode:AVCaptureTorchModeOn];
        [self.captureDevice unlockForConfiguration];
        [self.captureSession commitConfiguration];
    }
}
- (void) turnLightOff {
    if(!_isFlashAvailable) return;
    @synchronized(self) {
        [self.captureSession beginConfiguration];
        [self.captureDevice lockForConfiguration:nil];
        [self.captureDevice setTorchMode:AVCaptureTorchModeOff];
        [self.captureDevice unlockForConfiguration];
        [self.captureSession commitConfiguration];
    }
}

#pragma mark - Progress Functions
- (void) startProgress {
    @synchronized(self) {
        [progressSpinner setHidden: false];
        [CaptureBtn setEnabled:false];
        [LastOperationBtn setEnabled:false];
        [FlashButton setEnabled:false];
        
    }
}
- (void) stopProgress {
    @synchronized(self) {
        [progressSpinner setHidden: true];
        [CaptureBtn setEnabled:true];
        [LastOperationBtn setEnabled:true];
        [FlashButton setEnabled:true];
    }
}

#pragma mark - Capture Session Functions
- (void) startCaptureSession {
    if (!_isFlashAvailable) return;
    
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession addInput:[AVCaptureDeviceInput
                                   deviceInputWithDevice:self.captureDevice
                                   error:nil]];
    
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
	
    CGRect frame = self.CameraLayout.frame;
    frame.size.height = frame.size.height  + frame.origin.y;
    frame.origin.y = 0;
	captureVideoPreviewLayer.frame = frame;
    
    
    captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
	[self.CameraLayout.layer addSublayer:captureVideoPreviewLayer];
    
    [self.captureSession beginConfiguration];
    [self.captureDevice lockForConfiguration:nil];
    [self.captureDevice setTorchMode:AVCaptureTorchModeAuto];
    [self.captureDevice unlockForConfiguration];
    [self.captureSession commitConfiguration];
    
    stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [stillImageOutput setOutputSettings:outputSettings];
    
    [self.captureSession addOutput:stillImageOutput];
    
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
    }else
        if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
            self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
        }
    
    [self.captureSession startRunning];

}
- (void) stopCaptureSession {
    if (!_isFlashAvailable || !self.captureSession) return;
    
    [self.captureSession stopRunning];
    self.captureSession = nil;
    [self turnLightOff];
}
- (void) resumeCaptureSession {
    if (!_isFlashAvailable || !self.captureSession) return;
    
    if (flashState) [self turnLightOn];
    [self.captureSession startRunning];
}
- (void) pauseCaptureSession {
    if (!_isFlashAvailable || !self.captureSession) return;
    
    [self.captureSession stopRunning];
    [self turnLightOff];
    
}


#pragma mark - Utilities
- (UIImage*) fixOrientationOfImage:(UIImage *)image {
    
    // No-op if the orientation is already correct
    if (image.imageOrientation == UIImageOrientationUp) return image;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}
- (void) capImage { //method to capture image from AVCaptureSession video feed
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in stillImageOutput.connections) {
        
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                break;
            }
        }
        
        if (videoConnection) {
            break;
        }
    }
    
    if ([videoConnection isVideoOrientationSupported]) {
        [videoConnection  setVideoOrientation: AVCaptureVideoOrientationPortrait];
    }
    
    NSLog(@"about to request a capture from: %@", stillImageOutput);
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        
        if (imageSampleBuffer != NULL) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
            
            UIImage* capturedImage = [self fixOrientationOfImage:[UIImage imageWithData:imageData]];
            [self pauseCaptureSession];
            
            @synchronized(self) {
                [self processImage: capturedImage];
            }
            
        }
    }];
}
- (void) processImage:(UIImage *)image {
    
    
    float w1 = 0.f;     float h1 = 0.f;
    float w = 0.f;     float h = 0.f;
    float x = 0.f;     float y = 0.f;
    
    float w3 = 0.f;     float w4 = 0.f;
    float h3 = 0.f;     float h4 = 0.f;
    float x1 = 20.f;     float y1 = 80.f;
    
    w1 = image.size.width;  h1 = image.size.height;
    
    w3 = CameraLayout.frame.size.width;  h3 = CameraLayout.frame.size.height;
    w4 = 280.f;  h4 = CameraOverlay.cardframe.size.height;
    
    
    
    float Rw = w1/w3;    float Rh = h1/h3;
    
    w = Rw * w4;
    h = Rh * h4;
    x = Rw * x1;
    y = Rh * y1;
    
    
    CGRect clippedRect  = CGRectMake(x, y, w, h);
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], clippedRect);
    UIImage *newImage   = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    [self DetectNumbers:newImage];
    
    
}


#pragma mark - Alerts
- (void) showNumbers: (NSString*) Numbers{
    NSString* trimmedNo = [Numbers stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet] ];
    NSString* message = @"Number is: ";
    message = [message stringByAppendingString:Numbers];
        
    NSString* title = @"Operation Id: ";
    title = [title stringByAppendingString:LastOperationid];
    
    if([trimmedNo length] == 0){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: title
                                                        message: @"No Number Detected!"
                                                       delegate:self
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        [alert show];
    }
    else{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: title
                                                    message: message
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:@"Send Recharged Flag", nil];
    
    
    [alert show];
}
}
- (void) showLastOperationNumbers: (NSString*) Numbers{
    NSString* trimmedNo = [Numbers stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet] ];
    NSString* message = @"Number is: ";
    message = [message stringByAppendingString:Numbers];
    
    if([trimmedNo length] == 0) message = @"No Number Detected!";
    
    NSString* title = @"Operation Id: ";
    title = [title stringByAppendingString:LastOperationid];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: title
                                                    message: message
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles: nil];
    [alert show];
    
}
- (void) sendFlagSuccess{

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Success"
                                                    message: @"Send Recharged Flag is successfully"
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles: nil];
    [alert show];
    
}
- (void) showError: (int) errorNo{
    NSString* errorMessage = [self getMessageFromErrorNo:errorNo];
    NSString* message = @"Error: ";
    message = [message stringByAppendingString:errorMessage];
    
    NSString* title = @"Operation Id: ";
    title = [title stringByAppendingString:LastOperationid];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: title
                                                      message: message
                                                     delegate:self
                                            cancelButtonTitle:@"Ok"
                                            otherButtonTitles:nil];
    [alert show];
    
}
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self resumeCaptureSession];
    if(buttonIndex == 1){
        [self startProgress];
        [self SendRechargeFlag];
    }
}

-(NSString*) getMessageFromErrorNo:(int) errorNo{
    
    switch(errorNo) {
        case -2:
            return @"Unexpected Error Occur";
        case -1:
            return @"No Errors Found";
        case 0:
            return @"Successful Initialization API";
        case 1:
            return @"Invalid AppId or AppSecret";
        case 2:
            return @"Invalid Image Data";
        case 3:
            return @"Server is down";
        case 4:
            return @"Operation Id is not found";
        case 5:
            return @"Expired Account";
    }
    return @"";
}

#pragma mark - Network Tasks
-(void) InitAPI {
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *delegateFreeSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: self delegateQueue: [NSOperationQueue mainQueue]];
    
    NSString* url = @"http://esh7n.byorca.com/InitAPI?";
    
    
    if (![AppId isEqualToString:@""]) {
        url = [url stringByAppendingFormat:@"appId=%@", AppId ];
    }
    if (![APPSecret isEqualToString:@""]) {
        url = [url stringByAppendingFormat:@"&appSecret=%@", APPSecret ];
    }
    NSURL *rurl = [NSURL URLWithString: [url stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    
    
    NSURLSessionDataTask * dataTask = [delegateFreeSession dataTaskWithURL:rurl
                                                         completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                             [self stopProgress];
                                                             if(error == nil)
                                                             {
                                                                 NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                                                 
                                                                 NSError *e;
                                                                 NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&e];
                                                                 
                                                                 if (e!=Nil) {
                                                                     [self showError:ErrorServerDown];
                                                                 }else{
                                                                     
                                                                    //successful initialiazation
                                                                 }
                                                                 
                                                                 NSLog(@"Data = %@",text);
                                                             }
                                                             else
                                                                 [self showError:ErrorServerDown];
                                                             
                                                         }];
    
    [dataTask resume];
    
}
-(void) GetNumbersByLastOperationid {
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *delegateFreeSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: self delegateQueue: [NSOperationQueue mainQueue]];
    
    NSString* url = @"http://esh7n.byorca.com/GetNumbersByOperationid?";
    
    
    if (![AppId isEqualToString:@""]) {
        url = [url stringByAppendingFormat:@"appId=%@", AppId ];
    }
    if (![APPSecret isEqualToString:@""]) {
        url = [url stringByAppendingFormat:@"&appSecret=%@", APPSecret ];
    }
    if (![LastOperationid isEqualToString:@""]) {
        url = [url stringByAppendingFormat:@"&Operationid=%@", LastOperationid ];
    }
    NSURL *rurl = [NSURL URLWithString: [url stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    
    
    NSURLSessionDataTask * dataTask = [delegateFreeSession dataTaskWithURL:rurl
                                                         completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                             [self stopProgress];
                                                             if(error == nil)
                                                             {
                                                                 NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                                                 
                                                                 NSError *e;
                                                                 NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&e];
                                                                 
                                                                 if (e!=Nil) {
                                                                     [self showError:ErrorServerDown];
                                                                 }else{
                                                                     LastOperationid = [dict objectForKey:@"Operationid"];
                                                                     
                                                                     LastNumbers = [dict objectForKey:@"Numbers"];
                                                                     
                                                                     int Errorno = [(NSNumber*)[dict objectForKey:@"Errorno"] integerValue];
                                                                     
                                                                     if(Errorno == NoError)
                                                                         [self showLastOperationNumbers:LastNumbers];
                                                                     else
                                                                         [self showError:Errorno];
                                                                 }
                                                                 
                                                                 NSLog(@"Data = %@",text);
                                                             }
                                                             else
                                                                 [self showError:ErrorServerDown];
                                                             
                                                         }];
    
    [dataTask resume];
    
}
-(void) DetectNumbers:(UIImage *)image {
    NSData *imageData = UIImagePNGRepresentation(image);
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[imageData length]];
    
    // Init the URLRequest
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"POST"];
    NSString* url = @"http://esh7n.byorca.com/DetectNumbers?";
    
    
    if (![AppId isEqualToString:@""]) {
        url = [url stringByAppendingFormat:@"appId=%@", AppId ];
    }
    if (![APPSecret isEqualToString:@""]) {
        url = [url stringByAppendingFormat:@"&appSecret=%@", APPSecret ];
    }
    if (![Country isEqualToString:@""]) {
        url = [url stringByAppendingFormat:@"&country=%@", Country ];
    }
    if (![Manufacture isEqualToString:@""]) {
        url = [url stringByAppendingFormat:@"&manufacture=%@", Manufacture ];
    }
    if (![Model isEqualToString:@""]) {
        url = [url stringByAppendingFormat:@"&model=%@", Model ];
    }
    if (![OS isEqualToString:@""]) {
        url = [url stringByAppendingFormat:@"&os=%@", OS ];
    }
    if (![NetworkOperatorName isEqualToString:@""]) {
        url = [url stringByAppendingFormat:@"&networkOperatorName=%@", NetworkOperatorName ];
    }
    if (![PhoneSerialNo isEqualToString:@""]) {
        url = [url stringByAppendingFormat:@"&phoneSerialNo=%@", PhoneSerialNo ];
    }
    if (![MinDetectedNumbers isEqualToString:@""]) {
        url = [url stringByAppendingFormat:@"&minDetectedNumbers=%@", MinDetectedNumbers ];
    }
    
    url = [url stringByAppendingFormat:@"&isTestMode=%@", isTestMode ? @"true" : @"false"];
    

    NSURL *rurl = [NSURL URLWithString: [url stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    
    [request setURL: rurl ];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:imageData];
    
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *delegateFreeSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: self delegateQueue: [NSOperationQueue mainQueue]];
    NSURLSessionDataTask * dataTask = [delegateFreeSession dataTaskWithRequest:request
                                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                 [self stopProgress];
                                                                 if(error == nil)
                                                                 {
                                                                     NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                                                     
                                                                     NSError *e;
                                                                     NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&e];
                                                                     
                                                                     if (e!=Nil) {
                                                                         [self showError:ErrorServerDown];
                                                                     }else{
                                                                         LastOperationid = [dict objectForKey:@"Operationid"];
                                                                         
                                                                         LastNumbers = [dict objectForKey:@"Numbers"];
                                                                         
                                                                         int Errorno = [(NSNumber*)[dict objectForKey:@"Errorno"] integerValue];
                                                                         
                                                                         if(Errorno == NoError)
                                                                           [self showNumbers:LastNumbers];
                                                                         else
                                                                           [self showError:Errorno];
                                                                     }
                                                                     
                                                                     NSLog(@"Data = %@",text);
                                                                 }
                                                                 else
                                                                     [self showError:ErrorServerDown];
                                                                 
                                                             }];
    
    [dataTask resume];
    
}
-(void) SendRechargeFlag {
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *delegateFreeSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: self delegateQueue: [NSOperationQueue mainQueue]];
    
    NSString* url = @"http://esh7n.byorca.com/SendRechargeFlag?";
    
    
    if (![AppId isEqualToString:@""]) {
        url = [url stringByAppendingFormat:@"appId=%@", AppId ];
    }
    if (![APPSecret isEqualToString:@""]) {
        url = [url stringByAppendingFormat:@"&appSecret=%@", APPSecret ];
    }
    if (![LastOperationid isEqualToString:@""]) {
        url = [url stringByAppendingFormat:@"&Operationid=%@", LastOperationid ];
    }
    NSURL *rurl = [NSURL URLWithString: [url stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    
    
    NSURLSessionDataTask * dataTask = [delegateFreeSession dataTaskWithURL:rurl
                                                         completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                             [self stopProgress];
                                                             if(error == nil)
                                                             {
                                                                 NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                                                 
                                                                 NSError *e;
                                                                 NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&e];
                                                                 
                                                                 if (e!=Nil) {
                                                                     [self showError:ErrorServerDown];
                                                                 }else{
                                                                     LastOperationid = [dict objectForKey:@"Operationid"];
                                                                     
                                                                     
                                                                     int Errorno = [(NSNumber*)[dict objectForKey:@"Errorno"] integerValue];
                                                                     
                                                                     if(Errorno == NoError)
                                                                         [self sendFlagSuccess];
                                                                     else
                                                                         [self showError:Errorno];
                                                                 }
                                                                 
                                                                 NSLog(@"Data = %@",text);
                                                             }
                                                             else
                                                                 [self showError:ErrorServerDown];
                                                             
                                                         }];
    
    [dataTask resume];
    
}
@end// create request





