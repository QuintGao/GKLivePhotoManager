#import <Example-Swift.h>
#import "LivePhotoUtil.h"
#import <Photos/Photos.h>
#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "GKVideoConverter.h"
#import "GKImageConverter.h"

@implementation LivePhotoUtil

+ (void)convertVideo:(NSString*)path complete:(void(^)(BOOL, NSString*))complete;{
    NSLog(@"start converting");
    
    NSURL *metaURL = [NSBundle.mainBundle URLForResource:@"metadata" withExtension:@"mov"];
    CGSize livePhotoSize = CGSizeMake(1080, 1920);
    CMTime livePhotoDuration = CMTimeMake(550, 600);
    NSString *assetIdentifier = NSUUID.UUID.UUIDString;
    
    NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *durationPath = [documentPath stringByAppendingString:@"/duration.mp4"];
    NSString *acceleratePath = [documentPath stringByAppendingString:@"/accelerate.mp4"];
    NSString *resizePath = [documentPath stringByAppendingString:@"/resize.mp4"];
    [NSFileManager.defaultManager removeItemAtPath:durationPath error:nil];
    [NSFileManager.defaultManager removeItemAtPath:acceleratePath error:nil];
    [NSFileManager.defaultManager removeItemAtPath:resizePath error:nil];
    NSString *finalPath = resizePath;
//
//    NSString *path1 = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp4"];
//    NSData *data = [NSData dataWithContentsOfFile:path1];
//    
//    NSString *toPath = [documentPath stringByAppendingString:@"/test.mp4"];
//    [data writeToFile:toPath atomically:YES];
//    
//    GKVideoConverter *conver = [[GKVideoConverter alloc] initWithPath:path];
//    
//    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
//    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
//    generator.appliesPreferredTrackTransform = YES;
//    generator.requestedTimeToleranceAfter = kCMTimeZero;
//    generator.requestedTimeToleranceBefore = kCMTimeZero;
//    
//    NSMutableArray *times = @[].mutableCopy;
//    CMTime time = CMTimeMakeWithSeconds(0.5, asset.duration.timescale);
//    [times addObject:[NSValue valueWithCMTime:time]];
//    
//    dispatch_queue_t q = dispatch_queue_create("image", DISPATCH_QUEUE_SERIAL);
//    __block int index = 0;
//    [generator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
//        if (image) {
//            NSString *picturePath = [documentPath stringByAppendingFormat:@"/%@%d.heic", @"live", index, nil];
//            NSString *videoPath = [documentPath stringByAppendingFormat:@"/%@%d.mov", @"live", index, nil];
//            index += 1;
//            [[NSFileManager defaultManager] removeItemAtPath:picturePath error:nil];
//            [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
//            
//            GKImageConverter *imageConverter = [[GKImageConverter alloc] initWithImage:[UIImage imageWithCGImage:image]];
//            dispatch_async(q, ^{
//                [imageConverter writeToFile:picturePath identifier:assetIdentifier];
//                
//                [conver writeToFile:videoPath assetIdentifier:assetIdentifier metaURL:metaURL completion:^(BOOL success, NSError *error) {
//                    if (!success) {
//                        complete(NO, error.localizedDescription);
//                        return;
//                    }
//                    [PHPhotoLibrary.sharedPhotoLibrary performChanges:^{
//                        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
//                        NSURL *photoURL = [NSURL fileURLWithPath:picturePath];
//                        NSURL *pairedVideoURL = [NSURL fileURLWithPath:videoPath];
//                        [request addResourceWithType:PHAssetResourceTypePhoto fileURL:photoURL options:[PHAssetResourceCreationOptions new]];
//                        [request addResourceWithType:PHAssetResourceTypePairedVideo fileURL:pairedVideoURL options:[PHAssetResourceCreationOptions new]];
//                    } completionHandler:^(BOOL success, NSError * _Nullable error) {
//                        dispatch_async(dispatch_get_main_queue(), ^{
//                            !complete ?: complete(error==nil, error.localizedDescription);
//                        });
//                    }];
//                }];
//            });
//        }
//    }];
//    
//    
//    return;
    GKVideoConverter *converter = [[GKVideoConverter alloc] initWithPath:finalPath];
    [converter durationVideo:path outputPath:durationPath targetDuration:3 completion:^(BOOL success, NSError *error) {
        if (!success) {
            !complete ?: complete(NO, error.localizedDescription);
            return;
        }
        [converter accelerateVideoWithPath:durationPath duration:livePhotoDuration outputPath:acceleratePath completion:^(BOOL success, NSError *error) {
            if (!success) {
                !complete ?: complete(NO, error.localizedDescription);
                return;
            }
            [converter resizeVideoWithPath:acceleratePath outputPath:resizePath outputSize:livePhotoSize completion:^(BOOL success, NSError *error) {
                if (!success) {
                    !complete ?: complete(NO, error.localizedDescription);
                    return;
                }
                AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:finalPath] options:nil];
                AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
                generator.appliesPreferredTrackTransform = YES;
                generator.requestedTimeToleranceAfter = kCMTimeZero;
                generator.requestedTimeToleranceBefore = kCMTimeZero;
                
                NSMutableArray *times = @[].mutableCopy;
                CMTime time = CMTimeMakeWithSeconds(0.5, asset.duration.timescale);
                [times addObject:[NSValue valueWithCMTime:time]];
                
                dispatch_queue_t q = dispatch_queue_create("image", DISPATCH_QUEUE_SERIAL);
                __block int index = 0;
                [generator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
                    if (image) {
                        NSString *picturePath = [documentPath stringByAppendingFormat:@"/%@%d.heic", @"live", index, nil];
                        NSString *videoPath = [documentPath stringByAppendingFormat:@"/%@%d.mov", @"live", index, nil];
                        index += 1;
                        [[NSFileManager defaultManager] removeItemAtPath:picturePath error:nil];
                        [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
                        
                        GKImageConverter *imageConverter = [[GKImageConverter alloc] initWithImage:[UIImage imageWithCGImage:image]];
                        dispatch_async(q, ^{
                            [imageConverter writeToFile:picturePath identifier:assetIdentifier];
                            
                            [converter writeToFile:videoPath assetIdentifier:assetIdentifier metaURL:metaURL completion:^(BOOL success, NSError *error) {
                                if (!success) {
                                    complete(NO, error.localizedDescription);
                                    return;
                                }
                                [PHPhotoLibrary.sharedPhotoLibrary performChanges:^{
                                    PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
                                    NSURL *photoURL = [NSURL fileURLWithPath:picturePath];
                                    NSURL *pairedVideoURL = [NSURL fileURLWithPath:videoPath];
                                    [request addResourceWithType:PHAssetResourceTypePhoto fileURL:photoURL options:[PHAssetResourceCreationOptions new]];
                                    [request addResourceWithType:PHAssetResourceTypePairedVideo fileURL:pairedVideoURL options:[PHAssetResourceCreationOptions new]];
                                } completionHandler:^(BOOL success, NSError * _Nullable error) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        !complete ?: complete(error==nil, error.localizedDescription);
                                    });
                                }];
                            }];
                        });
                    }
                }];
            }];
        }];
    }];
    
    
