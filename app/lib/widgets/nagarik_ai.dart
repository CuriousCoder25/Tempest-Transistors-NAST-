import 'package:flutter/material.dart';

import '../theme.dart';

const nagarikAiName = 'Nagarik AI';

class NagarikAiMark extends StatelessWidget {
  const NagarikAiMark({super.key, required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => ClipOval(
    child: Image.asset(
      'assets/images/nagarik-ai-logo.png',
      width: size,
      height: size,
      excludeFromSemantics: true,
    ),
  );
}

class NagarikAiRibbon extends StatelessWidget {
  const NagarikAiRibbon({super.key, required this.onPressed});

  static const width = 88.0;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Material(
      type: MaterialType.transparency,
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: CivicColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: CivicColors.navy),
                  ),
                  child: const NagarikAiMark(size: 44),
                ),
                const SizedBox(height: 3),
                Text(
                  nagarikAiName,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: CivicColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class NagarikAiListeningMark extends StatefulWidget {
  const NagarikAiListeningMark({
    super.key,
    required this.listening,
    required this.amplitude,
  });
  final bool listening;
  final double amplitude;

  @override
  State<NagarikAiListeningMark> createState() => _NagarikAiListeningMarkState();
}

class _NagarikAiListeningMarkState extends State<NagarikAiListeningMark>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updatePulse();
  }

  @override
  void didUpdateWidget(NagarikAiListeningMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listening != widget.listening) _updatePulse();
  }

  void _updatePulse() {
    if (widget.listening && !MediaQuery.disableAnimationsOf(context)) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 60,
    child: CustomPaint(
      painter: widget.listening
          ? _ListeningRings(_pulse, widget.amplitude)
          : null,
      child: const Center(child: NagarikAiMark(size: 36)),
    ),
  );
}

class _ListeningRings extends CustomPainter {
  _ListeningRings(this.phase, this.amplitude) : super(repaint: phase);

  final Animation<double> phase;
  final double amplitude;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final offset in [0.0, .5]) {
      final progress = (phase.value + offset) % 1;
      final radius = 19 + 3 * amplitude + 7 * progress;
      ring.color = CivicColors.navy.withValues(
        alpha: (.23 + .22 * amplitude) * (1 - progress),
      );
      canvas.drawCircle(center, radius, ring);
    }
  }

  @override
  bool shouldRepaint(_ListeningRings oldDelegate) =>
      oldDelegate.amplitude != amplitude || oldDelegate.phase != phase;
}
