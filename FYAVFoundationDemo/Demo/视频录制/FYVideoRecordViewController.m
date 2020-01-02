//
//  FYVideoRecordViewController.m
//  FYAVFoundationDemo
//
//  Created by admin on 2019/12/5.
//  Copyright © 2019 fengyangcao. All rights reserved.
//

#import "FYVideoRecordViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AVCaptureDevice+FYAVCaptureTools.h"
#import <VideoToolbox/VideoToolbox.h>
#import <AudioToolbox/AudioToolbox.h>

#import "FYAVCapturePreview.h"
#import <ReactiveObjC/ReactiveObjC.h>
#import "FYConstant.h"

@interface FYVideoRecordViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    dispatch_queue_t videoCaptureQueue; //视频采集queue
}
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDevice *videoCaptureDevice;
@property (nonatomic, strong) AVCaptureVideoDataOutput *output;
@property (nonatomic, strong, nullable) FYAVCapturePreview *preview;
@property (nonatomic, assign) FYAudioSetupResult setupResult;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *effectView;

@end

@implementation FYVideoRecordViewController

- (void)dealloc {
    NSLog(@"%@ delloc", [self class]);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _preview.frame = self.view.bounds;
}

//- (void)viewWillAppear:(BOOL)animated {
//    [super viewWillAppear:animated];
//    if (self.session.isRunning == NO) {
//        [self.session startRunning];
//    }
//}
//
//- (void)viewDidAppear:(BOOL)animated {
//    [super viewDidAppear:animated];
//    if (self.session.isRunning) {
//        [self.session stopRunning];
//
//    }
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    videoCaptureQueue = dispatch_queue_create("com.fy.videocapture.queue", NULL);

    //Session
    self.session = [[AVCaptureSession alloc] init];
    self.preview = [[FYAVCapturePreview alloc] init];
    self.preview.session = self.session;
    [self.view insertSubview:self.preview atIndex:0];
    
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized:
            self.setupResult = FYAudioSetupResultSuccess;
            
            break;
        default:
            //未授权
            self.setupResult = FYAudioSetupResultNotAuthorized;
            break;
    }
    
    //输入设备
//    NSArray<AVCaptureDeviceType>* deviceTypes = @[AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInDualCamera, AVCaptureDeviceTypeBuiltInTrueDepthCamera];
//
//    self.videoDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes mediaType:<#(nullable AVMediaType)#> position:<#(AVCaptureDevicePosition)#>]
//
    self.videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:_videoCaptureDevice error:&error];
    
    //输出
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [output setSampleBufferDelegate:self queue:videoCaptureQueue];
    [output setAlwaysDiscardsLateVideoFrames:NO];
    
    //添加输入、输出到Session
    if ([_session canAddInput:input]) {
        [_session addInput:input];
    }
    if ([_session canAddOutput:output]) {
        [_session addOutput:output];
    }
    
    AVCaptureConnection *connection = [output connectionWithMediaType:AVMediaTypeVideo];
    if (connection.isVideoOrientationSupported) {
        connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    } else {
        NSLog(@"不支持设置方向");
    }
   
    //初始化编码器
//    [self initVideoToolBox];
}

#pragma mark - private metho

//typedef void (*VTCompressionOutputCallback)(
//void * CM_NULLABLE outputCallbackRefCon,
//void * CM_NULLABLE sourceFrameRefCon,
//OSStatus status,
//VTEncodeInfoFlags infoFlags,
//CM_NULLABLE CMSampleBufferRef sampleBuffer );
///编码完成回调
//void didCompressH264(void * outputCallbackRefCon, void * sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer) {
//
//}

#pragma mark - event response
- (IBAction)captureButtonClick:(UIButton *)sender {
    if (_session.isRunning) {
        dispatch_async(videoCaptureQueue, ^{

            [self.session stopRunning];
        });
        sender.selected = NO;
    }else {
        dispatch_async(videoCaptureQueue, ^{
            [self.session startRunning];
        });
        sender.selected = YES;
    }
}

- (IBAction)flashButtonClick:(UIButton *)sender {
}

- (IBAction)cameraPositionClick:(UIButton *)sender {
}

- (IBAction)openMicPermission:(UIButton *)sender {
    
}

- (IBAction)openCameraPermission:(UIButton *)sender {
    
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    NSLog(@"开始采集数据");
    //使用VideoToolBox进行硬解码
//    dispatch_sync(videoEncodeQueue, ^{
//        [self encode:sampleBuffer];
//    });
}

@end
