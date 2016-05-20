//
//  IMEQRCodeScanViewController
//  NDQRCodeScannerDemo
//
//  Created by xulihua on 15/10/14.
//  Copyright (c) 2015年 huage. All rights reserved.
//

#import "QRScanViewController.h"
#import "UIView+QREasyFrame.h"
#import <AVFoundation/AVFoundation.h>
#import "QRCodeCommon.h"



@interface QRScanViewController() <AVCaptureMetadataOutputObjectsDelegate>
{
    dispatch_queue_t _queue;
    BOOL             _isBarScrolling;
    CGRect           _cropRect;
    BOOL             _scanFinished;
}

@property (nonatomic, strong) UIImageView *scrollBar;   //滚动条
@property (nonatomic, strong) CALayer *headerLabel;      //视图上面的影阴
@property (nonatomic, strong) CALayer *footerLabel;      //视图下面的影阴
@property (nonatomic, strong) CALayer *rightLabel;      //视图右面的影阴
@property (nonatomic, strong) CALayer *leftLabel;      //视图左面的影阴


@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *prevLayer;
@property (nonatomic, strong) AVCaptureMetadataOutput *captureOutput;
@property (nonatomic, strong) UIView *blackCoverView;  //遮罩视图
@property (nonatomic, strong) UIActivityIndicatorView *activityView;
@end

@implementation QRScanViewController

- (void)dealloc
{
    _queue = nil;
    [self.captureSession stopRunning];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(onVideoStart:)
                                                     name: AVCaptureSessionDidStartRunningNotification
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(onVideoStop:)
                                                     name: AVCaptureSessionDidStopRunningNotification
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(onVideoStop:)
                                                     name: AVCaptureSessionWasInterruptedNotification
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(onVideoStart:)
                                                     name: AVCaptureSessionInterruptionEndedNotification
                                                   object: nil];
        
        _queue = dispatch_queue_create("com.nd.scan", NULL);
        
        if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
            self.edgesForExtendedLayout = UIRectEdgeNone;
        }
        self.title = @"二维码";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height - 64;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(30, 0, kQRReaderScanWidth, 70)];
    label.font = [UIFont systemFontOfSize:16.0];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    label.text = @"将二维码置于取景框中心，即可自动扫描";
    label.numberOfLines = 3;
    label.centerX = self.view.centerX;
    label.textAlignment = NSTextAlignmentCenter;
    
    
    CGFloat textLabelHeight = [label.text boundingRectWithSize:
                               CGSizeMake(label.frame.size.width, CGFLOAT_MAX)
                                                            options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName: label.font}
                                                            context:nil].size.height ;
    
    CGFloat vLblHeight = (screenHeight-kQRReaderScanHeight-textLabelHeight - kQRReaderScanLabelSpace)/2;
    label.height = textLabelHeight;
    label.top = vLblHeight + kQRReaderScanHeight + kQRReaderScanLabelSpace;
    [self.view addSubview:label];
    
    self.headerLabel.frame = CGRectMake(0, 0, screenWidth, vLblHeight);
    self.footerLabel.frame = CGRectMake(0, vLblHeight + kQRReaderScanHeight, screenWidth, screenHeight - label.top + kQRReaderScanLabelSpace);
    
    CGFloat hLblWidth = (screenWidth-kQRReaderScanWidth)/2;
    self.leftLabel.frame = CGRectMake(0, vLblHeight, hLblWidth, kQRReaderScanHeight);
    self.rightLabel.frame = CGRectMake(screenWidth-hLblWidth, vLblHeight, hLblWidth, kQRReaderScanHeight);
    
    CGRect cropRect = CGRectMake(hLblWidth, vLblHeight, kQRReaderScanWidth, kQRReaderScanHeight);
    _cropRect = cropRect;
    
    
    [self.view.layer addSublayer:self.headerLabel];
    [self.view.layer addSublayer:self.footerLabel];
    [self.view.layer addSublayer:self.rightLabel];
    [self.view.layer addSublayer:self.leftLabel];
    
    
    
    //添加四个小图片和边框
    
    {//上边
        UIView *rimView = [[UIView alloc] init];
        rimView.backgroundColor = RGBACOLOR(221, 221, 221, 1.0);
        rimView.frame = CGRectMake(CGRectGetMinX(cropRect), CGRectGetMinY(cropRect) - 1, CGRectGetWidth(cropRect), 1);
        [self.view addSubview:rimView];

    }
    {//下边
        
        UIView *rimView = [[UIView alloc] init];
        rimView.backgroundColor = RGBACOLOR(221, 221, 221, 1.0);
        rimView.frame = CGRectMake(CGRectGetMinX(cropRect), CGRectGetMaxY(cropRect), CGRectGetWidth(cropRect), 1);
        [self.view addSubview:rimView];
    }
    {//左边
        UIView *rimView = [[UIView alloc] init];
        rimView.backgroundColor = RGBACOLOR(221, 221, 221, 1.0);
        rimView.frame = CGRectMake(CGRectGetMinX(cropRect)-1, CGRectGetMinY(cropRect), 1, CGRectGetHeight(cropRect));
        [self.view addSubview:rimView];
    }
    
    {//右边
        UIView *rimView = [[UIView alloc] init];
        rimView.backgroundColor = RGBACOLOR(221, 221, 221, 1.0);
        rimView.frame = CGRectMake(CGRectGetMaxX(cropRect), CGRectGetMinY(cropRect), 1, CGRectGetHeight(cropRect));
        [self.view addSubview:rimView];
    }
    
    {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.image = [UIImage imageNamed:@"chat_code_pic_angle_ul.png"];
        imageView.frame = CGRectMake(CGRectGetMinX(cropRect)-4, CGRectGetMinY(cropRect)-4, 16, 16);
        [self.view addSubview:imageView];
    }
    {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.image = [UIImage imageNamed:@"chat_code_pic_angle_ur.png"];
        imageView.frame = CGRectMake(CGRectGetMaxX(cropRect)-12, CGRectGetMinY(cropRect)-4, 16, 16);
        [self.view addSubview:imageView];
    }
    {
        
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.image = [UIImage imageNamed:@"chat_code_pic_angle_ll.png"];
        imageView.frame = CGRectMake(CGRectGetMinX(cropRect)-4, CGRectGetMaxY(cropRect)-12, 16, 16);
        [self.view addSubview:imageView];
    }
    {
        
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.image = [UIImage imageNamed:@"chat_code_pic_angle_lr.png"];
        imageView.frame = CGRectMake(CGRectGetMaxX(cropRect)-12, CGRectGetMaxY(cropRect)-12, 16, 16);
        [self.view addSubview:imageView];
    }
    
    [self.view addSubview:self.scrollBar];
    [self.view addSubview:self.blackCoverView];
    
    [self initCapture];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (![self.captureSession isRunning]) {
        self.blackCoverView.alpha = 0.8;
        [self.captureSession startRunning];
    }
    _scanFinished = NO;
}

