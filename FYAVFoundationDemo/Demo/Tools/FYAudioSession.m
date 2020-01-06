//
//  FYAudioSession.m
//  FYAVFoundationDemo
//
//  Created by admin on 2020/1/2.
//  Copyright © 2020 fengyangcao. All rights reserved.
//

#import "FYAudioSession.h"

@interface FYAudioSession ()

@property (nonatomic, strong) AVAudioSession *audioSession;
@property (nonatomic, strong) FYAudioConfiguration *configuration;

@end

@implementation FYAudioSession

+ (FYAudioSession *)defaultAudioSession {
    FYAudioConfiguration *config = [FYAudioConfiguration defaultConfiguration];
    return [[self alloc] initWithConfiguration:config category:AVAudioSessionCategoryPlayback options:AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionDefaultToSpeaker];
}

- (instancetype)initWithConfiguration:(FYAudioConfiguration *)configuration
                             category:(nonnull AVAudioSessionCategory)category
                              options:(AVAudioSessionCategoryOptions)options {
    if (self = [super init]) {
        _configuration = configuration;
        _audioSession = [AVAudioSession sharedInstance];

        _audioSession = [AVAudioSession sharedInstance];
        [_audioSession setCategory:category withOptions:options error:nil];
        [_audioSession setPreferredSampleRate:_configuration.audioSampleRate error:nil];
        // 设置I/O的Buffer，数值越小说明缓存的数据越小，延迟也就越低；
        [_audioSession setPreferredIOBufferDuration:_configuration.bufferLength error:nil];
        [_audioSession setActive:YES error:nil];
    }
    
    return self;
}

- (AudioFormatFlags)formatFlags {
    AudioFormatFlags flags = kAudioFormatFlagIsSignedInteger;
    if (self.configuration.audioFormatType == FYAudioFormatType32Float) {
        flags = kAudioFormatFlagIsFloat;
    }
    if (self.configuration.audioDataType == FYAudioDataTypeNonInterleaved) {
        flags |= kAudioFormatFlagIsNonInterleaved;
    }else{
        flags |= kAudioFormatFlagIsPacked;
    }
    return flags;
}

- (NSInteger)bytesPerChannel {
    if (self.configuration.audioFormatType == FYAudioFormatType16Int) {
        return 2;
    }
    return 4;
}

@end
