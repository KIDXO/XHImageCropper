//
//  XHImageCropperController.m
//  XHImageCropperController
//
//  Created by NULL on 16/4/13.
//  Copyright © 2016年 NULL. All rights reserved.
//

#import "XHImageCropperController.h"

#define Animate_Duration    0.3f

@interface XHImageCropperController ()

@property (nonatomic, retain) UIImage       *imgOriginal;
@property (nonatomic, retain) UIImage       *imgEdited;

@property (nonatomic, retain) UIImageView   *imageView;

@property (nonatomic, retain) UIView        *viewOverlay;
@property (nonatomic, retain) UIView        *viewRatio;

@property (nonatomic, assign) CGRect        frameLimit;
@property (nonatomic, assign) CGRect        frameLarge;
@property (nonatomic, assign) CGRect        frameLatest;

@property (nonatomic, assign) CGFloat       ratioLimit;

@end

@implementation XHImageCropperController

- (void)dealloc
{
    self.imgOriginal = nil;
    self.imgEdited = nil;
    self.imageView = nil;
    self.viewOverlay = nil;
    self.viewRatio = nil;
}

- (id)initWithImage:(UIImage *)image cropFrame:(CGRect)cropFrame limitRatio:(NSInteger)limitRatio
{
    self = [super init];
    if (self) {
        self.cropFrame = cropFrame;
        self.ratioLimit = limitRatio;
        self.imgOriginal = [self fixOrientation:image];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initView];
    [self initButton];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return NO;
}

- (void)initView
{
    self.view.clipsToBounds = YES;
    self.view.backgroundColor = [UIColor blackColor];
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    [self.imageView setImage:self.imgOriginal];
    [self.imageView setUserInteractionEnabled:YES];
    [self.imageView setMultipleTouchEnabled:YES];
    
    CGFloat oriWidth;
    CGFloat oriHeight;
    if (self.imgOriginal.size.width < self.imgOriginal.size.height) {
        oriWidth = self.cropFrame.size.width;
        oriHeight = self.imgOriginal.size.height * (oriWidth / self.imgOriginal.size.width);
    }
    else {
        oriHeight = self.cropFrame.size.height;
        oriWidth = self.imgOriginal.size.width * (oriHeight / self.imgOriginal.size.height);
    }
    CGFloat oriX = self.cropFrame.origin.x + (self.cropFrame.size.width - oriWidth) / 2;
    CGFloat oriY = self.cropFrame.origin.y + (self.cropFrame.size.height - oriHeight) / 2;
    self.frameLimit = CGRectMake(oriX, oriY, oriWidth, oriHeight);
    self.frameLatest = self.frameLimit;
    self.imageView.frame = self.frameLimit;
    
    self.frameLarge = CGRectMake(0, 0, self.ratioLimit * self.frameLimit.size.width, self.ratioLimit * self.frameLimit.size.height);
    
    [self addGestureRecognizers];
    [self.view addSubview:self.imageView];
    
    self.viewOverlay = [[UIView alloc] initWithFrame:self.view.bounds];
    self.viewOverlay.alpha = 0.5f;
    self.viewOverlay.backgroundColor = [UIColor blackColor];
    self.viewOverlay.userInteractionEnabled = NO;
    self.viewOverlay.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.viewOverlay];
    
    self.viewRatio = [[UIView alloc] initWithFrame:self.cropFrame];
    self.viewRatio.layer.borderColor = SBColor_Main.CGColor;
    self.viewRatio.layer.borderWidth = 0.5f;
    self.viewRatio.autoresizingMask = UIViewAutoresizingNone;
    [self.view addSubview:self.viewRatio];
    
    [self overlayClipping];
}

