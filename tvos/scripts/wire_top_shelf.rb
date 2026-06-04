#!/usr/bin/env ruby
# Adds Plezy's tvOS Top Shelf extension target and Runner-side bridge source.

require 'xcodeproj'

PROJECT_PATH = File.expand_path('../Runner.xcodeproj', __dir__)
project = Xcodeproj::Project.open(PROJECT_PATH)
runner = project.targets.find { |t| t.name == 'Runner' }
raise 'Runner target not found' unless runner

main_group = project.main_group
runner_group = main_group['Runner']
raise 'Runner group not found' unless runner_group
products_group = main_group['Products'] || main_group.new_group('Products')
frameworks_group = main_group['Frameworks'] || main_group.new_group('Frameworks')
generated_config_ref = project.files.find { |file| file.path == 'Flutter/Generated.xcconfig' }
raise 'Generated.xcconfig not found' unless generated_config_ref

def ensure_file(group, path, name: nil, source_tree: '<group>')
  existing = group.files.find { |f| f.path == path || f.display_name == (name || File.basename(path)) }
  return existing if existing

  ref = group.new_file(path)
  ref.name = name if name
  ref.source_tree = source_tree
  ref
end

def ensure_source(target, file_ref)
  phase = target.source_build_phase
  return if phase.files_references.include?(file_ref)

  phase.add_file_reference(file_ref, true)
end

def ensure_copy_file(project, phase, file_ref)
  existing = phase.files.find { |build_file| build_file.file_ref == file_ref }
  return existing if existing

  build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  build_file.file_ref = file_ref
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
  phase.files << build_file
  build_file
end

def ensure_framework(target, file_ref)
  phase = target.frameworks_build_phase
  return if phase.files_references.include?(file_ref)

  phase.add_file_reference(file_ref, true)
end

system_shelf_ref = ensure_file(runner_group, 'SystemShelfPlugin.swift')
ensure_source(runner, system_shelf_ref)
ensure_file(runner_group, 'Runner.entitlements')

extension_group = main_group['TopShelfExtension'] || main_group.new_group('TopShelfExtension', 'TopShelfExtension')
top_shelf_ref = ensure_file(extension_group, 'TopShelfProvider.swift')
ensure_file(extension_group, 'Info.plist')
ensure_file(extension_group, 'TopShelfExtension.entitlements')

extension_target = project.targets.find { |t| t.name == 'TopShelfExtension' }
unless extension_target
  extension_target = project.new_target(:app_extension, 'TopShelfExtension', :tvos, '14.0')
end
extension_target.product_type = 'com.apple.product-type.app-extension'

ensure_source(extension_target, top_shelf_ref)

removed_framework_refs = []
extension_target.frameworks_build_phase.files.delete_if do |build_file|
  next false unless build_file.file_ref&.display_name == 'Foundation.framework'

  removed_framework_refs << build_file.file_ref
  true
end
removed_framework_refs.compact.uniq.each do |file_ref|
  still_used = project.targets.any? do |target|
    target.frameworks_build_phase.files_references.include?(file_ref)
  end
  file_ref.remove_from_project unless still_used
end

tv_services_ref = ensure_file(
  frameworks_group,
  'System/Library/Frameworks/TVServices.framework',
  name: 'TVServices.framework',
  source_tree: 'SDKROOT'
)
ensure_framework(extension_target, tv_services_ref)

extension_product = extension_target.product_reference
extension_product.name = 'TopShelfExtension.appex'
extension_product.path = 'TopShelfExtension.appex'
extension_product.explicit_file_type = 'wrapper.app-extension'
products_group.children << extension_product unless products_group.children.include?(extension_product)

runner.add_dependency(extension_target) unless runner.dependencies.any? { |d| d.target == extension_target }

embed_phase = runner.copy_files_build_phases.find { |phase| phase.name == 'Embed App Extensions' }
unless embed_phase
  embed_phase = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
  embed_phase.name = 'Embed App Extensions'
  embed_phase.dst_subfolder_spec = '13'
  embed_phase.dst_path = ''
  runner.build_phases.insert(-3, embed_phase)
end
ensure_copy_file(project, embed_phase, extension_product)

runner.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

extension_target.build_configurations.each do |config|
  config.base_configuration_reference = generated_config_ref

  settings = config.build_settings
  settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  settings['CLANG_ENABLE_MODULES'] = 'YES'
  settings['CODE_SIGN_ENTITLEMENTS'] = 'TopShelfExtension/TopShelfExtension.entitlements'
  settings['CODE_SIGN_IDENTITY'] = 'Apple Development'
  settings['CODE_SIGN_STYLE'] = 'Automatic'
  settings['CURRENT_PROJECT_VERSION'] = '$(FLUTTER_BUILD_NUMBER)'
  settings['DEVELOPMENT_TEAM'] = 'G88U5B5783'
  settings['ENABLE_BITCODE'] = 'NO'
  settings['INFOPLIST_FILE'] = 'TopShelfExtension/Info.plist'
  settings['LD_RUNPATH_SEARCH_PATHS'] = [
    '$(inherited)',
    '@executable_path/Frameworks',
    '@executable_path/../../Frameworks',
  ]
  settings['MARKETING_VERSION'] = '$(FLUTTER_BUILD_NAME)'
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.edde746.plezy.TopShelfExtension'
  settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
  settings['SDKROOT'] = 'appletvos'
  settings['SKIP_INSTALL'] = 'YES'
  settings['SUPPORTED_PLATFORMS'] = 'appletvos appletvsimulator'
  settings['SWIFT_VERSION'] = '5.0'
  settings['TARGETED_DEVICE_FAMILY'] = '3'
  settings['TVOS_DEPLOYMENT_TARGET'] = '14.0'
end

project.save
puts 'Saved Top Shelf wiring'
