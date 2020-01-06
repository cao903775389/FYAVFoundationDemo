//
//  FYAudioUnitRecorder.h
//  FYAVFoundationDemo
//  音频录制
//  Created by admin on 2020/1/5.
//  Copyright © 2020 fengyangcao. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class FYAudioConfiguration;

@interface FYAudioUnitRecorder : NSObject

- (instancetype)initWithConfiguration:(FYAudioConfiguration *)configuration;

- (void)startRecord;

- (void)stopRecord;

@end

NS_ASSUME_NONNULL_END