- (void)initButton
{
    UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 50.0f, 100, 50)];
    cancelBtn.backgroundColor = [UIColor clearColor];
    cancelBtn.titleLabel.textColor = [UIColor whiteColor];
    [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    [cancelBtn.titleLabel setFont:[UIFont systemFontOfSize:17.0f]];
    [cancelBtn.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [cancelBtn.titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [cancelBtn.titleLabel setNumberOfLines:0];
    [cancelBtn setTitleEdgeInsets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
    [cancelBtn addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cancelBtn];
    
    UIButton *confirmBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 100.0f, self.view.frame.size.height - 50.0f, 100, 50)];
    confirmBtn.backgroundColor = [UIColor clearColor];
    confirmBtn.titleLabel.textColor = [UIColor whiteColor];
    [confirmBtn setTitle:@"完成" forState:UIControlStateNormal];
    [confirmBtn.titleLabel setFont:[UIFont systemFontOfSize:17.0f]];
    [confirmBtn.titleLabel setTextAlignment:NSTextAlignmentCenter];
    confirmBtn.titleLabel.textColor = [UIColor whiteColor];
    [confirmBtn.titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [confirmBtn.titleLabel setNumberOfLines:0];
    [confirmBtn setTitleEdgeInsets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
    [confirmBtn addTarget:self action:@selector(confirm:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:confirmBtn];
}

- (void)cancel:(id)sender
{
    if (self.delegate && [self.delegate conformsToProtocol:@protocol(XHImageCropperDelegate)]) {
        [self.delegate imageCropperControllerDidCancel:self];
    }
}

- (void)confirm:(id)sender
{
    if (self.delegate && [self.delegate conformsToProtocol:@protocol(XHImageCropperDelegate)]) {
        [self.delegate imageCropperController:self didFinished:[self getEditedImage]];
    }
}

- (void)overlayClipping
{
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    CGMutablePathRef path = CGPathCreateMutable();

    CGPathAddRect(path, nil, CGRectMake(0, 0,
                                        self.viewRatio.frame.origin.x,
                                        self.viewOverlay.frame.size.height));

    CGPathAddRect(path, nil, CGRectMake(
                                        self.viewRatio.frame.origin.x + self.viewRatio.frame.size.width,
                                        0,
                                        self.viewOverlay.frame.size.width - self.viewRatio.frame.origin.x - self.viewRatio.frame.size.width,
                                        self.viewOverlay.frame.size.height));

    CGPathAddRect(path, nil, CGRectMake(0, 0,
                                        self.viewOverlay.frame.size.width,
                                        self.viewRatio.frame.origin.y));

    CGPathAddRect(path, nil, CGRectMake(0,
                                        self.viewRatio.frame.origin.y + self.viewRatio.frame.size.height,
                                        self.viewOverlay.frame.size.width,
                                        self.viewOverlay.frame.size.height - self.viewRatio.frame.origin.y + self.viewRatio.frame.size.height));
    maskLayer.path = path;
    self.viewOverlay.layer.mask = maskLayer;
    CGPathRelease(path);
}

- (void)addGestureRecognizers
{
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchView:)];
    [self.view addGestureRecognizer:pinchGestureRecognizer];
    
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panView:)];
    [self.view addGestureRecognizer:panGestureRecognizer];
}

- (void)pinchView:(UIPinchGestureRecognizer *)pinchGestureRecognizer
{
    UIView *view = self.imageView;
    if (pinchGestureRecognizer.state == UIGestureRecognizerStateBegan || pinchGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        view.transform = CGAffineTransformScale(view.transform, pinchGestureRecognizer.scale, pinchGestureRecognizer.scale);
        pinchGestureRecognizer.scale = 1;
    }
    else if (pinchGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGRect newFrame = self.imageView.frame;
        newFrame = [self handleScaleOverflow:newFrame];
        newFrame = [self handleBorderOverflow:newFrame];
        [UIView animateWithDuration:Animate_Duration animations:^{
            self.imageView.frame = newFrame;
            self.frameLatest = newFrame;
        }];
    }
}

- (void)panView:(UIPanGestureRecognizer *)panGestureRecognizer
{
    UIView *view = self.imageView;
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan || panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        CGFloat absCenterX = self.cropFrame.origin.x + self.cropFrame.size.width / 2;
        CGFloat absCenterY = self.cropFrame.origin.y + self.cropFrame.size.height / 2;
        CGFloat scaleRatio = self.imageView.frame.size.width / self.cropFrame.size.width;
        CGFloat acceleratorX = 1 - ABS(absCenterX - view.center.x) / (scaleRatio * absCenterX);
        CGFloat acceleratorY = 1 - ABS(absCenterY - view.center.y) / (scaleRatio * absCenterY);
        CGPoint translation = [panGestureRecognizer translationInView:view.superview];
        [view setCenter:(CGPoint){view.center.x + translation.x * acceleratorX, view.center.y + translation.y * acceleratorY}];
        [panGestureRecognizer setTranslation:CGPointZero inView:view.superview];
    }
    else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGRect newFrame = self.imageView.frame;
        newFrame = [self handleBorderOverflow:newFrame];
        [UIView animateWithDuration:Animate_Duration animations:^{
            self.imageView.frame = newFrame;
            self.frameLatest = newFrame;
        }];
    }
}

