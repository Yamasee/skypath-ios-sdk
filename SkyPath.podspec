Pod::Spec.new do |s|
    
    sdk_version = '2.1.4'

    s.name = 'SkyPath'
    s.version = sdk_version
    s.summary = 'The world’s leading turbulence and auto-PIREPS data source.'
    s.homepage = 'https://github.com/Yamasee/skypath-ios-sdk'
    s.author = { 'SkyPath' => 'info@skypath.io' }
    s.license = { :type => 'Commercial', :file => 'LICENSE' }
    s.documentation_url = 'https://yamasee.github.io/skypath-ios-sdk-docs'

    s.platform = :ios
    s.source = { :git => 'https://github.com/Yamasee/skypath-ios-sdk.git', :tag => "v#{sdk_version}" } 
    s.ios.deployment_target = '14.0'
    s.swift_version = '5.7'
    s.ios.vendored_frameworks = 'SkyPathSDK.xcframework'

end 