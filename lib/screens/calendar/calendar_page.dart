// screens/calendar/calendar_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/task.dart';
import '../../models/announcement.dart';

class CalendarPage extends StatefulWidget {
  final String userId;

  const CalendarPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with SingleTickerProviderStateMixin {
  late DateTime _currentMonth = DateTime.now();
  late int _selectedDate = DateTime.now().day;
  late TabController _tabController;
  String _selectedEventType = "all";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String? _error;

  // Format the current month for display
  String get formattedMonth {
    return DateFormat('MMMM yyyy').format(_currentMonth);
  }

  // Get the number of days in the current month
  int get daysInMonth {
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    final lastDay = nextMonth.subtract(const Duration(days: 1));
    return lastDay.day;
  }

  // Get the weekday of the first day of the month (0 = Sunday, 1 = Monday, etc.)
  int get firstWeekday {
    return DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;
  }

  // Navigate to the previous month
  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      // Adjust selected date if it's beyond the days in the new month
      if (_selectedDate > daysInMonth) {
        _selectedDate = daysInMonth;
      }
    });
  }

  // Navigate to the next month
  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      // Adjust selected date if it's beyond the days in the new month
      if (_selectedDate > daysInMonth) {
        _selectedDate = daysInMonth;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchEvents() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Fetch tasks
      final tasksSnapshot =
          await _firestore.collection('tasks').orderBy('startTime').get();

      // Fetch announcements
      final announcementsSnapshot = await _firestore
          .collection('announcements')
          .orderBy('startTime')
          .get();

      // Process tasks
      final tasks = tasksSnapshot.docs
          .map((doc) {
            final data = doc.data();
            DateTime? startTime;

            try {
              if (data['startTime'] is Timestamp) {
                startTime = (data['startTime'] as Timestamp).toDate();
              } else if (data['startTime'] is String) {
                try {
                  startTime = DateTime.parse(data['startTime']);
                } catch (e) {
                  print('Error parsing ISO date for task ${doc.id}: $e');
                  try {
                    startTime = DateFormat('yyyy-MM-dd HH:mm:ss')
                        .parse(data['startTime']);
                  } catch (e) {
                    print('Error parsing custom date for task ${doc.id}: $e');
                    return null;
                  }
                }
              }
            } catch (e) {
              print('Error parsing date for task ${doc.id}: $e');
              return null;
            }

            if (startTime == null) return null;

            String location = 'No location set';
            if (data['location'] != null) {
              if (data['location'] is GeoPoint) {
                final geoPoint = data['location'] as GeoPoint;
                location =
                    '${geoPoint.latitude.toStringAsFixed(6)}, ${geoPoint.longitude.toStringAsFixed(6)}';
              } else if (data['location'] is String) {
                location = data['location'] as String;
              } else if (data['location'] is Map<String, dynamic>) {
                final loc = data['location'] as Map<String, dynamic>;
                if (loc.containsKey('latitude') &&
                    loc.containsKey('longitude')) {
                  location = '${loc['latitude']}, ${loc['longitude']}';
                }
              }
            }

            // Get volunteeredUsers list
            List<dynamic> volunteeredUsers = [];
            if (data['volunteeredUsers'] != null) {
              if (data['volunteeredUsers'] is List) {
                volunteeredUsers = List<dynamic>.from(data['volunteeredUsers']);
              }
            }

            return {
              'title': data['name'] ?? 'Unnamed Task',
              'color': _getCategoryColor(data['label'] ?? ''),
              'date': startTime,
              'type': 'task',
              'id': doc.id,
              'description': data['description'] ?? '',
              'department': data['department'] ?? '',
              'location': location,
              'volunteeredUsers': volunteeredUsers,
            };
          })
          .where((task) => task != null)
          .cast<Map<String, dynamic>>()
          .toList();

      // Process announcements
      final announcements = announcementsSnapshot.docs
          .map((doc) {
            final data = doc.data();
            DateTime? startTime;

            try {
              if (data['startTime'] is Timestamp) {
                startTime = (data['startTime'] as Timestamp).toDate();
              } else if (data['startTime'] is String) {
                try {
                  startTime = DateTime.parse(data['startTime']);
                } catch (e) {
                  print(
                      'Error parsing ISO date for announcement ${doc.id}: $e');
                  try {
                    startTime = DateFormat('yyyy-MM-dd HH:mm:ss')
                        .parse(data['startTime']);
                  } catch (e) {
                    print(
                        'Error parsing custom date for announcement ${doc.id}: $e');
                    return null;
                  }
                }
              }
            } catch (e) {
              print('Error parsing date for announcement ${doc.id}: $e');
              return null;
            }

            if (startTime == null) return null;

            String location = 'No location set';
            if (data['location'] != null) {
              if (data['location'] is GeoPoint) {
                final geoPoint = data['location'] as GeoPoint;
                location =
                    '${geoPoint.latitude.toStringAsFixed(6)}, ${geoPoint.longitude.toStringAsFixed(6)}';
              } else if (data['location'] is String) {
                location = data['location'] as String;
              } else if (data['location'] is Map<String, dynamic>) {
                final loc = data['location'] as Map<String, dynamic>;
                if (loc.containsKey('latitude') &&
                    loc.containsKey('longitude')) {
                  location = '${loc['latitude']}, ${loc['longitude']}';
                }
              }
            }

            return {
              'title': data['name'] ?? 'Unnamed Announcement',
              'color': _getCategoryColor(data['label'] ?? ''),
              'date': startTime,
              'type': 'announcement',
              'id': doc.id,
              'description': data['description'] ?? '',
              'department': data['department'] ?? '',
              'location': location,
            };
          })
          .where((announcement) => announcement != null)
          .cast<Map<String, dynamic>>()
          .toList();

      setState(() {
        _events = [...tasks, ...announcements];
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching events: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'environment':
        return const Color(0xFF22C55E); // green-500
      case 'community':
        return const Color(0xFF6366F1); // indigo-500
      case 'healthcare':
        return const Color(0xFFEF4444); // red-500
      case 'education':
        return const Color(0xFFF59E0B); // amber-500
      default:
        return const Color(0xFF3B82F6); // blue-500
    }
  }

  // Add a method to get events for a specific date
  List<Map<String, dynamic>> _getEventsForDate(DateTime date) {
    return _events.where((event) {
      final eventDate = event['date'] as DateTime;
      return eventDate.year == date.year &&
          eventDate.month == date.month &&
          eventDate.day == date.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(child: Text('Error: $_error')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // slate-50
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildEventTypeFilter(),
            Expanded(
              child: Column(
                children: [
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMonthView(),
                        _buildWeekView(),
                        _buildDayView(),
                        _buildAgendaView(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Community Calendar',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF8B5CF6),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left, size: 12),
                      onPressed: _previousMonth,
                      color: const Color(0xFF8B5CF6),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMMM yyyy').format(_currentMonth),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF8B5CF6),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right, size: 12),
                      onPressed: _nextMonth,
                      color: const Color(0xFF8B5CF6),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.public,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'All City Events',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventTypeFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip("All", "all"),
            _buildFilterChip("Tasks", "task"),
            _buildFilterChip("Announcements", "announcement"),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedEventType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedEventType = value;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month, size: 14),
                  SizedBox(width: 4),
                  Text('Month'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.view_week, size: 14),
                  SizedBox(width: 4),
                  Text('Week'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 14),
                  SizedBox(width: 4),
                  Text('Day'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, size: 14),
                  SizedBox(width: 4),
                  Text('Agenda'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fix for the main month view overflow - use SingleChildScrollView
  Widget _buildMonthView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _buildCalendarGrid(),
            const SizedBox(height: 16),
            _buildSelectedDayEvents(),
            // Add extra padding at the bottom to ensure content is visible
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

    // Generate days for the month view
    List<int?> days = [];
    final firstDay = firstWeekday;
    final totalDays = daysInMonth;

    // Add empty cells for days before the 1st of the month
    for (int i = 0; i < firstDay; i++) {
      days.add(null);
    }

    // Add days of the month
    for (int i = 1; i <= totalDays; i++) {
      days.add(i);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Weekday headers
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE2E8F0), // slate-200
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: weekdays.map((day) {
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B), // slate-500
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Calendar days grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisExtent: 80, // Fixed height for day cells
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              if (day == null) {
                return Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Color(0xFFE2E8F0)),
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    color: Color(0xFFF8FAFC), // slate-50
                  ),
                );
              }

              // Get events for this day
              final date =
                  DateTime(_currentMonth.year, _currentMonth.month, day);
              final events = _getEventsForDate(date);

              // Filter events based on selected event type
              final filteredEvents = _selectedEventType == "all"
                  ? events
                  : events.where((event) {
                      // In a real app, you would filter based on actual event categories
                      return true; // For now, show all events regardless of filter
                    }).toList();

              return _buildDayCell(
                day: day,
                isSelected: day == _selectedDate,
                events: filteredEvents,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayEvents() {
    // Get the selected date as a DateTime
    final selectedDateTime =
        DateTime(_currentMonth.year, _currentMonth.month, _selectedDate);

    // Get events for the selected date
    final events = _getEventsForDate(selectedDateTime);

    // Filter events based on selected event type
    final filteredEvents = _selectedEventType == "all"
        ? events
        : events.where((event) {
            return event['type'] == _selectedEventType;
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Events for ${DateFormat('MMMM d, yyyy').format(selectedDateTime)}",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        if (filteredEvents.isNotEmpty)
          Column(
            children: filteredEvents.map((event) {
              final startTime = event['date'] as DateTime;
              final endTime =
                  startTime.add(const Duration(hours: 2)); // Default duration
              final timeString =
                  '${DateFormat('h:mm a').format(startTime)} - ${DateFormat('h:mm a').format(endTime)}';

              String location = 'No location set';
              if (event['location'] != null) {
                if (event['location'] is Map<String, dynamic>) {
                  final loc = event['location'] as Map<String, dynamic>;
                  location = '${loc['latitude']}, ${loc['longitude']}';
                } else {
                  location = event['location'].toString();
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildEventCard(
                  title: event['title'],
                  time: timeString,
                  location: location,
                  category: event['type'] == 'task' ? 'Task' : 'Announcement',
                  department: event['department'] ?? 'No Department',
                  color: event['color'],
                ),
              );
            }).toList(),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.event_busy,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  "No events scheduled for this day",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEventCard({
    required String title,
    required String time,
    required String location,
    required String category,
    required String department,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        // Navigate to event detail
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              constraints: const BoxConstraints(
                minHeight: 100,
              ),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildCategoryBadge(category),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 12,
                          color: Color(0xFF64748B), // slate-500
                        ),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B), // slate-500
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: Color(0xFF64748B), // slate-500
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B), // slate-500
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.business,
                          size: 12,
                          color: Color(0xFF64748B), // slate-500
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            department,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B), // slate-500
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    Color bgColor;
    Color textColor;

    switch (category) {
      case 'Volunteer':
        bgColor = const Color(0xFFDCFCE7); // green-100
        textColor = const Color(0xFF166534); // green-800
        break;
      case 'Government':
        bgColor = const Color(0xFFDBEAFE); // blue-100
        textColor = const Color(0xFF1E40AF); // blue-800
        break;
      case 'Payment':
        bgColor = const Color(0xFFFEF3C7); // amber-100
        textColor = const Color(0xFF92400E); // amber-800
        break;
      case 'Health':
        bgColor = const Color(0xFFFEE2E2); // rose-100
        textColor = const Color(0xFF9B1C1C); // rose-800
        break;
      case 'Community':
        bgColor = const Color(0xFFE0E7FF); // indigo-100
        textColor = const Color(0xFF3730A3); // indigo-800
        break;
      case 'Infrastructure':
        bgColor = const Color(0xFFFFEDD5); // orange-100
        textColor = const Color(0xFF9A3412); // orange-800
        break;
      default:
        bgColor = const Color(0xFFF1F5F9); // slate-100
        textColor = const Color(0xFF1E293B); // slate-800
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Fix for week view - use SingleChildScrollView
  Widget _buildWeekView() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    // Get events for the current week
    final weekEvents = _events.where((event) {
      final eventDate = event['date'] as DateTime;
      return eventDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          eventDate.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();

    // Filter events based on selected event type
    final filteredEvents = _selectedEventType == "all"
        ? weekEvents
        : weekEvents
            .where((event) => event['type'] == _selectedEventType)
            .toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Week of ${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('d, yyyy').format(endOfWeek)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      _buildWeekViewButton("This Week", Icons.view_week),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (filteredEvents.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No events scheduled for this week",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: List.generate(7, (index) {
                    final currentDate = startOfWeek.add(Duration(days: index));
                    final dayEvents = filteredEvents.where((event) {
                      final eventDate = event['date'] as DateTime;
                      return eventDate.year == currentDate.year &&
                          eventDate.month == currentDate.month &&
                          eventDate.day == currentDate.day;
                    }).toList();

                    return Container(
                      padding: const EdgeInsets.only(bottom: 16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      currentDate.day == DateTime.now().day &&
                                              currentDate.month ==
                                                  DateTime.now().month
                                          ? const Color(0xFF8B5CF6)
                                          : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat('E').format(currentDate),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: currentDate.day ==
                                                    DateTime.now().day &&
                                                currentDate.month ==
                                                    DateTime.now().month
                                            ? Colors.white
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                    Text(
                                      "${currentDate.day}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: currentDate.day ==
                                                    DateTime.now().day &&
                                                currentDate.month ==
                                                    DateTime.now().month
                                            ? Colors.white
                                            : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: dayEvents.isEmpty
                                    ? Text(
                                        "No events",
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                      )
                                    : Column(
                                        children: dayEvents.map((event) {
                                          final startTime =
                                              event['date'] as DateTime;
                                          final endTime = startTime
                                              .add(const Duration(hours: 2));
                                          final timeString =
                                              '${DateFormat('h:mm a').format(startTime)} - ${DateFormat('h:mm a').format(endTime)}';

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8),
                                            child: _buildEventCard(
                                              title: event['title'],
                                              time: timeString,
                                              location: event['location'] ??
                                                  'No location',
                                              category: event['type'] == 'task'
                                                  ? 'Task'
                                                  : 'Announcement',
                                              department: event['department'] ??
                                                  'No Department',
                                              color: event['color'],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlot(String time, Widget? event) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE2E8F0), // slate-200
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B), // slate-500
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: 8),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Color(0xFFE2E8F0), // slate-200
                    width: 1,
                  ),
                ),
              ),
              child: event ?? const SizedBox(height: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeEvent(
      String title, String time, String department, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            department,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Fix for day view - use SingleChildScrollView
  Widget _buildDayView() {
    final selectedDateTime =
        DateTime(_currentMonth.year, _currentMonth.month, _selectedDate);

    // Get events for the selected day
    final dayEvents = _getEventsForDate(selectedDateTime);

    // Filter events based on selected event type
    final filteredEvents = _selectedEventType == "all"
        ? dayEvents
        : dayEvents
            .where((event) => event['type'] == _selectedEventType)
            .toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMMM d, yyyy').format(selectedDateTime),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime.now();
                        _selectedDate = DateTime.now().day;
                      });
                    },
                    icon: const Icon(Icons.today, size: 16),
                    label: const Text("Today"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (filteredEvents.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No events scheduled for this day",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 500,
                  child: ListView(
                    shrinkWrap: true,
                    children: List.generate(24, (hour) {
                      final time = DateTime(selectedDateTime.year,
                          selectedDateTime.month, selectedDateTime.day, hour);
                      final eventsInHour = filteredEvents.where((event) {
                        final eventTime = event['date'] as DateTime;
                        return eventTime.hour == hour;
                      }).toList();

                      return _buildTimeSlot(
                        DateFormat('h:mm a').format(time),
                        eventsInHour.isEmpty
                            ? null
                            : Column(
                                children: eventsInHour.map((event) {
                                  final startTime = event['date'] as DateTime;
                                  final endTime =
                                      startTime.add(const Duration(hours: 2));
                                  final timeString =
                                      '${DateFormat('h:mm a').format(startTime)} - ${DateFormat('h:mm a').format(endTime)}';

                                  return _buildDetailedTimeEvent(
                                    event['title'],
                                    timeString,
                                    event['location'] ?? 'No location',
                                    event['department'],
                                    event['color'],
                                  );
                                }).toList(),
                              ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedTimeEvent(String title, String time, String location,
      String department, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 12,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                location,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            department,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Fix for agenda view - use SingleChildScrollView
  Widget _buildAgendaView() {
    // Get all events and sort them by date
    final sortedEvents = List<Map<String, dynamic>>.from(_events)
      ..sort(
          (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    // Filter to show only tasks that the user has participated in
    final filteredEvents = sortedEvents.where((event) {
      // Only include tasks (not announcements)
      if (event['type'] != 'task') return false;

      // Check if the user has participated in this task
      final volunteeredUsers = event['volunteeredUsers'] as List<dynamic>?;
      if (volunteeredUsers == null) return false;

      // Convert the list to strings and check if it contains the current user's ID
      return volunteeredUsers.map((e) => e.toString()).contains(widget.userId);
    }).toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "My Tasks",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (filteredEvents.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No tasks scheduled",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "You haven't volunteered for any tasks yet. Check the volunteer page to find opportunities!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    final eventDate = event['date'] as DateTime;
                    final timeString = DateFormat('h:mm a').format(eventDate);

                    return Container(
                      padding: const EdgeInsets.only(bottom: 16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('MMM').format(eventDate),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  "${eventDate.day}",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        event['title'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    _buildCategoryBadge('My Task'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      timeString,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                                if (event['location'] != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          event['location'],
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.business,
                                      size: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        event['department'],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0), // slate-200
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.home,
            label: 'Home',
            isSelected: false,
            onTap: () {
              // Navigate to home
            },
          ),
          _buildNavItem(
            icon: Icons.check_circle,
            label: 'Tasks',
            isSelected: false,
            onTap: () {
              // Navigate to tasks
            },
          ),
          _buildNavItem(
            icon: Icons.chat,
            label: 'Chat',
            isSelected: false,
            onTap: () {
              // Navigate to chat
            },
          ),
          _buildNavItem(
            icon: Icons.calendar_today,
            label: 'Calendar',
            isSelected: true,
            onTap: () {
              // Already on calendar
            },
          ),
          _buildNavItem(
            icon: Icons.person,
            label: 'Profile',
            isSelected: false,
            onTap: () {
              // Navigate to profile
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFEDE9FE)
                    : const Color(0xFFF1F5F9), // violet-100 : slate-100
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFF64748B), // violet-600 : slate-500
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFF64748B), // violet-600 : slate-500
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Updated day cell with ListView for mini events
  Widget _buildDayCell({
    required int day,
    required bool isSelected,
    required List<Map<String, dynamic>> events,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = day;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          border: const Border(
            right: BorderSide(color: Color(0xFFE2E8F0)), // slate-200
            bottom: BorderSide(color: Color(0xFFE2E8F0)), // slate-200
          ),
          color: isSelected
              ? const Color(0xFFEDE9FE)
              : Colors.white, // violet-50 : white
        ),
        child: Column(
          children: [
            // Date number with fixed height
            Container(
              height: 32,
              padding: const EdgeInsets.all(4),
              alignment: Alignment.center,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? const Color(0xFF8B5CF6)
                      : Colors.transparent, // violet-600 : transparent
                ),
                alignment: Alignment.center,
                child: Text(
                  day.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF1E293B), // white : slate-700
                  ),
                ),
              ),
            ),

            // Mini events with ListView
            if (events.isNotEmpty)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate how many events we can show
                    final maxEventsToShow = 2;
                    final visibleEvents = events.length > maxEventsToShow
                        ? events.sublist(0, maxEventsToShow)
                        : events;
                    final remainingEvents =
                        events.length - visibleEvents.length;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ListView for mini events
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: visibleEvents.length,
                            itemBuilder: (context, index) {
                              final event = visibleEvents[index];
                              return _buildMiniEvent(
                                event["title"],
                                event["color"],
                              );
                            },
                          ),
                        ),

                        // "+X more" indicator if needed
                        if (remainingEvents > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 2),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "+$remainingEvents more",
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B), // slate-500
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekViewButton(String label, IconData icon) {
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          _currentMonth = DateTime.now();
          _selectedDate = DateTime.now().day;
        });
      },
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF64748B),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        textStyle: const TextStyle(fontSize: 12),
      ),
    );
  }

  // Fixed mini event widget with proper constraints
  Widget _buildMiniEvent(String title, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1, left: 2, right: 2),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      height: 12, // Fixed height
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 7,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}
