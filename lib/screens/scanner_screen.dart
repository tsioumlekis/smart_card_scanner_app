import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nfc_manager/nfc_manager.dart'; 
import 'dart:convert';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:nfc_manager/ndef_record.dart';


class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  String currentTime = '';
  Timer? timer;
  bool isScanning = false;
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

  // --- Η ΛΟΓΙΚΗ ΤΟΥ NFC (ΔΙΑΒΑΖΕΙ ΓΡΑΜΜΕΝΟ ΚΕΙΜΕΝΟ) ---
  void startNfcSession() async {
    var availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) return;

    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (NfcTag tag) async {
        try {
          // 1. Δοκιμάζουμε να διαβάσουμε το γραμμένο κείμενο (NDEF Data)
          Ndef? ndef = Ndef.from(tag);
          
          if (ndef != null && ndef.cachedMessage != null) {
            for (var record in ndef.cachedMessage!.records) {
              // Ελέγχουμε αν η εγγραφή είναι τύπου Κειμένου (Text)
              if (record.typeNameFormat == TypeNameFormat.wellKnown &&
                  record.type.isNotEmpty && record.type.first == 0x54) { 
                
                final payload = record.payload;
                if (payload.isNotEmpty) {
                  // Παραλείπουμε τον κωδικό γλώσσας
                  final languageCodeLength = payload[0] & 0x3F;
                  final text = utf8.decode(payload.sublist(1 + languageCodeLength));
                  
                  stopAllScanning();
                  showSuccessMessage(text, "NFC Κάρτα");
                  return; // Βρήκαμε το κείμενο, τερματίζουμε την αναζήτηση!
                }
              }
            }
          }

          // 2. ΕΝΑΛΛΑΚΤΙΚΗ: Αν η κάρτα είναι άδεια (δεν έχει κείμενο)
          dynamic tagData = tag.data;
          var identifier = tagData.id;

          if (identifier != null) {
            String nfcId = (identifier as List<int>)
                .map((e) => e.toRadixString(16).padLeft(2, '0'))
                .join(':')
                .toUpperCase();
            
            stopAllScanning();
            showSuccessMessage(nfcId, "NFC Κάρτα (Hardware ID)");
          }
        } catch (e) {
          debugPrint("Σφάλμα κατά την ανάγνωση: $e");
        }
      },
    );
  }

  // --- ΣΤΑΜΑΤΑΕΙ ΤΗ ΣΑΡΩΣΗ (NFC & ΚΑΜΕΡΑ) ---
  void stopAllScanning() {
    NfcManager.instance.stopSession();
    setState(() {
      isScanning = false;
    });
  }

  void showSuccessMessage(String id, String method) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $currentAction επιτυχής ($method)\nID: $id\nΏρα: $currentTime'),
        backgroundColor: actionColor,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    NfcManager.instance.stopSession();
    super.dispose();
  }

  void startScan(String action, Color color) {
    setState(() {
      currentAction = action;
      actionColor = color;
      isScanning = true; 
    });
    startNfcSession(); // Ξεκινάει το NFC ταυτόχρονα με την κάμερα!
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12181F),
      appBar: AppBar(
        title: const Text('Τερματικό Ωρομέτρησης'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 1. Ρολόι
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: const Color(0xFF1F262F),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white10, width: 2),
              ),
              child: Text(
                currentTime,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 65, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 4),
              ),
            ),

            if (!isScanning) ...[
              const Text(
                'Επιλέξτε ενέργεια και σκανάρετε\nτο QR ή την NFC κάρτα σας:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              Row(
                children: [
                  Expanded(child: buildActionButton('ΠΡΟΣΕΛΕΥΣΗ', Icons.login, const Color(0xFF00E676))),
                  const SizedBox(width: 16),
                  Expanded(child: buildActionButton('ΑΠΟΧΩΡΗΣΗ', Icons.logout, const Color(0xFFFF1744))),
                ],
              ),
            ] else ...[
              Column(
                children: [
                  Text(
                    'Σκανάρετε QR ή NFC για $currentAction',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: actionColor),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: MobileScanner(
                        onDetect: (capture) {
                          final List<Barcode> barcodes = capture.barcodes;
                          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                            stopAllScanning();
                            showSuccessMessage(barcodes.first.rawValue!, "QR Code");
                          }
                        },
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: stopAllScanning,
                    icon: const Icon(Icons.cancel, color: Colors.white70),
                    label: const Text('Ακύρωση', style: TextStyle(color: Colors.white70)),
                  )
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildActionButton(String label, IconData icon, Color color) {
    return ElevatedButton(
      onPressed: () => startScan(label, color),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 35, color: Colors.white),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}