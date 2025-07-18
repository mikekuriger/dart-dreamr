import 'package:flutter/material.dart';

final ValueNotifier<bool> dreamDataChanged = ValueNotifier(false);

// temporary page refreshing to test
final ValueNotifier<int> journalRefreshTrigger = ValueNotifier(0);
final ValueNotifier<int> galleryRefreshTrigger = ValueNotifier(0);
final ValueNotifier<int> profileRefreshTrigger = ValueNotifier(0);
final ValueNotifier<int> dreamEntryRefreshTrigger = ValueNotifier(0);
final ValueNotifier<int> editorRefreshTrigger = ValueNotifier(0);


class AppConfig {
  static const String baseUrl = 'https://dreamr-us-west-01.zentha.me';
}
