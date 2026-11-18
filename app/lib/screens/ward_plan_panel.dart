import 'package:flutter/material.dart';

import '../models/assistant_reply.dart';
import '../theme.dart';
import '../widgets/civic_widgets.dart';

class WardPlanPanel extends StatefulWidget {
  const WardPlanPanel({super.key, required this.plan});
  final WardPlan plan;

  @override
  State<WardPlanPanel> createState() => _WardPlanPanelState();
}

class _WardPlanPanelState extends State<WardPlanPanel> {
  late final _checked = [for (final item in widget.plan.checklist) item.have];

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final theme = Theme.of(context);
    final done = _checked.where((value) => value).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CivicPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(plan.service, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(plan.message),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CivicPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customized checklist', style: theme.textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                '$done of ${_checked.length} ready',
                style: theme.textTheme.bodySmall,
              ),
              for (final (index, item) in plan.checklist.indexed)
                CheckboxListTile(
                  value: _checked[index],
                  activeColor: CivicColors.green,
                  onChanged: (checked) =>
                      setState(() => _checked[index] = checked ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(item.label),
                  subtitle: Text(
                    '${_checked[index] ? 'भएको' : 'बाँकी'} · PDF p. ${item.page}',
                    style: TextStyle(
                      color: _checked[index]
                          ? CivicColors.green
                          : CivicColors.muted,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CivicPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ward Office roadmap', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              for (final (index, step) in plan.steps.indexed) ...[
                if (index != 0) const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 13,
                        foregroundColor: CivicColors.navy,
                        backgroundColor: CivicColors.blueLight,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(step.instruction),
                            if (step.fee != null) Text('शुल्क · ${step.fee}'),
                            if (step.timeline != null)
                              Text('समय · ${step.timeline}'),
                            Text(
                              'PDF p. ${step.page}'
                              '${step.feePage != null && step.feePage != step.page ? ' · Fee p. ${step.feePage}' : ''}'
                              '${step.timelinePage != null && step.timelinePage != step.page ? ' · Time p. ${step.timelinePage}' : ''}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
