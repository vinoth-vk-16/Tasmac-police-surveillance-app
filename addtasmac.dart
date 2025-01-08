// addtasmac.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTASMACPage extends StatefulWidget {
  @override
  _AddTASMACPageState createState() => _AddTASMACPageState();
}

class _AddTASMACPageState extends State<AddTASMACPage> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController markerAreaController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  final TextEditingController ownerNoController = TextEditingController();
  final TextEditingController supplierController = TextEditingController();
  final TextEditingController supplierNoController = TextEditingController();

  void addTASMAC(BuildContext context) async {
    try {
      double latitude = double.parse(latitudeController.text);
      double longitude = double.parse(longitudeController.text);
      String docId = idController.text;

      // Create GeoPoint
      GeoPoint coordinates = GeoPoint(latitude, longitude);

      // Add data to Firestore
      await FirebaseFirestore.instance
          .collection('TASMAC_Locations')
          .doc(docId)
          .set({
        'title': titleController.text,
        'owner_name': ownerNameController.text,
        'marker_area': markerAreaController.text,
        'coordinates': coordinates, // Store as GeoPoint
        'owner_no':
            int.tryParse(ownerNoController.text) ?? 0, // Convert to integer
        'supplier': supplierController.text,
        'supplier_no':
            int.tryParse(supplierNoController.text) ?? 0, // Convert to integer
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('TASMAC location added successfully')),
      );

      // Clear the input fields after successful submission
      idController.clear();
      titleController.clear();
      ownerNameController.clear();
      markerAreaController.clear();
      latitudeController.clear();
      longitudeController.clear();
      ownerNoController.clear();
      supplierController.clear();
      supplierNoController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add TASMAC location: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add Tasmac",
          style: TextStyle(color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0575E6), // RGB(5, 117, 230)
                Color(0xFF021B79), // RGB(2, 27, 121)
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: "TASMAC Document ID",
                  hintText: "Enter TASMAC document ID",
                ),
              ),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Title",
                  hintText: "Enter TASMAC location title",
                ),
              ),
              TextField(
                controller: ownerNameController,
                decoration: const InputDecoration(
                  labelText: "Owner Name",
                  hintText: "Enter the owner's name",
                ),
              ),
              TextField(
                controller: markerAreaController,
                decoration: const InputDecoration(
                  labelText: "Marker Area",
                  hintText: "Enter the area where the marker is located",
                ),
              ),
              TextField(
                controller: latitudeController,
                decoration: const InputDecoration(
                  labelText: "Latitude",
                  hintText: "Enter the latitude",
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: longitudeController,
                decoration: const InputDecoration(
                  labelText: "Longitude",
                  hintText: "Enter the longitude",
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: ownerNoController,
                decoration: const InputDecoration(
                  labelText: "Owner Number",
                  hintText: "Enter the owner number",
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: supplierController,
                decoration: const InputDecoration(
                  labelText: "Supplier",
                  hintText: "Enter the supplier name",
                ),
              ),
              TextField(
                controller: supplierNoController,
                decoration: const InputDecoration(
                  labelText: "Supplier Number",
                  hintText: "Enter the supplier number",
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0575E6), // RGB(5, 117, 230)
                      Color(0xFF021B79), // RGB(2, 27, 121)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    if (_validateInputs(context)) {
                      addTASMAC(context);
                    }
                  },
                  child: const Text(
                    "Add TASMAC Location",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors
                        .transparent, // This ensures the button's background is transparent
                    elevation: 0, // No elevation
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Input validation function
  bool _validateInputs(BuildContext context) {
    if (idController.text.isEmpty ||
        titleController.text.isEmpty ||
        ownerNameController.text.isEmpty ||
        markerAreaController.text.isEmpty ||
        latitudeController.text.isEmpty ||
        longitudeController.text.isEmpty ||
        ownerNoController.text.isEmpty ||
        supplierController.text.isEmpty ||
        supplierNoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all the required fields')),
      );
      return false;
    }

    // Validate latitude and longitude values
    try {
      double lat = double.parse(latitudeController.text);
      double lng = double.parse(longitudeController.text);
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
        throw Exception("Invalid coordinates");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter valid latitude and longitude')),
      );
      return false;
    }

    return true;
  }
}
