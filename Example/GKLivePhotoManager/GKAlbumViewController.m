//
//  GKAlbumViewController.m
//  GKLivePhotoManager
//
//  Created by QuintGao on 2024/6/24.
//

#import "GKAlbumViewController.h"
#import <Photos/Photos.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "GKLivePhotoManager.h"
#import "GKMessageTool/GKMessageTool.h"
#import <Example-Swift.h>
#import <ZLPhotoBrowser/ZLPhotoBrowser-Swift.h>

@interface GKAlbumViewController ()

@end

@implementation GKAlbumViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"相册资源";
    
    UIButton *selectBtn = [[UIButton alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 100)/2, 100, 100, 30)];
    [selectBtn setTitle:@"选择图片" forState:UIControlStateNormal];
    [selectBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    selectBtn.backgroundColor = UIColor.blackColor;
    selectBtn.layer.cornerRadius = 5;
    selectBtn.layer.masksToBounds = YES;
    [selectBtn addTarget:self action:@selector(selectAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:selectBtn];
}

- (void)selectAction {
    BOOL isLive = [self.videoPath isEqualToString:@"1"];
    
    ZLPhotoConfiguration *config = [ZLPhotoConfiguration default];
    config.maxSelectCount = 1;
    
    if (isLive) {
        config.allowSelectImage = YES;
        config.allowSelectVideo = NO;
        config.allowSelectLivePhoto = YES;
    }else {
        config.allowSelectImage = NO;
        config.allowSelectVideo = YES;
    }
    
    ZLPhotoPreviewSheet *sheet = [[ZLPhotoPreviewSheet alloc] init];
    
    __weak __typeof(self) weakSelf = self;
    sheet.selectImageBlock = ^(NSArray<ZLResultModel *> *result, BOOL isOriginal) {
        __strong __typeof(weakSelf) self = weakSelf;
        ZLResultModel *model = result.firstObject;
        [self createLivePhotoWithAsset:model.asset];
    };
    
    [sheet showPhotoLibraryWithSender:self];
}

- (void)createLivePhotoWithAsset:(PHAsset *)asset {
    __weak __typeof(self) weakSelf = self;
    [GKMessageTool showMessage:nil];
    [[GKLivePhotoManager manager] createLivePhotoWithAsset:asset targetSize:CGSizeMake(300, 300) progressBlock:^(float progress) {
        NSLog(@"%f", progress);
    } completion:^(PHLivePhoto * _Nullable livePhoto, NSError * _Nullable error) {
        [GKMessageTool hideMessage];
        if (error) {
            [GKMessageTool showError:error.localizedDescription];
        }else {
            [weakSelf setLivePhoto:livePhoto];
        }
    }];
}

@end
