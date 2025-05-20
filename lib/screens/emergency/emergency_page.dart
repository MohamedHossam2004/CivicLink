import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyNumbersPage extends StatelessWidget {
  const EmergencyNumbersPage({super.key});

  final List<Map<String, String>> emergencyContacts = const [
    {'title': 'Police', 'number': '122'},
    {'title': 'Ambulance', 'number': '123'},
    {'title': 'Fire Department', 'number': '180'},
    {'title': 'Electricity Emergency', 'number': '121'},
    {'title': 'Gas Emergency', 'number': '129'},
    {'title': 'Tourist Police', 'number': '126'},
    {'title': 'Road Assistance', 'number': '01221110000'},
    {'title': 'Traffic Police', 'number': '128'},
    {'title': 'Coast Guard', 'number': '122'},
    {'title': 'Railway Police', 'number': '145'},
  ];

  Future<void> _callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Emergency Numbers in Egypt'),
        backgroundColor: const Color(0xFF8B5CF6),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: emergencyContacts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = emergencyContacts[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.phone, color: Color(0xFF8B5CF6)),
              title: Text(item['title'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text(item['number'] ?? '',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
              onTap: () => _callNumber(item['number'] ?? ''),
            ),
          );
        },
      ),
    );
  }
}
