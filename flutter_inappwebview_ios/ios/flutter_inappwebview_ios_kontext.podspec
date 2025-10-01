#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutterplugintest.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_inappwebview_ios_kontext'
  s.version          = '1.1.2'
  s.summary          = 'Kontext iOS platform code for flutter_inappwebview.'
  s.description      = <<-DESC
Native iOS implementation for the flutter_inappwebview plugin, including the
OM SDK dependencies and privacy resources required at runtime.
                       DESC
  s.homepage         = 'https://github.com/kontextso/flutter_inappwebview'
  s.license          = { :type => 'Apache-2.0', :file => '../LICENSE' }
  s.author           = { 'Lorenzo Pichilli' => 'lorenzo@pichillilorenzo.com' }
  s.source           = {
  :git => 'https://github.com/kontextso/flutter_inappwebview.git',
  :tag => s.version.to_s
  }

  s.swift_versions   = ['5.0']
  s.ios.deployment_target = '12.0'
  s.default_subspec = 'Core'
  s.subspec 'Core' do |core|
      core.source_files = 'Classes/**/*'
      core.resources = [
        'Storyboards/**/*.storyboard',
        'Frameworks/OMSDK/PrivacyInfo.xcprivacy'
      ]
      core.public_header_files = 'Classes/**/*.h'
      core.resource_bundles = { 'so_kontext_flutter_inappwebview_ios_privacy' => ['Resources/PrivacyInfo.xcprivacy'] }
      core.vendored_frameworks = 'Frameworks/OMSDK/OMSDK_Megabrainco.xcframework'
      core.dependency 'Flutter'
	  core.dependency 'OrderedSet', '~>6.0.3'
	  core.libraries = 'swiftCoreGraphics'
	  core.pod_target_xcconfig = {
        'DEFINES_MODULE' => 'YES',
        'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64',
        'OTHER_LDFLAGS' => '$(inherited) -framework "OMSDK_Megabrainco"',
        'FRAMEWORK_SEARCH_PATHS' => '$(inherited) ${PODS_TARGET_SRCROOT}/Frameworks/OMSDK'
      }
      core.user_target_xcconfig = {
        'OTHER_LDFLAGS' => '$(inherited) -framework "OMSDK_Megabrainco"',
        'FRAMEWORK_SEARCH_PATHS' => '$(inherited) ${PODS_ROOT}/flutter_inappwebview_ios_kontext/Frameworks/OMSDK ${PODS_ROOT}/../.symlinks/plugins/flutter_inappwebview_ios_kontext/ios/Frameworks/OMSDK'
      }
      core.xcconfig = {
        'LIBRARY_SEARCH_PATHS' => '$(SDKROOT)/usr/lib/swift'
      }
  end
end