//fix bug:多次进入扫一扫界面，再退出，因此界面未被系统回收，captureSession对象一直在运行，会造成内存
//泄露，引起界面卡顿。
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if ([self.captureSession isRunning]) {
        [self.captureSession stopRunning];
    }
}

#pragma mark - capture

- (void)startScan
{
    if (![self.captureSession isRunning]) {
        [self.captureSession startRunning];
        _scanFinished = NO;
    }
}

- (void)stopScan
{
    if ([self.captureSession isRunning]) {
        [self.captureSession stopRunning];
        _scanFinished = YES;
    }
}

- (void)initCapture
{
    AVCaptureDevice* inputDevice =
    [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    [inputDevice lockForConfiguration:nil];
    if ([inputDevice hasTorch])
    {
        inputDevice.torchMode = AVCaptureTorchModeAuto;
    }
    [inputDevice unlockForConfiguration];
    
    AVCaptureDeviceInput *captureInput =
    [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:nil];
    
    if (!captureInput) {
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
        {
            
            UIAlertController *alterVC = [UIAlertController alertControllerWithTitle:@"系统提示" message:@"您已关闭相机使用权限，请至手机“设置->隐私->相机”中打开" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
            [alterVC addAction:confirmAction];
            [self presentViewController:alterVC animated:YES completion:nil];
            
        }
        else
        {
            UIAlertController *alterVC = [UIAlertController alertControllerWithTitle:@"系统提示" message:@"未能找到相机设备" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
            [alterVC addAction:confirmAction];
            [self presentViewController:alterVC animated:YES completion:nil];
        }
        
        return;
    }
    
    AVCaptureMetadataOutput *captureOutput = [[AVCaptureMetadataOutput alloc] init];
    [captureOutput setMetadataObjectsDelegate:self queue:_queue];
    self.captureOutput = captureOutput;
    
    self.captureSession = [[AVCaptureSession alloc] init];
    
    [self.captureSession addInput:captureInput];
    [self.captureSession addOutput:captureOutput];
    
    CGFloat w = 1920.f;
    CGFloat h = 1080.f;
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
        self.captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
    } else if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
        w = 1280.f;
        h = 720.f;
    } else if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
        w = 960.f;
        h = 540.f;
    }
    captureOutput.metadataObjectTypes = [captureOutput availableMetadataObjectTypes];
    CGRect bounds = [[UIScreen mainScreen] bounds];
    
    
    if (!self.prevLayer) {
        self.prevLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    }
    // NSLog(@"prev %p %@", self.prevLayer, self.prevLayer);
    self.prevLayer.frame = bounds;
    self.prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    [self.view.layer insertSublayer:self.prevLayer atIndex:0];
    
//    计算rectOfInterest
    CGFloat p1 = bounds.size.height/bounds.size.width;
    CGFloat p2 = w/h;
    
    CGRect cropRect = CGRectMake(CGRectGetMinX(_cropRect) - kQRReaderScanExpandWidth, CGRectGetMinY(_cropRect) - kQRReaderScanExpandHeight, CGRectGetWidth(_cropRect) + 2*kQRReaderScanExpandWidth, CGRectGetHeight(_cropRect) + 2*kQRReaderScanExpandHeight);
    
//    CGRect cropRect = _cropRect;
    if (fabs(p1 - p2) < 0.00001) {
        captureOutput.rectOfInterest = CGRectMake(cropRect.origin.y /bounds.size.height,
                                                  cropRect.origin.x/bounds.size.width,
                                                  cropRect.size.height/bounds.size.height,
                                                  cropRect.size.width/bounds.size.width);
    } else if (p1 < p2) {
        //实际图像被截取一段高
        CGFloat fixHeight = bounds.size.width * w / h;
        CGFloat fixPadding = (fixHeight - bounds.size.height)/2;
        captureOutput.rectOfInterest = CGRectMake((cropRect.origin.y + fixPadding)/fixHeight,
                                                  cropRect.origin.x/bounds.size.width,
                                                  cropRect.size.height/fixHeight,
                                                  cropRect.size.width/bounds.size.width);
    } else {
        CGFloat fixWidth = bounds.size.height * h / w;
        CGFloat fixPadding = (fixWidth - bounds.size.width)/2;
        captureOutput.rectOfInterest = CGRectMake(cropRect.origin.y/bounds.size.height,
                                                  (cropRect.origin.x + fixPadding)/fixWidth,
                                                  cropRect.size.height/bounds.size.height,
                                                  cropRect.size.width/fixWidth);
    }
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (!_scanFinished) {
        if ([metadataObjects count]) {
            for (AVMetadataObject *obj in metadataObjects) {
            
                if ([obj isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
                    
                    [self stopScan];
                    AVMetadataMachineReadableCodeObject *codeObj = (AVMetadataMachineReadableCodeObject *)obj;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                            self.blackCoverView.alpha = 0.8;
                            
                        } completion:^(BOOL finished) {
                            
                        }];
                        
                        UIAlertController *alterVC = [UIAlertController alertControllerWithTitle:@"提示" message:codeObj.stringValue preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
                        [alterVC addAction:confirmAction];
                        [self presentViewController:alterVC animated:YES completion:nil];
                        
                        if ([self.delegate respondsToSelector:@selector(scanController:didScanResult:isTwoDCode:)]) {
                            [self.delegate scanController:self didScanResult:codeObj.stringValue isTwoDCode:[codeObj.type isEqualToString:AVMetadataObjectTypeQRCode]];
                        }
                    });
                    
                    break;
                }
            }
        }
    }
}

