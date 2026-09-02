#!/usr/bin/env ruby

require 'fileutils'
require 'minitest/autorun'
require 'open3'
require 'rbconfig'
require 'tmpdir'
require 'xcodeproj'

class WireTopShelfTest < Minitest::Test
  def setup
    @temporary_root = Dir.mktmpdir('wire-top-shelf-test')
    @tvos_root = File.join(@temporary_root, 'tvos')
    FileUtils.mkdir_p(File.join(@tvos_root, 'scripts'))
    FileUtils.cp_r(File.expand_path('../Runner.xcodeproj', __dir__), @tvos_root)
    FileUtils.cp_r(File.expand_path('../RunnerTests', __dir__), @tvos_root)
    FileUtils.cp(
      File.expand_path('wire_top_shelf.rb', __dir__),
      File.join(@tvos_root, 'scripts')
    )

    project = Xcodeproj::Project.open(project_path)
    runner = target(project, 'Runner')
    runner.build_configurations.each do |configuration|
      suffix = configuration.name.downcase
      if configuration.name == 'Profile'
        configuration.build_settings.delete('DEVELOPMENT_TEAM')
      else
        configuration.build_settings['DEVELOPMENT_TEAM'] = "TEAM-#{suffix}"
      end
      configuration.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "dev.plezy.#{suffix}"
    end
    %w[RunnerTests TopShelfExtension].each do |name|
      target(project, name).build_configurations.each do |configuration|
        configuration.build_settings['DEVELOPMENT_TEAM'] = 'STALE-TEAM'
        configuration.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'stale.bundle'
        configuration.build_settings['TVOS_DEPLOYMENT_TARGET'] = '14.0'
      end
    end
    project.save
  end

  def teardown
    FileUtils.remove_entry(@temporary_root)
  end

  def test_inherits_runner_identity_and_sets_supported_deployment_target
    run_wire_top_shelf
    run_wire_top_shelf

    project = Xcodeproj::Project.open(project_path)
    runner = target(project, 'Runner')
    runner_tests = target(project, 'RunnerTests')
    top_shelf = target(project, 'TopShelfExtension')

    runner.build_configurations.each do |runner_configuration|
      expected_team = runner_configuration.build_settings['DEVELOPMENT_TEAM']
      expected_bundle = runner_configuration.build_settings.fetch('PRODUCT_BUNDLE_IDENTIFIER')

      assert_generated_configuration(
        runner_tests,
        runner_configuration.name,
        expected_team,
        "#{expected_bundle}.RunnerTests"
      )
      assert_generated_configuration(
        top_shelf,
        runner_configuration.name,
        expected_team,
        "#{expected_bundle}.TopShelfExtension"
      )
    end

    assert_equal 1, project.targets.count { |candidate| candidate.name == 'RunnerTests' }
    assert_equal 1, project.targets.count { |candidate| candidate.name == 'TopShelfExtension' }
  end

  private

  def project_path
    File.join(@tvos_root, 'Runner.xcodeproj')
  end

  def target(project, name)
    project.targets.find { |candidate| candidate.name == name } || raise("#{name} target not found")
  end

  def run_wire_top_shelf
    script = File.join(@tvos_root, 'scripts', 'wire_top_shelf.rb')
    output, status = Open3.capture2e(RbConfig.ruby, script)
    assert status.success?, output
  end

  def assert_generated_configuration(target, name, expected_team, expected_bundle)
    configuration = target.build_configurations.find { |candidate| candidate.name == name }
    refute_nil configuration, "#{target.name} has no #{name} configuration"

    settings = configuration.build_settings
    if expected_team
      assert_equal expected_team, settings['DEVELOPMENT_TEAM']
    else
      assert_nil settings['DEVELOPMENT_TEAM']
    end
    assert_equal expected_bundle, settings['PRODUCT_BUNDLE_IDENTIFIER']
    assert_equal '15.0', settings['TVOS_DEPLOYMENT_TARGET']
  end
end
