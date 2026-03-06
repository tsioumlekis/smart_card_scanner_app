import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'employee_screen.dart'; 
import 'scanner_screen.dart'; // Βάλαμε και το Scanner εδώ!

class LoginScreen extends StatefulWidget {
  final bool isTerminalMode; // Αυτό λέει στην οθόνη ΓΙΑΤΙ την ανοίξαμε

  // Απαιτούμε να μας πουν αν είναι για τερματικό ή όχι όταν την καλούν
  const LoginScreen({super.key, required this.isTerminalMode}); 

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
      appBar: AppBar(
        // Αλλάζουμε λίγο τον τίτλο ανάλογα με το τι πατήσαμε!
        title: Text(widget.isTerminalMode ? 'Σύνδεση Τερματικού' : 'Σύνδεση Εταιρείας'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/image/logo_app1.png', width: 100, height: 100),
                const SizedBox(height: 20),
                const Text(
                  'Smart Work Card Scanner',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Εταιρείας',
                    prefixIcon: const Icon(Icons.business),
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
                        final email = _emailController.text.trim();
                        final password = _passwordController.text.trim();

                        await FirebaseAuth.instance.signInWithEmailAndPassword(
                          email: email,
                          password: password,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Επιτυχής Σύνδεση!'), backgroundColor: Colors.green),
                          );
                          
                          // ΕΔΩ ΕΙΝΑΙ Η ΜΑΓΕΙΑ: 
                          // Ελέγχει αν το ανοίξαμε για τερματικό ή για διαχείριση
                          if (widget.isTerminalMode) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const ScannerScreen()),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const EmployeeScreen()),
                            );
                          }
                        }
                      } on FirebaseAuthException catch (e) {
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