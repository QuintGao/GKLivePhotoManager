//
//  GKSaveViewController.m
//  GKLivePhotoManager
//
//  Created by QuintGao on 2024/6/25.
//

#import "GKSaveViewController.h"
#import <AVKit/AVKit.h>
#import <AFNetworking/AFNetworking.h>
#import "GKLivePhotoManager.h"
#import <GKMessageTool/GKMessageTool.h>

@interface GKSaveViewController ()

@property (nonatomic, strong) NSURL *url;

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (nonatomic, strong) UIView *playView;

@end

@implementation GKSaveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSURL *url = [NSURL URLWithString:@"https://videos.pexels.com/video-files/24797498/11897306_360_640_60fps.mp4"];
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
//        [GKMessageTool showMessage:nil];
//        [self saveLivePhotoWithUrl:filePath];
//        return;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [GKMessageTool showMessage:nil];
    [[manager downloadTaskWithRequest:[NSURLRequest requestWithURL:self.url] progress:^(NSProgress * _Nonnull downloadProgress) {
        NSLog(@"%.0f%%", ((float)downloadProgress.completedUnitCount / (float)downloadProgress.totalUnitCount) * 100);
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:filePath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        [self saveLivePhotoWithUrl:filePath.path];
    }] resume];
}

- (void)saveLivePhotoWithUrl:(NSString *)url {
    [[GKLivePhotoManager manager] handleDataWithVideoPath:url progressBlock:^(float progress) {
        NSLog(@"%f", progress);
    } completion:^(NSString * _Nullable outVideoPath, NSString * _Nullable outImagePath, NSError * _Nullable error) {
        if (error) {
            [GKMessageTool showError:error.localizedDescription];
        }else {
            [[GKLivePhotoManager manager] saveLivePhotoWithVideoPath:outVideoPath imagePath:outImagePath completion:^(BOOL success, NSError *error) {
                [GKMessageTool hideMessage];
                if (error) {
                    [GKMessageTool showError:error.localizedDescription];
                }else {
                    [GKMessageTool showText:@"保存成功！！！"];
                }
            }];
        }
    }];
}

@end
