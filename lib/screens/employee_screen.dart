import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {

  // ── Helpers ημερομηνίας ───────────────────────────────────────
  String get _today {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}";
  }

  List<String> get _last7Days {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return "${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}";
    });
  }

  // ── Mood config ───────────────────────────────────────────────
  static const List<String> _moodLabels = ['Υπέροχα','Καλά','Ουδέτερα','Κακά','Χάλια'];
  static const Map<String,Color> _moodColors = {
    'Υπέροχα': Color(0xFF00C853),
    'Καλά':    Color(0xFF64DD17),
    'Ουδέτερα':Color(0xFFFFD600),
    'Κακά':    Color(0xFFFF6D00),
    'Χάλια':   Color(0xFFD50000),
  };
  static const Map<String,String> _moodEmoji = {
    'Υπέροχα': '😄','Καλά':'🙂','Ουδέτερα':'😐','Κακά':'😕','Χάλια':'😞',
  };

  // ── Dialog: προσθήκη εργαζόμενου ─────────────────────────────
  void _showAddEmployeeDialog() {
    final nCtrl    = TextEditingController();
    final rCtrl    = TextEditingController();
    final eCtrl    = TextEditingController();
    final pCtrl    = TextEditingController();
    final aCtrl    = TextEditingController();
    final cCtrl    = TextEditingController();
    final cardCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E252D),
        title: const Text('Προσθήκη Υπαλλήλου', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _buildEditField(nCtrl, 'Ονοματεπώνυμο *'),
            _buildEditField(rCtrl, 'Ρόλος'),
            _buildEditField(eCtrl, 'Email'),
            _buildEditField(pCtrl, 'Τηλέφωνο'),
            _buildEditField(aCtrl, 'ΑΦΜ'),
            _buildEditField(cCtrl, 'Εταιρεία'),
            _buildEditField(cardCtrl, 'Card ID (NFC/QR)'),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ακύρωση', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              if (nCtrl.text.trim().isEmpty) return;
              // Αποθήκευση στο Firestore — το document ID δημιουργείται αυτόματα
              // Ο χρήστης μπορεί αργότερα να συνδέσει cardId με σκανάρισμα
              await FirebaseFirestore.instance.collection('employees').add({
                'name':     nCtrl.text.trim(),
                'role':     rCtrl.text.trim().isEmpty ? 'Νέος Υπάλληλος' : rCtrl.text.trim(),
                'email':    eCtrl.text.trim().isEmpty ? '-' : eCtrl.text.trim(),
                'phone':    pCtrl.text.trim().isEmpty ? '-' : pCtrl.text.trim(),
                'afm':      aCtrl.text.trim().isEmpty ? '-' : aCtrl.text.trim(),
                'company':  cCtrl.text.trim().isEmpty ? '-' : cCtrl.text.trim(),
                'cardId':   cardCtrl.text.trim(),
                'active':   true,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Αποθήκευση', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Dialog: επεξεργασία εργαζόμενου ──────────────────────────
  void _showEditEmployeeDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String,dynamic>;
    final nCtrl = TextEditingController(text: data['name']   ?? '');
    final rCtrl = TextEditingController(text: data['role']   ?? '');
    final eCtrl = TextEditingController(text: data['email']  ?? '');
    final pCtrl = TextEditingController(text: data['phone']  ?? '');
    final aCtrl = TextEditingController(text: data['afm']    ?? '');
    final cCtrl = TextEditingController(text: data['company']?? '');
    final cardCtrl = TextEditingController(text: data['cardId'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E252D),
        title: const Text('Επεξεργασία Στοιχείων', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _buildEditField(nCtrl, 'Όνομα'),
            _buildEditField(aCtrl, 'ΑΦΜ'),
            _buildEditField(cCtrl, 'Εταιρεία'),
            _buildEditField(rCtrl, 'Ρόλος'),
            _buildEditField(eCtrl, 'Email'),
            _buildEditField(pCtrl, 'Τηλέφωνο'),
            _buildEditField(cardCtrl, 'Card ID (NFC/QR)'),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ακύρωση', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              await doc.reference.update({
                'name':    nCtrl.text.trim(),
                'role':    rCtrl.text.trim(),
                'email':   eCtrl.text.trim(),
                'phone':   pCtrl.text.trim(),
                'afm':     aCtrl.text.trim(),
                'company': cCtrl.text.trim(),
                'cardId':  cardCtrl.text.trim(),
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Ενημέρωση', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Dialog: λεπτομέρειες εργαζόμενου ─────────────────────────
  void _showEmployeeDetails(DocumentSnapshot empDoc, Map<String,dynamic> lastMove, String lastMood) {
    final data = empDoc.data() as Map<String,dynamic>;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E252D),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Column(children: [
              Container(width: 50, height: 5, margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
              CircleAvatar(radius: 40, backgroundColor: Colors.blueAccent.withOpacity(0.2),
                  child: const Icon(Icons.person, size: 40, color: Colors.blueAccent)),
              const SizedBox(height: 15),
              Text(data['name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 5),
              Text(data['role'] ?? '', style: const TextStyle(fontSize: 16, color: Colors.blueAccent)),
            ])),
            const SizedBox(height: 25),
            _buildDetailRow(Icons.badge_outlined,       'ΑΦΜ',              data['afm']     ?? '-'),
            _buildDetailRow(Icons.business_outlined,    'Εταιρεία',         data['company'] ?? '-'),
            _buildDetailRow(Icons.email_outlined,       'Email',            data['email']   ?? '-'),
            _buildDetailRow(Icons.phone_outlined,       'Τηλέφωνο',         data['phone']   ?? '-'),
            _buildDetailRow(Icons.credit_card,          'Card ID',          data['cardId']  ?? '-'),
            _buildDetailRow(Icons.access_time_outlined, 'Τελευταία Κίνηση', lastMove['label'] ?? '-'),
            _buildDetailRow(Icons.mood,                 'Τελευταία Διάθεση',lastMood.isEmpty ? '-' : '${_moodEmoji[lastMood] ?? ''} $lastMood'),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 15)),
                child: const Text('Κλείσιμο', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ── Dialog: διαγραφή ──────────────────────────────────────────
  void _showDeleteConfirmationDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String,dynamic>;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E252D),
        title: const Text('Επιβεβαίωση', style: TextStyle(color: Colors.white)),
        content: Text('Διαγραφή υπαλλήλου: ${data['name']};', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ακύρωση', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await doc.reference.delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Διαγραφή', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF12181F),
      appBar: AppBar(
        title: const Text('Dashboard Εργοδότη', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E252D),
        elevation: 2, centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isDesktop
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 4, child: _buildEmployeeContainer(false)),
              const SizedBox(width: 30),
              Expanded(flex: 6, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _buildChartWidgets()))),
            ])
          : SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ..._buildChartWidgets(),
              const SizedBox(height: 20),
              _buildEmployeeContainer(true),
            ])),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CHART WIDGETS — live από Firestore
  // ═══════════════════════════════════════════════════════════════
  List<Widget> _buildChartWidgets() {
    return [
      // ── Stat cards σήμερα ──────────────────────────────────────
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .where('date', isEqualTo: _today)
            .snapshots(),
        builder: (context, snap) {
          final docs    = snap.data?.docs ?? [];
          final present = docs.where((d) => d['action'] == 'ΠΡΟΣΕΛΕΥΣΗ').length;
          final left    = docs.where((d) => d['action'] == 'ΑΠΟΧΩΡΗΣΗ').length;
          final active  = present - left < 0 ? 0 : present - left;
          return Row(children: [
            Expanded(child: _buildStatCard('Παρόντες',      '$active',  Colors.greenAccent)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('Αποχώρησαν',   '$left',    Colors.orangeAccent)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('Κινήσεις σήμερα','${docs.length}', Colors.blueAccent)),
          ]);
        },
      ),
      const SizedBox(height: 30),

      // ── Pie chart παρουσίας σήμερα ─────────────────────────────
      const Text('Στατιστικά Παρουσίας', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      const SizedBox(height: 15),
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .where('date', isEqualTo: _today)
            .snapshots(),
        builder: (context, snap) {
          final docs      = snap.data?.docs ?? [];
          final arrivals  = docs.where((d) => d['action'] == 'ΠΡΟΣΕΛΕΥΣΗ').length.toDouble();
          final departures= docs.where((d) => d['action'] == 'ΑΠΟΧΩΡΗΣΗ').length.toDouble();
          final total     = arrivals + departures;
          if (total == 0) {
            return Container(height: 150, alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFF1E252D), borderRadius: BorderRadius.circular(16)),
              child: const Text('Δεν υπάρχουν κινήσεις σήμερα', style: TextStyle(color: Colors.white54)));
          }
          return Container(
            height: 250, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1E252D), borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Expanded(flex: 3, child: PieChart(PieChartData(
                sectionsSpace: 2, centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(color: Colors.greenAccent, value: arrivals,   title: '${(arrivals/total*100).toStringAsFixed(0)}%',   radius: 30, titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black87)),
                  PieChartSectionData(color: Colors.orangeAccent,value: departures, title: '${(departures/total*100).toStringAsFixed(0)}%', radius: 30, titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black87)),
                ],
              ))),
              Expanded(flex: 2, child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildLegendItem(Colors.greenAccent,  'Προσελεύσεις (${arrivals.toInt()})'),
                const SizedBox(height: 10),
                _buildLegendItem(Colors.orangeAccent, 'Αποχωρήσεις (${departures.toInt()})'),
              ])),
            ]),
          );
        },
      ),
      const SizedBox(height: 30),

      // ── Bar chart mood σήμερα ──────────────────────────────────
      const Text('Δείκτης Ευεξίας (Σήμερα)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      const SizedBox(height: 15),
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .where('date', isEqualTo: _today)
            .where('action', isEqualTo: 'ΑΠΟΧΩΡΗΣΗ')
            .snapshots(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          // Μέτρηση ανά mood
          final Map<String,int> counts = { for (var m in _moodLabels) m: 0 };
          for (final d in docs) {
            final m = d['mood'] as String?;
            if (m != null && counts.containsKey(m)) counts[m] = counts[m]! + 1;
          }
          final maxY = (counts.values.isEmpty ? 1 : counts.values.reduce((a,b) => a > b ? a : b)).toDouble();
          if (docs.isEmpty) {
            return Container(height: 150, alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFF1E252D), borderRadius: BorderRadius.circular(16)),
              child: const Text('Δεν υπάρχουν δεδομένα διάθεσης σήμερα', style: TextStyle(color: Colors.white54)));
          }
          return Container(
            height: 250, padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(color: const Color(0xFF1E252D), borderRadius: BorderRadius.circular(16)),
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY + 1,
              barTouchData: BarTouchData(enabled: true, touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.black87,
                getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                  '${_moodLabels[group.x]}\n${rod.toY.toInt()} άτομα',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              )),
              titlesData: FlTitlesData(
                leftTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  getTitlesWidget: (value, _) {
                    final emojis = ['😄','🙂','😐','😕','😞'];
                    final i = value.toInt();
                    if (i < 0 || i >= emojis.length) return const SizedBox.shrink();
                    return SizedBox(
                      height: 40,
                      child: Center(
                        child: Text(emojis[i], style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  },
                )),
              ),
              gridData:   const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups:  List.generate(_moodLabels.length, (i) {
                final label = _moodLabels[i];
                return BarChartGroupData(x: i, barRods: [BarChartRodData(
                  toY:   counts[label]!.toDouble(),
                  color: _moodColors[label]!,
                  width: 22, borderRadius: BorderRadius.circular(6),
                )]);
              }),
            )),
          );
        },
      ),
      const SizedBox(height: 30),

      // ── Line chart τελευταίες 7 μέρες ─────────────────────────
      const Text('Τάση Παρουσιών (Εβδομάδα)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      const SizedBox(height: 15),
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .where('date', whereIn: _last7Days)
            .where('action', isEqualTo: 'ΠΡΟΣΕΛΕΥΣΗ')
            .snapshots(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          // Μέτρηση ανά μέρα
          final Map<String,int> perDay = { for (var d in _last7Days) d: 0 };
          for (final d in docs) {
            final date = d['date'] as String?;
            if (date != null && perDay.containsKey(date)) perDay[date] = perDay[date]! + 1;
          }
          final spots = _last7Days.asMap().entries.map((e) =>
            FlSpot(e.key.toDouble(), perDay[e.value]!.toDouble())).toList();
          final maxY = (perDay.values.isEmpty ? 1 : perDay.values.reduce((a,b) => a > b ? a : b)).toDouble() + 1;
          final dayLabels = _last7Days.map((d) => d.substring(8)).toList(); // μόνο η μέρα π.χ. "05"

          return Container(
            height: 220, padding: const EdgeInsets.only(right: 20, left: 10, top: 20, bottom: 10),
            decoration: BoxDecoration(color: const Color(0xFF1E252D), borderRadius: BorderRadius.circular(16)),
            child: LineChart(LineChartData(
              minX: 0, maxX: 6,   // ✅ Ακριβώς 7 σημεία (0-6), χωρίς extra ticks
              minY: 0, maxY: maxY,
              gridData:   const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1, // ✅ Ένα label ανά σημείο — χωρίς διπλά
                  getTitlesWidget: (value, _) {
                    final i = value.toInt();
                    if (i < 0 || i >= dayLabels.length || value != i.toDouble()) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(dayLabels[i], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    );
                  },
                )),
              ),
              lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => Colors.black87,
                getTooltipItems: (spots) => spots.map((s) =>
                  LineTooltipItem('${s.y.toInt()} Προσελεύσεις', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))).toList(),
              )),
              lineBarsData: [LineChartBarData(
                spots: spots,
                isCurved: false,  // ✅ Ευθείες γραμμές — χωρίς ψεύτικα dips
                color: Colors.blueAccent, barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: true, color: Colors.blueAccent.withOpacity(0.15)),
              )],
            )),
          );
        },
      ),
      const SizedBox(height: 20),
    ];
  }

  // ═══════════════════════════════════════════════════════════════
  // ΛΙΣΤΑ ΕΡΓΑΖΟΜΕΝΩΝ — live από Firestore
  // ═══════════════════════════════════════════════════════════════
  Widget _buildEmployeeContainer(bool isMobile) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('employees')
          .where('active', isEqualTo: true)
          .snapshots(),
      builder: (context, empSnap) {
        if (empSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        }
        final empDocs = (empSnap.data?.docs ?? [])
          ..sort((a, b) {
            final aName = (a.data() as Map<String,dynamic>)['name'] as String? ?? '';
            final bName = (b.data() as Map<String,dynamic>)['name'] as String? ?? '';
            return aName.compareTo(bName);
          });

        // Για κάθε εργαζόμενο παίρνουμε live την τελευταία κίνηση από attendance
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF1A2027), borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Ομάδα Εργασίας', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                IconButton(onPressed: _showAddEmployeeDialog, icon: const Icon(Icons.person_add, color: Colors.blueAccent)),
              ]),
              const Divider(color: Colors.white24, height: 20),
              if (empDocs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('Δεν υπάρχουν εργαζόμενοι.\nΠροσθέστε με το κουμπί +', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54))),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: isMobile ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
                  itemCount: empDocs.length,
                  itemBuilder: (context, i) => _EmployeeTile(
                    empDoc:     empDocs[i],
                    today:      _today,
                    moodColors: _moodColors,
                    moodEmoji:  _moodEmoji,
                    onTap:      (lastMove, lastMood) => _showEmployeeDetails(empDocs[i], lastMove, lastMood),
                    onEdit:     () => _showEditEmployeeDialog(empDocs[i]),
                    onDelete:   () => _showDeleteConfirmationDialog(empDocs[i]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers UI ────────────────────────────────────────────────
  Widget _buildEditField(TextEditingController c, String label) =>
    Padding(padding: const EdgeInsets.only(bottom: 15),
      child: TextField(controller: c, style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white54),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)))));

  Widget _buildDetailRow(IconData icon, String title, String value) =>
    Padding(padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 15),
        Expanded(child: Text(title, style: const TextStyle(color: Colors.white54, fontSize: 14))),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
      ]));

  Widget _buildStatCard(String title, String count, Color color) =>
    Container(padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: const Color(0xFF1E252D), borderRadius: BorderRadius.circular(16),
        border: Border(bottom: BorderSide(color: color, width: 4))),
      child: Column(children: [
        Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 13, color: Colors.white70), textAlign: TextAlign.center),
      ]));

  Widget _buildLegendItem(Color color, String text) =>
    Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]);
}

