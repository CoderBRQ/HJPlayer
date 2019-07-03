

Pod::Spec.new do |s|
  s.name         = "HJPlayer"
  s.version      = "0.0.1"
  s.summary      = "AVPlayer play and cache."

  s.description  = 'This library provides a singleton for cache data with support for remote '      \
                  'data coming from the web.'
  s.homepage     = "https://github.com/CoderBRQ/HJPlayer"

  s.license      = "MIT"

  s.author             = { "brq" => "brqmail@163.com" }
  s.social_media_url   = "http://www.hibrq.com"

  s.ios.deployment_target = "8.0"

  s.source       = { :git => "https://github.com/CoderBRQ/HJPlayer.git", :tag => "#{s.version}" }

  s.source_files  = "HJPlayer", "HJPlayer/*/*.{h,m}"

  s.requires_arc = true

end
