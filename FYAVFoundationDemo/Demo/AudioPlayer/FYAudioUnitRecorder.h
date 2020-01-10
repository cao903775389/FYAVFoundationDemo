//
//  FYAudioUnitRecorder.h
//  FYAVFoundationDemo
//  音频录制
//  Created by admin on 2020/1/5.
//  Copyright © 2020 fengyangcao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FYFileDataWritter.h"

NS_ASSUME_NONNULL_BEGIN
@class FYAudioConfiguration;

typedef struct FYAudioUnitRecordOption {
    bool enablePlayWhenRecord;
    bool enableMixWhenRecord;
    bool enableSaveLocal;
} FYAudioUnitRecordOption;

@interface FYAudioUnitRecorder : NSObject

//是否开启耳返
@property (nonatomic, assign, readonly) BOOL enablePlayWhenRecord;
@property (nonatomic, assign, readonly) BOOL enableMixWhenRecord;
@property (nonatomic, assign, readonly) BOOL enableSaveLocal;

@property (nonatomic, assign, readonly) BOOL isRecording;
@property (nonatomic, strong, nullable, readonly) FYFileDataWritter *audioWritter;

- (instancetype)initWithConfiguration:(FYAudioConfiguration *)configuration
                         recordOption:(FYAudioUnitRecordOption)recordOption;

- (instancetype)initWithConfiguration:(FYAudioConfiguration *)configuration
                     mixMusicFilePath:(NSString * _Nullable)mixMusicFilePath
                         recordOption:(FYAudioUnitRecordOption)recordOption;

- (void)startRecord;

- (void)stopRecord;

+ (NSString *)saveFilePath;

@end

NS_ASSUME_NONNULL_END
