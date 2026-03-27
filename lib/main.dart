import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  await Supabase.initialize(
    url: 'https://hzascfzmwbtruzpppbii.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh6YXNjZnptd2J0cnV6cHBwYmlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzNDIyMDksImV4cCI6MjA4OTkxODIwOX0.YV-qNzmHIXm-Y3ixvor4m4hyqjp_S7gPcbMelU9mizo',
  );

  runApp(const MeetUpApp());
}

class AppColors {
  static const Color primary = Color(0xFFE87A3E);
  static const Color primaryLight = Color(0xFFF5A574);
  static const Color primaryDark = Color(0xFFD4622A);
  static const Color background = Color(0xFFFFF5F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceWarm = Color(0xFFFFF0E8);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardWarm = Color(0xFFFFF8F3);
  static const Color textPrimary = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color dark = Color(0xFF1E1E1E);
  static const Color darkSurface = Color(0xFF2D2D2D);
  static const Color divider = Color(0xFFEEE6E0);
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE87A3E), Color(0xFFF5A574)],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF5F0), Color(0xFFFFE8D6)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D2D2D), Color(0xFF1E1E1E)],
  );
}

class MeetUpApp extends StatelessWidget {
  const MeetUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeetUp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          onPrimary: Colors.white,
          surface: AppColors.background,
          onSurface: AppColors.textPrimary,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.dark,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.divider, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          hintStyle: GoogleFonts.inter(
            color: AppColors.textTertiary,
            fontSize: 15,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.dark,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textTertiary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: CircleBorder(),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
