import 'package:flutter/material.dart';

import '../models/catalog.dart' show normalizeDigits;
import '../models/service_draft.dart';
import '../services/demo_activity.dart';
import '../theme.dart';
import '../widgets/civic_widgets.dart';

enum RequestService {
  complaint(
    'Complaint (Gunaso)',
    'Report a local issue',
    'GNS',
    Icons.campaign_outlined,
  ),
  hib(
    'Health Insurance Board',
    'Health insurance',
    'HIB',
    Icons.health_and_safety_outlined,
  );

  const RequestService(this.title, this.heading, this.prefix, this.icon);

  final String title;
  final String heading;
  final String prefix;
  final IconData icon;
}

class ServiceRequestScreen extends StatefulWidget {
  const ServiceRequestScreen({
    super.key,
    required this.service,
    required this.activity,
    this.draft = const ServiceDraft(),
  });

  final RequestService service;
  final DemoActivity activity;
  final ServiceDraft draft;

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final _form = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _receipts = <HibTab, DemoReceipt>{};
  late HibTab _tab = widget.service == RequestService.complaint
      ? HibTab.status
      : widget.draft.hibTab;

  bool get _isHib => widget.service == RequestService.hib;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (_receipts.containsKey(_tab) || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _receipts[_tab] = widget.activity.record(
        prefix: widget.service.prefix,
        title: _isHib ? 'HIB · ${_tab.title}' : widget.service.title,
      );
    });
  }

  String? _validate(
    String? value, {
    required bool required,
    required bool ward,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return required ? 'This field is required.' : null;
    if (ward) {
      final number = int.tryParse(normalizeDigits(text));
      if (number == null || number < 1 || number > 99) {
        return 'Enter a ward number from 1 to 99.';
      }
    }
    return null;
  }

  Widget _field(
    String key,
    String label, {
    bool required = true,
    bool ward = false,
    int lines = 1,
  }) {
    final draft = widget.draft;
    final original = draft.text(key);
    final controller = _controllers.putIfAbsent(
      key,
      () => TextEditingController(text: original),
    );
    return Padding(
      key: ValueKey(key),
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          if (original.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 5),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: CivicColors.blueLight,
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text(
                'AI Draft — Please Review',
                style: TextStyle(
                  color: CivicColors.navy,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            validator: (value) =>
                _validate(value, required: required, ward: ward),
            keyboardType: ward
                ? TextInputType.number
                : lines > 1
                ? TextInputType.multiline
                : null,
            maxLines: lines,
            maxLength: lines > 1 ? 1200 : 240,
            decoration: InputDecoration(hintText: label, counterText: ''),
          ),
          if (draft.explanations[key] case final String explanation)
            Padding(
              padding: const EdgeInsets.only(left: 3, top: 5),
              child: Text(
                explanation,
                style: const TextStyle(
                  fontFamily: 'Noto Sans Devanagari',
                  fontSize: 12,
                  color: CivicColors.muted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _fields() {
    if (!_isHib) {
      return [
        _field('category', 'Category'),
        _field('ward_number', 'Ward number', ward: true),
        _field('description', 'Problem description', lines: 4),
      ];
    }
    final draft = widget.draft;
    return [
      if (_tab != HibTab.enrollment || draft.text('policy_id').isNotEmpty)
        _field('policy_id', 'Policy ID', required: _tab != HibTab.enrollment),
      if (_tab != HibTab.status || draft.text('district').isNotEmpty)
        _field('district', 'District', required: _tab != HibTab.status),
      if (_tab == HibTab.enrollment || draft.text('family_details').isNotEmpty)
        _field(
          'family_details',
          'Family details',
          lines: 3,
          required: _tab == HibTab.enrollment,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    return CivicPage(
      title: service.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ServiceHeading(
            icon: service.icon,
            title: service.heading,
            teal: _isHib,
            detail:
                'Practice form. Confirming creates a demo receipt on this device.',
          ),
          const SizedBox(height: 14),
          if (_isHib) ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final tab in HibTab.values)
                  ChoiceChip(
                    label: Text(tab.label),
                    selected: _tab == tab,
                    selectedColor: CivicColors.tealLight,
                    checkmarkColor: CivicColors.teal,
                    backgroundColor: CivicColors.surface,
                    side: const BorderSide(color: CivicColors.border),
                    onSelected: (selected) {
                      if (!selected) return;
                      FocusScope.of(context).unfocus();
                      setState(() => _tab = tab);
                    },
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: Text(
                _tab.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
          if (_receipts[_tab] case final DemoReceipt receipt)
            StatusPanel(
              title: 'Demo receipt created',
              valid: true,
              message: '${receipt.title}\nReference ${receipt.reference}',
            )
          else
            CivicPanel(
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ..._fields(),
                    FilledButton(
                      onPressed: _submit,
                      child: const Text('Confirm & Submit'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
