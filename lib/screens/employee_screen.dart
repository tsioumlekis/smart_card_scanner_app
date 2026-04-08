import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  // Η λίστα μας με τα ΑΦΜ και την Εταιρεία
  List<Map<String, dynamic>> employees = [
    {'name': 'Γιάννης Παπαδόπουλος', 'time': 'In: 08:05 π.μ.', 'mood': '😊 Χαρούμενος', 'color': Colors.green, 'role': 'Senior Developer', 'email': 'giannis.p@company.gr', 'phone': '6912345678', 'company': 'COMP-1746', 'afm': '123456789'},
    {'name': 'Μαρία Γεωργίου', 'time': 'Εκτός Βάρδιας', 'mood': '😴 Κουρασμένη', 'color': Colors.grey, 'role': 'HR Manager', 'email': 'maria.g@company.gr', 'phone': '6998765432', 'company': 'COMP-1746', 'afm': '987654321'},
    {'name': 'Κώστας Νικολάου', 'time': 'Απών', 'mood': '-', 'color': Colors.red, 'role': 'Sales Representative', 'email': 'kostas.n@company.gr', 'phone': '6944445555', 'company': 'COMP-1746', 'afm': '555444333'},
    {'name': 'Ελένη Κωνσταντίνου', 'time': 'In: 09:00 π.μ.', 'mood': '😊 Χαρούμενη', 'color': Colors.green, 'role': 'Designer', 'email': 'eleni.k@company.gr', 'phone': '6933334444', 'company': 'COMP-1746', 'afm': '111222333'},
    {'name': 'Νίκος Στεργίου', 'time': 'In: 08:30 π.μ.', 'mood': '😫 Στρεσαρισμένος', 'color': Colors.orangeAccent, 'role': 'Accountant', 'email': 'nikos.s@company.gr', 'phone': '6977778888', 'company': 'COMP-1746', 'afm': '999888777'},
  ];

  void _addEmployee(String name) {
    if (name.isNotEmpty) {
      setState(() {
        employees.add({'name': name, 'time': 'Εκτός Βάρδιας', 'mood': '-', 'color': Colors.grey, 'role': 'Νέος Υπάλληλος', 'email': '-', 'phone': '-', 'company': 'COMP-1746', 'afm': '-'});
      });
    }
  }

  void _updateEmployee(int index, String newName, String newRole, String newEmail, String newPhone, String newAfm, String newCompany) {
    setState(() {
      employees[index]['name'] = newName; employees[index]['role'] = newRole; employees[index]['email'] = newEmail;
      employees[index]['phone'] = newPhone; employees[index]['afm'] = newAfm; employees[index]['company'] = newCompany;
    });
  }

  void _removeEmployee(int index) {
    setState(() => employees.removeAt(index));
  }

  // --- Παράθυρα ---
  void _showEmployeeDetails(Map<String, dynamic> employee) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(color: Color(0xFF1E252D), borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25))),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Column(children: [
                Container(width: 50, height: 5, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
                CircleAvatar(radius: 40, backgroundColor: employee['color'].withOpacity(0.2), child: Icon(Icons.person, size: 40, color: employee['color'])),
                const SizedBox(height: 15), Text(employee['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 5), Text(employee['role'], style: const TextStyle(fontSize: 16, color: Colors.blueAccent)),
              ])),
              const SizedBox(height: 25),
              _buildDetailRow(Icons.badge_outlined, 'ΑΦΜ', employee['afm']),
              _buildDetailRow(Icons.business_outlined, 'Εταιρεία', employee['company']),
              _buildDetailRow(Icons.email_outlined, 'Email', employee['email']),
              _buildDetailRow(Icons.phone_outlined, 'Τηλέφωνο', employee['phone']),
              _buildDetailRow(Icons.access_time_outlined, 'Τελευταία Κίνηση', employee['time']),
              _buildDetailRow(Icons.mood, 'Κατάσταση Διάθεσης', employee['mood']),
              const SizedBox(height: 30),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 15)), child: const Text('Κλείσιμο', style: TextStyle(color: Colors.white)))),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showEditEmployeeDialog(int index) {
    var emp = employees[index];
    var nCtrl = TextEditingController(text: emp['name']); var rCtrl = TextEditingController(text: emp['role']);
    var eCtrl = TextEditingController(text: emp['email']); var pCtrl = TextEditingController(text: emp['phone']);
    var aCtrl = TextEditingController(text: emp['afm']); var cCtrl = TextEditingController(text: emp['company']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E252D), title: const Text('Επεξεργασία Στοιχείων', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [_buildEditField(nCtrl, 'Όνομα'), _buildEditField(aCtrl, 'ΑΦΜ'), _buildEditField(cCtrl, 'Εταιρεία'), _buildEditField(rCtrl, 'Ρόλος'), _buildEditField(eCtrl, 'Email'), _buildEditField(pCtrl, 'Τηλέφωνο')])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ακύρωση', style: TextStyle(color: Colors.white54))),
            ElevatedButton(onPressed: () { _updateEmployee(index, nCtrl.text, rCtrl.text, eCtrl.text, pCtrl.text, aCtrl.text, cCtrl.text); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent), child: const Text('Ενημέρωση', style: TextStyle(color: Colors.white))),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(int index) {
    showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: const Color(0xFF1E252D), title: const Text('Επιβεβαίωση', style: TextStyle(color: Colors.white)), content: Text('Διαγραφή υπαλλήλου: ${employees[index]['name']};', style: const TextStyle(color: Colors.white70)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ακύρωση', style: TextStyle(color: Colors.white54))), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () { _removeEmployee(index); Navigator.pop(context); }, child: const Text('Διαγραφή', style: TextStyle(color: Colors.white)))]));
  }

  void _showAddEmployeeDialog() {
    var nCtrl = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: const Color(0xFF1E252D), title: const Text('Προσθήκη Υπαλλήλου', style: TextStyle(color: Colors.white)), content: TextField(controller: nCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Ονοματεπώνυμο', hintStyle: TextStyle(color: Colors.white54))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ακύρωση', style: TextStyle(color: Colors.white54))), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent), onPressed: () { _addEmployee(nCtrl.text); Navigator.pop(context); }, child: const Text('Αποθήκευση', style: TextStyle(color: Colors.white)))]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12181F),
      appBar: AppBar(title: const Text('Dashboard Εργοδότη', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF1E252D), elevation: 2, centerTitle: false),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // ΑΡΙΣΤΕΡΗ ΣΤΗΛΗ: ΛΙΣΤΑ ΥΠΑΛΛΗΛΩΝ (40%)
            // ==========================================
            Expanded(
              flex: 4, 
              child: Container(
                padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1A2027), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Ομάδα Εργασίας', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)), IconButton(onPressed: _showAddEmployeeDialog, icon: const Icon(Icons.person_add, color: Colors.blueAccent))]),
                    const Divider(color: Colors.white24, height: 20),
                    Expanded(child: ListView.builder(itemCount: employees.length, itemBuilder: (context, index) => _buildEmployeeTile(employees[index], index))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 30),

            // ==========================================
            // ΔΕΞΙΑ ΣΤΗΛΗ: ΣΤΑΤΙΣΤΙΚΑ & ΓΡΑΦΗΜΑΤΑ (60%)
            // ==========================================
            Expanded(
              flex: 6,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Σταθερές Εντυπωσιακές Καρτέλες
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: _buildStatCard('Παρόντες', '14', Colors.greenAccent)), const SizedBox(width: 15),
                        Expanded(child: _buildStatCard('Απόντες', '2', Colors.redAccent)), const SizedBox(width: 15),
                        Expanded(child: _buildStatCard('Άδειες', '1', Colors.orangeAccent)),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // 2. Σταθερή Εντυπωσιακή Πίτα
                    const Text('Στατιστικά Παρουσίας', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 15),
                    Container(
                      height: 250, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1E252D), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2, centerSpaceRadius: 40,
                                sections: [
                                  PieChartSectionData(color: Colors.greenAccent, value: 70, title: '70%', radius: 30, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87)),
                                  PieChartSectionData(color: Colors.orangeAccent, value: 20, title: '20%', radius: 30, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87)),
                                  PieChartSectionData(color: Colors.redAccent, value: 10, title: '10%', radius: 30, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87)),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLegendItem(Colors.greenAccent, 'Στην ώρα'), const SizedBox(height: 10),
                                _buildLegendItem(Colors.orangeAccent, 'Αργοπορία'), const SizedBox(height: 10),
                                _buildLegendItem(Colors.redAccent, 'Απουσία'),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 3. Σταθερό Bar Chart με Tooltip
                    const Text('Δείκτης Ευεξίας (Σήμερα)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 15),
                    Container(
                      height: 200, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1E252D), borderRadius: BorderRadius.circular(16)),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround, maxY: 10, 
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (group) => Colors.black87,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                double percentage = (rod.toY / 14) * 100;
                                return BarTooltipItem('${rod.toY.toInt()} Άτομα\n(${percentage.toStringAsFixed(1)}%)', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13));
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true, leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                              const titles = ['Χαρούμενοι', 'Κουρασμένοι', 'Στρεσαρισμένοι'];
                              return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(titles[value.toInt()], style: const TextStyle(color: Colors.white70, fontSize: 12)));
                            })),
                          ),
                          gridData: const FlGridData(show: false), borderData: FlBorderData(show: false),
                          barGroups: [_buildBarGroup(0, 8, Colors.green), _buildBarGroup(1, 4, Colors.orange), _buildBarGroup(2, 2, Colors.red)],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ==========================================
                    // 4. ΝΕΟ: Γράφημα Γραμμής (Εβδομαδιαία Τάση)
                    // ==========================================
                    const Text('Τάση Παρουσιών (Εβδομάδα)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 15),
                    Container(
                      height: 220, padding: const EdgeInsets.only(right: 20, left: 10, top: 20, bottom: 10), decoration: BoxDecoration(color: const Color(0xFF1E252D), borderRadius: BorderRadius.circular(16)),
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false), // Χωρίς γραμμές στο φόντο για καθαρό look
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            show: true, leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                              const days = ['Δευ', 'Τρι', 'Τετ', 'Πεμ', 'Παρ'];
                              if (value.toInt() >= 0 && value.toInt() < days.length) {
                                return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(days[value.toInt()], style: const TextStyle(color: Colors.white70, fontSize: 12)));
                              }
                              return const Text('');
                            })),
                          ),
                          // Το ταμπελάκι (Tooltip) όταν περνάς το ποντίκι
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (spot) => Colors.black87,
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) => LineTooltipItem('${spot.y.toInt()} Παρόντες', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))).toList();
                              },
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              // Τα δεδομένα μας: (Μέρα, Άτομα)
                              spots: const [FlSpot(0, 12), FlSpot(1, 14), FlSpot(2, 13), FlSpot(3, 14), FlSpot(4, 15)],
                              isCurved: true, // Κάνει τη γραμμή απαλή καμπύλη
                              color: Colors.blueAccent,
                              barWidth: 4,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true), // Φαίνονται οι τελείες
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.blueAccent.withOpacity(0.15), // Το εφέ σκιάς κάτω από τη γραμμή
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30), // Κενό στο τέλος για να σκρολάρει άνετα
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---
  Widget _buildEditField(TextEditingController controller, String label) => Padding(padding: const EdgeInsets.only(bottom: 15), child: TextField(controller: controller, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white54), enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)), focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)))));
  Widget _buildDetailRow(IconData icon, String title, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row(children: [Icon(icon, color: Colors.white54, size: 20), const SizedBox(width: 15), Expanded(child: Text(title, style: const TextStyle(color: Colors.white54, fontSize: 14))), Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500))]));
  Widget _buildStatCard(String title, String count, Color color) => Container(padding: const EdgeInsets.symmetric(vertical: 20), decoration: BoxDecoration(color: const Color(0xFF1E252D), borderRadius: BorderRadius.circular(16), border: Border(bottom: BorderSide(color: color, width: 4))), child: Column(children: [Text(count, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)), const SizedBox(height: 8), Text(title, style: const TextStyle(fontSize: 15, color: Colors.white70))]));
  Widget _buildLegendItem(Color color, String text) => Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: color)), const SizedBox(width: 8), Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13))]);
  BarChartGroupData _buildBarGroup(int x, double y, Color color) => BarChartGroupData(x: x, barRods: [BarChartRodData(toY: y, color: color, width: 25, borderRadius: BorderRadius.circular(6))]);

  Widget _buildEmployeeTile(Map<String, dynamic> employee, int index) {
    return Card(
      color: const Color(0xFF232A32), margin: const EdgeInsets.symmetric(vertical: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showEmployeeDetails(employee), borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [CircleAvatar(backgroundColor: employee['color'].withOpacity(0.2), child: Icon(Icons.person, color: employee['color'])), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(employee['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis), Text(employee['time'], style: const TextStyle(color: Colors.white54, fontSize: 13))]))]),
              const Divider(color: Colors.white12, height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(employee['mood'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(constraints: const BoxConstraints(), padding: const EdgeInsets.symmetric(horizontal: 8), icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 18), onPressed: () => _showEditEmployeeDialog(index)),
                    IconButton(constraints: const BoxConstraints(), padding: const EdgeInsets.symmetric(horizontal: 8), icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18), onPressed: () => _showDeleteConfirmationDialog(index)),
                  ])
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}