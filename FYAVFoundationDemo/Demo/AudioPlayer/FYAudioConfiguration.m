//
//  FYAudioConfiguration.m
//  FYAVFoundationDemo
//
//  Created by admin on 2020/1/5.
//  Copyright © 2020 fengyangcao. All rights reserved.
//

#import "FYAudioConfiguration.h"

@implementation FYAudioConfiguration

+ (instancetype)defaultConfiguration {
    FYAudioConfiguration *configuration = [FYAudioConfiguration new];
    configuration.audioDataType = FYAudioDataTypePacket;
    configuration.audioFileType = FYAudioFileTypeLPCM;
    configuration.audioFormatType = FYAudioFormatType32Float;
    configuration.audioSampleRate = FYAudioSampleRate_Default;
    configuration.bufferLength = FYSAudioSessionDelay_Default;
    configuration.channels = FYAudioChannelDouble;
    return configuration;
}

@end
