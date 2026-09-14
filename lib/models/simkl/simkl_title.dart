import '../../utils/json_utils.dart';

/// Extracts displayable names from Simkl's localized-title objects.
///
/// Some endpoints instead return a bare list of strings, so both shapes are
/// accepted and malformed siblings are dropped.
List<String>? simklTitleNames(Object? raw) => stringListFromRaw(raw, mapKey: 'name', nullIfEmpty: true);
