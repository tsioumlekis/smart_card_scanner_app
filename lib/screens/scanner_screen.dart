import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:nfc_manager/nfc_manager_android.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  String currentTime = '';
  Timer? timer;
  bool isScanning = false;
  String currentAction = '';
  Color actionColor = Colors.blue;
  bool _isProcessing = false;

  // ✅ Αυτό "πιάνει" το NFC intent ΠΡΙΝ φύγει στο Android σύστημα
  static const _nfcChannel = MethodChannel('com.example.smartCardScannerApp/nfc');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateTime();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
    _enableNfcForegroundDispatch();
  }

  // ✅ Η εφαρμογή παίρνει προτεραιότητα έναντι του Android για NFC intents
  void _enableNfcForegroundDispatch() {
    try {
      _nfcChannel.invokeMethod('enableForegroundDispatch');
    } catch (_) {}
  }

  void _disableNfcForegroundDispatch() {
    try {
      _nfcChannel.invokeMethod('disableForegroundDispatch');
    } catch (_) {}
  }

  // ✅ Όταν η εφαρμογή επιστρέφει foreground, ξανα-ενεργοποιούμε
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _enableNfcForegroundDispatch();
    } else if (state == AppLifecycleState.paused) {
      _disableNfcForegroundDispatch();
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    if (mounted) {
      setState(() {
        currentTime =
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
      });
    }
  }

  void startScan(String action, Color color) {
    _isProcessing = false;
    setState(() {
      currentAction = action;
      actionColor = color;
      isScanning = true;
    });

    NfcManager.instance.stopSession().catchError((_) {});

    Future.delayed(const Duration(milliseconds: 800), () {
      if (isScanning && mounted) {
        _startNfcSession();
      }
    });
  }

  void _startNfcSession() async {
    var availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) return;

    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (NfcTag tag) async {
        if (!isScanning || _isProcessing) return;

        // Κλειδώνουμε ΑΜΕΣΩΣ
        _isProcessing = true;

        await NfcManager.instance.stopSession().catchError((_) {});

        if (mounted) {
          setState(() {
            isScanning = false;
          });
        }

        try {
          // 1. NDEF κείμενο
          Ndef? ndef = Ndef.from(tag);
          if (ndef != null && ndef.cachedMessage != null) {
            for (var record in ndef.cachedMessage!.records) {
              if (record.typeNameFormat.index == 1 &&
                  record.type.isNotEmpty &&
                  record.type.first == 0x54) {
                final payload = record.payload;
                if (payload.isNotEmpty) {
                  final languageCodeLength = payload[0] & 0x3F;
                  final text =
                      utf8.decode(payload.sublist(1 + languageCodeLength));
                  showSuccessMessage(text, "NFC Κείμενο");
                  return;
                }
              }
            }
          }

          // 2. Hardware ID
          List<int>? identifier;
          if (NfcAAndroid.from(tag) != null) {
            identifier = NfcAAndroid.from(tag)!.tag.id;
          } else if (MifareClassicAndroid.from(tag) != null) {
            identifier = MifareClassicAndroid.from(tag)!.tag.id;
          } else if (NfcVAndroid.from(tag) != null) {
            identifier = NfcVAndroid.from(tag)!.tag.id;
          } else if (NfcBAndroid.from(tag) != null) {
            identifier = NfcBAndroid.from(tag)!.tag.id;
          } else if (NfcFAndroid.from(tag) != null) {
            identifier = NfcFAndroid.from(tag)!.tag.id;
          }

          if (identifier != null) {
            String nfcId = identifier
                .map((e) => e.toRadixString(16).padLeft(2, '0'))
                .join(':')
                .toUpperCase();
            showSuccessMessage(nfcId, "NFC Κάρτα");
          } else {
            showSuccessMessage("Άγνωστη Κάρτα", "NFC");
          }
        } catch (e) {
          debugPrint("Σφάλμα NFC: $e");
          _isProcessing = false;
        }
      },
    );
  }

  void cancelScan() {
    _isProcessing = false;
    setState(() {
      isScanning = false;
    });
    NfcManager.instance.stopSession().catchError((_) {});
  }

  void showSuccessMessage(String id, String method) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '✅ $currentAction επιτυχής ($method)\nID: $id\nΏρα: $currentTime'),
        backgroundColor: actionColor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    _disableNfcForegroundDispatch();
    NfcManager.instance.stopSession().catchError((_) {});
    super.dispose();
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
                style: const TextStyle(
                    fontSize: 65,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4),
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
                  Expanded(
                      child: buildActionButton(
                          'ΠΡΟΣΕΛΕΥΣΗ', Icons.login, const Color(0xFF00E676))),
                  const SizedBox(width: 16),
                  Expanded(
                      child: buildActionButton(
                          'ΑΠΟΧΩΡΗΣΗ', Icons.logout, const Color(0xFFFF1744))),
                ],
              ),
            ] else ...[
              Column(
                children: [
                  Text(
                    'Σκανάρετε QR ή NFC για $currentAction',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: actionColor),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: MobileScanner(
                        onDetect: (capture) {
                          if (_isProcessing) return;
                          final List<Barcode> barcodes = capture.barcodes;
                          if (barcodes.isNotEmpty &&
                              barcodes.first.rawValue != null) {
                            _isProcessing = true;
                            cancelScan();
                            showSuccessMessage(
                                barcodes.first.rawValue!, "QR Code");
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: cancelScan,
                    icon: const Icon(Icons.cancel, color: Colors.white70),
                    label: const Text('Ακύρωση',
                        style: TextStyle(color: Colors.white70)),
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
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ],
      ),
    );
  }
}