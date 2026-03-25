import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Configurar la animación de entrada
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // 2. Iniciar la animación y la carga de datos
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Iniciar la animación de fade/slide
    _animationController.forward();

    // Esta función se ejecutará después de que el primer frame esté completo.
    Future<void> loadData() async {
      // Usamos un try-catch aquí para que la app no se cuelgue en la splash si hay error
      try {
        await Provider.of<TaskProvider>(context, listen: false).loadTasks();
      } catch (e) {
        print("Error inicial al cargar tareas: $e");
        // El provider ya habrá manejado el estado de error, podemos continuar.
      }
    }

    // Iniciar ambas tareas al mismo tiempo y esperar a que las dos terminen
    await Future.wait([
      // Tarea 1: Cargar datos (ahora de forma segura)
      loadData(),

      // Tarea 2: Asegurar un tiempo mínimo de 2.5 segundos para la splash
      Future.delayed(const Duration(milliseconds: 2500)),
    ]);

    // 3. Navegar a la HomeScreen cuando todo esté listo
    // Usamos pushReplacement para que el usuario no pueda "volver" a la splash
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Fondo con gradiente sutil
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade900,
              Colors.teal.shade900,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Contenido principal (Logo y Título) con animación
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // --- El Logotipo ---
                      Image.asset(
                        'assets/logo.png',
                        width: 140,
                        height: 140,
                      ),
                      const SizedBox(height: 24),

                      // --- El Título ---
                      Text(
                        'Focus Hub',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80),

              // --- Indicador de Carga ---
              // Este indicador le muestra al usuario que la app está
              // cargando datos (loadTasks) mientras ve la animación.
              FadeTransition(
                opacity: _fadeAnimation,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}