//
//  FYAudioUnitRecordDemo.m
//  FYAVFoundationDemo
//
//  Created by admin on 2020/1/5.
//  Copyright © 2020 fengyangcao. All rights reserved.
//

#import "FYAudioUnitRecordDemo.h"
#import "FYAudioUnitRecorder.h"
#import "FYAudioConfiguration.h"
#import <QMUIKit/QMUIKit.h>
#import <ReactiveObjC/ReactiveObjC.h>
#import "FYAudioUnitPlay.h"

@interface FYAudioUnitRecordDemo ()

@property (nonatomic, strong) FYAudioUnitRecorder *recorder;
@property (nonatomic, strong) FYAudioUnitPlay *player;

@property (weak, nonatomic) IBOutlet UIButton *startRecordButton;
@property (weak, nonatomic) IBOutlet UIButton *stopRecordButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@property (weak, nonatomic) IBOutlet UISwitch *earReturnSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *bgSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *saveLocalSwitch;

@end

@implementation FYAudioUnitRecordDemo

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *filePath = [FYAudioUnitRecorder saveFilePath];
    
    FYAudioConfiguration *configuration = [[FYAudioConfiguration alloc] initWithSampleRate:FYAudioSampleRate_Default
                                          channels:FYAudioChannelDouble
                                          dataType:FYAudioDataTypePacket
                                          fileType:FYAudioFileTypeLPCM
                                        formatType:FYAudioFormatType16Int
                                      bufferLength:FYSAudioSessionDelay_Default];

    self.player = [[FYAudioUnitPlay alloc] initWithFileURL:[NSURL fileURLWithPath:filePath] configure:configuration];
    
    @weakify(self);
    RACSignal *recordSig = [RACObserve(self, recorder.isRecording) map:^id _Nullable(id  _Nullable value) {
        return @([value boolValue]);
    }];
    
    RACSignal *playSig = [RACObserve(self, player.isPlaying) map:^id _Nullable(id  _Nullable value) {
        return @([value boolValue]);
    }];
    
    [[[RACSignal combineLatest:@[recordSig, playSig]] deliverOnMainThread] subscribeNext:^(RACTuple * _Nullable x) {
        @strongify(self);
        BOOL isRecording = [x.first boolValue];
        BOOL isPlaying = [x.second boolValue];
        
        self.startRecordButton.enabled = !isRecording && !isPlaying;
        self.stopRecordButton.enabled = isRecording && !isPlaying;
        
        self.playButton.selected = isPlaying;
        self.playButton.enabled = !isRecording;
        
        self.earReturnSwitch.enabled = !isRecording;
        self.bgSwitch.enabled = !isRecording;
        self.saveLocalSwitch.enabled = !isRecording;
    }];
    
    
}

- (IBAction)startRecord:(UIButton *)sender {
    FYAudioConfiguration *configuration = [[FYAudioConfiguration alloc] initWithSampleRate:FYAudioSampleRate_Default channels:FYAudioChannelDouble dataType:FYAudioDataTypeNonInterleaved fileType:FYAudioFileTypeLPCM formatType:FYAudioFormatType16Int bufferLength:FYSAudioSessionDelay_Default];
    
    bool enablePlayWhenRecord = self.earReturnSwitch.isOn;
    bool enableMixWhenRecord = self.bgSwitch.isOn;
    bool enableSaveLocal = self.saveLocalSwitch.isOn;
    FYAudioUnitRecordOption options = { enablePlayWhenRecord, enableMixWhenRecord, enableSaveLocal };
    
    NSString *bgFilePath = nil;
    if (enableMixWhenRecord) {
        bgFilePath = [[NSBundle mainBundle] pathForResource:@"background" ofType:@"mp3"];
    }
    
    self.recorder = [[FYAudioUnitRecorder alloc] initWithConfiguration:configuration mixMusicFilePath:bgFilePath recordOption:options];
    
    RAC(self.recorder, enableSaveLocal) = RACObserve(self.saveLocalSwitch, isOn);
    RAC(self.recorder, enableMixWhenRecord) = RACObserve(self.bgSwitch, isOn);
    RAC(self.recorder, enablePlayWhenRecord) = RACObserve(self.earReturnSwitch, isOn);
    [self.recorder startRecord];
}

- (IBAction)stopRecord:(UIButton *)sender {
    [self.recorder stopRecord];
    self.recorder = nil;
}

- (IBAction)playButtonClick:(UIButton *)sender {
    if (self.player.isPlaying) {
        [self.player stop];
    }else {
        [self.player play];
    }
}

@end
