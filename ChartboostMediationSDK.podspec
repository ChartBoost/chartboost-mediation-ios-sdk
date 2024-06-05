Pod::Spec.new do |spec|
  spec.name              = 'ChartboostMediationSDK'
  spec.version           = '4.9.0'
  spec.license           = { :type => 'Commercial', :text => 'LICENSE © 2011-2024 Chartboost. All rights reserved. LICENSE' }
  spec.homepage          = 'https://www.chartboost.com/'
  spec.authors           = { 'Chartboost' => 'https://www.chartboost.com/' }
  spec.summary           = 'Chartboost Mediation iOS SDK.'
  spec.description       = 'A programmatic ad monetization platform for mobile games and apps.'
  spec.documentation_url = 'https://developers.chartboost.com'

  # Source
  spec.module_name  = 'ChartboostMediationSDK'
  spec.source       = { :http => 'https://chartboost.s3.amazonaws.com/helium/sdk/ios/4.9.0/ChartboostMediationSDK-iOS-4.9.0.zip' }

  # Minimum supported versions
  spec.swift_version         = '5.0'
  spec.ios.deployment_target = '10.0'

  # System frameworks used
  spec.ios.frameworks      = ['AVFoundation','CoreGraphics','StoreKit','Foundation','UIKit','WebKit','CoreTelephony','AdSupport']

  # Vendored frameworks used
  spec.vendored_frameworks = ['ChartboostMediationSDK.xcframework']
end
