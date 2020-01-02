//
//  FYAVCapturePreview.m
//  FYAVFoundationDemo
//
//  Created by admin on 2019/12/10.
//  Copyright © 2019 fengyangcao. All rights reserved.
//

@import AVFoundation;

#import "FYAVCapturePreview.h"

@implementation FYAVCapturePreview

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureVideoPreviewLayer*) videoPreviewLayer
{
    return (AVCaptureVideoPreviewLayer *)self.layer;
}

- (AVCaptureSession*) session
{
    return self.videoPreviewLayer.session;
}

- (void)setSession:(AVCaptureSession*) session
{
    self.videoPreviewLayer.session = session;
}

@end
