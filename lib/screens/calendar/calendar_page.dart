// screens/calendar/calendar_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with SingleTickerProviderStateMixin {
  late DateTime _currentMonth = DateTime.now();
  late int _selectedDate = DateTime.now().day;
  late TabController _tabController;
  String _selectedEventType = "all";

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.all(16),
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list, size: 16),
                    label: const Text('Filter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(
                          color: Color(0xFFCBD5E1)), // slate-300
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6), // violet-600
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
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_left, size: 16),
                    onPressed: _previousMonth,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMMM yyyy').format(_currentMonth),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.arrow_right, size: 16),
                    onPressed: _nextMonth,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                  ),
                ],
              ),
              const Row(
                children: [
                  Icon(
                    Icons.public,
                    size: 16,
                    color: Color(0xFF64748B), // slate-500
                  ),
                  SizedBox(width: 4),
                  Text(
                    'All City Events',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B), // slate-500
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventTypeFilter() {
    final eventTypes = [
      {"id": "all", "label": "All Events"},
      {"id": "government", "label": "Government", "icon": Icons.business},
      {"id": "volunteer", "label": "Volunteer", "icon": Icons.check_circle},
      {"id": "community", "label": "Community", "icon": Icons.people},
      {"id": "health", "label": "Health"},
      {"id": "payment", "label": "Payment"},
      {"id": "infrastructure", "label": "Infrastructure"},
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE2E8F0), // slate-200
            width: 1,
          ),
        ),
      ),
      // Fix for horizontal overflow - use a ListView with proper padding
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: eventTypes.length,
        itemBuilder: (context, index) {
          final eventType = eventTypes[index];
          final isSelected = _selectedEventType == eventType["id"];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedEventType = eventType["id"] as String;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFFF1F5F9), // violet-600 : slate-100
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Fix for row overflow
                  children: [
                    if (eventType.containsKey("icon"))
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          eventType["icon"] as IconData,
                          size: 12,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF1E293B), // white : slate-800
                        ),
                      ),
                    Text(
                      eventType["label"] as String,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF1E293B), // white : slate-800
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9), // slate-100
          borderRadius: BorderRadius.circular(9999),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          labelColor: const Color(0xFF8B5CF6), // violet-700
          unselectedLabelColor: const Color(0xFF64748B), // slate-500
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Month'),
            Tab(text: 'Week'),
            Tab(text: 'Day'),
            Tab(text: 'Agenda'),
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

  // Add a method to get events for a specific date
  List<Map<String, dynamic>> _getEventsForDate(DateTime date) {
    // In a real app, you would fetch events from a database or API
    // For this example, we'll use hardcoded events for specific dates

    // Format the date as a string for comparison (YYYY-MM-DD)
    final dateString = DateFormat('yyyy-MM-dd').format(date);

    // Map of events by date
    final eventsByDate = {
      // May 2025
      '2025-05-15': [
        {"title": "Park Cleanup", "color": const Color(0xFF22C55E)},
        {"title": "City Council Meeting", "color": const Color(0xFF3B82F6)},
        {"title": "Community Workshop", "color": const Color(0xFF6366F1)},
        {"title": "Volunteer Training", "color": const Color(0xFFF59E0B)},
      ],
      '2025-05-20': [
        {"title": "Bill Payment Deadline", "color": const Color(0xFFF59E0B)},
        {"title": "Library Event", "color": const Color(0xFF6366F1)},
      ],
      '2025-05-22': [
        {"title": "Vaccination Drive", "color": const Color(0xFFEF4444)},
        {"title": "Town Hall Meeting", "color": const Color(0xFF3B82F6)},
        {"title": "Art Exhibition", "color": const Color(0xFF6366F1)},
      ],
      '2025-05-25': [
        {"title": "Food Distribution", "color": const Color(0xFF6366F1)},
      ],
      '2025-05-18': [
        {"title": "Road Construction", "color": const Color(0xFFF97316)},
        {"title": "School Board Meeting", "color": const Color(0xFF3B82F6)},
      ],
      '2025-05-27': [
        {"title": "Budget Hearing", "color": const Color(0xFF3B82F6)},
      ],
      '2025-05-08': [
        {"title": "Farmers Market", "color": const Color(0xFF6366F1)},
        {"title": "Youth Sports", "color": const Color(0xFF22C55E)},
      ],

      // June 2025
      '2025-06-05': [
        {"title": "Summer Festival", "color": const Color(0xFF6366F1)},
        {"title": "City Planning", "color": const Color(0xFF3B82F6)},
      ],
      '2025-06-12': [
        {"title": "Blood Drive", "color": const Color(0xFFEF4444)},
      ],
      '2025-06-15': [
        {"title": "Tax Deadline", "color": const Color(0xFFF59E0B)},
      ],
      '2025-06-20': [
        {"title": "Park Concert", "color": const Color(0xFF6366F1)},
        {"title": "Beach Cleanup", "color": const Color(0xFF22C55E)},
      ],

      // April 2025
      '2025-04-10': [
        {"title": "Spring Cleanup", "color": const Color(0xFF22C55E)},
      ],
      '2025-04-15': [
        {"title": "Tax Day", "color": const Color(0xFFF59E0B)},
      ],
      '2025-04-22': [
        {"title": "Earth Day Event", "color": const Color(0xFF22C55E)},
      ],
      '2025-04-28': [
        {"title": "School Board", "color": const Color(0xFF3B82F6)},
      ],
    };

    // Return events for the given date, or an empty list if none
    return eventsByDate[dateString] ?? [];
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
            // In a real app, you would filter based on actual event categories
            // This is just a placeholder
            return true; // For now, show all events regardless of filter
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fix the overflow in this Row by using Expanded for the Text widget
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              // Add Expanded here to allow text to wrap or be truncated
              child: Text(
                "Events for ${DateFormat('MMMM d, yyyy').format(selectedDateTime)}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                overflow:
                    TextOverflow.ellipsis, // Add this to handle text overflow
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                "View All",
                style: TextStyle(
                  color: Color(0xFF8B5CF6), // violet-600
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (filteredEvents.isNotEmpty)
          Column(
            children: filteredEvents
                .map((event) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildEventCard(
                        title: event["title"],
                        time:
                            "9:00 AM - 12:00 PM", // In a real app, this would come from the event data
                        location:
                            "Location", // In a real app, this would come from the event data
                        category:
                            "Category", // In a real app, this would come from the event data
                        department:
                            "Department", // In a real app, this would come from the event data
                        color: event["color"],
                      ),
                    ))
                .toList(),
          )
        else
          Container(
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
                const Text(
                  "No events scheduled for this day",
                  style: TextStyle(
                    color: Color(0xFF64748B), // slate-500
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text("Add Event"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6), // violet-600
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
    String? location,
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
                    if (location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Color(0xFF64748B), // slate-500
                          ),
                          const SizedBox(width: 4),
                          Text(
                            location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B), // slate-500
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
                          color: Color(0xFF64748B), // slate-500
                        ),
                        const SizedBox(width: 4),
                        Text(
                          department,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B), // slate-500
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
                  // Wrap buttons in a Column for small screens
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 200) {
                        // Stack buttons vertically if space is limited
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildWeekViewButton("View", Icons.layers),
                            const SizedBox(height: 4),
                            _buildWeekViewButton("Today", Icons.grid_view),
                          ],
                        );
                      } else {
                        // Otherwise keep them in a row
                        return Row(
                          children: [
                            _buildWeekViewButton("View", Icons.layers),
                            const SizedBox(width: 8),
                            _buildWeekViewButton("Today", Icons.grid_view),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Rest of the code remains the same
              SizedBox(
                height: 500,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _buildTimeSlot("8:00 AM", null),
                    _buildTimeSlot(
                        "9:00 AM",
                        _buildTimeEvent(
                          "Park Cleanup",
                          "9:00 AM - 12:00 PM",
                          "Environmental Department",
                          const Color(0xFF22C55E), // green-500
                        )),
                    _buildTimeSlot("10:00 AM", null),
                    _buildTimeSlot("11:00 AM", null),
                    _buildTimeSlot("12:00 PM", null),
                    _buildTimeSlot("1:00 PM", null),
                    _buildTimeSlot(
                        "2:00 PM",
                        _buildTimeEvent(
                          "City Council Meeting",
                          "2:00 PM - 3:30 PM",
                          "City Council",
                          const Color(0xFF3B82F6), // blue-500
                        )),
                    _buildTimeSlot("3:00 PM", null),
                    _buildTimeSlot("4:00 PM", null),
                    _buildTimeSlot("5:00 PM", null),
                  ],
                ),
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
                    DateFormat('MMMM d, yyyy').format(DateTime(
                        _currentMonth.year,
                        _currentMonth.month,
                        _selectedDate)),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                    label: const Text("Today"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(
                          color: Color(0xFFCBD5E1)), // slate-300
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
              // Use a fixed height container with ListView for time slots
              SizedBox(
                height: 500, // Fixed height for time slots
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _buildTimeSlot("8:00 AM", null),
                    _buildTimeSlot(
                        "9:00 AM",
                        _buildDetailedTimeEvent(
                          "Park Cleanup",
                          "9:00 AM - 12:00 PM",
                          "Central Park",
                          "Environmental Department",
                          const Color(0xFF22C55E), // green-500
                        )),
                    _buildTimeSlot("10:00 AM", null),
                    _buildTimeSlot("11:00 AM", null),
                    _buildTimeSlot("12:00 PM", null),
                    _buildTimeSlot("1:00 PM", null),
                    _buildTimeSlot(
                        "2:00 PM",
                        _buildDetailedTimeEvent(
                          "City Council Meeting",
                          "2:00 PM - 3:30 PM",
                          "City Hall",
                          "City Council",
                          const Color(0xFF3B82F6), // blue-500
                        )),
                    _buildTimeSlot("3:00 PM", null),
                    _buildTimeSlot("4:00 PM", null),
                    _buildTimeSlot("5:00 PM", null),
                  ],
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
    final events = [
      {
        "id": 1,
        "title": "Park Cleanup",
        "time": "9:00 AM - 12:00 PM",
        "location": "Central Park",
        "category": "Volunteer",
        "department": "Environmental Department",
        "color": const Color(0xFF22C55E), // green-500
        "day": 15,
      },
      {
        "id": 2,
        "title": "City Council Meeting",
        "time": "2:00 PM - 3:30 PM",
        "location": "City Hall",
        "category": "Government",
        "department": "City Council",
        "color": const Color(0xFF3B82F6), // blue-500
        "day": 15,
      },
      {
        "id": 3,
        "title": "Utility Bill Payment Deadline",
        "time": "All Day",
        "category": "Payment",
        "department": "Finance Department",
        "color": const Color(0xFFF59E0B), // amber-500
        "day": 20,
      },
      {
        "id": 4,
        "title": "Public Vaccination Drive",
        "time": "10:00 AM - 4:00 PM",
        "location": "Community Center",
        "category": "Health",
        "department": "Health Department",
        "color": const Color(0xFFEF4444), // rose-500
        "day": 22,
      },
      {
        "id": 5,
        "title": "Food Distribution",
        "time": "1:00 PM - 5:00 PM",
        "location": "Downtown Square",
        "category": "Community",
        "department": "Social Services",
        "color": const Color(0xFF6366F1), // indigo-500
        "day": 25,
      },
      {
        "id": 6,
        "title": "Road Construction Begins",
        "time": "7:00 AM - 5:00 PM",
        "location": "Main Street",
        "category": "Infrastructure",
        "department": "Public Works",
        "color": const Color(0xFFF97316), // orange-500
        "day": 18,
      },
      {
        "id": 7,
        "title": "Public Budget Hearing",
        "time": "6:00 PM - 8:00 PM",
        "location": "City Hall",
        "category": "Government",
        "department": "Finance Department",
        "color": const Color(0xFF3B82F6), // blue-500
        "day": 27,
      },
      {
        "id": 8,
        "title": "Farmers Market",
        "time": "8:00 AM - 1:00 PM",
        "location": "City Square",
        "category": "Community",
        "department": "Economic Development",
        "color": const Color(0xFF6366F1), // indigo-500
        "day": 8,
      },
    ];

    // Filter events based on selected event type
    final filteredEvents = events.where((event) {
      if (_selectedEventType == "all") return true;
      return event["category"].toString().toLowerCase() == _selectedEventType;
    }).toList();

    // Sort events by day
    filteredEvents.sort((a, b) => (a["day"] as int).compareTo(b["day"] as int));

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
                    "Upcoming Events",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list, size: 16),
                    label: const Text("Department"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(
                          color: Color(0xFFCBD5E1)), // slate-300
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
              // Use ListView.builder directly instead of Expanded
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredEvents.length,
                itemBuilder: (context, index) {
                  final event = filteredEvents[index];
                  return Container(
                    padding: const EdgeInsets.only(bottom: 16),
                    margin: const EdgeInsets.only(bottom: 16),
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
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9), // slate-100
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('MMM').format(DateTime(
                                    _currentMonth.year,
                                    _currentMonth.month,
                                    event["day"] as int)),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B), // slate-800
                                ),
                              ),
                              Text(
                                "${event["day"]}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B), // slate-800
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
                                      event["title"] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  _buildCategoryBadge(
                                      event["category"] as String),
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
                                    event["time"] as String,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B), // slate-500
                                    ),
                                  ),
                                ],
                              ),
                              if (event.containsKey("location")) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 12,
                                      color: Color(0xFF64748B), // slate-500
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      event["location"] as String,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B), // slate-500
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
                                    color: Color(0xFF64748B), // slate-500
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    event["department"] as String,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B), // slate-500
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
              // Add extra padding at the bottom
              const SizedBox(height: 16),
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
                    const maxEventsToShow = 2;
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
      onPressed: () {},
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF64748B),
        side: const BorderSide(color: Color(0xFFCBD5E1)), // slate-300
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        textStyle: const TextStyle(fontSize: 14),
      ),
    );
  }
}
