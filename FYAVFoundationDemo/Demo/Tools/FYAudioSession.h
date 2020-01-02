//
//  FYAudioSession.h
//  FYAVFoundationDemo
//
//  Created by admin on 2020/1/2.
//  Copyright © 2020 fengyangcao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FYConstant.h"
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FYAudioSession : NSObject

//采样率
@property (nonatomic, assign, readonly) NSInteger sampleRate;
//声道数
@property (nonatomic, assign, readonly) NSInteger channels;
//音频的数据格式
@property (nonatomic, assign, readonly) FYAudioFormatType formatType;
//音频内存中的数据格式
@property (nonatomic, assign, readonly) FYAudioDataType dataType;
//音频会话
@property (nonatomic, strong, readonly) AVAudioSession *audioSession;
//音频数据格式+内存中的格式
@property (nonatomic, assign, readonly) AudioFormatFlags formatFlags;
//每个声道中的字节数
@property (nonatomic, assign, readonly) NSInteger bytesPerChannel;

+ (FYAudioSession *)defaultAudioSession;

- (instancetype)initWithSampleRate:(NSInteger)sampleRate
                          category:(AVAudioSessionCategory)category
                          channels:(NSInteger)channels
                    bufferDuration:(NSTimeInterval)duration
                        formatType:(FYAudioFormatType)formatType
                          dataType:(FYAudioDataType)dataType;

@end

NS_ASSUME_NONNULL_END
