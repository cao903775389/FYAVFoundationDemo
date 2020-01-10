//
//  FYEXAudioFile.h
//  FYAVFoundationDemo
//  封装EXAudioFile对音频数据的编解码
//  Created by admin on 2020/1/9.
//  Copyright © 2020 fengyangcao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FYConstant.h"
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FYEXAudioFile : NSObject {
    AudioStreamBasicDescription clientABSD;
}

//是否开启硬编
@property (nonatomic, assign) BOOL enableHardwareCodec;

//读取音频文件并进行解码
//clientabsd:从文件中读取数据后的输出给app的音频数据格式，函数内部会使用实际的采样率和声道数，这里只需要指定采样格式和存储方式(planner还是packet)

- (instancetype)initExAudioFileWithReadPath:(NSString *)path
                                      flags:(AudioFormatFlags)flags
                            bytesPerChannel:(NSInteger)bytesPerChannel;

//编码音频数据并写入目标文件
- (instancetype)initExAudioFileWithWritePath:(NSString *)path
                                        adsb:(AudioStreamBasicDescription)clientabsd
                                    fileType:(FYAudioFileType)fileType;

// 从文件中读取音频数据
- (OSStatus)readFrames:(UInt32*)framesNum toBufferData:(AudioBufferList*)bufferlist;

//关闭文件
- (void)closeFile;

- (AudioStreamBasicDescription)clientAbsdForReader;
- (AudioStreamBasicDescription)clientAbsdForWriter;


@end

NS_ASSUME_NONNULL_END
