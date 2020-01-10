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
    AUNode _ioNode;
    
    //格式转换
    AudioUnit _convertUnit;
    AUNode _convertNode;
}

@property (nonatomic, copy, nullable) NSURL *fileURL;
@property (nonatomic, assign) FYAudioSetupResult setupResult;
@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) FYAudioSession *audioSession;
@property (nonatomic, assign) BOOL isPlaying;

@property (nonatomic, strong) FYAudioConfiguration *configuration;

@end

@implementation FYAudioUnitPlay

- (void)dealloc {
    NSLog(@"%@ delloc", [self class]);
    [self destory];
}

- (instancetype)initWithFileURL:(NSURL *)fileURL configure:(nonnull FYAudioConfiguration *)configuration {
    if (self = [super init]) {
        _fileURL = fileURL;
        _configuration = configuration;
        _sessionQueue = dispatch_queue_create("com.fy.audioUnit.queue", DISPATCH_QUEUE_SERIAL);
        [self prepare];
        [self setupAudioSession];
        [self setupAudioUnit];
    }
    return self;
}

- (BOOL)initInputStream:(NSURL *)url {
    if ([[NSFileManager defaultManager] fileExistsAtPath:_fileURL.path]) {
        // open pcm stream
        _inputStream = [NSInputStream inputStreamWithURL:url];
        if (!_inputStream) {
            NSLog(@"打开文件失败 %@", url);
            return NO;
        }
        else {
            [_inputStream open];
            return YES;
        }
    }
    return NO;
}

- (void)play {
    if (self.setupResult != FYAudioSetupResultSuccess) {
        NSLog(@"AudioUnit初始化失败或者文件为空!!!");
        return;
    }
    dispatch_async(_sessionQueue, ^{
        OSStatus status;
        BOOL success = YES;
        if (self.inputStream == nil) {
            success = [self initInputStream:self.fileURL];
        }
        if (success == NO) {
            return ;
        }
        status = AUGraphInitialize(self->_processingGraph);
        if (status != noErr) {
            success = NO;
            NSLog(@"AUGraphInitialize fail %d",status);
        }
        status = AUGraphStart(self->_processingGraph);
        if (status != noErr) {
            success = NO;
            NSLog(@"AUGraphStart fail %d",status);
        }
        
        if (success) {
            self.isPlaying = YES;
        }
    });
}

- (void)stop {
    dispatch_async(_sessionQueue, ^{
        OSStatus status;
        status = AUGraphStop(self->_processingGraph);
        if (status != noErr) {
            NSLog(@"AUGraphStop fail %d",status);
        }
        [self->_inputStream close];
        self->_inputStream = nil;
        NSLog(@"AUGraphStop status %d",status);
        self.isPlaying = NO;
    });
}

- (void)destory {
    if (_processingGraph) {
        AUGraphStop(_processingGraph);
        AUGraphUninitialize(_processingGraph);
        AUGraphClose(_processingGraph);
        AUGraphRemoveNode(_processingGraph, _ioNode);
        AUGraphRemoveNode(_processingGraph, _convertNode);
        _ioUnit = NULL;
        _convertUnit = NULL;
        _ioNode = 0;
        _convertNode = 0;
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
}

- (void)setupAudioSession {
    dispatch_async(_sessionQueue, ^{
        if (self.configuration.audioFileType == FYAudioFileTypeLPCM) {
            self.configuration.audioDataType = FYAudioDataTypePacket;
        }else {
            // 从音频文件中读取数据解码后的音频数据格式;经过测试，发现只支持AudioFilePlayer解码后输出的数据格式只支持
            // kAudioFormatFlagIsFloat|kAudioFormatFlagIsNonInterleaved;
//            AudioFormatFlags flags = kAudioFormatFlagIsFloat|kAudioFormatFlagIsNonInterleaved;
            //暂不支持
            
        }
        self.audioSession = [[FYAudioSession alloc] initWithConfiguration:self.configuration category:AVAudioSessionCategoryPlayback options:AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionAllowBluetoothA2DP];

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
    AudioComponentDescription ioDes = [FYUnitTool componentDesWithType:kAudioUnitType_Output subType:kAudioUnitSubType_RemoteIO];
    status = AUGraphAddNode(_processingGraph, &ioDes, &_ioNode);
    if (status != noErr) {
        NSLog(@"AUGraphAddNode failed %d", status);
        self.setupResult = FYAudioSetupResultFailed;
    }
    
    //创建ConvertUnit
    AudioComponentDescription convertDes = [FYUnitTool componentDesWithType:kAudioUnitType_FormatConverter subType:kAudioUnitSubType_AUConverter];
    AUGraphAddNode(_processingGraph, &convertDes, &_convertNode);
    
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
    
    NSInteger sampleRate = self.audioSession.configuration.audioSampleRate;
    NSInteger channels = self.audioSession.configuration.channels;
    
    //设置AudioUnit 数据格式
    AudioStreamBasicDescription ioStreamDes = [FYUnitTool streamDesWithLinearPCMformat:kAudioFormatFlagIsFloat|kAudioFormatFlagIsNonInterleaved
                     sampleRate:sampleRate
                       channels:channels
                bytesPerChannel:sizeof(Float32)];
    
    // PCM文件的音频的数据格式
    AudioFormatFlags flags = self.audioSession.formatFlags;
    NSInteger bytesPerChannel = self.audioSession.bytesPerChannel;
    
    AudioStreamBasicDescription convertInputStreamDes = [FYUnitTool streamDesWithLinearPCMformat:flags
                    sampleRate:sampleRate
                      channels:channels
               bytesPerChannel:bytesPerChannel];
    
    //设置扬声器的输入流格式
    status = AudioUnitSetProperty(
         _ioUnit,
         kAudioUnitProperty_StreamFormat,
         kAudioUnitScope_Input,
         outputBus,
         &ioStreamDes,
         sizeof(ioStreamDes)
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
          &convertInputStreamDes,
          sizeof(convertInputStreamDes)
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
          &ioStreamDes,
          sizeof(ioStreamDes)
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
        if (player.inputStream != nil && player.configuration.audioFileType == FYAudioFileTypeLPCM) {
            //判断PCM数据格式
            if (player.audioSession.configuration.audioDataType == FYAudioDataTypeNonInterleaved) {
                //kAudioFormatFlagIsNonInterleaved
                NSInteger byteSize = (OSStatus)[player.inputStream read:ioData->mBuffers[0].mData maxLength:ioData->mBuffers[0].mDataByteSize];
                if (byteSize < 0) {
                    [player stop];
                    return kCGErrorNoneAvailable;
                }
                [player debugPrint:ioData readByte:byteSize];
                ioData->mBuffers[0].mDataByteSize = (UInt32)byteSize;

            }else if (player.audioSession.configuration.audioDataType == FYAudioDataTypePacket) {
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
