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

- (instancetype)initWithFileURL:(NSURL *)fileURL fileType:(FYAudioFileType)fileType;

- (void)play;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
