import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_constants.dart';

class GateInScreen extends StatefulWidget {
  const GateInScreen({super.key});

  @override
  State<GateInScreen> createState() => _GateInScreenState();
}

class _GateInScreenState extends State<GateInScreen> {
  final _formKey = GlobalKey<FormState>();

  final _gatePassDocCtrl = TextEditingController();
  final _totalQtyCtrl = TextEditingController();
  final _grossCtrl = TextEditingController();
  final _tareCtrl = TextEditingController();

  File? _slipPhoto;
  bool _submitting = false;

  late final Listenable _calcListenable = Listenable.merge(
    [_grossCtrl, _tareCtrl, _totalQtyCtrl],
  );

  @override
  void dispose() {
    _gatePassDocCtrl.dispose();
    _totalQtyCtrl.dispose();
    _grossCtrl.dispose();
    _tareCtrl.dispose();
    super.dispose();
  }

  double _toDouble(TextEditingController c) =>
      double.tryParse(c.text.trim()) ?? 0;

  double get _gross => _toDouble(_grossCtrl);
  double get _tare => _toDouble(_tareCtrl);
  double get _totalQty => _toDouble(_totalQtyCtrl);
  double get _netWeight => _gross - _tare;
  double get _totalWeight => _gross + _tare;

  bool get _netMatches =>
      _totalQtyCtrl.text.trim().isNotEmpty &&
      (_netWeight - _totalQty).abs() < 0.0001;

  bool get _totalWeightMatches =>
      _totalQtyCtrl.text.trim().isNotEmpty &&
      (_totalWeight - _totalQty).abs() < 0.0001;

