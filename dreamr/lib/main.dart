import 'package:flutter/material.dart';
import 'package:dreamr/screens/login_screen.dart';
import 'package:dreamr/screens/dashboard_screen.dart';
import 'services/api_service.dart';
import 'services/dio_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DioClient.init();
  runApp(DreamrApp());
}

class DreamrApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dreamr',
      home: FutureBuilder<bool>(
        future: ApiService.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          return snapshot.data == true ? DashboardScreen() : LoginScreen();
        },
      ),
    );
  }
}
