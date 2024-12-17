//
//  GKLocalViewController.m
//  GKLivePhotoManager
//
//  Created by QuintGao on 2024/6/24.
//

#import "GKLocalViewController.h"
#import "GKLivePhotoManager.h"
#import <GKMessageTool/GKMessageTool.h>

@interface GKLocalViewController ()

@end

@implementation GKLocalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"本地资源";
    
    __weak __typeof(self) weakSelf = self;
    [GKMessageTool showMessage:nil];
    [[GKLivePhotoManager manager] handleDataWithVideoPath:self.videoPath imagePath:self.imagePath progressBlock:^(float progress) {
        NSLog(@"进度---%f", progress);
    } completion:^(NSString * _Nullable outVideoPath, NSString * _Nullable outImagePath, NSError * _Nullable error) {
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
