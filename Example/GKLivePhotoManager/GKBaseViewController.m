//
//  GKBaseViewController.m
//  GKLivePhotoManager
//
//  Created by QuintGao on 2024/6/24.
//

#import "GKBaseViewController.h"
#import <PhotosUI/PhotosUI.h>

@interface GKBaseViewController ()

@property (nonatomic, strong) PHLivePhotoView *photoView;

@end

@implementation GKBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    
    self.photoView = [[PHLivePhotoView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 300)/2, 300, 300, 300)];
    [self.view addSubview:self.photoView];
}

- (void)setLivePhoto:(id)livePhoto {
    self.photoView.livePhoto = livePhoto;
    self.photoView.muted = NO;
    [self.photoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
}

- (void)dealloc {
    NSLog(@"%@--dealloc", self);
}

@end