  void _pickPhoto() {
    // Photo capture not wired yet — left as a stub so the form can be reviewed
    // before adding the image_picker dependency. Tap shows a notice for now.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo capture pending — add image_picker package'),
        backgroundColor: Color(0xFF8C7A6B),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_slipPhoto == null) {
      _toast('Attach weigh bridge slip photo', error: true);
      return;
    }
    if (!_netMatches) {
      _toast('Net weight must equal total qty', error: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      final photoBytes = await _slipPhoto!.readAsBytes();
      final payload = <String, dynamic>{
        'gate_pass_doc': _gatePassDocCtrl.text.trim(),
        'total_qty': _totalQty,
        'gross_weight': _gross,
        'tare_weight': _tare,
        'net_weight': _netWeight,
        'total_weight': _totalWeight,
        'slip_photo': {
          'filename': _slipPhoto!.path.split(Platform.pathSeparator).last,
          'mime': 'image/jpeg',
          'base64': base64Encode(photoBytes),
        },
      };

      // Print payload (base64 truncated so the log stays readable).
      final preview = Map<String, dynamic>.from(payload);
      final photo = Map<String, dynamic>.from(preview['slip_photo'] as Map);
      final b64 = photo['base64'] as String;
      photo['base64'] =
          '${b64.length > 64 ? '${b64.substring(0, 64)}…' : b64} (${b64.length} chars)';
      preview['slip_photo'] = photo;
      debugPrint('→ POST ${AppConstants.baseUrl}${AppConstants.gateEntry}');
      debugPrint('  body: ${const JsonEncoder.withIndent('  ').convert(preview)}');

      final response = await _postJson(
        Uri.parse(AppConstants.baseUrl + AppConstants.gateEntry),
        payload,
      );
      debugPrint('  response: $response');

      _toast('Gate entry saved', error: false);
      _formKey.currentState!.reset();
      _gatePassDocCtrl.clear();
      _totalQtyCtrl.clear();
      _grossCtrl.clear();
      _tareCtrl.clear();
      setState(() => _slipPhoto = null);
    } catch (e) {
      _toast('Submit failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<Map<String, dynamic>> _postJson(
    Uri uri,
    Map<String, dynamic> payload,
  ) async {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true;
    client.connectionTimeout = const Duration(seconds: 30);
    try {
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Accept', 'application/json');
      request.write(jsonEncode(payload));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      debugPrint('← ${response.statusCode} $uri');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode} — $body');
      }
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'raw': decoded};
    } finally {
      client.close(force: true);
    }
  }

  void _toast(String message, {required bool error}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error
            ? const Color(0xFFE5322B)
            : const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6EE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Gate Entry',
          style: TextStyle(
            color: Color(0xFF2A1B10),
            fontSize: 18,
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // _textField(
            //   controller: _gatePassDocCtrl,
            //   label: 'Gate Pass Doc Number',
            //   hint: 'e.g. GP-2026-0001',
            //   required: true,
            // ),
            _photoPicker(),
            _textField(
              controller: _totalQtyCtrl,
              label: 'Total Qty',
              hint: 'kg',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              numeric: true,
              required: true,
            ),
            _textField(
              controller: _grossCtrl,
              label: 'Gross Weight',
              hint: 'kg',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              numeric: true,
              required: true,
            ),
            _textField(
              controller: _tareCtrl,
              label: 'Tare Weight',
              hint: 'kg',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              numeric: true,
              required: true,
            ),
            ListenableBuilder(
              listenable: _calcListenable,
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // _netWeightField(),
                  _netSummary(),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF075A7A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Submit Gate Entry',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    bool numeric = false,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2A1B10),
              letterSpacing: 0.15,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: numeric
                ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
                : null,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFF1E4D0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFF1E4D0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF075A7A)),
              ),
            ),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (required && value.isEmpty) return 'Required';
              if (numeric && value.isNotEmpty && double.tryParse(value) == null) {
                return 'Enter a number';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _netWeightField() {
    final hasInputs = _grossCtrl.text.trim().isNotEmpty &&
        _tareCtrl.text.trim().isNotEmpty;
    final net = _netWeight;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Net Weight  (Gross − Tare)',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2A1B10),
                    letterSpacing: 0.15,
                  ),
                ),
              ),
              if (hasInputs)
                GestureDetector(
                  onTap: () {
                    _totalQtyCtrl.text = net.toStringAsFixed(3);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Use as Total Qty',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF075A7A),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F1E3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF1E4D0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasInputs ? net.toStringAsFixed(3) : '—',
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2A1B10),
                    ),
                  ),
                ),
                const Text(
                  'kg',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 12,
                    color: Color(0xFF8C7A6B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weigh Bridge Slip Photo',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2A1B10),
              letterSpacing: 0.15,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _slipPhoto != null
                      ? const Color(0xFF075A7A)
                      : const Color(0xFFF1E4D0),
                ),
              ),
              alignment: Alignment.center,
              child: _slipPhoto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _slipPhoto!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 32,
                          color: Color(0xFF8C7A6B),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Tap to attach slip photo',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 12,
                            color: Color(0xFF8C7A6B),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _netSummary() {
    final showMatch = _totalQtyCtrl.text.trim().isNotEmpty &&
        _grossCtrl.text.trim().isNotEmpty &&
        _tareCtrl.text.trim().isNotEmpty;
    final matches = _netMatches;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF1E4D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _calcRow('Gross', _gross),
          _calcRow('Tare', _tare),
          const Divider(height: 14, color: Color(0xFFF1E4D0)),
          _summaryRow('Net Weight  (Gross − Tare)', _netWeight),
          // const SizedBox(height: 4),
          // _summaryRow('Total Weight  (Gross + Tare)', _totalWeight),
          // if (showMatch) ...[
          //   const SizedBox(height: 8),
          //   Container(
          //     padding: const EdgeInsets.symmetric(
          //       horizontal: 10,
          //       vertical: 6,
          //     ),
          //     decoration: BoxDecoration(
          //       color: (matches
          //               ? const Color(0xFF4CAF50)
          //               : const Color(0xFFE5322B))
          //           .withValues(alpha: 0.1),
          //       borderRadius: BorderRadius.circular(8),
          //     ),
          //     child: Row(
          //       children: [
          //         Icon(
          //           matches ? Icons.check_circle : Icons.error_outline,
          //           size: 16,
          //           color: matches
          //               ? const Color(0xFF4CAF50)
          //               : const Color(0xFFE5322B),
          //         ),
          //         const SizedBox(width: 6),
          //         Expanded(
          //           child: Text(
          //             matches
          //                 ? 'Net weight matches total qty'
          //                 : 'Net ${_netWeight.toStringAsFixed(3)} ≠ Total ${_totalQty.toStringAsFixed(3)}',
          //             style: TextStyle(
          //               fontFamily: 'Fredoka',
          //               fontSize: 11,
          //               fontWeight: FontWeight.w700,
          //               color: matches
          //                   ? const Color(0xFF4CAF50)
          //                   : const Color(0xFFE5322B),
          //             ),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2A1B10),
            ),
          ),
        ),
        Text(
          value.toStringAsFixed(3),
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2A1B10),
          ),
        ),
      ],
    );
  }

  Widget _calcRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 12,
                color: Color(0xFF8C7A6B),
              ),
            ),
          ),
          Text(
            value.toStringAsFixed(3),
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
              color: Color(0xFF2A1B10),
            ),
          ),
        ],
      ),
    );
  }
}
