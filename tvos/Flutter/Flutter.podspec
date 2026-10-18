#
# This podspec is NOT to be published. It is only used as a local source!
# The Flutter tool does not generate a tvOS Flutter.podspec, so this file is
# hand-maintained and must stay checked in (see tvos/.gitignore).
#

Pod::Spec.new do |s|
  s.name             = 'Flutter'
  s.version          = '1.0.0'
  s.summary          = 'A UI toolkit for beautiful and fast apps.'
  s.homepage         = 'https://flutter.dev'
  s.license          = { :type => 'BSD' }
  s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :git => 'https://github.com/flutter/engine', :tag => s.version.to_s }
  s.ios.deployment_target  = '13.0'
  s.tvos.deployment_target = '15.0'
  # Framework linking is handled by Flutter tooling, not CocoaPods.
  # Add a placeholder to satisfy `s.dependency 'Flutter'` plugin podspecs.
  s.vendored_frameworks = 'path/to/nothing'
end
