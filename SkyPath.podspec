Pod::Spec.new do |s|
    
    sdk_version = '2.2.0'

    s.name = 'SkyPath'
    s.version = sdk_version
    s.summary = 'The world’s leading turbulence and auto-PIREPs data source.'
    s.homepage = 'https://github.com/Yamasee/skypath-ios-sdk'
    s.author = { 'SkyPath' => 'info@skypath.io' }
    s.license = { :type => 'Commercial' }
    s.license = { :type => 'Commercial', :text => <<-LICENSE
        SkyPath iOS SDK

        Copyright © 2023 SkyPath LTD

        All rights reserved.

        SkyPath iOS SDK must be used according to the SkyPath Terms of Use https://skypath.io/terms/.
        LICENSE
    }
    s.documentation_url = 'https://yamasee.github.io/skypath-ios-sdk-docs'

    s.platform = :ios
    s.source = { :http => "#{s.homepage}/releases/download/v#{sdk_version}/SkyPathSDK.xcframework.zip" } 
    s.ios.deployment_target = '14.0'
    s.swift_version = '5.10'
    s.ios.vendored_frameworks = 'SkyPathSDK.xcframework'
    s.dependency 'geos', '~> 8.1'

end 