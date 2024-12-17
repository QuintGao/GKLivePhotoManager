//
//  GKImageConverter.m
//  Example
//
//  Created by QuintGao on 2024/7/5.
//  Copyright © 2024 QuintGao. All rights reserved.
//

#import "GKImageConverter.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <MobileCoreServices/MobileCoreServices.h>

static NSString *const kFigAppleMakerNote_AssetIdentifier = @"17";

@interface GKImageConverter()

@property (nonatomic, strong) UIImage *image;

@end

@implementation GKImageConverter

- (instancetype)initWithImage:(UIImage *)image {
    if (self = [super init]) {
        self.image = image;
    }
    return self;
}

- (void)writeToFile:(NSString *)filePath identifier:(NSString *)identifier {
    CFURLRef destURL = (__bridge CFURLRef)[NSURL fileURLWithPath:filePath];
    CFStringRef type;
    if (@available(iOS 14.0, *)) {
        CFArrayRef supportedTypes = CGImageDestinationCopyTypeIdentifiers();
        if (CFArrayContainsValue(supportedTypes, CFRangeMake(0, CFArrayGetCount(supportedTypes)), (__bridge const void *)(UTTypeHEIC.identifier))) {
            type = (__bridge CFStringRef)UTTypeHEIC.identifier;
        }else {
            type = (__bridge CFStringRef)UTTypeJPEG.identifier;
        }
    }else {
        type = kUTTypeJPEG;
    }
    
    CGImageDestinationRef dest = CGImageDestinationCreateWithURL(destURL, (CFStringRef)type, 1, nil);
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)[self data], nil);
    NSMutableDictionary *metadata = [(__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) mutableCopy];
    NSMutableDictionary *makerNote = [NSMutableDictionary dictionary];
    [makerNote setValue:identifier forKey:kFigAppleMakerNote_AssetIdentifier];
    [metadata setObject:makerNote forKey:(__bridge_transfer NSString *)kCGImagePropertyMakerAppleDictionary];
    CGImageDestinationAddImageFromSource(dest, imageSource, 0, (CFDictionaryRef)metadata);
    CGImageDestinationFinalize(dest);
    CFRelease(dest);
}

- (NSData *)data {
    if (@available(iOS 17.0, *)) {
        return UIImageHEICRepresentation(self.image);
    }else {
        return UIImagePNGRepresentation(self.image);
    }
}

@end
