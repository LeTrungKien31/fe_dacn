import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildTheme() {
  final base = ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal);
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  );
}
