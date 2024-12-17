//
//  GKBaseViewController.h
//  GKLivePhotoManager
//
//  Created by QuintGao on 2024/6/24.
//

#import <UIKit/UIKit.h>
#import <PhotosUI/PhotosUI.h>

NS_ASSUME_NONNULL_BEGIN

@interface GKBaseViewController : UIViewController

@property (nonatomic, strong, readonly) PHLivePhotoView *photoView;

@property (nonatomic, copy) NSString *videoPath;
@property (nonatomic, copy) NSString *imagePath;

- (void)setLivePhoto:(id)livePhoto;

@end

NS_ASSUME_NONNULL_END
