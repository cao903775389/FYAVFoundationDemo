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
    return [[FYAudioConfiguration alloc] initWithSampleRate:FYAudioSampleRate_Default channels:FYAudioChannelDouble dataType:FYAudioDataTypePacket fileType:FYAudioFileTypeLPCM formatType:FYAudioFormatType32Float bufferLength:FYSAudioSessionDelay_Default];
}

- (instancetype)initWithSampleRate:(FYAudioSampleRate)sampleRate
    channels:(FYAudioChannel)channels
    dataType:(FYAudioDataType)dataType
    fileType:(FYAudioFileType)fileType
  formatType:(FYAudioFormatType)formatType
                      bufferLength:(NSTimeInterval)bufferLength {
    
    if (self = [super init]) {
        self.audioDataType = dataType;
        self.audioFileType = fileType;
        self.audioFormatType = formatType;
        self.audioSampleRate = sampleRate;
        self.bufferLength = bufferLength;
        self.channels = channels;
    }
    return self;
}

@end
