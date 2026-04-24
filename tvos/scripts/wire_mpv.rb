#!/usr/bin/env ruby
# Adds the Plezy MpvPlayer Swift sources and the MPVKit Swift Package
# dependency to tvos/Runner.xcodeproj so it matches the iOS project's
# linkage. Idempotent: re-running skips already-added entries.

require 'xcodeproj'

PROJECT_PATH = File.expand_path('../Runner.xcodeproj', __dir__)
project = Xcodeproj::Project.open(PROJECT_PATH)
runner_target = project.targets.find { |t| t.name == 'Runner' }
raise "Runner target not found" unless runner_target

# Find or create the MpvPlayer group under Runner.
main_group = project.main_group['Runner']
raise "Runner group not found" unless main_group
mpv_group = main_group['MpvPlayer'] || main_group.new_group('MpvPlayer', 'Runner/MpvPlayer')

# File references.
# path is relative to the group's path (Runner/MpvPlayer → ../..).
# For files elsewhere in the repo, use SOURCE_ROOT with the absolute-ish path.
sources = [
  { name: 'MpvPlayerCoreBase.swift',   path: '../shared/apple/MpvPlayer/MpvPlayerCoreBase.swift',   tree: '<source_root>' },
  { name: 'MpvPlayerPluginShared.swift', path: '../shared/apple/MpvPlayer/MpvPlayerPluginShared.swift', tree: '<source_root>' },
  { name: 'MpvPlayerCore.swift',       path: '../ios/Runner/MpvPlayer/MpvPlayerCore.swift',   tree: '<source_root>' },
  { name: 'MpvPlayerPlugin.swift',     path: '../ios/Runner/MpvPlayer/MpvPlayerPlugin.swift', tree: '<source_root>' },
  { name: 'MpvPipController.swift',    path: '../ios/Runner/MpvPlayer/MpvPipController.swift', tree: '<source_root>' },
]

sources_phase = runner_target.source_build_phase
sources.each do |src|
  existing = mpv_group.files.find { |f| f.display_name == src[:name] }
  if existing
    puts "[skip] #{src[:name]} already present"
    next
  end
  ref = mpv_group.new_file(src[:path])
  ref.name = src[:name]
  ref.source_tree = src[:tree]
  sources_phase.add_file_reference(ref, true)
  puts "[add ] #{src[:name]}"
end

# Swift Package: MPVKit.
pkg_url = 'https://github.com/edde746/MPVKit'
existing_pkg = project.root_object.package_references.find do |p|
  p.repositoryURL == pkg_url rescue false
end

if existing_pkg
  puts "[skip] MPVKit SPM package already present"
else
  pkg = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  pkg.repositoryURL = pkg_url
  pkg.requirement = { 'kind' => 'branch', 'branch' => 'main' }
  project.root_object.package_references << pkg

  product = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  product.package = pkg
  product.product_name = 'MPVKit'
  runner_target.package_product_dependencies << product

  frameworks_phase = runner_target.frameworks_build_phase
  build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  build_file.product_ref = product
  frameworks_phase.files << build_file
  puts "[add ] MPVKit SPM package + framework linkage"
end

project.save
puts "Saved #{PROJECT_PATH}"
