import 'package:flutter/material.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  bool isWorking = false; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ταμπλό Υπαλλήλου', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isWorking ? 'Κατάσταση: ΕΝΤΟΣ ΕΡΓΑΣΙΑΣ' : 'Κατάσταση: ΕΚΤΟΣ ΕΡΓΑΣΙΑΣ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isWorking ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 60),
            GestureDetector(
              onTap: () {
                setState(() {
                  isWorking = !isWorking; 
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300), 
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: isWorking ? Colors.red : Colors.green, 
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 8))
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isWorking ? Icons.stop_circle_outlined : Icons.touch_app,
                        size: 70,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isWorking ? 'ΑΠΟΧΩΡΗΣΗ' : 'ΕΝΑΡΞΗ',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}