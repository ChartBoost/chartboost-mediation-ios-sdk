Pod::Spec.new do |spec|
  spec.name              = 'ChartboostMediationSDK'
  spec.version           = '5.0.0'
  spec.license           = { :type => 'MIT', :file => 'LICENSE.md' }
  spec.homepage          = 'https://github.com/ChartBoost/chartboost-mediation-ios-sdk'
  spec.authors           = { 'Chartboost' => 'https://www.chartboost.com/' }
  spec.summary           = 'Chartboost Mediation iOS SDK.'
  spec.description       = 'A programmatic ad monetization platform for mobile games and apps.'
  spec.documentation_url = 'https://developers.chartboost.com'

  # Source
  spec.module_name  = 'ChartboostMediationSDK'
  spec.source       = { :git => 'https://github.com/ChartBoost/chartboost-mediation-ios-sdk.git', :tag => spec.version }
  spec.source_files = 'Source/**/*.{swift,md}'
  spec.resource_bundles = { 'ChartboostMediationSDK' => ['PrivacyInfo.xcprivacy'] }
  spec.static_framework = true

  # Minimum supported versions
  spec.swift_version         = '5.0'
  spec.ios.deployment_target = '13.0'

  # System frameworks used
  spec.ios.frameworks      = ['AVFoundation','CoreGraphics','StoreKit','Foundation','UIKit','WebKit','CoreTelephony','AdSupport']

  # Dependency
  spec.dependency 'ChartboostCoreSDK', '~> 1.0'

  # Test spec that defines tests to run when executing `pod lib lint`
  spec.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'Tests/**/*.{swift,h,m}'
    test_spec.resources = 'Tests/Resources/**/*'
    test_spec.scheme = { :code_coverage => true }
    # Higher deployment target than the main spec because it simplifies the implementation of some tests and mocks.
    # We don't run tests in old OS simulators anyway.
    test_spec.ios.deployment_target = '14.0'
    # Add test SKAdNetwork IDs to the Info.plist used by some tests
    test_spec.info_plist = {
      'SKAdNetworkItems' => [
        { 'SKAdNetworkIdentifier': 'test-0.skadnetwork' },
        { 'SKAdNetworkIdentifier': 'test-1.skadnetwork' },
        { 'SKAdNetworkIdentifier': 'test-2.skadnetwork' }
      ]
    }
  end
end
