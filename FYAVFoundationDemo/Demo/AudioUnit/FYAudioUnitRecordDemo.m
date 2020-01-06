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

@interface FYAudioUnitRecordDemo ()

@property (nonatomic, strong) FYAudioUnitRecorder *recorder;

@end

@implementation FYAudioUnitRecordDemo

- (void)viewDidLoad {
    [super viewDidLoad];
    FYAudioConfiguration *configuration = [FYAudioConfiguration defaultConfiguration];
    self.recorder = [[FYAudioUnitRecorder alloc] initWithConfiguration:configuration];
}

- (IBAction)startRecord:(UIButton *)sender {
    [self.recorder startRecord];
}

- (IBAction)stopRecord:(UIButton *)sender {
    [self.recorder stopRecord];
}

@end
