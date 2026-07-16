#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint wakelock_plus.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'wakelock_plus'
  s.version          = '0.0.1'
  s.summary          = 'Plugin that allows you to keep the device screen awake, i.e. prevent the screen from sleeping on Android, iOS, macOS, Windows, Linux, and web.'
  s.description      = <<-DESC
Plugin that allows you to keep the device screen awake, i.e. prevent the screen from sleeping on Android, iOS, macOS, Windows, Linux, and web.
                       DESC
  s.homepage         = 'https://github.com/fluttercommunity/wakelock_plus'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flutter Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :path => '.' }
  s.source_files = 'wakelock_plus/Sources/wakelock_plus/**/*.{h,m}'
  s.public_header_files = 'wakelock_plus/Sources/wakelock_plus/include/**/*.h'
  s.dependency 'Flutter'
  s.ios.deployment_target = '12.0'
  s.tvos.deployment_target = '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.resource_bundles = {'wakelock_plus_privacy' => ['wakelock_plus/Sources/wakelock_plus/Resources/PrivacyInfo.xcprivacy']}
end
