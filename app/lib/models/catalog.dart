import 'package:flutter/material.dart';

String normalizeDigits(String text) {
  const nepaliDigits = '०१२३४५६७८९';
  return text.replaceAllMapped(
    RegExp('[०-९]'),
    (match) => nepaliDigits.indexOf(match[0]!).toString(),
  );
}

enum CivicService {
  complaint(
    'Complaint',
    'Gunaso',
    'गुनासो',
    Icons.campaign_outlined,
    '/complaint',
  ),
  hib(
    'Health Insurance Board',
    'HIB',
    'स्वास्थ्य बीमा',
    Icons.health_and_safety_outlined,
    '/hib',
  ),
  ward(
    'Ward Office',
    'Helpdesk',
    'वडा कार्यालय',
    Icons.account_balance_outlined,
    '/ward',
  );

  const CivicService(
    this.title,
    this.subtitle,
    this.nepaliTitle,
    this.icon,
    this.route,
  );

  final String title;
  final String subtitle;
  final String nepaliTitle;
  final IconData icon;
  final String route;
}

enum CivicDocument {
  nationalId(
    'national_id',
    'National ID',
    'राष्ट्रिय परिचयपत्र',
    Icons.badge_outlined,
    'NID-DEMO-0001',
    'National identity number',
  ),
  drivingLicense(
    'driving_license',
    'Driving License',
    'सवारी चालक अनुमतिपत्र',
    Icons.directions_car_outlined,
    'DL-DEMO-0002',
    'License number',
  ),
  pan(
    'pan',
    'PAN',
    'स्थायी लेखा नम्बर',
    Icons.receipt_long_outlined,
    '100000003',
    'Permanent account number',
  ),
  citizenship(
    'citizenship',
    'Citizenship',
    'नागरिकता प्रमाणपत्र',
    Icons.verified_user_outlined,
    'CTZ-DEMO-0004',
    'Certificate number',
  ),
  passport(
    'passport',
    'Passport',
    'राहदानी',
    Icons.language_outlined,
    'P-DEMO-0005',
    'Passport number',
  ),
  voterId(
    'voter_id',
    'Voter ID',
    'मतदाता परिचयपत्र',
    Icons.how_to_vote_outlined,
    'VT-DEMO-0006',
    'Voter number',
  );

  const CivicDocument(
    this.id,
    this.title,
    this.nepaliTitle,
    this.icon,
    this.number,
    this.numberLabel,
  );

  final String id;
  final String title;
  final String nepaliTitle;
  final IconData icon;
  final String number;
  final String numberLabel;
}

enum SocialService {
  cit('CIT', Icons.savings_outlined, 'CIT member number', 8),
  providentFund(
    'Provident Fund',
    Icons.account_balance_wallet_outlined,
    'PF account number',
    8,
  ),
  ssf('SSF', Icons.groups_outlined, 'SSF member number', 10);

  const SocialService(
    this.title,
    this.icon,
    this.fieldLabel,
    this.minimumDigits,
  );

  final String title;
  final IconData icon;
  final String fieldLabel;
  final int minimumDigits;

  String get formatHint => 'Enter $minimumDigits–15 digits.';

  bool accepts(String number) =>
      RegExp(r'^\d+$').hasMatch(number) &&
      number.length >= minimumDigits &&
      number.length <= 15;
}
