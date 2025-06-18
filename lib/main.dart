import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Asegúrate de importar esto
import 'package:mi_app/views/welcome.dart';
import 'package:firebase_core/firebase_core.dart';

import '../services/upload_data_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformApp(
      title: 'Centro Cultural UNSA',
      material: (_, __) =>
          MaterialAppData(theme: ThemeData(primarySwatch: Colors.red)),
      cupertino: (_, __) => CupertinoAppData(
        theme: const CupertinoThemeData(
          primaryColor: CupertinoColors.systemRed,
        ),
      ),
      home: const Welcome(),
    );
  }
}
