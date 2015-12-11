//
//  ViewController.m
//  QRCodeDemo
//
//  Created by xulihua on 15/12/4.
//  Copyright © 2015年 huage. All rights reserved.
//

#import "ViewController.h"
#import "QRCodeGenerator.h"
#import "ZBarReaderController.h"
#import "QRScanViewController.h"
#import "UIView+QREasyFrame.h"
#import "QRCodeCommon.h"
#import "UIImage+QRScale.h"

@interface ViewController () <UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic, strong) UITextField *codeTF;
@property (nonatomic, strong) UIImageView *headerImageView;
@property (nonatomic, strong) UIButton *button1;
@property (nonatomic, strong) UIButton *button2;
@property (nonatomic, strong) UIButton *button3;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"扫一扫";
    UITapGestureRecognizer *tapGr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    tapGr.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGr];
    
    
    [self.view addSubview:self.codeTF];
    [self.view addSubview:self.headerImageView];
    [self.view addSubview:self.button1];
    [self.view addSubview:self.button2];
    [self.view addSubview:self.button3];
    
    
}

-(void)viewTapped:(UITapGestureRecognizer*)tapGr
{
    [self.view endEditing:YES];
}



//encode
- (UIImage *)encodeQRImageWithContent:(NSString *)content size:(CGSize)size {
    UIImage *codeImage = nil;
    if (iOS8_OR_LATER) {
        NSData *stringData = [content dataUsingEncoding: NSUTF8StringEncoding];
        
        //生成
        CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
        [qrFilter setValue:stringData forKey:@"inputMessage"];
        [qrFilter setValue:@"M" forKey:@"inputCorrectionLevel"];
        
        UIColor *onColor = [UIColor blackColor];
        UIColor *offColor = [UIColor whiteColor];
        
        //上色
        CIFilter *colorFilter = [CIFilter filterWithName:@"CIFalseColor"
                                           keysAndValues:
                                 @"inputImage",qrFilter.outputImage,
                                 @"inputColor0",[CIColor colorWithCGColor:onColor.CGColor],
                                 @"inputColor1",[CIColor colorWithCGColor:offColor.CGColor],
                                 nil];
        
        CIImage *qrImage = colorFilter.outputImage;
        CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:qrImage fromRect:qrImage.extent];
        UIGraphicsBeginImageContext(size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetInterpolationQuality(context, kCGInterpolationNone);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextDrawImage(context, CGContextGetClipBoundingBox(context), cgImage);
        codeImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        CGImageRelease(cgImage);
    } else {
        codeImage = [QRCodeGenerator qrImageForString:content imageSize:size.width];
    }
    return codeImage;
}


//decode
- (NSString *)decodeQRImageWith:(UIImage*)aImage {
    NSString *qrResult = nil;
    if (aImage.size.width < 641) {
        aImage = [aImage TransformtoSize:CGSizeMake(640, 640)];
    }
    //iOS8及以上可以使用系统自带的识别二维码图片接口，但此api有问题，在一些机型上detector为nil。
    
    //    if (iOS8_OR_LATER) {
    //        CIContext *context = [CIContext contextWithOptions:nil];
    //        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:context options:@{CIDetectorAccuracy:CIDetectorAccuracyHigh}];
    //        CIImage *image = [CIImage imageWithCGImage:aImage.CGImage];
    //        NSArray *features = [detector featuresInImage:image];
    //        CIQRCodeFeature *feature = [features firstObject];
    //
    //        qrResult = feature.messageString;
    //    } else {
    
    ZBarReaderController* read = [ZBarReaderController new];
    CGImageRef cgImageRef = aImage.CGImage;
    ZBarSymbol* symbol = nil;
    for(symbol in [read scanImage:cgImageRef]) break;
    qrResult = symbol.data ;
    return qrResult;
}

- (void)buttonAction:(UIButton *)sender {
    
    switch (sender.tag) {
        case 0:{
            QRScanViewController *vc = [[QRScanViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
            
        case 1:{
            UIImagePickerController *photoPicker = [[UIImagePickerController alloc] init];
            
            photoPicker.delegate = self;
            photoPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            photoPicker.view.backgroundColor = [UIColor whiteColor];
            [self presentViewController:photoPicker animated:YES completion:NULL];
        }
            break;
            
        case 2:{
            self.headerImageView.image = [self encodeQRImageWithContent:self.codeTF.text size:CGSizeMake(100, 100)];
        }
            break;
            
        default:
            break;
    }
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
    
    UIImage * srcImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    
    NSString *result = [self decodeQRImageWith:srcImage];
    
    if ( result )
    {
        UIAlertController *alterVC = [UIAlertController alertControllerWithTitle:@"提示" message:result preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        [alterVC addAction:confirmAction];
        [self presentViewController:alterVC animated:YES completion:nil];
    }
}

#pragma mark - getter

-(UITextField *)codeTF {
    if (_codeTF == nil) {
        _codeTF = [[UITextField alloc] initWithFrame:CGRectMake(10, 30, kScreenWidth-100, 40)];
        _codeTF.centerX = self.view.centerX;
        _codeTF.text = @"haaaaaaaaha";
        _codeTF.borderStyle = UITextBorderStyleRoundedRect;
    }
    return _codeTF;
}

-(UIImageView *)headerImageView {
    if (_headerImageView == nil) {
        _headerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.codeTF.bottom + 20, 100, 100)];
        _headerImageView.centerX = self.view.centerX;
        _headerImageView.image = [UIImage imageNamed:@"11.jpg"];
    }
    return _headerImageView;
}

-(UIButton *)button1 {
    if (_button1 == nil) {
        
        _button1 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _button1.frame = CGRectMake(0, self.headerImageView.bottom + 30, 200, 44);
        _button1.centerX = self.view.centerX;
        [_button1 setTitle:@"扫一扫" forState:UIControlStateNormal];
        [_button1 addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        _button1.tag = 0;
    }
    return _button1;
}

-(UIButton *)button2 {
    if (_button2 == nil) {
        
        _button2 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _button2.frame = CGRectMake(0, self.button1.bottom + 30, 200, 44);
        _button2.centerX = self.view.centerX;
        [_button2 setTitle:@"识别二维码" forState:UIControlStateNormal];
        [_button2 addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        _button2.tag = 1;
    }
    return _button2;
}

-(UIButton *)button3 {
    if (_button3 == nil) {
        
        _button3 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _button3.frame = CGRectMake(0, self.button2.bottom + 30, 200, 44);
        _button3.centerX = self.view.centerX;
        [_button3 setTitle:@"生成二维码" forState:UIControlStateNormal];
        [_button3 addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        _button3.tag = 2;
    }
    return _button3;
}
@end
