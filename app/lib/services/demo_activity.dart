import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/service_draft.dart';

class DemoActivity extends ChangeNotifier {
  final List<DemoReceipt> _receipts = [];

  List<DemoReceipt> get receipts => List.unmodifiable(_receipts);

  DemoReceipt record({required String prefix, required String title}) {
    final id = const Uuid().v4().substring(0, 8).toUpperCase();
    final receipt = DemoReceipt('$prefix-$id', title, DateTime.now());
    _receipts.insert(0, receipt);
    notifyListeners();
    return receipt;
  }
}
