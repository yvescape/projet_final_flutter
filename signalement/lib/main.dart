import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app_router.dart';
import './providers/auth_provider.dart';
import './providers/signalement_provider.dart';
import './providers/location_provider.dart';
import '../providers/signet_provider.dart';
import './services/notification_service.dart'; // service local

// 🔑 GlobalKey pour la navigation à partir des notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 🔔 Initialiser les notifications locales sans FCM
  await NotificationService.initialize(navigatorKey);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SignalementProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => SignetProvider()),
      ],
      child: const SignalementAPP(),
    ),
  );
}

class SignalementAPP extends StatefulWidget {
  const SignalementAPP({super.key});

  @override
  State<SignalementAPP> createState() => _SignalementAPPState();
}

class _SignalementAPPState extends State<SignalementAPP> {
  @override
  void initState() {
    super.initState();

    // 📍 Initialiser la localisation
    Future.delayed(Duration.zero, () async {
      Provider.of<LocationProvider>(context, listen: false).initLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'Signalement',
    );
  }
}
