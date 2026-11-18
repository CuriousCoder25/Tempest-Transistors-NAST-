enum HibTab {
  status('Check Policy Status', 'Status'),
  renewal('Renewal', 'Renewal'),
  enrollment('New Enrollment', 'Enrollment');

  const HibTab(this.title, this.label);
  final String title;
  final String label;
}

class ServiceDraft {
  const ServiceDraft({
    this.prefill = const {},
    this.explanations = const {},
    this.hibTab = HibTab.status,
  });

  final Map<String, String> prefill;
  final Map<String, String> explanations;
  final HibTab hibTab;

  String text(String key) => prefill[key] ?? '';
}

class DemoReceipt {
  const DemoReceipt(this.reference, this.title, this.createdAt);

  final String reference;
  final String title;
  final DateTime createdAt;
}
