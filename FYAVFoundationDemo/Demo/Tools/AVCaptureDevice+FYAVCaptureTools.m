//
//  AVCaptureDevice+FYAVCaptureTools.m
//  FYAVFoundationDemo
//
//  Created by admin on 2019/12/6.
//  Copyright © 2019 fengyangcao. All rights reserved.
//

#import "AVCaptureDevice+FYAVCaptureTools.h"
#import <UIKit/UIKit.h>

@implementation AVCaptureDevice (FYAVCaptureTools)

+ (void)requestAccess:(AVMediaType)mediaType
    completionHandler:(void (^)(BOOL))handler {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    switch (status) {
        case AVAuthorizationStatusNotDetermined: {
            NSLog(@"用户尚未授予或拒绝该权限:AVAuthorizationStatusNotDetermined");
            [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
                if (handler) {
                    handler(granted);
                }
            }];
        }
            break;
        case AVAuthorizationStatusDenied: {
            if (handler) {
                handler(NO);
            }
            
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"没有权限" message:@"该功能需要授权使用你的相机" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"拒绝" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"授权" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSURL *url= [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if([[UIApplication sharedApplication] canOpenURL:url] ) {
                    if (@available(iOS 10.0, *)){
                        [[UIApplication sharedApplication]openURL:url options:@{} completionHandler:^(BOOL success) {
                        }];
                    }else{
                        [[UIApplication sharedApplication] openURL:url];
                    }
                }
            }];
            [alertController addAction:cancelAction];
            [alertController addAction:okAction];
            [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
            NSLog(@"用户已经明确拒绝了应用访问捕获设备:AVAuthorizationStatusDenied");
        }
            break;
        case AVAuthorizationStatusAuthorized:
            if (handler) {
                handler(YES);
            }
            NSLog(@"用户授予应用访问捕获设备的权限:AVAuthorizationStatusAuthorized");
            break;
        case AVAuthorizationStatusRestricted:
            if (handler) {
                handler(NO);
            }
            NSLog(@"不允许用户访问媒体捕获设备:AVAuthorizationStatusRestricted");
            break;
        default:
            break;
    }
}

+ (AVCaptureDevice * _Nullable)getDefaultCamera {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //使用该方法请求摄像机AVMediaTypeVideo时，返回的总是AVCaptureDeviceTypeBuiltInWideAngleCamera设备类型。
    //要使用其他设备类型，使用+ defaultDeviceWithDeviceType:mediaType:position:方法。
    return device;
}

+ (NSArray<AVCaptureDevice *> * _Nullable)getAllCaptureDevices {
    //[AVCaptureDevice devices]; deprecated after iOS 10
    
    if (@available(iOS 10.2, *)) {
        //广角镜头、双镜头
        AVCaptureDeviceDiscoverySession *session = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInDuoCamera, AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
        
        //当前可用的devices
        NSArray <AVCaptureDevice *> *devices = session.devices;
        __block AVCaptureDevice *newVideoDevice = nil;

        //遍历所有可用的AVCaptureDevice，获取 后置双镜头
        [devices enumerateObjectsUsingBlock:^(AVCaptureDevice * _Nonnull device, NSUInteger idx, BOOL * _Nonnull stop) {
            if ( device.position == AVCaptureDevicePositionBack && [device.deviceType isEqualToString:AVCaptureDeviceTypeBuiltInDuoCamera] ) {
                newVideoDevice = device;
                * stop = YES;
            }
        }];
        
        if (!newVideoDevice){
            //如果后置双镜头获取失败，则获取广角镜头
            [devices enumerateObjectsUsingBlock:^(AVCaptureDevice * _Nonnull device, NSUInteger idx, BOOL * _Nonnull stop) {
                if ( device.position == AVCaptureDevicePositionBack) {
                    newVideoDevice = device;
                    * stop = YES;
                }
            }];
        }
        
        return session.devices;
    }
    return nil;
}

@end
