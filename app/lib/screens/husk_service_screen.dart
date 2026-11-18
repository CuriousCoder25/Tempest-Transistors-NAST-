import 'package:flutter/material.dart';

import '../models/catalog.dart';
import '../widgets/civic_widgets.dart';

class HuskServiceScreen extends StatefulWidget {
  const HuskServiceScreen({super.key, required this.service});
  final SocialService service;

  @override
  State<HuskServiceScreen> createState() => _HuskServiceScreenState();
}

class _HuskServiceScreenState extends State<HuskServiceScreen> {
  final _number = TextEditingController();
  bool? _valid;

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  void _check() {
    FocusScope.of(context).unfocus();
    setState(
      () =>
          _valid = widget.service.accepts(normalizeDigits(_number.text.trim())),
    );
  }

  @override
  Widget build(BuildContext context) => CivicPage(
    title: widget.service.title,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ServiceHeading(
          icon: widget.service.icon,
          title: 'Check number format',
          detail: 'Enter a sample number to run a format check on this device.',
        ),
        const SizedBox(height: 14),
        CivicPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _number,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: widget.service.fieldLabel,
                  helperText: widget.service.formatHint,
                ),
                onChanged: (_) {
                  if (_valid != null) setState(() => _valid = null);
                },
                onSubmitted: (_) => _check(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _check,
                child: const Text('Check / Submit'),
              ),
            ],
          ),
        ),
        if (_valid case final bool valid) ...[
          const SizedBox(height: 12),
          StatusPanel(
            valid: valid,
            title: valid ? 'Valid format' : 'Check the number',
            message: valid
                ? 'The number passes the demo format check.'
                : widget.service.formatHint,
          ),
        ],
      ],
    ),
  );
}
