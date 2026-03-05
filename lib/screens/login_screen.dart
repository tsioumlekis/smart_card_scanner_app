import 'package:flutter/material.dart';
import 'employee_screen.dart'; // Συνδέουμε τη δεύτερη οθόνη!
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      persistentFooterButtons: [
        Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8.0),
          child: const Text(
            '© 2026 Smart Work Card Scanner. Όλα τα δικαιώματα διατηρούνται.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/image/logo_app1.png', 
                  width: 100, 
                  height: 100,  
                ),
                const SizedBox(height: 20),
                const Text(
                  'Smart Work Card Scanner',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Κωδικός',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        // 1. Διαβάζουμε τι έγραψε ο χρήστης στα κουτάκια
                        final email = _emailController.text.trim();
                        final password = _passwordController.text.trim();

                        // 2. Ζητάμε από το Firebase να ελέγξει αν υπάρχουν
                        await FirebaseAuth.instance.signInWithEmailAndPassword(
                          email: email,
                          password: password,
                        );

                        // 3. ΑΝ είναι σωστά, ΤΟΤΕ αλλάζουμε οθόνη (μαζί με ένα μήνυμα επιτυχίας)
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Επιτυχής Σύνδεση!'), backgroundColor: Colors.green),
                          );
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const EmployeeScreen()),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        // 4. ΑΝ τα στοιχεία είναι λάθος, βγάζουμε κόκκινο μήνυμα λάθους!
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Λάθος Email ή Κωδικός! Προσπαθήστε ξανά.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Είσοδος', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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