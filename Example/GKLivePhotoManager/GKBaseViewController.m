//
//  GKBaseViewController.m
//  GKLivePhotoManager
//
//  Created by QuintGao on 2024/6/24.
//

#import "GKBaseViewController.h"
#import <GKLivePhotoManager/GKLivePhotoManager.h>

@interface GKBaseViewController ()<PHLivePhotoViewDelegate>

@property (nonatomic, strong) PHLivePhotoView *photoView;

@end

@implementation GKBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    
    self.photoView = [[PHLivePhotoView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 300)/2, 150, 300, 300)];
    self.photoView.delegate = self;
    [self.view addSubview:self.photoView];
}

- (void)setLivePhoto:(id)livePhoto {
    self.photoView.livePhoto = livePhoto;
    self.photoView.muted = NO;
    [self.photoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
}

- (void)dealloc {
    NSLog(@"%@--dealloc", self);
    [self.photoView stopPlayback];
    
    [GKLivePhotoManager deallocManager];
}

#pragma mark - PHLivePhotoViewDelegate
- (BOOL)livePhotoView:(PHLivePhotoView *)livePhotoView canBeginPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
    NSLog(@"可以播放");
    return YES;
}

- (void)livePhotoView:(PHLivePhotoView *)livePhotoView willBeginPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
    NSLog(@"即将播放");
}

- (void)livePhotoView:(PHLivePhotoView *)livePhotoView didEndPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
    NSLog(@"结束播放");
}

@end
