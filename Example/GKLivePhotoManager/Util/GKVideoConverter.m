//
//  GKVideoConverter.m
//  Example
//
//  Created by QuintGao on 2024/7/5.
//  Copyright © 2024 QuintGao. All rights reserved.
//

#import "GKVideoConverter.h"
#import <AVKit/AVKit.h>

@interface GKVideoConverter ()

@property (nonatomic, copy) NSString *path;

@property (nonatomic, strong) AVURLAsset *asset;

@end

@implementation GKVideoConverter

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        self.path = path;
    }
    return self;
}

- (void)durationVideo:(NSString *)inputPath outputPath:(NSString *)outputPath targetDuration:(NSTimeInterval)targetDuration completion:(void (^)(BOOL, NSError * _Nullable))completion {
    AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:inputPath]];
    CMTime duration = asset.duration;
    int timeScale = duration.timescale;
    
    Float64 length = CMTimeGetSeconds(duration);
    if (length <= targetDuration) {
        AVMutableComposition *composition = [AVMutableComposition composition];
        AVMutableCompositionTrack *compositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        AVAssetTrack *assetTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        compositionTrack.preferredTransform = assetTrack.preferredTransform;
        
        NSError *error = nil;
        [compositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, duration) ofTrack:assetTrack atTime:kCMTimeZero error:&error];
        if (error) {
            !completion ?: completion(NO, error);
            return;
        }
        
        __block UIImage *firstFrame = nil;
        __block UIImage *lastFrame = nil;
        
        CMTime prefixDuration = CMTimeMakeWithSeconds((targetDuration - CMTimeGetSeconds(duration) / 2), timeScale);
        CMTime suffixDuration = CMTimeMakeWithSeconds((targetDuration - CMTimeGetSeconds(duration) / 2), timeScale);
        
        [self loadImageWithAsset:asset time:CMTimeMake(0, timeScale) completion:^(UIImage *image, NSError *error) {
            if (error) {
                !completion ?: completion(NO, error);
                return;
            }
            firstFrame = image;
            if (firstFrame && lastFrame) {
                [self createVideoWithComposition:composition track:compositionTrack firstFrame:firstFrame lastFrame:lastFrame prefixDuration:prefixDuration suffixDuration:suffixDuration duration:duration outputPath:outputPath completion:completion];
            }
        }];
        
        [self loadImageWithAsset:asset time:CMTimeSubtract(duration, CMTimeMake(1, timeScale)) completion:^(UIImage *image, NSError *error) {
            if (error) {
                !completion ?: completion(NO, error);
                return;
            }
            lastFrame = image;
            if (firstFrame && lastFrame) {
                [self createVideoWithComposition:composition track:compositionTrack firstFrame:firstFrame lastFrame:lastFrame prefixDuration:prefixDuration suffixDuration:suffixDuration duration:duration outputPath:outputPath completion:completion];
            }
        }];
    }else {
        double startTime = length / 2 - targetDuration / 2;
        double endTime = length / 2 + targetDuration / 2;
        
        AVAssetExportSession *export = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetHighestQuality];
        export.outputURL = [NSURL fileURLWithPath:outputPath];
        export.outputFileType = AVFileTypeMPEG4;
        export.timeRange = CMTimeRangeFromTimeToTime(CMTimeMakeWithSeconds(startTime, timeScale), CMTimeMakeWithSeconds(endTime, timeScale));
        [export exportAsynchronouslyWithCompletionHandler:^{
            switch (export.status) {
                case AVAssetExportSessionStatusCompleted:
                    !completion ?: completion(YES, nil);
                    break;
                case AVAssetExportSessionStatusFailed:
                case AVAssetExportSessionStatusCancelled:
                    !completion ?: completion(NO, export.error);
                    break;
                default:
                    break;
            }
        }];
    }
}

