import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // For date formatting

class LocationInfo extends StatefulWidget {
  final String locationId;
  final String locationTitle;
  final String locationMarkerArea;

  const LocationInfo({
    super.key,
    required this.locationId,
    required this.locationTitle,
    required this.locationMarkerArea,
  });

  @override
  _LocationInfoState createState() => _LocationInfoState();
}

class _LocationInfoState extends State<LocationInfo> {
  String? selectedDayNotes;
  String? visitedBy; // Variable to hold 'visited_by' information
  DateTime focusedDay = DateTime.now(); // Store focused day
  DateTime? selectedDay; // Variable to keep track of the selected day

  // Function to format the selectedDay to 'yyyy-MM-dd'
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Function to fetch location visit information based on the selected date
  void _fetchVisitInfo(String formattedDate) {
    FirebaseFirestore.instance
        .collection('TASMAC_Locations')
        .doc(widget.locationId)
        .collection('Location_visits')
        .doc(formattedDate) // Date in 'yyyy-MM-dd' format
        .get()
        .then((visitDoc) {
      if (visitDoc.exists) {
        setState(() {
          selectedDayNotes =
              visitDoc['information'] ?? 'No information available';
          visitedBy = visitDoc['visited_by'] ?? 'No one';
        });
      } else {
        setState(() {
          selectedDayNotes = 'No notes available for this day.';
          visitedBy = 'No one';
        });
      }
    }).catchError((error) {
      setState(() {
        selectedDayNotes = 'Error fetching data: $error';
        visitedBy = 'No one';
      });
    });
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 8.0), // Space around text
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 8.0), // Space around text
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 0.0), // Add padding to the text
          child: Text(
            widget.locationTitle,
            style: const TextStyle(
              color: Colors.white, // White text color
              fontSize: 22, // Decreased font size
              fontFamily: 'Roboto', // Common mobile font style
            ),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0575E6), Color(0xFF021B79)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('TASMAC_Locations')
                  .doc(widget.locationId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (!snapshot.hasData) {
                  return const Text('Loading...');
                }

                DocumentSnapshot locationDoc = snapshot.data!;

                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    padding:
                        const EdgeInsets.all(16.0), // Padding inside the box
                    decoration: BoxDecoration(
                      color: Colors.white, // Background color for the box
                      borderRadius:
                          BorderRadius.circular(12.0), // Rounded corners
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12, // Shadow color
                          blurRadius: 8.0, // Softness of the shadow
                          offset: Offset(0, 2), // Position of the shadow
                        ),
                      ],
                      border: Border.all(
                        color: const Color(
                            0xFF0575E6), // Border color to match gradient
                        width: 2.0, // Border width
                      ),
                    ),
                    child: Column(
                      children: [
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(
                                2), // Adjust width for label column
                            1: FlexColumnWidth(
                                3), // Adjust width for value column
                          },
                          children: [
                            _buildTableRow(
                                'Marker Area', widget.locationMarkerArea),
                            _buildTableRow(
                                'Owner Name', '${locationDoc['owner_name']}'),
                            _buildTableRow(
                                'Owner No', '${locationDoc['owner_no']}'),
                            _buildTableRow(
                                'Supplier', '${locationDoc['supplier']}'),
                            _buildTableRow(
                                'Supplier No', '${locationDoc['supplier_no']}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Expanded widget for the Calendar and Notes
            Padding(
              padding: const EdgeInsets.all(16.0), // Padding around the notes
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedDayNotes != null
                        ? '“${selectedDayNotes!}”' // Add quotes around the notes
                        : 'No notes available',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold, // Make the text bold
                      color: Colors.black87, // Slightly muted text color
                    ),
                  ),
                  const SizedBox(
                      height: 16.0), // Space between notes and visited_by
                  Text(
                    'Visited by: ${visitedBy ?? 'No one'}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors
                          .black54, // Slightly muted text color for visited_by
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 8.0), // Space around the calendar
              child: TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime(2050),
                focusedDay: focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(
                      selectedDay, day); // Compare selectedDay with day
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    this.selectedDay = selectedDay; // Update the selected day
                    this.focusedDay = focusedDay; // Update the focused day
                  });

                  String formattedDate =
                      _formatDate(selectedDay); // Format the date
                  _fetchVisitInfo(
                      formattedDate); // Fetch visit information for the selected date
                },
                daysOfWeekHeight:
                    50, // Add more height between days of week and dates
                calendarStyle: const CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Color(0xFF0575E6), // Color for selected day
                    shape: BoxShape.circle, // Make the selected day a circle
                  ),
                  todayDecoration: BoxDecoration(
                    color: Color.fromARGB(
                        81, 163, 233, 253), // Lighter green for today's date
                    shape: BoxShape.circle,
                  ),
                  defaultTextStyle: TextStyle(
                    fontSize: 16, // Default text size
                  ),
                  selectedTextStyle: TextStyle(
                    color: Colors.white, // White text on the selected day
                  ),
                  todayTextStyle: TextStyle(
                    color: Colors.black, // Black text for today's date
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false, // Hide the format button
                  titleCentered: true, // Center the month/year title
                  titleTextStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0575E6), // Title color for the month/year
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: Color(0xFF0575E6), // Left chevron color
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: Color(0xFF0575E6), // Right chevron color
                  ),
                  headerPadding: EdgeInsets.only(
                      bottom: 8.0), // Add padding below the header
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: Color(0xFF0575E6), // Color for weekdays
                  ),
                  weekendStyle: TextStyle(
                    color: Color(0xFF0575E6), // Color for weekends
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
