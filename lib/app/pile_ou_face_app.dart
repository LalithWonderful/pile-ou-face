import 'package:flutter/material.dart';

import '../features/tarot/presentation/screens/home_screen.dart';
import 'app_theme.dart';

class PileOuFaceApp extends StatelessWidget {
  const PileOuFaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pile ou Face',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}
