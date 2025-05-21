import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyNumbersPage extends StatefulWidget {
  const EmergencyNumbersPage({super.key});

  @override
  State<EmergencyNumbersPage> createState() => _EmergencyNumbersPageState();
}

class _EmergencyNumbersPageState extends State<EmergencyNumbersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> emergencyContacts = const [
    {
      'category': 'Emergency Services',
      'contacts': [
        {'title': 'Police', 'number': '122', 'icon': Icons.local_police},
        {'title': 'Ambulance', 'number': '123', 'icon': Icons.emergency},
        {'title': 'Fire Department', 'number': '180', 'icon': Icons.fire_truck},
      ],
    },
    {
      'category': 'Utilities',
      'contacts': [
        {
          'title': 'Electricity Emergency',
          'number': '121',
          'icon': Icons.power
        },
        {'title': 'Gas Emergency', 'number': '129', 'icon': Icons.gas_meter},
      ],
    },
    {
      'category': 'Transportation',
      'contacts': [
        {'title': 'Tourist Police', 'number': '126', 'icon': Icons.tour},
        {
          'title': 'Road Assistance',
          'number': '01221110000',
          'icon': Icons.directions_car
        },
        {'title': 'Traffic Police', 'number': '128', 'icon': Icons.traffic},
        {'title': 'Railway Police', 'number': '145', 'icon': Icons.train},
      ],
    },
    {
      'category': 'Other Services',
      'contacts': [
        {'title': 'Coast Guard', 'number': '122', 'icon': Icons.beach_access},
      ],
    },
  ];

  List<Map<String, dynamic>> get filteredContacts {
    if (_searchQuery.isEmpty) return emergencyContacts;

    return emergencyContacts
        .map((category) {
          final filteredCategoryContacts = (category['contacts'] as List)
              .where((contact) =>
                  contact['title']
                      .toString()
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  contact['number'].toString().contains(_searchQuery))
              .toList();

          return {
            'category': category['category'],
            'contacts': filteredCategoryContacts,
          };
        })
        .where((category) => (category['contacts'] as List).isNotEmpty)
        .toList();
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone call')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Emergency Numbers'),
        backgroundColor: const Color(0xFF8B5CF6),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF8B5CF6),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search emergency services...',
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredContacts.length,
              itemBuilder: (context, categoryIndex) {
                final category = filteredContacts[categoryIndex];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        category['category'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    ...(category['contacts'] as List).map((contact) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              contact['icon'],
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                          title: Text(
                            contact['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            contact['number'],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.phone,
                              color: Color(0xFF8B5CF6),
                            ),
                            onPressed: () => _callNumber(contact['number']),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
