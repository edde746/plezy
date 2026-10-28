import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/settings_service.dart';
import '../../utils/language_codes.dart';
import '../../widgets/settings_page.dart';
import '../../widgets/settings_section.dart';

class SubtitleLanguageOrderScreen extends StatefulWidget {
  const SubtitleLanguageOrderScreen({super.key});

  @override
  State<SubtitleLanguageOrderScreen> createState() => _SubtitleLanguageOrderScreenState();
}

class _SubtitleLanguageOrderScreenState extends State<SubtitleLanguageOrderScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _error;
  String? _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await SettingsService.getInstance();
    if (!mounted) return;
    _controller.text = settings.read(SettingsService.subtitleLanguageOrder).join(', ');
    setState(() {});
  }

  List<String>? _parseOrder() {
    final raw = _controller.text
        .split(RegExp(r'[,;\s]+'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (raw.length > 12) {
      setState(() => _error = 'Use at most 12 language codes.');
      return null;
    }
    final normalized = <String>[];
    for (final value in raw) {
      final code = LanguageCodes.getIso6391Code(value);
      if (code == null) {
        setState(() => _error = '“$value” is not a supported language code.');
        return null;
      }
      if (!normalized.contains(code)) normalized.add(code);
    }
    return normalized;
  }

  Future<void> _save() async {
    final order = _parseOrder();
    if (order == null) return;
    setState(() {
      _saving = true;
      _error = null;
      _status = null;
    });
    try {
      final settings = await SettingsService.getInstance();
      await settings.write(SettingsService.subtitleLanguageOrder, order);
      if (mounted) setState(() => _status = order.isEmpty ? 'Language fallback order cleared.' : 'Language order saved.');
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save the subtitle language order.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clear() async {
    setState(() {
      _saving = true;
      _error = null;
      _status = null;
    });
    try {
      final settings = await SettingsService.getInstance();
      await settings.reset(SettingsService.subtitleLanguageOrder);
      _controller.clear();
      if (mounted) setState(() => _status = 'Language fallback order cleared.');
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not clear the subtitle language order.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: const Text('Preferred subtitle languages'),
      children: [
        SettingsGroup(
          title: 'Device-local fallback order',
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Enter ISO 639-1 language codes in priority order, separated by commas. '
                'The server profile language is checked first. This order is used when no matching server choice is available.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                enabled: !_saving,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Language codes',
                  hintText: 'en, es, ja',
                  errorText: _error,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {
                  _error = null;
                  _status = null;
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Wrap(
                spacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save order'),
                  ),
                  TextButton.icon(
                    onPressed: _saving ? null : _clear,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear'),
                  ),
                ],
              ),
            ),
            if (_status != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(_status!, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              ),
          ],
        ),
      ],
    );
  }
}
