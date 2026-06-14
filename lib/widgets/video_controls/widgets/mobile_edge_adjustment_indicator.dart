import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/widgets/app_icon.dart';

import '../helpers/mobile_edge_adjustment_tracker.dart';

class MobileEdgeAdjustmentIndicator extends StatelessWidget {
  const MobileEdgeAdjustmentIndicator({super.key, required this.side, required this.value});

  final MobileEdgeAdjustmentSide side;
  final double value;

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0);
    final isLeft = side == MobileEdgeAdjustmentSide.left;
    final icon = side == MobileEdgeAdjustmentSide.left ? Symbols.brightness_6_rounded : Symbols.volume_up_rounded;
    final alignment = isLeft ? Alignment.centerLeft : Alignment.centerRight;
    final margin = isLeft ? const EdgeInsets.only(left: 20) : const EdgeInsets.only(right: 20);

    return SafeArea(
      minimum: margin,
      child: Align(
        alignment: alignment,
        child: _FilledPillIndicator(icon: icon, value: clampedValue),
      ),
    );
  }
}

class _FilledPillIndicator extends StatelessWidget {
  const _FilledPillIndicator({required this.icon, required this.value});

  final IconData icon;
  final double value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return Container(
          width: 54,
          height: 184,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.60),
            borderRadius: const BorderRadius.all(Radius.circular(27)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: Colors.white.withValues(alpha: 0.14)),
              Align(
                alignment: .bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: animatedValue,
                  widthFactor: 1,
                  alignment: .bottomCenter,
                  child: ColoredBox(color: Colors.white.withValues(alpha: 0.74)),
                ),
              ),
              _IndicatorContent(icon: icon, value: animatedValue, color: Colors.white),
              ClipRect(
                clipper: _BottomFractionClipper(animatedValue),
                child: _IndicatorContent(icon: icon, value: animatedValue, color: Colors.black.withValues(alpha: 0.86)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IndicatorContent extends StatelessWidget {
  const _IndicatorContent({required this.icon, required this.value, required this.color});

  final IconData icon;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: .min,
        children: [
          AppIcon(icon, fill: 1, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            '${(value * 100).round()}%',
            textAlign: .center,
            style: TextStyle(
              color: color,
              fontSize: 14,
              height: 1,
              fontWeight: .w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomFractionClipper extends CustomClipper<Rect> {
  const _BottomFractionClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) {
    final height = size.height * fraction.clamp(0.0, 1.0);
    return Rect.fromLTWH(0, size.height - height, size.width, height);
  }

  @override
  bool shouldReclip(_BottomFractionClipper oldClipper) => oldClipper.fraction != fraction;
}
