//
//  FYFileDataWritter.m
//  FYAVFoundationDemo
//
//  Created by admin on 2020/1/8.
//  Copyright © 2020 fengyangcao. All rights reserved.
//

#import "FYFileDataWritter.h"

@interface FYFileDataWritter () {
    NSFileHandle * _fileHandle;
}

@property (nonatomic, copy, nullable) NSString *savePath;

@end

@implementation FYFileDataWritter

- (void)dealloc {
    [_fileHandle closeFile];
}

- (id)initWithPath:(NSString*)path {
    if (self = [super init]) {
        self.savePath = path;
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
    }
    return self;
}

- (void)deleteFile {
    if (self.savePath.length == 0) {
        return;
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.savePath]){
        [[NSFileManager defaultManager] removeItemAtPath:self.savePath error:nil];
    }
}

- (void)finishWriting {
    [_fileHandle closeFile];
}

- (void)writeData:(NSData*)data {
    if (self.savePath.length == 0) {
        return;
    }
    BOOL canWrite = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.savePath]) {
        canWrite = [[NSFileManager defaultManager] createFileAtPath:self.savePath contents:nil attributes:nil];
    }
    
    if (canWrite) {
        NSFileHandle * handle = [NSFileHandle fileHandleForWritingAtPath:self.savePath];
        [handle seekToEndOfFile];
        [handle writeData:data];
        NSLog(@"write data size: %lu", (unsigned long)data.length);
    }
}

@end