- (CGRect)handleScaleOverflow:(CGRect)newFrame
{
    CGPoint oriCenter = CGPointMake(newFrame.origin.x + newFrame.size.width/2, newFrame.origin.y + newFrame.size.height/2);
    if (newFrame.size.width < self.frameLimit.size.width) {
        newFrame = self.frameLimit;
    }
    if (newFrame.size.width > self.frameLarge.size.width) {
        newFrame = self.frameLarge;
    }
    newFrame.origin.x = oriCenter.x - newFrame.size.width/2;
    newFrame.origin.y = oriCenter.y - newFrame.size.height/2;
    return newFrame;
}

- (CGRect)handleBorderOverflow:(CGRect)newFrame
{
    if (newFrame.origin.x > self.cropFrame.origin.x) newFrame.origin.x = self.cropFrame.origin.x;
    if (CGRectGetMaxX(newFrame) < self.cropFrame.size.width) newFrame.origin.x = self.cropFrame.size.width - newFrame.size.width;
    if (newFrame.origin.y > self.cropFrame.origin.y) newFrame.origin.y = self.cropFrame.origin.y;
    if (CGRectGetMaxY(newFrame) < self.cropFrame.origin.y + self.cropFrame.size.height) {
        newFrame.origin.y = self.cropFrame.origin.y + self.cropFrame.size.height - newFrame.size.height;
    }
    if (self.imageView.frame.size.width > self.imageView.frame.size.height && newFrame.size.height <= self.cropFrame.size.height) {
        newFrame.origin.y = self.cropFrame.origin.y + (self.cropFrame.size.height - newFrame.size.height) / 2;
    }
    return newFrame;
}

- (UIImage *)getEditedImage
{
    CGRect squareFrame = self.cropFrame;
    CGFloat scaleRatio = self.frameLatest.size.width / self.imgOriginal.size.width;
    CGFloat x = (squareFrame.origin.x - self.frameLatest.origin.x) / scaleRatio;
    CGFloat y = (squareFrame.origin.y - self.frameLatest.origin.y) / scaleRatio;
    CGFloat w = squareFrame.size.width / scaleRatio;
    CGFloat h = squareFrame.size.height / scaleRatio;
    if (self.frameLatest.size.width < self.cropFrame.size.width) {
        CGFloat newW = self.imgOriginal.size.width;
        CGFloat newH = newW * (self.cropFrame.size.height / self.cropFrame.size.width);
        x = 0; y = y + (h - newH) / 2;
        w = newH; h = newH;
    }
    if (self.frameLatest.size.height < self.cropFrame.size.height) {
        CGFloat newH = self.imgOriginal.size.height;
        CGFloat newW = newH * (self.cropFrame.size.width / self.cropFrame.size.height);
        x = x + (w - newW) / 2; y = 0;
        w = newH; h = newH;
    }
    CGRect myImageRect = CGRectMake(x, y, w, h);
    CGImageRef imageRef = self.imgOriginal.CGImage;
    CGImageRef subImageRef = CGImageCreateWithImageInRect(imageRef, myImageRect);
    CGSize size;
    size.width = myImageRect.size.width;
    size.height = myImageRect.size.height;
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, myImageRect, subImageRef);
    UIImage* smallImage = [UIImage imageWithCGImage:subImageRef];
    CGImageRelease(subImageRef);
    UIGraphicsEndImageContext();
    return smallImage;
}

- (UIImage *)fixOrientation:(UIImage *)img
{
    if (img.imageOrientation == UIImageOrientationUp) return img;
    CGAffineTransform transform = CGAffineTransformIdentity;
    switch (img.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, img.size.width, img.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, img.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, img.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (img.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, img.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, img.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    CGContextRef ctx = CGBitmapContextCreate(NULL, img.size.width, img.size.height,
                                             CGImageGetBitsPerComponent(img.CGImage), 0,
                                             CGImageGetColorSpace(img.CGImage),
                                             CGImageGetBitmapInfo(img.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (img.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0,0,img.size.height,img.size.width), img.CGImage);
            break;
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,img.size.width,img.size.height), img.CGImage);
            break;
    }
    
    CGImageRef imageCG = CGBitmapContextCreateImage(ctx);
    UIImage *image = [UIImage imageWithCGImage:imageCG];
    CGContextRelease(ctx);
    CGImageRelease(imageCG);
    return image;
}

@end
