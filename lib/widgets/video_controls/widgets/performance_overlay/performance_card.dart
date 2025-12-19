import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';

/// A single metric row for display in the performance card.
class PerformanceMetric {
  final String label;
  final String value;

  const PerformanceMetric({required this.label, required this.value});
}

/// A card widget displaying a group of performance metrics.
///
/// Used in the performance overlay to show video, audio, performance,
/// and buffer statistics.
class PerformanceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<PerformanceMetric> metrics;

  const PerformanceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row with icon and title
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(icon, fill: 1, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Metrics
          ...metrics.map(_buildMetricRow),
        ],
      ),
    );
  }

  Widget _buildMetricRow(PerformanceMetric metric) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${metric.label}: ',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
          Text(
            metric.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