- (void)accelerateVideoWithPath:(NSString *)inputPath duration:(CMTime)duration outputPath:(nonnull NSString *)outputPath completion:(nonnull void (^)(BOOL, NSError * _Nullable))completion {
    NSURL *videoURL = [NSURL fileURLWithPath:inputPath];
    AVAsset *asset = [AVAsset assetWithURL:videoURL];
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    [self loadTracksWithAsset:asset type:AVMediaTypeVideo completion:^(NSArray *tracks, NSError *error) {
        if (error) {
            !completion ?: completion(NO, error);
            return;
        }
        
        AVAssetTrack *videoTrack = tracks.firstObject;
        if (!videoTrack) {
            !completion ?: completion(NO, [NSError errorWithDomain:@"Accelerate" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Video Track is not available"}]);
            return;
        }
        
        AVMutableCompositionTrack *track = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        NSError *trackError = nil;
        [track insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:videoTrack atTime:kCMTimeZero error:&trackError];
        if (trackError) {
            !completion ?: completion(NO, trackError);
            return;
        }
        
        CMTime targetDuration = duration;
        [track scaleTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) toDuration:targetDuration];
        track.preferredTransform = videoTrack.preferredTransform;
        
        AVAssetExportSession *export = [AVAssetExportSession exportSessionWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
        export.outputURL = [NSURL fileURLWithPath:outputPath];
        export.outputFileType = AVFileTypeQuickTimeMovie;
        [export exportAsynchronouslyWithCompletionHandler:^{
            switch (export.status) {
                case AVAssetExportSessionStatusExporting:
                case AVAssetExportSessionStatusWaiting:
                    break;
                case AVAssetExportSessionStatusCompleted:
                    !completion ?: completion(YES, nil);
                    break;
                case AVAssetExportSessionStatusFailed:
                    !completion ?: completion(NO, export.error);
                    break;
                default:
                    !completion ?: completion(NO, [NSError errorWithDomain:@"VideoProcessing" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Unknown error"}]);
                    break;
            }
        }];
    }];
}

- (void)resizeVideoWithPath:(NSString *)inputPath outputPath:(NSString *)outputPath outputSize:(CGSize)outputSize completion:(void (^)(BOOL, NSError * _Nullable))completion {
    NSURL *inputURL = [NSURL fileURLWithPath:inputPath];
    NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
    
    AVAsset *asset = [AVAsset assetWithURL:inputURL];
    [self loadTracksWithAsset:asset type:AVMediaTypeVideo completion:^(NSArray *tracks, NSError *error) {
        if (error) {
            !completion ?: completion(NO, error);
            return;
        }
        AVAssetTrack *videoTrack = tracks.firstObject;
        if (!videoTrack) {
            !completion ?: completion(NO, [NSError errorWithDomain:@"Resize" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Video track is not available"}]);
            return;
        }
        int originDegree = [self degressFromVideoTrack:videoTrack];
        if (originDegree != 0) {
            NSString *tmpPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingString:@"/tmp.mp4"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:tmpPath]) {
                [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
            }
            [self cleanTransformVideo:inputPath outputPath:tmpPath completion:^(BOOL success, NSError *error) {
                [self rotateVideoWithPath:inputPath outputPath:outputPath degree:originDegree completion:completion];
            }];
            return;
        }
        
        AVAssetExportSession *export = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetHighestQuality];
        export.outputURL = outputURL;
        export.outputFileType = AVFileTypeQuickTimeMovie;
        export.shouldOptimizeForNetworkUse = YES;
        
        AVMutableVideoComposition *composition = [AVMutableVideoComposition videoComposition];
        composition.renderSize = outputSize;
        composition.frameDuration = CMTimeMake(1, 60);
        
        AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
        
        AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        CGAffineTransform preferredTransform = videoTrack.preferredTransform;
        
        CGSize originalSize = CGSizeMake(videoTrack.naturalSize.width, videoTrack.naturalSize.height);
        CGSize transformedSize = CGSizeApplyAffineTransform(originalSize, preferredTransform);
        CGSize absoluteSize = CGSizeMake(fabs(transformedSize.width), fabs(transformedSize.height));
        CGFloat widthRatio = outputSize.width / absoluteSize.width;
        CGFloat heightRatio = outputSize.height / absoluteSize.height;
        CGFloat scaleFactor = MIN(widthRatio, heightRatio);
        
        CGFloat newWidth = absoluteSize.width * scaleFactor;
        CGFloat newHeight = absoluteSize.height * scaleFactor;
        
        CGFloat translateX = (outputSize.width - newWidth) / 2;
        CGFloat translateY = (outputSize.height - newHeight) / 2;
        
        CGAffineTransform translateTransform = CGAffineTransformMakeTranslation(translateX, translateY);
        translateTransform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
        
        [layerInstruction setTransform:translateTransform atTime:kCMTimeZero];
        
        instruction.layerInstructions = @[layerInstruction];
        composition.instructions = @[instruction];
        
        export.videoComposition = composition;
        [export exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                switch (export.status) {
                    case AVAssetExportSessionStatusCompleted:
                        !completion ?: completion(YES, nil);
                        break;
                    case AVAssetExportSessionStatusFailed:
                        !completion ?: completion(NO, export.error);
                        break;
                    default:
                        break;
                }
            });
        }];
    }];
}

- (void)cleanTransformVideo:(NSString *)inputPath outputPath:(NSString *)outputPath completion:(void(^)(BOOL, NSError *))completion {
    NSURL *inputURL = [NSURL fileURLWithPath:inputPath];
    NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
    AVAsset *asset = [AVAsset assetWithURL:inputURL];
    [self loadTracksWithAsset:asset type:AVMediaTypeVideo completion:^(NSArray *tracks, NSError *error) {
        if (error) {
            !completion ?: completion(NO, error);
            return;
        }
        AVAssetTrack *videoTrack = tracks.firstObject;
        if (!videoTrack) {
            !completion ?: completion(NO, [NSError errorWithDomain:@"Clean Transform" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Video track is not available"}]);
            return;
        }
        AVMutableComposition *composition = [AVMutableComposition composition];
        AVMutableCompositionTrack *track = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        NSError *trackError = nil;
        [track insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:videoTrack atTime:kCMTimeZero error:&trackError];
        if (trackError) {
            !completion ?: completion(NO, trackError);
            return;
        }
        track.preferredTransform = CGAffineTransformIdentity;
        
        AVAssetExportSession *export = [AVAssetExportSession exportSessionWithAsset:composition presetName:AVAssetExportPresetPassthrough];
        export.outputURL = outputURL;
        export.outputFileType = AVFileTypeQuickTimeMovie;
        [export exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                switch (export.status) {
                    case AVAssetExportSessionStatusCompleted:
                        !completion ?: completion(YES, nil);
                        break;
                    case AVAssetExportSessionStatusFailed:
                        !completion ?: completion(NO, export.error);
                        break;
                    default:
                        break;
                }
            });
        }];
    }];
}

