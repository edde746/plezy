#!/usr/bin/env ruby
# Adds the Plezy MpvPlayer Swift sources and the MPVKit Swift Package
# dependency to tvos/Runner.xcodeproj so it matches the iOS project's
# linkage. Idempotent: re-running skips already-added entries.

require 'json'
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
  { name: 'MpvAudioPlayerCore.swift', path: '../shared/apple/MpvPlayer/MpvAudioPlayerCore.swift', tree: '<source_root>' },
  { name: 'MpvAudioPlayerPlugin.swift', path: '../shared/apple/MpvPlayer/MpvAudioPlayerPlugin.swift', tree: '<source_root>' },
]

sources_phase = runner_target.source_build_phase
sources.each do |src|
  ref = mpv_group.files.find { |file| file.display_name == src[:name] }
  unless ref
    ref = mpv_group.new_file(src[:path])
    ref.name = src[:name]
    ref.source_tree = src[:tree]
    puts "[add ] #{src[:name]} reference"
  end

  if sources_phase.files_references.include?(ref)
    puts "[skip] #{src[:name]} source membership already present"
  else
    sources_phase.add_file_reference(ref, true)
    puts "[add ] #{src[:name]} source membership"
  end
end

# Swift Package: MPVKit. Restore each graph edge independently so a project
# with a surviving package reference cannot silently omit the Runner linkage.
#
# MPVKit is pinned by commit, not by version: the fork publishes
# content-addressed binaries on every push to main, so a sha names the exact
# artifacts we link. The committed SwiftPM lock is the source of truth for that
# sha, so re-wiring can never revert a bump made by
# scripts/set_mpvkit_revision.sh.
pkg_url = 'https://github.com/edde746/MPVKit'
lock_path = File.join(PROJECT_PATH, 'project.xcworkspace', 'xcshareddata', 'swiftpm', 'Package.resolved')
raise "MPVKit lock not found at #{lock_path}" unless File.exist?(lock_path)
lock_pin = JSON.parse(File.read(lock_path)).fetch('pins', []).find do |candidate|
  candidate['identity'] == 'mpvkit'
end
raise "no mpvkit pin in #{lock_path}" unless lock_pin
pkg_revision = lock_pin.dig('state', 'revision')
unless pkg_revision.to_s.match?(/\A[0-9a-f]{40}\z/)
  raise "mpvkit pin in #{lock_path} has no full commit revision"
end
pkg = project.root_object.package_references.find do |candidate|
  candidate.repositoryURL == pkg_url rescue false
end

unless pkg
  pkg = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  pkg.repositoryURL = pkg_url
  project.root_object.package_references << pkg
  puts "[add ] MPVKit SPM package reference"
end
pkg.requirement = { 'kind' => 'revision', 'revision' => pkg_revision }
puts "[set ] MPVKit SPM package revision #{pkg_revision[0, 12]}"

product = runner_target.package_product_dependencies.find do |candidate|
  candidate.product_name == 'MPVKit'
end
unless product
  product = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  product.product_name = 'MPVKit'
  runner_target.package_product_dependencies << product
  puts "[add ] MPVKit Runner product dependency"
end
product.package = pkg

frameworks_phase = runner_target.frameworks_build_phase
unless frameworks_phase.files.any? { |build_file| build_file.product_ref == product }
  build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  build_file.product_ref = product
  frameworks_phase.files << build_file
  puts "[add ] MPVKit framework linkage"
end

project.save
puts "Saved #{PROJECT_PATH}"
