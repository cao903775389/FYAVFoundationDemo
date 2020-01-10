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
#import "FYEXAudioFile.h"

#define BufferList_cache_size (1024*10*5)

@interface FYAudioUnitRecorder () {
    AUGraph _processingGraph;
    
    //remote io
    AudioUnit _ioUnit;
    AudioComponentDescription _ioDes;
    AUNode _ioNode;
    
    //混音器
    AudioUnit _mixerUnit;
    AUNode _mixerNode;
    AudioStreamBasicDescription _mixerStreamDesForInput;    // 混音器的输入数据格式
    AudioStreamBasicDescription _mixerStreamDesForOutput;    // 混音器的输出数据格式
    
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
@property (nonatomic, strong, nullable) FYFileDataWritter *audioWritter;
@property (nonatomic, assign) BOOL isRecording;
@property (nonatomic, strong, nullable) NSString *mixerPath;

@property (nonatomic, strong, nullable) FYEXAudioFile *dataReader;

@property (nonatomic, assign) BOOL enablePlayWhenRecord;
@property (nonatomic, assign) BOOL enableMixWhenRecord;
@property (nonatomic, assign) BOOL enableSaveLocal;
@end

@implementation FYAudioUnitRecorder

- (void)dealloc {
    NSLog(@"%@ delloc", [self class]);
    [self destory];
}

- (instancetype)initWithConfiguration:(FYAudioConfiguration *)configuration recordOption:(FYAudioUnitRecordOption)recordOption {
    return [self initWithConfiguration:configuration mixMusicFilePath:nil recordOption:recordOption];
}

- (instancetype)initWithConfiguration:(FYAudioConfiguration *)configuration
                     mixMusicFilePath:(NSString * _Nullable)mixMusicFilePath
                         recordOption:(FYAudioUnitRecordOption)recordOption {
    if (self = [super init]) {
        _configuration = configuration;
        _sessionQueue = dispatch_queue_create("com.fy.audioUnitRecord.queue", DISPATCH_QUEUE_SERIAL);
        _enablePlayWhenRecord = recordOption.enablePlayWhenRecord;
        _enableSaveLocal = recordOption.enableSaveLocal;
        _enableMixWhenRecord = recordOption.enableMixWhenRecord;
        [self setupAudioSession];
        [self setBackgroundMusicMixerPath:mixMusicFilePath];
        [self setupAudioUnit];
        _bufferList = (AudioBufferList *)malloc(sizeof(AudioBufferList) + (configuration.channels - 1) * sizeof(AudioBuffer));
        _bufferList->mNumberBuffers = configuration.audioDataType == FYAudioDataTypeNonInterleaved ? (UInt32)configuration.channels : 1;
        for (NSInteger i=0; i< configuration.channels; i++) {
            _bufferList->mBuffers[i].mData = malloc(BufferList_cache_size);
            _bufferList->mBuffers[i].mDataByteSize = BufferList_cache_size;
        }
    }
    return self;
}

/** 音轨混合的原理：
 *  空气中声波的叠加等价于量化的语音信号的叠加
 *  多路音轨混合的前提：
 *  需要叠加的音轨具有相同的采样频率，采样精度和采样通道，如果不相同，则需要先让他们相同
 *  1、不同采样频率需要算法进行重新采样处理
 *  2、不同采样精度则通过算法将精度保持一样，精度向上扩展和精度向下截取
 *  3、不同通道数也是和精度类似处理方式
 *  音轨混合算法：
 *  比如线性叠加平均、自适应混音、多通道混音等等
 *  线性叠加平均：原理就是把不同音轨的各个通道值(对应的每个声道的值)叠加之后取平均值，优点不会有噪音，缺点是如果
 *  某一路或几路音量特别小那么导致整个混音结果的音量变小
 *  伪代码 音轨1：a11b11c11a12b12c12a13b13c13
 *        音轨2：a21b21c21a22b22c22a23b23c23
 *        混音:  (a11+a21)/2(b11+b21)/2(c13+c23)/2
 *  自适应混音：根据每路音轨所占的比例权重进行叠加，具体算法有很多种，这里不详解
 *  多通道混音：将每路音轨分别放到各个声道上，就好比如果有两路音轨，则一路音轨放到左声道，一路音轨放到右声道。那如果
 *  要混合的音轨数大于设备的通道数呢？
 *  对于ios平台，提供了Mixer混音器，它提供了内置的混音算法供我们使用，我们只需要指定要混合的音轨数，混合后音轨音量大
 *  小，确定每路音轨的采样率一致等等配置参数即可。
 */
- (void)setBackgroundMusicMixerPath:(NSString *)path
{
    if (path == nil) {
        _enableMixWhenRecord = NO;
        NSLog(@"混音文件路径为空");
        return;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        _enableMixWhenRecord = NO;
        NSLog(@"混音文件不存在");
        return;
    }
    
    _mixerPath = path;
    
    /** 1、配置从文件中读取的音频数据最终解码后输出给app的数据格式，AudioUnitFileRex内部会进行解码，和格式转化
     *  2、混音要保证各个音轨的采样率，采样精度，声道数一致，这里不考虑这么复杂的情况，录制的音频格式保持与音频文件中音频格式一致
     *  3、如果两者不一致，则两路音轨数据传入混音器之前要进行重采样
     */
    /** 网络序就是大端序，Native就是主机序(跟硬件平台有关，要么大端序要么小端序)，一般一个类型的平台主机序是固定的
     *  比如ios平台Native就是小端序
     *  对于_mixerUnit，它的kAudioUnitScope_OutScope是一个和_clientFormat32float固定格式的ABSD，不需要
     *  额外设置
     */
    UInt32 bytesPerSample = 4;  // 要与下面mFormatFlags 对应
    AudioStreamBasicDescription absd;
    absd.mFormatID          = kAudioFormatLinearPCM;
    absd.mFormatFlags       = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    absd.mBytesPerPacket    = bytesPerSample;
    absd.mFramesPerPacket   = 1;
    absd.mBytesPerFrame     = 4;
    absd.mChannelsPerFrame  = 2;
    absd.mBitsPerChannel    = 8 * bytesPerSample;
    absd.mSampleRate        = 0;
    
    self.dataReader = [[FYEXAudioFile alloc] initExAudioFileWithReadPath:_mixerPath flags:absd.mFormatFlags bytesPerChannel:bytesPerSample];
    _mixerStreamDesForInput = [self.dataReader clientAbsdForReader];
}

- (void)startRecord {
    if (self.setupResult != FYAudioSetupResultSuccess) {
        NSLog(@"AudioUnit初始化失败或者文件为空!!!");
        return;
    }
    dispatch_async(_sessionQueue, ^{
        OSStatus status;
        [self.audioWritter deleteFile];
        BOOL success = YES;
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
        self.isRecording = success;
    });
}

- (void)stopRecord {
    dispatch_async(_sessionQueue, ^{
        OSStatus status;
        status = AUGraphStop(self->_processingGraph);
        if (status != noErr) {
            NSLog(@"AUGraphStop fail %d",status);
        }
        [self->_audioWritter finishWriting];
        self.isRecording = NO;
        NSLog(@"AUGraphStop status %d",status);
    });
}

- (void)destory {
    if (_processingGraph) {
        OSStatus status = noErr;
        status = AUGraphStop(_processingGraph);
        if (status != noErr) {
            NSLog(@"AUGraphStop fail %d",status);
        }
        status = AUGraphUninitialize(_processingGraph);
        if (status != noErr) {
            NSLog(@"AUGraphUninitialize fail %d",status);
        }
        status = AUGraphClose(_processingGraph);
        if (status != noErr) {
            NSLog(@"AUGraphClose fail %d",status);
        }
        status = AUGraphRemoveNode(_processingGraph, _ioNode);
        if (status != noErr) {
            NSLog(@"AUGraphRemove_ioNode fail %d",status);
        }
        status = AUGraphRemoveNode(_processingGraph, _convertNode);
        if (status != noErr) {
            NSLog(@"AUGraphRemove_convertNode fail %d",status);
        }
        status = AUGraphRemoveNode(_processingGraph, _mixerNode);
        if (status != noErr) {
            NSLog(@"AUGraphRemove_convertNode fail %d",status);
        }
        _ioUnit = NULL;
        _ioNode = 0;
        _convertUnit = NULL;
        _convertNode = 0;
        _mixerUnit = NULL;
        _mixerNode = 0;
        _processingGraph = NULL;
    }else {
        AudioOutputUnitStop(_ioUnit);
    }
    if (_bufferList != NULL) {
        for (int i=0; i<_bufferList->mNumberBuffers; i++) {
            if (_bufferList->mBuffers[i].mData != NULL) {
                free(_bufferList->mBuffers[i].mData);
                _bufferList->mBuffers[i].mData = NULL;
            }
        }
        free(_bufferList);
        _bufferList = NULL;
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
        self.audioSession = [[FYAudioSession alloc] initWithConfiguration:self.configuration category:AVAudioSessionCategoryPlayAndRecord options:AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionAllowBluetoothA2DP];
    });
}

