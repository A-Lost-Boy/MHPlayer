Pod::Spec.new do |s|

  s.name         = "MHPlayer"
  s.version      = "1.0.0"
  s.summary      = "A good video player made by CoderMikeHe"
  s.description  = "Based on AVPlayer, support for the horizontal screen, vertical screen , the upper and lower slide to adjust the volume, the screen brightness, or so slide to adjust the playback progress."
  s.homepage     = "https://github.com/CoderMikeHe/MHPlayer"
  s.license      = "MIT"
  s.authors      = {"Mike_He" => "491273090@qq.com"}
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/CoderMikeHe/MHPlayer.git", :tag => s.version }
  s.source_files  = "MHPlayer", "MHPlayer/**/*.{h,m}"
  s.resource     = "MHPlayer/MhPlayer.bundle"
  s.frameworks   = "UIKit", "MediaPlayer"
  s.dependency 'Masonry'
  s.dependency 'MBProgressHUD'
  s.requires_arc = true

end