//
//  IMEQRCodeScanViewController.h
//  NDQRCodeScannerDemo
//
//  Created by xulihua on 15/10/14.
//  Copyright (c) 2015年 huage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol QRCodeScanDelegate;

@interface QRScanViewController : UIViewController

@property (nonatomic, weak) id<QRCodeScanDelegate> delegate;

- (void)startScan;
- (void)stopScan;

@end

@protocol QRCodeScanDelegate <NSObject>

- (void)scanController:(QRScanViewController *)scanController
           didScanResult:(NSString *)result
              isTwoDCode:(BOOL)isTwoDCode;

@end