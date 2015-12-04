//
//  QRCodeCommon.h
//  QRCodeDemo
//
//  Created by xulihua on 15/12/4.
//  Copyright © 2015年 huage. All rights reserved.
//

#ifndef QRCodeCommon_h
#define QRCodeCommon_h

//iOS8及以上
#define iOS8_OR_LATER SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]

#define kScreenWidth  [[UIScreen mainScreen] bounds].size.width        //屏幕宽
#define kScreenHeight [[UIScreen mainScreen] bounds].size.height       //屏幕高

#define kQRReaderScanWidth      (kScreenWidth - 100)
#define kQRReaderScanHeight     (kScreenWidth - 100)
#define kQRReaderScanExpandWidth     (50)
#define kQRReaderScanExpandHeight    (50)
#define kQRReaderScanLabelSpace 10

#define IsStrEmpty(_ref)    (((_ref) == nil) || ([(_ref) isEqual:[NSNull null]]) ||([(_ref)isEqualToString:@""]))


#endif
