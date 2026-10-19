import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'core/audio_service.dart';
import 'core/save_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Enable immersive sticky mode
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize persistence service
  await SaveService.I.load();

  runApp(const CosmoApp());

  // Optional startup work must not hold the first frame hostage (for example,
  // Google Fonts may need network access on a fresh install).
  unawaited(_initializeAudio());
  unawaited(_prefetchFonts());
}

Future<void> _initializeAudio() async {
  await Sfx.init();
}

Future<void> _prefetchFonts() async {
  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.lilitaOne(),
      GoogleFonts.baloo2(),
    ]);
  } catch (e) {
    debugPrint("GoogleFonts pre-fetch failed (using system fallbacks): $e");
  }
}
