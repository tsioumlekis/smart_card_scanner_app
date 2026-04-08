import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'employee_screen.dart'; 
import 'scanner_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isTerminalMode;

  const LoginScreen({super.key, required this.isTerminalMode}); 

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;

  // ==========================================
  // ΕΔΩ ΒΑΖΕΙΣ ΤΟ ΚΡΥΦΟ PIN ΤΟΥ ΕΡΓΟΔΟΤΗ
  // ==========================================
  final String _secretAdminPin = "1234"; 

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- ΝΕΟ: Το παράθυρο που ζητάει το PIN ---
  void _showPinDialog() {
    final pinController = TextEditingController();
    bool isPinWrong = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Δεν κλείνει αν πατήσεις απ' έξω (απαιτείται PIN ή Ακύρωση)
      builder: (context) {
        // Χρησιμοποιούμε StatefulBuilder για να μπορούμε να δείξουμε το μήνυμα λάθους ΜΕΣΑ στο pop-up
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E252D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Column(
                children: [
                  Icon(Icons.security, color: Colors.blueAccent, size: 40),
                  SizedBox(height: 10),
                  Text('Κωδικός Ασφαλείας', style: TextStyle(color: Colors.white, fontSize: 20)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Εισάγετε το 4-ψήφιο PIN Διαχειριστή για να αποκτήσετε πρόσβαση.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true, // Κρύβει το PIN με τελίτσες
                    maxLength: 4, // Μόνο 4 ψηφία
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 10),
                    decoration: InputDecoration(
                      counterText: "", // Κρύβει το μετρητή γραμμάτων (π.χ. "4/4")
                      filled: true,
                      fillColor: const Color(0xFF12181F),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent)),
                      errorText: isPinWrong ? 'Λάθος PIN! Προσπαθήστε ξανά.' : null,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Αν πατήσει ακύρωση, τον κάνουμε Sign Out για ασφάλεια και κλείνουμε το Pop-up
                    FirebaseAuth.instance.signOut(); 
                    Navigator.pop(context);
                  },
                  child: const Text('Ακύρωση', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  onPressed: () {
                    // Έλεγχος του PIN
                    if (pinController.text == _secretAdminPin) {
                      Navigator.pop(context); // Κλείνει το pop-up
                      // ΤΗΛΕΜΕΤΑΦΟΡΑ ΣΤΟ DASHBOARD!
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const EmployeeScreen()),
                      );
                    } else {
                      // Αν έβαλε λάθος PIN
                      setStateDialog(() {
                        isPinWrong = true;
                        pinController.clear();
                      });
                    }
                  },
                  child: const Text('Επιβεβαίωση', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _handleLogin() async {
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Σύνδεση με Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (context.mounted) {
        if (widget.isTerminalMode) {
          // Αν είναι το Τερματικό (Scanner), μπαίνει κατευθείαν
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Επιτυχής Σύνδεση Τερματικού!'), backgroundColor: Colors.green),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ScannerScreen()),
          );
        } else {
          // ==========================================
          // ΑΝ ΕΙΝΑΙ ΤΟ ΑΦΕΝΤΙΚΟ, ΠΕΤΑΕΙ ΤΟ PIN DIALOG
          // ==========================================
          _showPinDialog();
        }
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Λάθος Email ή Κωδικός! Προσπαθήστε ξανά.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12181F), 
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/image/logo_app1.png', width: 120, height: 120),
                const SizedBox(height: 20),
                Text(
                  widget.isTerminalMode ? 'Τερματικό Σάρωσης' : 'Smart Work Card',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isTerminalMode ? 'Συνδεθείτε για έναρξη βάρδιας' : 'Πίνακας Ελέγχου Εργοδότη',
                  style: const TextStyle(fontSize: 16, color: Colors.white54),
                ),
                const SizedBox(height: 40),

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Email Εταιρείας',
                    labelStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.business, color: Colors.white54),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: const Color(0xFF1E252D), 
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent)),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible, 
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Κωδικός',
                    labelStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.lock, color: Colors.white54),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white54,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: const Color(0xFF1E252D),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent)),
                  ),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55, 
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
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