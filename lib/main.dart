import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Importante
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_app/models/gallery.dart';
import 'package:mi_app/providers/selected_gallery_provider.dart';
import 'package:mi_app/services/gallery_service.dart';
import 'package:mi_app/views/gallery_detail.dart';
import 'package:mi_app/views/sensor_control_view.dart';
import 'package:mi_app/views/welcome.dart';
import 'package:mi_app/views/realtime_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_app/models/painting.dart';

import '../services/upload_data_service.dart';
import 'firebase_options.dart';
import 'package:mi_app/views/gallery_paintings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return PlatformApp(
      title: 'Centro Cultural UNSA',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('es', '')],
      material: (_, __) => MaterialAppData(
        theme: ThemeData(primarySwatch: Colors.red),
        onGenerateRoute: (settings) {
          if (settings.name == '/paintings') {
            final args = settings.arguments;
            if (args is Map<String, dynamic>) {
              final String galleryTitle = args['galleryTitle'] as String;
              final List<Painting> paintings =
                  args['paintings'] as List<Painting>;

              return MaterialPageRoute(
                builder: (context) => GalleryPaintingsScreen(
                  galleryTitle: galleryTitle,
                  paintings: paintings,
                ),
              );
            } else {
              return MaterialPageRoute(
                builder: (context) => const Scaffold(
                  body: Center(child: Text('Error: argumentos inválidos')),
                ),
              );
            }
          }
          return null;
        },
      ),
      cupertino: (_, __) => CupertinoAppData(
        theme: const CupertinoThemeData(
          primaryColor: CupertinoColors.systemRed,
        ),
      ),
      home: const Welcome(),
    );
  }
}
