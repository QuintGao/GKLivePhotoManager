//
//  GKAlbumViewController.m
//  GKLivePhotoManager
//
//  Created by QuintGao on 2024/6/24.
//

#import "GKAlbumViewController.h"
#import <Photos/Photos.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <TZImagePickerController/TZImagePickerController.h>
#import "GKLivePhotoManager.h"
#import "GKMessageTool/GKMessageTool.h"

@interface GKAlbumViewController ()<TZImagePickerControllerDelegate>

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
    TZImagePickerController *pickerVC = [[TZImagePickerController alloc] initWithMaxImagesCount:1 delegate:self];
    [self presentViewController:pickerVC animated:YES completion:nil];
}

#pragma mark - TZImagePickerControllerDelegate
- (void)tz_imagePickerControllerDidCancel:(TZImagePickerController *)picker {
    
}

- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto infos:(NSArray<NSDictionary *> *)infos {
    
    PHAsset *asset = assets.firstObject;
    if (!asset) return;
    
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
