import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  late MobileScannerController _cameraController;

  static const _nfcChannel = MethodChannel('com.example.smartCardScannerApp/nfc');

  // ============================================================
  // Οι 5 επιλογές mood με emoji, label και χρώμα
  // ============================================================
  final List<Map<String, dynamic>> _moods = [
    {'emoji': '😄', 'label': 'Υπέροχα',   'color': const Color(0xFF00C853)},
    {'emoji': '🙂', 'label': 'Καλά',       'color': const Color(0xFF64DD17)},
    {'emoji': '😐', 'label': 'Ουδέτερα',  'color': const Color(0xFFFFD600)},
    {'emoji': '😕', 'label': 'Κακά',       'color': const Color(0xFFFF6D00)},
    {'emoji': '😞', 'label': 'Χάλια',      'color': const Color(0xFFD50000)},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraController = MobileScannerController(facing: CameraFacing.back);
    _updateTime();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
    _enableNfcForegroundDispatch();
  }

  void _enableNfcForegroundDispatch() {
    try { _nfcChannel.invokeMethod('enableForegroundDispatch'); } catch (_) {}
  }

  void _disableNfcForegroundDispatch() {
    try { _nfcChannel.invokeMethod('disableForegroundDispatch'); } catch (_) {}
  }

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
      if (isScanning && mounted) _startNfcSession();
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
        _isProcessing = true;

        await NfcManager.instance.stopSession().catchError((_) {});
        if (mounted) setState(() { isScanning = false; });

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
                  final text = utf8.decode(payload.sublist(1 + languageCodeLength));
                  _handleScanResult(text, "NFC Κείμενο");
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
            _handleScanResult(nfcId, "NFC Κάρτα");
          } else {
            _handleScanResult("Άγνωστη Κάρτα", "NFC");
          }
        } catch (e) {
          debugPrint("Σφάλμα NFC: $e");
          _isProcessing = false;
        }
      },
    );
  }

  // ============================================================
  // Κεντρική λογική με ελέγχους Firestore
  // ============================================================
  void _handleScanResult(String cardId, String method) {
    if (currentAction == 'ΠΡΟΣΕΛΕΥΣΗ') {
      _checkAndHandleArrival(cardId, method);
    } else {
      _checkAndHandleDeparture(cardId, method);
    }
  }

  // ── Κεντρικός έλεγχος: βρες την τελευταία κίνηση σήμερα ───────
  // Λογική:
  //   ΠΡΟΣΕΛΕΥΣΗ επιτρέπεται αν: δεν υπάρχει καμία κίνηση σήμερα
  //                               Ή η τελευταία ήταν ΑΠΟΧΩΡΗΣΗ
  //   ΑΠΟΧΩΡΗΣΗ  επιτρέπεται αν: η τελευταία ήταν ΠΡΟΣΕΛΕΥΣΗ
  Future<void> _checkAndHandleArrival(String cardId, String method) async {
    final lastAction = await _getLastActionToday(cardId);

    if (lastAction == 'ΠΡΟΣΕΛΕΥΣΗ') {
      // Η τελευταία κίνηση ήταν προσέλευση — δεν επιτρέπεται νέα
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Υπάρχει ήδη ενεργή ΠΡΟΣΕΛΕΥΣΗ! Πρέπει πρώτα να γίνει ΑΠΟΧΩΡΗΣΗ.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() { _isProcessing = false; });
      }
      return;
    }

    // null (καμία κίνηση) ή 'ΑΠΟΧΩΡΗΣΗ' → επιτρέπεται
    _saveToFirestore(cardId, method, null);
  }

  Future<void> _checkAndHandleDeparture(String cardId, String method) async {
    final lastAction = await _getLastActionToday(cardId);

    if (lastAction == null) {
      // Καμία κίνηση σήμερα — δεν μπορεί να αποχωρήσει
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Δεν βρέθηκε ΠΡΟΣΕΛΕΥΣΗ σήμερα! Σκανάρετε πρώτα Προσέλευση.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() { _isProcessing = false; });
      }
      return;
    }

    if (lastAction == 'ΑΠΟΧΩΡΗΣΗ') {
      // Η τελευταία κίνηση ήταν ήδη αποχώρηση
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Υπάρχει ήδη καταχωρημένη ΑΠΟΧΩΡΗΣΗ! Σκανάρετε Προσέλευση πρώτα.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() { _isProcessing = false; });
      }
      return;
    }

    // Η τελευταία ήταν ΠΡΟΣΕΛΕΥΣΗ → επιτρέπεται αποχώρηση
    _showMoodDialog(cardId, method);
  }

  // ── Βρίσκει την τελευταία κίνηση σήμερα για αυτή την κάρτα ───
  Future<String?> _getLastActionToday(String cardId) async {
    try {
      final today = _todayString();
      final snap = await FirebaseFirestore.instance
          .collection('attendance')
          .where('employeeId', isEqualTo: cardId)
          .where('date', isEqualTo: today)
          .get();

      if (snap.docs.isEmpty) return null;

      // Ταξινόμηση στη μνήμη — πιο πρόσφατο πρώτο
      final sorted = snap.docs..sort((a, b) {
        final aTs = (a.data())['timestamp'] as Timestamp?;
        final bTs = (b.data())['timestamp'] as Timestamp?;
        if (aTs == null) return 1;
        if (bTs == null) return -1;
        return bTs.compareTo(aTs);
      });

      return (sorted.first.data())['action'] as String?;
    } catch (e) {
      debugPrint('Firestore check error: $e');
      return null;
    }
  }

  // ── Helper: σημερινή ημερομηνία ───────────────────────────────
  String _todayString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  // ============================================================
  // Το mood dialog με τις 5 φατσούλες
  // ============================================================
  void _showMoodDialog(String cardId, String method) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E252D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_emotions, color: Colors.amber, size: 44),
                const SizedBox(height: 12),
                const Text(
                  'Πώς ήταν η βάρδια σου;',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Επίλεξε πώς αισθάνεσαι',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 24),

                // Οι 5 φατσούλες σε Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _moods.map((mood) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context); // Κλείνει το dialog
                        _saveToFirestore(cardId, method, mood['label']);
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: (mood['color'] as Color).withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: mood['color'] as Color,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                mood['emoji'],
                                style: const TextStyle(fontSize: 26),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            mood['label'],
                            style: TextStyle(
                              color: mood['color'] as Color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Αποθηκεύει χωρίς mood αν παραλείψει
                    _saveToFirestore(cardId, method, null);
                  },
                  child: const Text(
                    'Παράλειψη',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // Αποθήκευση στο Firestore με νέα δομή για το EmployeeScreen
  // ============================================================
  Future<void> _saveToFirestore(String cardId, String method, String? mood) async {
    try {
      final now = DateTime.now();
      final dateStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      await FirebaseFirestore.instance.collection('attendance').add({
        'cardId':     cardId,
        'employeeId': cardId,
        'action':     currentAction,
        'method':     method,
        'timestamp':  FieldValue.serverTimestamp(),
        'date':       dateStr,
        'mood':       mood,
      });
      debugPrint('✅ Firestore [attendance]: αποθηκεύτηκε επιτυχώς');
    } catch (e) {
      debugPrint('❌ Firestore error: $e');
    }
    _showSuccessSnackbar(cardId, method, mood);
  }

  void _showSuccessSnackbar(String id, String method, String? mood) {
    if (!mounted) return;
    final moodText = mood != null ? '\nΔιάθεση: $mood' : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ $currentAction επιτυχής ($method)\nID: $id\nΏρα: $currentTime$moodText',
        ),
        backgroundColor: actionColor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void cancelScan() {
    _isProcessing = false;
    setState(() { isScanning = false; });
    NfcManager.instance.stopSession().catchError((_) {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    _cameraController.dispose();
    _disableNfcForegroundDispatch();
    NfcManager.instance.stopSession().catchError((_) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12181F),
      appBar: AppBar(
        title: const Text(
          'Τερματικό Ωρομέτρησης',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1F262F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Ψηφιακό ρολόι
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
                  letterSpacing: 4,
                ),
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
                  Expanded(child: buildActionButton('ΠΡΟΣΕΛΕΥΣΗ', Icons.login,  const Color(0xFF00E676))),
                  const SizedBox(width: 16),
                  Expanded(child: buildActionButton('ΑΠΟΧΩΡΗΣΗ',  Icons.logout, const Color(0xFFFF1744))),
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
                      color: actionColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          MobileScanner(
                            controller: _cameraController,
                            onDetect: (capture) {
                              if (_isProcessing) return;
                              final barcodes = capture.barcodes;
                              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                                _isProcessing = true;
                                cancelScan();
                                _handleScanResult(barcodes.first.rawValue!, "QR Code");
                              }
                            },
                          ),
                          // Κουμπί flip κάμερας
                          Positioned(
                            top: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: () => _cameraController.switchCamera(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Icon(
                                  Icons.flip_camera_android,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: cancelScan,
                    icon: const Icon(Icons.cancel, color: Colors.white70),
                    label: const Text('Ακύρωση', style: TextStyle(color: Colors.white70)),
                  ),
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
