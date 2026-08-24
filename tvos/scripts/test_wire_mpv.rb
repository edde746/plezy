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
  MPVKIT_LOCATION = 'https://github.com/edde746/MPVKit'
  MPVKIT_REVISION = /\A[0-9a-f]{40}\z/.freeze

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

  # MPVKit is pinned by commit so any upstream commit is consumable without a
  # release. Assert the shape and that every pin site agrees, rather than a
  # literal sha: scripts/set_mpvkit_revision.sh is the only thing that writes
  # one, and it must stay the only file to edit when the pin moves.
  def test_all_apple_targets_pin_mpvkit_to_one_commit
    repository_root = File.expand_path('../..', __dir__)
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
        pin = resolved.fetch('pins').find { |candidate| candidate.fetch('identity') == 'mpvkit' }
        refute_nil pin, "#{resolved_path} must resolve MPVKit"
        assert_equal MPVKIT_LOCATION, pin['location'], "#{resolved_path} MPVKit source"
        state = pin.fetch('state')
        assert_match MPVKIT_REVISION, state['revision'].to_s, "#{resolved_path} MPVKit revision"
        refute state.key?('version'), "#{resolved_path} pins MPVKit by version; it must pin a commit"
        refute state.key?('branch'), "#{resolved_path} pins MPVKit by branch; it must pin a commit"
        revisions[resolved_path] = state['revision']
      end

      project = Xcodeproj::Project.open(File.join(repository_root, platform, 'Runner.xcodeproj'))
      package = project.root_object.package_references.find do |candidate|
        (candidate.repositoryURL rescue nil) == MPVKIT_LOCATION
      end
      refute_nil package, "#{platform} must reference MPVKit"
      requirement = package.requirement
      assert_equal 'revision', requirement['kind'], "#{platform} MPVKit requirement kind"
      assert_match MPVKIT_REVISION, requirement['revision'].to_s, "#{platform} MPVKit requirement revision"
      revisions[File.join(platform, 'Runner.xcodeproj')] = requirement['revision']
    end

    assert_equal 1, revisions.values.uniq.count, "Apple targets disagree on the MPVKit commit: #{revisions}"
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