- (void)rotateVideoWithPath:(NSString *)inputPath outputPath:(NSString *)outputPath degree:(int)degree completion:(void(^)(BOOL, NSError *))completion {
    NSURL *inputURL = [NSURL fileURLWithPath:inputPath];
    NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
    
    AVAsset *asset = [AVAsset assetWithURL:inputURL];
    [self loadTracksWithAsset:asset type:AVMediaTypeVideo completion:^(NSArray *tracks, NSError *error) {
        if (error) {
            !completion ?: completion(NO, error);
            return;
        }
        AVAssetTrack *videoTrack = tracks.firstObject;
        if (!videoTrack) {
            !completion ?: completion(NO, [NSError errorWithDomain:@"Resize" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Video track is not available"}]);
            return;
        }
        AVAssetExportSession *export = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetHighestQuality];
        export.outputURL = outputURL;
        export.outputFileType = AVFileTypeQuickTimeMovie;
        export.shouldOptimizeForNetworkUse = YES;
        
        AVMutableVideoComposition *composition = [AVMutableVideoComposition videoComposition];
        composition.renderSize = abs(degree) == 90 ? CGSizeMake(videoTrack.naturalSize.height, videoTrack.naturalSize.width) : videoTrack.naturalSize;
        composition.frameDuration = CMTimeMake(1, 60);
        
        AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
        
        AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        CGAffineTransform transform;
        if (degree == 90) {
            transform = CGAffineTransformMakeTranslation(videoTrack.naturalSize.height, 0);
            transform = CGAffineTransformRotate(transform, M_PI / 2);
        }else if (degree == -90) {
            transform = CGAffineTransformMakeTranslation(0, videoTrack.naturalSize.width);
            transform = CGAffineTransformRotate(transform, -M_PI / 2);
        }else {
            transform = CGAffineTransformMakeTranslation(videoTrack.naturalSize.width, videoTrack.naturalSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
        }
        [layerInstruction setTransform:transform atTime:kCMTimeZero];
        
        instruction.layerInstructions = @[layerInstruction];
        composition.instructions = @[instruction];
        export.videoComposition = composition;
        [export exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                switch (export.status) {
                    case AVAssetExportSessionStatusCompleted:
                        !completion ?: completion(YES, nil);
                        break;
                    case AVAssetExportSessionStatusFailed:
                        !completion ?: completion(NO, export.error);
                        break;
                    default:
                        break;
                }
            });
        }];
    }];
}

