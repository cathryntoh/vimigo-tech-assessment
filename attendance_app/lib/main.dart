import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  timeago.setLocaleMessages('en', timeago.EnMessages());
  runApp(MyApp());
}

class AttendanceRecord {
  final String user;
  final String phone;
  final DateTime checkIn;

  AttendanceRecord({
    required this.user, 
    required this.phone, 
    required this.checkIn
  });
}

// set up root of application
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance Records', 
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AttendanceListScreen(),
    );
  }
}

// define attendance list widget
class AttendanceListScreen extends StatefulWidget {
  @override
  AttendanceListScreenState createState() => AttendanceListScreenState();
}

// formats time as absolute time
String _formatDateTimeGeneral(DateTime dateTime) {
    return '${dateTime.day} ${_getMonthAbbreviation(dateTime.month)} ${dateTime.year}, ${_formatTime(dateTime)}';
}

// formats just the time
String _formatTime(DateTime dateTime) {
  String hour = (dateTime.hour % 12).toString().padLeft(2, '0'); 
  hour = hour == '00' ? '12' : hour; 
  String minute = dateTime.minute.toString().padLeft(2, '0');
  String period = dateTime.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

// retrieves month
String _getMonthAbbreviation(int month) {
  switch (month) {
    case 1:
      return 'Jan';
    case 2:
      return 'Feb';
    case 3:
      return 'Mar';
    case 4:
      return 'Apr';
    case 5:
      return 'May';
    case 6:
      return 'Jun';
    case 7:
      return 'Jul';
    case 8:
      return 'Aug';
    case 9:
      return 'Sep';
    case 10:
      return 'Oct';
    case 11:
      return 'Nov';
    case 12:
      return 'Dec';
    default:
      return '';
  }
}

// define state and behaviour of AttendanceListScreen
class AttendanceListScreenState extends State<AttendanceListScreen> {
  List<AttendanceRecord> _attendanceRecords = [];
  List<AttendanceRecord> _filteredRecords = [];
  bool _useTimeAgo = true;

  // initialize stateful widgets
  @override
  void initState() {
    super.initState();
    _loadAttendanceRecords();
    _loadTimeFormatPreference();
  }

  // formats time as absolute time
  String _formatDateTime(DateTime dateTime) {
    if (_useTimeAgo) {
      return timeago.format(dateTime, locale: 'en');
    } else {
      return '${dateTime.day} ${_getMonthAbbreviation(dateTime.month)} ${dateTime.year}, ${_formatTime(dateTime)}';
    }
  }

  // load user's time format preference
  Future<void> _loadTimeFormatPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _useTimeAgo = prefs.getBool('useTimeAgo') ?? true;
    });
  }

  // save current time format
  Future<void> _toggleTimeFormatPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool newPreference = !_useTimeAgo;
    await prefs.setBool('useTimeAgo', newPreference);
    setState(() {
      _useTimeAgo = newPreference;
    });
  }

  // handle the insertion of a new record
  void _addAttendanceRecord(AttendanceRecord record) {
    setState(() {
      _attendanceRecords.insert(0, record);
    });
  }

  // load all records
  Future<void> _loadAttendanceRecords() async {
    // load text file contents
    String data = await rootBundle.loadString('./assets/dataset.txt');

    // parse data and populate the attendance records list
    List<dynamic> jsonList = json.decode(data);
    List<AttendanceRecord> records = jsonList.map((item) {
      return AttendanceRecord(
        user: item['user'],
        phone: item['phone'],
        checkIn: DateTime.parse(item['check-in']),
      );
    }).toList();

    // sort records based on check-in time (most recent to oldest)
    records.sort((a, b) => b.checkIn.compareTo(a.checkIn));

    // update attendance record lists with updated data
    setState(() {
      _attendanceRecords = records;
      _filteredRecords = records;
    });
  }

  // filter attendance records based on search query
  void _filterRecords(String query) {
    setState(() {
      _filteredRecords = _attendanceRecords.where((record) {
        return record.user.toLowerCase().contains(query.toLowerCase()) ||
            record.phone.contains(query);
      }).toList();
    });
  }

  // controllers for input fields in "add record" form
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // display a form to enter a new record, notify user when action was successful
  void _showAddRecordSuccess() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // layout of the form
        return AlertDialog(
          title: Text("Add Record"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _userController,
                  decoration: InputDecoration(labelText: "Name"),
                ),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: "Phone Number"),
                ),
              ],
            ),
          ),
          actions: [
            // cancel button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            // add record button
            TextButton(
              onPressed: () {
                // create new record with current time as check-in
                AttendanceRecord newRecord = AttendanceRecord(
                  user: _userController.text,
                  phone: _phoneController.text,
                  checkIn: DateTime.now(), 
                );
                _addAttendanceRecord(newRecord);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    // dialog pop-up to notify user
                    content: Text("Attendance record added successfully"),
                  ),
                );
                Navigator.of(context).pop();
                // clear input fields after insert is complete
                _userController.clear();
                _phoneController.clear();
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Attendance Records'),
          actions: [
            // toggle time format button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: TextButton(
                onPressed: () {
                  _toggleTimeFormatPreference();
                },
                child: Text("Change date/time format"),
              ),
            ),
            // search button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: TextButton(
                onPressed: () async {
                  final String? selected = await showSearch<String?>(
                    context: context,
                    delegate: _SearchDelegate(_attendanceRecords),
                  );
                  if (selected != null && selected.isNotEmpty) {
                    _filterRecords(selected);
                  }
                },
                child: Text("Search"),
              ),
            ),
            // add record button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: TextButton(
                onPressed: () {
                  _showAddRecordSuccess();
                },
                child: Text("Add Attendance"),
              ),
            ),
          ],
        ),
        body: _filteredRecords.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _filteredRecords.length,
                itemBuilder: (context, index) {
                  final record = _filteredRecords[index];
                  String formattedTime = _formatDateTime(record.checkIn);
                  return ListTile(
                    title: Text(record.user),
                    subtitle: Text(
                        'Phone: ${record.phone}\nChecked in: $formattedTime'),
                  );
                },
              ),
      );
    }
  }

  // record search functionality
  class _SearchDelegate extends SearchDelegate<String?> {
    final List<AttendanceRecord> attendanceRecords;

    _SearchDelegate(this.attendanceRecords);

    @override
    List<Widget> buildActions(BuildContext context) {
      return [IconButton(icon: Icon(Icons.clear), onPressed: () => query = '')];
    }

    @override
    Widget buildLeading(BuildContext context) {
      return IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );
    }

    @override
    Widget buildResults(BuildContext context) {
      return SizedBox.shrink();
    }

    @override
    Widget buildSuggestions(BuildContext context) {
      final List<AttendanceRecord> suggestionList = query.isEmpty
          ? attendanceRecords
          : attendanceRecords.where((record) {
              return record.user.toLowerCase().contains(query.toLowerCase()) ||
                  record.phone.contains(query) ||
                  _formatDateTimeGeneral(record.checkIn).contains(query);
            }).toList();

      return ListView.builder(
        itemCount: suggestionList.length,
        itemBuilder: (context, index) {
          final record = suggestionList[index];
          String formattedTime = _formatDateTimeGeneral(record.checkIn);
          return ListTile(
            title: Text(record.user),
            subtitle: Text('Phone: ${record.phone}\nChecked in: $formattedTime'),
            onTap: () {
              close(context, record.user);
            },
          );
        },
      );
    }
  }