#pragma mark - video

- (void)onVideoStart: (NSNotification*) note
{
    [self startScrollBar];
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        self.blackCoverView.alpha = 0.0;
        
    } completion:^(BOOL finished) {
        
    }];
    
}

- (void)onVideoStop: (NSNotification*) note
{
    [self stopScrollBar];
    
}

- (void)startScrollBar
{
    self.scrollBar.hidden = NO;
    _isBarScrolling = YES;
    self.scrollBar.frame = CGRectMake(_cropRect.origin.x, CGRectGetMinY(_cropRect), self.scrollBar.frame.size.width, self.scrollBar.frame.size.height);
    [self setScrollBarPositionAnimatied];
}

- (void)stopScrollBar
{
    self.scrollBar.hidden = YES;
    _isBarScrolling = NO;
}

- (void)setScrollBarPositionAnimatied
{
    if (_isBarScrolling)
    {
        [UIView animateWithDuration:2.0f delay:0.0f
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             
                             self.scrollBar.frame = CGRectMake(_cropRect.origin.x, CGRectGetMaxY(_cropRect) - 7, self.scrollBar.frame.size.width, self.scrollBar.frame.size.height);
                             
                         } completion:^(BOOL finished) {
                             
                             self.scrollBar.frame = CGRectMake(_cropRect.origin.x, CGRectGetMinY(_cropRect), self.scrollBar.frame.size.width, self.scrollBar.frame.size.height);
                             
                             [self setScrollBarPositionAnimatied];
                         }];
    }
}