- (int)degressFromVideoTrack:(AVAssetTrack *)videoTrack {
    int degress = 0;
    CGAffineTransform transform = videoTrack.preferredTransform;
    if (transform.a == 0 && transform.b == 0 && transform.c == -1 && transform.d == 0) {
        degress = 90;
    }else if (transform.a == 0 && transform.b == -1 && transform.c == 1 && transform.d == 0) {
        degress = 270;
    }else if (transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0) {
        degress = 0;
    }else if (transform.a == -1 && transform.b == 0 && transform.c == 0 && transform.d == -1) {
        degress = 180;
    }
    return degress;
}

- (void)writeToFile:(NSString *)filePath assetIdentifier:(NSString *)assetIdentifier metaURL:(NSURL *)metaURL completion:(void (^)(BOOL, NSError * _Nullable))completion {
    AVURLAsset *metadataAsset = [AVURLAsset assetWithURL:metaURL];
    
    NSError *error = nil;
    AVAssetReader *videoReader = [AVAssetReader assetReaderWithAsset:self.asset error:&error];
    if (error) {
        !completion ?: completion(NO, error);
        return;
    }
    AVAssetReader *metadataReader = [AVAssetReader assetReaderWithAsset:metadataAsset error:&error];
    if (error) {
        !completion ?: completion(NO, error);
        return;
    }
    
    AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:filePath] fileType:AVFileTypeQuickTimeMovie error:&error];
    if (error) {
        !completion ?: completion(NO, error);
        return;
    }
    
    [self loadTracksWithAsset:self.asset type:AVMediaTypeVideo completion:^(NSArray *tracks, NSError *error) {
        if (error) {
            !completion ?: completion(NO, error);
            return;
        }
        
        NSMutableArray *videoIOs = [NSMutableArray array];
        NSMutableArray *metadataIOs = [NSMutableArray array];
        
        for (AVAssetTrack *track in tracks) {
            AVAssetReaderTrackOutput *output = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]}];
            [videoReader addOutput:output];
            
            AVAssetWriterInput *input = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:@{AVVideoCodecKey: AVVideoCodecTypeH264, AVVideoWidthKey: @(track.naturalSize.width), AVVideoHeightKey: @(track.naturalSize.height)}];
            input.transform = track.preferredTransform;
            input.expectsMediaDataInRealTime = YES;
            [writer addInput:input];
            
            [videoIOs addObject:@{@"input": input, @"output": output}];
        }
        
        [self loadTracksWithAsset:metadataAsset type:AVMediaTypeMetadata completion:^(NSArray *tracks, NSError *error) {
            if (error) {
                !completion ?: completion(NO, error);
                return;
            }
            
            for (AVAssetTrack *track in tracks) {
                AVAssetReaderTrackOutput *output = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:nil];
                [metadataReader addOutput:output];
                
                AVAssetWriterInput *input = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeMetadata outputSettings:nil];
                [writer addInput:input];
                
                [metadataIOs addObject:@{@"input": input, @"output": output}];
            }
            
            writer.metadata = @[[self metadataItemWithAssetID:assetIdentifier]];
            [writer startWriting];
            [videoReader startReading];
            [metadataReader startReading];
            [writer startSessionAtSourceTime:kCMTimeZero];
            
            dispatch_group_t group = dispatch_group_create();
            for (NSDictionary *dic in videoIOs) {
                dispatch_group_enter(group);
                AVAssetReaderTrackOutput *output = dic[@"output"];
                AVAssetWriterInput *input = dic[@"input"];
                [input requestMediaDataWhenReadyOnQueue:dispatch_queue_create("assetWriterQueue.video", nil) usingBlock:^{
                    while (input.isReadyForMoreMediaData) {
                        CMSampleBufferRef bufferRef = output.copyNextSampleBuffer;
                        if (bufferRef != NULL) {
                            [input appendSampleBuffer:bufferRef];
                        }else {
                            [input markAsFinished];
                            dispatch_group_leave(group);
                            break;
                        }
                    }
                }];
            }
            for (NSDictionary *dic in metadataIOs) {
                dispatch_group_enter(group);
                AVAssetReaderTrackOutput *output = dic[@"output"];
                AVAssetWriterInput *input = dic[@"input"];
                [input requestMediaDataWhenReadyOnQueue:dispatch_queue_create("assetWriterQueue.metadata", nil) usingBlock:^{
                    while (input.isReadyForMoreMediaData) {
                        CMSampleBufferRef bufferRef = output.copyNextSampleBuffer;
                        if (bufferRef != NULL) {
                            [input appendSampleBuffer:bufferRef];
                        }else {
                            [input markAsFinished];
                            dispatch_group_leave(group);
                            break;
                        }
                    }
                }];
            }
            dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                if (videoReader.status == AVAssetReaderStatusCompleted &&
                    metadataReader.status == AVAssetReaderStatusCompleted &&
                    writer.status == AVAssetWriterStatusWriting) {
                    [writer finishWritingWithCompletionHandler:^{
                        !completion ?: completion(writer.status == AVAssetWriterStatusCompleted, writer.error);
                    }];
                }else {
                    if (videoReader.error) {
                        !completion ?: completion(NO, videoReader.error);
                    }else if (metadataReader.error) {
                        !completion ?: completion(NO, metadataReader.error);
                    }else if (writer.error) {
                        !completion ?: completion(NO, writer.error);
                    }else {
                        !completion ?: completion(NO, [NSError errorWithDomain:@"VideoProcessing" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Unknown error"}]);
                    }
                }
            });
        }];
    }];
}

