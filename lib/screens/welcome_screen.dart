import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'scanner_screen.dart';

// Την οθόνη σάρωσης θα τη φτιάξουμε στο επόμενο βήμα!
// import 'scanner_screen.dart'; 

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Λογότυπο
              Image.asset(
                'assets/image/logo_app1.png', 
                width: 120, 
                height: 120,  
              ),
              const SizedBox(height: 30),
              const Text(
                'Επιλογή Λειτουργίας',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 50),

              // ΚΟΥΜΠΙ 1: Διαχείριση Εταιρείας (Οδηγεί στο Login)
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen(isTerminalMode: false)),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[800],
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.admin_panel_settings, size: 50, color: Colors.white),
                      SizedBox(height: 10),
                      Text('Διαχείριση Εταιρείας', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text('Στατιστικά, QR Codes & Προσωπικό', style: TextStyle(fontSize: 14, color: Colors.white70)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // ΚΟΥΜΠΙ 2: Τερματικό Υπαλλήλων (Θα οδηγεί στο Σκανάρισμα)
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen(isTerminalMode: true)),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.qr_code_scanner, size: 50, color: Colors.white),
                      SizedBox(height: 10),
                      Text('Τερματικό Σάρωσης', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text('Χτύπημα κάρτας (Είσοδος / Έξοδος)', style: TextStyle(fontSize: 14, color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}