import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// ΒΑΖΟΥΜΕ ΤΗΝ ΚΑΙΝΟΥΡΙΑ ΟΘΟΝΗ!
import 'screens/welcome_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SmartCardApp());
}

class SmartCardApp extends StatelessWidget {
  const SmartCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Work Card Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // ΑΛΛΑΓΗ ΕΔΩ: Η εφαρμογή ξεκινάει πλέον από την Welcome Screen
      home: const WelcomeScreen(), 
    );
  }
}