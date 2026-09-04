#!/usr/bin/env ruby

require 'fileutils'
require 'json'
require 'minitest/autorun'
require 'open3'
require 'rbconfig'
require 'tmpdir'
require 'xcodeproj'

class WireMpvTest < Minitest::Test
  SOURCE_NAMES = %w[
    MpvPlayerCoreBase.swift
    MpvPlayerPluginShared.swift
    MpvPlayerCore.swift
    MpvPlayerPlugin.swift
    MpvPipController.swift
    MpvAudioPlayerCore.swift
    MpvAudioPlayerPlugin.swift
  ].freeze
  AFFECTED_NAMES = %w[
    MpvAudioPlayerCore.swift
    MpvAudioPlayerPlugin.swift
  ].freeze
  # Without a lock the pin may sit on either side of the MPVKit -> mpv-build
  # repo flip, as long as every site names the same repo; with a lock, the
  # lock names the repo and every site must match it.
  NATIVE_LOCATIONS = [
    'https://github.com/edde746/MPVKit',
    'https://github.com/edde746/mpv-build',
  ].freeze
  NATIVE_REVISION = /\A[0-9a-f]{40}\z/.freeze

  def setup
    @temporary_root = Dir.mktmpdir('wire-mpv-test')
    @tvos_root = File.join(@temporary_root, 'tvos')
    FileUtils.mkdir_p(File.join(@tvos_root, 'scripts'))
    FileUtils.cp_r(File.expand_path('../Runner.xcodeproj', __dir__), @tvos_root)
    FileUtils.cp(File.expand_path('wire_mpv.rb', __dir__), File.join(@tvos_root, 'scripts'))
  end

  def teardown
    FileUtils.remove_entry(@temporary_root)
  end

  def test_restores_missing_references_and_is_idempotent
    edit_project do |_project, _runner, group|
      AFFECTED_NAMES.each do |name|
        group.files.find { |file| file.display_name == name }&.remove_from_project
      end
    end

    run_wire_mpv
    run_wire_mpv
    assert_complete_source_graph
  end

  def test_restores_membership_when_references_remain
    edit_project do |_project, runner, group|
      affected = group.files.select { |file| AFFECTED_NAMES.include?(file.display_name) }
      runner.source_build_phase.files.each do |build_file|
        build_file.remove_from_project if affected.include?(build_file.file_ref)
      end
    end

    run_wire_mpv
    assert_complete_source_graph
  end

  def test_restores_missing_package_product_and_framework_edges
    edit_project do |_project, runner, _group|
      runner.package_product_dependencies
        .select { |product| product.product_name == 'MPVKit' }
        .each(&:remove_from_project)
    end

    run_wire_mpv
    assert_complete_source_graph
  end

  # After scripts/set_native_revision.sh flips the repo, a Flutter-regenerated
  # project still carries the old package reference; wire_mpv.rb must update it
  # in place from the lock instead of hardcoding one repo or adding a second
  # reference.
  def test_wire_updates_the_package_reference_across_the_repo_flip
    revision = flip_swiftpm_pin_to('edde746/mpv-build')
    write_repo_lock('edde746/mpv-build', revision)

    run_wire_mpv

    project = Xcodeproj::Project.open(project_path)
    references = project.root_object.package_references.select do |candidate|
      (candidate.repositoryURL rescue nil)
    end
    assert_equal 1, references.count, 'expected exactly one remote package reference'
    assert_equal 'https://github.com/edde746/mpv-build', references.first.repositoryURL
    assert_equal({ 'kind' => 'revision', 'revision' => revision }, references.first.requirement)
    assert_complete_source_graph
  end

  def test_wire_refuses_a_lock_that_disagrees_with_the_swiftpm_pin
    # Whichever side of the flip the copied pin sits on, name the other one.
    lock = JSON.parse(File.read(swiftpm_lock_path))
    pin = lock.fetch('pins').find { |candidate| %w[mpvkit mpv-build].include?(candidate['identity']) }
    refute_nil pin, 'copied lock has no native package pin'
    other = pin['identity'] == 'mpvkit' ? 'edde746/mpv-build' : 'edde746/MPVKit'
    write_repo_lock(other, 'f' * 40)

    output = run_wire_mpv_failure
    assert_match(/no #{Regexp.escape(File.basename(other).downcase)} pin/, output)
  end

  # The native package is pinned by commit so any upstream commit is
  # consumable without a release. Assert the shape and that every pin site
  # agrees, rather than a literal sha or repo: scripts/set_native_revision.sh
  # is the only thing that writes one, and it must stay the only file to edit
  # when the pin moves. The root mpv-build.lock.json is the same pin's
  # non-Apple carrier; once it exists it is the tenth site: it names the repo
  # every Apple site must point at and the commit they must all pin.
  def test_all_apple_targets_pin_the_native_package_to_one_commit
    repository_root = File.expand_path('../..', __dir__)
    lock_path = File.join(repository_root, 'mpv-build.lock.json')
    lock = File.exist?(lock_path) ? JSON.parse(File.read(lock_path)) : nil

    expected_locations =
      if lock
        assert_equal 1, lock['formatVersion'], "#{lock_path} formatVersion"
        assert_match %r{\A[\w.-]+/[\w.-]+\z}, lock['repo'].to_s, "#{lock_path} repo must name owner/name"
        assert_match NATIVE_REVISION, lock['commit'].to_s, "#{lock_path} commit"
        ["https://github.com/#{lock['repo']}"]
      else
        NATIVE_LOCATIONS
      end

    locations = {}
    revisions = {}

    %w[ios macos tvos].each do |platform|
      lock_paths = [
        File.join(repository_root, platform, 'Runner.xcworkspace', 'xcshareddata', 'swiftpm', 'Package.resolved'),
        File.join(
          repository_root, platform, 'Runner.xcodeproj', 'project.xcworkspace',
          'xcshareddata', 'swiftpm', 'Package.resolved'
        ),
      ]
      lock_paths.each do |resolved_path|
        resolved = JSON.parse(File.read(resolved_path))
        pin = resolved.fetch('pins').find { |candidate| expected_locations.include?(candidate['location']) }
        refute_nil pin, "#{resolved_path} must resolve the native package from #{expected_locations.join(' or ')}"
        assert_equal 'remoteSourceControl', pin['kind'], "#{resolved_path} native pin kind"
        assert_equal File.basename(pin['location']).downcase, pin['identity'],
                     "#{resolved_path} native pin identity must derive from its location"
        state = pin.fetch('state')
        assert_match NATIVE_REVISION, state['revision'].to_s, "#{resolved_path} native pin revision"
        refute state.key?('version'), "#{resolved_path} pins the native package by version; it must pin a commit"
        refute state.key?('branch'), "#{resolved_path} pins the native package by branch; it must pin a commit"
        locations[resolved_path] = pin['location']
        revisions[resolved_path] = state['revision']
      end

      project = Xcodeproj::Project.open(File.join(repository_root, platform, 'Runner.xcodeproj'))
      package = project.root_object.package_references.find do |candidate|
        expected_locations.include?((candidate.repositoryURL rescue nil))
      end
      refute_nil package, "#{platform} must reference the native package from #{expected_locations.join(' or ')}"
      requirement = package.requirement
      assert_equal 'revision', requirement['kind'], "#{platform} native requirement kind"
      assert_match NATIVE_REVISION, requirement['revision'].to_s, "#{platform} native requirement revision"
      locations[File.join(platform, 'Runner.xcodeproj')] = package.repositoryURL
      revisions[File.join(platform, 'Runner.xcodeproj')] = requirement['revision']
    end

    revisions[lock_path] = lock['commit'] if lock
    assert_equal 1, locations.values.uniq.count, "Apple targets disagree on the native repo: #{locations}"
    assert_equal 1, revisions.values.uniq.count, "Apple targets disagree on the native commit: #{revisions}"
  end

  private

  def project_path
    File.join(@tvos_root, 'Runner.xcodeproj')
  end

  def edit_project
    project = Xcodeproj::Project.open(project_path)
    runner = project.targets.find { |target| target.name == 'Runner' }
    group = project.main_group['Runner']['MpvPlayer']
    yield project, runner, group
    project.save
  end

  def run_wire_mpv
    script = File.join(@tvos_root, 'scripts', 'wire_mpv.rb')
    output, status = Open3.capture2e(RbConfig.ruby, script)
    assert status.success?, output
  end

  def run_wire_mpv_failure
    script = File.join(@tvos_root, 'scripts', 'wire_mpv.rb')
    output, status = Open3.capture2e(RbConfig.ruby, script)
    refute status.success?, "wire_mpv.rb unexpectedly succeeded:\n#{output}"
    output
  end

  def swiftpm_lock_path
    File.join(project_path, 'project.xcworkspace', 'xcshareddata', 'swiftpm', 'Package.resolved')
  end

  # Rewrites the copied project's SwiftPM pin to the given repo, returning the
  # pin's revision. Mirrors what set_native_revision.sh does to the real lock.
  def flip_swiftpm_pin_to(repo)
    lock = JSON.parse(File.read(swiftpm_lock_path))
    pin = lock.fetch('pins').find { |candidate| %w[mpvkit mpv-build].include?(candidate['identity']) }
    refute_nil pin, 'copied lock has no native package pin'
    pin['identity'] = File.basename(repo, '.git').downcase
    pin['location'] = "https://github.com/#{repo}"
    File.write(swiftpm_lock_path, JSON.pretty_generate(lock))
    pin.fetch('state').fetch('revision')
  end

  # The temp root stands in for the repository root: wire_mpv.rb resolves
  # mpv-build.lock.json two directories above itself.
  def write_repo_lock(repo, commit)
    File.write(
      File.join(@temporary_root, 'mpv-build.lock.json'),
      JSON.pretty_generate('formatVersion' => 1, 'repo' => repo, 'commit' => commit, 'artifacts' => {})
    )
  end

  def assert_complete_source_graph
    project = Xcodeproj::Project.open(project_path)
    runner = project.targets.find { |target| target.name == 'Runner' }
    group = project.main_group['Runner']['MpvPlayer']

    SOURCE_NAMES.each do |name|
      references = group.files.select { |file| file.display_name == name }
      assert_equal 1, references.count, "expected one reference for #{name}"
      memberships = runner.source_build_phase.files_references.count { |file| file == references.first }
      assert_equal 1, memberships, "expected one Runner source membership for #{name}"
    end

    products = runner.package_product_dependencies.select { |product| product.product_name == 'MPVKit' }
    assert_equal 1, products.count, 'expected one MPVKit product dependency'
    framework_links = runner.frameworks_build_phase.files.count { |file| file.product_ref == products.first }
    assert_equal 1, framework_links, 'expected one MPVKit framework link'
  end
end
