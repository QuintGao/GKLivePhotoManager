//
//  GKViewController.m
//  GKLivePhotoManager
//
//  Created by QuintGao on 06/27/2024.
//  Copyright (c) 2024 QuintGao. All rights reserved.
//

#import "GKViewController.h"
#import "GKLocalViewController.h"
#import "GKWebViewController.h"
#import "GKAlbumViewController.h"
#import "GKSaveViewController.h"
#import <Example-Swift.h>

@interface GKViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSArray *dataSource;

@end

@implementation GKViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"GKLivePhotoManager";
    
    [self.view addSubview:self.tableView];
    
    self.dataSource = @[
        @{@"title": @"本地资源",
          @"detail": @"本地视频转livePhoto",
          @"class": @"GKLocalViewController",
          @"video": [NSBundle.mainBundle pathForResource:@"test" ofType:@"mp4"],
          @"image": @""},
        @{@"title": @"本地资源",
          @"detail": @"本地视频和图片转livePhoto",
          @"class": @"GKLocalViewController",
          @"video": [NSBundle.mainBundle pathForResource:@"IMG_E8375" ofType:@"mov"],
          @"image": [NSBundle.mainBundle pathForResource:@"IMG_E8375" ofType:@"heic"]},
        @{@"title": @"网络资源",
          @"detail": @"网络视频转livePhoto",
          @"class": @"GKWebViewController",
          @"video": @"http://vd4.bdstatic.com/mda-qkvpzc201yn7ia1g/cae_h264/1732985779708787214/mda-qkvpzc201yn7ia1g.mp4",
          @"image": @""},
        @{@"title": @"网络资源",
          @"detail": @"网络视频和图片转livePhoto",
          @"class": @"GKWebViewController",
          @"video": @"https://video.weibo.com/media/play?livephoto=https%3A%2F%2Fus.sinaimg.cn%2F000YYEgOgx08fAjKa77G0f0f0100fQhZ0k01.mov",
          @"image": @"https://wx1.sinaimg.cn/mw690/87b3c920gy1hqm73s9siyj22c0340u0x.jpg"},
        @{@"title": @"相册资源",
          @"detail": @"加载相册livePhoto",
          @"class": @"GKAlbumViewController",
          @"video": @"1",
          @"image": @""},
        @{@"title": @"相册资源",
          @"detail": @"相册视频转livePhoto",
          @"class": @"GKAlbumViewController",
          @"video": @"0",
          @"image": @""},
        @{@"title": @"保存相册",
          @"detail": @"livePhoto保存到相册",
          @"class": @"GKSaveViewController",
          @"video": @"https://hellorfimg.zcool.cn/videos/preview_mp4/1062985270.mp4",
          @"image": @""},
        @{@"title": @"保存为墙纸",
          @"detail": @"livePhoto保存到相册",
          @"class": @"GKWallpapersViewController",
          @"video": @"https://hellorfimg.zcool.cn/videos/preview_mp4/3454661509.mp4",
          @"image": @""}
    ];
}

#pragma mark - <UITableViewDataSource, UITableViewDelegate>
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    NSDictionary *dict = self.dataSource[indexPath.row];
    cell.textLabel.text = dict[@"title"];
    cell.detailTextLabel.text = dict[@"detail"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dict = self.dataSource[indexPath.row];
    
    Class cls = NSClassFromString(dict[@"class"]);
    
    UIViewController *vc = [[cls alloc] init];
    if ([vc isKindOfClass:GKBaseViewController.class]) {
        ((GKBaseViewController *)vc).videoPath = dict[@"video"];
        ((GKBaseViewController *)vc).imagePath = dict[@"image"];
    }
    
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - lazy
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
    }
    return _tableView;
}

@end
