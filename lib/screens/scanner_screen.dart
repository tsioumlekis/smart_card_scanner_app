import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mobile_scanner/mobile_scanner.dart'; // Το πακέτο της κάμερας!

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  String currentTime = '';
  Timer? timer;

  // Ελέγχει αν η κάμερα είναι ανοιχτή αυτή τη στιγμή
  bool isScanning = false;
  // Θυμάται τι πάτησε ο χρήστης ('ΠΡΟΣΕΛΕΥΣΗ' ή 'ΑΠΟΧΩΡΗΣΗ')
  String currentAction = ''; 
  Color actionColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _updateTime();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      currentTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // 1. Ο χρήστης πατάει το κουμπί (Προσέλευση/Αποχώρηση) και ανοίγει η κάμερα
  void startScan(String action, Color color) {
    setState(() {
      currentAction = action;
      actionColor = color;
      isScanning = true; // Ανοίγει η κάμερα!
    });
  }

  // 2. Η κάμερα διαβάζει το QR
  void handleBarcode(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final scannedId = barcode.rawValue!; // Το ID που διάβασε (π.χ. emp-1234)
        
        // Κλείνουμε αμέσως την κάμερα
        setState(() {
          isScanning = false;
        });

        // Δείχνουμε το μήνυμα επιτυχίας
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $currentAction επιτυχής για: $scannedId\nΏρα: $currentTime'),
            backgroundColor: actionColor,
            duration: const Duration(seconds: 4),
          ),
        );
        break; // Σταματάμε στο πρώτο QR που θα βρει για να μη σκανάρει 10 φορές
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: const Text('Τερματικό Ωρομέτρησης'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Το Ψηφιακό Ρολόι
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: Text(
                    currentTime,
                    style: const TextStyle(fontSize: 70, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 5),
                  ),
                ),
                const SizedBox(height: 50),

                // --- ΛΕΙΤΟΥΡΓΙΑ 1: ΔΕΙΧΝΕΙ ΤΑ ΚΟΥΜΠΙΑ ---
                if (!isScanning) ...[
                  const Text(
                    'Επιλέξτε ενέργεια για να σκανάρετε την κάρτα σας:',
                    style: TextStyle(fontSize: 22, color: Colors.white70),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 80,
                        child: ElevatedButton.icon(
                          onPressed: () => startScan('ΠΡΟΣΕΛΕΥΣΗ', Colors.greenAccent[400]!),
                          icon: const Icon(Icons.login, size: 32),
                          label: const Text('ΠΡΟΣΕΛΕΥΣΗ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent[400],
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),
                      SizedBox(
                        width: 200,
                        height: 80,
                        child: ElevatedButton.icon(
                          onPressed: () => startScan('ΑΠΟΧΩΡΗΣΗ', Colors.redAccent[400]!),
                          icon: const Icon(Icons.logout, size: 32),
                          label: const Text('ΑΠΟΧΩΡΗΣΗ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent[400],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] 
                // --- ΛΕΙΤΟΥΡΓΙΑ 2: ΔΕΙΧΝΕΙ ΤΗΝ ΚΑΜΕΡΑ ---
                else ...[
                  Text(
                    'Σκανάρετε το QR για $currentAction',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: actionColor),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      border: Border.all(color: actionColor, width: 4), // Το περίγραμμα παίρνει το χρώμα της ενέργειας!
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: MobileScanner(
                        onDetect: handleBarcode, // Μόλις δει QR, τρέχει τη συνάρτηση
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Κουμπί Ακύρωσης αν πάτησε λάθος κουμπί
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        isScanning = false; // Κλείνει την κάμερα
                      });
                    },
                    icon: const Icon(Icons.cancel, color: Colors.white70),
                    label: const Text('Ακύρωση & Επιστροφή', style: TextStyle(color: Colors.white70, fontSize: 18)),
                  )
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}