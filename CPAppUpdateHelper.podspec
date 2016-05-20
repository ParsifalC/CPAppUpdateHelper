Pod::Spec.new do |s|
  s.name         = "CPAppUpdateHelper"
  s.version      = "0.0.1"
  s.summary      = "A light tool for iOS App update."
  s.homepage     = "https://github.com/mingweizhang/CPAppUpdateHelper"
  s.license      = { :type => "MIT", :text => "" }
  s.author             = { "mingweizhang" => "mingweiz@foxmail.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/mingweizhang/CPAppUpdateHelper.git", :tag => s.version.to_s }
  s.source_files  = "CPAppUpdateHelper/Classes/**/*.{h,m}"
end
