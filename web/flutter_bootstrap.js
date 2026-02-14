{{flutter_js}}
{{flutter_build_config}}

// Initialize Flutter with webOS-optimized settings
_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    // Use CanvasKit renderer for better TV rendering quality
    const appRunner = await engineInitializer.initializeEngine({
      renderer: 'canvaskit',
      // Optimize for TV resolution
      hostElement: document.body,
    });

    // Remove loading indicator
    const loading = document.getElementById('loading');
    if (loading) {
      loading.style.display = 'none';
    }

    await appRunner.runApp();
  }
});
