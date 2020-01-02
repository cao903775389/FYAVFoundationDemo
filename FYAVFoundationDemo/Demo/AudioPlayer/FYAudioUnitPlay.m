//
//  FYAudioUnitPlay.m
//  FYAVFoundationDemo
//
//  Created by admin on 2019/12/31.
//  Copyright © 2019 fengyangcao. All rights reserved.
//

#import "FYAudioUnitPlay.h"
#import <AVFoundation/AVFoundation.h>
#import "FYUnitTool.h"

@interface FYAudioUnitPlay () {
    AUGraph _processingGraph;
    
    //播放
    AudioUnit _ioUnit;
    AudioComponentDescription _ioDes;
    AudioStreamBasicDescription _ioStreamDes; //扬声器播放的流格式
    AUNode _ioNode;
    
    //格式转换
    AudioUnit _convertUnit;
    AudioComponentDescription _convertDes;
    AudioStreamBasicDescription _convertInputStreamDes; //需要转换的文件流格式
    AUNode _convertNode;
}

@property (nonatomic, copy, nullable) NSURL *fileURL;
@property (nonatomic, assign) FYAudioFileType fileType;

@property (nonatomic, assign) FYAudioSetupResult setupResult;
@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) FYAudioSession *audioSession;

@end

@implementation FYAudioUnitPlay

- (void)dealloc {
    NSLog(@"%@ delloc", [self class]);
    [self destory];
}

- (instancetype)initWithFileURL:(NSURL *)fileURL fileType:(FYAudioFileType)fileType {
    if (self = [super init]) {
        _fileType = fileType;
        _fileURL = fileURL;
        _sessionQueue = dispatch_queue_create("com.fy.audioUnit.queue", DISPATCH_QUEUE_SERIAL);
        [self prepare];
        [self setupAudioSession];
        [self setupAudioUnit];
    }
    return self;
}

- (void)initInputStream:(NSURL *)url {
    if ([[NSFileManager defaultManager] fileExistsAtPath:_fileURL.path]) {
        // open pcm stream
        _inputStream = [NSInputStream inputStreamWithURL:url];
        if (!_inputStream) {
            NSLog(@"打开文件失败 %@", url);
        }
        else {
            [_inputStream open];
        }
    }
}

- (void)play {
    if (self.setupResult != FYAudioSetupResultSuccess) {
        NSLog(@"AudioUnit初始化失败或者文件为空!!!");
        return;
    }
    OSStatus status;
    CAShow(_processingGraph);
    status = AUGraphInitialize(_processingGraph);
    if (status != noErr) {
        NSLog(@"AUGraphInitialize fail %d",status);
    }
    status = AUGraphStart(_processingGraph);
    if (status != noErr) {
        NSLog(@"AUGraphStart fail %d",status);
    }
    
    if (_inputStream == nil) {
        [self initInputStream:_fileURL];
    }
}

- (void)stop {
    OSStatus status;
    status = AUGraphStop(_processingGraph);
    if (status != noErr) {
        NSLog(@"AUGraphStop fail %d",status);
    }
    [_inputStream close];
    _inputStream = nil;
    NSLog(@"AUGraphStop status %d",status);
}

- (void)destory {
    if (_processingGraph) {
        AUGraphStop(_processingGraph);
        AUGraphUninitialize(_processingGraph);
        AUGraphClose(_processingGraph);
        AUGraphRemoveNode(_processingGraph, _ioNode);
        AUGraphRemoveNode(_processingGraph, _convertNode);
        _ioUnit = NULL;
        _ioNode = 0;
        _processingGraph = NULL;
    }else {
        AudioOutputUnitStop(_ioUnit);
    }
}

- (void)prepare {
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio]) {
        case AVAuthorizationStatusAuthorized:
            self.setupResult = FYAudioSetupResultSuccess;
            break;
        case AVAuthorizationStatusNotDetermined: {
            dispatch_suspend(_sessionQueue);
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                if (!granted) {
                    self.setupResult = FYAudioSetupResultNotAuthorized;
                }
                dispatch_resume(self.sessionQueue);
            }];
            break;
        }
        default:
            self.setupResult = AVAuthorizationStatusNotDetermined;
            break;
    }
    [self initInputStream:_fileURL];
}

- (void)setupAudioSession {
    dispatch_async(_sessionQueue, ^{
        self.audioSession = [[FYAudioSession alloc] initWithSampleRate:44100
                                              category:AVAudioSessionCategoryPlayback
                                              channels:FYAudioChannelDouble
                                        bufferDuration:FYSAudioSessionDelay_Default
                                            formatType:FYAudioFormatType32Float
                                              dataType:FYAudioDataTypePacket];
    });
}

- (void)setupAudioUnit {
    dispatch_async(_sessionQueue, ^{
//        [self setupAudioUnitMethod1];
        [self setupAudioUnitMethod2];
        [self setupAudioUnitProperty];
    });
}

