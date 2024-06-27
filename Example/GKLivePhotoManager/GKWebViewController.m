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

@property (nonatomic, copy) NSString *videoPath;
@property (nonatomic, copy) NSString *imagePath;

@end

@implementation GKWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"网络资源";
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSURL *videoUrl = [NSURL URLWithString:@"https://video.weibo.com/media/play?livephoto=https%3A%2F%2Fus.sinaimg.cn%2F000YYEgOgx08fAjKa77G0f0f0100fQhZ0k01.mov"];
    NSURL *imageUrl = [NSURL URLWithString:@"https://wx1.sinaimg.cn/mw690/87b3c920gy1hqm73s9siyj22c0340u0x.jpg"];
    
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
    [[manager downloadTaskWithRequest:[NSURLRequest requestWithURL:videoUrl] progress:nil destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:videoPath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        self.videoPath = filePath.path;
        if (self.videoPath && self.imagePath) {
            [self reqeustLivePhoto];
        }
    }] resume];
    
    [[manager downloadTaskWithRequest:[NSURLRequest requestWithURL:imageUrl] progress:nil destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:imagePath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        self.imagePath = filePath.path;
        if (self.videoPath && self.imagePath) {
            [self reqeustLivePhoto];
        }
    }] resume];
}

- (void)reqeustLivePhoto {
    __weak __typeof(self) weakSelf = self;
    [GKMessageTool showMessage:@"处理livePhoto"];
    [[GKLivePhotoManager manager] handleDataWithVideoPath:self.videoPath imagePath:self.imagePath completion:^(NSString * _Nullable outVideoPath, NSString * _Nullable outImagePath, NSError * _Nullable error) {
        if (error) {
            [GKMessageTool showError:error.localizedDescription];
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
