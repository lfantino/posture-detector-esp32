import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_page.dart';
import 'database/database_helper.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialització de la base de dades abans que l'app arrenqui.
  // Es crida explícitament al getter `database` perquè forci el `_onCreate` o el `sqfliteFfiInit` en Windows.
  final dbHelper = DatabaseHelper();
  await dbHelper.database;
  
  await NotificationService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cadira de Correcció Postural',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF1EDE6),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB5A1E5)),
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
      // L'aplicació comença per la pàgina de login
      home: const LoginPage(),
    );
  }
}
