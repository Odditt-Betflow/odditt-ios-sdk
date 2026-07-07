Pod::Spec.new do |s|
  s.name             = 'OddittSDK'
  s.version          = '0.1.0'
  s.summary          = 'Embed the Odditt betting widget in an iOS app.'
  s.description      = <<-DESC
    Drop the Odditt betting widget into your iOS app with one OddittWidgetView
    (UIKit) or OddittWidget (SwiftUI): pass typed config into a managed WKWebView
    and receive typed post-back signals (bet clicks, ready, errors, resize).
  DESC
  s.homepage         = 'https://github.com/Odditt-Betflow/odditt-ios-sdk'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.authors          = 'Odditt'
  s.source           = { :git => 'https://github.com/Odditt-Betflow/odditt-ios-sdk.git', :tag => "v#{s.version}" }
  s.ios.deployment_target = '13.0'
  s.swift_version    = '5.9'
  s.source_files     = 'Sources/OddittSDK/**/*.swift'
  s.frameworks       = 'UIKit', 'WebKit'
end
