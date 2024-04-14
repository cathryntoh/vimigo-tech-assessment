import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

// data structure for attendance records
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

  // initialize stateful widgets
  @override
  void initState() {
    super.initState();
    _loadAttendanceRecords();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Records'),
      ),
      body: _attendanceRecords.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _attendanceRecords.length, // count of records
              // build each item in list
              itemBuilder: (context, index) {
                final record = _attendanceRecords[index];
                return ListTile(
                  title: Text(record.user),
                  subtitle: Text('Phone: ${record.phone}\nCheck-in: ${record.checkIn.toString()}'),
                );
              },
            ),
    );
  }

}