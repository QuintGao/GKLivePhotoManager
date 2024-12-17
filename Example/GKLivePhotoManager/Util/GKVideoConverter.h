//
//  GKVideoConverter.h
//  Example
//
//  Created by QuintGao on 2024/7/5.
//  Copyright © 2024 QuintGao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GKVideoConverter : NSObject

- (instancetype)initWithPath:(NSString *)path;

- (void)durationVideo:(NSString *)inputPath outputPath:(NSString *)outputPath targetDuration:(NSTimeInterval)targetDuration completion:(void(^)(BOOL, NSError *_Nullable))completion;

- (void)accelerateVideoWithPath:(NSString *)inputPath duration:(CMTime)duration outputPath:(NSString *)outputPath completion:(void(^)(BOOL, NSError *_Nullable))completion;

- (void)resizeVideoWithPath:(NSString *)inputPath outputPath:(NSString *)outputPath outputSize:(CGSize)outputSize completion:(void(^)(BOOL, NSError *_Nullable))completion;

- (void)writeToFile:(NSString *)filePath assetIdentifier:(NSString *)assetIdentifier metaURL:(NSURL *)metaURL completion:(void(^)(BOOL, NSError *_Nullable))completion;

@end

NS_ASSUME_NONNULL_END
