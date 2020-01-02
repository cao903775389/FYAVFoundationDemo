//
//  AVCaptureDevice+FYAVCaptureTools.h
//  FYAVFoundationDemo
//
//  Created by admin on 2019/12/6.
//  Copyright © 2019 fengyangcao. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVCaptureDevice (FYAVCaptureTools)

//call back on main thread
+ (void)requestAccess:(AVMediaType)mediaType
    completionHandler:(void (^)(BOOL))handler;

//获取默认相机
+ (AVCaptureDevice * _Nullable)getDefaultCamera;

//获取全部设备
+ (NSArray <AVCaptureDevice *>* _Nullable)getAllCaptureDevices;

@end

NS_ASSUME_NONNULL_END