- (void)appendToCompositionWithTrack:(AVMutableCompositionTrack *)track asset:(AVAsset *)asset duration:(CMTime)duration atTime:(CMTime)atTime {
    AVAssetTrack *assetTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    CMTime frameDuration = CMTimeMake(1, 30);
    CMTime currentTime = atTime;
    CMTime endTime = CMTimeAdd(currentTime, duration);
    
    while (currentTime.value < endTime.value) {
        CMTime nextTime = CMTimeAdd(currentTime, frameDuration);
        [track insertTimeRange:CMTimeRangeMake(kCMTimeZero, frameDuration) ofTrack:assetTrack atTime:currentTime error:nil];
        currentTime = nextTime;
    }
}

- (void)createVideoWithComposition:(AVMutableComposition *)composition track:(AVMutableCompositionTrack *)track firstFrame:(UIImage *)firstFrame lastFrame:(UIImage *)lastFrame prefixDuration:(CMTime)prefixDuration suffixDuration:(CMTime)suffixDuration duration:(CMTime)duration outputPath:(NSString *)outputPath completion:(void(^)(BOOL, NSError *))completion {
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    
    NSString *firstPath = [docPath stringByAppendingString:@"/first.mp4"];
    NSString *lastPath = [docPath stringByAppendingString:@"/last.mp4"];
    NSURL *firstURL = [NSURL fileURLWithPath:firstPath];
    NSURL *lastURL = [NSURL fileURLWithPath:lastPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:firstPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:firstPath error:nil];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:lastPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:lastPath error:nil];
    }
    
    int timeScale = duration.timescale;
    
    [self createVideoWithImage:firstFrame duration:CMTimeMake(1 * timeScale, timeScale) outputURL:firstURL completion:^(BOOL success) {
        [self appendToCompositionWithTrack:track asset:[AVAsset assetWithURL:firstURL] duration:prefixDuration atTime:kCMTimeZero];
        [self createVideoWithImage:lastFrame duration:CMTimeMake(1 * timeScale, timeScale) outputURL:lastURL completion:^(BOOL success) {
            [self appendToCompositionWithTrack:track asset:[AVAsset assetWithURL:lastURL] duration:suffixDuration atTime:CMTimeAdd(prefixDuration, duration)];
            
            AVAssetExportSession *export = [AVAssetExportSession exportSessionWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
            export.outputURL = [NSURL fileURLWithPath:outputPath];
            export.outputFileType = AVFileTypeMPEG4;
            [export exportAsynchronouslyWithCompletionHandler:^{
                switch (export.status) {
                    case AVAssetExportSessionStatusCompleted:
                        !completion ?: completion(YES, nil);
                        break;
                    case AVAssetExportSessionStatusFailed:
                    case AVAssetExportSessionStatusCancelled:
                        !completion ?: completion(NO, export.error);
                        break;
                    default:
                        break;
                }
            }];
        }];
    }];
}