- (void)setupAudioUnit {
    dispatch_async(_sessionQueue, ^{
        [self setupAudioUnitMethod2];
        [self setupAudioUnitProperty];
        [self connectAUGraphNode];
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
//    kAudioUnitSubType_VoiceProcessingIO（回声消除） & kAudioUnitSubType_RemoteIO
    _ioDes = [FYUnitTool componentDesWithType:kAudioUnitType_Output subType:kAudioUnitSubType_RemoteIO];
    status = AUGraphAddNode(_processingGraph, &_ioDes, &_ioNode);
    if (status != noErr) {
        NSLog(@"AUGraphAddNode failed %d", status);
        self.setupResult = FYAudioSetupResultFailed;
    }
    
    //创建ConvertUnit
    _convertDes = [FYUnitTool componentDesWithType:kAudioUnitType_FormatConverter subType:kAudioUnitSubType_AUConverter];
    AUGraphAddNode(_processingGraph, &_convertDes, &_convertNode);
    
    //混音器
    AudioComponentDescription mixDes = [FYUnitTool componentDesWithType:kAudioUnitType_Mixer subType:kAudioUnitSubType_MultiChannelMixer];
    AUGraphAddNode(_processingGraph, &mixDes, &_mixerNode);
    
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
    
    status = AUGraphNodeInfo(_processingGraph, _mixerNode, NULL, &_mixerUnit);
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
    AudioUnitElement inputBus = 1; //Element1 input

    //Element -> Input Scope 、Output Scope
    //Element0 输出端 Element1 输入端
    OSStatus status = noErr;
    
    //开启扬声器的播放功能
//    status = AudioUnitSetProperty(
//          _ioUnit,
//          kAudioOutputUnitProperty_EnableIO,
//          kAudioUnitScope_Output,
//          outputBus,
//          &flag,
//          sizeof(flag)
//    );
//    if (status != noErr) {
//        self.setupResult = FYAudioSetupResultFailed;
//        NSLog(@"AudioUnitSetProperty io fail %d",status);
//    }
    
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
    /**
     *录制的音频作为一路音频输入到混音器，从文件读取的音频作为另一路音频输入到混音器，它们要保持相同的采样率，采样格式，声道数。这里以录制的
     *音频输出的数据格式作为混音器数据的输入格式，所以格式转换器用于转换从文件读取的音频数据
    */
    if (_enableMixWhenRecord) {
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
    }
    
    //混音
    if (self.enableMixWhenRecord) {
        _mixerStreamDesForOutput = [FYUnitTool streamDesWithLinearPCMformat:flags sampleRate:sampleRate channels:channels bytesPerChannel:bytesPerChannel];
        
        //指定混音器的音轨数量
        UInt32 mixerInputCount = _enablePlayWhenRecord ? 2 : 1;
        status = AudioUnitSetProperty(
              _mixerUnit,
              kAudioUnitProperty_ElementCount,
              kAudioUnitScope_Input,
              outputBus,
              &mixerInputCount,
              sizeof(mixerInputCount)
        );
        if (status != noErr) {
            self.setupResult = FYAudioSetupResultFailed;
            NSLog(@"AudioUnitSetProperty mixer fail %d",status);
        }
        //指定混音器的采样率
        status = AudioUnitSetProperty(
              _mixerUnit,
              kAudioUnitProperty_SampleRate,
              kAudioUnitScope_Output,
              outputBus,
              &sampleRate,
              sizeof(sampleRate)
        );
        if (status != noErr) {
            self.setupResult = FYAudioSetupResultFailed;
            NSLog(@"AudioUnitSetProperty mixer fail %d",status);
        }
        
        // 设置AudioUnitRender()函数在处理输入数据时，最大的输入吞吐量
        UInt32 maximumFramesPerSlice = 4096;
        AudioUnitSetProperty (
              _ioUnit,
              kAudioUnitProperty_MaximumFramesPerSlice,
              kAudioUnitScope_Global,
              0,
              &maximumFramesPerSlice,
              sizeof(maximumFramesPerSlice)
        );
        
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
    }
    
    if (status == noErr && self.setupResult != FYAudioSetupResultFailed) {
        self.setupResult = FYAudioSetupResultSuccess;
        NSLog(@"AudioUnitSetProperty set up success");
    }
}

- (void)connectAUGraphNode {
    AudioUnitElement outputBus = 0; //Element0 output
    AudioUnitElement inputBus = 1; //Element1 input
    OSStatus status = noErr;

    if (!_enableMixWhenRecord) {
        if (self.enablePlayWhenRecord) {
            //构建连接
            status = AUGraphConnectNodeInput(_processingGraph, _ioNode, inputBus, _ioNode, outputBus);
            if (status != noErr) {
                self.setupResult = FYAudioSetupResultFailed;
                NSLog(@"AUGraphConnectNodeInput fail %d",status);
            }
        }
        //设置麦克风音频采集回调
        AURenderCallbackStruct callBack;
        callBack.inputProc = saveOutputCallback;
        callBack.inputProcRefCon = (__bridge void*)self;
        
        //与上面的方法效果相同
        //    status = AUGraphSetNodeInputCallback(_processingGraph, _convertNode, outputBus, callBack);
        status = AudioUnitSetProperty(_ioUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Output, inputBus, &callBack, sizeof(callBack));
        if (status != noErr) {
            self.setupResult = FYAudioSetupResultFailed;
            NSLog(@"AudioUnitSetProperty fail %d",status);
        }
    }else {
        //开启混音
        status = AUGraphConnectNodeInput(_processingGraph, _mixerNode, outputBus, _ioNode, outputBus);
        if (status != noErr) {
            self.setupResult = FYAudioSetupResultFailed;
            NSLog(@"AUGraphConnectNodeInput fail %d",status);
        }
        //为混音器配置输入
        int mixerCount = _enablePlayWhenRecord ? 2 : 1;
        for (int i = 0; i < mixerCount; i++) {
            AURenderCallbackStruct callback;
            callback.inputProc = mixerInputDataCallback;
            callback.inputProcRefCon = (__bridge void*)self;
            status = AudioUnitSetProperty(_mixerUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, i, &callback, sizeof(callback));
            if (status != noErr) {
                NSLog(@"AudioUnitSetProperty kAudioUnitProperty_SetRenderCallback %d",status);
            }
            status = AudioUnitSetProperty(_mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, i, &_mixerStreamDesForInput, sizeof(_mixerStreamDesForInput));
            if (status != noErr) {
                NSLog(@"AudioUnitSetProperty kAudioUnitProperty_StreamFormat %d",status);
            }
        }
        if (_enablePlayWhenRecord) {
            //开启耳返+混音
            AudioUnitSetProperty(_ioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &_mixerStreamDesForInput, sizeof(_mixerStreamDesForInput));
        }
        
        //设置麦克风音频采集回调
        AURenderCallbackStruct callBack;
        callBack.inputProc = saveOutputCallback;
        callBack.inputProcRefCon = (__bridge void*)self;
        
        //与上面的方法效果相同
        //    status = AUGraphSetNodeInputCallback(_processingGraph, _convertNode, outputBus, callBack);
        status = AudioUnitSetProperty(_ioUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Output, inputBus, &callBack, sizeof(callBack));
        if (status != noErr) {
            self.setupResult = FYAudioSetupResultFailed;
            NSLog(@"AudioUnitSetProperty fail %d",status);
        }
    }
}


- (void)debugPrint:(AudioBufferList *)ioData
                 inTimeStamp:(const AudioTimeStamp *)inTimeStamp
               inBusNumber:(UInt32)inBusNumber
            inNumberFrames:(UInt32)inNumberFrames {
    
    NSMutableString *printStr = [NSMutableString new];
    AudioBuffer *mbuffer = ioData->mBuffers;
    UInt32 mbuffersNum = ioData->mNumberBuffers;
    [printStr appendFormat:@"begin record\n"];
    [printStr appendFormat:@"duration: %f\n", inTimeStamp->mSampleTime];
    [printStr appendFormat:@"inBusNumber: %d\n", inBusNumber];
    [printStr appendFormat:@"inNumberFrames: %d\n", inNumberFrames];
    [printStr appendFormat:@"buffer data: %p\n", mbuffer->mData];
    [printStr appendFormat:@"buffer data byteSize: %u\n", (unsigned int)mbuffer->mDataByteSize];
    [printStr appendFormat:@"buffer data channels: %u\n", (unsigned int)mbuffer->mNumberChannels];
    [printStr appendFormat:@"buffers num: %d\n", mbuffersNum];
    NSLog(@"%@", printStr);
}

+ (NSString *)saveFilePath {
    NSString *documentDir = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"FYDemo"];
    NSString *path = [documentDir stringByAppendingPathComponent:@"audiounit_record.pcm"];
    return path;
}

#pragma mark - lazy load
- (FYFileDataWritter *)audioWritter {
    if (!_audioWritter) {
        NSString *documentDir = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"FYDemo"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:documentDir]){
            NSError *error;
            [[NSFileManager defaultManager] createDirectoryAtPath:documentDir withIntermediateDirectories:NO attributes:nil error:&error];
        }
        NSString *path = [documentDir stringByAppendingPathComponent:@"audiounit_record.pcm"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]){
            [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
        }
        _audioWritter = [[FYFileDataWritter alloc] initWithPath:path];
    }
    return _audioWritter;
}


