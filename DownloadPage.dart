import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DownloadPage extends StatefulWidget {
  @override
  _DownloadPageState createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _requestPermissions() async {
    if (await Permission.storage.request().isGranted) {
      // Storage permission granted
    } else {
      // Show a message if permission is denied
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Storage permission is required to download files.')),
      );
    }
  }

  Future<void> _downloadExcel(String selectedDate) async {
    // Request storage permission before proceeding
    await _requestPermissions();

    // Create an Excel document
    var excel = Excel.createExcel();
    Sheet visitedSheet = excel['Visited TASMACs'];
    Sheet unvisitedSheet = excel['Unvisited TASMACs'];

    visitedSheet.appendRow([
      'ID',
      'Visited Time',
      'Information',
      'Information Time',
      'Visited By'
    ]);
    unvisitedSheet.appendRow(['ID', 'Title', 'Marker Area']);

    try {
      DateTime date = DateTime.parse(selectedDate);
      DateTime startOfDay = DateTime(date.year, date.month, date.day);
      DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      QuerySnapshot tasmacSnapshot =
          await _firestore.collection('TASMAC_Locations').get();

      for (var doc in tasmacSnapshot.docs) {
        final locationId = doc.id;
        final visitsSnapshot = await _firestore
            .collection('TASMAC_Locations')
            .doc(locationId)
            .collection('Location_visits')
            .where('visited_time', isGreaterThanOrEqualTo: startOfDay)
            .where('visited_time', isLessThanOrEqualTo: endOfDay)
            .get();

        if (visitsSnapshot.docs.isEmpty) {
          unvisitedSheet
              .appendRow([locationId, doc['title'], doc['marker_area']]);
        }

        for (var visitDoc in visitsSnapshot.docs) {
          final data = visitDoc.data();
          visitedSheet.appendRow([
            locationId,
            (data['visited_time'] as Timestamp).toDate().toLocal().toString(),
            data['information'] ?? 'N/A',
            (data['info_time'] as Timestamp).toDate().toLocal().toString(),
            'N/A', // Handle 'visited by' if available
          ]);
        }
      }

      // Get the directory to save the file in Downloads folder
      Directory? directory = await getExternalStorageDirectory();
      String downloadsPath =
          '${directory!.path}/Download'; // Downloads directory
      String filePath = '$downloadsPath/TASMAC_Report_$selectedDate.xlsx';

      // Create Downloads directory if it doesn't exist
      Directory(downloadsPath).create(recursive: true);

      // Save the Excel file
      File file = File(filePath);
      await file.writeAsBytes(excel.save()!);

      // Open the file after saving
      final result = await OpenFile.open(filePath);

      // Notify the user
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Excel file downloaded and opened successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open the file: ${result.message}')),
        );
      }

      // Log the file path
      print('File saved at: $filePath');
    } catch (e) {
      // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController dateController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text('Download Excel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: dateController,
              decoration: InputDecoration(
                labelText: 'Enter Date (YYYY-MM-DD)',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String selectedDate = dateController.text;
                if (selectedDate.isNotEmpty) {
                  _downloadExcel(selectedDate);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid date.')),
                  );
                }
              },
              child: Text('Download Excel'),
            ),
          ],
        ),
      ),
    );
  }
}
