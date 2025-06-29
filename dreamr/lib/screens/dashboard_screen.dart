import 'package:flutter/material.dart';
import 'package:dreamr/widgets/dream_entry_widget.dart';
// import 'package:dreamr/widgets/main_scaffold.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: const [
          DreamEntryWidget(),
        ],
      ),
    );
  }
}
