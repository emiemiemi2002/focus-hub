import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/task_provider.dart';
import 'screens/splash_screen.dart'; 

// --- Paleta de Colores de la App ---
const Color kBgColor = Color(0xFF0D1117);
const Color kTileColor = Color(0xFF161B22);
const Color kAccentColor = Color(0xFF30D5C8);
// ------------------------------------

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider envuelve la app para que TaskProvider esté
    // disponible en todas las pantallas.
    return ChangeNotifierProvider(
      create: (context) => TaskProvider(),
      child: MaterialApp(
        title: 'Focus Hub',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(context),
        home: const SplashScreen(), // Inicia con la SplashScreen
      ),
    );
  }

  // Define el tema visual completo de la app
  ThemeData _buildTheme(BuildContext context) {
    final baseTheme = ThemeData.dark();
    return baseTheme.copyWith(
      // --- Colores ---
      scaffoldBackgroundColor: kBgColor,
      primaryColor: kAccentColor,
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: kAccentColor,
        secondary: kAccentColor,
        onPrimary: kBgColor, // Color del texto/iconos sobre kAccentColor
        surface: kTileColor, // Color de fondo de los "cards"
      ),
      // --- Tema de la AppBar ---
      appBarTheme: AppBarTheme(
        backgroundColor: kBgColor,
        elevation: 0,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      // --- Tema del FAB ---
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kAccentColor,
        foregroundColor: kBgColor, // Color del icono '+'
        elevation: 4,
      ),
      // --- Tipografía ---
      textTheme: GoogleFonts.manropeTextTheme(baseTheme.textTheme).copyWith(
        // Títulos de secciones
        headlineSmall: GoogleFonts.manrope(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: Colors.grey.shade400,
          letterSpacing: 0.5,
        ),
        // Nombres de tareas
        titleMedium: GoogleFonts.manrope(
          fontWeight: FontWeight.w500,
          fontSize: 17,
        ),
        // Cuerpo de texto
        bodyMedium: GoogleFonts.manrope(
          color: Colors.white70,
        ),
      ),
    );
  }
}
