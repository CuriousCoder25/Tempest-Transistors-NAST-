import 'package:flutter/material.dart';

import '../theme.dart';

class CivicPanel extends StatelessWidget {
  const CivicPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = CivicColors.surface,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: CivicColors.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: child,
  );
}

class CivicIcon extends StatelessWidget {
  const CivicIcon(this.icon, {super.key, this.teal = false, this.size = 38});

  final IconData icon;
  final bool teal;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: teal ? CivicColors.tealLight : CivicColors.blueLight,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Icon(
      icon,
      size: size * .55,
      color: teal ? CivicColors.teal : CivicColors.navy,
    ),
  );
}

class CivicPage extends StatelessWidget {
  const CivicPage({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(child: CivicScroll(child: child)),
  );
}

class CivicScroll extends StatelessWidget {
  const CivicScroll({super.key, required this.child, this.controller});
  final Widget child;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: SingleChildScrollView(
        controller: controller,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: SizedBox(width: double.infinity, child: child),
      ),
    ),
  );
}

class ServiceHeading extends StatelessWidget {
  const ServiceHeading({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    this.teal = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool teal;

  @override
  Widget build(BuildContext context) => CivicPanel(
    color: teal ? CivicColors.tealLight : CivicColors.blueLight,
    child: Row(
      children: [
        CivicIcon(icon, teal: teal, size: 46),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 3),
              Text(detail, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}

class StatusPanel extends StatelessWidget {
  const StatusPanel({
    super.key,
    required this.title,
    required this.message,
    required this.valid,
  });
  final String title;
  final String message;
  final bool valid;

  @override
  Widget build(BuildContext context) {
    final color = valid ? CivicColors.green : CivicColors.red;
    return Semantics(
      liveRegion: true,
      child: CivicPanel(
        color: valid ? CivicColors.greenLight : CivicColors.redLight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              valid ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
