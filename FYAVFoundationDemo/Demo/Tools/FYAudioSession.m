//
//  FYAudioSession.m
//  FYAVFoundationDemo
//
//  Created by admin on 2020/1/2.
//  Copyright © 2020 fengyangcao. All rights reserved.
//

#import "FYAudioSession.h"
#import "FYConstant.h"

@interface FYAudioSession ()

@property (nonatomic, assign) NSInteger sampleRate;
@property (nonatomic, assign) NSInteger channels;
@property (nonatomic, assign) FYAudioFormatType formatType;
@property (nonatomic, assign) FYAudioDataType dataType;
@property (nonatomic, strong) AVAudioSession *audioSession;

@end

@implementation FYAudioSession

+ (FYAudioSession *)defaultAudioSession {
    return [[FYAudioSession alloc] initWithSampleRate:44100
                                 category:AVAudioSessionCategoryPlayback
                                 channels:FYAudioChannelDouble
                           bufferDuration:FYSAudioSessionDelay_Default
                               formatType:FYAudioFormatType32Float
                                 dataType:FYAudioDataTypePacket];
}

- (instancetype)initWithSampleRate:(NSInteger)sampleRate
                          category:(AVAudioSessionCategory)category
                          channels:(NSInteger)channels
                    bufferDuration:(NSTimeInterval)duration
                        formatType:(FYAudioFormatType)formatType
                          dataType:(FYAudioDataType)dataType {
    if (self = [super init]) {
        _sampleRate = sampleRate;
        _channels = channels;
        _formatType = formatType;
        _dataType = dataType;
        _audioSession = [AVAudioSession sharedInstance];
        [_audioSession setCategory:category error:nil];
        [_audioSession setPreferredSampleRate:sampleRate error:nil];
        // 设置I/O的Buffer，数值越小说明缓存的数据越小，延迟也就越低；
        [_audioSession setPreferredIOBufferDuration:duration error:nil];
        [_audioSession setActive:YES error:nil];
    }
    return self;
}

- (AudioFormatFlags)formatFlags {
    AudioFormatFlags flags = kAudioFormatFlagIsSignedInteger;
    if (self.formatType == FYAudioFormatType32Float) {
        flags = kAudioFormatFlagIsFloat;
    }
    if (self.dataType == FYAudioDataTypePlanner) {
        flags |= kAudioFormatFlagIsNonInterleaved;
    }else{
        flags |= kAudioFormatFlagIsPacked;
    }
    return flags;
}

- (NSInteger)bytesPerChannel {
    if (self.formatType == FYAudioFormatType16Int) {
        return 2;
    }
    return 4;
}

@end
