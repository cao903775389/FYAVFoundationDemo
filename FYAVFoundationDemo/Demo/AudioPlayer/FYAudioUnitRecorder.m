//
//  FYAudioUnitRecorder.m
//  FYAVFoundationDemo
//
//  Created by admin on 2020/1/5.
//  Copyright © 2020 fengyangcao. All rights reserved.
//

#import "FYAudioUnitRecorder.h"
#import "FYAudioConfiguration.h"
#import <AVFoundation/AVFoundation.h>
#import "FYUnitTool.h"
#import "FYAudioSession.h"

@interface FYAudioUnitRecorder () {
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
    
    AudioBufferList *_bufferList;
}

@property (nonatomic, strong, nullable) FYAudioConfiguration *configuration;
@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, assign) FYAudioSetupResult setupResult;
@property (nonatomic, strong) FYAudioSession *audioSession;

@end

@implementation FYAudioUnitRecorder

- (void)dealloc {
    NSLog(@"%@ delloc", [self class]);
    [self destory];
}

- (instancetype)initWithConfiguration:(FYAudioConfiguration *)configuration {
    if (self = [super init]) {
        _configuration = configuration;
        _sessionQueue = dispatch_queue_create("com.fy.audioUnitRecord.queue", DISPATCH_QUEUE_SERIAL);
        [self setupAudioSession];
        [self setupAudioUnit];
    }
    return self;
}

- (void)startRecord {
    if (self.setupResult != FYAudioSetupResultSuccess) {
        NSLog(@"AudioUnit初始化失败或者文件为空!!!");
        return;
    }
    OSStatus status;
    CAShow(self->_processingGraph);
    status = AUGraphInitialize(self->_processingGraph);
    if (status != noErr) {
        NSLog(@"AUGraphInitialize fail %d",status);
    }
    status = AUGraphStart(self->_processingGraph);
    if (status != noErr) {
        NSLog(@"AUGraphStart fail %d",status);
    }
}

- (void)stopRecord {
    OSStatus status;
    status = AUGraphStop(self->_processingGraph);
    if (status != noErr) {
        NSLog(@"AUGraphStop fail %d",status);
    }
    NSLog(@"AUGraphStop status %d",status);
}

