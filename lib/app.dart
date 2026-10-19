import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'screens/splash_screen.dart';

/// Root application widget for Cosmo Pop.
class CosmoApp extends StatelessWidget {
  const CosmoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cosmo Pop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
