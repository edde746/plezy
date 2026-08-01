#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'wakelock_plus'
  s.version          = '0.0.1'
  s.summary          = 'Plugin that allows you to keep the device screen awake, i.e. prevent the screen from sleeping on Android, iOS, macOS, Windows, and web.'
  s.description      = <<-DESC
  Plugin that allows you to keep the device screen awake, i.e. prevent the screen from sleeping on Android, iOS, macOS, Windows, and web.
                       DESC
  s.homepage         = 'https://github.com/fluttercommunity/wakelock_plus'
  s.license          = { :type => 'BSD', :file => '../LICENSE' }
  s.author           = { 'Flutter Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :http => 'https://github.com/fluttercommunity/wakelock_plus/tree/main/packages/wakelock_plus_macos' }
  s.source_files = 'wakelock_plus/Sources/wakelock_plus/**/*.swift'
  s.dependency 'FlutterMacOS'
  s.osx.deployment_target = '10.15'
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  s.resource_bundles = {'wakelock_plus' => ['wakelock_plus/Sources/wakelock_plus/Resources/PrivacyInfo.xcprivacy']}
end
