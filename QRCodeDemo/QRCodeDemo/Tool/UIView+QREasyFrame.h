//
//  UIView+QREasyFrame.h
//  Pods
//
//  Created by xulihua on 15/11/3.
//
//

#import <UIKit/UIKit.h>



CGPoint QRCGRectGetCenter(CGRect rect);
CGRect  QRCGRectMoveToCenter(CGRect rect, CGPoint center);

@interface UIView (QREasyFrame)

@property (nonatomic, assign) CGPoint origin;
@property (nonatomic, assign) CGSize size;


@property (nonatomic, assign) CGPoint bottomLeft;
@property (nonatomic, assign) CGPoint bottomRight;
@property (nonatomic, assign) CGPoint topRight;

@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGFloat width;

@property (nonatomic, assign) CGFloat top;
@property (nonatomic, assign) CGFloat left;
@property (nonatomic, assign) CGFloat bottom;
@property (nonatomic, assign) CGFloat right;

@property (nonatomic, assign) CGFloat centerX;
@property (nonatomic, assign) CGFloat centerY;

- (void)moveBy:(CGPoint)delta;
- (void)scaleBy:(CGFloat)scaleFactor;
- (void)fitInSize:(CGSize)aSize;

@end