- (void)destory {
    if (_processingGraph) {
        AUGraphStop(_processingGraph);
        AUGraphUninitialize(_processingGraph);
        AUGraphClose(_processingGraph);
        AUGraphRemoveNode(_processingGraph, _ioNode);
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
}

- (void)setupAudioSession {
    dispatch_async(_sessionQueue, ^{
        FYAudioConfiguration *configuration = [FYAudioConfiguration defaultConfiguration];
        self.audioSession = [[FYAudioSession alloc] initWithConfiguration:configuration category:AVAudioSessionCategoryPlayAndRecord options:AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionAllowBluetoothA2DP];
    });
}

- (void)setupAudioUnit {
    dispatch_async(_sessionQueue, ^{
        [self setupAudioUnitMethod2];
        [self setupAudioUnitProperty];
    });
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
//    _convertDes = [FYUnitTool componentDesWithType:kAudioUnitType_FormatConverter subType:kAudioUnitSubType_AUConverter];
//    AUGraphAddNode(_processingGraph, &_convertDes, &_convertNode);
    
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
    
//    status = AUGraphNodeInfo(_processingGraph, _convertNode, NULL, &_convertUnit);
//    if (status != noErr) {
//        NSLog(@"AUGraphNodeInfo failed %d", status);
//        self.setupResult = FYAudioSetupResultFailed;
//    }
}

//设置AudioUnit参数
- (void)setupAudioUnitProperty {
    if (self.setupResult == FYAudioSetupResultNotAuthorized || self.setupResult == FYAudioSetupResultFailed) {
        return;
    }
    UInt32 flag = 1; //1 enable 0 disable
    AudioUnitElement outputBus = 0; //Element0 output
    AudioUnitElement inputBus = 1; //Element1 input

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
    
    //开启麦克风录制功能
    status = AudioUnitSetProperty(
          _ioUnit,
          kAudioOutputUnitProperty_EnableIO,
          kAudioUnitScope_Input,
          inputBus,
          &flag,
          sizeof(flag)
    );
    if (status != noErr) {
        self.setupResult = FYAudioSetupResultFailed;
        NSLog(@"AudioUnitSetProperty io fail %d",status);
    }
    
    NSInteger sampleRate = self.audioSession.configuration.audioSampleRate;
    NSInteger channels = self.audioSession.configuration.channels;
    AudioFormatFlags flags = self.audioSession.formatFlags;
    NSInteger bytesPerChannel = self.audioSession.bytesPerChannel;
    
    //设置麦克风录制的音频流格式
    AudioStreamBasicDescription recordASBD = [FYUnitTool streamDesWithLinearPCMformat:flags
                                                         sampleRate:sampleRate
                                                           channels:channels
                                                    bytesPerChannel:bytesPerChannel];
    //设置麦克风的输出流格式
    status = AudioUnitSetProperty(
         _ioUnit,
         kAudioUnitProperty_StreamFormat,
         kAudioUnitScope_Output,
         inputBus,
         &recordASBD,
         sizeof(recordASBD)
    );
    if (status != noErr) {
        self.setupResult = FYAudioSetupResultFailed;
        NSLog(@"AudioUnitSetProperty io fail %d",status);
    }
    
    //设置扬声器输入流格式
    status = AudioUnitSetProperty(
         _ioUnit,
         kAudioUnitProperty_StreamFormat,
         kAudioUnitScope_Input,
         outputBus,
         &recordASBD,
         sizeof(recordASBD)
    );
    if (status != noErr) {
        self.setupResult = FYAudioSetupResultFailed;
        NSLog(@"AudioUnitSetProperty io fail %d",status);
    }
    
    // PCM文件的音频的数据格式
//    _convertInputStreamDes = [FYUnitTool streamDesWithLinearPCMformat:flags
//                    sampleRate:sampleRate
//                      channels:channels
//               bytesPerChannel:bytesPerChannel];
//
//
//    //设置格式转换的的输入端和输出端 对于格式转换器AudioUnit 他的AudioUnitElement只有一个 element0
//    status = AudioUnitSetProperty(
//          _convertUnit,
//          kAudioUnitProperty_StreamFormat,
//          kAudioUnitScope_Input,
//          outputBus,
//          &_convertInputStreamDes,
//          sizeof(_convertInputStreamDes)
//    );
//    if (status != noErr) {
//        self.setupResult = FYAudioSetupResultFailed;
//        NSLog(@"AudioUnitSetProperty io fail %d",status);
//    }
//
//    status = AudioUnitSetProperty(
//          _convertUnit,
//          kAudioUnitProperty_StreamFormat,
//          kAudioUnitScope_Output,
//          outputBus,
//          &_ioStreamDes,
//          sizeof(_ioStreamDes)
//    );
//    if (status != noErr) {
//        self.setupResult = FYAudioSetupResultFailed;
//        NSLog(@"AudioUnitSetProperty io fail %d",status);
//    }
    //构建连接
    status = AUGraphConnectNodeInput(_processingGraph, _ioNode, inputBus, _ioNode, outputBus);
    if (status != noErr) {
        self.setupResult = FYAudioSetupResultFailed;
        NSLog(@"AUGraphConnectNodeInput fail %d",status);
    }
    
    //设置麦克风音频采集回调
    AURenderCallbackStruct callBack;
    callBack.inputProc = handleInputBuffer;
    callBack.inputProcRefCon = (__bridge void*)self;
    
    //与上面的方法效果相同
    //    status = AUGraphSetNodeInputCallback(_processingGraph, _convertNode, outputBus, callBack);
    status = AudioUnitSetProperty(_ioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Output, inputBus, &callBack, sizeof(callBack));
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
static OSStatus handleInputBuffer(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    @autoreleasepool {
        FYAudioUnitRecorder *player = (__bridge FYAudioUnitRecorder*)inRefCon;
        AudioBufferList *bufferList = player->_bufferList;

        [player debugPrint:ioData inTimeStamp:inTimeStamp inBusNumber:inBusNumber inNumberFrames:inNumberFrames];

        OSStatus status = noErr;
        // 该函数的作用就是将麦克风采集的音频数据根据前面配置的RemoteIO输出数据格式渲染出来，然后放到
        // bufferList缓冲中；那么这里将是PCM格式的原始音频帧
        status = AudioUnitRender(player->_ioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, bufferList);
        if (status != noErr) {
            NSLog(@"AudioUnitRender fail %d",status);
        }
        if (bufferList->mBuffers[0].mData == NULL) {
            return noErr;
        }
        
//        if (player.inputStream != nil && player.fileType == FYAudioFileTypeLPCM) {
//            //判断PCM数据格式
//            if (player->_ioStreamDes.mFormatFlags & kAudioFormatFlagIsNonInterleaved) {
//                //kAudioFormatFlagIsNonInterleaved
//                NSInteger byteSize = (OSStatus)[player.inputStream read:ioData->mBuffers[0].mData maxLength:ioData->mBuffers[0].mDataByteSize];
//                if (byteSize < 0) {
//                    [player stop];
//                    return kCGErrorNoneAvailable;
//                }
//                [player debugPrint:ioData readByte:byteSize];
//                ioData->mBuffers[0].mDataByteSize = (UInt32)byteSize;
//
//            }else if (player->_ioStreamDes.mFormatFlags & kAudioFormatFlagIsPacked) {
//                //kAudioFormatFlagIsPacked
//                for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; iBuffer++) {
//                    NSInteger byteSize = (UInt32)[player.inputStream read:ioData->mBuffers[iBuffer].mData maxLength:(NSInteger)ioData->mBuffers[iBuffer].mDataByteSize];
//                    if (byteSize <=0) {
//                        [player stop];
//                        break;
//                    }
//                    [player debugPrint:ioData readByte:byteSize];
//                    ioData->mBuffers[iBuffer].mDataByteSize = (UInt32)byteSize;
//                }
//            }
//        }
        return noErr;
    }
}

- (void)debugPrint:(AudioBufferList *)ioData
                 inTimeStamp:(const AudioTimeStamp *)inTimeStamp
               inBusNumber:(UInt32)inBusNumber
            inNumberFrames:(UInt32)inNumberFrames {
    
    NSMutableString *printStr = [NSMutableString new];
    AudioBuffer *mbuffer = ioData->mBuffers;
    UInt32 mbuffersNum = ioData->mNumberBuffers;
    [printStr appendFormat:@"begin record"];
    [printStr appendFormat:@"duration: %f\n", inTimeStamp->mSampleTime];
    [printStr appendFormat:@"inBusNumber: %d\n", inBusNumber];
    [printStr appendFormat:@"inNumberFrames: %d\n", inNumberFrames];
    [printStr appendFormat:@"buffer data: %p\n", mbuffer->mData];
    [printStr appendFormat:@"buffer data byteSize: %u\n", (unsigned int)mbuffer->mDataByteSize];
    [printStr appendFormat:@"buffer data channels: %u\n", (unsigned int)mbuffer->mNumberChannels];
    [printStr appendFormat:@"buffers num: %d\n", mbuffersNum];
    NSLog(@"%@", printStr);
}

@end
