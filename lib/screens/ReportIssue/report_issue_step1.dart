import 'package:flutter/material.dart';
import 'package:gov_app/screens/ReportIssue/report_issue_step2.dart';

class ReportIssueStep1 extends StatefulWidget {
  const ReportIssueStep1({Key? key}) : super(key: key);

  @override
  State<ReportIssueStep1> createState() => _ReportIssueStep1State();
}

class _ReportIssueStep1State extends State<ReportIssueStep1> {
  String selectedIssueType = 'Garbage Collection Issue';
  final TextEditingController _descriptionController = TextEditingController();

  // List of issue types
  final List<String> issueTypes = [
    'Garbage Collection Issue',
    'Road Maintenance',
    'Street Light Issue',
    'Water Supply Problem',
    'Public Safety Concern',
    'Other'
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Report an Issue'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Step 1 of 3'),
                    Text('33% Complete'),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: 0.33,
                  backgroundColor: Colors.grey[200],
                  color: Colors.green,
                  minHeight: 5,
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What type of issue would you like to report?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Dropdown for issue type
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedIssueType,
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: issueTypes.map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedIssueType = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Description text field for user input
                  const Text(
                    'Describe the issue:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Please provide details about the issue...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),

                  const Spacer(),

                  // Next button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to next step
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportIssueStep2(
                              issueType: selectedIssueType,
                              description: _descriptionController.text,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(100, 40),
                      ),
                      child: const Text('Next'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