- (void)createVideoWithImage:(UIImage *)image duration:(CMTime)duration outputURL:(NSURL *)outputURL completion:(void(^)(BOOL))completion {
    NSError *error = nil;
    AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:outputURL fileType:AVFileTypeQuickTimeMovie error:&error];
    if (error) {
        !completion ?: completion(NO);
        return;
    }
    AVAssetWriterInput *input = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:@{
        AVVideoCodecKey: AVVideoCodecTypeH264,
        AVVideoWidthKey: @(image.size.width),
        AVVideoHeightKey: @(image.size.height)
    }];
    
    AVAssetWriterInputPixelBufferAdaptor *adapter = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:input sourcePixelBufferAttributes:nil];
    
    [writer addInput:input];
    [writer startWriting];
    [writer startSessionAtSourceTime:kCMTimeZero];
    
    CVPixelBufferRef bufferRef = [self pixelBufferFrom:image];
    __block int frameCount = 0;
    CMTime frameDuration = CMTimeMake(1, 30);
    __block CMTime presentTime = kCMTimeZero;
    
    [input requestMediaDataWhenReadyOnQueue:dispatch_queue_create("mediaInputQueue", nil) usingBlock:^{
        while (frameCount < CMTimeGetSeconds(duration) * 30) {
            if (input.isReadyForMoreMediaData) {
                [adapter appendPixelBuffer:bufferRef withPresentationTime:presentTime];
            }
            presentTime = CMTimeAdd(presentTime, frameDuration);
            frameCount += 1;
        }
        [input markAsFinished];
        [writer finishWritingWithCompletionHandler:^{
            switch (writer.status) {
                case AVAssetWriterStatusCompleted:
                    !completion ?: completion(YES);
                    break;
                default:
                    !completion ?: completion(NO);
                    break;
            }
        }];
    }];
}

- (CVPixelBufferRef)pixelBufferFrom:(UIImage *)image {
    NSDictionary *attrs = @{(id)kCVPixelBufferCGImageCompatibilityKey: (id)kCFBooleanTrue,
                            (id)kCVPixelBufferCGBitmapContextCompatibilityKey: (id)kCFBooleanTrue};
    CVPixelBufferRef bufferRef;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, image.size.width, image.size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef _Nullable)(attrs), &bufferRef);
    if (status != kCVReturnSuccess) {
        return nil;
    }
    CVPixelBufferLockBaseAddress(bufferRef, 0);
    void *pixelData = CVPixelBufferGetBaseAddress(bufferRef);
    CGColorSpaceRef rgbColorRef = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixelData, image.size.width, image.size.height, 8, CVPixelBufferGetBytesPerRow(bufferRef), rgbColorRef, kCGImageAlphaNoneSkipFirst);
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    UIGraphicsPushContext(context);
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    UIGraphicsPopContext();
    CVPixelBufferUnlockBaseAddress(bufferRef, 0);
    return bufferRef;
}

- (void)loadTracksWithAsset:(AVAsset *)asset type:(AVMediaType)type completion:(void(^)(NSArray * _Nullable, NSError * _Nullable))completion {
    if (@available(iOS 15.0, *)) {
        [asset loadTracksWithMediaType:type completionHandler:^(NSArray<AVAssetTrack *> *tracks, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(tracks, error);
            });
        }];
    }else {
        NSArray *tracks = [asset tracksWithMediaType:type];
        !completion ?: completion(tracks, nil);
    }
}

- (void)loadImageWithAsset:(AVAsset *)asset time:(CMTime)time completion:(void(^)(UIImage *_Nullable, NSError *_Nullable))completion {
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    generator.requestedTimeToleranceBefore = kCMTimeZero;
    generator.requestedTimeToleranceAfter = kCMTimeZero;
    
    if (@available(iOS 16.0, *)) {
        [generator generateCGImageAsynchronouslyForTime:time completionHandler:^(CGImageRef  _Nullable image, CMTime actualTime, NSError * _Nullable error) {
            if (image) {
                !completion ?: completion([UIImage imageWithCGImage:image], nil);
            }else {
                !completion ?: completion(nil, error);
            }
        }];
    } else {
        NSError *error = nil;
        CGImageRef image = [generator copyCGImageAtTime:time actualTime:nil error:&error];
        if (image) {
            !completion ?: completion([UIImage imageWithCGImage:image], nil);
        }else {
            !completion ?: completion(nil, error);
        }
    }
}

- (AVMetadataItem *)metadataItemWithAssetID:(NSString *)assetIdentifier {
    AVMutableMetadataItem *item = [[AVMutableMetadataItem alloc] init];
    item.key = @"com.apple.quicktime.content.identifier";
    item.keySpace = @"mdta";
    item.value = assetIdentifier;
    item.dataType = @"com.apple.metadata.datatype.UTF-8";
    return item;
}

#pragma mark - lazy
- (AVURLAsset *)asset {
    if (!_asset) {
        _asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:self.path]];
    }
    return _asset;
}

@end
