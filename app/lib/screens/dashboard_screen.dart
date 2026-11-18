import 'package:flutter/material.dart';

import '../models/catalog.dart';
import '../services/demo_activity.dart';
import '../theme.dart';
import '../widgets/civic_widgets.dart';
import '../widgets/nagarik_ai.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.activity});
  final DemoActivity activity;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _search = TextEditingController();
  int _tab = 0;
  String _query = '';
  bool _assistantOpen = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(String value) => value.toLowerCase().contains(_query);

  Future<void> _openAssistant() async {
    if (_assistantOpen) return;
    _assistantOpen = true;
    try {
      await Navigator.pushNamed(context, '/assistant');
    } finally {
      _assistantOpen = false;
    }
  }

  void _profile() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Citizen profile'),
        content: const Row(
          children: [
            CircleAvatar(
              radius: 27,
              backgroundImage: AssetImage(citizenPortrait),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [Text('Aarav Sharma'), Text('Demo citizen')],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _documents(Iterable<CivicDocument> documents) => _TileGroup(
    tiles: [
      for (final item in documents)
        _Tile(
          title: item.title,
          icon: item.icon,
          onTap: () =>
              Navigator.pushNamed(context, '/document', arguments: item),
        ),
    ],
  );

  Widget _home() {
    final services = CivicService.values.where(
      (item) => _matches('${item.title} ${item.subtitle} ${item.nepaliTitle}'),
    );
    final docs = CivicDocument.values.where(
      (item) => _matches('${item.title} ${item.nepaliTitle}'),
    );
    final social = SocialService.values.where((item) => _matches(item.title));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _search,
          onChanged: (value) =>
              setState(() => _query = value.trim().toLowerCase()),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search for a service',
            prefixIcon: const Icon(
              Icons.search,
              color: CivicColors.muted,
              size: 22,
            ),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _search.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        if (_query.isEmpty) ...[
          const SizedBox(height: 14),
          CivicPanel(
            color: CivicColors.blueLight,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, Aarav',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Access your documents and local services.',
                        style: TextStyle(color: CivicColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.account_balance_outlined,
                  size: 50,
                  color: CivicColors.navy,
                ),
              ],
            ),
          ),
        ],
        if (services.isNotEmpty) ...[
          const _SectionTitle('Voice-enabled services'),
          _TileGroup(
            tiles: [
              for (final item in services)
                _Tile(
                  title: item.title,
                  subtitle: item.subtitle,
                  icon: item.icon,
                  voice: true,
                  teal: item == CivicService.hib,
                  onTap: () => Navigator.pushNamed(context, item.route),
                ),
            ],
          ),
        ],
        if (docs.isNotEmpty) ...[
          const _SectionTitle('Documents'),
          _documents(docs),
        ],
        if (social.isNotEmpty) ...[
          const _SectionTitle('Social services'),
          _TileGroup(
            tiles: [
              for (final item in social)
                _Tile(
                  title: item.title,
                  icon: item.icon,
                  onTap: () =>
                      Navigator.pushNamed(context, '/social', arguments: item),
                ),
            ],
          ),
        ],
        if (services.isEmpty && docs.isEmpty && social.isEmpty) ...[
          const SizedBox(height: 16),
          const CivicPanel(child: Text('No services match your search.')),
        ],
      ],
    );
  }

  Widget _activity() => ListenableBuilder(
    listenable: widget.activity,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Activity'),
        if (widget.activity.receipts.isEmpty)
          const ServiceHeading(
            icon: Icons.history,
            title: 'No activity yet',
            detail: 'Confirmed demo requests will appear here.',
          ),
        for (final receipt in widget.activity.receipts)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CivicPanel(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CivicIcon(Icons.receipt_long_outlined),
                title: Text(receipt.title),
                subtitle: Text(receipt.reference),
                trailing: Text(
                  MaterialLocalizations.of(
                    context,
                  ).formatShortDate(receipt.createdAt),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final body = switch (_tab) {
      0 => _home(),
      1 => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Documents'),
          _documents(CivicDocument.values),
        ],
      ),
      2 => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Notifications'),
          ServiceHeading(
            icon: Icons.notifications_none,
            title: 'No new notifications',
            detail: 'Service notices will appear here.',
          ),
        ],
      ),
      _ => _activity(),
    };
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 3),
                child: Row(
                  children: [
                    const CivicIcon(Icons.account_balance_outlined, size: 42),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nagarik Sathi',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Text(
                            'नागरिक साथी',
                            style: TextStyle(
                              fontFamily: 'Noto Sans Devanagari',
                              fontSize: 12,
                              color: CivicColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Citizen profile, Aarav Sharma',
                      onPressed: _profile,
                      icon: const CircleAvatar(
                        radius: 18,
                        backgroundImage: AssetImage(citizenPortrait),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: CivicScroll(key: ValueKey(_tab), child: body),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _CivicNavigation(
        active: _tab,
        onSelected: (index) => setState(() => _tab = index),
        onOpenAssistant: _openAssistant,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Semantics(
      header: true,
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    ),
  );
}

class _TileGroup extends StatelessWidget {
  const _TileGroup({required this.tiles});
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scaled = MediaQuery.textScalerOf(context).scale(14);
      final columns = constraints.maxWidth < 285 || scaled > 20 ? 2 : 3;
      const gap = 8.0;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final tile in tiles) SizedBox(width: width, child: tile),
        ],
      );
    },
  );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.voice = false,
    this.teal = false,
  });
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool voice;
  final bool teal;

  @override
  Widget build(BuildContext context) => Material(
    color: CivicColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: CivicColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: voice ? 131 : 96),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CivicIcon(icon, teal: teal, size: 35),
                  if (voice)
                    const Tooltip(
                      message: 'Voice-enabled',
                      child: Icon(
                        Icons.mic_none,
                        size: 17,
                        color: CivicColors.muted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: CivicColors.ink,
                  fontSize: 12.5,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null)
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CivicNavigation extends StatelessWidget {
  const _CivicNavigation({
    required this.active,
    required this.onSelected,
    required this.onOpenAssistant,
  });
  final int active;
  final ValueChanged<int> onSelected;
  final VoidCallback onOpenAssistant;

  static const _tabs = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.folder_outlined, Icons.folder_rounded, 'Document'),
    (Icons.notifications_none, Icons.notifications_rounded, 'Notification'),
    (Icons.history, Icons.history, 'Activity'),
  ];

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.topCenter,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 14),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: CivicColors.surface,
            border: Border(top: BorderSide(color: CivicColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Material(
                  color: CivicColors.surface,
                  child: Row(
                    children: [
                      for (final (index, tab) in _tabs.indexed) ...[
                        if (index == 2)
                          const SizedBox(width: NagarikAiRibbon.width),
                        Expanded(child: _tab(index, tab)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      NagarikAiRibbon(onPressed: onOpenAssistant),
    ],
  );

  Widget _tab(int index, (IconData, IconData, String) tab) {
    final selected = index == active;
    final color = selected ? CivicColors.navy : CivicColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: () => onSelected(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 26,
                decoration: BoxDecoration(
                  color: selected ? CivicColors.blueLight : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(selected ? tab.$2 : tab.$1, size: 20, color: color),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  tab.$3,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
