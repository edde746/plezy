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
  MPVKIT_PIN = {
    'location' => 'https://github.com/edde746/MPVKit',
    'revision' => '39df1216941c1442e9163d2a574ca37ef2c2b4ff',
    'version' => '1.0.16',
  }.freeze

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

  def test_all_apple_targets_resolve_the_same_mpvkit_source
    repository_root = File.expand_path('../..', __dir__)
    %w[ios macos tvos].each do |platform|
      resolved_path =
        File.join(
          repository_root,
          platform,
          'Runner.xcworkspace',
          'xcshareddata',
          'swiftpm',
          'Package.resolved'
        )
      resolved = JSON.parse(File.read(resolved_path))
      pin = resolved.fetch('pins').find { |candidate| candidate.fetch('identity') == 'mpvkit' }
      refute_nil pin, "#{platform} must resolve MPVKit"
      assert_equal MPVKIT_PIN['location'], pin['location'], "#{platform} MPVKit source"
      assert_equal MPVKIT_PIN['revision'], pin.dig('state', 'revision'), "#{platform} MPVKit revision"
      assert_equal MPVKIT_PIN['version'], pin.dig('state', 'version'), "#{platform} MPVKit version"
    end
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
