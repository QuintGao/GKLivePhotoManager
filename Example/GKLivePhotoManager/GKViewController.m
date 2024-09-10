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
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface GKViewController ()

@end

@implementation GKViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"%@", UTTypeHEIC);
}

- (IBAction)localAction:(id)sender {
    [self.navigationController pushViewController:GKLocalViewController.new animated:YES];
}

- (IBAction)webAction:(id)sender {
    [self.navigationController pushViewController:GKWebViewController.new animated:YES];
}
- (IBAction)albumAction:(id)sender {
    [self.navigationController pushViewController:GKAlbumViewController.new animated:YES];
}

- (IBAction)saveAction:(id)sender {
    [self.navigationController pushViewController:GKSaveViewController.new animated:YES];
}


@end