#pragma mark - 通过该回调读取数据
static OSStatus saveOutputCallback(void *inRefCon,
                                AudioUnitRenderActionFlags *ioActionFlags,
                                const AudioTimeStamp *inTimeStamp,
                                UInt32 inBusNumber,
                                UInt32 inNumberFrames,
                                AudioBufferList *ioData) {
    @autoreleasepool {
        FYAudioUnitRecorder *player = (__bridge FYAudioUnitRecorder*)inRefCon;
        AudioBufferList *bufferList = player->_bufferList;
        FYAudioChannel channels = player.audioSession.configuration.channels;
        //每个采样数据所占字节数
        NSInteger bytesPerChannel = player.audioSession.bytesPerChannel;
        
        OSStatus status = noErr;
        // 该函数的作用就是将麦克风采集的音频数据根据前面配置的RemoteIO输出数据格式渲染出来，然后放到
        // bufferList缓冲中；那么这里将是PCM格式的原始音频帧
        status = AudioUnitRender(player->_ioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, bufferList);
        if (status != noErr) {
            NSLog(@"AudioUnitRender fail %d",status);
        }
        [player debugPrint:bufferList inTimeStamp:inTimeStamp inBusNumber:inBusNumber inNumberFrames:inNumberFrames];
        
        if (bufferList->mBuffers[0].mData == NULL) {
            return noErr;
        }
        if (player.enableSaveLocal) {
            if (player.audioSession.configuration.audioFileType == FYAudioFileTypeLPCM) {
                //数据写入本地存储为PCM文件
                if (player.audioSession.configuration.audioDataType == FYAudioDataTypeNonInterleaved) {
                    // 需要重新排序一下，将音频数据存储为packet 格式
                    //单个声道需要存储的字节数
                    UInt32 totalBytePerChannel = bufferList->mBuffers[0].mDataByteSize;
                    //全部声道需要存储的字节数
                    size_t totalBytes = totalBytePerChannel * channels;
                    Byte *buf = (Byte *)malloc(totalBytes);
                    bzero(buf, totalBytes);
                    //计算单个声道中的采样数
                    NSInteger numberOfPackets = totalBytePerChannel / bytesPerChannel;
                    for (int i = 0; i < numberOfPackets; i ++) {
                        //当前进行写入的起始Buffer指针
                        Byte *currentBuffer = buf + i * channels * bytesPerChannel;
                        for (int j = 0; j < channels; j++) {
                            Byte *buffer = bufferList->mBuffers[j].mData;
                            //拷贝一个采样的数据到buf中
                            memcpy(currentBuffer + j * bytesPerChannel, buffer + i * bytesPerChannel, bytesPerChannel);
                        }
                    }
                    //写入文件
                    NSData *audioData = [[NSData alloc] initWithBytes:buf length:totalBytes];
                    [player.audioWritter writeData:audioData];
                    
                    // 释放资源
                    free(buf);
                    buf = NULL;
                    
                }else {
                    //直接写入本地文件
                    AudioBuffer buffer = bufferList->mBuffers[0];
                    
                    NSData *audioData = [[NSData alloc] initWithBytes:buffer.mData length:buffer.mDataByteSize];
                    [player.audioWritter writeData:audioData];
                }
            }
        }
        return status;
    }
}

//混音器输入数据回调
static OSStatus mixerInputDataCallback(void *inRefCon,
                        AudioUnitRenderActionFlags *ioActionFlags,
                        const AudioTimeStamp *inTimeStamp,
                        UInt32 inBusNumber,
                        UInt32 inNumberFrames,
                                       AudioBufferList *ioData) {
    
    @autoreleasepool {
        FYAudioUnitRecorder *recorder = (__bridge FYAudioUnitRecorder*)inRefCon;
        OSStatus status = noErr;
        [recorder debugPrint:ioData inTimeStamp:inTimeStamp inBusNumber:inBusNumber inNumberFrames:inNumberFrames];
        if (recorder.enablePlayWhenRecord) {
            if (inBusNumber == 0) {
                //读取录音数据
                status = AudioUnitRender(recorder->_ioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
                
            }else if (inBusNumber == 1) {
                //读取背景音乐数据
                status = [recorder->_dataReader readFrames:&inNumberFrames toBufferData:ioData];
            }
        }else {
            //背景音乐数据
            status = [recorder->_dataReader readFrames:&inNumberFrames toBufferData:ioData];
        }
        return status;
    }
}

@end
