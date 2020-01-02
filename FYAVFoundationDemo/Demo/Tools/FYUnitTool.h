//
//  FYUnitTool.h
//  FYAVFoundationDemo
//
//  Created by admin on 2019/12/31.
//  Copyright © 2019 fengyangcao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FYUnitTool : NSObject

+ (AudioComponentDescription)componentDesWithType:(OSType)type subType:(OSType)subType;

+ (AudioStreamBasicDescription)streamDesWithLinearPCMformat:(AudioFormatFlags)flags
                                                 sampleRate:(CGFloat)rate
                                                   channels:(NSInteger)chs
                                            bytesPerChannel:(NSInteger)bytesPerChann;

@end

NS_ASSUME_NONNULL_END
