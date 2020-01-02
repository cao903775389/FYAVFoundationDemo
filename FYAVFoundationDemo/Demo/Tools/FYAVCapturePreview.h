//
//  FYAVCapturePreview.h
//  FYAVFoundationDemo
//
//  Created by admin on 2019/12/10.
//  Copyright © 2019 fengyangcao. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class AVCaptureSession;
@class AVCaptureVideoPreviewLayer;

@interface FYAVCapturePreview : UIView

@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@property (nonatomic) AVCaptureSession *session;

@end

NS_ASSUME_NONNULL_END
