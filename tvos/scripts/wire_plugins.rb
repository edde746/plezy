#!/usr/bin/env ruby
# Adds pure-Swift Flutter plugin sources to Runner target (no pods needed).
# Cleans up stale plugin file references left from earlier failed attempts.

require 'xcodeproj'

PROJECT_PATH = File.expand_path('../Runner.xcodeproj', __dir__)
project = Xcodeproj::Project.open(PROJECT_PATH)
runner = project.targets.find { |t| t.name == 'Runner' }
raise "Runner target not found" unless runner

# Names we want to own (anything with these basenames that's NOT part of
# MpvPlayer is a stale duplicate from earlier failed runs).
PLUGIN_BASENAMES = %w[
  SharedPreferencesPlugin.swift
  messages.g.swift
  PackageInfoPlusPlugin.swift
  PathProviderPlugin.swift
  GamepadPlugin.swift
  GamepadStreamHandler.swift
  GCControllerManager.swift
  ButtonMapping.swift
  DeviceInfoPlusPlugin.swift
  ConnectivityPlusPlugin.swift
  ConnectivityProvider.swift
  PathMonitorConnectivityProvider.swift
  OsMediaControlsPlugin.swift
]

# Remove any existing file refs for these basenames from the entire project.
project.files.select { |f| PLUGIN_BASENAMES.include?(f.display_name) }.each do |f|
  f.remove_from_project
end

# Drop any build files whose file_ref is now nil.
project.targets.each do |t|
  t.build_phases.each do |phase|
    next unless phase.respond_to?(:files)
    phase.files.delete_if { |bf| bf.file_ref.nil? }
  end
end

# Remove any empty Plugins groups.
runner_group = project.main_group['Runner']
if (prev = runner_group['Plugins'])
  prev.remove_from_project
end

# Fresh Plugins group, filesystem-aligned under tvos/Runner/Plugins.
plugins_group = runner_group.new_group('Plugins', 'Plugins')

plugins = {
  'shared_preferences_foundation' => %w[
    SharedPreferencesPlugin.swift
    messages.g.swift
  ],
  'package_info_plus' => %w[
    PackageInfoPlusPlugin.swift
  ],
  'path_provider' => %w[
    PathProviderPlugin.swift
  ],
  'universal_gamepad' => %w[
    GamepadPlugin.swift
    GamepadStreamHandler.swift
    GCControllerManager.swift
    ButtonMapping.swift
  ],
  'device_info_plus' => %w[
    DeviceInfoPlusPlugin.swift
  ],
  'connectivity_plus' => %w[
    ConnectivityPlusPlugin.swift
    ConnectivityProvider.swift
    PathMonitorConnectivityProvider.swift
  ],
  'os_media_controls' => %w[
    OsMediaControlsPlugin.swift
  ],
}

sources_phase = runner.source_build_phase
plugins.each do |plugin_name, files|
  sub = plugins_group.new_group(plugin_name, plugin_name)
  files.each do |fname|
    ref = sub.new_file(fname)
    sources_phase.add_file_reference(ref, true)
    puts "[add ] Runner/Plugins/#{plugin_name}/#{fname}"
  end
end

project.save
puts "Saved"
