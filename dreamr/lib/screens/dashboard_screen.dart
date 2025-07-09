import 'package:flutter/material.dart';
import 'package:dreamr/widgets/dream_entry_widget.dart';
// import 'package:dreamr/widgets/main_scaffold.dart';

class DashboardScreen extends StatefulWidget {
  final ValueNotifier<int> refreshTrigger;

  const DashboardScreen({super.key, required this.refreshTrigger});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DreamEntryWidget(refreshTrigger: widget.refreshTrigger), 
        ],
      ),
    );
  }
}

