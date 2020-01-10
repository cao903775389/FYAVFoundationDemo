//
//  FYAudioConfiguration.h
//  FYAVFoundationDemo
//
//  Created by admin on 2020/1/5.
//  Copyright © 2020 fengyangcao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "FYConstant.h"

NS_ASSUME_NONNULL_BEGIN

@interface FYAudioConfiguration : NSObject

//声道数
@property (nonatomic, assign) FYAudioChannel channels;
//采样率
@property (nonatomic, assign) FYAudioSampleRate audioSampleRate;
//音频buffer格式
@property (nonatomic, assign) FYAudioDataType audioDataType;
//音频封装格式
@property (nonatomic, assign) FYAudioFileType audioFileType;
//音频数据格式
@property (nonatomic, assign) FYAudioFormatType audioFormatType;
//buffer时长
@property (nonatomic, assign) NSTimeInterval bufferLength;

+ (instancetype)defaultConfiguration;

- (instancetype)initWithSampleRate:(FYAudioSampleRate)sampleRate
                          channels:(FYAudioChannel)channels
                          dataType:(FYAudioDataType)dataType
                          fileType:(FYAudioFileType)fileType
                        formatType:(FYAudioFormatType)formatType
                      bufferLength:(NSTimeInterval)bufferLength;

@end

NS_ASSUME_NONNULL_END
