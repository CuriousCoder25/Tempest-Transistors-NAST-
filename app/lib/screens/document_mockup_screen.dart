import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/catalog.dart';
import '../theme.dart';
import '../widgets/civic_widgets.dart';

class DocumentMockupScreen extends StatelessWidget {
  const DocumentMockupScreen({super.key, required this.document});
  final CivicDocument document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CivicPage(
      title: document.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CivicPanel(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: CivicColors.navy,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(11),
                    ),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/nepal-flag.png',
                        width: 25,
                        height: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              document.nepaliTitle,
                              style: const TextStyle(
                                fontFamily: 'Noto Sans Devanagari',
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              document.title,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              citizenPortrait,
                              width: 71,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Full name',
                                  style: theme.textTheme.bodySmall,
                                ),
                                Text(
                                  'Aarav Sharma',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  document.numberLabel,
                                  style: theme.textTheme.bodySmall,
                                ),
                                Text(
                                  document.number,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sample district',
                                  style: theme.textTheme.bodySmall,
                                ),
                                const Text('Kathmandu'),
                                const SizedBox(height: 8),
                                const Text(
                                  'DEMO MOCKUP',
                                  style: TextStyle(
                                    color: CivicColors.navy,
                                    letterSpacing: 1,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          QrImageView(
                            data:
                                'Nagarik Sathi demo | ${document.title} | ${document.number}',
                            size: 72,
                            padding: const EdgeInsets.all(3),
                            semanticsLabel:
                                'QR code containing fictional demo data',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This sample uses fictional details for the Nagarik Sathi demo.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
