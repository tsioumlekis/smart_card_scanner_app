import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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
      // Εδώ λέμε στο Flutter ότι η πρώτη οθόνη πλέον είναι η LoginScreen
      home: const LoginScreen(), 
    );
  }
}

// ---------------------------------------------------------
// Η ΝΕΑ ΜΑΣ ΟΘΟΝΗ: LoginScreen
// ---------------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Ένα πολύ απαλό γκρι φόντο
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Το Λογότυπο / Εικονίδιο
                Image.asset(
                   'assets/image/logo_app1.png', 
                     width: 100,
                     height: 100,
                ),
                const SizedBox(height: 20), // Κενό διάστημα

                // 2. Ο Τίτλος της εφαρμογής
                const Text(
                  'Smart Work Card Scanner',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 40),

                // 3. Το πεδίο για το Email
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // 4. Το πεδίο για τον Κωδικό
                TextField(
                  obscureText: true, // Αυτό κρύβει τα γράμματα (βάζει τελείες)
                  decoration: InputDecoration(
                    labelText: 'Κωδικός',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Το Κουμπί Σύνδεσης
                SizedBox(
                  width: double.infinity, // Να πιάσει όλο το πλάτος
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // Εδώ θα μπει η λογική του Firebase αργότερα!
                      print("Πατήθηκε το κουμπί!");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Είσοδος',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}