#pragma mark - actions

//- (void)CancelClicked:(id)sender
//{
//    [self dismissViewControllerAnimated:YES completion:^{
//        
//        if ([_delegate respondsToSelector:@selector(scanControllerCancelButtonTapped:)]) {
//            [_delegate scanControllerCancelButtonTapped:self];
//        }
//        
//    }];
//}
//
//- (void)DoneClicked:(id)sender
//{
//    if ([_delegate respondsToSelector:@selector(scanControllerScanHistoryButtonTapped:)]) {
//        [_delegate scanControllerScanHistoryButtonTapped:self];
//    }
//}

#pragma mark - setter

- (UIImageView *)scrollBar
{
    if (!_scrollBar) {
        _scrollBar = [[UIImageView alloc] init];
        _scrollBar.frame = CGRectMake(0, 0, kQRReaderScanWidth, 2.5);
        _scrollBar.image = [UIImage imageNamed:@"chat_code_pic_line.png"];
        _scrollBar.contentMode = UIViewContentModeScaleToFill;
    }
    return _scrollBar;
}

//头部影阴
- (CALayer *)headerLabel
{
    if (!_headerLabel)
    {
        _headerLabel = [[CALayer alloc] init];
        _headerLabel.frame = CGRectMake(0, 0, 320, 90);
        _headerLabel.backgroundColor=RGBACOLOR(0, 0, 0, 0.3).CGColor;
        
    }
    return _headerLabel;
}

//底部影阴
- (CALayer *)footerLabel
{
    if (!_footerLabel)
    {
        _footerLabel = [[CALayer alloc] init];
        _footerLabel.frame = CGRectMake(0, 330, 320, 250);
        _footerLabel.backgroundColor=RGBACOLOR(0, 0, 0, 0.3).CGColor;
    }
    return _footerLabel;
}
//头部影阴
- (CALayer *)rightLabel
{
    if (!_rightLabel)
    {
        _rightLabel = [[CALayer alloc] init];
        _rightLabel.frame = CGRectMake(300, 90, 20, 240);
        _rightLabel.backgroundColor=RGBACOLOR(0, 0, 0, 0.3).CGColor;
    }
    return _rightLabel;
}

//底部影阴
- (CALayer *)leftLabel
{
    if (!_leftLabel)
    {
        _leftLabel = [[CALayer alloc] init];
        _leftLabel.frame = CGRectMake(0, 90, 20, 240);
        _leftLabel.backgroundColor=RGBACOLOR(0, 0, 0, 0.3).CGColor;
    }
    return _leftLabel;
}

- (UIView *)blackCoverView
{
    if (!_blackCoverView) {
        _blackCoverView = [[UIView alloc] initWithFrame:self.view.bounds];
        _blackCoverView.backgroundColor = [UIColor blackColor];
        [_blackCoverView addSubview:self.activityView];
        UILabel *loadLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.activityView.bottom + 10, kScreenWidth, 30)];
        loadLabel.font = [UIFont systemFontOfSize:16.0];
        loadLabel.textColor = [UIColor whiteColor];
        loadLabel.backgroundColor = [UIColor clearColor];
        loadLabel.text = @"正在加载中...";
        loadLabel.textAlignment = NSTextAlignmentCenter;
        [_blackCoverView addSubview:loadLabel];
    }
    return _blackCoverView;
}

- (UIActivityIndicatorView *)activityView
{
    if (!_activityView)
    {
        _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityView.hidesWhenStopped = YES;
        _activityView.frame = CGRectMake(150, 230, 50, 50);
        _activityView.center = QRCGRectGetCenter(_cropRect);
        
        [_activityView startAnimating];
    }
    return _activityView;
}

@end
