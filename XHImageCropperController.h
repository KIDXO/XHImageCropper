//
//  XHImageCropperController.h
//  XHImageCropperController
//
//  Created by NULL on 16/4/13.
//  Copyright © 2016年 NULL. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XHImageCropperController;

@protocol XHImageCropperDelegate <NSObject>

- (void)imageCropperController:(XHImageCropperController *)cropper didFinished:(UIImage *)editedImage;
- (void)imageCropperControllerDidCancel:(XHImageCropperController *)cropper;

@end

@interface XHImageCropperController : UIViewController

@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, assign) id<XHImageCropperDelegate> delegate;
@property (nonatomic, assign) CGRect cropFrame;

- (id)initWithImage:(UIImage *)image cropFrame:(CGRect)cropFrame limitRatio:(NSInteger)limitRatio;

@end
