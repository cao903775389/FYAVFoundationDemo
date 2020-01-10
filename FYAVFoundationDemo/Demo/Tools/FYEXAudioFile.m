//
//  FYEXAudioFile.m
//  FYAVFoundationDemo
//
//  Created by admin on 2020/1/9.
//  Copyright © 2020 fengyangcao. All rights reserved.
//

#import "FYEXAudioFile.h"
#import "FYUnitTool.h"

@interface FYEXAudioFile () {
    ExtAudioFileRef _audioFile;
    
    // 用于写
    AudioFileTypeID             _fileTypeId;
    AudioStreamBasicDescription _clientabsdForWriter;
    AudioStreamBasicDescription _fileDataabsdForWriter;
    
    // 用于读
    AudioStreamBasicDescription _clientabsdForReader;
    AudioStreamBasicDescription _fileDataabsdForReader;
    UInt32 _packetSize;
    SInt64 _totalFrames;
}

@property (nonatomic, copy, nullable) NSString *filePath;

@end

@implementation FYEXAudioFile

- (void)dealloc {
    [self closeFile];
}

//读取音频文件并进行解码
- (instancetype)initExAudioFileWithReadPath:(NSString *)path flags:(AudioFormatFlags)flags bytesPerChannel:(NSInteger)bytesPerChannel {
    if (path.length == 0) {
        return nil;
    }
    if (self = [super init]) {
        _filePath = path;
        NSURL *fileURL = [NSURL fileURLWithPath:path];
        OSStatus status = noErr;
        //打开文件
        status = ExtAudioFileOpenURL((__bridge CFURLRef)fileURL, &_audioFile);
        if (status != noErr) {
            NSLog(@"ExtAudioFileOpenURL faile %d",status);
            return nil;
        }
        
        /** 通过ExtAudioFileGetProperty()函数获取文件有关属性，比如编码格式，总共的音频frames数目等等；
        *  这些步骤对于读取数据不是必须的，主要用于打印和分析
        */
        
        //文件音频流数据格式
        UInt32 size = sizeof(_fileDataabsdForReader);
        status = ExtAudioFileGetProperty(_audioFile, kExtAudioFileProperty_FileDataFormat, &size, &_fileDataabsdForReader);
        if (status != noErr) {
            NSLog(@"ExtAudioFileGetProperty kExtAudioFileProperty_FileDataFormat fail %d",status);
            return nil;
        }
        
        size = sizeof(_packetSize);
        ExtAudioFileGetProperty(_audioFile, kExtAudioFileProperty_ClientMaxPacketSize, &size, &_packetSize);
        NSLog(@"每次读取的packet的大小: %u",(unsigned int)_packetSize);
        
        // 备注：_totalFrames一定要是SInt64类型的，否则会出错。
        size = sizeof(_totalFrames);
        ExtAudioFileGetProperty(_audioFile, kExtAudioFileProperty_FileLengthFrames, &size, &_totalFrames);
        NSLog(@"文件中包含的frame数目: %lld",_totalFrames);
        
        // 设置从文件中读取数据后经过解码等步骤后最终输出的数据格式
        _clientabsdForReader = [FYUnitTool streamDesWithLinearPCMformat:flags sampleRate:_fileDataabsdForReader.mSampleRate channels:_fileDataabsdForReader.mChannelsPerFrame bytesPerChannel:bytesPerChannel];
        
        status = ExtAudioFileSetProperty(_audioFile, kExtAudioFileProperty_ClientDataFormat, sizeof(_clientabsdForReader), &_clientabsdForReader);
        if (status != noErr) {
            NSLog(@"ExtAudioFileSetProperty kExtAudioFileProperty_ClientDataFormat fail %d",status);
            return nil;
        }
    }
    return self;
}

//编码音频数据并写入目标文件
- (instancetype)initExAudioFileWithWritePath:(NSString *)path
                                        adsb:(AudioStreamBasicDescription)clientabsd
                                    fileType:(FYAudioFileType)fileType {
    if (path.length == 0) {
        return nil;
    }
    if (self = [super init]) {
        _filePath = path;
        _fileTypeId = convertFromFileType(fileType);
        _clientabsdForWriter = clientabsd;
        
        //初始化文件
        
    }
    return self;
}

- (void)closeFile {
    if (_audioFile) {
        ExtAudioFileDispose(_audioFile);
        _audioFile = nil;
    }
}

// 从文件中读取音频数据
- (OSStatus)readFrames:(UInt32*)framesNum toBufferData:(AudioBufferList*)bufferlist {
//    if (_canrepeat) {
//        SInt64 curFramesOffset = 0;
        // 目前读取指针的postion
//        if (ExtAudioFileTell(_audioFile, &curFramesOffset) == noErr) {
//
//            if (curFramesOffset >= _totalFrames) {   // 已经读取完毕
//                ExtAudioFileSeek(_audioFile, 0);
//                curFramesOffset = 0;
//            }
//        }
//    }
    OSStatus status = ExtAudioFileRead(_audioFile, framesNum, bufferlist);
    return status;
}

- (AudioStreamBasicDescription)clientAbsdForReader {
    return _clientabsdForReader;
}
- (AudioStreamBasicDescription)clientAbsdForWriter {
    return _clientabsdForWriter;
}

@end