// ══════════════════════════════════════════════════════════════════
// EmployeeTile — ξεχωριστό widget για να έχει το δικό του Stream
// ══════════════════════════════════════════════════════════════════
class _EmployeeTile extends StatelessWidget {
  final DocumentSnapshot empDoc;
  final String today;
  final Map<String,Color> moodColors;
  final Map<String,String> moodEmoji;
  final void Function(Map<String,dynamic> lastMove, String lastMood) onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EmployeeTile({
    required this.empDoc,
    required this.today,
    required this.moodColors,
    required this.moodEmoji,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final data   = empDoc.data() as Map<String,dynamic>;
    final cardId = data['cardId'] as String? ?? '';
    final name   = data['name']   as String? ?? '-';
    final role   = data['role']   as String? ?? '-';

    // Live stream της τελευταίας κίνησης για αυτόν τον εργαζόμενο σήμερα
    // ⚠️ Χωρίς orderBy για να μην χρειάζεται composite index — ταξινόμηση στη μνήμη
    return StreamBuilder<QuerySnapshot>(
      stream: cardId.isEmpty
        ? const Stream.empty()
        : FirebaseFirestore.instance
            .collection('attendance')
            .where('employeeId', isEqualTo: cardId)
            .where('date', isEqualTo: today)
            .snapshots(),
      builder: (context, attSnap) {
        // Ταξινόμηση στη μνήμη — πιο πρόσφατο πρώτο
        final allDocs = attSnap.data?.docs ?? [];
        final attDocs = [...allDocs]..sort((a, b) {
          final aTs = (a.data() as Map<String,dynamic>)['timestamp'] as Timestamp?;
          final bTs = (b.data() as Map<String,dynamic>)['timestamp'] as Timestamp?;
          if (aTs == null && bTs == null) return 0;
          if (aTs == null) return 1;
          if (bTs == null) return -1;
          return bTs.compareTo(aTs); // descending
        });
        String timeLabel = cardId.isEmpty ? 'Χωρίς κάρτα' : 'Εκτός Βάρδιας';
        String lastMood  = '';
        Color  dotColor  = Colors.grey;

        if (attDocs.isNotEmpty) {
          final last   = attDocs.first.data() as Map<String,dynamic>;
          final action = last['action'] as String? ?? '';
          final ts     = last['timestamp'] as Timestamp?;
          final mood   = last['mood']   as String? ?? '';

          if (ts != null) {
            final dt = ts.toDate();
            final hh = dt.hour.toString().padLeft(2,'0');
            final mm = dt.minute.toString().padLeft(2,'0');
            timeLabel = action == 'ΠΡΟΣΕΛΕΥΣΗ' ? '✅ Μέσα  $hh:$mm' : '🚪 Έξω  $hh:$mm';
            dotColor  = action == 'ΠΡΟΣΕΛΕΥΣΗ' ? const Color(0xFF00E676) : const Color(0xFFFF1744);
            lastMood  = mood;
          }
        }

        final lastMove = {'label': timeLabel};

        return Card(
          color: const Color(0xFF232A32),
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => onTap(lastMove, lastMood),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  // Έγχρωμη κουκίδα κατάστασης
                  Container(width: 10, height: 10, margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor,
                      boxShadow: [BoxShadow(color: dotColor.withOpacity(0.6), blurRadius: 6)])),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(role, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ])),
                ]),
                const Divider(color: Colors.white12, height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  // Ώρα + mood
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(timeLabel, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    if (lastMood.isNotEmpty)
                      Text('${moodEmoji[lastMood] ?? ''} $lastMood',
                        style: TextStyle(color: moodColors[lastMood] ?? Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                  // Κουμπιά
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(constraints: const BoxConstraints(), padding: const EdgeInsets.symmetric(horizontal: 8),
                      icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 18), onPressed: onEdit),
                    IconButton(constraints: const BoxConstraints(), padding: const EdgeInsets.symmetric(horizontal: 8),
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18), onPressed: onDelete),
                  ]),
                ]),
              ]),
            ),
          ),
        );
      },
    );
  }
}
