import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../i18n/presentation_formats.dart';
import '../../i18n/strings.g.dart';
import '../../services/settings_service.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/settings_page.dart';
import '../../widgets/settings_section.dart';
import 'settings_utils.dart';
import 'subtitle_style_preview.dart';

class SubtitleStylingScreen extends StatefulWidget {
  const SubtitleStylingScreen({super.key});

  @override
  State<SubtitleStylingScreen> createState() => _SubtitleStylingScreenState();
}

class _SubtitleStylingScreenState extends State<SubtitleStylingScreen> {
  SubtitleStylePreviewOverlay? _preview;

  @override
  void initState() {
    super.initState();
    // After the first frame: the root overlay this inserts into is an ancestor
    // that does not exist yet while initState runs.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _preview = SubtitleStylePreviewOverlay.insert(context);
    });
  }

  @override
  void dispose() {
    _preview?.remove();
    _preview = null;
    // A dialog still open when the screen goes away would never fire its own
    // end signal.
    clearSubtitleStylePreviewOverrides();
    super.dispose();
  }

  String _assOverrideLabel(SubAssOverride value) {
    return switch (value) {
      SubAssOverride.no => t.common.no,
      SubAssOverride.yes => t.common.yes,
      SubAssOverride.scale => t.subtitlingStyling.overrideScale,
      SubAssOverride.force => t.subtitlingStyling.overrideForce,
      SubAssOverride.strip => t.subtitlingStyling.overrideStrip,
    };
  }

  String _assOverrideDescription(SubAssOverride value) => switch (value) {
    SubAssOverride.no => t.subtitlingStyling.assOverrideOptions.no,
    SubAssOverride.yes => t.subtitlingStyling.assOverrideOptions.yes,
    SubAssOverride.scale => t.subtitlingStyling.assOverrideOptions.scale,
    SubAssOverride.force => t.subtitlingStyling.assOverrideOptions.force,
    SubAssOverride.strip => t.subtitlingStyling.assOverrideOptions.strip,
  };

  String _formatPosition(int value) {
    if (value == 0) return t.subtitlingStyling.positionTop;
    if (value == 100) return t.subtitlingStyling.positionBottom;
    return formatPercent(value / 100);
  }

  String _renderResolutionLabel(SubtitleRenderResolution value) {
    return switch (value) {
      SubtitleRenderResolution.screen => t.subtitlingStyling.renderResolutionScreen,
      SubtitleRenderResolution.video => t.subtitlingStyling.renderResolutionVideo,
      SubtitleRenderResolution.threeQuarter => '¾',
      SubtitleRenderResolution.half => '½',
      SubtitleRenderResolution.third => '⅓',
      SubtitleRenderResolution.quarter => '¼',
    };
  }

  String _renderResolutionDescription(SubtitleRenderResolution value) => switch (value) {
    SubtitleRenderResolution.screen => t.subtitlingStyling.renderResolutionOptions.screen,
    SubtitleRenderResolution.video => t.subtitlingStyling.renderResolutionOptions.video,
    SubtitleRenderResolution.threeQuarter => t.subtitlingStyling.renderResolutionOptions.threeQuarter,
    SubtitleRenderResolution.half => t.subtitlingStyling.renderResolutionOptions.half,
    SubtitleRenderResolution.third => t.subtitlingStyling.renderResolutionOptions.third,
    SubtitleRenderResolution.quarter => t.subtitlingStyling.renderResolutionOptions.quarter,
  };

  @override
  Widget build(BuildContext context) {
    // Each backend exposes its own text-subtitle placement preference.
    final exoActive = Platform.isAndroid && SettingsService.instance.read(SettingsService.useExoPlayer);
    return SettingsPage(
      title: Text(t.screens.subtitleStyling),
      children: [
        SettingsGroup(
          title: t.subtitlingStyling.text,
          children: [
            SettingSelectionTile<SubAssOverride>(
              pref: SettingsService.subAssOverride,
              icon: Symbols.subtitles_rounded,
              title: t.subtitlingStyling.assOverride,
              description: t.subtitlingStyling.assOverrideDescription,
              subtitleBuilder: _assOverrideLabel,
              options: SubAssOverride.values
                  .map((v) => DialogOption(value: v, title: _assOverrideLabel(v), subtitle: _assOverrideDescription(v)))
                  .toList(),
            ),
            // Apple avfoundation VO: screen vs video-resolution basis.
            if (Platform.isIOS || Platform.isMacOS)
              SettingSelectionTile<SubtitleRenderResolution>(
                pref: SettingsService.subtitleRenderResolution,
                icon: Symbols.aspect_ratio_rounded,
                title: t.subtitlingStyling.renderResolution,
                description: t.subtitlingStyling.renderResolutionDescription,
                subtitleBuilder: _renderResolutionLabel,
                options: const [SubtitleRenderResolution.screen, SubtitleRenderResolution.video]
                    .map(
                      (v) => DialogOption(
                        value: v,
                        title: _renderResolutionLabel(v),
                        subtitle: _renderResolutionDescription(v),
                      ),
                    )
                    .toList(),
              ),
            // Android libass overlay: full or a fractional render scale (perf knob for
            // render-bound low-end TVs; heavy/animated signs raster faster at < 1).
            if (Platform.isAndroid)
              SettingSelectionTile<SubtitleRenderResolution>(
                pref: SettingsService.subtitleRenderResolution,
                icon: Symbols.aspect_ratio_rounded,
                title: t.subtitlingStyling.renderResolution,
                description: t.subtitlingStyling.renderResolutionDescription,
                subtitleBuilder: _renderResolutionLabel,
                options:
                    const [
                          SubtitleRenderResolution.screen,
                          SubtitleRenderResolution.threeQuarter,
                          SubtitleRenderResolution.half,
                          SubtitleRenderResolution.third,
                          SubtitleRenderResolution.quarter,
                        ]
                        .map(
                          (v) => DialogOption(
                            value: v,
                            title: _renderResolutionLabel(v),
                            subtitle: _renderResolutionDescription(v),
                          ),
                        )
                        .toList(),
              ),
            SettingNumberTile(
              pref: SettingsService.subtitleFontSize,
              onPreview: (v) => setSubtitleStylePreviewOverride(SettingsService.subtitleFontSize.key, v),
              onPreviewEnd: () => setSubtitleStylePreviewOverride(SettingsService.subtitleFontSize.key, null),
              icon: Symbols.format_size_rounded,
              title: t.subtitlingStyling.fontSize,
              description: t.subtitlingStyling.fontSizeDescription,
              subtitleBuilder: (v) => formatDecimal(v, maximumDecimals: 0),

              labelText: t.subtitlingStyling.fontSize,
              suffixText: '',
            ),
            SettingColorTile(
              pref: SettingsService.subtitleTextColor,
              onPreview: (v) => setSubtitleStylePreviewOverride(SettingsService.subtitleTextColor.key, v),
              onPreviewEnd: () => setSubtitleStylePreviewOverride(SettingsService.subtitleTextColor.key, null),
              icon: Symbols.format_color_text_rounded,
              title: t.subtitlingStyling.textColor,
              description: t.subtitlingStyling.textColorDescription,
            ),
            SettingNumberTile(
              pref: SettingsService.subtitlePosition,
              onPreview: (v) => setSubtitleStylePreviewOverride(SettingsService.subtitlePosition.key, v),
              onPreviewEnd: () => setSubtitleStylePreviewOverride(SettingsService.subtitlePosition.key, null),
              icon: Symbols.vertical_align_bottom_rounded,
              title: t.subtitlingStyling.position,
              description: t.subtitlingStyling.positionDescription,
              subtitleBuilder: _formatPosition,
              labelText: t.subtitlingStyling.position,
              suffixText: '%',
            ),
            if (!exoActive)
              SettingSwitchTile(
                pref: SettingsService.subtitleUseMargins,
                icon: Symbols.fit_screen_rounded,
                title: t.subtitlingStyling.useMargins,
                subtitle: t.subtitlingStyling.useMarginsDescription,
              ),
            if (exoActive)
              SettingSwitchTile(
                pref: SettingsService.subtitleAnchorToScreen,
                icon: Symbols.fit_screen_rounded,
                title: t.subtitlingStyling.anchorToScreen,
                subtitle: t.subtitlingStyling.anchorToScreenDescription,
              ),
            SettingSwitchTile(
              pref: SettingsService.subtitleBold,
              icon: Symbols.format_bold_rounded,
              title: t.subtitlingStyling.bold,
              subtitle: t.subtitlingStyling.boldDescription,
            ),
            SettingSwitchTile(
              pref: SettingsService.subtitleItalic,
              icon: Symbols.format_italic_rounded,
              title: t.subtitlingStyling.italic,
              subtitle: t.subtitlingStyling.italicDescription,
            ),
          ],
        ),

        SettingsGroup(
          title: t.subtitlingStyling.border,
          children: [
            SettingNumberTile(
              pref: SettingsService.subtitleBorderSize,
              onPreview: (v) => setSubtitleStylePreviewOverride(SettingsService.subtitleBorderSize.key, v),
              onPreviewEnd: () => setSubtitleStylePreviewOverride(SettingsService.subtitleBorderSize.key, null),
              icon: Symbols.border_style_rounded,
              title: t.subtitlingStyling.borderSize,
              description: t.subtitlingStyling.borderSizeDescription,
              subtitleBuilder: (v) => formatDecimal(v, maximumDecimals: 0),

              labelText: t.subtitlingStyling.borderSize,
              suffixText: '',
            ),
            SettingColorTile(
              pref: SettingsService.subtitleBorderColor,
              onPreview: (v) => setSubtitleStylePreviewOverride(SettingsService.subtitleBorderColor.key, v),
              onPreviewEnd: () => setSubtitleStylePreviewOverride(SettingsService.subtitleBorderColor.key, null),
              icon: Symbols.border_color_rounded,
              title: t.subtitlingStyling.borderColor,
              description: t.subtitlingStyling.borderColorDescription,
            ),
          ],
        ),

        SettingsGroup(
          title: t.subtitlingStyling.background,
          children: [
            SettingNumberTile(
              pref: SettingsService.subtitleBackgroundOpacity,
              onPreview: (v) => setSubtitleStylePreviewOverride(SettingsService.subtitleBackgroundOpacity.key, v),
              onPreviewEnd: () => setSubtitleStylePreviewOverride(SettingsService.subtitleBackgroundOpacity.key, null),
              icon: Symbols.opacity_rounded,
              title: t.subtitlingStyling.backgroundOpacity,
              description: t.subtitlingStyling.backgroundOpacityDescription,
              subtitleBuilder: (v) => formatPercent(v / 100),
              labelText: t.subtitlingStyling.backgroundOpacity,
              suffixText: '%',
            ),
            SettingColorTile(
              pref: SettingsService.subtitleBackgroundColor,
              onPreview: (v) => setSubtitleStylePreviewOverride(SettingsService.subtitleBackgroundColor.key, v),
              onPreviewEnd: () => setSubtitleStylePreviewOverride(SettingsService.subtitleBackgroundColor.key, null),
              icon: Symbols.format_color_fill_rounded,
              title: t.subtitlingStyling.backgroundColor,
              description: t.subtitlingStyling.backgroundColorDescription,
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