//创建方式1
- (void)setupAudioUnitMethod1 {
    if (self.setupResult == FYAudioSetupResultNotAuthorized || self.setupResult == FYAudioSetupResultFailed) {
        return;
    }
    AudioComponentDescription ioUnitDesc = [FYUnitTool componentDesWithType:kAudioUnitType_Output subType:kAudioUnitSubType_RemoteIO];
    AudioComponent ioUnitRef = AudioComponentFindNext(NULL, &ioUnitDesc);
    OSStatus status = AudioComponentInstanceNew(ioUnitRef, &_ioUnit);
    if (status != noErr) {
        self.setupResult = FYAudioSetupResultFailed;
    }
}

//创建方式2
- (void)setupAudioUnitMethod2 {
    if (self.setupResult == FYAudioSetupResultNotAuthorized || self.setupResult == FYAudioSetupResultFailed) {
        return;
    }
    
    OSStatus status = noErr;
    
    status = NewAUGraph(&_processingGraph);
    if (status != noErr) {
        NSLog(@"create graph failed %d", status);
        self.setupResult = FYAudioSetupResultFailed;
    }

    //创建IOUnit
    _ioDes = [FYUnitTool componentDesWithType:kAudioUnitType_Output subType:kAudioUnitSubType_RemoteIO];
    status = AUGraphAddNode(_processingGraph, &_ioDes, &_ioNode);
    if (status != noErr) {
        NSLog(@"AUGraphAddNode failed %d", status);
        self.setupResult = FYAudioSetupResultFailed;
    }
    
    //创建ConvertUnit
    _convertDes = [FYUnitTool componentDesWithType:kAudioUnitType_FormatConverter subType:kAudioUnitSubType_AUConverter];
    AUGraphAddNode(_processingGraph, &_convertDes, &_convertNode);
    
    status = AUGraphOpen(_processingGraph);
    if (status != noErr) {
        NSLog(@"AUGraphOpen failed %d", status);
        self.setupResult = FYAudioSetupResultFailed;
    }
    
    status = AUGraphNodeInfo(_processingGraph, _ioNode, NULL, &_ioUnit);
    if (status != noErr) {
        NSLog(@"AUGraphNodeInfo failed %d", status);
        self.setupResult = FYAudioSetupResultFailed;
    }
    
    status = AUGraphNodeInfo(_processingGraph, _convertNode, NULL, &_convertUnit);
    if (status != noErr) {
        NSLog(@"AUGraphNodeInfo failed %d", status);
        self.setupResult = FYAudioSetupResultFailed;
    }
}

//设置AudioUnit参数
- (void)setupAudioUnitProperty {
    if (self.setupResult == FYAudioSetupResultNotAuthorized || self.setupResult == FYAudioSetupResultFailed) {
        return;
    }
    UInt32 flag = 1; //1 enable 0 disable
    AudioUnitElement outputBus = 0; //Element0 output

    //Element -> Input Scope 、Output Scope
    //Element0 输出端 Element1 输入端
    OSStatus status = noErr;
    
    //开启扬声器的播放功能
    status = AudioUnitSetProperty(
          _ioUnit,
          kAudioOutputUnitProperty_EnableIO,
          kAudioUnitScope_Output,
          outputBus,
          &flag,
          sizeof(flag)
    );
    if (status != noErr) {
        self.setupResult = FYAudioSetupResultFailed;
        NSLog(@"AudioUnitSetProperty io fail %d",status);
    }
    
    NSInteger sampleRate = self.audioSession.sampleRate;
    NSInteger channels = self.audioSession.channels;
    
    //设置AudioUnit 数据格式
    _ioStreamDes = [FYUnitTool streamDesWithLinearPCMformat:kAudioFormatFlagIsFloat|kAudioFormatFlagIsNonInterleaved
                     sampleRate:sampleRate
                       channels:channels
                bytesPerChannel:4];
    
    // PCM文件的音频的数据格式
    AudioFormatFlags flags = self.audioSession.formatFlags;
    NSInteger bytesPerChannel = self.audioSession.bytesPerChannel;
    
    _convertInputStreamDes = [FYUnitTool streamDesWithLinearPCMformat:flags
                    sampleRate:sampleRate
                      channels:channels
               bytesPerChannel:bytesPerChannel];
    
    //设置扬声器的输入流格式
    status = AudioUnitSetProperty(
         _ioUnit,
         kAudioUnitProperty_StreamFormat,
         kAudioUnitScope_Input,
         outputBus,
         &_ioStreamDes,
         sizeof(_ioStreamDes)
    );
    if (status != noErr) {
        self.setupResult = FYAudioSetupResultFailed;
        NSLog(@"AudioUnitSetProperty io fail %d",status);
    }
    
    //设置格式转换的的输入端和输出端 对于格式转换器AudioUnit 他的AudioUnitElement只有一个 element0
    status = AudioUnitSetProperty(
          _convertUnit,
          kAudioUnitProperty_StreamFormat,
          kAudioUnitScope_Input,
          outputBus,
          &_convertInputStreamDes,
          sizeof(_convertInputStreamDes)
    );
    if (status != noErr) {
        self.setupResult = FYAudioSetupResultFailed;
        NSLog(@"AudioUnitSetProperty io fail %d",status);
    }
    
    status = AudioUnitSetProperty(
          _convertUnit,
          kAudioUnitProperty_StreamFormat,
          kAudioUnitScope_Output,
          outputBus,
          &_ioStreamDes,
          sizeof(_ioStreamDes)
    );
    if (status != noErr) {
        self.setupResult = FYAudioSetupResultFailed;
        NSLog(@"AudioUnitSetProperty io fail %d",status);
    }
    //构建连接
    status = AUGraphConnectNodeInput(_processingGraph, _convertNode, outputBus, _ioNode, outputBus);
    if (status != noErr) {
        self.setupResult = FYAudioSetupResultFailed;
        NSLog(@"AUGraphConnectNodeInput fail %d",status);
    }
    
    //设置Convert的输入数据源
    AURenderCallbackStruct callBack;
    callBack.inputProc = handleInputBuffer;
    callBack.inputProcRefCon = (__bridge void*)self;
    
    status = AudioUnitSetProperty(_convertUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, outputBus, &callBack, sizeof(callBack));
    
    //与上面的方法效果相同
//    status = AUGraphSetNodeInputCallback(_processingGraph, _convertNode, outputBus, callBack);
    if (status != noErr) {
        self.setupResult = FYAudioSetupResultFailed;
        NSLog(@"AudioUnitSetProperty fail %d",status);
    }
    
    if (status == noErr && self.setupResult != FYAudioSetupResultFailed) {
        self.setupResult = FYAudioSetupResultSuccess;
        NSLog(@"AudioUnitSetProperty set up success");
    }
}

