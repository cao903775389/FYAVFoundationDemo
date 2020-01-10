//
//  FYAudioUnitPlay.h
//  FYAVFoundationDemo
//  播放本地PCM裸数据
//  Created by admin on 2019/12/31.
//  Copyright © 2019 fengyangcao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FYConstant.h"
#import "FYAudioSession.h"

NS_ASSUME_NONNULL_BEGIN

@interface FYAudioUnitPlay : NSObject

@property (nonatomic, assign, readonly) BOOL isPlaying;

- (instancetype)initWithFileURL:(NSURL *)fileURL
                      configure:(FYAudioConfiguration *)configuration;

- (void)play;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
