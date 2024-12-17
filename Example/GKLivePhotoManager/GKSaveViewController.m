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
#import "LivePhotoUtil.h"

@interface GKSaveViewController ()

@property (nonatomic, strong) NSURL *url;

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (nonatomic, strong) UIView *playView;

@property (nonatomic, copy) NSString *saveVideoPath;

@property (nonatomic, copy) NSString *outVideoPath;
@property (nonatomic, copy) NSString *outImagePath;

@end

@implementation GKSaveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"保存到相册";
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSURL *videoUrl = [NSURL URLWithString:self.videoPath];
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString *videoPath = [path stringByAppendingPathComponent:@"web.mov"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:videoPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
    }
    
    [GKMessageTool showMessage:@"资源下载中..."];
    
    [[manager downloadTaskWithRequest:[NSURLRequest requestWithURL:videoUrl] progress:nil destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:videoPath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        self.saveVideoPath = filePath.path;
        if (self.saveVideoPath) {
            [self reqeustLivePhoto];
        }else {
            [GKMessageTool hideMessage];
            [GKMessageTool showError:error.localizedDescription];
        }
    }] resume];
    
    UIButton *saveBtn = [[UIButton alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 180)/2, CGRectGetMaxY(self.photoView.frame) + 80, 180, 30)];
    [saveBtn setTitle:@"生成livePhoto并保存" forState:UIControlStateNormal];
    [saveBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    saveBtn.backgroundColor = UIColor.blackColor;
    saveBtn.layer.cornerRadius = 5;
    saveBtn.layer.masksToBounds = YES;
    [self.view addSubview:saveBtn];
    [saveBtn addTarget:self action:@selector(saveAction) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.saveVideoPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.saveVideoPath error:nil];
    }
}

- (void)reqeustLivePhoto {
    
    [[GKLivePhotoManager manager] handleDataWithVideoPath:self.saveVideoPath progressBlock:^(float progress) {
        
    } completion:^(NSString * _Nullable outVideoPath, NSString * _Nullable outImagePath, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [GKMessageTool showError:error.localizedDescription];
            });
        }else {
            self.outVideoPath = outVideoPath;
            self.outImagePath = outImagePath;
            
            [[GKLivePhotoManager manager] createLivePhotoWithVideoPath:outVideoPath imagePath:outImagePath targetSize:CGSizeMake(300, 300) completion:^(PHLivePhoto * _Nullable livePhoto, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        [GKMessageTool showError:error.localizedDescription];
                    }else {
                        [GKMessageTool hideMessage];
                        [self setLivePhoto:livePhoto];
                    }
                });
            }];
        }
    }];
}

- (void)saveAction {
    if (!self.outVideoPath || !self.outImagePath) {
        [GKMessageTool showError:@"资源准备中，请稍后"];
        return;
    }
    
    // 保存到相册
    [GKMessageTool showMessage:nil];
    [[GKLivePhotoManager manager] saveLivePhotoWithVideoPath:self.outVideoPath imagePath:self.outImagePath completion:^(BOOL success, NSError *error) {
        if (error) {
            [GKMessageTool showError:error.localizedDescription];
        }else {
            [GKMessageTool showText:@"保存成功！！！"];
        }
    }];
}

@end