#pragma mark - 通过该回调读取数据
/** AudioBufferList详解
*  struct AudioBufferList
*  {
*      UInt32      mNumberBuffers;
*      AudioBuffer mBuffers[1]; // 这里的定义等价于 AudioBuffer *mBuffers,所以它的元素个数是不固定的,元素个数由mNumberBuffers决定;
*      mFormatFlags = kAudioFormatFlagIsNonInterleaved   AudioBufferList mBuffers[0] = 左声道 mBuffers[1] = 右声道
*      mFormatFlags = kAudioFormatFlagIsInterleaved         AudioBufferList mBuffers[0] = 左声道/右声道
*      对于packet数据,各个声道数据依次存储在mBuffers[0]中,对于planner格式,每个声道数据分别存储在mBuffers[0],...,mBuffers[i]中
*      对于packet数据,AudioBuffer中mNumberChannels数目等于channels数目，对于planner则始终等于1
*      ......
*  };
*  typedef struct AudioBufferList  AudioBufferList;
 
 struct AudioBuffer
 {
     UInt32              mNumberChannels;
     UInt32              mDataByteSize;
     void* __nullable    mData;
 };
 typedef struct AudioBuffer  AudioBuffer;
 
*/
static OSStatus handleInputBuffer(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    @autoreleasepool {
        FYAudioUnitPlay *player = (__bridge FYAudioUnitPlay*)inRefCon;
        if (player.inputStream != nil && player.fileType == FYAudioFileTypeLPCM) {
            //判断PCM数据格式
            if (player->_ioStreamDes.mFormatFlags & kAudioFormatFlagIsNonInterleaved) {
                //kAudioFormatFlagIsNonInterleaved
                NSInteger byteSize = (OSStatus)[player.inputStream read:ioData->mBuffers[0].mData maxLength:ioData->mBuffers[0].mDataByteSize];
                if (byteSize < 0) {
                    [player stop];
                    return kCGErrorNoneAvailable;
                }
                [player debugPrint:ioData readByte:byteSize];
                ioData->mBuffers[0].mDataByteSize = (UInt32)byteSize;

            }else if (player->_ioStreamDes.mFormatFlags & kAudioFormatFlagIsPacked) {
                //kAudioFormatFlagIsPacked
                for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; iBuffer++) {
                    NSInteger byteSize = (UInt32)[player.inputStream read:ioData->mBuffers[iBuffer].mData maxLength:(NSInteger)ioData->mBuffers[iBuffer].mDataByteSize];
                    if (byteSize <=0) {
                        [player stop];
                        break;
                    }
                    [player debugPrint:ioData readByte:byteSize];
                    ioData->mBuffers[iBuffer].mDataByteSize = (UInt32)byteSize;
                }
            }
        }
        return noErr;
    }
}

- (void)debugPrint:(AudioBufferList *)ioData readByte:(NSInteger)readByte {
    NSMutableString *printStr = [NSMutableString new];
    AudioBuffer *mbuffer = ioData->mBuffers;
    UInt32 mbuffersNum = ioData->mNumberBuffers;
    [printStr appendFormat:@"read input data: %ld\n", (long)readByte];
    [printStr appendFormat:@"buffer data: %p\n", mbuffer->mData];
    [printStr appendFormat:@"buffer data byteSize: %u\n", (unsigned int)mbuffer->mDataByteSize];
    [printStr appendFormat:@"buffer data channels: %u\n", (unsigned int)mbuffer->mNumberChannels];
    [printStr appendFormat:@"buffers num: %d\n", mbuffersNum];
    NSLog(@"%@", printStr);
}

@end
