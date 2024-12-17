//
//  GKWebViewController.m
//  GKLivePhotoManager
//
//  Created by QuintGao on 2024/6/24.
//

#import "GKWebViewController.h"
#import <AFNetworking/AFNetworking.h>
#import "GKLivePhotoManager.h"
#import <GKMessageTool/GKMessageTool.h>

@interface GKWebViewController ()

@property (nonatomic, copy) NSString *outVideoPath;
@property (nonatomic, copy) NSString *outImagePath;

@end

@implementation GKWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"网络资源";
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSURL *videoUrl = [NSURL URLWithString:self.videoPath];
    NSURL *imageUrl = nil;
    if (self.imagePath.length) {
        imageUrl = [NSURL URLWithString:self.imagePath];
    }
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString *videoPath = [path stringByAppendingPathComponent:@"web.mov"];
    NSString *imagePath = [path stringByAppendingPathComponent:@"web.jpg"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:videoPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
    }
    
    [GKMessageTool showMessage:@"资源下载中..."];
    if (videoUrl && imageUrl) {
        [[manager downloadTaskWithRequest:[NSURLRequest requestWithURL:videoUrl] progress:nil destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [NSURL fileURLWithPath:videoPath];
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            self.outVideoPath = filePath.path;
            if (self.outVideoPath && self.outImagePath) {
                [self reqeustLivePhoto];
            }
        }] resume];
        
        [[manager downloadTaskWithRequest:[NSURLRequest requestWithURL:imageUrl] progress:nil destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [NSURL fileURLWithPath:imagePath];
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            self.outImagePath = filePath.path;
            if (self.outVideoPath && self.outImagePath) {
                [self reqeustLivePhoto];
            }
        }] resume];
    }else {
        [[manager downloadTaskWithRequest:[NSURLRequest requestWithURL:videoUrl] progress:nil destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [NSURL fileURLWithPath:videoPath];
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            self.outVideoPath = filePath.path;
            if (self.outVideoPath) {
                [self reqeustLivePhoto];
            }
        }] resume];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    if ([manager fileExistsAtPath:self.outVideoPath]) {
        [manager removeItemAtPath:self.outVideoPath error:nil];
    }
    
    if ([manager fileExistsAtPath:self.outImagePath]) {
        [manager removeItemAtPath:self.outImagePath error:nil];
    }
}

- (void)reqeustLivePhoto {
    __weak __typeof(self) weakSelf = self;
    [GKMessageTool showMessage:@"处理livePhoto"];
    
    [[GKLivePhotoManager manager] handleDataWithVideoPath:self.outVideoPath imagePath:self.outImagePath progressBlock:^(float progress) {
        NSLog(@"处理进度---%f", progress);
    } completion:^(NSString * _Nullable outVideoPath, NSString * _Nullable outImagePath, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [GKMessageTool showError:error.localizedDescription];
            });
        }else {
            [[GKLivePhotoManager manager] createLivePhotoWithVideoPath:outVideoPath imagePath:outImagePath targetSize:CGSizeMake(300, 300) completion:^(PHLivePhoto * _Nullable livePhoto, NSError * _Nullable error) {
                [GKMessageTool hideMessage];
                if (error) {
                    [GKMessageTool showError:error.localizedDescription];
                }else {
                    [weakSelf setLivePhoto:livePhoto];
                }
            }];
        }
    }];
}

@end
