enum MusicVisualizerPreset { aurora, bloom, orbitals, prism, tunnel, trackMap }

extension MusicVisualizerPresetNavigation on MusicVisualizerPreset {
  MusicVisualizerPreset get next {
    final values = MusicVisualizerPreset.values;
    return values[(index + 1) % values.length];
  }

  MusicVisualizerPreset get previous {
    final values = MusicVisualizerPreset.values;
    return values[(index - 1 + values.length) % values.length];
  }
}
