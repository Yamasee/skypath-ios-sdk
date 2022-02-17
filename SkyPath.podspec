Pod::Spec.new do |s|  

    sdk_version = '1.11.1'

    s.name = 'SkyPath'
    s.version = sdk_version
    s.summary = 'SkyPath iOS SDK'
    s.homepage = 'https://github.com/Yamasee/skypath-ios-sdk'

    s.author = { 'SkyPath' => 'info@skypath.io' }
    s.license = { type: 'Commercial', file: 'LICENSE' }

    s.platform = :ios
    s.source = { :git => 'https://github.com/Yamasee/skypath-ios-sdk.git', :tag => "v#{sdk_version}" } 
    s.ios.deployment_target = '12.0'
    s.swift_version = '5.0'
    s.ios.vendored_frameworks = 'Yamasee.xcframework'

end 