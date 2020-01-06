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
#import "FYAudioConfiguration.h"

NS_ASSUME_NONNULL_BEGIN
@class FYAudioConfiguration;

@interface FYAudioSession : NSObject

//音频会话
@property (nonatomic, strong, readonly) AVAudioSession *audioSession;
//音频数据格式+内存中的格式
@property (nonatomic, assign, readonly) AudioFormatFlags formatFlags;
//每个声道中的字节数
@property (nonatomic, assign, readonly) NSInteger bytesPerChannel;
//视频配置
@property (nonatomic, strong, readonly) FYAudioConfiguration *configuration;

- (instancetype)initWithConfiguration:(FYAudioConfiguration *)configuration
                             category:(AVAudioSessionCategory)category
                              options:(AVAudioSessionCategoryOptions)options;

+ (FYAudioSession *)defaultAudioSession;

@end

NS_ASSUME_NONNULL_END