//    Converter4Video *converter = [[Converter4Video alloc] initWithPath:finalPath];
//    
//    [converter durationVideoAt:path outputPath:durationPath targetDuration:3 completion:^(BOOL success, NSError * error) {
//        
//        [converter accelerateVideoAt:durationPath to:livePhotoDuration outputPath:acceleratePath completion:^(BOOL success, NSError * error) {
//            
//            [converter resizeVideoAt:acceleratePath outputPath:resizePath outputSize:livePhotoSize completion:^(BOOL success, NSError * error) {
//                
//                AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:finalPath] options:nil];
//                AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
//                generator.appliesPreferredTrackTransform = YES;
//                generator.requestedTimeToleranceAfter = kCMTimeZero;
//                generator.requestedTimeToleranceBefore = kCMTimeZero;
//                NSMutableArray *times = @[].mutableCopy;
//                //        for (int i=0; i<10; i++) {
//                //            if (i!=5) {
//                //                continue;
//                //            }
//                CMTime time = CMTimeMakeWithSeconds(0.5, asset.duration.timescale);
//                [times addObject:[NSValue valueWithCMTime:time]];
//                //        }
//                dispatch_queue_t q = dispatch_queue_create("image", DISPATCH_QUEUE_SERIAL);
//                __block int index = 0;
//                [generator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
//                    if (image)
//                    {
//                        NSString *picturePath = [documentPath stringByAppendingFormat:@"/%@%d.heic", @"live", index, nil];
//                        NSString *videoPath = [documentPath stringByAppendingFormat:@"/%@%d.mov", @"live", index, nil];
//                        index += 1;
//                        [NSFileManager.defaultManager removeItemAtPath:picturePath error:nil];
//                        [NSFileManager.defaultManager removeItemAtPath:videoPath error:nil];
//                        
//                        Converter4Image *converter4Image = [[Converter4Image alloc] initWithImage:[UIImage imageWithCGImage:image]];
//                        dispatch_async(q, ^{
//                            [converter4Image writeWithDest:picturePath assetIdentifier:assetIdentifier];
//                            
//                            [converter writeWithDest:videoPath assetIdentifier:assetIdentifier metaURL:metaURL completion:^(BOOL success, NSError * error) {
//                                if (!success) {
//                                    NSLog(@"merge failed: %@", error);
//                                    complete(NO, error.localizedDescription);
//                                    return;
//                                }
//                                [PHPhotoLibrary.sharedPhotoLibrary performChanges:^{
//                                    PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
//                                    NSURL *photoURL = [NSURL fileURLWithPath:picturePath];
//                                    NSURL *pairedVideoURL = [NSURL fileURLWithPath:videoPath];
//                                    [request addResourceWithType:PHAssetResourceTypePhoto fileURL:photoURL options:[PHAssetResourceCreationOptions new]];
//                                    [request addResourceWithType:PHAssetResourceTypePairedVideo fileURL:pairedVideoURL options:[PHAssetResourceCreationOptions new]];
//                                } completionHandler:^(BOOL success, NSError * _Nullable error) {
//                                    dispatch_async(dispatch_get_main_queue(), ^{
//                                        complete(error==nil, error.localizedDescription);
//                                    });
//                                }];
//                            }];
//                        });
//                    }
//                }];
//                
//            }];
//            
//        }];
//        
//    }];
}

@end
