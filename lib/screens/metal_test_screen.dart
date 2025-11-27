import 'dart:io';

import 'package:flutter/material.dart';

import '../services/native_video_service.dart';

/// Test screen to verify the Metal layer transparency works correctly.
/// This screen shows the native Metal layer behind transparent Flutter UI.
class MetalTestScreen extends StatefulWidget {
  const MetalTestScreen({super.key});

  @override
  State<MetalTestScreen> createState() => _MetalTestScreenState();
}

class _MetalTestScreenState extends State<MetalTestScreen> {
  final NativeVideoService _nativeVideoService = NativeVideoService();
  bool _isInitialized = false;
  bool _isVisible = false;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initNativeVideo();
  }

  Future<void> _initNativeVideo() async {
    if (!Platform.isMacOS) {
      setState(() {
        _statusMessage = 'Metal layer only available on macOS';
      });
      return;
    }

    setState(() {
      _statusMessage = 'Initializing Metal layer...';
    });

    final initialized = await _nativeVideoService.initialize();

    if (initialized) {
      // Show the Metal layer
      final visible = await _nativeVideoService.setVisible(true);
      setState(() {
        _isInitialized = true;
        _isVisible = visible;
        _statusMessage = visible
            ? 'Metal layer visible - you should see a rotating triangle!'
            : 'Failed to show Metal layer';
      });
    } else {
      setState(() {
        _statusMessage = 'Failed to initialize Metal layer';
      });
    }
  }

  Future<void> _toggleVisibility() async {
    final newVisibility = !_isVisible;
    final success = await _nativeVideoService.setVisible(newVisibility);
    if (success) {
      setState(() {
        _isVisible = newVisibility;
      });
    }
  }

  @override
  void dispose() {
    // Hide the Metal layer when leaving
    _nativeVideoService.setVisible(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IMPORTANT: Transparent background to see Metal layer behind
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Metal Layer Test'),
        backgroundColor: Colors.black.withOpacity(0.7),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isVisible ? Icons.visibility : Icons.visibility_off,
                size: 64,
                color: _isVisible ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 24),
              Text(
                'Metal Layer Status',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildStatusRow('Platform', Platform.operatingSystem),
                    _buildStatusRow('Initialized', _isInitialized ? 'Yes' : 'No'),
                    _buildStatusRow('Visible', _isVisible ? 'Yes' : 'No'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                style: TextStyle(
                  color: _isVisible ? Colors.green[300] : Colors.orange[300],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_isInitialized) ...[
                ElevatedButton.icon(
                  onPressed: _toggleVisibility,
                  icon: Icon(_isVisible ? Icons.visibility_off : Icons.visibility),
                  label: Text(_isVisible ? 'Hide Metal Layer' : 'Show Metal Layer'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'If working correctly, you should see a\nrotating RGB triangle behind this panel.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
