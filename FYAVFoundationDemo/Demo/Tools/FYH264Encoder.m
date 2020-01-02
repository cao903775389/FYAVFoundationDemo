//
//  FYH264Encoder.m
//  FYAVFoundationDemo
//
//  Created by admin on 2019/12/9.
//  Copyright © 2019 fengyangcao. All rights reserved.
//

#import "FYH264Encoder.h"
#import <VideoToolbox/VideoToolbox.h>

@interface FYH264Encoder () {
    dispatch_queue_t videoEncodeQueue; //视频编码queue
    int frameID;
    VTCompressionSessionRef videoEncodeSession; // 编码器
}

@end

@implementation FYH264Encoder

- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (void)prepare {
    dispatch_sync(videoEncodeQueue, ^{
        frameID = 0;
        int width = 480;
        int height = 640;
        OSStatus status = VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, NULL, (__bridge void * _Nullable)(self), &videoEncodeSession);
        
        if (status != noErr) {
            NSLog(@"H264: Unable to create a H264 session status: %d", (int)status);
            return;
        }
        
        //设置编码参数
        //设置实时编码输出（避免延迟）
        status = VTSessionSetProperty(videoEncodeSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
        if (status != noErr) {
            NSLog(@"H264: Unable to create a H264 session status: %d", (int)status);
            return;
        }
        //设置编码等级
        status = VTSessionSetProperty(videoEncodeSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);
        if (status != noErr) {
            NSLog(@"H264: Unable to create a H264 session status: %d", (int)status);
            return;
        }
        
        //设置GOP
        int fps = 10;
        CFNumberRef fpsRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &fps);
        status = VTSessionSetProperty(videoEncodeSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, fpsRef);
        if (status != noErr) {
            NSLog(@"H264: Unable to create a H264 session status: %d", (int)status);
            return;
        }
        
        //设置期望帧率、均值，单位是bit
        //*3 YUV分量表示一个像素点 一个分量4byte
        int bitRate = width * height * 3 * 4 * 8;
        CFNumberRef biteRateRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRate);
        status = VTSessionSetProperty(videoEncodeSession, kVTCompressionPropertyKey_AverageBitRate, biteRateRef);
        if (status != noErr) {
            NSLog(@"H264: Unable to create a H264 session status: %d", (int)status);
            return;
        }
        //设置码率上线 单位byte
        int bitRateLimit = width * height * 3 * 4;
        CFNumberRef biteRateLimitRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRateLimit);
        status = VTSessionSetProperty(videoEncodeSession, kVTCompressionPropertyKey_DataRateLimits, biteRateLimitRef);
        if (status != noErr) {
            NSLog(@"H264: Unable to create a H264 session status: %d", (int)status);
            return;
        }
        //配置完成
        status = VTCompressionSessionPrepareToEncodeFrames(videoEncodeSession);
        if (status != noErr) {
            NSLog(@"H264: Unable to create a H264 session status: %d", (int)status);
            return;
        }
    });
}

@end
