Pod::Spec.new do |s|
  s.name = 'plezy_preparation'
  s.version = '1.0.0'
  s.summary = 'PlezyNG preparation workers'
  s.description = s.summary
  s.homepage = 'https://github.com/snapetech-org/PlezyNG'
  s.license = { :type => 'GPL-3.0' }
  s.author = { 'PlezyNG' => 'https://github.com/snapetech-org' }
  s.source = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.5'
  s.swift_version = '5.0'
end
