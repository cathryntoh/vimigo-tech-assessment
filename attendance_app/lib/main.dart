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

class AttendanceListScreenState extends State<AttendanceListScreen> {
  List<AttendanceRecord> _attendanceRecords = [];
  bool _useTimeAgo = true;

  // initialize stateful widgets
  @override
  void initState() {
    super.initState();
    _loadAttendanceRecords();
    _loadTimeFormatPreference();
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
    });
  }

  // formats time as absolute time
  String _formatDateTime(DateTime dateTime) {
    if (_useTimeAgo) {
      return timeago.format(dateTime, locale: 'en');
    } else {
      return '${dateTime.day} ${_getMonthAbbreviation(dateTime.month)} ${dateTime.year}, ${_formatTime(dateTime)}';
    }
  }

  // formats just the time
  String _formatTime(DateTime dateTime) {
    String hour = dateTime.hour.toString().padLeft(2, '0');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Records'),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0), // Adjust the horizontal padding as needed
            child: TextButton(
              onPressed: () {
                _toggleTimeFormatPreference();
                // setState(() {
                //   _useTimeAgo = !_useTimeAgo;
                // });
              },
              child: Text("Change date/time format"),
            ),
          ),
        ],
      ),
      body: _attendanceRecords.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _attendanceRecords.length, // count of records
              // build each item in list
              itemBuilder: (context, index) {
                final record = _attendanceRecords[index];
                String formattedTime = _formatDateTime(record.checkIn);
                return ListTile(
                  title: Text(record.user),
                  subtitle: Text('Phone: ${record.phone}\nChecked in: $formattedTime'),
                );
              },
            ),
    );
  }
}