import 'dart:convert';
import '../models/pick_list_model.dart';

/// Parses a QR payload using one of:
///   1. Double-pipe positional: `<itemName>||<itemCode>||<batch>||<mfg>||<exp>`
///   2. Pipe key/value: `ITM|<code>|BCH|<batch>|SR|<serial>|MFG|<date>|EXP|<date>`
///   3. JSON object: `{"item":"...", "batch":"...", ...}`
///
/// Returns null when the payload is unrecognised.
ScanResult? parseQR(String? raw) {
  if (raw == null) return null;
  final s = raw.trim();
  if (s.isEmpty) return null;

  if (s.contains('||')) {
    final parts = s.split('||').map((p) => p.trim()).toList();
    if (parts.length >= 2) {
      final code = parts[1];
      if (code.isNotEmpty) {
        return ScanResult(
          itemCode: code,
          batch: parts.length > 2 ? _emptyToNull(parts[2]) : null,
          mfg: parts.length > 3 ? _emptyToNull(parts[3]) : null,
          exp: parts.length > 4 ? _emptyToNull(parts[4]) : null,
          raw: s,
        );
      }
    }
    return null;
  }

  if (s.contains('|')) {
    final parts = s.split('|');
    final out = <String, String>{};
    for (var i = 0; i < parts.length - 1; i += 2) {
      out[parts[i].trim().toUpperCase()] = parts[i + 1].trim();
    }
    final code = out['ITM'];
    if (code == null || code.isEmpty) return null;
    return ScanResult(
      itemCode: code,
      batch: _emptyToNull(out['BCH']),
      serial: _emptyToNull(out['SR']),
      mfg: _emptyToNull(out['MFG']),
      exp: _emptyToNull(out['EXP']),
      raw: s,
    );
  }

  try {
    final dynamic obj = jsonDecode(s);
    if (obj is! Map) return null;
    final code = obj['item'];
    if (code is! String || code.isEmpty) return null;
    return ScanResult(
      itemCode: code,
      batch: obj['batch'] as String?,
      serial: obj['serial'] as String?,
      mfg: obj['mfg'] as String?,
      exp: obj['exp'] as String?,
      raw: s,
    );
  } catch (_) {
    return null;
  }
}

String? _emptyToNull(String? v) =>
    (v == null || v.isEmpty) ? null : v;

/// Builds the canonical pipe-delimited payload used to render test QRs.
String buildQRPayload({
  required String itemCode,
  String? batch,
  required String serial,
}) {
  final buf = StringBuffer('ITM|$itemCode');
  if (batch != null && batch.isNotEmpty) {
    buf.write('|BCH|$batch');
  }
  buf.write('|SR|$serial');
  return buf.toString();
}
