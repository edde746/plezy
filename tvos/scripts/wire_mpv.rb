#!/usr/bin/env ruby
# Adds the Plezy MpvPlayer Swift sources and the native mpv Swift Package
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

# Swift Package: the native mpv package. Restore each graph edge independently
# so a project with a surviving package reference cannot silently omit the
# Runner linkage.
#
# The package is pinned by commit, not by version: the build repo publishes
# content-addressed binaries on every push to main, so a sha names the exact
# artifacts we link. The committed SwiftPM lock is the source of truth for that
# sha, so re-wiring can never revert a bump made by
# scripts/set_native_revision.sh.
#
# The repo itself is not hardcoded: mpv-build.lock.json names it when present
# (the same source of truth set_native_revision.sh writes); without one the
# script accepts either side of the MPVKit -> mpv-build flip, as long as the
# SwiftPM lock carries exactly one such pin. The SwiftPM identity of a pin is
# its URL basename, .git stripped, lowercased.
KNOWN_IDENTITIES = %w[mpvkit mpv-build].freeze

lock_path = File.join(PROJECT_PATH, 'project.xcworkspace', 'xcshareddata', 'swiftpm', 'Package.resolved')
raise "native package lock not found at #{lock_path}" unless File.exist?(lock_path)
pins = JSON.parse(File.read(lock_path)).fetch('pins', [])

repo_lock_path = File.expand_path('../../mpv-build.lock.json', __dir__)
if File.exist?(repo_lock_path)
  repo = JSON.parse(File.read(repo_lock_path)).fetch('repo')
  pkg_url = "https://github.com/#{repo}"
  pkg_identity = File.basename(repo, '.git').downcase
  lock_pin = pins.find { |candidate| candidate['identity'] == pkg_identity }
  raise "no #{pkg_identity} pin in #{lock_path} (mpv-build.lock.json names #{repo})" unless lock_pin
  location = lock_pin['location']
  unless location == pkg_url
    raise "#{lock_path} pins #{pkg_identity} at #{location}, but mpv-build.lock.json names #{pkg_url}"
  end
else
  candidates = pins.select { |candidate| KNOWN_IDENTITIES.include?(candidate['identity']) }
  raise "no native package pin in #{lock_path}" if candidates.empty?
  if candidates.size > 1
    raise "ambiguous native package pins in #{lock_path}: #{candidates.map { |c| c['identity'] }.join(', ')}"
  end
  lock_pin = candidates.first
  pkg_url = lock_pin.fetch('location')
  pkg_identity = lock_pin.fetch('identity')
end
pkg_name = File.basename(pkg_url, '.git')
pkg_revision = lock_pin.dig('state', 'revision')
unless pkg_revision.to_s.match?(/\A[0-9a-f]{40}\z/)
  raise "#{pkg_identity} pin in #{lock_path} has no full commit revision"
end
# Find the reference by the identity of its URL so a re-wire after the repo
# flip updates the surviving reference in place instead of adding a second one.
pkg = project.root_object.package_references.find do |candidate|
  url = (candidate.repositoryURL rescue nil)
  url && KNOWN_IDENTITIES.include?(File.basename(url, '.git').downcase)
end

if pkg.nil?
  pkg = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  pkg.repositoryURL = pkg_url
  project.root_object.package_references << pkg
  puts "[add ] #{pkg_name} SPM package reference"
elsif pkg.repositoryURL != pkg_url
  pkg.repositoryURL = pkg_url
  puts "[set ] #{pkg_name} SPM package URL #{pkg_url}"
end
pkg.requirement = { 'kind' => 'revision', 'revision' => pkg_revision }
puts "[set ] #{pkg_name} SPM package revision #{pkg_revision[0, 12]}"

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
