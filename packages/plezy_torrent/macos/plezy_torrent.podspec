Pod::Spec.new do |s|
  s.name = 'plezy_torrent'
  s.version = '1.0.0'
  s.summary = 'PlezyNG native verified-piece torrent streaming'
  s.description = s.summary
  s.homepage = 'https://github.com/snapetech-org/PlezyNG'
  s.license = { :type => 'BSD-3-Clause and BSL-1.0', :file => '../NOTICE.md' }
  s.author = { 'PlezyNG' => 'https://github.com/snapetech-org' }
  s.source = { :path => '.' }
  s.platform = :osx, '13.0'
  s.vendored_frameworks = 'Frameworks/macos/PlezyTorrent.xcframework'
end
