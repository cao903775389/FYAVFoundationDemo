//
//  FYConstant.h
//  FYAVFoundationDemo
//
//  Created by admin on 2019/12/31.
//  Copyright © 2019 fengyangcao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FYAudioSetupResult) {
    FYAudioSetupResultSuccess = 0,
    FYAudioSetupResultNotAuthorized,
    FYAudioSetupResultFailed
};

typedef NS_ENUM(NSInteger, FYVideoSetupResult) {
    FYVideoSetupResultSuccess = 0,
    FYVideoSetupResultNotAuthorized
};

/** 音频文件封装格式，
*  FYAudioFileTypeLPCM 是单纯的裸PCM数据，没有音频属性数据；裸PCM数据文件不能用AudioFilePlayer和ExtAudioFileRef读写，只能用
*  NSInputStream和NSOutputStream等流式接口进行读写
*  FYAudioFileTypeMP3和FYAudioFileTypeM4A 用于存储压缩的音频数据
*  FYAudioFileTypeWAV和FYAudioFileTypeCAF 用于存储未压缩音频数据
*  IOS不支持MP3的编码？一直返回错误
*/
typedef NS_ENUM(NSInteger, FYAudioFileType) {
    FYAudioFileTypeUnknown = -1,
    FYAudioFileTypeLPCM = 0, //PCM裸数据
    FYAudioFileTypeMP3, //压缩封装文件数据
    FYAudioFileTypeM4A,
    FYAudioFileTypeWAV,
    FYAudioFileTypeCAF,
};

/** 音频采样数据在内存中的存储方式
*  AudioSaveTypePacket:
*  对应kAudioFormatFlagIsPacked，每个声道数据交叉存储在AudioBufferList的mBuffers
*  [0]中,如：左声道右声道左声道右声道....
*  FYAudioDataTypeNonInterleaved:
*  对应kAudioFormatFlagIsNonInterleaved，表示每个声道数据分开存储在mBuffers[i]中如：
*  mBuffers[0],左声道左声道左声道左声道
*  mBuffers[1],右声道右声道右声道右声道
*/
typedef NS_ENUM(NSInteger, FYAudioDataType) {
    FYAudioDataTypePacket,
    FYAudioDataTypeNonInterleaved
};

/** 音频采样数据的采样格式
 *  FYAudioFormatType16Int:
 *  对应kAudioFormatFlagIsSignedInteger，表示每一个采样数据是由16位整数来表示
 *  FYAudioFormatType32Int:
 *  对应kAudioFormatFlagIsSignedInteger，表示每一个采样数据是由32位整数来表示，播放音频时不支持
 *  FYAudioFormatType32Float:
 *  对应kAudioFormatFlagIsFloat，表示每一个采样数据由32位浮点数来表示
 */
typedef NS_ENUM(NSInteger, FYAudioFormatType) {
    FYAudioFormatType16Int,
    FYAudioFormatType32Int,
    FYAudioFormatType32Float,
};

/**
 声道数
 */
typedef NS_ENUM(NSInteger, FYAudioChannel) {
    FYAudioChannelSingle = 1,
    FYAudioChannelDouble = 2,
};

/// 音频采样率 (默认44.1KHz)
typedef NS_ENUM (NSUInteger, FYAudioSampleRate){
    /// 16KHz 采样率
    FYAudioSampleRate_16000Hz = 16000,
    /// 44.1KHz 采样率
    FYAudioSampleRate_44100Hz = 44100,
    /// 48KHz 采样率
    FYAudioSampleRate_48000Hz = 48000,
    /// 默认音频采样率，默认为 44.1KHz
    FYAudioSampleRate_Default = FYAudioSampleRate_44100Hz
};

// 三种不同音频播放延迟
static const NSTimeInterval FYAudioSessionDelay_Background = 0.0929;
static const NSTimeInterval FYSAudioSessionDelay_Default = 0.0232;
static const NSTimeInterval FYSAudioSessionDelay_Low = 0.0058;

static inline AudioFileTypeID convertFromFileType(FYAudioFileType fileType) {
    if (fileType == FYAudioFileTypeLPCM) {
        NSLog(@"无法处理 PCM数据");
        return 0;
    }
    AudioFileTypeID resultType = kAudioFileM4AType;
    if (fileType == FYAudioFileTypeM4A) {
        resultType = kAudioFileM4AType;
    } else if (fileType == FYAudioFileTypeMP3) {
        resultType = kAudioFileMP3Type;
    } else if (fileType == FYAudioFileTypeCAF) {
        resultType = kAudioFileCAFType;
    } else if (fileType == FYAudioFileTypeWAV) {
        resultType = kAudioFileWAVEType;
    } else {
        resultType = kAudioFileWAVEType;
    }
    return resultType;
};

NS_ASSUME_NONNULL_END
