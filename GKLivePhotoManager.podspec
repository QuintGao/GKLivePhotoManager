Pod::Spec.new do |s|
  s.name             = 'GKLivePhotoManager'
  s.version          = '1.0.0'
  s.summary          = 'livePhoto处理工具类'
  s.homepage         = 'https://github.com/QuintGao/GKLivePhotoManager'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.authors      = { "QuintGao" => "1094887059@qq.com" }
  s.social_media_url   = "https://github.com/QuintGao"
  s.ios.deployment_target = "10.0"
  s.source       = { :git => "https://github.com/QuintGao/GKLivePhotoManager.git", :tag => s.version.to_s }
  s.source_files = 'GKLivePhotoManager/**/*'
end
