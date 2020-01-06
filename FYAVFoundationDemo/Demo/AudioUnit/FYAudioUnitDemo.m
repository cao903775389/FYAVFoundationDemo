//
//  FYAudioUnitDemo.m
//  FYAVFoundationDemo
//
//  Created by admin on 2019/12/31.
//  Copyright © 2019 fengyangcao. All rights reserved.
//

#import "FYAudioUnitDemo.h"
#import <AVFoundation/AVFoundation.h>
#import "FYAudioUnitPlay.h"

@interface FYAudioUnitDemo ()

@property (nonatomic, strong) FYAudioUnitPlay *player;

@end

@implementation FYAudioUnitDemo

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"test_441_f32le_2" ofType:@"pcm"];
    self.player = [[FYAudioUnitPlay alloc] initWithFileURL:[NSURL fileURLWithPath:filePath] fileType:FYAudioFileTypeLPCM];
}

- (IBAction)playePcmFile:(id)sender {
    [self.player play];
}
- (IBAction)pausButtonClick:(UIButton *)sender {
    [self.player stop];
}

@end
