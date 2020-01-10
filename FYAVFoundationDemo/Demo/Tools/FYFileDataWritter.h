//
//  FYFileDataWritter.h
//  FYAVFoundationDemo
//
//  Created by admin on 2020/1/8.
//  Copyright © 2020 fengyangcao. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FYFileDataWritter : NSObject

@property (nonatomic, copy, nullable, readonly) NSString *savePath;

- (instancetype)initWithPath:(NSString*)path;

- (void)deleteFile;
- (void)writeData:(NSData*)data;
- (void)finishWriting;

@end

NS_ASSUME_NONNULL_END
