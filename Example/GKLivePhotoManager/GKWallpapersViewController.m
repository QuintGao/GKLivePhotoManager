//
//  GKWallpapersViewController.m
//  Example
//
//  Created by QuintGao on 2024/9/19.
//  Copyright © 2024 QuintGao. All rights reserved.
//

#import "GKWallpapersViewController.h"
#import <AVKit/AVKit.h>
#import <AFNetworking/AFNetworking.h>
#import "GKLivePhotoManager.h"
#import <GKMessageTool/GKMessageTool.h>
#import "LivePhotoUtil.h"

@interface GKWallpapersViewController ()

@property (nonatomic, strong) NSURL *url;

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (nonatomic, strong) UIView *playView;

@end

@implementation GKWallpapersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"保存为墙纸";
    
    NSURL *url = [NSURL URLWithString:self.videoPath];
    self.url = url;
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
    
    self.player = [AVPlayer playerWithPlayerItem:item];
    
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    self.playView = [[UIView alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.width * 9 / 16)];
    [self.view addSubview:self.playView];
    
    self.playerLayer.frame = self.playView.bounds;
    [self.playView.layer addSublayer:self.playerLayer];
    
    [self.player play];
    
    UIButton *saveBtn = [[UIButton alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 180)/2, CGRectGetMaxY(_playView.frame) + 20, 180, 30)];
    [saveBtn setTitle:@"生成livePhoto并保存" forState:UIControlStateNormal];
    [saveBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    saveBtn.backgroundColor = UIColor.blackColor;
    saveBtn.layer.cornerRadius = 5;
    saveBtn.layer.masksToBounds = YES;
    [self.view addSubview:saveBtn];
    [saveBtn addTarget:self action:@selector(saveAction) forControlEvents:UIControlEventTouchUpInside];
}

- (void)saveAction {
    // 下载视频并保存
    
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [documentPath stringByAppendingPathComponent:@"test-video.mp4"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [GKMessageTool showMessage:nil];
    [[manager downloadTaskWithRequest:[NSURLRequest requestWithURL:self.url] progress:^(NSProgress * _Nonnull downloadProgress) {
        NSLog(@"%.0f%%", ((float)downloadProgress.completedUnitCount / (float)downloadProgress.totalUnitCount) * 100);
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:filePath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        if (!error) {
            [self saveLivePhotoWithUrl:filePath.path];
        }else {
            [GKMessageTool showError:error.localizedDescription];
        }
    }] resume];
}

- (void)saveLivePhotoWithUrl:(NSString *)url {
    [GKMessageTool showMessage:@"视频处理中..."];
    [LivePhotoUtil convertVideo:url complete:^(BOOL success, NSString *msg) {
        if (success) {
            [GKMessageTool showText:@"保存成功！"];
        }else {
            [GKMessageTool showError:msg];
        }
    }];
}

@end
