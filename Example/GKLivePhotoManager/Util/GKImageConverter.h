//
//  GKImageConverter.h
//  Example
//
//  Created by QuintGao on 2024/7/5.
//  Copyright © 2024 QuintGao. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GKImageConverter : NSObject

- (instancetype)initWithImage:(UIImage *)image;

- (void)writeToFile:(NSString *)filePath identifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
